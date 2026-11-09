# 3. Database Schema and API List — AuraSound

**Status:** Draft v1.0 · **Source of truth for DDL:** [`db/schema.sql`](../db/schema.sql) · **Validation:** `cd db && npm install && npm run validate`

The DDL is validated against a real PostgreSQL engine (PGlite 0.3.2, with pgvector). The script applies the whole file, runs a happy-path insert and a vector nearest-neighbour query, and checks 8 invalid writes that must be rejected (plus one labelled AI upload that must be accepted). All checks pass.

---

## 3.1 Schema overview

The schema has **59 tables** (58 logical tables plus the default partition of `recent_plays`). Tables are grouped by domain. Each domain is owned by one service (see [02-architecture.md](02-architecture.md) §2.4).

| Domain | Tables | Phase | Owning service |
|---|---|---|---|
| Identity, consent, devices | `users`, `user_consents`, `data_requests`, `devices`, `user_taste_profiles` | MVP | Identity |
| Plans and billing | `plans`, `plan_prices`, `subscriptions`, `subscription_seats`, `payments` | MVP | Billing |
| Catalog | `artists`, `albums`, `tracks`, `track_artists`, `track_renditions` | MVP | Catalog |
| Rights | `rights_holders`, `licenses`, `track_licenses` | MVP | Rights ledger |
| Intelligence | `track_embeddings`, `track_tags`, `track_fingerprints` | MVP | ML and Search |
| Lyrics | `lyrics`, `lyric_lines`, `lyric_translations` | MVP | Lyrics |
| Library and playback | `playlists`, `playlist_items`, `library_items`, `downloads`, `recent_plays` (partitioned) | MVP | Library |
| Assistant and context | `assistant_sessions`, `assistant_turns`, `context_snapshots` | MVP | Assistant |
| Podcasts and audiobooks | `shows`, `episodes`, `audiobooks`, `playback_positions` | P2 | Library |
| Social | `follows`, `activity_events`, `listening_rooms`, `room_members`, `shared_queue_items` | P2 | Social |
| Creator | `creator_profiles`, `uploads` | P2 | Creator |
| Insights | `user_insights` | P2 | Insights |
| AI creation | `ai_generations`, `ai_generation_attributions` | P3 | AI generation |
| Royalties | `royalty_periods`, `royalty_usage`, `royalty_statements`, `payouts` | MVP | Rights ledger |
| Live, tickets, commerce | `live_events`, `ticket_tiers`, `tickets`, `merch_products`, `orders`, `order_items`, `tips` | P3 | Live and commerce |
| Audit | `audit_log` | MVP | Platform |

### Key design decisions

1. **OLTP holds state, not events.** Raw listening events go to the event log and the lake. `recent_plays` holds the last 90 days for fast "recently played" queries.
2. **Money is integer minor units** (`*_minor` columns plus ISO-4217 currency). No floats.
3. **Rights are first-class.** A track is playable only if a licence covers the requested right (streaming, offline, karaoke derivative, AI training, AI derivative), the territory, and the date. The `licenses` table carries this, and `track_licenses` links it to tracks. The playback service checks it on every session request.
4. **Gapless metadata in the catalog.** Encoder delay and padding live on the track, so the player can trim exactly.
5. **Embeddings in Postgres at MVP.** `track_embeddings` uses pgvector with an HNSW index. The migration trigger to a dedicated vector engine is in ADR-09.
6. **Polymorphic library.** `library_items` uses `entity_type` plus `entity_id` with no foreign key. Application code validates the reference. This keeps one table for likes, saves, and follows across entity types.
7. **Provenance and consent on AI output.** `ai_generations.provenance` holds the C2PA-style manifest. `ai_generation_attributions` links each contribution to a rights holder and to the consent record (`consent_id`) as evidence.
8. **Creator labelling is enforced by the database.** A check constraint on `uploads` blocks an AI-declared upload from going live without an applied label (verified in the validator).
9. **Personal data is tagged.** Columns that hold personal data are marked `[PII]` in the DDL comments, to support the data map required by DPDP and GDPR.

