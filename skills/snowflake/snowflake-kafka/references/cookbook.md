# Snowflake Kafka Connector — Real-Time JSON Cookbook

A read-once-then-do study guide. Goal: you can stand the pipeline up from a blank machine, explain every moving part out loud, and answer the questions an interviewer will ask.

Read top-to-bottom the first time. After that, treat it as a reference.

---

## Part 1 — What the connector actually IS

### The one-sentence definition

> The Snowflake Kafka Connector is a **Kafka Connect sink plugin** maintained by Snowflake that pulls messages from one or more Kafka topics and writes them into Snowflake tables — with no application code in between.

### Unpacking that

- **Kafka Connect** is Apache Kafka's pluggable runtime for moving data in and out of Kafka. It's a daemon (or cluster of daemons) that loads plugins called *connectors*. Source connectors read from somewhere and write to Kafka. **Sink connectors** read from Kafka and write somewhere else.
- The Snowflake Kafka Connector is the **sink** plugin for Snowflake. It's just a JAR file (`snowflake-kafka-connector-*.jar`) you drop into the Connect worker's plugin path.
- The connector reads Kafka messages, transforms them according to its config, and uses Snowflake's ingest APIs to write them into a Snowflake table.

### What "the connector" is NOT

- Not a Snowflake feature you turn on with SQL. It's a JAR running in your Kafka Connect cluster.
- Not Kafka itself. You bring your own Kafka.
- Not a real-time stream processor (no transformations, joins, aggregations). It only does ingest. If you need transforms, do them upstream in Kafka Streams / ksqlDB or downstream in Snowflake (dbt, dynamic tables).
- Not a pull-from-Snowflake export. There's no Snowflake-source connector in this repo.

### What's in the JAR

A Java/Rust hybrid. Two big internal components:

1. **The Connect-facing layer** (Java) — implements the `SinkConnector` and `SinkTask` interfaces Kafka Connect calls every time records arrive on a partition. Handles config, partition assignment, error tolerance, DLQ routing.
2. **The Snowflake-facing layer** — depends on which version:
   - **v3 classic Snowpipe path**: the connector buffers records, writes them as compressed JSON/Avro files to a Snowflake **internal stage**, then calls **Snowpipe**'s `insertFiles` REST API to load them. Files → stage → pipe → table. Higher latency (tens of seconds) but battle-tested.
   - **v3 with `snowflake.ingestion.method=SNOWPIPE_STREAMING`** or **v4 always**: skip the file step entirely. Use the **Snowpipe Streaming SDK** which writes rows directly to a per-partition **channel**. Sub-second latency. v4 has this rewritten in **Rust** and runs off-heap.

### What objects it creates inside Snowflake

When the connector starts, depending on path:

| Object | Created by | Path |
|---|---|---|
| Target table | Auto-created if missing (or you pre-create it) | both |
| Internal stage `SNOWFLAKE_KAFKA_CONNECTOR_<name>_STAGE_<table>` | Connector | v3 classic only |
| Pipe(s) `SNOWFLAKE_KAFKA_CONNECTOR_<name>_PIPE_<table>_<partition>` | Connector | v3 classic only (one per partition) |
| Pipe `<TABLE>-STREAMING` | Connector | Snowpipe Streaming (one per table) |
| Channels `<CONNECTOR>_<id>_<topic>_<partition>` | Connector at runtime | Snowpipe Streaming |

You will see these names in `SHOW STAGES` / `SHOW PIPES`. Memorize the patterns — interviewers love asking "what shows up in Snowflake when the connector starts?"

### Where it runs

Wherever you run Kafka Connect. Three common deployments:

- **Confluent Cloud**: managed Kafka Connect. Click-install the connector from Confluent Hub and paste a JSON config. Easiest for production.
- **Self-managed Kafka Connect cluster** (on K8s, EC2, on-prem). What "real" deployments tend to look like. You manage the JVM, plugins, security.
- **Local Kafka Connect** (the demo you just ran). One Connect worker in a Docker container, fine for learning.

The connector itself is identical everywhere; only the operational layer changes.

---

## Part 2 — The mental model in three pictures

### Picture 1: The big arrow

```
Producer apps  ──▶  Kafka topics  ──▶  Kafka Connect (running the connector)  ──▶  Snowflake table
   (your code)         (broker)              (sink plugin)                            (queryable)
```

That's the whole job: drag bytes from the topic on the left to the table on the right.

### Picture 2: v3 classic Snowpipe (file-based) — slower

