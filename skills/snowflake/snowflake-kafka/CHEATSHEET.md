# Snowflake Kafka Connector — One-Page Cheat Sheet

## What it is (60-second pitch)

A **Kafka Connect sink plugin** (a JAR) maintained by Snowflake. Drop it into a Kafka Connect worker, give it a config, and it streams Kafka topic messages into Snowflake tables. No app code in between. Two paths exist: classic Snowpipe (file-based, slow) and Snowpipe Streaming (row-based, sub-second). v4 always uses Streaming.

## Architecture in one line

`Producer → Kafka topic → Kafka Connect (running the connector JAR) → Snowflake table`

## v3 vs v4 — know cold

|   | v3 classic | v3 Streaming | v4 (current) |
|---|---|---|---|
| `connector.class` | `SnowflakeSinkConnector` | `SnowflakeSinkConnector` | `SnowflakeStreamingSinkConnector` |
| Latency | tens of seconds | sub-second | sub-second |
| Stages files? | yes | no | no |
| Schematization | no | yes | yes (default) |
| Role grants | hierarchical OK | hierarchical OK | **must be direct** |
| JVM heap | proportional to partitions | same | ~50% (Rust SDK off-heap) |

## Default table layout (no schematization)

```
RECORD_METADATA  VARIANT   -- topic, partition, offset, CreateTime, key, headers
RECORD_CONTENT   VARIANT   -- raw JSON payload, unparsed
```

Query with `:` accessors: `record_content:sensorId::int`.

## With schematization (v4 default)

Top-level JSON keys become typed columns; nested objects stay VARIANT. RECORD_CONTENT disappears, RECORD_METADATA stays. Requires Snowpipe Streaming + a structured converter (Json/Avro/Protobuf — NOT String/ByteArray). Top-level arrays not supported.

## Snowflake-side prep

```sql
CREATE DATABASE  kafka_db;
CREATE SCHEMA    kafka_db.kafka_schema;
CREATE WAREHOUSE kafka_wh WITH WAREHOUSE_SIZE=XSMALL AUTO_SUSPEND=60;
CREATE USER      kafka_connector_user;
ALTER  USER      kafka_connector_user SET RSA_PUBLIC_KEY='<body, no PEM headers>';
CREATE ROLE      kafka_connector_role;

GRANT USAGE        ON DATABASE  kafka_db              TO ROLE kafka_connector_role;
GRANT USAGE        ON SCHEMA    kafka_db.kafka_schema TO ROLE kafka_connector_role;
GRANT CREATE TABLE ON SCHEMA    kafka_db.kafka_schema TO ROLE kafka_connector_role;
GRANT USAGE        ON WAREHOUSE kafka_wh              TO ROLE kafka_connector_role;
GRANT ROLE kafka_connector_role TO USER kafka_connector_user;
```

## Minimum v4 connector config (paste-ready)

```json
{
  "name": "sensors-snowflake-v4",
  "config": {
    "connector.class": "com.snowflake.kafka.connector.SnowflakeStreamingSinkConnector",
    "tasks.max": "1",
    "topics": "sensors",
    "snowflake.url.name": "https://<org>-<account>.snowflakecomputing.com",
    "snowflake.user.name": "KAFKA_CONNECTOR_USER",
    "snowflake.role.name": "KAFKA_CONNECTOR_ROLE",
    "snowflake.database.name": "KAFKA_DB",
    "snowflake.schema.name": "KAFKA_SCHEMA",
    "snowflake.private.key": "<base64 PKCS#8, no headers>",
    "snowflake.private.key.passphrase": "<passphrase>",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "snowflake.enable.schematization": "true",
    "snowflake.validation": "server_side"
  }
}
```

## Top 5 gotchas (interview-bait)

1. **Private key format** — strip PEM headers and newlines. `grep -v "BEGIN\|END" rsa_key.p8 | tr -d '\n'`.
2. **v4 grants are direct only** — `GRANT INSERT ON TABLE foo TO ROLE x`, never via a wrapper role.
3. **Schematization on a pre-existing table needs OWNERSHIP + `ENABLE_SCHEMA_EVOLUTION=TRUE`** or the payload silently drops. Easier path: drop the table and let the connector auto-create it.
4. **`errors.tolerance=all` without a DLQ topic = silent data loss.** Server-side validation failures go to `<table>$errors`; client-side go to the DLQ topic.
5. **v4 JVM heap should be ~50% of system RAM.** The Rust SDK runs off-heap. Standard Kafka tuning advice (give JVM 80%) starves it.

## Verify the pipeline

```bash
# Connector status
curl -s http://localhost:8083/connectors/<name>/status | jq .

# Did rows land?
snowq "SELECT COUNT(*) FROM kafka_db.kafka_schema.sensors"

# Schema (after schematization)
snowq "DESCRIBE TABLE kafka_db.kafka_schema.sensors"

# End-to-end Streaming latency
snowq "SELECT DATEDIFF('ms',
         TO_TIMESTAMP(record_metadata:CreateTime::bigint/1000),
         TO_TIMESTAMP(record_metadata:SnowflakeConnectorPushTime::bigint/1000)) AS lag_ms
       FROM kafka_db.kafka_schema.sensors ORDER BY lag_ms DESC LIMIT 5"

# Server-side rejected rows
snowq "SELECT * FROM kafka_db.kafka_schema.sensors\$errors LIMIT 10"
```

## Snowflake objects the connector creates

- **v3 classic:** one internal stage per topic + N pipes per topic (one per partition) + the table.  
  Names: `SNOWFLAKE_KAFKA_CONNECTOR_<name>_STAGE_<table>` and `..._PIPE_<table>_<partition>`.
- **v4 / Streaming:** one pipe per table (`<TABLE>-STREAMING`) + N channels (`<CONNECTOR>_<id>_<topic>_<partition>`). No stages, no files.

## Exactly-once

Snowpipe Streaming persists each channel's `offsetTokenUpperBound` server-side. Restart the connector → it resumes from the persisted offset, so already-ingested records aren't duplicated.

## Elevator pitch (memorize)

> "It's a Kafka Connect sink plugin from Snowflake. v4 streams Kafka partitions directly into Snowflake tables via Snowpipe Streaming channels — sub-second latency, schema evolution by default, exactly-once via persisted channel offsets. Auth is RSA key-pair, the connector role needs direct grants, and the JVM heap should be modest because the Rust SDK runs off-heap."