---

## 3.2 Entity relationships (summary)

```
users ──< user_consents
users ──< devices ──< downloads >── tracks ──< track_renditions
users ──1 user_taste_profiles
users ──< subscriptions ──< subscription_seats >── users     (family / duo)
plans ──< plan_prices
artists >──< tracks (via track_artists) ──> albums
tracks ──< track_licenses >── licenses >── rights_holders
tracks ──1 track_embeddings;  tracks ──< track_tags;  tracks ──< track_fingerprints
tracks ──< lyrics ──< lyric_lines ──< lyric_translations
users ──< playlists ──< playlist_items >── tracks
users ──< library_items (polymorphic)
users ──< recent_plays >── tracks
users ──< assistant_sessions ──< assistant_turns
users ──< context_snapshots
ai_generations ──< ai_generation_attributions >── rights_holders
royalty_periods ──< royalty_usage >── tracks;  royalty_periods ──< royalty_statements ──< payouts
```

---

## 3.3 Retention, deletion, and minimisation

| Data | Stored in | Retention | Deletion trigger and method |
|---|---|---|---|
| Account profile (`users`) | OLTP | Life of account + 30 days | Erasure request: soft-delete (`status = pending_deletion`), 30-day grace, then hard delete with cascade |
| Consent ledger (`user_consents`) | OLTP | Life of account + 5 years (proof of consent) | Retained for legal defence; personal fields minimised after deletion |
| Listening events (raw) | Lake | 13 months; pseudonymised after 90 days | Pseudonym key deleted on erasure, which breaks linkage |
| Recent plays (`recent_plays`) | OLTP | 90 days (monthly partitions dropped) | Partition drop job |
| Assistant transcripts (`assistant_turns.utterance_text`) | OLTP | 30 days | Nightly purge job |
| Voice audio | Not stored | Processed in memory | — |
| Context snapshots (`context_snapshots`) | OLTP | 30 days; H3 resolution 6 only | Nightly purge job; off when consent withdrawn |
| Downloads (`downloads`) | OLTP | Until removed or licence expiry | Expired or revoked entries are removed daily |
| Payments (`payments`) | OLTP | 8 years (tax and accounting, to be confirmed with finance) | Not deleted on erasure; personal fields minimised |
| Royalty ledger | OLTP and lake | 7 years (contractual audit) | Pseudonymous rights-holder IDs only |
| Audit log | OLTP | 2 years | Partition drop |
| Backups | Snapshots | 35 days rolling | Purged automatically; erasure replays on restore |

Data subject requests are tracked in `data_requests` with a `due_at` of 90 days (DPDP) and one month (GDPR). The product targets 30 days for both.

---

## 3.4 Indexing and partitioning

- Lookup indexes on foreign keys used in joins (`playlist_items.track_id`, `track_artists.artist_id`, `downloads(user_id, status)`).
- Trigram GIN indexes on names and titles for fuzzy search fallback (`pg_trgm`). The main search runs in OpenSearch.
- HNSW index on `track_embeddings.embedding` (cosine).
- `recent_plays` is range-partitioned by `played_at` (monthly partitions in production; a default partition for safety).
- `tracks(language)` is a partial index on ready tracks only, which keeps language-filtered catalog browsing fast.
- `track_fingerprints` is keyed by `(hash, track_id, offset_ms)`. In production, a dedicated index service (sharded key-value) replaces the table once the catalog passes about 1M tracks.

---

## 3.5 Event topics (Kafka-compatible)