```
Kafka partition ──▶ connector buffer ──▶ JSON file ──▶ INTERNAL STAGE ──▶ PIPE ──▶ TABLE
                    (10k rows or         (gz)         (per topic)        (per      (auto-created)
                     120s or 5MB)                                         partition)
```

Latency: ~30 s typical. Files are real on the stage; you can `LIST @%table` and download them.

### Picture 3: v4 Snowpipe Streaming — fast

```
Kafka partition ──▶ Streaming SDK ──▶ CHANNEL ──▶ TABLE
                    (Rust, off-heap)   (per       (auto-created
                                        partition) with schema evolution)
```

No staging, no files. Latency: 100–500 ms typical (you saw 31–43 ms today). One pipe per table; channels do the per-partition work.

---

## Part 3 — End-to-end recipe (the path you ran today)

Each step has a **What** (the action) and a **Why** (so you can defend it).

### Step 0 — Prereqs

**What:** Snowflake account (paid, not trial — Streaming requires it), Docker Desktop, a way to run SQL against Snowflake (Snowsight UI or your `snowq` REST helper).

**Why:** Snowpipe Streaming and the v4 connector aren't enabled on free trial accounts.

### Step 1 — Provision Snowflake objects

**What:**
- Database: `KAFKA_DB`
- Schema: `KAFKA_DB.KAFKA_SCHEMA`
- Warehouse: `KAFKA_WH` (XSMALL, auto-suspend 60s — cheap)
- Service-account user: `KAFKA_CONNECTOR_USER` with `RSA_PUBLIC_KEY` set
- Role: `KAFKA_CONNECTOR_ROLE` with **direct grants** (USAGE on db/schema/warehouse, CREATE TABLE on the schema)
- Grant the role to the user, set as default

```sql
-- Drop me into Snowflake; I'll fully qualify everything because the SQL REST API
-- doesn't accept USE statements.
CREATE DATABASE  IF NOT EXISTS kafka_db;
CREATE SCHEMA    IF NOT EXISTS kafka_db.kafka_schema;
CREATE WAREHOUSE IF NOT EXISTS kafka_wh WITH WAREHOUSE_SIZE=XSMALL AUTO_SUSPEND=60 AUTO_RESUME=TRUE;

CREATE USER IF NOT EXISTS kafka_connector_user
  LOGIN_NAME='kafka_connector_user'
  COMMENT='Kafka Connector service account';

CREATE ROLE IF NOT EXISTS kafka_connector_role;

GRANT USAGE        ON DATABASE  kafka_db                  TO ROLE kafka_connector_role;
GRANT USAGE        ON SCHEMA    kafka_db.kafka_schema     TO ROLE kafka_connector_role;
GRANT CREATE TABLE ON SCHEMA    kafka_db.kafka_schema     TO ROLE kafka_connector_role;
GRANT USAGE        ON WAREHOUSE kafka_wh                  TO ROLE kafka_connector_role;

GRANT ROLE kafka_connector_role TO USER kafka_connector_user;
ALTER USER kafka_connector_user SET DEFAULT_ROLE=kafka_connector_role
                                    DEFAULT_WAREHOUSE=kafka_wh;
```

**Why each grant:**
- USAGE on db/schema: minimum to "see" objects.
- CREATE TABLE: lets the connector auto-create the target table on first record. Without it, you must pre-create the table AND grant INSERT.
- USAGE on warehouse: every Snowflake operation needs a warehouse, even ingest path.
- **Direct grants, not inherited:** v4 explicitly does NOT honor role hierarchy. `GRANT ROLE foo TO ROLE kafka_connector_role` does not work. This is the #1 silent permissions failure.

### Step 2 — Generate a key-pair

**What:** Snowflake authenticates the connector via RSA key-pair (no password). Generate a PKCS#8 private key, extract the public key, paste the public key into the user definition.

```bash
# Encrypted PKCS#8 private key
openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 aes256 -inform PEM -out rsa_key.p8 -passout pass:<PASSPHRASE>
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub -passin pass:<PASSPHRASE>

# Strip header/footer/newlines for the connector config
grep -v "BEGIN\|END" rsa_key.p8 | tr -d '\n' > rsa_key.connector
```

Then in Snowflake:

```sql
ALTER USER kafka_connector_user
  SET RSA_PUBLIC_KEY = '<paste body of rsa_key.pub, no header/footer, no newlines>';
```

**Why key-pair?**
- Snowflake disables password auth for service accounts by default.
- v3 only supports key-pair (or OAuth). v4 also supports OAuth for Snowpipe Streaming.
- The public key lives on the user; the private key lives in your Connect worker's config. Standard asymmetric setup.

