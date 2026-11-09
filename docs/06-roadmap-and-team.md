# 6. 12-Month Roadmap and Team Structure — AuraSound

**Status:** Draft v1.0 · **Planning window:** Month 1 = December 2026 · Month 12 = November 2027
**Related:** [01-prd](01-prd.md) (scope), [07-cost-estimate](07-cost-estimate.md) (cost of this plan), [08-risks](08-risks.md)

---

## 6.1 Roadmap at a glance

| Phase | Months | Theme | Exit gate (go or no-go) |
|---|---|---|---|
| **Foundations** (part of MVP) | M1 | Decisions, spikes, licensing, compliance groundwork | Flutter spike passes; licensing LOIs signed for the MVP catalog |
| **MVP** | M1–M4 | Core listening product in India: streaming, library, offline, search, lyrics, onboarding, first AI features | Beta KPIs met (§6.4); launch checklist signed |
| **Phase 2** | M5–M8 | Social, Creator Hub, karaoke, insights, podcasts and audiobooks, global readiness | Creator payouts accurate; DPDP core obligations in place (13 May 2027) |
| **Phase 3** | M9–M12 | Live and ticketing, merch and fan clubs, AI creation (if licensed), car, watch, desktop | Scale test at 2× peak; Phase 3 features with safety sign-off |

---

## 6.2 Month-by-month plan

