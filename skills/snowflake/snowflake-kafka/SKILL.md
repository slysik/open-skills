---
name: snowflake-kafka
description: Build, configure, debug, and explain the Snowflake Kafka Connector — both the classic v3 file-based Snowpipe path and the v4 Snowpipe Streaming path. Use whenever the user mentions ingesting Kafka topics into Snowflake, the Snowflake Kafka Connector, Snowpipe Streaming, schematization, RECORD_METADATA / RECORD_CONTENT VARIANT columns, or wants to stand up an end-to-end Kafka → Snowflake demo. Includes a runnable local docker-compose stack, key-pair auth setup, role/grant SQL, v4 connector JSON, a smoke-test producer, and the gotchas an interviewer is most likely to probe.
---

# Snowflake Kafka Connector — End-to-End

Helper for everything related to the official Snowflake Kafka Connector (`snowflakeinc/snowflake-kafka-connector`). Covers both released paths — classic v3 (file → stage → Snowpipe) and v4 (rows → Snowpipe Streaming channels) — with a runnable local demo.

Source of truth: https://docs.snowflake.com/en/user-guide/kafka-connector/index. Deeper notes scraped into `ai_docs/snowflake_kafka_connector.md` at the project root if loaded.

## When to use this skill

Triggers: "Snowflake Kafka connector", "Kafka → Snowflake", "Snowpipe Streaming", "schematization", "RECORD_METADATA", `SnowflakeSinkConnector` / `SnowflakeStreamingSinkConnector` in a config, `topic2table.map`, "DLQ for the Snowflake sink", interview-prep on real-time ingestion.

Skip: generic Kafka tuning unrelated to Snowflake, Snowflake → Kafka egress (that is Streams + a custom producer), or non-Snowflake sinks.

## The two paths in one picture

```
                   ┌────────────── v3 (classic Snowpipe) ──────────────┐
Kafka topic ──▶ Connect worker ──▶ buffer ──▶ internal STAGE ──▶ PIPE ──▶ table
                                          (file flush)      (Snowpipe REST)

                   ┌────────────── v3 SNOWPIPE_STREAMING / v4 ─────────┐
Kafka topic ──▶ Connect worker ──▶ Streaming SDK ──▶ channel ──▶ table
                                                  (no files, no pipes)
```

`connector.class` literally changes between v3 and v4 — confusing them is the #1 demo-day fail. See `Decision tree` below.

## Decision tree — which mode do you want?

| Goal                                                 | Mode to pick                                                    |
|------------------------------------------------------|-----------------------------------------------------------------|
| New project, latest features, schematization default | **v4** (`SnowflakeStreamingSinkConnector`)                      |
| Existing v3 deployment you don't want to migrate yet | **v3 classic** (`SnowflakeSinkConnector`)                       |
| Want sub-second latency on v3 without upgrading      | v3 + `snowflake.ingestion.method=SNOWPIPE_STREAMING`            |
| Need Avro + schema evolution                         | Any streaming path + structured converter (Avro / Protobuf / Json) |
| Iceberg target                                       | v4 only — schematization with structured-type columns           |

Defaults for an interview-prep demo: **v4**, JsonConverter, schematization on, server_side validation.

## End-to-end demo runbook

This is the path to follow when you want a working Kafka → Snowflake pipeline you can show off. Each step links to a script/file in this skill.

### 0. Prereqs (one-time)

- A paid Snowflake account (Cortex/Streaming need a non-trial). User already has `XDOJQZJ-ZSB13251` per memory.
- Docker Desktop, `bun`/`uv` (per project CLAUDE.md), and either `kcat` or `docker compose exec` for producing.
- About 6 GB free RAM for the local stack.

### 1. Provision Snowflake (role, user, db, table)

```bash
# Edit the public key value first (step 2 produces it), then pipe via stdin
# (the snowq SQL REST API path doesn't accept -f and rejects USE statements):
snowq < scripts/setup-snowflake.sql
```

