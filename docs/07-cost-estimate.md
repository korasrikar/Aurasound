# 7. Cost Estimate — AuraSound

**Status:** Planning estimate v1.0 · **Currency:** USD · **Source of numbers:** [`tools/cost_model.py`](../tools/cost_model.py) (run `python3 tools/cost_model.py` to reproduce every table in this document)

> **Accuracy:** these are planning figures, roughly ±30%. Cloud prices, CDN rates, and vendor quotes must be replaced with actual quotes before budget approval. Excluded costs are listed in §7.6.

---

## 7.1 Summary

| Item | Estimate | Note |
|---|---|---|
| **Development, 12 months** | **≈ $5.3M** | People $4.5M (480 FTE-months) plus $0.84M non-people spend |
| **Development, MVP (M1–M4)** | ≈ $1.4M | 30 people average |
| **Monthly infrastructure at launch** (M4, 300k MAU) | ≈ $39k | About $4.2k is CDN |
| **Monthly infrastructure at M12** (2M MAU) | ≈ $159k | CDN $21k, ML and data about $28k |
| **Monthly infrastructure at 10M MAU** | ≈ $714k | CDN $70k, compute $150k, ML and data $130k |
| **Key finding** | **The subscription model needs ~26% paid conversion at 10M MAU to cover infrastructure and people** | At the planning assumption of 8%, the business loses about $1.3M a month at that scale. See §7.4 |

**What drives the numbers:** people cost is about 84% of development spend. At scale, infrastructure is dominated by compute, the data platform, and ML. CDN egress is the largest single line only at the largest scale. The bigger issue is revenue per listener, not infrastructure.

---

## 7.2 Assumptions

| Area | Assumption | Basis and what to check |
|---|---|---|
| People | Blended loaded cost **$9,350 per FTE-month** = 70% India at $6,500 + 30% global or senior at $16,000 | Loaded salary, benefits, equipment, and overhead. Validate with the HR and finance teams |
| Team | Average headcount 30 (MVP), 42 (Phase 2), 48 (Phase 3) | Matches the squad table in [06-roadmap-and-team](06-roadmap-and-team.md) §6.3.2 |
| Usage | 35% DAU/MAU; 55 minutes per DAU per day | PRD targets (§1.7) |
| Bitrate | 95% standard at 160 kbps, 5% Hi-Res at 1,000 kbps → **202 kbps** blended, **1.51 MB per minute** | §2.7 of the architecture doc |
| Offline | 20% of listening is served from downloads (no CDN egress) | Planning value; download share will be measured in beta |
| CDN price | $0.020 per GB (launch), $0.015 (M12), $0.010 (10M MAU) | Negotiated, multi-CDN. Public list prices are higher; contracts are needed |
| LLM | 0.2 assistant interactions per DAU per day at $0.0015 each | Small hosted model with caching (§5.6.3) |
| Revenue | 8% of MAU are paid, at a blended **$2.50 per paid user per month** | India-heavy mix with regional pricing. Replace with price-book data |
| Royalties | **60% of subscription revenue** goes to rights holders (pool) | Assumption to test in label and publisher negotiations (see R-1 and R-2 in [08-risks](08-risks.md)) |
| Store and payment fees | **12% of revenue** | Blended app-store commissions (up to 30%, lower for subscriptions after year one) and payment-gateway fees. Shift to direct billing lowers this |

---

## 7.3 Development cost

| Phase | Months | Avg headcount | FTE-months | People cost | Non-people | Phase total |
|---|---|---|---|---|---|---|
| MVP | 4 | 30 | 120 | $1.12M | $270k | **$1.39M** |
| Phase 2 | 4 | 42 | 168 | $1.57M | $275k | **$1.85M** |
| Phase 3 | 4 | 48 | 192 | $1.80M | $295k | **$2.09M** |
| **Total, 12 months** | 12 | | 480 | **$4.49M** | **$840k** | **$5.33M** |

**Non-people spend included (per phase):**

| Item | MVP | Phase 2 | Phase 3 |
|---|---|---|---|
| Device lab and QA tooling | $40k | $30k | $30k |
| Cloud dev, staging, and test environments | $30k | $40k | $40k |
| Security: penetration tests, threat models, DRM review | $50k | $60k | $60k |
| Privacy counsel (DPDP and GDPR) | $60k | — | — |
| Creator, payments, and live compliance reviews | — | $50k | $50k |
| Hardware and wearable test devices | — | — | $60k |
| Accessibility audits (WCAG 2.2) | $20k | $15k | $15k |
| Design research and user testing | $40k | $40k | — |
| SaaS tooling (CI, issue tracking, design) | $30k | $40k | $40k |
| Live and ticketing PCI review | — | — | $50k |