| Month | Dates | Workstreams and deliverables | Exit criteria |
|---|---|---|---|
| **M1** | Dec 2026 | **Foundations.** Architecture decision records (ADR-01 to ADR-12); Flutter spike (background audio, DRM, gapless, offline keys); design system v1; licensing negotiations (labels, publishers, IPRS and PPL, regional labels); consent ledger and privacy notice v1 (DPDP); data map; CI/CD baseline; catalog ingest prototype. **Note:** consent-manager registration opens 13 Nov 2026, four days after this plan's date; the plan does not depend on it. | Flutter spike report with go or no-go. **Pass = all five:** (1) background playback with lock-screen controls runs 60 minutes on Android and iOS; (2) Widevine L1 and FairPlay licences are acquired on the device test matrix; (3) gapless transitions on three low-end Android devices, with no audible gap in 20 consecutive transitions; (4) an encrypted offline file plays with the device offline and its key bound to the device; (5) p50 playback start ≤ 500 ms on Wi-Fi. Any fail triggers the native fallback decision (AQ-4). Also: licensing term sheets for ≥ 70% of MVP catalog; ADRs accepted |
| **M2** | Jan 2027 | **Playback v1.** Gapless, EQ, quality selection, low-data mode, media session (lock screen) via audio_service. Catalog ingest and loudness pipeline in production. Library (likes, playlists). Auth (OTP, Google, Apple). Plans and billing (Razorpay, store IAP). Lyrics provider integration (sync). Search index v1 (text, transliteration-aware). | Playback start p50 ≤ 500 ms in staging on Wi-Fi; internal dogfood at ≥ 50 users; signed licences for ≥ 90% of MVP catalog |
| **M3** | Feb 2027 | **Offline and intelligence.** Encrypted downloads and licence renewal. Voice search (ASR) and hum beta (licensed catalog). Onboarding with taste profile. Prompt-to-playlist v1. AI DJ v0 (top 20 intents). Recommender v1 (two-tower plus LightGBM ranking). Lyrics translation and transliteration for hi, te, ta, en (machine, plus top-1000 review). Usability testing with 12 users in Hyderabad, Chennai, and Pune on the clickable prototype (F1–F5), before the feature freeze. Web player (playback, library, search). Warehouse decision. | Offline licence checks pass the test matrix; recs beat popularity by ≥ 20% offline; assistant intent accuracy ≥ 90% on the scripted set. **Feature freeze** for MVP at end of M3 |
| **M4** | Mar 2027 | **Hardening and launch.** Closed beta (20k users, India); load test at 2× launch target; security review and pen-test fixes; accessibility audit fixes (WCAG 2.2 AA); privacy and DPDP readiness review; app-store submissions; launch marketing with no ad budget spent on interruptive channels. **Public launch in India at the end of M4 (≈ April 2027).** | Crash-free sessions ≥ 99.7%; playback failure rate ≤ 0.5%; no P1 security findings open; ad-free compliance scan clean; launch checklist signed |
| **M5** | Apr 2027 | **Social and creators (beta).** Follow, friend activity with privacy controls; Creator Hub invite-only upload and rights attestation; analytics v1; karaoke alpha (licensed subset, batch stems); monthly insights beta; multi-language UI expansion to 6 languages. | Activity privacy audit passed; creator upload pipeline processes 100% of test uploads with correct labels |
| **M6** | May 2027 | **Rooms and podcasts.** Listening rooms with shared queue and sync; podcasts and audiobooks (licensed and RSS sources) with resume; DPDP core obligations apply on **13 May 2027** (notices, rights workflow, breach process, erasure); data-retention jobs in production. | DPDP readiness sign-off; rights requests handled within 30 days in test; room sync drift ≤ 300 ms in tests |
| **M7** | Jun 2027 | **Creator payouts and global readiness.** Royalty statements and payouts for creators; artist analytics; EU region (data residency) live for EU users; first non-India market pilot (decision D-7) with local pricing; smart auto-download by context. | Royalty statements reproducible from ledger (100%); EU data residency verified; pilot market legal sign-off |
| **M8** | Jul 2027 | **Phase 2 GA.** Karaoke with stems GA for licensed catalog; yearly and monthly insights GA; crossfade and Hi-Res GA; passkeys; 9 UI languages; Phase 2 load test. | Phase 2 KPIs (§6.4) on track; no open P1 defects; Phase 2 release notes published |
| **M9** | Aug 2027 | **Live and wearables prototype.** Livestreams with low-latency HLS (glass-to-glass ≤ 8 s); ticketing pilot with rotating QR tickets; Wear OS and watchOS prototypes; CarPlay and Android Auto entitlement applications submitted early (Apple approval lead time). | Live pilot passes payment and entitlement tests; CarPlay entitlement submitted |
| **M10** | Sep 2027 | **Commerce and AI creation (gated).** Tips and merch (policy-compliant checkout); fan clubs. AI creation **closed beta only if** licence agreements for generation are signed and the similarity and labelling controls pass (see §5.8.2). EU AI Act and India SGI labelling checks completed for all generative features. | Safety review sign-off; zero critical findings in the red-team exercise; licences signed (or AI creation deferred) |
| **M11** | Oct 2027 | **Cars, watches, desktop.** Android Auto and CarPlay GA (after platform approval); Wear OS and watchOS beta; desktop companion beta (Windows and macOS); smart speaker prototype (voice only). | Driving-distraction review passed; watch offline playback tested on 3 devices per platform |
| **M12** | Nov 2027 | **Scale and next-year plan.** Scale test at 10M MAU capacity (≈ 205k concurrent streams, ≈ 42 Gbps peak; §2.7 of the architecture doc); reliability review (99.95% achieved?); 12-month retrospective; plan for Year 2 (global expansion, enterprise plan decision). | 99.95% availability over the year (or documented error-budget action plan); Year-2 plan approved |

**Critical path:** content licensing (M1–M3) → catalog ingest (M2) → beta (M4). Any slip in licences moves M4 directly. The cut-line in [01-prd](01-prd.md) §1.3 protects the launch date.

---

## 6.3 Team structure

### 6.3.1 Organisation model

- **Tribes** group squads that share a mission and a quarterly plan. Each tribe has a tribe lead (engineering) and a product lead.
- **Squads** of 5–8 people own a product area end to end. Each squad includes product, design, engineering, and QA. Squads have a single backlog and a fixed mission.
- **Platform and enablement** teams provide shared services (SRE, data platform, security, mobile tooling).
- **Hubs:** India engineering hub (Hyderabad, primary; Bengaluru and Chennai satellites). Global product and design hub (Phase 2+). Time-zone overlap of at least 4 hours between hubs.

