# 1. Product Requirements Document (PRD) — AuraSound

**Status:** Draft v1.0 for review · **Owner:** Product · **Date:** 2026-11-09
**Scope:** MVP (Months 1–4), Phase 2 (Months 5–8), Phase 3 (Months 9–12). See [06-roadmap-and-team.md](06-roadmap-and-team.md).

---

## 1.1 Vision and positioning

AuraSound is a premium, **100% ad-free** music super app. It combines streaming, discovery, creation, social, and live experiences, with AI in every layer. India is the first market, with Hindi, Telugu, Tamil, and English at launch. Global expansion follows.

**Positioning statement:** *For Indian music lovers who want to hear the music they love in their own language without interruptions, AuraSound is the ad-free music app that understands regional music, lyrics, and moods. Unlike ad-supported services, we earn from listeners and creators, never from interruptions.*

### Product principles

1. **No interruptions, ever.** No audio, banner, interstitial, or sponsored-recommendation ads. Promotions for AuraSound's own plans are limited to the Free tier's upgrade prompts, and they never interrupt playback.
2. **Language-first.** Lyrics, search, onboarding, and assistant work in regional languages and scripts, not just English with translated labels.
3. **Trustworthy AI.** Every AI output is explainable ("Why this song?"), labelled when generated, and built on licensed or consented data.
4. **Fast by default.** Playback starts quickly on mid-range Android phones over average Indian mobile networks.
5. **Privacy as a feature.** Minimal data, clear consent, on-device processing wherever it is practical.

---

## 1.2 Target users and personas

| Persona | Who | What they need from AuraSound | Primary phase |
|---|---|---|---|
| **P1 Everyday listener** — *Ravi, 27, Hyderabad* | Works in IT, listens during commute and workouts, mixes Telugu film songs with English pop. Pays for ad-free but price-sensitive. | Ad-free playback, offline for metro travel, easy switching between languages, low data use | MVP |
| **P2 Music explorer** — *Meera, 34, Chennai* | Follows Tamil cinema scores and Carnatic fusion. Discovers music through friends and lyrics. | Language-aware discovery, synced lyrics with transliteration and translation, hum-to-search for half-remembered songs | MVP |
| **P3 Creator / indie artist** — *Kiran, 24, Pune* | Releases independent singles, wants fans and analytics. | Upload and distribution, transparent royalties, AI labelling and rights controls | Phase 2 |
| **P4 Social listener** — *Ananya, 21, Bengaluru* | Listens with a friend group and a college community. | Shared queues, listening rooms, friend activity (with privacy controls) | Phase 2 |
| **P5 Family / student / duo** | Shares a plan with family members or a partner, or has a student discount. | Multi-seat plans with separate libraries and recommendations | MVP (plan types), Phase 2 (sharing UX) |

---

## 1.3 Scope by phase

| Capability | MVP (M1–M4) | Phase 2 (M5–M8) | Phase 3 (M9–M12) |
|---|---|---|---|
| Streaming: gapless, crossfade, equalizer, Hi-Res | Gapless, EQ, Hi-Res as opt-in beta | Crossfade, Hi-Res GA | Spatial audio (research only) |
| Zero-ads subscription, freemium | Free + Individual, Student, Family, Duo plans | Regional pricing review, annual plans | Enterprise / workplace plan (exploratory) |
| Library: playlists, likes, albums, artists | Yes | Yes | Yes |
| Library: podcasts, audiobooks | Data model and resume only | Full | Full |
| Offline: encrypted downloads, smart auto-download | Yes (manual + "favourites auto-download") | Smart auto-download by context | Offline lyrics and recap |
| Search: text, voice, hum/sing | Text, voice (commands and search); hum as **beta** | Hum GA | Hum in car and watch |
| Lyrics: synced, translation, transliteration | Synced (licensed); translation and transliteration for Hindi, Telugu, Tamil, English | More languages; human-reviewed top tracks | Real-time karaoke scoring GA |
| Onboarding: taste profile, multi-language | Yes (4 languages) | 9 languages | 12+ languages |
| AI DJ / voice assistant | Intents and playback control; "calm for studying" | Full conversational DJ | Car and speaker versions |
| Prompt-to-playlist | Yes | Refinement loop ("more upbeat") | Shared prompts |
| Recommendations (hybrid) | Content plus collaborative; basic context | Full context-aware | Personal radio per mood |
| Smart mood and context engine | Time of day and manual activity | On-device activity signals (opt-in) | Auto-adapt in car and watch |
| AI music creation (text-to-song, remix) | — | Remix and stems for creators | Text-to-song with licensed model and attribution |
| Stem separation and karaoke | — | Yes (licensed catalog) | Live lyric scoring |
| Auto-tagging and fingerprinting | Fingerprint for recognition | Auto-tagging at catalog scale | — |
| Listening insights (monthly, yearly) | — | Yes | Shareable recap cards |
| Social (friends, rooms, shared queue) | — | Yes | — |
| Live (streams, virtual concerts, ticketing) | — | — | Yes |
| Creator Hub | — | Upload, analytics, payouts (invite-only at first) | Fan monetisation, tips |
| Merch and fan clubs | — | — | Yes |
| Community chats | — | — | Pilot |
| Platforms | Android, iOS, web player (playback only) | Desktop companion beta | Android Auto, CarPlay, Wear OS, watchOS, speaker beta |