| Topic | Producer | Key fields | Consumers |
|---|---|---|---|
| `playback.events.v1` | Client via Playback API | session_id, user_key, track_id, event (start, progress, complete, skip, seek), position_ms, context, consent_state | Recs features, royalty usage, analytics, insights |
| `search.events.v1` | Search API | query_hash, language, result_ids, clicked_id | Search ranking, query understanding |
| `recs.impressions.v1` | Recs API | request_id, user_key, item_ids, model_version | Offline evaluation, CTR |
| `recs.feedback.v1` | Client | user_key, track_id, signal (like, dislike, skip, hide_artist, reset) | Recs training |
| `assistant.turns.v1` | Assistant orchestrator | session_id, intent, latency_ms, tool, outcome (no raw text) | Quality monitoring |
| `billing.events.v1` | Billing | subscription_id, event type, plan_id, region | Entitlement cache, finance |
| `catalog.changes.v1` | Catalog | entity type, id, change type | Search index, cache invalidation, recs |
| `rights.usage.v1` | Playback (aggregated) | period, track_id, territory, streams, ms_played | Royalty batch |

Events carry a schema version, an event ID (idempotency key), and a UTC timestamp. Personal data fields are pseudonymous. Consumers check `consent_state`.

---

## 3.6 API list

**Conventions**

- Base URL `https://api.aurasound.in/v1` (regional endpoints later). Versioned paths; breaking changes need a new version.
- JSON, UTF-8. Dates in ISO-8601 UTC. Money as `{amount_minor, currency}`.
- Auth: `Authorization: Bearer <access_token>` (OAuth 2.1, PKCE). Service-to-service calls use mTLS and are not public.
- Pagination: cursor-based (`?cursor=…&limit=…`, max 100), response includes `next_cursor`.
- Errors: RFC 9457 `application/problem+json` with stable `type` codes (e.g., `entitlement.required`, `licence.territory_blocked`, `quota.exceeded`).
- Idempotency: `Idempotency-Key` header required on POST for payments, downloads, and playlist creation.
- Rate limits: per user and per IP, returned in `RateLimit-*` headers.
- Phase codes: MVP, P2, P3.

### 3.6.1 Identity and account

| Method | Path | Purpose | Phase |
|---|---|---|---|
| POST | `/auth/otp/request` | Send OTP to phone (E.164) | MVP |
| POST | `/auth/otp/verify` | Verify OTP; returns access and refresh tokens | MVP |
| POST | `/auth/oidc/{provider}/callback` | Google and Apple sign-in | MVP |
| POST | `/auth/token/refresh` | Rotate refresh token (bound to device) | MVP |
| POST | `/auth/logout` | Revoke session on this device | MVP |
| GET | `/me` | Current user profile and plan summary | MVP |
| PATCH | `/me` | Update display name, locale, country | MVP |
| DELETE | `/me` | Request account erasure (30-day grace) | MVP |
| GET | `/me/consents` | Current consent state per purpose | MVP |
| PUT | `/me/consents/{purpose}` | Grant or withdraw consent (`notice_version` required) | MVP |
| POST | `/me/data-requests` | Access, correction, erasure, grievance, portability | MVP |
| GET | `/me/data-requests/{id}` | Status of a request | MVP |
| GET | `/me/export` | Create portability export (async; signed URL when ready) | MVP |
| POST | `/me/age-verification` | Age declaration; starts parental consent flow when under 18 | MVP |
| PATCH | `/me/privacy` | Activity visibility, personalisation on or off | P2 |
| POST | `/auth/passkeys` | Register a passkey | P2 |

### 3.6.2 Onboarding and taste

| Method | Path | Purpose | Phase |
|---|---|---|---|
| GET | `/onboarding/seeds?languages=hi,te,ta,en` | Artists, genres, and playlists to choose from | MVP |
| PUT | `/me/taste` | Save languages, genres, seed artists | MVP |
| DELETE | `/me/taste` | Reset taste profile (personalisation restarts) | MVP |

### 3.6.3 Devices

| Method | Path | Purpose | Phase |
|---|---|---|---|
| POST | `/devices` | Register device (platform, push token, app version) | MVP |
| GET | `/devices` | List devices | MVP |
| DELETE | `/devices/{id}` | Remove device; revokes its downloads | MVP |

### 3.6.4 Catalog and charts

