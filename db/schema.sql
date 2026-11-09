-- =============================================================================
-- AuraSound — PostgreSQL 16 schema (system of record for OLTP data)
--
-- Scope:
--   * MVP tables are unmarked.
--   * "-- [P2]" = Phase 2 (social, creator, podcasts/audiobooks, insights)
--   * "-- [P3]" = Phase 3 (live/ticketing, merch, AI creation)
--
-- Not stored here (by design):
--   * Raw listening events        -> event stream -> data lake (Iceberg/Parquet)
--   * Audio bytes / lyric masters -> object storage (S3/GCS), referenced by URI
--   * Offline decryption keys     -> device secure enclave / Android Keystore
--   * Payment card data           -> provider vault only (PCI scope minimised)
--
-- Conventions:
--   * UUID primary keys (gen_random_uuid()), timestamptz everywhere (UTC).
--   * Money stored as integer minor units + ISO-4217 currency code.
--   * Enumerations are TEXT + CHECK (easy to extend with a migration).
--   * Polymorphic references (e.g. library_likes.entity_id) carry no FK and are
--     validated in the application layer.
--   * Personal data is minimised and tagged in comments with [PII] for DPDP/GDPR
--     data-mapping; deletion flows are described in docs/03-data-model-and-api.md.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS vector;     -- pgvector: embeddings (MVP scale); see docs/02
CREATE EXTENSION IF NOT EXISTS pg_trgm;    -- fuzzy text search on titles/names

-- -----------------------------------------------------------------------------
-- 1. Identity, consent, devices
-- -----------------------------------------------------------------------------
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email           TEXT,                                   -- [PII]
    phone_e164      TEXT,                                   -- [PII] e.g. +919876543210
    display_name    TEXT NOT NULL,                          -- [PII]
    country_code    CHAR(2) NOT NULL DEFAULT 'IN',          -- ISO-3166-1 alpha-2
    locale          TEXT NOT NULL DEFAULT 'en',             -- BCP-47, e.g. hi-IN, te-IN, ta-IN
    status          TEXT NOT NULL DEFAULT 'active'
                    CHECK (status IN ('active', 'suspended', 'pending_deletion', 'deleted')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    deleted_at      TIMESTAMPTZ,
    CHECK (email IS NOT NULL OR phone_e164 IS NOT NULL)
);
CREATE UNIQUE INDEX users_email_lower_uq ON users (lower(email)) WHERE email IS NOT NULL;
CREATE UNIQUE INDEX users_phone_uq ON users (phone_e164) WHERE phone_e164 IS NOT NULL;

-- DPDP/GDPR consent ledger: append-only; the latest row per purpose is current.
CREATE TABLE user_consents (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    purpose         TEXT NOT NULL
                    CHECK (purpose IN ('core_service', 'personalisation', 'analytics',
                                       'marketing', 'voice_processing', 'context_signals',
                                       'ai_training_opt_in', 'third_party_sharing')),
    granted         BOOLEAN NOT NULL,
    notice_version  TEXT NOT NULL,                          -- which privacy notice text was shown
    channel         TEXT NOT NULL CHECK (channel IN ('app', 'web', 'api', 'consent_manager')),
    recorded_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX user_consents_latest_idx ON user_consents (user_id, purpose, recorded_at DESC);

-- Data-principal rights requests (DPDP: respond within 90 days; GDPR: one month).
CREATE TABLE data_requests (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    request_type    TEXT NOT NULL
                    CHECK (request_type IN ('access', 'correction', 'erasure', 'grievance', 'nomination', 'portability')),
    status          TEXT NOT NULL DEFAULT 'open'
                    CHECK (status IN ('open', 'in_progress', 'completed', 'rejected')),
    requested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    due_at          TIMESTAMPTZ NOT NULL,
    completed_at    TIMESTAMPTZ
);

CREATE TABLE devices (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    platform        TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web', 'desktop',
                                                      'wear_os', 'watchos', 'android_auto',
                                                      'carplay', 'speaker')),
    push_token      TEXT,                                   -- [PII]-adjacent; rotate on refresh
    app_version     TEXT,
    last_seen_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX devices_user_idx ON devices (user_id);