**The classic gotcha:** the connector's `snowflake.private.key` field expects raw base64 — no `-----BEGIN-----` / `-----END-----` lines, no newlines. Pasting the file as-is is the #1 first-run failure.

### Step 3 — Run Kafka + Schema Registry + Connect locally

**What:** `docker compose up -d` brings up four services:

| Service | Port | Purpose |
|---|---|---|
| zookeeper | 2181 | Kafka coordination (not needed in newer KRaft mode) |
| kafka | 9092 | The broker |
| schema-registry | 8081 | Holds Avro/Protobuf schemas (we don't use it for plain JSON, but it's wired up) |
| connect | 8083 | Kafka Connect REST API + the Snowflake plugin |

The Connect container's `command` does `confluent-hub install snowflakeinc/snowflake-kafka-connector:latest` before starting the worker. That's why the first boot is slow.

**Why all four?** Connect needs Kafka. Kafka (in classic mode) needs Zookeeper. Schema Registry is included so Avro path is one config change away.

**Verify:**

```bash
curl -s http://localhost:8083/connector-plugins | jq -r '.[].class' | grep -i snowflake
# Should print: com.snowflake.kafka.connector.SnowflakeStreamingSinkConnector
```

### Step 4 — Submit the connector config

**What:** POST a JSON config to Connect's REST API.

```bash
curl -s -X POST -H 'Content-Type: application/json' \
     --data @connector-v4.json \
     http://localhost:8083/connectors | jq .
```

The minimum-viable v4 config (annotated):

```jsonc
{
  "name": "sensors-snowflake-v4",                                // unique connector name; embeds into Snowflake object names
  "config": {
    // --- WHO ---
    "connector.class": "com.snowflake.kafka.connector.SnowflakeStreamingSinkConnector", // v4 class
    "tasks.max": "1",                                            // 1 task can handle several partitions; for prod set = total partition count

    // --- WHAT TOPIC, WHICH TABLE ---
    "topics": "sensors",                                         // comma list, or use "topics.regex"
    "snowflake.topic2table.map": "sensors:SENSORS",              // optional; default is topic name sanitized

    // --- HOW TO REACH SNOWFLAKE ---
    "snowflake.url.name": "https://<org>-<account>.snowflakecomputing.com",
    "snowflake.user.name": "KAFKA_CONNECTOR_USER",
    "snowflake.role.name": "KAFKA_CONNECTOR_ROLE",               // MUST be granted directly
    "snowflake.database.name": "KAFKA_DB",
    "snowflake.schema.name": "KAFKA_SCHEMA",
    "snowflake.private.key": "<single-line base64 PKCS#8>",
    "snowflake.private.key.passphrase": "<passphrase>",          // omit/empty if you used -nocrypt

    // --- HOW TO INTERPRET MESSAGES ---
    "key.converter":   "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",                   // plain JSON, not envelope JSON

    // --- WHAT TO DO WITH THE PAYLOAD ---
    "snowflake.enable.schematization": "true",                   // unpack JSON keys into typed columns (v4 default)

    // --- VALIDATION & ERRORS ---
    "snowflake.validation": "server_side",                       // bad rows → <table>$errors
    "snowflake.streaming.validate.compatibility.with.classic": "false", // skip v3 migration probe for new installs
    "errors.tolerance": "none",                                  // fail-fast; "all" requires DLQ
    "errors.log.enable": "true",
    "enable.task.fail.on.authorization.errors": "true"
  }
}
```

**Then verify it's RUNNING:**

```bash
curl -s http://localhost:8083/connectors/sensors-snowflake-v4/status | jq .
# Want: { "connector": {"state":"RUNNING"}, "tasks": [{"state":"RUNNING"}] }
```

### Step 5 — Produce a message

**What:** publish a JSON line to the `sensors` topic.

```bash
echo '{"sensorId":1,"psi":451,"ts":"2026-05-03T19:23:51Z","location":{"site":"AUS-1","rack":3}}' \
  | docker exec -i kafka kafka-console-producer --broker-list kafka:9092 --topic sensors
```

**Why this shape?** Top-level scalar fields (`sensorId`, `psi`, `ts`) become typed columns. Nested object (`location`) becomes a single VARIANT column. Top-level arrays would NOT work (schematization restriction).

### Step 6 — See it in Snowflake

```bash
snowq "SELECT sensorid, psi, ts, location FROM kafka_db.kafka_schema.sensors ORDER BY record_metadata:offset DESC LIMIT 5"
```

If the connector auto-created the table with schematization, you'll see four typed columns plus `RECORD_METADATA`. Check the schema:

