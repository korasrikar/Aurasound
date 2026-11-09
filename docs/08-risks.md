# 8. Top 10 Risks and Mitigations — AuraSound

**Status:** Register v1.0 · **Review cadence:** every two weeks in the program review; top three go to the leadership team monthly
**Scoring:** Likelihood (L) and Impact (I) are rated Low, Medium, High, or Critical. Priority combines them (Critical × High = P1).

---

## 8.1 Summary

| ID | Risk | L | I | Priority | Owner | Trigger to act |
|---|---|---|---|---|---|---|
| R-1 | Content licensing is late, costly, or narrower than the MVP needs | High | Critical | **P1** | Head of Licensing | < 70% of MVP catalog under term sheet by end of M1 |
| R-2 | Ad-free economics do not cover royalties and infrastructure at planned conversion | High | High | **P1** | CFO and Head of Product | Conversion < 5% at M4 + 60 days |
| R-3 | Legal exposure from AI features: generation, voice likeness, and AI-content labelling | Medium | Critical | **P1** | General Counsel and Trust and Safety | Any licence term unsigned at M9; new adverse ruling in a key case |
| R-4 | Privacy and compliance failure (DPDP, GDPR, EU AI Act Article 50) | Medium | High | **P2** | DPO and Head of Engineering | Consent coverage < 99% in audit; rights requests > 30 days |
| R-5 | Playback start and reliability fall short on low-end Android and weak networks | Medium | High | **P2** | Head of Mobile and Head of Playback | p50 start > 500 ms in beta for 2 weeks |
| R-6 | Piracy and key extraction for offline and Hi-Res content | Medium | High | **P2** | Head of Media | Licensor audit finding; leak detected |
| R-7 | App-store and payment policy rejections, fees, or entitlement delays | Medium | High | **P2** | Head of Billing | Store rejection of a release; CarPlay entitlement not approved by M10 |
| R-8 | Indic language quality (lyrics, transliteration, voice, hum) below user expectations | High | Medium | **P2** | Head of Language and lyrics | Error reports > 2 per 1,000 lyric views; ASR WER above gate |
| R-9 | Scope and execution: MVP and AI features exceed a 4-month window and 30 people | High | High | **P2** | Head of Product and Head of Engineering | Feature freeze at M3 not met on 3 or more MVP stories |
| R-10 | Competitive response: incumbents with free tiers, bundles, and deep pricing | High | Medium | **P3** | Head of Product and Marketing | Churn > 6% monthly; price cuts by competitors in India |

Watch list (below P3, reviewed monthly): cloud and CDN cost overrun; recommendation quality and popularity bias; key-person dependency on licensing and ML; accessibility gaps in launch build; security incident affecting customer payment data.

---

## 8.2 Risk details

### R-1 — Content licensing is late, costly, or narrower than the MVP needs (P1)

- **Cause:** MVP depends on signed licences from major and regional labels, publishers, and performing rights societies (PPL and IPRS in India). Regional catalogs (Telugu, Tamil, Hindi film) are concentrated in a few labels and distributors. Synced lyrics are a separate licence.
- **Effect:** beta and launch slip; the free tier or the language promise is weakened; minimum guarantees make early cash flow negative.
- **Likelihood:** High. Licensing for a new service usually takes several months, and each rights type (streaming, offline, karaoke derivative, AI) can be a separate negotiation. Rights terms are also a significant part of the business case.
- **Impact:** Critical. Without a catalog there is no product.
- **Mitigation:**
  1. Start in M1 with a prioritised list: the top labels by listening share in each MVP language first.
  2. Ask for territory and rights-type flexibility at the start (streaming and offline first; karaoke and AI rights as options).
  3. Use aggregators and distributors for independent and regional catalog where direct deals take too long.
  4. Track **catalog coverage by language and by playlist** as a weekly leadership metric.
  5. Negotiate minimum guarantees against a ramp, not a flat fee.
- **Contingency:** launch with the licensed subset and a visible "more music coming" plan; delay the language or feature promise that depends on the missing rights, not the core product.
- **Early-warning indicators:** share of MVP catalog under term sheet; number of open licence negotiations past their planned date; minimum guarantee asks above the model's plan.

### R-2 — Ad-free economics do not cover royalties and infrastructure at planned conversion (P1)