-- Quick taste profile captured during onboarding; refined by the recommender.
CREATE TABLE user_taste_profiles (
    user_id         UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    languages       TEXT[] NOT NULL DEFAULT '{}',           -- e.g. {'hi','te','en'}
    genres          TEXT[] NOT NULL DEFAULT '{}',
    seed_artist_ids UUID[] NOT NULL DEFAULT '{}',
    mood_prefs      JSONB NOT NULL DEFAULT '{}'::jsonb,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 2. Plans and subscriptions
-- -----------------------------------------------------------------------------
CREATE TABLE plans (
    id              TEXT PRIMARY KEY,                       -- 'free', 'premium_individual', ...
    tier            TEXT NOT NULL CHECK (tier IN ('free', 'premium_individual', 'premium_family',
                                                  'premium_student', 'premium_duo')),
    max_seats       SMALLINT NOT NULL DEFAULT 1 CHECK (max_seats BETWEEN 1 AND 6),
    hires_allowed   BOOLEAN NOT NULL DEFAULT FALSE,
    offline_allowed BOOLEAN NOT NULL DEFAULT FALSE,
    active          BOOLEAN NOT NULL DEFAULT TRUE
);

-- Regional price book (India-friendly pricing is a row, not a code change).
CREATE TABLE plan_prices (
    plan_id         TEXT NOT NULL REFERENCES plans (id),
    region          CHAR(2) NOT NULL,                       -- 'IN', 'US', ...
    currency        CHAR(3) NOT NULL,
    price_minor     BIGINT NOT NULL CHECK (price_minor >= 0),
    billing_period  TEXT NOT NULL CHECK (billing_period IN ('month', 'year')),
    valid_from      DATE NOT NULL,
    PRIMARY KEY (plan_id, region, billing_period, valid_from)
);

CREATE TABLE subscriptions (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id        UUID NOT NULL REFERENCES users (id),
    plan_id              TEXT NOT NULL REFERENCES plans (id),
    status               TEXT NOT NULL CHECK (status IN ('trialing', 'active', 'past_due',
                                                         'grace', 'canceled', 'expired')),
    billing_provider     TEXT NOT NULL CHECK (billing_provider IN ('apple', 'google', 'razorpay',
                                                                   'stripe', 'upi_autopay', 'manual')),
    provider_ref         TEXT NOT NULL,
    current_period_start TIMESTAMPTZ NOT NULL,
    current_period_end   TIMESTAMPTZ NOT NULL,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (billing_provider, provider_ref)
);
CREATE INDEX subscriptions_owner_idx ON subscriptions (owner_user_id);

-- Family / duo seats. Each member keeps their own library and taste profile.
CREATE TABLE subscription_seats (
    subscription_id UUID NOT NULL REFERENCES subscriptions (id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role            TEXT NOT NULL CHECK (role IN ('owner', 'member')),
    added_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (subscription_id, user_id)
);
CREATE UNIQUE INDEX subscription_seats_one_active_per_user
    ON subscription_seats (user_id);  -- a user holds one premium seat at a time

CREATE TABLE payments (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id   UUID REFERENCES subscriptions (id),
    user_id           UUID NOT NULL REFERENCES users (id),
    amount_minor      BIGINT NOT NULL CHECK (amount_minor >= 0),
    currency          CHAR(3) NOT NULL,
    status            TEXT NOT NULL CHECK (status IN ('pending', 'succeeded', 'failed', 'refunded')),
    provider_ref      TEXT NOT NULL UNIQUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 3. Catalog: artists, albums, tracks, renditions, rights
-- -----------------------------------------------------------------------------
CREATE TABLE artists (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            TEXT NOT NULL,
    sort_name       TEXT NOT NULL,
    country_code    CHAR(2),
    bio             TEXT,
    is_verified     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX artists_name_trgm_idx ON artists USING gin (name gin_trgm_ops);

CREATE TABLE albums (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL,
    album_type      TEXT NOT NULL DEFAULT 'album'
                    CHECK (album_type IN ('album', 'single', 'ep', 'compilation')),
    primary_artist_id UUID REFERENCES artists (id),
    release_date    DATE,
    upc             TEXT UNIQUE,
    cover_uri       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX albums_title_trgm_idx ON albums USING gin (title gin_trgm_ops);

CREATE TABLE tracks (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL,
    album_id        UUID REFERENCES albums (id),
    duration_ms     INTEGER NOT NULL CHECK (duration_ms > 0),
    isrc            CHAR(12) UNIQUE,
    language        TEXT NOT NULL DEFAULT 'und',            -- BCP-47; 'hi', 'te', 'ta', 'en', 'zxx' (instrumental)
    genres          TEXT[] NOT NULL DEFAULT '{}',
    is_explicit     BOOLEAN NOT NULL DEFAULT FALSE,
    status          TEXT NOT NULL DEFAULT 'processing'
                    CHECK (status IN ('processing', 'ready', 'blocked', 'takedown')),
    -- Gapless metadata: encoder delay/padding so the player can trim silence exactly.
    encoder_delay_samples INTEGER NOT NULL DEFAULT 0,
    encoder_padding_samples INTEGER NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX tracks_album_idx ON tracks (album_id);
CREATE INDEX tracks_title_trgm_idx ON tracks USING gin (title gin_trgm_ops);
CREATE INDEX tracks_language_idx ON tracks (language) WHERE status = 'ready';

CREATE TABLE track_artists (
    track_id        UUID NOT NULL REFERENCES tracks (id) ON DELETE CASCADE,
    artist_id       UUID NOT NULL REFERENCES artists (id),
    role            TEXT NOT NULL CHECK (role IN ('primary', 'featured', 'composer', 'lyricist', 'producer')),
    PRIMARY KEY (track_id, artist_id, role)
);
CREATE INDEX track_artists_artist_idx ON track_artists (artist_id);

-- One row per encoded rendition (codec x bitrate). Manifests are generated per track.
CREATE TABLE track_renditions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    track_id        UUID NOT NULL REFERENCES tracks (id) ON DELETE CASCADE,
    codec           TEXT NOT NULL CHECK (codec IN ('aac', 'opus', 'flac', 'alac')),
    bitrate_kbps    INTEGER NOT NULL CHECK (bitrate_kbps > 0),
    sample_rate_hz  INTEGER NOT NULL CHECK (sample_rate_hz > 0),
    bit_depth       SMALLINT CHECK (bit_depth IN (16, 24)),
    container       TEXT NOT NULL CHECK (container IN ('cmaf', 'hls_ts', 'adts')),
    drm_scheme      TEXT NOT NULL DEFAULT 'widevine_playready_fairplay'
                    CHECK (drm_scheme IN ('none', 'widevine_playready_fairplay')),
    storage_uri     TEXT NOT NULL,                          -- s3://... (encrypted at rest)
    manifest_uri    TEXT,                                   -- HLS/DASH master playlist
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (track_id, codec, bitrate_kbps)
);

-- Rights holders: labels, publishers, PROs, distributors, independent artists.
CREATE TABLE rights_holders (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name              TEXT NOT NULL,
    holder_type       TEXT NOT NULL CHECK (holder_type IN ('label', 'publisher', 'pro', 'distributor',
                                                           'independent_artist', 'aggregator')),
    country_code      CHAR(2),
    payout_account_ref TEXT,                                -- [PII]-adjacent; vault reference only
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE licenses (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rights_holder_id UUID NOT NULL REFERENCES rights_holders (id),
    rights_type     TEXT NOT NULL CHECK (rights_type IN ('streaming', 'download', 'offline',
                                                         'karaoke_derivative', 'ai_training',
                                                         'ai_derivative', 'live_stream', 'sync')),
    territories     CHAR(2)[] NOT NULL,                     -- ISO-3166 alpha-2 list, or {'WW'}
    starts_on       DATE NOT NULL,
    ends_on         DATE,
    royalty_terms   JSONB NOT NULL DEFAULT '{}'::jsonb,     -- rate card / revenue-share reference
    contract_ref    TEXT,
    CHECK (ends_on IS NULL OR ends_on > starts_on)
);

CREATE TABLE track_licenses (
    track_id        UUID NOT NULL REFERENCES tracks (id) ON DELETE CASCADE,
    license_id      UUID NOT NULL REFERENCES licenses (id),
    PRIMARY KEY (track_id, license_id)
);

-- -----------------------------------------------------------------------------
-- 4. Intelligence: embeddings, tags, fingerprints, lyrics
-- -----------------------------------------------------------------------------
-- Content embeddings drive content-based and hum/sing retrieval. Versioned by model.
CREATE TABLE track_embeddings (
    track_id        UUID PRIMARY KEY REFERENCES tracks (id) ON DELETE CASCADE,
    model_version   TEXT NOT NULL,
    embedding       VECTOR(256) NOT NULL,
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX track_embeddings_hnsw ON track_embeddings USING hnsw (embedding vector_cosine_ops);

CREATE TABLE track_tags (
    track_id        UUID NOT NULL REFERENCES tracks (id) ON DELETE CASCADE,
    tag_type        TEXT NOT NULL CHECK (tag_type IN ('mood', 'activity', 'genre', 'instrument',
                                                      'tempo_bucket', 'energy', 'context')),
    tag             TEXT NOT NULL,
    score           REAL NOT NULL CHECK (score BETWEEN 0 AND 1),
    source          TEXT NOT NULL CHECK (source IN ('model', 'editorial', 'artist')),
    model_version   TEXT,
    PRIMARY KEY (track_id, tag_type, tag, source)
);
CREATE INDEX track_tags_lookup_idx ON track_tags (tag_type, tag, score DESC);

-- Audio fingerprint landmarks for recognition (Shazam-style). One row per landmark hash.
CREATE TABLE track_fingerprints (
    hash            BIGINT NOT NULL,
    track_id        UUID NOT NULL REFERENCES tracks (id) ON DELETE CASCADE,
    offset_ms       INTEGER NOT NULL CHECK (offset_ms >= 0),
    PRIMARY KEY (hash, track_id, offset_ms)
);
-- In production this lives in a dedicated index service (sharded KV); the table is the
-- reference / small-catalog implementation and is used by the contract tests.

CREATE TABLE lyrics (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    track_id        UUID NOT NULL REFERENCES tracks (id) ON DELETE CASCADE,
    language        TEXT NOT NULL,                          -- original language/script of the lyric
    script          TEXT CHECK (script IN ('Latn', 'Deva', 'Telu', 'Taml', 'Arab', 'Other')),
    is_synced       BOOLEAN NOT NULL DEFAULT FALSE,
    source          TEXT NOT NULL CHECK (source IN ('licensed_provider', 'artist', 'community', 'ai_transcribed')),
    license_id      UUID REFERENCES licenses (id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (track_id, language, source)
);

CREATE TABLE lyric_lines (
    lyric_id        UUID NOT NULL REFERENCES lyrics (id) ON DELETE CASCADE,
    line_no         INTEGER NOT NULL CHECK (line_no >= 1),
    start_ms        INTEGER CHECK (start_ms IS NULL OR start_ms >= 0),
    end_ms          INTEGER CHECK (end_ms IS NULL OR end_ms >= start_ms),
    text            TEXT NOT NULL,
    PRIMARY KEY (lyric_id, line_no)
);

-- Translation and transliteration are separate rows so each can be reviewed/versioned.
CREATE TABLE lyric_translations (
    lyric_id        UUID NOT NULL REFERENCES lyrics (id) ON DELETE CASCADE,
    line_no         INTEGER NOT NULL,
    target_language TEXT NOT NULL,                          -- 'en', 'hi-Latn', 'te-Latn', ...
    kind            TEXT NOT NULL CHECK (kind IN ('translation', 'transliteration')),
    text            TEXT NOT NULL,
    model_version   TEXT,
    reviewed_by     UUID REFERENCES users (id),             -- human review for editorial quality
    PRIMARY KEY (lyric_id, line_no, target_language, kind),
    FOREIGN KEY (lyric_id, line_no) REFERENCES lyric_lines (lyric_id, line_no) ON DELETE CASCADE
);

-- -----------------------------------------------------------------------------
-- 5. Library, playlists, downloads, history
-- -----------------------------------------------------------------------------
CREATE TABLE playlists (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id   UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    description     TEXT,
    visibility      TEXT NOT NULL DEFAULT 'private'
                    CHECK (visibility IN ('private', 'unlisted', 'public', 'collaborative')),
    source          TEXT NOT NULL DEFAULT 'user'
                    CHECK (source IN ('user', 'ai_prompt', 'editorial', 'system')),
    prompt_text     TEXT,                                   -- for prompt-to-playlist (user-owned text)
    model_version   TEXT,
    cover_uri       TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX playlists_owner_idx ON playlists (owner_user_id, updated_at DESC);

CREATE TABLE playlist_items (
    playlist_id     UUID NOT NULL REFERENCES playlists (id) ON DELETE CASCADE,
    position        INTEGER NOT NULL CHECK (position >= 0),
    track_id        UUID NOT NULL REFERENCES tracks (id),
    added_by        UUID REFERENCES users (id),
    added_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (playlist_id, position)
);
CREATE INDEX playlist_items_track_idx ON playlist_items (track_id);

-- Liked songs, saved albums/artists, followed shows, etc. Polymorphic (no FK on entity_id).
CREATE TABLE library_items (
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    entity_type     TEXT NOT NULL CHECK (entity_type IN ('track', 'album', 'artist', 'playlist',
                                                         'show', 'episode', 'audiobook')),
    entity_id       UUID NOT NULL,
    saved_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, entity_type, entity_id)
);

-- Offline downloads: the server tracks entitlement and revocation only.
-- Decryption keys never leave the device keystore.
CREATE TABLE downloads (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    device_id       UUID NOT NULL REFERENCES devices (id) ON DELETE CASCADE,
    track_id        UUID NOT NULL REFERENCES tracks (id),
    rendition_id    UUID NOT NULL REFERENCES track_renditions (id),
    status          TEXT NOT NULL DEFAULT 'queued'
                    CHECK (status IN ('queued', 'downloading', 'complete', 'failed', 'revoked')),
    license_expires_at TIMESTAMPTZ NOT NULL,                -- must re-validate online before expiry
    bytes           BIGINT CHECK (bytes IS NULL OR bytes >= 0),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (device_id, track_id)
);
CREATE INDEX downloads_user_idx ON downloads (user_id, status);

-- Recent plays for "recently played" and instant recommendations. Full history goes to the lake.
CREATE TABLE recent_plays (
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    played_at       TIMESTAMPTZ NOT NULL,
    track_id        UUID NOT NULL REFERENCES tracks (id),
    context_type    TEXT CHECK (context_type IN ('playlist', 'album', 'artist', 'search',
                                                 'radio', 'ai_dj', 'room', 'library', 'other')),
    context_id      UUID,
    ms_played       INTEGER NOT NULL DEFAULT 0 CHECK (ms_played >= 0),
    PRIMARY KEY (user_id, played_at, track_id)
) PARTITION BY RANGE (played_at);
CREATE TABLE recent_plays_default PARTITION OF recent_plays DEFAULT;
-- Monthly partitions are created by a scheduled job; 90-day retention (see docs/03).

-- -----------------------------------------------------------------------------
-- 6. Podcasts and audiobooks [P2]
-- -----------------------------------------------------------------------------
CREATE TABLE shows (                                        -- [P2]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL,
    publisher       TEXT,
    language        TEXT NOT NULL DEFAULT 'und',
    rss_feed_url    TEXT UNIQUE,
    is_explicit     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE episodes (                                     -- [P2]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    show_id         UUID NOT NULL REFERENCES shows (id) ON DELETE CASCADE,
    title           TEXT NOT NULL,
    duration_ms     INTEGER NOT NULL CHECK (duration_ms > 0),
    published_at    TIMESTAMPTZ NOT NULL,
    audio_uri       TEXT NOT NULL,
    transcript_uri  TEXT
);
CREATE INDEX episodes_show_idx ON episodes (show_id, published_at DESC);

CREATE TABLE audiobooks (                                   -- [P2]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title           TEXT NOT NULL,
    author          TEXT NOT NULL,
    narrator        TEXT,
    language        TEXT NOT NULL DEFAULT 'und',
    duration_ms     BIGINT NOT NULL CHECK (duration_ms > 0),
    chapters        JSONB NOT NULL DEFAULT '[]'::jsonb,     -- [{title, start_ms}]
    license_id      UUID REFERENCES licenses (id)
);

-- Resume positions for audiobooks and podcasts (cross-device sync).
CREATE TABLE playback_positions (                           -- [P2]
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    entity_type     TEXT NOT NULL CHECK (entity_type IN ('episode', 'audiobook')),
    entity_id       UUID NOT NULL,
    position_ms     INTEGER NOT NULL CHECK (position_ms >= 0),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, entity_type, entity_id)
);

-- -----------------------------------------------------------------------------
-- 7. Social [P2]
-- -----------------------------------------------------------------------------
CREATE TABLE follows (                                      -- [P2]
    follower_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    followee_id     UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (follower_id, followee_id),
    CHECK (follower_id <> followee_id)
);

-- Friend activity respects per-user privacy settings (friends / private / off).
CREATE TABLE activity_events (                              -- [P2]
    id              BIGSERIAL PRIMARY KEY,
    actor_user_id   UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    event_type      TEXT NOT NULL CHECK (event_type IN ('now_playing', 'liked', 'playlist_created',
                                                        'room_joined', 'recap_shared')),
    payload         JSONB NOT NULL DEFAULT '{}'::jsonb,
    visibility      TEXT NOT NULL DEFAULT 'friends' CHECK (visibility IN ('private', 'friends', 'public')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX activity_events_actor_idx ON activity_events (actor_user_id, created_at DESC);

CREATE TABLE listening_rooms (                              -- [P2]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    host_user_id    UUID NOT NULL REFERENCES users (id),
    name            TEXT NOT NULL,
    join_code       CHAR(6) NOT NULL UNIQUE,
    status          TEXT NOT NULL DEFAULT 'live' CHECK (status IN ('live', 'ended')),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at        TIMESTAMPTZ
);

CREATE TABLE room_members (                                 -- [P2]
    room_id         UUID NOT NULL REFERENCES listening_rooms (id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    role            TEXT NOT NULL CHECK (role IN ('host', 'cohost', 'listener')),
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (room_id, user_id)
);

CREATE TABLE shared_queue_items (                           -- [P2]
    id              BIGSERIAL PRIMARY KEY,
    room_id         UUID NOT NULL REFERENCES listening_rooms (id) ON DELETE CASCADE,
    track_id        UUID NOT NULL REFERENCES tracks (id),
    added_by        UUID NOT NULL REFERENCES users (id),
    position        INTEGER NOT NULL,
    added_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (room_id, position)
);

-- -----------------------------------------------------------------------------
-- 8. Creator hub [P2]
-- -----------------------------------------------------------------------------
CREATE TABLE creator_profiles (                             -- [P2]
    user_id         UUID PRIMARY KEY REFERENCES users (id) ON DELETE CASCADE,
    artist_id       UUID REFERENCES artists (id),
    kyc_status      TEXT NOT NULL DEFAULT 'pending' CHECK (kyc_status IN ('pending', 'verified', 'rejected')),
    payout_account_ref TEXT,                                -- vault reference only
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE uploads (                                      -- [P2]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_user_id UUID NOT NULL REFERENCES users (id),
    track_id        UUID REFERENCES tracks (id),
    status          TEXT NOT NULL DEFAULT 'received'
                    CHECK (status IN ('received', 'processing', 'review', 'rejected', 'live')),
    declared_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,   -- creator self-declaration
    ai_label_applied      BOOLEAN NOT NULL DEFAULT FALSE,   -- platform label shown to listeners
    rights_attestation_at TIMESTAMPTZ NOT NULL,             -- creator attests rights at upload
    submitted_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (NOT declared_ai_generated OR ai_label_applied OR status IN ('received', 'processing', 'review', 'rejected'))
);

-- -----------------------------------------------------------------------------
-- 9. AI features
-- -----------------------------------------------------------------------------
-- Assistant sessions. Raw voice audio is NOT stored; transcripts are kept 30 days.
CREATE TABLE assistant_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    channel         TEXT NOT NULL CHECK (channel IN ('voice', 'text')),
    locale          TEXT NOT NULL,
    started_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at        TIMESTAMPTZ
);

CREATE TABLE assistant_turns (
    id              BIGSERIAL PRIMARY KEY,
    session_id      UUID NOT NULL REFERENCES assistant_sessions (id) ON DELETE CASCADE,
    role            TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'tool')),
    intent          TEXT,                                   -- e.g. 'play_mood', 'create_playlist', 'lyrics_query'
    utterance_text  TEXT,                                   -- [PII] possibly; 30-day retention
    tool_calls      JSONB NOT NULL DEFAULT '[]'::jsonb,
    latency_ms      INTEGER CHECK (latency_ms IS NULL OR latency_ms >= 0),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX assistant_turns_session_idx ON assistant_turns (session_id, id);

-- Coarse context signals for the Smart Mood & Context Engine. Coarse only (H3 res 6),
-- opt-in via consent purpose 'context_signals', 30-day retention. Never precise GPS.
CREATE TABLE context_snapshots (
    id              BIGSERIAL PRIMARY KEY,
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    captured_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    local_hour      SMALLINT NOT NULL CHECK (local_hour BETWEEN 0 AND 23),
    activity        TEXT CHECK (activity IN ('still', 'walking', 'running', 'driving', 'cycling', 'unknown')),
    weather_code    TEXT,
    h3_cell_res6    TEXT                                    -- [PII]-adjacent, coarse
);
CREATE INDEX context_snapshots_user_idx ON context_snapshots (user_id, captured_at DESC);

-- Generated-music provenance. Every output is watermarked and carries a manifest.
CREATE TABLE ai_generations (                               -- [P3] for text_to_song; remix/stems in [P2]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    kind            TEXT NOT NULL CHECK (kind IN ('text_to_song', 'remix', 'stem_separation', 'karaoke_session')),
    prompt_text     TEXT,
    model_id        TEXT NOT NULL,                          -- must be a licensed-data model (see docs/05)
    status          TEXT NOT NULL DEFAULT 'queued'
                    CHECK (status IN ('queued', 'running', 'complete', 'failed', 'blocked_by_policy')),
    output_track_id UUID REFERENCES tracks (id),
    watermark_id    TEXT,                                   -- inaudible watermark payload
    provenance      JSONB NOT NULL DEFAULT '{}'::jsonb,     -- C2PA-style manifest
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Attribution: who contributed to an AI output and how much of the credit/royalty pool they get.
CREATE TABLE ai_generation_attributions (                   -- [P3]
    generation_id   UUID NOT NULL REFERENCES ai_generations (id) ON DELETE CASCADE,
    rights_holder_id UUID NOT NULL REFERENCES rights_holders (id),
    contribution    TEXT NOT NULL CHECK (contribution IN ('style_reference', 'voice_likeness',
                                                          'composition', 'stem_source', 'sample')),
    share_bps       INTEGER NOT NULL CHECK (share_bps BETWEEN 0 AND 10000),
    consent_id      BIGINT REFERENCES user_consents (id),   -- opt-in evidence
    PRIMARY KEY (generation_id, rights_holder_id, contribution)
);

-- Personal listening insights (monthly / yearly recap). Stats are computed; text is LLM-written.
CREATE TABLE user_insights (                                -- [P2]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    period_type     TEXT NOT NULL CHECK (period_type IN ('month', 'year')),
    period_start    DATE NOT NULL,
    stats           JSONB NOT NULL,
    summary_text    TEXT,
    generated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, period_type, period_start)
);

-- -----------------------------------------------------------------------------
-- 10. Royalties and payouts (ledger)
-- -----------------------------------------------------------------------------
CREATE TABLE royalty_periods (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    period_start    DATE NOT NULL,
    period_end      DATE NOT NULL,
    status          TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'closed', 'paid')),
    pool_minor      BIGINT NOT NULL DEFAULT 0 CHECK (pool_minor >= 0),   -- revenue pool to distribute
    currency        CHAR(3) NOT NULL,
    CHECK (period_end > period_start),
    UNIQUE (period_start, period_end)
);

-- Usage aggregated per period x track x territory (pro-rata or user-centric method).
CREATE TABLE royalty_usage (
    period_id       UUID NOT NULL REFERENCES royalty_periods (id),
    track_id        UUID NOT NULL REFERENCES tracks (id),
    territory       CHAR(2) NOT NULL,
    streams         BIGINT NOT NULL DEFAULT 0 CHECK (streams >= 0),
    ms_played       BIGINT NOT NULL DEFAULT 0 CHECK (ms_played >= 0),
    weighted_units  NUMERIC(20, 4) NOT NULL DEFAULT 0,      -- method-dependent weighting
    PRIMARY KEY (period_id, track_id, territory)
);

CREATE TABLE royalty_statements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    period_id       UUID NOT NULL REFERENCES royalty_periods (id),
    rights_holder_id UUID NOT NULL REFERENCES rights_holders (id),
    amount_minor    BIGINT NOT NULL CHECK (amount_minor >= 0),
    currency        CHAR(3) NOT NULL,
    statement_uri   TEXT,
    UNIQUE (period_id, rights_holder_id)
);

CREATE TABLE payouts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    statement_id    UUID NOT NULL REFERENCES royalty_statements (id),
    amount_minor    BIGINT NOT NULL CHECK (amount_minor >= 0),
    status          TEXT NOT NULL DEFAULT 'scheduled'
                    CHECK (status IN ('scheduled', 'sent', 'failed', 'returned')),
    provider_ref    TEXT,
    paid_at         TIMESTAMPTZ
);

-- -----------------------------------------------------------------------------
-- 11. Live, ticketing, merch [P3]
-- -----------------------------------------------------------------------------
CREATE TABLE live_events (                                  -- [P3]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    artist_id       UUID NOT NULL REFERENCES artists (id),
    event_type      TEXT NOT NULL CHECK (event_type IN ('concert', 'livestream', 'virtual_concert')),
    title           TEXT NOT NULL,
    venue_name      TEXT,
    city            TEXT,
    country_code    CHAR(2),
    starts_at       TIMESTAMPTZ NOT NULL,
    status          TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'live', 'ended', 'cancelled'))
);
CREATE INDEX live_events_starts_idx ON live_events (starts_at);

CREATE TABLE ticket_tiers (                                 -- [P3]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id        UUID NOT NULL REFERENCES live_events (id) ON DELETE CASCADE,
    name            TEXT NOT NULL,
    price_minor     BIGINT NOT NULL CHECK (price_minor >= 0),
    currency        CHAR(3) NOT NULL,
    quantity_total  INTEGER NOT NULL CHECK (quantity_total >= 0),
    quantity_sold   INTEGER NOT NULL DEFAULT 0 CHECK (quantity_sold >= 0),
    CHECK (quantity_sold <= quantity_total)
);

CREATE TABLE tickets (                                      -- [P3]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tier_id         UUID NOT NULL REFERENCES ticket_tiers (id),
    owner_user_id   UUID NOT NULL REFERENCES users (id),
    status          TEXT NOT NULL DEFAULT 'issued'
                    CHECK (status IN ('issued', 'transferred', 'refunded', 'checked_in', 'void')),
    qr_secret_hash  TEXT NOT NULL,                          -- never store the QR secret itself
    purchased_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE merch_products (                               -- [P3]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    artist_id       UUID NOT NULL REFERENCES artists (id),
    sku             TEXT NOT NULL UNIQUE,
    title           TEXT NOT NULL,
    price_minor     BIGINT NOT NULL CHECK (price_minor >= 0),
    currency        CHAR(3) NOT NULL,
    stock           INTEGER NOT NULL DEFAULT 0 CHECK (stock >= 0)
);

CREATE TABLE orders (                                       -- [P3]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users (id),
    status          TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'shipped', 'refunded', 'cancelled')),
    total_minor     BIGINT NOT NULL CHECK (total_minor >= 0),
    currency        CHAR(3) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE order_items (                                  -- [P3]
    order_id        UUID NOT NULL REFERENCES orders (id) ON DELETE CASCADE,
    product_id      UUID NOT NULL REFERENCES merch_products (id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price_minor BIGINT NOT NULL CHECK (unit_price_minor >= 0),
    PRIMARY KEY (order_id, product_id)
);

CREATE TABLE tips (                                         -- [P3]
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    from_user_id    UUID NOT NULL REFERENCES users (id),
    to_artist_id    UUID NOT NULL REFERENCES artists (id),
    amount_minor    BIGINT NOT NULL CHECK (amount_minor > 0),
    currency        CHAR(3) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- 12. Audit trail (security-relevant actions only; no listening data here)
-- -----------------------------------------------------------------------------
CREATE TABLE audit_log (
    id              BIGSERIAL PRIMARY KEY,
    actor_user_id   UUID,                                   -- NULL for system actors
    action          TEXT NOT NULL,                          -- e.g. 'consent.withdraw', 'admin.takedown'
    entity_type     TEXT NOT NULL,
    entity_id       TEXT,
    ip_hash         TEXT,                                   -- salted hash, never raw IP
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX audit_log_actor_idx ON audit_log (actor_user_id, created_at DESC);