**MVP cut-line.** If the M3 readiness review shows risk, these slip first, in this order: hum search GA (stays beta), transliteration for Tamil, offline auto-download rules, Family plan sharing UX. Features that are never cut are: gapless playback, ad-free guarantee, encrypted offline, consent and DPDP controls, and synced lyrics.

---

## 1.4 Plans and free tier (proposal for decision)

Ad-free means the free tier earns nothing directly. The free tier must therefore be a **genuine preview**, not a full product. The cost analysis ([07-cost-estimate.md](07-cost-estimate.md)) shows why the limits matter.

| Feature | Free | Premium Individual | Student | Family (up to 6) | Duo (2) |
|---|---|---|---|---|---|
| Ads | None | None | None | None | None |
| On-demand playback | Shuffle and radio only | Full | Full | Full | Full |
| Skips | 6 per hour | Unlimited | Unlimited | Unlimited | Unlimited |
| Audio quality | Up to 128 kbps | Up to 320 kbps; Hi-Res opt-in | Up to 320 kbps | Up to 320 kbps; Hi-Res | Up to 320 kbps; Hi-Res |
| Offline downloads | No | Yes | Yes | Yes | Yes |
| Prompt-to-playlist | 3 per day | Unlimited | Unlimited | Unlimited | Unlimited |
| AI DJ | 10 requests per day | Unlimited | Unlimited | Unlimited | Unlimited |
| Karaoke and stems (Phase 2) | No | Yes | Yes | Yes | Yes |

**Decision needed (D-1):** whether the free tier allows free on-demand listening. The recommended default is shuffle-only, with no on-demand selection until the user converts. Our economics assume that default.

Price points are set regionally in the `plan_prices` table. India launch pricing should be set after willingness-to-pay research. The model assumes a blended paid ARPU of about USD 2.50 per month.

---

## 1.5 User stories and acceptance criteria

Priorities: **Must** (MVP blocker), **Should** (planned in the phase shown), **Could** (opportunistic).
Phase codes: **MVP**, **P2**, **P3**.

### E1 — Streaming and playback

- **US-101 (Must, MVP)** As a listener, I want gapless playback across album tracks, so that live albums and DJ mixes flow without silence.
  *AC:* Gap between consecutive tracks ≤ 10 ms on the reference Android and iOS devices, measured with the test suite. Encoder delay and padding are honoured (`tracks.encoder_*_samples`).
- **US-102 (Must, MVP)** As a listener, I want playback to start quickly, so that I am not waiting after tapping play.
  *AC:* p50 time from tap to first audio ≤ 500 ms on Wi-Fi or 5G. p95 ≤ 1,000 ms on 4G. See NFR-01 and the note on this target in §1.6.
- **US-103 (Should, P2)** As a listener, I want crossfade between tracks, so that transitions are smooth at parties and workouts.
  *AC:* Crossfade length 0–12 s, user-configurable. Off by default for gapless albums and live recordings.
- **US-104 (Must, MVP)** As a listener, I want an equalizer with presets, so that I can tune sound to my headphones.
  *AC:* Presets (Flat, Bass Boost, Vocal, Late Night) plus a 5-band custom EQ. Settings persist per device.