| Method | Path | Purpose | Phase |
|---|---|---|---|
| GET | `/tracks/{id}` | Metadata, credits, renditions available to the user | MVP |
| GET | `/albums/{id}` | Album with track list | MVP |
| GET | `/artists/{id}` | Artist profile | MVP |
| GET | `/artists/{id}/top-tracks` | Top tracks (region and language aware) | MVP |
| GET | `/artists/{id}/albums` | Discography (cursor) | MVP |
| GET | `/tracks/{id}/similar` | Content-based similar tracks | MVP |
| GET | `/charts?region=IN&language=te` | Regional and language charts | MVP |
| GET | `/tracks/{id}/lyrics?lang=hi&translation=en&transliteration=hi-Latn` | Synced lyrics with translation and transliteration | MVP |
| GET | `/shows/{id}` and `/shows/{id}/episodes` | Podcast show and episodes | P2 |
| GET | `/audiobooks/{id}` | Audiobook metadata and chapters | P2 |

### 3.6.5 Playback

| Method | Path | Purpose | Phase |
|---|---|---|---|
| POST | `/playback/sessions` | Entitlement and rights check; returns manifest URL, DRM licence URLs, quality ladder, expiry, and session ID | MVP |
| POST | `/playback/sessions/{id}/heartbeat` | Every 30 s; keeps concurrent-stream slot; re-checks entitlement | MVP |
| DELETE | `/playback/sessions/{id}` | End session and free the stream slot | MVP |
| POST | `/playback/events` | Batch of listening events (max 200 per call), consent-aware | MVP |
| GET | `/playback/queue` | Server-side queue for multi-device handoff | P2 |
| PUT | `/playback/positions/{type}/{id}` | Save resume position (episode or audiobook) | P2 |

### 3.6.6 Search and recognition

| Method | Path | Purpose | Phase |
|---|---|---|---|
| GET | `/search?q=&types=track,album,artist,playlist&language=` | Full search across scripts | MVP |
| GET | `/search/suggest?q=` | Autocomplete (under 100 ms p95) | MVP |
| POST | `/search/voice` | Voice query (audio up to 10 s); returns transcript and results. Raw audio not stored | MVP |
| POST | `/search/hum` | Hum or sing query (audio 5 to 15 s); returns candidate tracks | MVP (beta) |
| POST | `/recognise` | Fingerprint an audio clip from the environment (up to 15 s) | MVP |

### 3.6.7 Library, playlists, downloads

| Method | Path | Purpose | Phase |
|---|---|---|---|
| GET | `/library?type=track&cursor=` | Liked songs, saved albums, followed artists, shows | MVP |
| PUT | `/library/{type}/{id}` | Save or like (idempotent) | MVP |
| DELETE | `/library/{type}/{id}` | Unsave | MVP |
| GET | `/library/recent` | Recently played (90 days) | MVP |
| POST | `/playlists` | Create playlist (`Idempotency-Key` required) | MVP |
| GET | `/playlists/{id}` | Playlist with items (cursor) | MVP |
| PATCH | `/playlists/{id}` | Title, description, visibility | MVP |
| DELETE | `/playlists/{id}` | Delete playlist | MVP |
| POST | `/playlists/{id}/items` | Add tracks (`position` optional) | MVP |
| PATCH | `/playlists/{id}/items/{position}` | Move item (`to` position) | MVP |
| DELETE | `/playlists/{id}/items/{position}` | Remove item | MVP |
| POST | `/downloads` | Request offline licence for a track and rendition on a device; returns licence blob and expiry | MVP |
| GET | `/downloads?device_id=` | Downloads on a device | MVP |
| POST | `/downloads/{id}/renew` | Re-validate offline licence (online check) | MVP |
| DELETE | `/downloads/{id}` | Revoke and remove | MVP |
| PUT | `/settings/auto-download` | Favourites auto-download rules (Wi-Fi only, storage cap) | MVP (beta) |

### 3.6.8 AI: assistant, playlists, recommendations, context