```bash
snowq "DESCRIBE TABLE kafka_db.kafka_schema.sensors"
```

### Step 7 — Watch schema evolution live

```bash
echo '{"sensorId":99,"psi":500,"ts":"2026-05-03T19:30:00Z","location":{"site":"AUS-1","rack":1},"battery_pct":87}' \
  | docker exec -i kafka kafka-console-producer --broker-list kafka:9092 --topic sensors

sleep 5
snowq "DESCRIBE TABLE kafka_db.kafka_schema.sensors"
# A new BATTERY_PCT NUMBER column appears
```

The connector saw a new top-level key, ran an `ALTER TABLE ... ADD COLUMN`, and stamped the schema-evolution metadata column on the table. No human intervention.

### Step 8 — Tear down

```bash
curl -s -X DELETE http://localhost:8083/connectors/sensors-snowflake-v4
docker compose -f ~/.claude/skills/snowflake-kafka/scripts/docker-compose.yml down -v
snowq "DROP DATABASE IF EXISTS kafka_db"
```

---

## Part 4 — Two paths, one connector

The v3 vs v4 split is the most common interview confusion. Memorize this table.

| Aspect | v3 classic Snowpipe | v3 Snowpipe Streaming | v4 (current) |
|---|---|---|---|
| `connector.class` | `SnowflakeSinkConnector` | `SnowflakeSinkConnector` | `SnowflakeStreamingSinkConnector` |
| `snowflake.ingestion.method` | not set / `SNOWPIPE` | `SNOWPIPE_STREAMING` | n/a (always streaming) |
| Latency | tens of seconds | sub-second | sub-second |
| Files on disk? | yes (gzipped JSON in stage) | no | no |
| Stage object created? | yes | no | no |
| Pipes created? | one per partition | n/a (channels) | n/a (channels, one pipe per table) |
| Schematization available? | no | yes | yes (default on) |
| Heap tuning | JVM heap proportional to partitions | same | JVM ~50%, Rust SDK off-heap |
| Role grant inheritance | OK | OK | **NOT honored — must be direct** |
| OAuth supported? | no | no | yes (for Streaming) |

**When to pick which:**

- New project today: **v4**.
- Existing v3 deployment, can't migrate: **stay on v3**.
- Need sub-second latency without a v4 migration: **v3 + Snowpipe Streaming**.

---

## Part 5 — Verification queries (the muscle memory set)

```bash
# Is anything in the table?
snowq "SELECT COUNT(*) FROM kafka_db.kafka_schema.sensors"

# Last 5 rows with typed columns
snowq "SELECT sensorid, psi, ts, location FROM kafka_db.kafka_schema.sensors ORDER BY record_metadata:offset DESC LIMIT 5"

# End-to-end ingest lag (Snowpipe Streaming only)
snowq "SELECT record_metadata:offset::int AS offset, DATEDIFF('millisecond', TO_TIMESTAMP(record_metadata:CreateTime::bigint/1000), TO_TIMESTAMP(record_metadata:SnowflakeConnectorPushTime::bigint/1000)) AS ingest_lag_ms FROM kafka_db.kafka_schema.sensors ORDER BY offset DESC LIMIT 10"

# Did schematization fire?
snowq "DESCRIBE TABLE kafka_db.kafka_schema.sensors"

# What pipe did the connector create?
snowq "SHOW PIPES IN SCHEMA kafka_db.kafka_schema"

# Server-side rejected rows (validation failures)
snowq "SELECT * FROM kafka_db.kafka_schema.sensors\$errors ORDER BY inserted_at DESC LIMIT 20"
# Note: backslash-escape the $ in shell.
```

---

## Part 6 — Failure modes and how to recognize them

| Symptom | Likely cause | Fix |
|---|---|---|
| Task state = FAILED, "JWT token is invalid" | Public-key fingerprint mismatch | `DESC USER` and verify `RSA_PUBLIC_KEY_FP`; regenerate if needed |
| Task state = FAILED, "Invalid private key" | PEM headers/newlines in `snowflake.private.key` | Use the stripped single-line form |
| Connector RUNNING but rows never appear | Topic name mismatch (case-sensitive) | `kafka-topics --describe` and confirm exact topic name |
| Rows appear, but `RECORD_CONTENT` is empty | Schematization on + pre-existing classic table without OWNERSHIP / `ENABLE_SCHEMA_EVOLUTION` | Drop table, let connector auto-create; or grant OWNERSHIP + alter table |
| `Insufficient privileges to operate on table` (running as ACCOUNTADMIN) | Connector role auto-created the table; ACCOUNTADMIN doesn't inherit | `GRANT ROLE kafka_connector_role TO ROLE sysadmin` |
| Same offset appears twice | Kafka consumer poll timeout | Bump `consumer.max.poll.interval.ms=900000`, lower `consumer.max.poll.records=50` |
| `errors.tolerance=all` set, but no DLQ output | DLQ topic not configured | Add `errors.deadletterqueue.topic.name`; otherwise records vanish silently |
| Connector restarts and re-ingests rows | v3 only | Check pipe state with `SYSTEM$PIPE_STATUS()`; v4 won't do this because of channel offset persistence |