- **US-105 (Should, MVP beta / P2 GA)** As a listener with compatible headphones, I want Hi-Res lossless playback, so that I can hear the full recording.
  *AC:* FLAC 24-bit/96 kHz playback where the catalog provides it. The app shows the active quality and falls back automatically on bandwidth or device limits.
- **US-106 (Must, MVP)** As a listener, I want playback to continue when the app is in the background or the screen is locked, with lock-screen and notification controls.
  *AC:* Media session metadata and controls on Android and iOS. Audio focus is respected (calls and navigation prompts duck or pause).

### E2 — Zero ads and plans

- **US-201 (Must, MVP)** As a listener, I want a guarantee that no ads play in the app, so that I can trust the subscription.
  *AC:* Automated tests check that no ad SDK is linked in release builds. Launch-policy checklist signed by Product and Legal.
- **US-202 (Must, MVP)** As a new user, I want a free tier that is useful, so that I can try AuraSound before paying.
  *AC:* Free tier limits match §1.4. Upgrade prompts never interrupt playback and appear only at defined moments (after a skip limit, on a locked feature).
- **US-203 (Must, MVP)** As a student, I want a student plan with verification, so that I pay less.
  *AC:* Student verification via an approved provider. Re-verification every 12 months. Verification data is deleted after confirmation.
- **US-204 (Must, MVP)** As a family organiser, I want to share a plan with up to five members, so that each person has a separate library and recommendations.
  *AC:* Invitations by phone or link. Each member's data is isolated. The owner cannot see member listening history.
- **US-205 (Must, MVP)** As an Indian user, I want to pay in rupees with UPI or cards and get a clear renewal reminder, so that I stay in control of recurring payments.
  *AC:* Supported payment methods are validated for India. Recurring payments follow the applicable RBI e-mandate rules (to be confirmed by counsel). Reminder sent before each renewal. Cancel in two taps.

### E3 — Library

- **US-301 (Must, MVP)** As a listener, I want liked songs, saved albums, and followed artists in one place, so that my library is easy to find.
  *AC:* Like, unlike, save, and unsave work offline and sync within 5 s when back online.
- **US-302 (Must, MVP)** As a listener, I want to create, edit, reorder, and share playlists, so that I can organise my music.
  *AC:* Up to 10,000 tracks per playlist. Reorder is optimistic and conflict-safe. Share link respects visibility settings.
- **US-303 (Should, P2)** As a listener, I want podcasts and audiobooks in my library, with resume across devices.
  *AC:* Resume position synced within 10 s. Audiobook chapters and playback speed (0.5x–2.5x) supported.

### E4 — Offline

- **US-401 (Must, MVP)** As a listener, I want to download songs and albums for offline playback, so that I can listen without data.
  *AC:* Files are encrypted at rest with a key bound to the device keystore. Files cannot be copied out of the app or played in another app.
- **US-402 (Must, MVP)** As a listener, I want the app to licence-check downloads regularly, so that revoked or expired music stops playing.
  *AC:* Offline licence valid up to 30 days. The app re-validates online at each launch when possible. After 30 days offline, downloads are locked until the app reconnects.
- **US-403 (Should, MVP beta / P2)** As a listener, I want my favourites to download automatically on Wi-Fi, so that my commute is covered.
  *AC:* Configurable storage cap (default 5 GB). Uses Wi-Fi by default. Oldest auto-downloads are removed first. Never deletes manual downloads.

### E5 — Search and recognition

- **US-501 (Must, MVP)** As a listener, I want text search that handles transliteration, so that I can type "Kannana Kanne" and find the right song in Tamil or Telugu script.
  *AC:* Matches across scripts (Latin, Devanagari, Telugu, Tamil) and common spellings. Top-1 accuracy target 90% on the internal regional search test set.
- **US-502 (Must, MVP)** As a listener, I want to search by voice in Hindi, Telugu, Tamil, or English, so that I can search while driving or with my hands full.
  *AC:* Word error rate and intent accuracy measured per language before release. Microphone permission requested in context.
- **US-503 (Should, MVP beta)** As a listener, I want to hum or sing a tune to find a song, so that I can find music I half remember.
  *AC:* Recording of 5–15 s. Top-3 accuracy target set after the beta baseline (initial target: 70% on the hum test set). Recognition of recorded audio (fingerprinting) at 95%+ on clean clips.

### E6 — Lyrics