**Not included in development cost:** content licence advances and minimum guarantees, marketing and user acquisition, office space, recruiting fees, and taxes. See §7.6.

---

## 7.4 Monthly infrastructure

Three scenarios: **launch** (end of M4, public launch in India), **growth** (end of M12), and **scale** (steady state at 10M MAU, the PRD target).

| Line item | Launch (M4, India) | Growth (M12) | Scale (10M MAU) |
|---|---|---|---|
| MAU | 300,000 | 2,000,000 | 10,000,000 |
| Monthly egress (TB, after offline share) | 210 | 1,400 | 6,999 |
| CDN egress | $4.2k | $21.0k | $70.0k |
| LLM assistant inference | $945 | $6.3k | $31.5k |
| Compute (Kubernetes, autoscaling) | $6.0k | $30.0k | $150.0k |
| Managed PostgreSQL (multi-AZ) | $4.0k | $12.0k | $45.0k |
| Redis cache | $800 | $3.0k | $15.0k |
| Vector search (pgvector to dedicated) | $300 | $2.0k | $20.0k |
| Event streaming (Kafka-compatible) | $1.5k | $6.0k | $30.0k |
| Data lake and warehouse | $1.0k | $8.0k | $50.0k |
| Catalog master storage | $2.0k | $8.0k | $40.0k |
| Transcoding and ingest | $3.0k | $10.0k | $25.0k |
| ML training and batch GPU | $5.0k | $20.0k | $80.0k |
| Observability | $2.0k | $8.0k | $60.0k |
| Auth, OTP, email, push | $1.0k | $4.0k | $25.0k |
| DRM license servers (vendor) | $2.0k | $8.0k | $30.0k |
| WAF, DDoS, secrets | $1.0k | $4.0k | $20.0k |
| Dev, staging, and test environments | $3.0k | $6.0k | $12.0k |
| Misc. SaaS | $1.0k | $3.0k | $10.0k |
| **Total infrastructure per month** | **$38.7k** | **$159.3k** | **$713.5k** |
| Infrastructure per MAU per month | $0.13 | $0.08 | $0.07 |

**Reading the table:**

- **CDN is 10% of scale infrastructure**, which is less than most people expect for music streaming. Low-data mode, offline downloads, and multi-CDN price negotiation are the main levers.
- **Compute (21%), ML (11%), and data platforms (28%: PostgreSQL, Redis, vector search, streaming, lake, and catalog storage) together make up about 60% of scale infrastructure.** Savings come from ARM instances (Graviton), spot capacity for batch work, and right-sizing once real traffic data is available (FinOps review monthly from M4).
- **Infrastructure per listener falls with scale** from $0.13 to $0.07 per MAU per month. This is typical, but it is not enough to offset the revenue gap in §7.5.

---

## 7.5 Unit economics check

This table asks a simple question: **at these prices and royalty terms, do revenues cover infrastructure and people?** It is not a full financial model. It excludes marketing, G&A, licence advances, and taxes.

| Scenario | Gross subscription revenue | After royalty pool and fees, before infra | Infra | People | Net per month | Paid conversion needed to break even |
|---|---|---|---|---|---|---|
| Launch (M4, India) | $60k | $16.8k | $38.7k | $280.5k | -$302.4k | Not reachable (above 100%) |
| Growth (M12) | $400k | $112k | $159.3k | $561k | -$608.3k | 51.4% |
| Scale (10M MAU) | $2.00M | $560k | $713.5k | $1.12M | -$1.28M | **26.2%** |

**Sensitivity at 10M MAU:** paid conversion needed to break even.

| ARPU per paid user | Royalty pool 50% | Royalty pool 60% (base) | Royalty pool 70% |
|---|---|---|---|
| $2.50 (base) | 19.3% | **26.2%** | 40.8% |
| $4.00 | 12.1% | 16.4% | 25.5% |
| $5.00 | 9.7% | 13.1% | 20.4% |

**What this means**

