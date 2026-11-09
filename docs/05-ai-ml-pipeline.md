# 5. AI/ML Pipeline Design — AuraSound

**Status:** Draft v1.0 · **Owner:** ML lead · **Related:** [02-architecture](02-architecture.md) (AI services), [08-risks](08-risks.md) (R-3, R-8, R-9)

---

## 5.1 Principles

1. **Licensed or consented data only** for training and for generative features. A model trained on music without rights is not used, even if it is technically better. This follows from the 2024–2026 label lawsuits against AI music generators, where several labels settled and others are still litigating (see R-3).
2. **Catalog-grounded outputs.** Any AI that names a song, lyric, or artist must resolve it to a real catalog ID. The model never returns free-text track titles to the client.
3. **On-device where practical.** Activity detection, voice wake-up, short-form ASR, and hum capture run on the device. Heavy models run in the cloud GPU pool.
4. **Explainable.** Every personalised output has reason codes, and the "Why this?" affordance is part of the product.
5. **Measured before shipped.** Each model has offline metrics, a launch gate, and an online A/B test. Metrics are defined in §5.9.
6. **Labelled.** AI-generated outputs are labelled to the user. Machine-readable marking is applied to generated audio and text where the rules require it (§5.10).

---

## 5.2 Platform overview

```
             ┌─────────────────── Offline batch (Dagster/Airflow on Kubernetes + GPU pool) ──────────────────┐
Catalog ───▶ │ Audio analysis: loudness, tempo, key, tags, embeddings, fingerprints, stems (batch)          │
masters      │ Lyric alignment, translation, transliteration (with human review queue)                      │
             │ Recommender training (two-tower retrieval, ranking model), evaluation, model registry         │
             └──────────────┬─────────────────────────────────────────────────────────────┬────────────────┘
                            │ features (Feast: online Redis, offline Iceberg)              │ models (MLflow)
             ┌──────────────▼─────────────────────────────────────────────────────────────▼────────────────┐
Events  ───▶ │ ONLINE SERVING (Python + Go gateways, gRPC)                                                 │
             │ Recs: candidate retrieval (ANN) → ranking → re-ranking (business rules)                     │
             │ Context engine: rules + bandit policy over (time, weather, activity, device)                │
             │ Assistant orchestrator: ASR → intent router → tool calls → LLM (gateway) → TTS              │
             │ Prompt-to-playlist: intent extraction → constrained catalog search → ranking → draft        │
             │ Hum search: pitch contour → melody embedding → ANN → fingerprint re-rank                    │
             └──────────────┬─────────────────────────────────────────────────────────────────────────────┘
                            │ traces, metrics, guardrail logs, feedback
             ┌──────────────▼─────────────────────────────────────────────────────────────────────────────┐
             │ MLOps: experiment tracking, offline eval gates, canary, drift monitors, cost dashboards     │
             └─────────────────────────────────────────────────────────────────────────────────────────────┘
On device: wake word or push-to-talk, short-command ASR, activity classifier, hum recording, EQ, lyric
           sync display, offline recommendations fallback (popularity and last-played).
```

**Compute plan:** a managed GPU pool (A10G or L4 class for inference; A100 or H100 for training bursts), autoscaled by queue depth. Batch work runs on spot instances with checkpointing. GPU and batch compute costs are in [07-cost-estimate.md](07-cost-estimate.md).

---

## 5.3 Catalog intelligence (auto-tagging and fingerprinting)

**Goal:** every track gets a consistent set of tags (mood, activity, genre, tempo bucket, energy, instruments, context), an embedding, and fingerprint landmarks, within 2 hours of ingest.