- **US-601 (Must, MVP)** As a listener, I want synced lyrics that follow the song in real time, so that I can sing along.
  *AC:* Line-level sync within ±250 ms for licensed synced lyrics. Word-level sync where available. Fallback to unsynced text clearly labelled.
- **US-602 (Must, MVP)** As a listener, I want lyrics translated and transliterated into my chosen language and script, so that I understand and can read Tamil or Telugu songs in Latin letters.
  *AC:* Translation and transliteration available for Hindi, Telugu, Tamil, and English at launch. Machine output for all tracks; human-reviewed output for the top 1,000 tracks per language.
- **US-603 (Should, P2)** As a listener, I want to save lyric lines, so that I can keep favourite lines.

### E7 — Onboarding

- **US-701 (Must, MVP)** As a new user, I want to sign up with my phone number or a social account in under a minute, so that I can start listening right away.
  *AC:* Phone OTP and Google or Apple sign-in. Time to first song ≤ 60 s on a median network (measured in usability tests).
- **US-702 (Must, MVP)** As a new user, I want a quick taste profile (languages, genres, artists), so that my first home screen is relevant.
  *AC:* Language selection first (Hindi, Telugu, Tamil, English, others in P2). Up to 10 artists or genres. Skippable, with a sensible default. Taste profile is editable at any time.
- **US-703 (Must, MVP)** As a user, I want the app in my language (UI strings), so that I can navigate comfortably.
  *AC:* UI localised for Hindi, Telugu, Tamil, and English at launch. Right-to-left support is not needed in MVP.

### E8 — AI DJ and voice assistant

- **US-801 (Must, MVP)** As a listener, I want to say "play something calm for studying" and have the app do it, so that I can stay hands-free.
  *AC:* Intent accuracy ≥ 90% on the scripted test set for the top 20 intents. First response audio ≤ 1.5 s p95.
- **US-802 (Must, MVP)** As a listener, I want to ask the assistant what a song's lyrics mean, so that I can understand songs better.
  *AC:* Answers cite the lyric lines used. The assistant states that it is an AI.
- **US-803 (Should, P2)** As a listener, I want a conversational DJ that keeps a theme running, so that the music changes with my mood.
  *AC:* Multi-turn context for at least 10 turns. "Why did you play this?" always has an answer.
- **US-804 (Must, MVP)** As a user, I want to know what the assistant can and cannot do, and to be able to turn off voice processing, so that I trust it.
  *AC:* Voice processing requires separate consent (purpose `voice_processing`). Raw audio is not stored. Transcripts are deleted after 30 days.

### E9 — Prompt-to-playlist

- **US-901 (Must, MVP)** As a listener, I want to describe a playlist ("monsoon evening, Hindi retro, slow") and get a playlist, so that I do not have to search song by song.
  *AC:* Playlist generated in ≤ 4 s p95. Every track comes from the licensed catalog (no hallucinated titles). The playlist can be saved, edited, or regenerated.
- **US-902 (Should, P2)** As a listener, I want to refine a generated playlist with follow-ups ("more upbeat, no remixes"), so that I can shape it.
  *AC:* Refinement keeps the accepted tracks and changes only the rest.

### E10 — Recommendations and context

- **US-1001 (Must, MVP)** As a listener, I want recommendations for my home screen and radio that reflect my taste, so that I discover music I like.
  *AC:* Offline evaluation: Recall@50 and NDCG@10 beat popularity baseline by ≥ 20%. A/B test: recommendation click-through rate (CTR) and listening time improve over the control.
- **US-1002 (Must, MVP)** As a listener, I want a "Why this song?" explanation, so that I trust recommendations.
  *AC:* Every recommended item has a reason from a fixed set (e.g., "Because you played Artist X", "Matches your Telugu picks", "Good for focus").
- **US-1003 (Should, P2)** As a listener, I want recommendations to adapt to time, weather, and activity, so that music fits my day.
  *AC:* Context signals require opt-in (purpose `context_signals`). Coarse location only (H3 resolution 6). Turning off the signal changes recommendations without breaking them.
- **US-1004 (Must, MVP)** As a listener, I want to reset or edit my taste profile and to turn off personalisation, so that I control how I'm profiled.
  *AC:* Reset clears the profile within 24 h. With personalisation off, the app still works, using popularity and language only.