- **Cause:** AuraSound has no advertising revenue. The free tier earns nothing. The cost model in [07-cost-estimate](07-cost-estimate.md) §7.5 shows that at 8% paid conversion and a blended $2.50 ARPU, the business loses about $1.3M a month at 10M MAU. Break-even needs about 26% conversion at a 60% royalty pool, or about 16% with a $4 ARPU.
- **Effect:** the company runs out of runway before reaching the scale where the model works; pressure to add ads, which would break the core promise.
- **Likelihood:** High under current assumptions. Mature services with ad-supported free tiers have far higher paid shares than 8% (Spotify reported about 39% paid share in Q3 2025; it also earns advertising revenue). [1](https://www.hollywoodreporter.com/business/business-news/spotify-q3-2025-earnings-report-subscribers-1236417329/)
- **Impact:** High.
- **Mitigation:**
  1. Free-tier limits designed to convert (shuffle-only, skip limits, quality cap) — PRD §1.4 and decision D-1.
  2. Family and duo plans priced to lift ARPU; annual plans for retention.
  3. Creator, tip, and merch revenue (Phase 2 and 3) as non-listener revenue.
  4. Royalty model negotiated early (decision D-3): pro-rata revenue pool with a transparent split; test user-centric terms for the free tier.
  5. Quarterly unit-economics review using the cost model with real data.
- **Contingency:** if conversion stays below 5% at M4 + 60 days, pause Phase 2 and 3 spend; test a price and packaging change before any change in the no-ads promise.
- **Early-warning indicators:** paid conversion by cohort; ARPU; royalty pool as a share of revenue; infrastructure per MAU.

### R-3 — Legal exposure from AI features: generation, voice likeness, and AI-content labelling (P1)

- **Cause:** AI music generation is under active litigation. Warner settled with both Suno and Udio, and Universal settled with Udio; Universal and Sony are still litigating against Suno, and Sony against Udio. A Munich court largely ruled for GEMA against Suno at first instance in July 2026, which is not final. [2](https://www.hacksvitae.com/life-hack/ai-music-generators-and-the-lawsuits-explained-what-was-filed-settled-and-still-open) Labelling rules also apply: EU AI Act Article 50 (chatbot disclosure and machine-readable marking) has applied since 2 August 2026, with a grace period for marking of systems already on the market until 2 December 2026. India's IT Rules amendments on synthetically generated information took effect on 20 February 2026 and require visible labels and traceable metadata. [3](https://www.legal500.com/intelligence/india/media-telecoms-it-entertainment/2026-it-rules-amendments-ai-content-labelling-and-intermediary-obligations)
- **Effect:** infringement claims, takedowns, withdrawal of features, fines, and reputational damage. Voice cloning of artists creates personality-rights claims.
- **Likelihood:** Medium (higher for generation features than for assistant features).
- **Impact:** Critical for generation features; High for the rest.
- **Mitigation:**
  1. No text-to-song launch without signed licences that cover our use of the model and output (gate at M10, §5.8.2).
  2. Voice likeness off by default; artist opt-in recorded with consent evidence (`ai_generation_attributions.consent_id`).
  3. Similarity block against the catalog (fingerprint and embedding) before any output is shown.
  4. Visible AI labels, machine-readable marking, and watermarking on all generated outputs; SGI-compliant labelling for uploads.
  5. Counsel review of each AI feature before its launch, with a written risk note.
  6. Assistant disclosure (EU Article 50) built into the M3 launch.
- **Contingency:** remove or disable the generation feature by configuration flag; keep catalog-based AI features (playlists, DJ) running.
- **Early-warning indicators:** new filings or rulings in the key cases; licensor statements on AI training; similarity-block rate; takedown requests.

### R-4 — Privacy and compliance failure (DPDP, GDPR, EU AI Act) (P2)

- **Cause:** AuraSound collects sensitive-adjacent signals: voice commands, hum recordings, location (coarse), activity, and listening history. It serves users under 18, which requires verifiable parental consent under DPDP. Obligations phase in: consent-manager registration opens on 13 November 2026 (four days after this register's date), and most data-fiduciary obligations apply from 13 May 2027. [4](https://www.consult-ds.com/regulatory-hub/dpdp-in-scope-and-timeline)
- **Effect:** penalties (DPDP penalties are per breach and can be large), forced changes to features, loss of user trust, and launch delays in the EU.
- **Likelihood:** Medium. The design is privacy-led, but the obligations are new and broad.
- **Impact:** High.
- **Mitigation:**
  1. Consent ledger and purpose-based consent from day one (`user_consents`, purpose codes).
  2. Data map per table (the `[PII]` tags in `db/schema.sql` are the start); retention jobs in production by M6.
  3. Rights workflow (access, correction, erasure, grievance, portability) tested end to end before 13 May 2027.
  4. Parental consent flow for users under 18; age gate at sign-up.
  5. EU AI Act Article 50 controls (assistant disclosure, marking) in the EU launch checklist.
  6. Annual independent privacy audit from Year 2; DPO appointed in M1.
- **Contingency:** a feature-level kill switch for any feature found non-compliant; breach response plan rehearsed twice before launch.
- **Early-warning indicators:** consent coverage in automated tests; rights requests older than 30 days; data-retention job failures.

### R-5 — Playback start and reliability fall short on low-end Android and weak networks (P2)

- **Cause:** the playback path includes an entitlement call, a DRM licence exchange, and the first CDN segment (see [02-architecture](02-architecture.md) §2.5). On mid-range Android devices and variable Indian networks, these steps add latency. Device fragmentation affects the decoder pipeline and background audio behaviour.
- **Effect:** users abandon playback; crash-free and playback failure targets are missed; poor app store ratings.
- **Likelihood:** Medium.
- **Impact:** High.
- **Mitigation:**
  1. Prefetch the next track's manifest and licence (§2.5); keep queues filled.
  2. Device lab with at least 15 representative Android devices (including low-end models) and 5 iPhone models; test on throttled networks.
  3. Real-user monitoring of playback start by device and network from the first beta.
  4. Adaptive first segment and conservative initial bitrate on cellular; low-data mode default when metered.
  5. Playback failover: alternate CDN and cached manifests.
- **Contingency:** raise the initial-quality floor only when the network is good; ship a hotfix within 48 hours for device-specific regressions.
- **Early-warning indicators:** p50 and p95 start time by device class; playback failure rate; ANR and crash rate by device model.

### R-6 — Piracy and key extraction for offline and Hi-Res content (P2)

- **Cause:** downloaded content must be decryptable offline. Rooted devices and extraction tools can attempt to copy keys or media. Licensors require protection proportionate to the rights.
- **Effect:** licensors withdraw content or raise minimum guarantees; leaked Hi-Res masters appear online.
- **Likelihood:** Medium.
- **Impact:** High.
- **Mitigation:**
  1. Keys wrapped by the device keystore or secure enclave; never exported; licences expire in 30 days.
  2. Play Integrity and App Attest checks before downloads and Hi-Res licences.
  3. Forensic watermarking of Hi-Res masters (Phase 2), with leak tracing.
  4. Rate limits and anomaly detection on licence requests.
  5. Licence-server vendor with DRM expertise; annual security review.
- **Contingency:** revoke licences for affected device classes; coordinate with licensors on takedowns within contract time limits.
- **Early-warning indicators:** licence request anomalies; attestation failure rate; takedown notices.

### R-7 — App-store and payment policy rejections, fees, or entitlement delays (P2)

- **Cause:** app stores review music apps, subscriptions, and background audio strictly. In-app purchase commissions apply to digital subscriptions. Some features need platform approval (CarPlay entitlement). Indian recurring payments (UPI autopay and e-mandates) have their own rules and merchant onboarding time.
- **Effect:** launch delays, feature removal on one platform, higher fees, and lower conversion.
- **Likelihood:** Medium.
- **Impact:** High.
- **Mitigation:**
  1. Store-policy review in M1 with a checklist for each release; request review early for features that touch policy (background audio, subscriptions, downloads).
  2. Provider and store choice by market: UPI and cards through a licensed Indian payment provider; store billing where required.
  3. CarPlay entitlement application in M9, well before the M11 launch.
  4. Clear, store-compliant upgrade flows (no hidden links to external checkout where the policy forbids).
  5. E-mandate and renewal reminders reviewed by counsel.
- **Contingency:** ship on Android first if iOS review is delayed; use web billing where the store policy and law allow.
- **Early-warning indicators:** store review rejections; checkout conversion by platform; entitlement application status.

### R-8 — Indic language quality below user expectations (P2)

- **Cause:** lyrics translation and transliteration, voice recognition, and hum search all depend on models that are weaker for Indic languages, code-mixed speech (Hinglish, Tanglish), and regional dialects. Film song lyrics mix languages and scripts.
- **Effect:** wrong lyrics, bad transliterations, failed voice commands, and lower trust in the language promise (a core differentiator).
- **Likelihood:** High (some errors are certain at launch).
- **Impact:** Medium to High.
- **Mitigation:**
  1. Human review for the top 1,000 tracks per language before launch; "machine translation" labels until reviewed.
  2. Native-speaker evaluation sets for each language, including code-mixed input, reviewed before each model change.
  3. Report-an-error action on lyrics and search results (S-108), with a 48-hour triage target.
  4. Hybrid ASR: on device for commands, cloud for long or noisy input.
  5. Dialect and code-mix coverage in the training plan, with data from licensed sources and consenting users only.
- **Contingency:** restrict transliteration to reviewed tracks; offer typed search when voice confidence is low.
- **Early-warning indicators:** error reports per 1,000 views; voice word-error rate by language; "not what I meant" rate.

### R-9 — Scope and execution: MVP and AI features exceed a 4-month window and 30 people (P2)

- **Cause:** the PRD asks for seven MVP core features and several AI features within four months, with a 30-person team that must be partly hired during M1. Each feature depends on licensing, DRM, and compliance work that is hard to parallelise.
- **Effect:** missed launch date; low quality at launch; hurried compliance work; team burnout.
- **Likelihood:** High without scope control.
- **Impact:** High.
- **Mitigation:**
  1. Explicit MVP cut-line (PRD §1.3) and a feature freeze at the end of M3.
  2. Feature flags for every AI feature, so unfinished features can ship dark.
  3. Spikes in M1 for the three riskiest items (Flutter audio, DRM, offline keys) with go or no-go decisions.
  4. Hiring plan with critical squads first; contract partners for QA and design research.
  5. Monthly scope review against the roadmap; trade scope for dates, not dates for quality.
- **Contingency:** move hum search, Tamil transliteration, and family sharing UX to Phase 2 (in the order given in the PRD).
- **Early-warning indicators:** MVP stories not started by M2 end; open P1 defects at M3; hiring fill rate by squad.

### R-10 — Competitive response: incumbents with free tiers, bundles, and deep pricing (P3)

- **Cause:** established music services in India, including ad-supported free tiers, telco and device bundles, and low entry prices, compete for the same listeners. "No ads" is a valuable promise, but it is a price-sensitive one in India. Competitors can cut prices or bundle services faster than a new entrant can build catalog and trust.
- **Effect:** lower conversion, higher acquisition cost, and pressure on regional pricing.
- **Likelihood:** High.
- **Impact:** Medium.
- **Mitigation:**
  1. Differentiate on language, lyrics, and discovery rather than price alone.
  2. Use regional and student pricing from launch; test price points in the beta.
  3. Partnerships with telcos and device makers for bundles (Phase 2 onward), priced for margin.
  4. Focus on retention features (offline, rooms, family plans, insights) that are hard to copy quickly.
  5. Track competitor pricing and bundle moves monthly.
- **Contingency:** temporary promotions limited to conversion (never interruptive ads); adjust the free-tier limits.
- **Early-warning indicators:** churn by source; trial-to-paid conversion; competitor price changes in India.

---

## 8.3 Risk interactions

- **R-1 and R-2 compound:** late licensing delays revenue and inflates the cost of minimum guarantees. Treat royalty negotiations as one workstream.
- **R-3 and R-4 share controls:** the consent ledger, labelling, and provenance records serve both privacy and AI compliance. Build them once, in the platform team.
- **R-5 and R-9 share a root cause:** scope and spikes. The M1 spikes are the early test for both.
- **R-8 and R-10:** language quality is the main answer to competitive pressure; it is not optional.

---

## 8.4 Review and governance

- Risk owners update their rows every two weeks; new risks are added with a short cause-effect statement.
- P1 risks have a named executive sponsor and a monthly decision point in the leadership review.
- Post-mortems for any triggered risk are written up and linked from the relevant ADR in [02-architecture](02-architecture.md) (or PRD §1.9 for product decisions) when they change an architecture or product decision.

---

## 8.5 Sources used

1. [Spotify Q3 2025 results: 281M premium subscribers, 713M MAU, and the advertising revenue decline (The Hollywood Reporter)](https://www.hollywoodreporter.com/business/business-news/spotify-q3-2025-earnings-report-subscribers-1236417329/)
2. [AI music generators and lawsuits: status of settlements and open cases as of October 2026](https://www.hacksvitae.com/life-hack/ai-music-generators-and-the-lawsuits-explained-what-was-filed-settled-and-still-open)
3. [India IT Rules amendments on synthetically generated information, effective 20 February 2026](https://www.legal500.com/intelligence/india/media-telecoms-it-entertainment/2026-it-rules-amendments-ai-content-labelling-and-intermediary-obligations)
4. [India DPDP Act and Rules: commencement timeline (consent managers 13 Nov 2026; core obligations 13 May 2027)](https://www.consult-ds.com/regulatory-hub/dpdp-in-scope-and-timeline)

The EU AI Act Article 50 dates are taken from the Digital Omnibus commentary (Gibson Dunn, cobalt.legal, and others, mid-2026). Confirm the final text with counsel before relying on them for a launch decision.