| Method | Path | Purpose | Phase |
|---|---|---|---|
| POST | `/assistant/sessions` | Start session (`channel`: voice or text; requires consent `voice_processing` for voice) | MVP |
| POST | `/assistant/sessions/{id}/turns` | Send turn (text or audio reference); response streamed over SSE | MVP |
| POST | `/assistant/sessions/{id}/actions/{action_id}/confirm` | Confirm an action that changes the library or account | MVP |
| DELETE | `/assistant/sessions/{id}` | End session; transcript deletion scheduled | MVP |
| POST | `/ai/playlists/drafts` | Prompt-to-playlist: returns a draft (catalog track IDs and rationale) | MVP |
| POST | `/ai/playlists/drafts/{id}/refine` | Refine a draft with follow-up text (P2) | P2 |
| GET | `/home?surface=home&locale=hi-IN` | Home feed (also available through GraphQL) | MVP |
| GET | `/radio/{seed_type}/{seed_id}` | Radio station from seed track, artist, or mood | MVP |
| POST | `/recommendations/feedback` | Like, dislike, skip reason, hide artist, reset | MVP |
| GET | `/recommendations/explain?track_id=` | "Why this song?" reason codes | MVP |
| PUT | `/context/signals` | Coarse context (local hour, activity, weather code, H3 res 6). Requires consent `context_signals` | P2 |
| GET | `/insights/{period}?period_start=` | Monthly or yearly recap (`period`: month or year) | P2 |
| POST | `/insights/{id}/share-card` | Generate share image without personal identifiers | P2 |
| POST | `/karaoke/sessions` | Start karaoke session for licensed track (instrumental stem stream) | P2 |
| POST | `/karaoke/sessions/{id}/score` | Submit pitch and timing summary for scoring | P3 |
| POST | `/ai/generations` | Text-to-song or remix job (`rights_mode` required) | P3 |
| GET | `/ai/generations/{id}` | Job status and output | P3 |
| GET | `/ai/generations/{id}/provenance` | Provenance manifest and watermark ID | P3 |

### 3.6.9 Social

| Method | Path | Purpose | Phase |
|---|---|---|---|
| PUT | `/follows/{user_id}` | Follow a user (idempotent) | P2 |
| DELETE | `/follows/{user_id}` | Unfollow | P2 |
| GET | `/friends/activity` | Friends' now-playing and recent activity (privacy-filtered) | P2 |
| POST | `/rooms` | Create listening room | P2 |
| POST | `/rooms/join` | Join by 6-character code | P2 |
| POST | `/rooms/{id}/queue` | Add track to shared queue | P2 |
| WS | `/rooms/{id}/ws` | Real-time room state and playback sync | P2 |
| POST | `/rooms/{id}/end` | End room (host) | P2 |

### 3.6.10 Creator Hub

| Method | Path | Purpose | Phase |
|---|---|---|---|
| POST | `/creators/profile` | Apply for creator access (KYC starts) | P2 |
| GET | `/creators/profile` | Creator profile and KYC status | P2 |
| POST | `/creator/uploads` | Create upload: metadata, rights attestation, AI-generated declaration; returns signed multipart URLs | P2 |
| POST | `/creator/uploads/{id}/complete` | Finish upload and start processing | P2 |
| GET | `/creator/uploads/{id}` | Processing and review status | P2 |
| GET | `/creator/analytics?from=&to=&granularity=` | Streams, listeners, cities, saves | P2 |
| GET | `/creator/royalties/statements` | Statements and line items | P2 |
| GET | `/creator/payouts` | Payout history | P2 |
| POST | `/tips` | Tip an artist (`Idempotency-Key`) | P3 |

### 3.6.11 Billing and subscriptions

