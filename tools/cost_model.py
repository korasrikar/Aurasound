#!/usr/bin/env python3
"""
AuraSound cost model: development cost, monthly infrastructure, and a
unit-economics sanity check. All inputs are planning ASSUMPTIONS (see
docs/07-cost-estimate.md). Change the constants below and re-run:

    python3 tools/cost_model.py

Prints markdown tables that are copied into docs/07-cost-estimate.md.
Stdlib only, no dependencies.
"""

# ---------------------------------------------------------------------------
# 1. Development cost
# ---------------------------------------------------------------------------
INDIA_FTE_MONTHLY = 6_500    # loaded cost (salary, benefits, overhead), USD
GLOBAL_FTE_MONTHLY = 16_000  # loaded cost for senior/global hires, USD
INDIA_SHARE = 0.70           # share of team based in India hubs

BLENDED_FTE_MONTHLY = INDIA_SHARE * INDIA_FTE_MONTHLY + (1 - INDIA_SHARE) * GLOBAL_FTE_MONTHLY

# (phase, months, average headcount, non-people spend in USD)
PHASES = [
    ("MVP", 4, 30, {
        "Device lab and QA tooling": 40_000,
        "Cloud dev/staging environments": 30_000,
        "Security: pen-test and threat model": 50_000,
        "Accessibility audit (WCAG 2.2)": 20_000,
        "Privacy counsel: DPDP + GDPR readiness": 60_000,
        "Design research and user testing": 40_000,
        "SaaS tooling (CI, issue tracking, design)": 30_000,
    }),
    ("Phase 2", 4, 42, {
        "Device lab and QA tooling": 30_000,
        "Cloud dev/staging environments": 40_000,
        "Security: pen-test and DRM review": 60_000,
        "Creator/payments compliance review": 50_000,
        "Accessibility audit (WCAG 2.2)": 15_000,
        "Design research and user testing": 40_000,
        "SaaS tooling (CI, issue tracking, design)": 40_000,
    }),
    ("Phase 3", 4, 48, {
        "Device lab and QA tooling": 30_000,
        "Cloud dev/staging environments": 40_000,
        "Security: pen-test (watch/auto/speaker surfaces)": 60_000,
        "Live/ticketing PCI review": 50_000,
        "Hardware and wearable test devices": 60_000,
        "Accessibility audit (WCAG 2.2)": 15_000,
        "SaaS tooling (CI, issue tracking, design)": 40_000,
    }),
]


def dev_cost():
    rows = []
    total = 0
    for name, months, hc, extras in PHASES:
        fte_months = months * hc
        people = fte_months * BLENDED_FTE_MONTHLY
        non_people = sum(extras.values())
        phase_total = people + non_people
        total += phase_total
        rows.append((name, months, hc, fte_months, people, non_people, phase_total))
    return rows, total


# ---------------------------------------------------------------------------
# 2. Monthly infrastructure (three scenarios)
# ---------------------------------------------------------------------------
BITRATE_STANDARD_KBPS = 160   # standard tier (AAC/Opus-class at ~160 kbps effective)
BITRATE_HIRES_KBPS = 1_000    # Hi-Res FLAC (~1,000 kbps average)
HIRES_SHARE = 0.05            # share of streams at Hi-Res
OFFLINE_SHARE = 0.20          # share of listening served from encrypted offline downloads
DAYS = 30

BLENDED_KBPS = (1 - HIRES_SHARE) * BITRATE_STANDARD_KBPS + HIRES_SHARE * BITRATE_HIRES_KBPS
MB_PER_MIN = BLENDED_KBPS * 1000 / 8 * 60 / 1e6  # kbps -> MB per minute of audio

# Scenario: name, MAU, DAU/MAU, avg minutes per DAU per day, CDN $/GB, LLM interactions per DAU/day,
# and per-component monthly infra in USD (excluding CDN and LLM, which are computed).
DAU_RATIO = 0.35
MINUTES_PER_DAU_DAY = 55
LLM_COST_PER_INTERACTION = 0.0015
LLM_INTERACTIONS_PER_DAU_DAY = 0.2

