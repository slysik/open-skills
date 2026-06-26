# Troubleshooting & monitoring

Sources:
- https://docs.snowflake.com/en/user-guide/kafka-connector-ts
- https://docs.snowflake.com/en/user-guide/kafka-connector-monitor

## The 10 gotchas (interview-bait)

### 1. Private key format

Connector wants raw base64 — no PEM headers, no newlines.

```bash
# WRONG — pasting the whole .p8 file:
-----BEGIN ENCRYPTED PRIVATE KEY-----
MIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAII...
-----END ENCRYPTED PRIVATE KEY-----

# RIGHT:
MIIFHDBOBgkqhkiG9w0BBQ0wQTApBgkqhkiG9w0BBQwwHAII...vQ==
```

```bash
# Helper:
grep -v "BEGIN\|END" rsa_key.p8 | tr -d '\n'
```

Key must be PKCS#8. If you generated with `openssl genrsa`, run it through `openssl pkcs8 -topk8` first.

### 2. JVM heap sizing for v4

The Rust Streaming SDK runs **off-heap**. Standard tuning advice (give JVM 80% of system RAM) starves it.

```bash
# v4 recommended
export KAFKA_HEAP_OPTS="-Xmx4G -Xms4G"     # for an 8 GB worker
# Leave ~50% for the OS + Rust SDK.
```

For v3 (Java only): ~5 MB per partition minimum, target 20–50 MB per partition in prod.

### 3. Buffer flush thresholds (v3)

Three thresholds, OR-ed. First one wins.

```properties
buffer.flush.time=10        # seconds — main latency lever
buffer.count.records=500    # lower if records are small but frequent
buffer.size.bytes=1000000   # lower if records are large
```

For v3 Snowpipe Streaming also tune:

```properties
snowflake.streaming.max.client.lag=10
snowflake.streaming.enable.single.buffer=true
```

v4 has no equivalent buffer knobs — flush behavior is owned by the Rust SDK.

### 4. Duplicate rows

Symptom: same `(topic, partition, offset)` appears twice. Root cause is almost always a Kafka consumer poll timeout.

```
Look for: CommitFailedException in connector logs
```

Fix:

```properties
consumer.max.poll.interval.ms=900000   # default 300000
consumer.max.poll.records=50           # default 500
```

### 5. Streaming channel offset migration error (v3 ≥ 2.1.0)

Channel naming changed; offset detection breaks on upgrade.

```properties
# Pin the old behaviour
enable.streaming.channel.offset.migration=false
```

For v3 → v4 migration:

```properties
snowflake.streaming.classic.offset.migration=strict       # exact channel name match
snowflake.streaming.classic.offset.migration=best_effort  # cleaned channels / new topics
```

### 6. Rebalancing loops on many topics

Symptom: `Channel is marked as closed` on repeat.

```properties
partition.assignment.strategy=org.apache.kafka.clients.consumer.CooperativeStickyAssignor
consumer.heartbeat.interval.ms=3000
consumer.session.timeout.ms=45000
consumer.max.poll.interval.ms=900000
tasks.max=<total partitions across all topics>
```

### 7. MIXED_RECORDS error (v3 Snowpipe)

Records from multiple schema versions in one file batch → COPY INTO fails.

Causes:
1. Schema changed mid-flight without schematization.
2. Avro without schema registry, mixed schema IDs in one batch.

Fixes:
- Enable schematization (requires Snowpipe Streaming).
- Force all producers through schema registry.
- Validate manually:
  ```sql
  GET @%table_stage_name file:///tmp/inspect/;
  COPY INTO sensors FROM @debug_stage VALIDATION_MODE = 'RETURN_ALL_ERRORS';
  ```

### 8. Schematization + wrong converter

```
Schema evolution is enabled but data isn't being unpacked into columns
```

Schematization needs a structured converter. **Not** `StringConverter` or `ByteArrayConverter`.

### 9. v4 role-hierarchy grants don't work

```sql
-- Does NOT work:
GRANT ROLE data_loader TO ROLE kafka_connector_role;       -- where data_loader has INSERT

-- DOES work:
GRANT INSERT ON TABLE my_table TO ROLE kafka_connector_role;
```

### 10. Connector name is baked into Snowflake object names

If you rename or recreate a connector, new stages/pipes are created. Old ones stay and accumulate files until manually dropped.

```sql
SHOW STAGES IN SCHEMA kafka_db.kafka_schema LIKE 'SNOWFLAKE_KAFKA_CONNECTOR_%';
SHOW PIPES  IN SCHEMA kafka_db.kafka_schema LIKE 'SNOWFLAKE_KAFKA_CONNECTOR_%';

DROP STAGE SNOWFLAKE_KAFKA_CONNECTOR_old_name_STAGE_sensors;
DROP PIPE  SNOWFLAKE_KAFKA_CONNECTOR_old_name_PIPE_sensors_0;
```

