#!/usr/bin/env bash
# produce-demo.sh — Publish 5 sample sensor records to topic 'sensors'.
#
# Uses the Kafka container's bundled console producer so you don't need
# any host-side Kafka tools. Topic is auto-created on first publish
# (default broker config allows this).
#
# Usage:  ./produce-demo.sh [count]
#         count defaults to 5.

set -euo pipefail

COUNT="${1:-5}"
TOPIC=sensors

if ! docker ps --format '{{.Names}}' | grep -q '^kafka$'; then
  echo "kafka container is not running. Did you 'docker compose up -d'?" >&2
  exit 1
fi

# Build a JSON-per-line payload, one row per record.
PAYLOAD=$(
  for i in $(seq 1 "$COUNT"); do
    printf '{"sensorId":%d,"psi":%d,"ts":"%s","location":{"site":"AUS-1","rack":%d}}\n' \
      "$i" \
      "$((400 + RANDOM % 100))" \
      "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
      "$((RANDOM % 8))"
  done
)

echo "Publishing $COUNT records to topic '$TOPIC'..."
echo "$PAYLOAD" \
  | docker exec -i kafka kafka-console-producer \
      --broker-list kafka:9092 \
      --topic "$TOPIC"

echo "Done.  Verify in Snowflake:"
echo "  SELECT * FROM kafka_db.kafka_schema.sensors ORDER BY record_metadata:offset DESC LIMIT $COUNT;"