What it does (`scripts/setup-snowflake.sql`):
- Creates `KAFKA_DB.KAFKA_SCHEMA`, warehouse `KAFKA_WH`.
- Creates user `KAFKA_CONNECTOR_USER` with key-pair auth.
- Creates role `KAFKA_CONNECTOR_ROLE` with **direct** grants (v4 ignores role hierarchy — gotcha #1).
- Creates a target table `SENSORS` with the default `RECORD_METADATA VARIANT, RECORD_CONTENT VARIANT` layout.

### 2. Generate a key-pair for the connector user

```bash
./scripts/gen-keypair.sh
# → writes rsa_key.p8 (private, encrypted), rsa_key.pub (public),
#   and prints the SINGLE-LINE base64 you paste into the connector config.
```

Then paste:
- `rsa_key.pub` body → into the `ALTER USER ... SET RSA_PUBLIC_KEY=...` line in `setup-snowflake.sql` and re-run that statement.
- The single-line base64 (printed by the script) → into `snowflake.private.key` in `connector-v4.json`.

PEM headers/footers + newlines stripped is required. Gotcha #2 in `references/troubleshooting.md`.

### 3. Stand up Kafka + Connect locally

```bash
cd scripts && docker compose up -d
docker compose logs -f connect | grep -i "snowflake"   # wait for "Loaded plugin"
```

`scripts/docker-compose.yml` brings up: Zookeeper, one Kafka broker, Schema Registry (Avro-ready), and Kafka Connect with the Snowflake connector plugin pre-installed.

### 4. Submit the connector

```bash
# From repo root
curl -s -X POST -H 'Content-Type: application/json' \
     --data @scripts/connector-v4.json \
     http://localhost:8083/connectors | jq .

# Confirm it is RUNNING
curl -s http://localhost:8083/connectors/sensors-snowflake-v4/status | jq .
```

`scripts/connector-v4.json` is the working v4 sink config. The placeholders are the only fields you should need to change: `<ACCOUNT_LOCATOR>`, `<PRIVATE_KEY_BASE64>`, and `<PRIVATE_KEY_PASSPHRASE>`.

### 5. Produce a few records

```bash
./scripts/produce-demo.sh   # publishes 5 JSON messages to topic 'sensors'
```

### 6. Watch rows land in Snowflake

```sql
-- With schematization ON (v4 default), expect typed columns:
SELECT * FROM kafka_db.kafka_schema.sensors ORDER BY record_metadata:offset DESC LIMIT 5;

-- Latency check (Snowpipe Streaming only):
SELECT
  record_metadata:topic::string                                          AS topic,
  record_metadata:partition::int                                         AS partition,
  record_metadata:offset::int                                            AS offset,
  TO_TIMESTAMP(record_metadata:SnowflakeConnectorPushTime::bigint/1000)  AS pushed_at,
  CURRENT_TIMESTAMP()                                                    AS now,
  DATEDIFF('second',
    TO_TIMESTAMP(record_metadata:SnowflakeConnectorPushTime::bigint/1000),
    CURRENT_TIMESTAMP())                                                 AS lag_secs
FROM kafka_db.kafka_schema.sensors
ORDER BY pushed_at DESC LIMIT 5;
```

### 7. (Optional) See the failure path

Delete one of the table's auto-grants, push another record, and watch the row appear in `kafka_db.kafka_schema.sensors$errors` — the v4 server-side **Error Table**. See `references/troubleshooting.md` § "Error Table vs DLQ".

## What the candidate is most likely to be quizzed on

These are the things that surprise people and that interviewers like to probe.

1. **`connector.class` changed in v4.** v3 = `com.snowflake.kafka.connector.SnowflakeSinkConnector`. v4 = `com.snowflake.kafka.connector.SnowflakeStreamingSinkConnector`. v4 was GA April 2025 — most blog posts online still show v3.
2. **v4 grants must be direct, not inherited.** Every other Snowflake context honors role hierarchy; v4 does not. `GRANT INSERT ON TABLE ... TO ROLE kafka_connector_role` directly, not via a wrapper role.
3. **Schematization replaces RECORD_CONTENT, keeps RECORD_METADATA.** Top-level JSON keys become typed columns; nested objects → VARIANT. Requires Snowpipe Streaming + a structured converter (NOT StringConverter / ByteArrayConverter).
4. **`errors.tolerance=all` without a DLQ topic = silent data loss.** No log line, records just vanish. Server-side validation failures route to the **`<table>$errors`** Error Table instead of the DLQ.
5. **JVM heap for v4 is ~50%, not 80%.** The Rust Streaming SDK runs off-heap; sizing the JVM huge starves it and causes OOM/backpressure. Inverse of standard Kafka Connect tuning advice.
6. **Default table = exactly two VARIANT columns**: `RECORD_METADATA` (envelope) and `RECORD_CONTENT` (raw payload). Memorize the metadata fields — `topic`, `partition`, `offset`, `CreateTime`, `key`, `schema_id`, `headers`, plus `SnowflakeConnectorPushTime` for Streaming.
7. **One stage + N pipes per topic in the v3 file path.** Naming pattern `SNOWFLAKE_KAFKA_CONNECTOR_<connector>_STAGE_<table>` and `..._PIPE_<table>_<partition>`. Renaming a connector orphans these — they have to be dropped manually.
8. **Flush thresholds are OR'd, not AND'd**: first of `buffer.flush.time` (120 s default v3), `buffer.count.records` (10,000), or `buffer.size.bytes` (5 MB) wins. Lowering `buffer.flush.time` is the main latency lever in v3.

## Reference docs (deeper dives)

- **`CHEATSHEET.md` — 1-page printable.** v3/v4 table, default layout, top 5 gotchas, elevator pitch. Read on the way into the interview.
- **`references/cookbook.md` — start here if you're learning.** Read-once-then-do study guide: what the connector IS, the mental model, every step with WHY, failure modes, quiz yourself.
- `references/snowflake-setup.md` — full role/grant matrix, key-pair auth from scratch, common 401/403 fixes.
- `references/v4-config-reference.md` — every v4 config key with its default and when you'd change it.
- `references/troubleshooting.md` — the 10 gotchas, JMX/SQL monitoring queries, file-validation workflow for v3.

## Scripts (drop-in)

- `scripts/setup-snowflake.sql` — provisions Snowflake side end-to-end.
- `scripts/gen-keypair.sh` — generates PKCS#8 keypair and the stripped single-line base64.
- `scripts/docker-compose.yml` — Zookeeper + Kafka + Schema Registry + Connect with connector plugin.
- `scripts/connector-v4.json` — submit-ready v4 connector config (placeholders only).
- `scripts/produce-demo.sh` — publishes 5 sample JSON records to `sensors`.

## Common one-liners

```bash
# List connectors
curl -s http://localhost:8083/connectors | jq .

# Connector status (look for state=RUNNING)
curl -s http://localhost:8083/connectors/sensors-snowflake-v4/status | jq .

# Restart failed task
curl -s -X POST http://localhost:8083/connectors/sensors-snowflake-v4/tasks/0/restart

# Tear down
curl -s -X DELETE http://localhost:8083/connectors/sensors-snowflake-v4
docker compose -f scripts/docker-compose.yml down -v
```

```sql
-- v3-only: pipe status
SELECT SYSTEM$PIPE_STATUS('KAFKA_DB.KAFKA_SCHEMA.SNOWFLAKE_KAFKA_CONNECTOR_<name>_PIPE_SENSORS_0');

-- v3-only: load history (last 6h)
SELECT * FROM TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
  TABLE_NAME => 'SENSORS',
  START_TIME => DATEADD('hours', -6, CURRENT_TIMESTAMP())))
ORDER BY LAST_LOAD_TIME DESC;

-- Server-side error table (v4)
SELECT * FROM kafka_db.kafka_schema.sensors$errors ORDER BY inserted_at DESC LIMIT 20;
```

## Source links

- Connector index: https://docs.snowflake.com/en/user-guide/kafka-connector/index
- How it works: https://docs.snowflake.com/en/user-guide/kafka-connector-overview
- Install: https://docs.snowflake.com/en/user-guide/kafka-connector-install
- Snowpipe Streaming for Kafka: https://docs.snowflake.com/en/user-guide/data-load-snowpipe-streaming-kafka
- Schema detection: https://docs.snowflake.com/en/user-guide/data-load-snowpipe-streaming-kafka-schema-detection
- Monitoring: https://docs.snowflake.com/en/user-guide/kafka-connector-monitor
- Troubleshooting: https://docs.snowflake.com/en/user-guide/kafka-connector-ts
