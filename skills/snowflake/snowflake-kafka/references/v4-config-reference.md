# v4 connector config reference

Source: https://docs.snowflake.com/en/user-guide/kafka-connector/setup-kafka

The v4 connector class is **`com.snowflake.kafka.connector.SnowflakeStreamingSinkConnector`**. Schematization is on by default. Latency target is < 1 s in-region.

## Identity & topic routing

| Key                        | Required | Default | Purpose                                                                                                                    |
|----------------------------|----------|---------|----------------------------------------------------------------------------------------------------------------------------|
| `name`                     | yes      | —       | Unique connector name. Must be a valid Snowflake unquoted identifier (alphanum + `_`, starts with a letter).               |
| `connector.class`          | yes      | —       | `com.snowflake.kafka.connector.SnowflakeStreamingSinkConnector`                                                            |
| `tasks.max`                | yes      | 1       | Recommended = total partition count across all topics. Don't exceed 2× CPU cores.                                          |
| `topics`                   | yes¹     | —       | Comma-separated topic list. Mutually exclusive with `topics.regex`.                                                        |
| `topics.regex`             | yes¹     | —       | Java regex matching topic names. Mutually exclusive with `topics`.                                                         |
| `snowflake.topic2table.map` | no      | —       | `topicA:tableA,topicB:tableB`. Supports regex. Without it, table name = topic name (sanitized).                            |

¹ Provide one of `topics` or `topics.regex`.

## Snowflake connection

| Key                                                       | Required | Default     | Purpose                                                                |
|-----------------------------------------------------------|----------|-------------|------------------------------------------------------------------------|
| `snowflake.url.name`                                      | yes      | —           | `https://<org>-<account>.snowflakecomputing.com` (v4 accepts `https://`).|
| `snowflake.user.name`                                     | yes      | —           | Service account user.                                                  |
| `snowflake.private.key`                                   | yes      | —           | PKCS#8 base64, single line, headers stripped.                          |
| `snowflake.private.key.passphrase`                        | no       | —           | Required if the private key is encrypted (recommended).                |
| `snowflake.database.name`                                 | yes      | —           | Target database.                                                       |
| `snowflake.schema.name`                                   | yes      | —           | Target schema.                                                         |
| `snowflake.role.name`                                     | yes      | —           | **Direct grants only** — see `snowflake-setup.md`.                     |

## Serialization

| Key                              | Default                                              | Notes                                                                       |
|----------------------------------|------------------------------------------------------|------------------------------------------------------------------------------|
| `key.converter`                  | —                                                    | Usually `org.apache.kafka.connect.storage.StringConverter`.                  |
| `value.converter`                | —                                                    | `JsonConverter`, `AvroConverter`, or `ProtobufConverter` for schematization. |
| `value.converter.schemas.enable` | `false` for plain JSON; `true` for envelope-style    | If true, expect `{"schema":..., "payload":...}` shape.                       |
| `value.converter.schema.registry.url` | —                                               | Required for Avro/Protobuf.                                                  |

**Schematization compatibility:**
- ✅ `JsonConverter`, `AvroConverter`, `ProtobufConverter`
- ❌ `StringConverter`, `ByteArrayConverter` (opaque to schema detection)

## Schematization & schema evolution

| Key                                                          | Default     | Purpose                                                                  |
|--------------------------------------------------------------|-------------|--------------------------------------------------------------------------|
| `snowflake.enable.schematization`                            | `true`      | v4 default. Top-level keys become typed columns; `RECORD_CONTENT` drops. |
| `schema.registry.url`                                        | —           | For Avro/Protobuf only.                                                  |

To turn schematization on for a pre-existing table the connector role needs OWNERSHIP, then:

```sql
ALTER TABLE kafka_db.kafka_schema.sensors SET ENABLE_SCHEMA_EVOLUTION = TRUE;
```

What schema evolution can/can't do:

