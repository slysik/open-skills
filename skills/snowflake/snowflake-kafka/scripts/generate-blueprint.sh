#!/usr/bin/env bash
# generate-blueprint.sh (Snowflake-Kafka) — zero-boilerplate scaffolder.
# Senses live account state, resolves {{TOKENS}} in the blueprint templates, and
# writes a ready-to-run pattern directory. Secrets stay as placeholders.
#
# Usage: generate-blueprint.sh --pattern kafka-to-snowflake [--out DIR]
#          [--db DB --schema S --role R --user U --wh W --topic T --table T]
# stdout = JSON envelope. See _runtime/contract.md.
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
SKILL="$(cd "$HERE/.." && pwd)"
RUNTIME="$(cd "$SKILL/../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"

runtime_require snow jq sed || exit $?

PATTERN="" OUT=""
DB="KAFKA_DB" SCHEMA="KAFKA_SCHEMA" ROLE="KAFKA_CONNECTOR_ROLE" USERNAME="KAFKA_CONNECTOR_USER"
WH="KAFKA_WH" TOPIC="sensors" TABLE="SENSORS"
while [ $# -gt 0 ]; do case "$1" in
  --pattern) PATTERN="$2"; shift 2;; --out) OUT="$2"; shift 2;;
  --db) DB="$2"; shift 2;; --schema) SCHEMA="$2"; shift 2;; --role) ROLE="$2"; shift 2;;
  --user) USERNAME="$2"; shift 2;; --wh) WH="$2"; shift 2;; --topic) TOPIC="$2"; shift 2;;
  --table) TABLE="$2"; shift 2;; *) shift;; esac; done

[ -n "$PATTERN" ] || { emit_fail "no --pattern provided" "generate-blueprint.sh --pattern kafka-to-snowflake" "$RC_UNKNOWN"; exit $?; }
TMPL="$SKILL/blueprints/$PATTERN"
[ -d "$TMPL" ] || { emit_fail "unknown pattern '$PATTERN'" "ls $SKILL/blueprints" "$RC_UNKNOWN"; exit $?; }
[ -n "$OUT" ] || OUT="./blueprint-out/$PATTERN"

# --- JIT sense: account must be real, else block (no half-filled template) ---
ACCOUNT="$(snow sql -q "select current_account() as a" --format json 2>/dev/null | jq -r '.[0].A // empty')"
if [ -z "$ACCOUNT" ]; then
  emit_fail "could not sense Snowflake account (auth?)" \
            "bash $SKILL/../snowflake-cortex/scripts/verify-auth.sh" "$RC_AUTH"
  exit $?
fi

mkdir -p "$OUT"
resolve() {
  sed -e "s|{{ACCOUNT}}|$ACCOUNT|g" -e "s|{{DB}}|$DB|g" -e "s|{{SCHEMA}}|$SCHEMA|g" \
      -e "s|{{CONN_ROLE}}|$ROLE|g" -e "s|{{CONN_USER}}|$USERNAME|g" -e "s|{{WAREHOUSE}}|$WH|g" \
      -e "s|{{TOPIC}}|$TOPIC|g" -e "s|{{TABLE}}|$TABLE|g" "$1"
}

count=0
for f in "$TMPL"/*; do
  base="$(basename "$f")"
  resolve "$f" > "$OUT/$base"
  count=$((count + 1))
done

# secret placeholders intentionally left: {{PUBLIC_KEY}}, <PRIVATE_KEY_BASE64>, <PRIVATE_KEY_PASSPHRASE>
data="$(jq -n --arg dir "$OUT" --argjson files "$count" --arg acct "$ACCOUNT" \
  --arg db "$DB" --arg schema "$SCHEMA" --arg role "$ROLE" --arg wh "$WH" --arg tbl "$TABLE" '{
    dir:$dir, files:$files, account:$acct,
    resolved:{db:$db, schema:$schema, role:$role, warehouse:$wh, table:$tbl},
    secrets_pending:["{{PUBLIC_KEY}}","<PRIVATE_KEY_BASE64>","<PRIVATE_KEY_PASSPHRASE>"]
  }')"
echo "blueprint '$PATTERN' written to $OUT ($count files); fill secret placeholders before deploy" >&2
emit_ok "$data"