SCENARIOS = [
    {
        "name": "Launch (M4, India)", "mau": 300_000, "cdn_usd_per_gb": 0.020, "headcount": 30,
        "components": {
            "Compute (Kubernetes, autoscaling)": 6_000,
            "Managed PostgreSQL (multi-AZ)": 4_000,
            "Redis cache": 800,
            "Vector search (pgvector to dedicated)": 300,
            "Event streaming (Kafka-compatible)": 1_500,
            "Data lake and warehouse": 1_000,
            "Catalog master storage": 2_000,
            "Transcoding and ingest": 3_000,
            "ML training and batch GPU": 5_000,
            "Observability": 2_000,
            "Auth, OTP, email, push": 1_000,
            "DRM license servers (vendor)": 2_000,
            "WAF, DDoS, secrets": 1_000,
            "Dev/staging/test environments": 3_000,
            "Misc. SaaS": 1_000,
        },
    },
    {
        "name": "Growth (M12)", "mau": 2_000_000, "cdn_usd_per_gb": 0.015, "headcount": 60,
        "components": {
            "Compute (Kubernetes, autoscaling)": 30_000,
            "Managed PostgreSQL (multi-AZ)": 12_000,
            "Redis cache": 3_000,
            "Vector search (pgvector to dedicated)": 2_000,
            "Event streaming (Kafka-compatible)": 6_000,
            "Data lake and warehouse": 8_000,
            "Catalog master storage": 8_000,
            "Transcoding and ingest": 10_000,
            "ML training and batch GPU": 20_000,
            "Observability": 8_000,
            "Auth, OTP, email, push": 4_000,
            "DRM license servers (vendor)": 8_000,
            "WAF, DDoS, secrets": 4_000,
            "Dev/staging/test environments": 6_000,
            "Misc. SaaS": 3_000,
        },
    },
    {
        "name": "Scale (10M MAU)", "mau": 10_000_000, "cdn_usd_per_gb": 0.010, "headcount": 120,
        "components": {
            "Compute (Kubernetes, autoscaling)": 150_000,
            "Managed PostgreSQL (multi-AZ)": 45_000,
            "Redis cache": 15_000,
            "Vector search (pgvector to dedicated)": 20_000,
            "Event streaming (Kafka-compatible)": 30_000,
            "Data lake and warehouse": 50_000,
            "Catalog master storage": 40_000,
            "Transcoding and ingest": 25_000,
            "ML training and batch GPU": 80_000,
            "Observability": 60_000,
            "Auth, OTP, email, push": 25_000,
            "DRM license servers (vendor)": 30_000,
            "WAF, DDoS, secrets": 20_000,
            "Dev/staging/test environments": 12_000,
            "Misc. SaaS": 10_000,
        },
    },
]

# Revenue assumptions for the unit-economics check
PAID_CONVERSION = 0.08         # paid share of MAU (base case)
ARPU_PAID_USD = 2.50           # blended monthly revenue per paid user (India-heavy mix)
ROYALTY_POOL_SHARE = 0.60      # share of subscription revenue paid to rights holders (assumption)
PAYMENT_AND_STORE_FEE = 0.12   # blended app-store and payment-gateway fees, share of revenue (assumption)


def scenario_infra(s):
    dau = s["mau"] * DAU_RATIO
    minutes = dau * MINUTES_PER_DAU_DAY * DAYS
    offline_adjusted_minutes = minutes * (1 - OFFLINE_SHARE)
    gb = offline_adjusted_minutes * MB_PER_MIN / 1000
    cdn = gb * s["cdn_usd_per_gb"]
    llm = dau * LLM_INTERACTIONS_PER_DAU_DAY * DAYS * LLM_COST_PER_INTERACTION
    comp = sum(s["components"].values())
    total = comp + cdn + llm
    return {
        "dau": dau, "minutes": minutes, "egress_tb": gb / 1000,
        "cdn": cdn, "llm": llm, "components": comp, "total": total,
    }


def unit_economics(s, infra_total):
    mau = s["mau"]
    revenue = mau * PAID_CONVERSION * ARPU_PAID_USD
    contribution_pre_people = revenue * (1 - ROYALTY_POOL_SHARE - PAYMENT_AND_STORE_FEE) - infra_total
    people = s["headcount"] * BLENDED_FTE_MONTHLY
    net = contribution_pre_people - people
    # Paid conversion needed so that net = 0 (linear in conversion)
    per_conv_contribution = mau * ARPU_PAID_USD * (1 - ROYALTY_POOL_SHARE - PAYMENT_AND_STORE_FEE)
    breakeven_conv = (infra_total + people) / per_conv_contribution
    return revenue, contribution_pre_people, people, net, breakeven_conv