| Action                                          | Supported? |
|-------------------------------------------------|------------|
| Add a column when a new top-level key appears   | yes        |
| Drop NOT NULL when a field goes missing         | yes        |
| Rename a column                                 | no — creates a new column |
| Change a column type                            | no — type mismatches go to Error Table |
| Evolve Iceberg table schemas                    | no         |
| Top-level JSON ARRAY                            | no         |

## Validation & error handling

| Key                                              | Default       | Purpose                                                                              |
|--------------------------------------------------|---------------|--------------------------------------------------------------------------------------|
| `snowflake.validation`                           | `server_side` | `server_side` → bad rows go to `<table>$errors`. `client_side` → connector enforces, can DLQ. |
| `errors.tolerance`                               | `none`        | `all` to keep going on error. **`all` without DLQ = silent data loss.**              |
| `errors.deadletterqueue.topic.name`              | —             | DLQ Kafka topic for client-side rejects + converter failures.                        |
| `errors.log.enable`                              | `false`       | Log errors to connector log (set `true` while debugging).                            |
| `enable.task.fail.on.authorization.errors`       | `true`        | Fail the task on auth failures rather than silently retrying.                        |

## Migration from v3

| Key                                                             | Default | When to use                                                                                      |
|-----------------------------------------------------------------|---------|--------------------------------------------------------------------------------------------------|
| `snowflake.streaming.validate.compatibility.with.classic`       | `true`  | Set `false` for new installs to skip the v3-compatibility probe.                                 |
| `snowflake.streaming.classic.offset.migration`                  | `strict`| `strict` requires exact v3 channel name match. `best_effort` for cleaned/renamed channels.       |

## Tuning (only touch if needed)

| Key                                          | Default   | Notes                                                                       |
|----------------------------------------------|-----------|-----------------------------------------------------------------------------|
| `consumer.max.poll.interval.ms`              | `300000`  | Bump to `900000` if you see `CommitFailedException` + duplicate rows.       |
| `consumer.max.poll.records`                  | `500`     | Lower to `50` if records are large.                                         |
| `partition.assignment.strategy`              | (default) | Set `org.apache.kafka.clients.consumer.CooperativeStickyAssignor` for many partitions. |
| `consumer.heartbeat.interval.ms`             | `3000`    |                                                                             |
| `consumer.session.timeout.ms`                | `45000`   |                                                                             |
| `snowflake.cache.table.exists.expire.ms`     | `60000`   | Bump for large topic counts.                                                |
| `snowflake.cache.pipe.exists.expire.ms`      | `60000`   |                                                                             |

JVM heap: target ~50% of system RAM. The Rust SDK runs **off-heap**. Standard Kafka Connect tuning advice (give JVM 80%) is wrong for v4.

## Minimal working config (paste-ready)

```json
{
  "name": "sensors-snowflake-v4",
  "config": {
    "connector.class": "com.snowflake.kafka.connector.SnowflakeStreamingSinkConnector",
    "tasks.max": "1",
    "topics": "sensors",
    "snowflake.topic2table.map": "sensors:SENSORS",
    "snowflake.url.name": "https://XDOJQZJ-ZSB13251.snowflakecomputing.com",
    "snowflake.user.name": "KAFKA_CONNECTOR_USER",
    "snowflake.role.name": "KAFKA_CONNECTOR_ROLE",
    "snowflake.database.name": "KAFKA_DB",
    "snowflake.schema.name": "KAFKA_SCHEMA",
    "snowflake.private.key": "<base64-pkcs8-no-headers>",
    "snowflake.private.key.passphrase": "<passphrase>",

    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",

    "snowflake.enable.schematization": "true",
    "snowflake.validation": "server_side",
    "snowflake.streaming.validate.compatibility.with.classic": "false",

    "errors.tolerance": "none",
    "errors.log.enable": "true",
    "enable.task.fail.on.authorization.errors": "true"
  }
}
```
