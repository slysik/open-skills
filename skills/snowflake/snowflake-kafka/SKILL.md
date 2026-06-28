---
name: snowflake-kafka
description: Build, configure, debug, and explain the Snowflake Kafka Connector — both the classic v3 file-based Snowpipe path and the v4 Snowpipe Streaming path. Use whenever the user mentions ingesting Kafka topics into Snowflake, the Snowflake Kafka Connector, Snowpipe Streaming, schematization, RECORD_METADATA / RECORD_CONTENT VARIANT columns, or wants to stand up an end-to-end Kafka → Snowflake demo. Includes a runnable local docker-compose stack, key-pair auth setup, role/grant SQL, v4 connector JSON, a smoke-test producer, and the gotchas an interviewer is most likely to probe.
---

# Snowflake Kafka Connector — End-to-End Router

Helper for everything related to the official Snowflake Kafka Connector (`snowflakeinc/snowflake-kafka-connector`). Covers both released paths — classic v3 (file → stage → Snowpipe) and v4 (rows → Snowpipe Streaming channels) — with a runnable local demo.

Source of truth: https://docs.snowflake.com/en/user-guide/kafka-connector/index. Deeper notes scraped into `ai_docs/snowflake_kafka_connector.md` at the project root if loaded.

## When to use this skill

Triggers: "Snowflake Kafka connector", "Kafka → Snowflake", "Snowpipe Streaming", "schematization", "RECORD_METADATA", `SnowflakeSinkConnector` / `SnowflakeStreamingSinkConnector` in a config, `topic2table.map`, "DLQ for the Snowflake sink", interview-prep on real-time ingestion.

Skip: generic Kafka tuning unrelated to Snowflake, Snowflake → Kafka egress (that is Streams + a custom producer), or non-Snowflake sinks.

---

## Decision tree — which mode do you want?

| Goal | Mode to pick |
|---|---|
| New project, latest features, schematization default | **v4** (`SnowflakeStreamingSinkConnector`) |
| Existing v3 deployment you don't want to migrate yet | **v3 classic** (`SnowflakeSinkConnector`) |
| Want sub-second latency on v3 without upgrading | v3 + `snowflake.ingestion.method=SNOWPIPE_STREAMING` |
| Need Avro + schema evolution | Any streaming path + structured converter (Avro / Protobuf / Json) |
| Iceberg target | v4 only — schematization with structured-type columns |

Defaults for an interview-prep demo: **v4**, JsonConverter, schematization on, server-side validation.

---

## Core Scripts & Files (Drop-In)

- `scripts/setup-snowflake.sql` — provisions Snowflake side end-to-end (db, schema, warehouse, user, role, table).
- `scripts/gen-keypair.sh` — generates PKCS#8 keypair and the stripped single-line base64.
- `scripts/docker-compose.yml` — Zookeeper + Kafka + Schema Registry + Connect with connector plugin.
- `scripts/connector-v4.json` — submit-ready v4 connector config (placeholders only).
- `scripts/produce-demo.sh` — publishes 5 sample JSON records to `sensors`.

---

## Common CLI & SQL One-Liners

```bash
# List connectors
curl -s http://localhost:8083/connectors | jq .

# Connector status (look for state=RUNNING)
curl -s http://localhost:8083/connectors/sensors-snowflake-v4/status | jq .

# Restart failed task
curl -s -X POST http://localhost:8083/connectors/sensors-snowflake-v4/tasks/0/restart

# Tear down local stack
docker compose -f scripts/docker-compose.yml down -v
```

```sql
-- Server-side error table (v4)
SELECT * FROM kafka_db.kafka_schema.sensors$errors ORDER BY inserted_at DESC LIMIT 20;

-- v3-only: pipe status
SELECT SYSTEM$PIPE_STATUS('KAFKA_DB.KAFKA_SCHEMA.SNOWFLAKE_KAFKA_CONNECTOR_<name>_PIPE_SENSORS_0');
```

---

## Reference Docs (Deeper Dives)

- **[Cookbook & Study Guide](references/cookbook.md)** — Start here for a full end-to-end walkthrough, mental models, and step-by-step setup reasons.
- **[Troubleshooting & Gotchas](references/troubleshooting.md)** — The 10 interview-bait gotchas, private key format fixes, JVM heap sizing, buffer thresholds, duplicate rows, and rebalancing loops.
- **[Snowflake Provisioning](references/snowflake-setup.md)** — Full role/grant matrix and key-pair auth setup.
- **[v4 Config Reference](references/v4-config-reference.md)** — Complete config key defaults and options.