### E11 — Karaoke and stems (Phase 2)

- **US-1101 (Should, P2)** As a listener, I want a karaoke version of a song with vocals removed, so that I can sing it.
  *AC:* Available only for tracks licensed for `karaoke_derivative`. Stems generated server-side in batch.
- **US-1102 (Could, P3)** As a listener, I want my singing scored against the melody and timing, so that I can improve.
  *AC:* Pitch and timing score 0–100 with per-line feedback. Scoring runs on-device; only the final score is saved, if the user opts in.

### E12 — Insights (Phase 2)

- **US-1201 (Should, P2)** As a listener, I want a monthly and yearly recap of my listening, so that I can relive my year.
  *AC:* Stats computed from aggregated data. Narrative text generated by AI and grounded only in computed stats. Shareable card without personal identifiers beyond the display name.

### E13 — AI music creation (Phase 3)

- **US-1301 (Should, P3)** As a creator, I want to generate a song from a text description, so that I can make demos and ideas quickly.
  *AC:* Output carries an audible AI label, an inaudible watermark, and a provenance manifest. Output cannot imitate a named artist's voice without that artist's opt-in.
- **US-1302 (Should, P3)** As a creator, I want to remix an existing track within licensed limits, so that I can make derivative work legally.
  *AC:* Remix options only for tracks with `ai_derivative` rights. Attribution and revenue shares recorded per contributor.
- **US-1303 (Must, P3)** As a rights holder, I want control over whether my music or voice is used in AI features, so that I decide.
  *AC:* Opt-in and opt-out per rights holder and per contribution type (style, voice, composition). Opt-outs take effect for new outputs within 24 h.

### E14 — Social (Phase 2)

- **US-1401 (Should, P2)** As a listener, I want to see what my friends are listening to, so that I can discover music together.
  *AC:* Activity visible only to followers the user accepts. Default is "friends only". A global off switch is in one tap.
- **US-1402 (Should, P2)** As a group, we want a listening room where everyone can add to a shared queue, so that we can listen together remotely.
  *AC:* Join by code. Host can set who may add. Sync drift ≤ 300 ms between participants. Room ends automatically after 30 min with no members.

### E15 — Live and commerce (Phase 3)

- **US-1501 (Should, P3)** As a fan, I want to watch artist livestreams and virtual concerts, so that I can attend from anywhere.
  *AC:* Low-latency live HLS (glass-to-glass ≤ 8 s). Entitlement checked per stream.
- **US-1502 (Should, P3)** As a fan, I want to buy tickets and see my ticket in the app, so that entry is quick.
  *AC:* Tickets issued with a rotating QR code. Transfers are logged. Refund rules are displayed before purchase.
- **US-1503 (Should, P3)** As a fan, I want to tip an artist, so that I can support them directly.
  *AC:* Tip amounts in regional currency. Platform fee disclosed before payment.

### E16 — Creator Hub (Phase 2)

- **US-1601 (Must, P2)** As an independent artist, I want to upload tracks with rights attestations and distribute them to AuraSound, so that my music reaches listeners.
  *AC:* Upload with ISRC or generated ISRC, creator rights attestation, and a declared AI-generation flag. Labels are applied when required by the Indian IT Rules (SGI) and EU Article 50.
- **US-1602 (Must, P2)** As an artist, I want analytics on streams, listeners, and cities, so that I understand my audience.
  *AC:* Daily data within 24 h. Monthly royalty statements with per-track lines.
- **US-1603 (Must, P2)** As an artist, I want transparent royalties and payouts, so that I can trust the numbers.
  *AC:* Statement lines reproduce from the royalty ledger. Payout schedule and minimum threshold shown in the app.

### E17 — Podcasts and audiobooks (Phase 2)

- **US-1701 (Should, P2)** As a listener, I want to find and follow podcasts and audiobooks, so that I can listen to spoken content.
  *AC:* Follow, new-episode notifications (opt-in), and resume across devices.

### E18 — Merch and fan clubs (Phase 3)

- **US-1801 (Could, P3)** As a fan, I want to buy merchandise and join an artist's fan club, so that I can support them.
  *AC:* Checkout inside the app where app-store policy allows; otherwise a clearly labelled external checkout.

### E19 — Privacy, consent, and account