| Stage | Method | Output | Notes |
|---|---|---|---|
| Decode and validate | FFmpeg; format and channel checks | Validated master | Rejects clipping and silence artefacts over threshold |
| Loudness | EBU R128 integrated loudness and true peak | Gain per track | Stored in catalog metadata |
| Tempo, key, beat | Essentia (open source) plus a learned beat tracker | BPM, key, tempo bucket | Accuracy checked against labelled sample; Indian classical and film tempos need extra tests |
| Audio embedding | Audio-language embedding model (CLAP family, fine-tuned on regional music) | 256-d vector | Model choice is evaluated on an Indian music benchmark (see §5.9) |
| Tags | Multi-label classifier on embeddings; editorial overrides win | `track_tags` rows with score and source | Source column records `model`, `editorial`, or `artist` |
| Fingerprint | Landmark hashing (Shazam-style, after Wang 2003) | `track_fingerprints` or index service | Robust to noise and compression; used for recognition and duplicate detection |
| Duplicate and near-duplicate check | Fingerprint match and embedding distance | Duplicate flags for ingest review | Prevents double-listing of re-releases; also feeds the AI-generation similarity check (§5.8) |

**Human review:** editorial team reviews the top 1,000 tracks per language and every tag with score below 0.6 for the top 200 tracks in each genre.

---

## 5.4 Recommendations (hybrid)

**Goal:** recommend tracks that match the user's taste, language, and context, while keeping discovery fresh.

### 5.4.1 Architecture

```
Candidate generation (≈ 1,000 per request)
  ├─ Collaborative: two-tower model (user tower, item tower) → ANN index (pgvector → vector engine)
  ├─ Content-based: track embeddings nearest to user's recent taste vector
  ├─ Context-aware: tag filters (activity, mood, tempo) and time-of-day priors
  ├─ Popularity and trending in the user's languages (cold-start floor)
  └─ Editorial and charts (bounded share)
        │
        ▼
Ranking (≈ 200 candidates → top 50): gradient-boosted trees (LightGBM) first; DCN-v2 (deep and cross network) once features are mature
  features: user history stats, track stats, embeddings similarity, context, time since last play, language match, skip rate, artist affinity
        │
        ▼
Re-ranking (business rules): diversity (max 3 per artist in a 20-item list), language mix target, freshness, repeat suppression (no track twice in 2 hours), explainability codes
        │
        ▼
Serve: precomputed top-200 lists per user refreshed every 15 min; online re-rank with current context (< 50 ms p95)
```

### 5.4.2 Training

- **Implicit feedback:** plays, completions, skips (under 30 s), saves, playlist adds, explicit like or dislike. Weights are tuned on a held-out week.
- **Negative sampling:** in-batch and popularity-weighted negatives for the two-tower model.
- **Retraining:** two-tower retrained daily on a 90-day window; ranker retrained weekly; embeddings refreshed when the catalog model version changes.
- **Cold start:**
  - *New user:* onboarding picks (artists, languages) map to seed embeddings; popularity in chosen languages fills the first session.
  - *New track:* content embedding plus tags; exposure guarantee for new releases in the user's languages (bounded).
  - *New artist:* artist-level similarity from track embeddings.
- **Privacy:** personalisation purpose consent is required for user-level features. Without consent, the model uses only the current session and language (non-personal).

### 5.4.3 Evaluation

| Metric | Use | Launch gate |
|---|---|---|
| Recall@50 and NDCG@10 (offline, held-out week) | Model selection | ≥ 20% above popularity baseline |
| Catalog coverage and diversity (Gini, artist entropy) | Guardrail against popularity bias | Coverage ≥ 30% of eligible catalog in a 7-day window |
| Online CTR, completion rate, listening minutes per session | Product impact | A/B test: CTR up and minutes per session not down |
| Skip rate in first 30 s | Quality signal | Not higher than control |
| Fairness check across languages and regions | Responsible AI | No language group below 80% of the average on NDCG@10 |

---

## 5.5 Smart mood and context engine

**Goal:** adapt music to workout, commute, sleep, and focus, with minimal data.

| Signal | Source | Privacy treatment | Use |
|---|---|---|---|
| Local time | Device | None (not personal data on its own) | Time-of-day priors; sleep and morning modes |
| Activity (still, walking, running, driving) | On-device classifier using motion sensors | Never leaves the device; only the label is sent, and only with consent `context_signals` | Workout and commute modes; skip prompts while driving |
| Weather | Weather API for coarse location (H3 resolution 6, average cell area about 36 km²) | Coarse location only; cell stored 30 days | Rain or monsoon moods, heat-related energy level |
| Listening pattern | Playback events | Pseudonymous, consent `personalisation` | Mood inference from recent plays |
| Manual mood chip | User tap | Explicit | Strongest signal; overrides inference for the session |

