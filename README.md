# Aurasound

Aurasound (working name) is a premium, **100% ad-free** music app that combines streaming,
discovery, creation, social, and live experiences, with AI in every layer. India is the first
market, with Hindi, Telugu, Tamil, and English at launch.

## What is in this repository

| Path | What it is | Status |
|---|---|---|
| [`docs/`](docs/README.md) | Product, architecture, data, UX, AI, roadmap, cost, and risk documents (all 9 deliverables) | Draft v1.0 |
| [`db/`](db/) | PostgreSQL schema (59 tables) and a validation script | Schema validated |
| [`apps/mobile/`](apps/mobile/) | Flutter app starter with a basic player module (gapless, shuffle, repeat, queue) | Written; not yet compiled |
| [`tools/cost_model.py`](tools/cost_model.py) | Reproduces the cost tables (standard library only) | Runs |

## Start here

- Product brief summary and open decisions: [docs/README.md](docs/README.md)
- Run the schema validation: `cd db && npm install && npm run validate`
- Reproduce the cost model: `python3 tools/cost_model.py`
- Mobile starter: see [apps/mobile/README.md](apps/mobile/README.md), including the commands to verify it (`flutter analyze`, `flutter test`), which have not been run yet.