### 6.3.2 Squads and headcount by phase

| Tribe | Squad | Mission | MVP (M1–M4) | Phase 2 (M5–M8) | Phase 3 (M9–M12) |
|---|---|---|---|---|---|
| **Listening** | Playback and media | Gapless, quality, DRM, streaming, prefetch, encoding | 4 | 4 | 4 |
| | Mobile core (Flutter) | App shell, player UI, settings, release engineering | 3 | 3 | 3 |
| | Catalog and rights | Ingest, licence checks, availability, rights ledger | 2 | 2 | 2 |
| | Library and search | Library, playlists, search, transliteration; podcasts and audiobooks (P2) | 2 | 3 | 3 |
| **Intelligence** | Recommendations and context | Recs, radio, context engine | 2 | 2 | 2 |
| | Assistant and voice | AI DJ, ASR, TTS, prompt-to-playlist | 2 | 2 | 2 |
| | Language and lyrics | Lyrics sync, translation, transliteration, hum search | 2 | 2 | 2 |
| | Audio research | Karaoke, stems, scoring; AI creation (P3, gated) | — | 3 | 3 |
| **Community and creators** | Social | Follow, friend activity, listening rooms | — | 4 | 4 |
| | Creator Hub | Upload, rights attestation, analytics, payouts | — | 4 | 4 |
| **Live and commerce** | Live and ticketing | Livestreams, tickets, tips | — | — | 3 |
| | Merch and fan clubs | Products, orders, fan clubs | — | — | 1 |
| **Platform** | Web (Next.js) | Web player, public pages, SEO | 2 | 2 | 2 |
| | Native and devices | Android Auto, CarPlay, Wear OS, watchOS | — | — | 2 |
| | Backend platform and SRE | Clusters, observability, security baseline | 2 | 2 | 2 |
| | Data platform | Lake, warehouse, event pipelines | 1 | 1 | 1 |
| | Identity, billing, compliance | Auth, plans, payments, DPDP workflows, trust and safety tooling | 2 | 2 | 2 |
| **Design** | Product design | Design system, screens, research | 2 | 2 | 2 |
| **Quality** | QA and test automation | Device lab, E2E, performance | 1 | 1 | 1 |
| **Operations** | Licensing and catalog operations | Contracts admin, metadata quality, editorial review | 1 | 1 | 1 |
| **Product** | Product management | Product trios, roadmap | 2 | 2 | 2 |
| | **Total** | | **30** | **42** | **48** |

The totals match the cost model in [07-cost-estimate](07-cost-estimate.md) (`tools/cost_model.py`, `PHASES`).

**Phase changes:** Phase 2 adds 12 people: Social 4, Creator Hub 4, audio research 3, and library and search +1 for podcasts and audiobooks. Phase 3 adds 6 people: live and ticketing 3, native and devices 2, and merch and fan clubs 1. Hiring for Phase 2 starts in M3 so the squads are in place by M5. The table shows headcount per phase; the exact role mix is part of the hiring plan.

### 6.3.3 Roles and key profiles

| Role | Count (M1, then per phase) | Must-have skills |
|---|---|---|
| Head of Product | 1 | Consumer music or media, subscription products |
| Head of Engineering | 1 | Distributed systems, mobile, media streaming |
| Engineering managers | 1 per 6–8 engineers | Team leadership, delivery |
| Staff or principal engineers | 3 (playback, platform, ML) | Media pipelines, DRM, distributed data |
| Flutter engineers | Within mobile core and playback squads | Dart, platform channels, audio plugins, performance profiling |
| Backend engineers (Go, TypeScript) | Within domain squads | Go services, gRPC, PostgreSQL, Kafka |
| ML engineers | Within intelligence tribe | PyTorch, recommender systems, speech or NLP, Indic languages (preferred) |
| SRE | Within platform | Kubernetes, Terraform, observability, incident response |
| Designers | Within design | Accessibility, multilingual UI, motion, design systems |
| QA automation | Within quality | Appium or Patrol, device farms, performance tests |
| Licensing and catalog operations | Within operations | Music rights, contract administration, metadata QA |