**Decision logic:** a rule layer produces candidate moods; a contextual bandit (Thompson sampling over mood-to-playlist arms) picks a mood for each session and learns from skips and completions. The bandit is capped by guardrails: no more than one mood switch per 20 minutes, and the user's explicit mood always wins.

**Explainability:** each context-driven rail names its driver ("Rainy evening in Chennai" or "Your workout time"). The user can turn off any signal.

---

## 5.6 Assistant (AI DJ and voice)

**Goal:** conversational control ("play something calm for studying"), with first audio response ≤ 1.5 s p95.

### 5.6.1 Pipeline

```
Wake or push-to-talk (on device)
  → ASR streaming
      on device: small Indic-capable model for commands (languages: hi, te, ta, en at launch)
      cloud fallback: larger Indic ASR model for long or noisy input (AI4Bharat-style Indic ASR models are candidates; evaluate)
  → Intent router
      fast path: finite intent classifier for the top 20 intents (play, pause, skip, volume, mood, artist, language, lyrics meaning, create playlist, save, sleep timer)
      open path: LLM with tool calling for anything else
  → Tool execution (allowlisted): search, playback, playlist, library, lyrics, recommendations
      each tool returns catalog IDs; no free-text track names are trusted
  → Response generation
      short response text; reasons from the recommender; "AI assistant" disclosure on first use and in settings
  → TTS (on device for short replies; cloud Indic TTS for longer)
  → Stream to the client (SSE for text; audio chunks for voice)
```

### 5.6.2 Safety and control

- **Tool allowlist.** The LLM cannot call tools outside the list. Destructive actions (delete playlist, remove downloads, change plan, delete data) require explicit confirmation through the UI (S-62).
- **No account-level actions by voice** without a second factor when the action changes billing or privacy.
- **Content guardrails:** profanity filter is user-configurable; the assistant refuses requests to impersonate artists or to generate songs (text-to-song goes through the creation flow with rights checks, §5.8).
- **Transparency:** the assistant says it is an AI system on first use and whenever asked. This applies to the EU AI Act Article 50 obligation that has applied since 2 August 2026.
- **Logs:** no raw audio stored. Transcripts kept 30 days (`assistant_turns`). Intent and latency logged without text.

### 5.6.3 LLM strategy

- **Gateway:** all LLM calls go through an internal gateway with provider routing (at least two providers), prompt versioning, caching for repeated intents, token budgets per feature, and PII redaction before logging.
- **Model tiers:** small hosted or self-hosted model for intent and short replies (target cost ≤ USD 0.0015 per interaction); a larger model only for multi-turn DJ conversations and lyric explanations.
- **Evaluation:** a scripted test set of 500 utterances across the four languages (≥ 100 per language) for intent accuracy, slot accuracy, and refusal correctness; monthly regression run.

---

## 5.7 Prompt-to-playlist and lyrics

### 5.7.1 Prompt-to-playlist

```
User prompt ("monsoon evening, Hindi retro, slow, no remixes")
  → Intent extraction (LLM, JSON schema output): mood, activity, languages, era, tempo range, energy, exclusions, length
  → Constrained retrieval:
       hard filters: rights (streaming licence, territory), language, explicit flag, exclusions
       soft ranking: embedding similarity to mood prototypes, tag scores, user taste (if consent), diversity
  → Draft: ordered track IDs, length target, title and description generated from the chosen tags (LLM, grounded)
  → Explanation: 2–3 reasons from tags and taste matches
  → Validation: every ID exists, is playable, and matches the hard filters; otherwise removed and replaced
```

**Latency:** p95 ≤ 4 s. Intent extraction is cached for common prompts. Retrieval is precomputed by mood prototypes.

**Free-tier limit:** 3 drafts per day (see PRD §1.4). Cost per draft is kept under USD 0.002.

### 5.7.2 Lyrics: sync, translation, transliteration