## Error Table vs DLQ

| Origin of the failure                           | Where the row goes                 |
|-------------------------------------------------|------------------------------------|
| Server-side validation (default v4)             | `<table>$errors` table in Snowflake|
| Client-side validation                          | DLQ Kafka topic (if configured)    |
| Converter / deserializer failure                | DLQ Kafka topic (if configured)    |
| `errors.tolerance=all` and **no DLQ topic set** | **Records silently dropped**       |

Inspecting:

```sql
-- Server-side errors (Snowflake)
SELECT * FROM kafka_db.kafka_schema.sensors$errors
ORDER BY inserted_at DESC LIMIT 20;
```

```bash
# Client-side / converter errors (Kafka DLQ topic)
kcat -b localhost:9092 -C -t sensors_dlq -o end -q -e | jq .
```

## Monitoring SQL — v3 (file-based) only

```sql
-- Pipe status (file-path connectors only)
SELECT SYSTEM$PIPE_STATUS(
  'kafka_db.kafka_schema.SNOWFLAKE_KAFKA_CONNECTOR_my_connector_PIPE_sensors_0'
);

-- COPY history for a target table (last 6h)
SELECT *
FROM   TABLE(INFORMATION_SCHEMA.COPY_HISTORY(
         TABLE_NAME => 'SENSORS',
         START_TIME => DATEADD('hours', -6, CURRENT_TIMESTAMP())
       ))
ORDER BY LAST_LOAD_TIME DESC;

-- Auto-created objects
SHOW STAGES IN SCHEMA kafka_db.kafka_schema;
SHOW PIPES  IN SCHEMA kafka_db.kafka_schema;
```

## Monitoring SQL — Snowpipe Streaming (v3-streaming + v4)

```sql
-- End-to-end latency using SnowflakeConnectorPushTime
SELECT
  RECORD_METADATA:topic::STRING                                            AS topic,
  RECORD_METADATA:partition::INT                                           AS partition,
  RECORD_METADATA:offset::INT                                              AS offset,
  TO_TIMESTAMP(RECORD_METADATA:SnowflakeConnectorPushTime::BIGINT / 1000)  AS pushed_at,
  CURRENT_TIMESTAMP()                                                      AS now,
  DATEDIFF('second',
    TO_TIMESTAMP(RECORD_METADATA:SnowflakeConnectorPushTime::BIGINT / 1000),
    CURRENT_TIMESTAMP())                                                   AS lag_secs
FROM kafka_db.kafka_schema.sensors
ORDER BY pushed_at DESC LIMIT 20;
```

## JMX metrics

```bash
# Enable JMX on the Connect worker
export KAFKA_JMX_OPTS="-Dcom.sun.management.jmxremote \
  -Dcom.sun.management.jmxremote.authenticate=false \
  -Dcom.sun.management.jmxremote.ssl=false \
  -Dcom.sun.management.jmxremote.port=9099"
```

MBean naming pattern:
```
snowflake.kafka.connector:connector=<connector_name>,task=<task_id>,category=<category>
```

Key categories:

- **offset**: `processedOffset`, `flushedOffset`, `committedOffset`, `purgedOffset` (v3) / `offsetPersistedInSnowflake` (Streaming).
- **task** (v4): per-task throughput, latency, retry counts.
- **file** (v3 only): `fileCountOnStage`, `fileCountOnIngestion`.
- **latency** (v3 file): `kafkaLag`, `commitLag`, `ingestionLag`.

A growing gap between `processedOffset` and `committedOffset` means the connector is falling behind.

## Useful log knobs

```bash
# Quiet the v4 Rust SDK
export SS_LOG_LEVEL=warn

# Better log context
export CONNECT_LOG4J_APPENDER_STDOUT_LAYOUT_CONVERSIONPATTERN="%d{ISO8601} %p %X{connector.context} %c{1}: %m%n"
```

## File-validation workflow (v3 Snowpipe path)

When Snowpipe fails to load a staged file:

```sql
-- 1. Find failed file on the table stage
LIST @%sensors;

-- 2. Pull it down
GET @%sensors/path/to/file.gz file:///tmp/failed/;

-- 3. Upload to a dedicated stage
CREATE STAGE debug_stage FILE_FORMAT = (TYPE = 'JSON');
PUT file:///tmp/failed/file.gz @debug_stage;

-- 4. Surface every error in one pass
COPY INTO sensors FROM @debug_stage
  VALIDATION_MODE = 'RETURN_ALL_ERRORS';

-- 5. Fix data, reload.
```