| Method | Path | Purpose | Phase |
|---|---|---|---|
| GET | `/plans?region=IN` | Plans and regional prices | MVP |
| POST | `/subscriptions/checkout` | Start checkout (`provider`: razorpay, stripe, or store) | MVP |
| POST | `/subscriptions/receipts/apple` | Validate App Store transaction (server-to-server verified) | MVP |
| POST | `/subscriptions/receipts/google` | Validate Google Play purchase token | MVP |
| GET | `/subscriptions/current` | Current plan, status, renewal date, seats | MVP |
| POST | `/subscriptions/{id}/cancel` | Cancel at period end | MVP |
| POST | `/subscriptions/{id}/seats` | Invite family or duo member | MVP |
| DELETE | `/subscriptions/{id}/seats/{user_id}` | Remove seat | MVP |
| POST | `/webhooks/razorpay` | Provider webhook (HMAC verified, idempotent) | MVP |
| POST | `/webhooks/stripe` | Provider webhook (signature verified) | MVP |
| POST | `/webhooks/apple` | App Store Server Notifications v2 | MVP |
| POST | `/webhooks/google` | Google Play real-time developer notifications | MVP |

### 3.6.12 Live, tickets, commerce (P3)

| Method | Path | Purpose | Phase |
|---|---|---|---|
| GET | `/live/events?city=&artist_id=` | Upcoming events and livestreams | P3 |
| GET | `/live/events/{id}/stream` | Low-latency live manifest (entitlement checked) | P3 |
| POST | `/tickets/orders` | Hold tickets and create payment intent (`Idempotency-Key`) | P3 |
| GET | `/tickets/me` | My tickets (rotating QR token) | P3 |
| POST | `/tickets/{id}/transfer` | Transfer to another user (logged) | P3 |
| GET | `/merch/products?artist_id=` | Merchandise catalog | P3 |
| POST | `/merch/orders` | Create order | P3 |
| GET | `/fan-clubs/{artist_id}` | Fan club info and tiers | P3 |
| POST | `/fan-clubs/{artist_id}/join` | Join fan club | P3 |

### 3.6.13 Internal APIs (not public)

| Area | Examples | Access |
|---|---|---|
| Catalog ingest | `POST /internal/ingest/jobs`, `GET /internal/ingest/jobs/{id}` | Ops role, SSO and MFA |
| Rights | `POST /internal/licences`, `POST /internal/takedowns` | Rights team |
| Royalties | `POST /internal/royalty-periods/{id}/close`, `GET /internal/royalty-periods/{id}/reconciliation` | Finance, four-eyes approval |
| Moderation | `POST /internal/moderation/actions` | Trust and safety |
| Feature flags and experiments | Managed through OpenFeature provider; no public endpoint | Product and engineering |

---

## 3.7 GraphQL schema (BFF) — outline

The BFF exposes one GraphQL endpoint (`/graphql`). Clients use persisted queries, so only pre-approved query shapes run in production.

```graphql
type Query {
  me: Me!
  home(surface: Surface = HOME, locale: String!): HomeFeed!     # MVP
  search(q: String!, types: [SearchType!], language: String): SearchResult!   # MVP
  track(id: ID!): Track                                         # MVP
  album(id: ID!): Album                                         # MVP
  artist(id: ID!): Artist                                       # MVP
  playlist(id: ID!): Playlist                                   # MVP
  nowPlaying: NowPlaying                                        # P2 (friends and rooms)
}

type Mutation {
  savePlaylistDraft(draftId: ID!, title: String!): Playlist!    # MVP
  setTaste(input: TasteInput!): Me!                              # MVP
  reportRecommendationFeedback(input: FeedbackInput!): Boolean!  # MVP
}

type Subscription {
  roomState(roomId: ID!): RoomState!                             # P2 (over WebSocket)
}
```

---

## 3.8 Versioning and compatibility

- REST: additive changes are allowed within `/v1`. Removing fields or changing types needs `/v2` and a 6-month deprecation window.
- GraphQL: deprecate fields with `@deprecated`; mobile clients use persisted queries, so the team tracks usage before removal.
- Event schemas: Avro or Protobuf with compatibility mode `BACKWARD` in the registry.
- Mobile app: minimum supported version enforced by the API (`426 Upgrade Required` with a problem type) for breaking changes only.