| Stage | Method | Quality gate |
|---|---|---|
| Source | Licensed synced lyric provider (preferred); artist-submitted text; community lyrics only where licensed | Source and licence recorded per lyric (`lyrics.license_id`) |
| Alignment | Forced alignment of licensed text to vocals (stems used for alignment where available) | Line-level error ≤ 250 ms on a labelled set; low-confidence lines flagged |
| Translation | Indic-language neural MT (IndicTrans2-class models are candidates) to English and to other Indian languages | Human review for top 1,000 tracks per language; BLEU or COMET tracked; reviewer edits feed back |
| Transliteration | Script transliteration (IndicXlit-class models) between Telugu, Tamil, Devanagari, and Latin | Spot-checked by native speakers; common-word dictionary overrides |
| Storage | `lyric_lines`, `lyric_translations` with `model_version` and `reviewed_by` | All machine output is labelled "machine translation" until a reviewer signs it off; the reviewed flag is stored per row |

**Important:** translations and transliterations are labelled as machine-generated until reviewed. Users can report errors from the lyrics screen (S-108).

---

## 5.8 Creation tools, stems, and karaoke

### 5.8.1 Stem separation and karaoke (Phase 2)

- **Model:** open-source source-separation models (Demucs-class), with weights reviewed for licence terms before use in production.
- **Where it runs:** batch on the catalog for tracks licensed for `karaoke_derivative` (stored as derived renditions); on device for the user's own files, so user uploads do not leave the device.
- **Scoring (P3):** pitch tracking (pYIN-class) compared with the reference melody, onset timing compared with the synced lyric lines; per-line score 0–100. Scoring runs on device; only the final score is saved (if the user opts in).

### 5.8.2 Text-to-song and remix (Phase 3)

This is the highest-risk feature in the product. The design is conservative by default.

| Control | Design |
|---|---|
| **Model provenance** | Only models trained on licensed or rights-cleared data, or licensed third-party generation APIs with a contract that covers our use. Model cards recorded in `ai_generations.model_id` |
| **Artist likeness** | No imitation of a named artist's voice or style unless that artist has opted in (`ai_generation_attributions` with `consent_id`). Voice cloning is off by default |
| **Similarity check** | Each output is fingerprinted and embedded; if it matches a catalog track above a threshold, it is blocked and the user is told why |
| **Remix** | Only for tracks with `ai_derivative` rights. Source attribution and revenue share recorded per contributor |
| **Labels** | Visible AI label on the track and in the player. Machine-readable marking (metadata and inaudible watermark) on all outputs (§5.10) |
| **Downloads and sharing** | Permitted for paid users only, consistent with the licence terms of the chosen model. Export includes the provenance manifest |
| **Attribution and payouts** | Contributor shares recorded at generation time; payout through the rights ledger (Phase 3) |
| **Abuse handling** | Prompt classifier blocks requests for hate content, real-person impersonation, and copyrighted lyrics reproduction; logs reviewed by trust and safety |

**Current market context:** as of late 2025 and 2026, major labels have settled with some AI music platforms (Warner with Suno and Udio; Universal with Udio), and others have not (Sony is still litigating; a German court largely ruled for GEMA against Suno at first instance in July 2026, not yet final). Licensed-data generation with artist opt-in is the only path we consider viable. The Phase 3 go or no-go decision depends on licence terms, and we will not launch text-to-song without signed agreements.

---

## 5.9 Evaluation, launch gates, and monitoring

| Model | Offline metric | Online metric | Launch gate |
|---|---|---|---|
| Recommender | NDCG@10, Recall@50 | CTR, listening minutes, skip rate | +20% over popularity offline; A/B neutral or positive on minutes |
| Tagger | Macro F1 on labelled set | Tag-driven rail CTR | Macro F1 ≥ 0.75 per tag group; editorial spot check ≥ 90% agreement |
| Embedding model (catalog) | Retrieval Recall@10 on regional benchmark | Similar-track CTR | Beats baseline on the Indian benchmark |
| Hum search | Top-3 accuracy on hum test set (5 languages, 3 hum styles) | Hum success rate (user taps a candidate and plays ≥ 30 s) | Top-3 ≥ 70% at beta launch; improve to ≥ 85% for GA |
| Fingerprint | Recall at 0 dB and 10 dB SNR | Recognition success | ≥ 95% clean clips; ≥ 80% at 10 dB |
| Assistant intent | Accuracy on scripted set (500 utterances) | Task success rate, "not what I meant" rate | ≥ 90% intent accuracy; ≤ 5% refusals on valid requests |
| Prompt-to-playlist | Grounding error rate (invalid IDs = 0), human rating | Save rate, regenerate rate | Save rate ≥ 25%; grounding errors = 0 |
| Lyrics alignment | Line error ≤ 250 ms on labelled set | Lyric-screen engagement, error reports | ≥ 90% of lines within 250 ms |
| Translation | COMET on reviewed set | Error reports per 1,000 views | Reviewed top tracks ≥ human-rated 4/5 average |