### 6.3.4 Governance

- **Quarterly planning** with OKRs per tribe, reviewed monthly.
- **Decision records** for architecture and product decisions (ADRs in `docs/adr/`, to be created in M1).
- **Stage gates** at the end of M1, M3 (feature freeze), M4 (launch), M6 (DPDP), and M10 (AI creation).
- **Release train:** two-week sprints; mobile releases every two weeks to staged rollout; backend continuous deployment with canaries.

---

## 6.4 Milestone KPIs

| Milestone | KPIs |
|---|---|
| M4 (MVP launch) | Closed beta: D7 retention ≥ 22%; playback start p50 ≤ 500 ms; playback failure ≤ 0.5%; crash-free ≥ 99.7%; no P1 security issues |
| M8 (Phase 2 GA) | MAU 500k (planning target); premium conversion ≥ 6%; recommendation CTR ≥ 8%; DAU/MAU ≥ 30% |
| M12 (Year 1) | MAU 2M (planning target, cost model growth scenario); premium conversion ≥ 8%; D30 ≥ 18%; churn ≤ 4% monthly |

These are planning targets. They are re-based after the closed beta (M4) with real data.

---

## 6.5 Dependencies and external lead times

| Dependency | Lead time | Owner | Needed for | Mitigation |
|---|---|---|---|---|
| Label, publisher, and regional catalog licences | 3–6 months | Licensing | MVP catalog (M2 to M4) | Start in M1; prioritise top-catalog labels; regional content deals in parallel |
| PPL and IPRS arrangements (performance rights) | 2–4 months | Licensing and legal | Public playback licensing in India | Legal review in M1; confirm the licence structure with the societies |
| Synced lyrics licence | 2–3 months | Licensing | Lyrics (MVP) | Choose a provider with Indic-language coverage; keep unsynced fallback |
| DRM vendor and onboarding | 4–6 weeks | Media | Offline and Hi-Res | Decide in M2 (AQ-3); test in staging early |
| Apple CarPlay audio entitlement | Several weeks, subject to Apple review | Native | Car launch (M11) | Submit in M9 |
| App store review and in-app purchase approval | 1–7 days per release; longer for policy questions | Mobile and billing | Launch (M4) | Pre-submission checklist; request review early |
| Razorpay or equivalent merchant onboarding and UPI or e-mandate setup | 2–6 weeks | Billing | Paid plans (M2) | Start in M1 |
| Student verification provider | 2–4 weeks | Identity | Student plan (M4) | Shortlist in M1 |
| EU data region build | 6–8 weeks | Platform | EU launch (M7) | Start design in M5 |
| Indic ASR and TTS vendor contracts | 4–8 weeks | Assistant | Voice (M3) | Pilot in M1 |

---

## 6.6 Risks to the timeline (summary)

Full register in [08-risks](08-risks.md). The timeline-specific risks are:

- **Scope.** The MVP asks for seven core features plus several AI features in four months. The cut-line (PRD §1.3) is the mitigation. We will not cut licensed playback, offline encryption, consent controls, or synced lyrics.
- **Licensing.** Late licences delay the beta and launch. Mitigation: parallel negotiations and a staged catalog (launch with a licensed subset, expand weekly).
- **Hiring.** 30 people in M1 is a large team to hire at once. Mitigation: open requisitions in M1 for the critical squads (playback, mobile, identity and billing); use contract partners for non-core work such as QA and design research; keep MVP scope tied to the people who are in seat.
- **Platform approvals.** CarPlay and app-store reviews sit outside our control. Mitigation: early submissions and fallback launch dates.