1. **An ad-free model with an open free tier is hard to fund at India-friendly prices.** The free tier earns nothing. Under a pro-rata revenue pool, free listening adds no direct royalty cost; it only dilutes the pool's split. Under per-stream minimum guarantees, free listening adds cost directly, so those terms must be avoided. CDN cost per MAU is small (about $0.01 per MAU per month at M12), but it is not zero.
2. **Conversion is the biggest lever.** Mature audio services report paid shares far above 8%. Spotify reported 281 million premium subscribers against 713 million monthly active users in Q3 2025 (about 39%). That company also earns advertising revenue from its free tier, which AuraSound does not have. [1](https://www.hollywoodreporter.com/business/business-news/spotify-q3-2025-earnings-report-subscribers-1236417329/) Our target of 8% by M12 and the break-even at 16–26% need a deliberately strong free-to-paid funnel, which is why the free-tier limits in the PRD matter (§1.4).
3. **Royalty terms can make or break the model.** Moving the pool from 60% to 70% pushes break-even from 26% to 41%. Negotiating a user-centric or hybrid model for the free tier (decision D-3) is therefore a business decision, not a finance detail.

### Levers to close the gap (ranked by expected impact)

| Lever | Expected effect | Owner | Risk |
|---|---|---|---|
| Free tier limited to shuffle-only with skip limits (PRD §1.4) | Raises conversion; reduces free-user consumption | Product | Lower free-user satisfaction and acquisition |
| Family and duo plans priced for multi-seat value | Raises ARPU per account (ARPU $2.50 assumes a mix) | Product and finance | Cannibalises individual plans if priced too low |
| Annual plans with a discount | Improves retention and cash flow | Finance | Lower revenue per month |
| Creator fees, tips, and merch commissions (Phase 2 and 3) | New revenue not dependent on listeners; not in the model above | Creator and commerce | Requires scale of creators and fans |
| Telco and device bundles (e.g., with mobile operators) | Lower acquisition cost; higher ARPU when bundled | Partnerships | Lower price per user; partner terms |
| Direct billing where allowed (web and UPI) | Reduces the 12% store and payment fee share | Billing | Store policy compliance; conversion friction |
| Royalty model change (user-centric or hybrid for the free tier) | Could reduce royalty cost for free listening | Legal and finance | Label acceptance; negotiation time |
| Infrastructure efficiency (ARM, spot, FinOps) | 10–20% of infrastructure | SRE | Engineering time |

---

## 7.6 Excluded items and open cost questions

These costs are real but not included in the totals above. Each needs an owner and a decision date.

| Item | Why excluded | Needed by |
|---|---|---|
| **Content licence advances and minimum guarantees** | Negotiated per deal and not yet known. Usually a major cost line for a launch | M2 (term sheets) |
| Marketing and user acquisition | Depends on launch plan; the PRD commits to no interruptive advertising for the product, but marketing spend is still needed | M3 |
| Indian taxes (GST on subscriptions), withholding on foreign payments | Tax advice pending | M2 |
| Legal fees (licensing, litigation reserve, DPDP compliance beyond the privacy counsel line) | Depends on licence terms and counsel's review | M1 onward |
| Insurance (cyber, media liability) | Quote needed | M4 |
| Office and workstations | Hybrid model assumed; not costed | M1 |
| Currency conversion and hedging | All figures in USD; INR conversion at planning rate to be set by finance | M1 |
| Payment-provider and store fee detail beyond the blended 12% | Depends on the final mix of channels | M2 |
| Customer support (tools and staff) | Not in the squad table; likely 6–10 agents at scale | M4 |

**Decisions that change this estimate most:** the free-tier design (D-1), the royalty model (D-3), the regional price book, and the licence advance schedule.

---

## 7.7 Recommendations

1. **Approve the MVP budget** (about $1.4M development plus the licence advances, which are not yet estimated). Do not commit Phase 2 and 3 spend until the M4 beta confirms conversion above 5% and D7 retention above 22% (see [06-roadmap-and-team](06-roadmap-and-team.md) §6.4).
2. **Treat the 26% break-even as the real target**, not 8%. Build the free-tier limits, family and duo plans, and annual pricing into the M2 plan, and test them in the closed beta.
3. **Start royalty negotiations on the economics of the free tier** in M1. This is the biggest unknown in the model.
4. **Set up FinOps from M4:** tagged cost reporting per service, monthly review, and budget alerts. Target infrastructure at or below $0.07 per MAU per month at 10M MAU.
5. **Re-run the model after the beta** with real bitrate, offline share, DAU/MAU, and conversion. Use the script, not a spreadsheet, so the assumptions stay in one place.