- **US-1901 (Must, MVP)** As a user, I want to see, change, and withdraw each consent purpose at any time, so that I stay in control of my data.
  *AC:* Consent screen lists each purpose with plain-language text in my language. Withdrawal takes effect immediately and is recorded in `user_consents`.
- **US-1902 (Must, MVP)** As a user, I want to download my data and request its deletion, so that I can exercise my rights.
  *AC:* Export (portability) within 30 days, deletion request logged in `data_requests`. Deletion completes within 30 days, with backups purged within 35 days.
- **US-1903 (Must, MVP)** As a parent, I want child accounts to need verifiable parental consent, so that children's data is protected.
  *AC:* Users below 18 (DPDP threshold) require verifiable parental consent before personalisation or marketing. Age gate on sign-up.
- **US-1904 (Must, MVP)** As a user, I want to know when content is AI-generated, so that I understand what I am listening to.
  *AC:* Visible label for AI-generated tracks. Machine-readable metadata present on AI outputs.

### E20 — Platforms

- **US-2001 (Must, MVP)** As a user on Android or iOS, I want the same experience on both platforms, so that I can switch phones.
  *AC:* Feature parity for MVP on both platforms. Platform-specific behaviour documented.
- **US-2002 (Should, MVP)** As a user on the web, I want to play music in my browser and open shared links, so that I can listen without installing an app.
  *AC:* Web player supports playback, library, and search for logged-in users. Public artist, album, and playlist pages are server-rendered for SEO and link previews.
- **US-2003 (Should, P3)** As a driver, I want to use AuraSound on Android Auto and CarPlay, so that I can listen safely.
  *AC:* Templates-only UI that follows platform driving-distraction rules. Apple CarPlay entitlement obtained before launch.
- **US-2004 (Could, P3)** As a runner, I want controls on my Wear OS or Apple Watch, so that I can run without my phone.
  *AC:* Offline playback from watch-synced downloads; play, pause, skip, and volume controls.

---

## 1.6 Non-functional requirements

| ID | Requirement | Target and how it is measured |
|---|---|---|
| NFR-01 | Playback start | p50 ≤ 500 ms on Wi-Fi/5G; p95 ≤ 1,000 ms on 4G. Measured from tap to first audio sample in real-user monitoring. |
| NFR-02 | App startup | Cold start to interactive home ≤ 2.0 s on a mid-range Android device (4 GB RAM, Snapdragon 6-series class). Warm start ≤ 1.0 s. |
| NFR-03 | Availability | 99.95% monthly (≈ 21.6 minutes of downtime per month) for playback, catalog, and login. Error budget tracked per service. |
| NFR-04 | Scale | Designed for 10M+ MAU: ~205k concurrent streams and ~42 Gbps peak egress (see [02-architecture.md](02-architecture.md)). Load-tested to 2× peak before each major release. |
| NFR-05 | Audio quality | Standard up to 320 kbps AAC/Opus; Hi-Res FLAC 24-bit/96 kHz where licensed. |
| NFR-06 | Low-data mode | Default cap 96 kbps on cellular when enabled; auto-enabled when the network is metered. Cover art and lyrics images are compressed. |
| NFR-07 | Accessibility | WCAG 2.2 AA. 4.5:1 contrast for text, 44×44 pt minimum targets, full screen-reader labels, dynamic type up to 200%, reduce-motion support, captions for voice responses. |
| NFR-08 | Dark mode | System-linked, plus manual override. Tested for contrast in both modes. |
| NFR-09 | Privacy compliance | DPDP Act 2023 and DPDP Rules 2025 (core obligations from 13 May 2027), GDPR for EU users, and the EU AI Act Article 50 transparency rules for AI features offered in the EU (applicable since 2 Aug 2026). |
| NFR-10 | Security and payments | PCI DSS scope minimised (no card data stored). OWASP ASVS Level 2 for APIs. Annual third-party penetration tests. |
| NFR-11 | Content security and DRM | Widevine (Android), FairPlay (iOS), PlayReady (web and Windows) for licensed catalog. Offline keys bound to device hardware where available. |
| NFR-12 | Localisation | UI, lyrics, and search cover Hindi, Telugu, Tamil, and English at launch. Script-aware fonts (Noto Sans family). |
| NFR-13 | Data residency | Personal data of Indian users stored in India (primary region). Cross-border transfers are reviewed against DPDP Act requirements before use. |
| NFR-14 | Observability | Crash-free sessions ≥ 99.7%. Playback failure rate ≤ 0.5% of starts. Traces on every playback request. |

