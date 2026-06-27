#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=customer_support_smoke_lib.sh
source "$SCRIPT_DIR/customer_support_smoke_lib.sh"

CONNECTION="${SNOWFLAKE_CONNECTION_NAME:-default}"
DATABASE="${SNOWFLAKE_SMOKE_DATABASE:-OPEN_SKILLS_SMOKE}"
SCHEMA="${SNOWFLAKE_SMOKE_SCHEMA:-CUSTOMER_SUPPORT}"
WAREHOUSE="${SNOWFLAKE_SMOKE_WAREHOUSE:-OPEN_SKILLS_AI_WH}"
OUTPUT="$SMOKE_RAW_RESULTS_DIR/snowflake.json"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/smoke_snowflake_customer_support.sh [options]

Snowflake CLI customer-support smoke test. No MCP tools are used.

Options:
  --connection NAME      Snowflake CLI connection
  --database NAME        Target database
  --schema NAME          Target schema
  --warehouse NAME       X-Small smoke warehouse
  --output PATH          Result JSON path
  --dry-run              Generate data and print the command plan only
  -h, --help             Show help

Environment equivalents:
  SNOWFLAKE_CONNECTION_NAME, SNOWFLAKE_SMOKE_DATABASE,
  SNOWFLAKE_SMOKE_SCHEMA, SNOWFLAKE_SMOKE_WAREHOUSE
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --connection) CONNECTION="$2"; shift 2 ;;
    --database) DATABASE="$2"; shift 2 ;;
    --schema) SCHEMA="$2"; shift 2 ;;
    --warehouse) WAREHOUSE="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

smoke_begin "snowflake" "$OUTPUT"
SMOKE_CLI="snow"
SMOKE_SKILLS=("snowflake" "snowflake-cortex" "cortex-code")

for command_name in python3 jq snow; do
  smoke_require "$command_name" || true
done
if [[ "$SMOKE_STATUS" == "failed" ]]; then
  smoke_finish
  exit 1
fi

SMOKE_CLI_VERSION="$(snow --version 2>/dev/null | head -1 || true)"
smoke_generate_data
TARGET="$DATABASE.$SCHEMA"

if [[ "$DRY_RUN" -eq 1 ]]; then
  SMOKE_STATUS="dry_run"
  SMOKE_NOTES+=("would execute snow connection test and snow sql -f")
  SMOKE_NOTES+=("target: $TARGET; warehouse: $WAREHOUSE")
  SMOKE_FEATURE_GAPS+=("Cortex Analyst semantic-view provisioning follows the core Cortex AI/Search smoke")
  SMOKE_FEATURE_GAPS+=("token and credit history requires account-level usage access")
  smoke_finish
  exit 0
fi

if ! snow connection test -c "$CONNECTION" >/dev/null 2>&1; then
  SMOKE_ERRORS+=("Snowflake connection test failed: $CONNECTION")
  SMOKE_STATUS="failed"
  smoke_finish
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

prepare_sql() {
  local source_file="$1"
  local destination_file="$2"
  sed \
    -e "s/__DATABASE__/$DATABASE/g" \
    -e "s/__TARGET__/$TARGET/g" \
    -e "s/__WAREHOUSE__/$WAREHOUSE/g" \
    "$source_file" > "$destination_file"
}

prepare_sql "$SMOKE_EXAMPLE_ROOT/sql/snowflake/00_schema.sql" "$TMP_DIR/00_schema.sql"
prepare_sql "$SMOKE_GENERATED_DIR/sql/snowflake_inserts.sql" "$TMP_DIR/05_data.sql"
prepare_sql "$SMOKE_EXAMPLE_ROOT/sql/snowflake/10_solution.sql" "$TMP_DIR/10_solution.sql"

for sql_file in "$TMP_DIR/00_schema.sql" "$TMP_DIR/05_data.sql" "$TMP_DIR/10_solution.sql"; do
  if ! snow sql -c "$CONNECTION" -f "$sql_file" >/dev/null; then
    SMOKE_ERRORS+=("snow sql failed for $(basename "$sql_file")")
    SMOKE_STATUS="failed"
    break
  fi
done

if [[ "$SMOKE_STATUS" == "passed" ]]; then
  validation_sql="
SELECT
  IFF((SELECT COUNT(*) FROM $TARGET.support_tickets WHERE ticket_status IN ('open', 'pending')) = 5, 1, 0)
  + IFF((SELECT COUNT(*) FROM $TARGET.support_tickets WHERE customer_id = 'C001') = 2, 1, 0)
  + IFF(
      (SELECT COUNT(*) FROM $TARGET.support_tickets WHERE expected_category = 'billing') = 2
      AND (SELECT COUNT(*) FROM $TARGET.support_tickets WHERE expected_category = 'technical') = 2,
      1, 0
    )
  + IFF((SELECT COUNT(*) FROM $TARGET.orders WHERE order_status IN ('returned', 'refunded')) = 2, 1, 0)
  + IFF((
      SELECT COUNT(*) FROM $TARGET.support_tickets
      WHERE expected_category = 'technical' AND product_id = 'P003'
    ) = 2, 1, 0) AS eval_passed"
  if validation_output="$(snow sql -c "$CONNECTION" --format JSON --silent -q "$validation_sql")"; then
    SMOKE_TABLES_CREATED=7
    SMOKE_AI_ROWS=8
    SMOKE_EVAL_PASSED="$(
      jq -r '.[0].EVAL_PASSED // .[0].eval_passed // 0' <<<"$validation_output"
    )"
    search_config='{"query":"How do I recover a gateway that went offline after a firmware update?","columns":["article_id","title"],"limit":1}'
    rag_sql="SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW('$TARGET.KNOWLEDGE_SEARCH', '$search_config') AS RESULT"
    if rag_output="$(snow sql -c "$CONNECTION" --format JSON --silent -q "$rag_sql")"; then
      if [[ "$(
        jq -r '.[0].RESULT | fromjson | .results[0].article_id // empty' <<<"$rag_output"
      )" == "A002" ]]; then
        SMOKE_EVAL_PASSED=$((SMOKE_EVAL_PASSED + 1))
      else
        SMOKE_ERRORS+=("Snowflake Cortex Search did not rank article A002 first")
      fi
    fi
  else
    SMOKE_ERRORS+=("Snowflake validation query failed")
    SMOKE_STATUS="failed"
  fi
fi

SMOKE_FEATURE_GAPS+=("Cortex Analyst semantic-view provisioning is deferred until the core Cortex AI and Search smoke passes")
SMOKE_FEATURE_GAPS+=("account-level token and credit history can be unavailable to non-admin smoke identities")
SMOKE_NOTES+=("all execution used Snowflake CLI; Cortex Search is created by SQL and queried with SEARCH_PREVIEW")
smoke_finish
[[ "$SMOKE_STATUS" == "passed" ]]
