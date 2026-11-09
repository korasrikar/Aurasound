# AuraSound — Product and Technical Specification

This folder contains the deliverables for the AuraSound spec (ad-free AI music super app). The
numbering follows the list in Section 12 of the product brief.

| # | Deliverable (Section 12) | Document | Status |
|---|---|---|---|
| 1 | Product requirements document with user stories | [01-prd.md](01-prd.md) | Draft v1.0 |
| 2 | System architecture diagram (text) | [02-architecture.md](02-architecture.md) | Draft v1.0 |
| 3 | Database schema and API list | [03-data-model-and-api.md](03-data-model-and-api.md) and [`../db/schema.sql`](../db/schema.sql) | Draft v1.0; schema validated |
| 4 | UI/UX screen list and navigation flow | [04-ux-screens-and-navigation.md](04-ux-screens-and-navigation.md) | Draft v1.0 |
| 5 | AI/ML pipeline design | [05-ai-ml-pipeline.md](05-ai-ml-pipeline.md) | Draft v1.0 |
| 6 | 12-month roadmap (MVP, Phase 2, Phase 3) with team structure | [06-roadmap-and-team.md](06-roadmap-and-team.md) | Draft v1.0 |
| 7 | Cost estimate (development and monthly infrastructure) | [07-cost-estimate.md](07-cost-estimate.md) and [`../tools/cost_model.py`](../tools/cost_model.py) | Planning estimate |
| 8 | Top 10 risks and mitigations | [08-risks.md](08-risks.md) | Register v1.0 |
| 9 | Starter code (project structure and basic player module) | [09-starter-code.md](09-starter-code.md) and [`../apps/mobile`](../apps/mobile) | Starter; Dart not yet compiled |

## Reading order

1. [PRD](01-prd.md) — what we are building and for whom. Read §1.4 (free tier) and §1.9 (open decisions) first.
2. [Architecture](02-architecture.md) — how it is built, and why Flutter and Go.
3. [Cost estimate](07-cost-estimate.md) — read §7.5 (unit economics) before the roadmap.
4. [Roadmap](06-roadmap-and-team.md) and [risks](08-risks.md).
5. The remaining design documents as needed.

## Decisions needed before build starts (M1)

These are listed with owners and dates in [01-prd.md](01-prd.md) §1.9:

- **D-1** Free-tier on-demand listening (recommended: shuffle-only with limits)
- **D-2** Playback start target (recommended: p50 ≤ 500 ms; p95 ≤ 1 s on cellular)
- **D-3** Royalty model (pro-rata to start; test user-centric for the free tier)
- **D-4** Sign-in methods (phone OTP plus Google and Apple)
- **D-5** Hum search in MVP (beta only)
- **D-6** Launch languages (hi, te, ta, en)
- **D-7** First market after India

## Conventions

- Planning figures are estimates and are labelled as such. Sources for legal and market facts are cited inline.
- Scripts that produce numbers in these documents live in `tools/`, so the numbers can be regenerated.
