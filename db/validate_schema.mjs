// Validates db/schema.sql against a real PostgreSQL engine (PGlite = Postgres compiled to WASM),
// including pgvector, then runs constraint smoke tests that must FAIL or SUCCEED as expected.
import { PGlite } from "@electric-sql/pglite";
import { vector } from "@electric-sql/pglite/vector";
import { pg_trgm } from "@electric-sql/pglite/contrib/pg_trgm";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const here = dirname(fileURLToPath(import.meta.url));
const sql = readFileSync(join(here, "schema.sql"), "utf8");
const db = await PGlite.create({ extensions: { vector, pg_trgm } });

let failures = 0;
const check = (name, ok) => {
  console.log(`${ok ? "PASS" : "FAIL"}  ${name}`);
  if (!ok) failures++;
};

try {
  await db.exec(sql);
  check("schema.sql applies cleanly", true);
} catch (e) {
  check(`schema.sql applies cleanly (${e.message})`, false);
  process.exit(1);
}

const tables = await db.query(
  "select count(*)::int as n from information_schema.tables where table_schema='public' and table_type='BASE TABLE'"
);
console.log(`INFO  tables created: ${tables.rows[0].n}`);

// Happy path: a user, a track, a playlist with an item, an embedding.
const user = await db.query(
  "insert into users (email, display_name) values ('a@example.com', 'Asha') returning id"
);
const uid = user.rows[0].id;
const artist = await db.query("insert into artists (name, sort_name) values ('Test Artist','Artist, Test') returning id");
const track = await db.query(
  `insert into tracks (title, duration_ms, language, genres, status)
   values ('Song', 215000, 'hi', '{pop}', 'ready') returning id`
);
const tid = track.rows[0].id;
await db.query("insert into track_artists (track_id, artist_id, role) values ($1, $2, 'primary')", [tid, artist.rows[0].id]);
await db.query(
  "insert into track_embeddings (track_id, model_version, embedding) values ($1, 'emb-v1', $2)",
  [tid, JSON.stringify(Array(256).fill(0.01))]
);
const pl = await db.query("insert into playlists (owner_user_id, title, source) values ($1, 'Study', 'ai_prompt') returning id", [uid]);
await db.query("insert into playlist_items (playlist_id, position, track_id) values ($1, 0, $2)", [pl.rows[0].id, tid]);
check("happy-path inserts (user, track, playlist, embedding)", true);

// Ann-style nearest neighbour query uses the HNSW index without error.
const nn = await db.query(
  "select track_id from track_embeddings order by embedding <=> $1 limit 1",
  [JSON.stringify(Array(256).fill(0.01))]
);
check("vector nearest-neighbour query returns a row", nn.rows.length === 1);

// Negative tests: each must throw.
const expectFail = async (name, fn) => {
  try {
    await fn();
    check(`rejects: ${name}`, false);
  } catch {
    check(`rejects: ${name}`, true);
  }
};

await expectFail("user with neither email nor phone", () =>
  db.query("insert into users (display_name) values ('Nobody')"));
await expectFail("unknown subscription plan tier", () =>
  db.query("insert into plans (id, tier) values ('x', 'gold')"));
await expectFail("track with zero duration", () =>
  db.query("insert into tracks (title, duration_ms) values ('bad', 0)"));
await expectFail("duplicate playlist position", () =>
  db.query("insert into playlist_items (playlist_id, position, track_id) values ($1, 0, $2)", [pl.rows[0].id, tid]));
await expectFail("ticket tier sold beyond total", async () => {
  const ev = await db.query(
    "insert into live_events (artist_id, event_type, title, starts_at) values ($1,'concert','Show', now()) returning id",
    [artist.rows[0].id]
  );
  await db.query(
    "insert into ticket_tiers (event_id, name, price_minor, currency, quantity_total, quantity_sold) values ($1,'GA',100,'INR',10,11)",
    [ev.rows[0].id]
  );
});
await expectFail("AI-declared upload that is live without a label", () =>
  db.query(
    "insert into uploads (creator_user_id, status, declared_ai_generated, ai_label_applied, rights_attestation_at) values ($1,'live',true,false,now())",
    [uid]
  ));
await expectFail("self-follow", () =>
  db.query("insert into follows (follower_id, followee_id) values ($1,$1)", [uid]));
await expectFail("translation without a matching lyric line", async () => {
  const ly = await db.query(
    "insert into lyrics (track_id, language, source) values ($1,'hi','licensed_provider') returning id", [tid]);
  await db.query(
    "insert into lyric_translations (lyric_id, line_no, target_language, kind, text) values ($1, 99, 'en', 'translation', 'x')",
    [ly.rows[0].id]);
});

// Positive: a valid AI-declared upload that carries a label is accepted.
await db.query(
  "insert into uploads (creator_user_id, status, declared_ai_generated, ai_label_applied, rights_attestation_at) values ($1,'live',true,true,now())",
  [uid]);
check("accepts labelled AI-declared upload", true);

console.log(failures === 0 ? "\nAll schema checks passed." : `\n${failures} check(s) failed.`);
await db.close();
process.exit(failures === 0 ? 0 : 1);