---

## Part 7 — The interview cheat sheet

If you forget everything else, remember these eight points.

1. **It's a Kafka Connect sink plugin.** Maintained by Snowflake. JAR + config.
2. **v3 vs v4 are different connector classes.** `SnowflakeSinkConnector` vs `SnowflakeStreamingSinkConnector`. v4 GA'd April 2025.
3. **v4 grants must be direct.** `GRANT INSERT ON TABLE foo TO ROLE x`, not via a wrapper role.
4. **v4 uses Snowpipe Streaming + Rust SDK off-heap.** JVM heap should be ~50% of system RAM (opposite of standard Kafka tuning).
5. **Schematization replaces RECORD_CONTENT, keeps RECORD_METADATA.** Top-level keys → typed columns; nested → VARIANT.
6. **Default classic table = two VARIANT columns.** `RECORD_METADATA`, `RECORD_CONTENT`.
7. **`errors.tolerance=all` without `errors.deadletterqueue.topic.name` = silent data loss.** Server-side validation failures go to `<table>$errors` in Snowflake; client-side go to the DLQ topic.
8. **Per-partition flush is OR-ed across three thresholds (v3):** `buffer.flush.time` (120s), `buffer.count.records` (10k), `buffer.size.bytes` (5MB). Lower the time threshold for latency.

---

## Part 8 — Quiz yourself

Cover the right column with your hand and answer out loud.

| Question | Answer |
|---|---|
| What is the connector? | A Kafka Connect sink plugin (a JAR) that ingests Kafka topics into Snowflake tables. |
| Where does it run? | In a Kafka Connect worker — managed (Confluent Cloud) or self-hosted. |
| Two ingestion paths? | Classic Snowpipe (v3 file-based) and Snowpipe Streaming (v3 opt-in or v4 default). |
| What's special about v4 grants? | Privileges must be granted directly to the connector role; role hierarchy is ignored. |
| What does schematization do? | Unpacks top-level JSON keys into typed columns; replaces RECORD_CONTENT; requires a structured converter. |
| Default table layout without schematization? | Two VARIANT columns: `RECORD_METADATA` and `RECORD_CONTENT`. |
| What's `RECORD_METADATA`? | Envelope: topic, partition, offset, timestamps, key, headers, plus `SnowflakeConnectorPushTime` for Streaming. |
| Why does the v4 JVM heap need to be small? | The Rust SDK runs off-heap; sizing JVM huge starves it. |
| What's the silent failure mode of `errors.tolerance=all`? | Without a DLQ topic configured, rejected records disappear. |
| What objects appear in Snowflake when v3 starts? | One internal stage per topic, N pipes per topic (one per partition), and the table. |
| What about v4? | One pipe per table (`<TABLE>-STREAMING`) and N channels (`<connector>_<id>_<topic>_<partition>`). |
| How is exactly-once achieved in Streaming? | Each channel's `offsetTokenUpperBound` is persisted server-side; on restart the connector resumes from there. |
| Can schema evolution rename a column? | No — it adds a new column. Renames and type changes require manual ALTER. |
| What converter must you NOT use with schematization? | StringConverter or ByteArrayConverter — they produce opaque bytes that can't be parsed. |
| One-line elevator pitch? | "It's a Kafka Connect sink plugin from Snowflake that streams Kafka topics into Snowflake tables via Snowpipe Streaming, with schema evolution out of the box." |

---

## Part 9 — Where to read more (in this skill)

- `SKILL.md` — entry point and the runbook you used today
- `references/snowflake-setup.md` — role/grant matrix, key-pair workflow
- `references/v4-config-reference.md` — every v4 config key with its default
- `references/troubleshooting.md` — the 10 gotchas, JMX/SQL monitoring queries
- `scripts/` — runnable artifacts (compose, connector JSON, key-gen, producer)
- `ai_docs/snowflake_kafka_connector.md` — 1000+ line raw research dump if you want primary-source detail