**Monitoring:** feature drift (PSI on top 50 features), prediction drift, latency and cost per request, guardrail trigger rates (refusals, blocked generations, similarity blocks), fairness metrics by language and region (weekly).

**Rollout:** shadow mode for 1 week, then canary at 1%, 10%, 50%, 100% with automatic rollback when a guardrail metric breaches its threshold.

---

## 5.10 Responsible AI, labelling, and compliance

| Obligation | Applies to | Our implementation |
|---|---|---|
| **EU AI Act Article 50 — chatbot disclosure** (since 2 Aug 2026) | Assistant offered to EU users | Disclosure on first use, in settings, and when asked |
| **EU AI Act Article 50 — machine-readable marking** of generated audio, image, video, and text | Generation features (P3) and any generated output | Metadata and inaudible watermark; systems launched before 2 Aug 2026 have until 2 Dec 2026 under the grace period |
| **EU AI Act Article 50 — deepfake labelling** | User-created content that resembles real people | Voice-likeness is off by default; labels where it is allowed |
| **India IT Rules (SGI amendments, in force 20 Feb 2026)** | Platforms offering SGI creation tools, and hosts of user uploads | Clear visible label; traceable metadata or unique identifier; tamper-resistant markers; quarterly user reminders on synthetic-content rules; takedown workflow within the required time limits |
| **Copyright (AI-generated works)** | Generation outputs | Policy: we do not claim copyright in outputs we cannot protect; terms explain the user's rights and limits; attribution recorded |
| **DPDP Act and Rules** | Personal data in models | Consent purposes for personalisation, voice, and context; data minimisation; training data excludes personal data where possible; erasure reaches feature stores and training snapshots within 30 days |
| **Bias and fairness** | Recommender, ASR, lyrics | Language and region fairness checks (§5.9); regional dataset coverage targets |
| **Human oversight** | Lyrics, translation, creator uploads, generation blocks | Review queues with SLA; appeals path for creators and rights holders |

---

## 5.11 Build, buy, or license

| Capability | Build | Buy or license | MVP choice |
|---|---|---|---|
| Recommender | Build (core differentiator) | Managed feature store or vector service where useful | Build on Python, LightGBM and two-tower |
| Audio analysis | Build pipeline | Open-source (Essentia, FFmpeg) | Build |
| Audio embeddings | Fine-tune open model | Licensed models only | Fine-tune open model on Indian data |
| Lyric source | — | Licensed provider (required) | License |
| Translation and transliteration | Fine-tune open Indic models | Hosted MT APIs as fallback | Open Indic models, self-hosted; API fallback |
| ASR (Indic) | Fine-tune open Indic model | Cloud ASR as fallback | Hybrid (on-device plus cloud fallback) |
| LLM | — | Hosted frontier and small models via gateway | Hosted, two providers |
| TTS (Indic) | — | Cloud TTS | Cloud, with on-device for short replies if quality passes |
| Stems | Open-source self-hosted | — | Self-host batch |
| DRM | — | Licence server vendor | License (decide at M2, AQ-3) |
| Generation (P3) | Only if licensed data | Licensed generation API with contract | Decide at M8 based on licence terms |

---

## 5.12 Team and tooling

- **ML team (MVP: 3; Phase 2: 6; Phase 3: 8):** recommender lead, audio and MIR engineer, LLM and assistant engineer, applied scientist for languages, ML platform engineer (shared with SRE), data scientist for experimentation.
- **Tooling:** Python 3.11, PyTorch, LightGBM, Ray for distributed training, Feast for features, MLflow for registry, Dagster for pipelines, Great Expectations for data checks, Evidently or equivalent for drift, OpenTelemetry for traces.