def money(x):
    if x < 0:
        return "-" + money(-x)
    if abs(x) >= 1_000_000:
        return f"${x/1_000_000:,.2f}M"
    if abs(x) >= 1_000:
        return f"${x/1_000:,.1f}k"
    return f"${x:,.0f}"


def main():
    print("## Assumptions")
    print(f"- Blended loaded FTE cost: {money(BLENDED_FTE_MONTHLY)}/month "
          f"({INDIA_SHARE:.0%} India at {money(INDIA_FTE_MONTHLY)}, "
          f"{1-INDIA_SHARE:.0%} global at {money(GLOBAL_FTE_MONTHLY)})")
    print(f"- Blended bitrate: {BLENDED_KBPS:.0f} kbps -> {MB_PER_MIN:.2f} MB per audio minute")
    print(f"- DAU/MAU {DAU_RATIO:.0%}, {MINUTES_PER_DAU_DAY} min/DAU/day, {OFFLINE_SHARE:.0%} offline")
    print()

    print("## Development cost")
    rows, total = dev_cost()
    print("| Phase | Months | Avg headcount | FTE-months | People cost | Non-people | Phase total |")
    print("|---|---|---|---|---|---|---|")
    for name, months, hc, fte, people, nonp, tot in rows:
        print(f"| {name} | {months} | {hc} | {fte} | {money(people)} | {money(nonp)} | {money(tot)} |")
    print(f"| **Total (12 months)** | 12 | | {sum(r[3] for r in rows)} | "
          f"{money(sum(r[4] for r in rows))} | {money(sum(r[5] for r in rows))} | **{money(total)}** |")
    print()

    print("## Monthly infrastructure")
    infras = [scenario_infra(s) for s in SCENARIOS]
    print("| Line item | " + " | ".join(s["name"] for s in SCENARIOS) + " |")
    print("|---|" + "---|" * len(SCENARIOS))
    print("| MAU | " + " | ".join(f"{s['mau']:,}" for s in SCENARIOS) + " |")
    print("| Monthly egress (TB, after offline share) | " + " | ".join(f"{i['egress_tb']:,.0f}" for i in infras) + " |")
    print("| CDN egress | " + " | ".join(money(i["cdn"]) for i in infras) + " |")
    print("| LLM assistant inference | " + " | ".join(money(i["llm"]) for i in infras) + " |")
    # component rows, using the union of names from scenario 0 (same order)
    for comp_name in SCENARIOS[0]["components"]:
        vals = [s["components"][comp_name] for s in SCENARIOS]
        print(f"| {comp_name} | " + " | ".join(money(v) for v in vals) + " |")
    print("| **Total infrastructure / month** | " + " | ".join(f"**{money(i['total'])}**" for i in infras) + " |")
    print()

    print("## Unit-economics sanity check (monthly)")
    print("| Scenario | Gross subscription revenue | After royalty pool and fees, before infra | Infra | People | Net | Paid conversion needed to break even |")
    print("|---|---|---|---|---|---|---|")
    for s, i in zip(SCENARIOS, infras):
        rev, pre, people, net, be = unit_economics(s, i["total"])
        contrib_after_infra = pre
        print(f"| {s['name']} | {money(rev)} | {money(contrib_after_infra + i['total'])} | "
              f"{money(i['total'])} | {money(people)} | {money(net)} | "
              f"{be:.1%}" + (" (not reachable)" if be > 1 else "") + " |")

    print()
    print("## Sensitivity: paid conversion needed to break even at 10M MAU (scale scenario)")
    scale = SCENARIOS[-1]
    scale_infra = scenario_infra(scale)["total"]
    people = scale["headcount"] * BLENDED_FTE_MONTHLY
    print("| ARPU per paid user | Royalty pool 50% | Royalty pool 60% | Royalty pool 70% |")
    print("|---|---|---|---|")
    for arpu in (2.5, 4.0, 5.0):
        cells = []
        for pool in (0.50, 0.60, 0.70):
            per_conv = scale["mau"] * arpu * (1 - pool - PAYMENT_AND_STORE_FEE)
            cells.append(f"{(scale_infra + people) / per_conv:.1%}")
        print(f"| ${arpu:.2f} | " + " | ".join(cells) + " |")


if __name__ == "__main__":
    main()