> **Tension to resolve (D-2):** NFR-01 says "under 500 ms" in the brief. A 500 ms target is realistic as a **p50 on good networks**. A p95 of 500 ms over cellular networks is not realistic with DRM license exchange on the critical path. We propose the targets above and will prefetch the next track's manifest and first segment to hide most of the latency.

---

## 1.7 Success metrics

| Category | Metric | Definition | MVP target (M4 + 60 days) | Year-1 target (M12) |
|---|---|---|---|---|
| Engagement | DAU/MAU | DAU ÷ MAU, 28-day window | ≥ 25% | ≥ 35% |
| Engagement | Average listening time | Minutes of playback per DAU per day | ≥ 45 min | ≥ 55 min |
| Retention | D1 / D7 / D30 | Share of new users active on day 1, 7, 30 | 40% / 22% / 12% | 45% / 28% / 18% |
| Monetisation | Premium conversion | Paid subscribers ÷ MAU | ≥ 5% | ≥ 8% (see risk R-2) |
| Discovery | Recommendation CTR | Plays started from recommendations ÷ impressions | ≥ 6% | ≥ 9% |
| Retention | Churn | Monthly paid churn | ≤ 6% | ≤ 4% |
| Quality guardrail | Playback start p50 / failure rate | From NFR-01 and NFR-14 | ≤ 500 ms / ≤ 0.5% | Same |
| Trust guardrail | Ad-free compliance | Automated ad-SDK scan of release builds | Zero findings | Zero findings |
| Rights guardrail | Royalty accuracy | Royalty statement lines reproducible from ledger | 100% | 100% |

---

## 1.8 Dependencies and constraints

- **Content licensing (critical path).** The MVP catalog depends on signed licences with major, regional, and independent labels, publishers, and the performing rights societies (PPL and IPRS in India), plus licensed synced lyrics. Without these, MVP cannot launch. See R-1 in [08-risks.md](08-risks.md).
- **App store policy.** Subscription billing rules differ by store and by country. In-app purchase commissions apply to digital subscriptions.
- **DPDP timeline.** Consent-manager registration opens 13 Nov 2026. Most data-fiduciary obligations apply from 13 May 2027, within the MVP's first months in market.
- **EU AI Act Article 50.** Applies since 2 Aug 2026 to AI features offered to people in the EU. The AI assistant must disclose that it is an AI system. Generated content needs machine-readable marking. Existing systems have until 2 Dec 2026 for marking (grace period).
- **India IT Rules (SGI).** Amendments effective 20 Feb 2026 require clear labelling and traceable metadata for synthetically generated information, which applies to creation tools and user uploads.

---

## 1.9 Open decisions

| ID | Decision | Options | Recommendation | Owner | Needed by |
|---|---|---|---|---|---|
| D-1 | Free-tier on-demand listening | Shuffle-only / on-demand with limits / full on-demand | Shuffle-only with limits | Product + Finance | M1 |
| D-2 | Playback start target | 500 ms p50 / p95 / both | p50 ≤ 500 ms; p95 ≤ 1 s on cellular | Eng + Product | M1 |
| D-3 | Royalty model | Pro-rata revenue pool / user-centric pool / hybrid | Start pro-rata to fit label deals; explore user-centric for the free tier | Legal + Finance | M2 |
| D-4 | Sign-in methods | Phone OTP only / phone + Google + Apple | Phone OTP + Google + Apple | Product | M1 |
| D-5 | Hum search in MVP | GA / beta / Phase 2 | Beta in MVP, limited to licensed catalog | Product + ML | M2 |
| D-6 | Launch languages for UI and lyrics | 4 / 6 / 9 | 4 at launch (hi, te, ta, en), 9 in Phase 2 | Product | M1 |
| D-7 | Global launch market after India | UK / US / UAE / SEA | Decide after licensing review, based on rights and demand | Exec | M5 |

---

## 1.10 Assumptions

- Launch uses licensed catalog and lyrics; no unlicensed or user-uploaded content in MVP.
- Team size and cadence follow [06-roadmap-and-team.md](06-roadmap-and-team.md).
- Metric targets are planning targets. They will be re-based after the closed beta.
