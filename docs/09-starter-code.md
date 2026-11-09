# 9. Starter Code — Project Structure and Player Module

**Status:** Starter v0.1 · **Scope:** repository layout for the whole product, with the first implemented module (the mobile player)

---

## 9.1 Repository layout

The product is a monorepo. Folders marked **implemented** exist in this repository today. Folders marked **planned** are placeholders in the layout, to be created by the squad that owns them (see [06-roadmap-and-team](06-roadmap-and-team.md)).

```
aurasound/
├── apps/
│   ├── mobile/              Flutter app for Android and iOS                 IMPLEMENTED (player module)
│   ├── web/                 Next.js web player and public pages             planned (M2–M3)
│   └── desktop/             Flutter desktop companion                       planned (P2)
├── services/                Backend services, one folder per domain          planned (M1–M2)
│   ├── bff/                 GraphQL gateway (TypeScript)
│   ├── playback/            Entitlement, sessions, DRM handoff (Go)
│   ├── catalog/             Metadata and availability (Go)
│   ├── library/             Library, playlists, downloads (Go)
│   ├── search/              Query service and indexing (Go + Python)
│   ├── billing/             Plans, checkout, webhooks (Go)
│   └── rights/              Licences and royalty ledger (Go + Python batch)
├── ml/                      Python: recommender, assistant, lyrics, hum, stems   planned (M2–M3)
├── data/                    dbt models, streaming jobs, pipeline DAGs            planned (M2–M3)
├── db/                      PostgreSQL schema and validation                     IMPLEMENTED
│   ├── schema.sql           59 tables, pgvector, constraints
│   ├── validate_schema.mjs  Applies schema to PGlite and runs 12 checks
│   └── package.json
├── api/                     OpenAPI (REST) and GraphQL schema files              planned (from docs/03)
├── infra/                   Terraform modules, Helm charts, Argo CD apps         planned (M1)
├── tools/                   Maintenance scripts                                  IMPLEMENTED
│   └── cost_model.py        Reproduces every table in docs/07-cost-estimate.md
├── docs/                    Product, architecture, data, UX, AI, roadmap, cost, risks
├── .gitignore
└── README.md
```

**Conventions**

- One folder per deployable unit. Shared contracts (protobuf, GraphQL, OpenAPI) live in `api/` and are generated into each service.
- No cross-service database access. Services talk through APIs and events only.
- Feature flags for every feature that is not yet GA.
- Each app and service has its own README with the run and test commands.

---

## 9.2 Mobile player module (implemented)

Location: `apps/mobile/lib/player/`, tests in `apps/mobile/test/player/`.

### What it does

| Capability | How | Spec reference |
|---|---|---|
| Gapless playback between queued tracks | One `ConcatenatingAudioSource` in the native player | PRD US-101 |
| Shuffle that keeps the current track playing | Queue reorders the rest; the engine sequence is rebuilt at the current position | PRD US-101, §1.3 |
| Repeat off, all, one | Queue mode, mapped to the engine's loop mode | Standard player behaviour |
| Play next and remove from queue | In-place edits to the engine sequence (no restart) | PRD §1.3 (library, queue) |
| Previous restarts a track after 3 seconds | Controller logic | Standard player behaviour |
| Seek, volume, speed | Engine commands | PRD US-104 (EQ later) |
| Mini player and full-screen player | Widgets with accessible labels and tooltips | NFR-07 (WCAG 2.2) |

### Design

```
features/ (UI)  ──depends on──▶  player/PlayerController  ──▶  PlaybackQueue (pure Dart)
                                         │
                                         ▼
                              PlaybackEngine (interface)
                                 ▲                 ▲
                   JustAudioEngine (production)   FakePlaybackEngine (tests)
```

- **`PlaybackQueue`** is pure Dart. It knows ordering, shuffle, repeat, and cursor position. It has no platform dependency, so it is fully unit-tested.
- **`PlaybackEngine`** is the only seam to the audio stack. Swapping just_audio for a native Media3 or AVPlayer module changes one file.
- **`PlayerController`** coordinates the queue and the engine and notifies the UI.
- **`PlaybackSnapshot`** is the immutable state the UI renders.

### Tests

| File | What it covers |
|---|---|
| `playback_queue_test.dart` | Load and start index; shuffle keeps the current track first; turning shuffle off restores order; repeat cycle; next and previous cursor with each repeat mode; play next; remove before, at, and after the cursor; removing the last track |
| `player_controller_test.dart` | Commands reach the engine in the right order; engine index keeps the queue in sync; shuffle reloads at the current position; repeat is forwarded; play next and remove forwarded as in-place edits; previous restarts or goes back depending on position |

### Verification status (important)

- **Dart code: not compiled or tested yet.** The sandbox used to create this starter has no Flutter or Dart SDK, and the SDK download host is not reachable from it. The code follows documented APIs of `just_audio` 0.9.x and Flutter 3.22+, but the analyzer may still report issues. The first task after cloning is `flutter analyze` and `flutter test` (commands in [`apps/mobile/README.md`](../apps/mobile/README.md)).
- **Database schema: verified.** `db/validate_schema.mjs` applies `schema.sql` to a real PostgreSQL engine (PGlite with pgvector) and checks the happy path, a vector query, and 8 invalid writes that must be rejected (plus one labelled upload that must be accepted). All checks pass.
- **Cost model: verified by running.** `tools/cost_model.py` runs with the standard library only, and its output matches the tables in the cost document.

### Known gaps in the player module

| Gap | Plan |
|---|---|
| Lock-screen and background playback | Wrap the engine in `audio_service` (M2). Required before any release |
| Crossfade | Two players with a volume ramp (P2) |
| Equalizer | `AudioPipeline` effects (M2 for presets, P2 for custom bands) |
| DRM | Spike in M1 (AQ-4 in [02-architecture](02-architecture.md)) |
| Offline playback | Separate `downloads/` module with encrypted storage and licence renewal (M3) |
| Position updates | Throttle the snapshot stream; by default the engine emits position about 5 times per second, which rebuilds the UI each time |
| Error handling | Map engine errors to user-facing states and retries (M2) |

---

## 9.3 How to extend the starter

1. **Add a feature to the player** by changing the controller first, adding a test with `FakePlaybackEngine`, then implementing it in `JustAudioEngine`.
2. **Add a screen** under `features/<name>/`. Read state through `PlayerController`, and do not import `just_audio` in UI code.
3. **Add a backend service** under `services/<name>/` with its own README, and generate its contracts from `api/`.
4. **Add a database table** by changing `db/schema.sql` and extending `validate_schema.mjs` with a test for each new constraint.
