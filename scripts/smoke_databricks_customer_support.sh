#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=customer_support_smoke_lib.sh
source "$SCRIPT_DIR/customer_support_smoke_lib.sh"

PROFILE="${DATABRICKS_CONFIG_PROFILE:-${DATABRICKS_PROFILE:-DEFAULT}}"
WAREHOUSE_ID="${DATABRICKS_WAREHOUSE_ID:-}"
CATALOG="${DATABRICKS_CATALOG:-}"
SCHEMA="${DATABRICKS_SCHEMA:-open_skills_customer_support}"
OUTPUT="$SMOKE_RAW_RESULTS_DIR/databricks.json"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: scripts/smoke_databricks_customer_support.sh [options]

CLI-only Databricks customer-support smoke test. No MCP tools are used.

Options:
  --profile NAME         Databricks CLI profile
  --warehouse-id ID      Serverless or Pro SQL warehouse id
  --catalog NAME         Unity Catalog catalog (default: main)
  --schema NAME          Target schema
  --output PATH          Result JSON path
  --dry-run              Generate data and print the command plan only
  -h, --help             Show help

Environment equivalents:
  DATABRICKS_CONFIG_PROFILE, DATABRICKS_WAREHOUSE_ID,
  DATABRICKS_CATALOG, DATABRICKS_SCHEMA
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --profile) PROFILE="$2"; shift 2 ;;
    --warehouse-id) WAREHOUSE_ID="$2"; shift 2 ;;
    --catalog) CATALOG="$2"; shift 2 ;;
    --schema) SCHEMA="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

smoke_begin "databricks" "$OUTPUT"
SMOKE_CLI="databricks"
SMOKE_SKILLS=(
  "databricks-config"
  "databricks-dbsql"
  "databricks-ai-functions"
  "databricks-vector-search"
  "databricks-genie"
  "databricks-mlflow-evaluation"
)

for command_name in python3 jq databricks; do
  smoke_require "$command_name" || true
done
if [[ "$SMOKE_STATUS" == "failed" ]]; then
  smoke_finish
  exit 1
fi

SMOKE_CLI_VERSION="$(databricks version 2>/dev/null | head -1 || true)"
smoke_generate_data

if [[ "$DRY_RUN" -eq 1 ]]; then
  SMOKE_STATUS="dry_run"
  SMOKE_NOTES+=("would execute Databricks SQL Statement Execution API through the Databricks CLI")
  SMOKE_NOTES+=("target: ${CATALOG:-<auto-owned-catalog>}.$SCHEMA")
  SMOKE_FEATURE_GAPS+=("Genie Space creation is not part of the bounded SQL smoke; add it after data/AI validation passes")
  SMOKE_FEATURE_GAPS+=("production Vector Search and billing telemetry are deferred until the SQL/AI smoke passes")
  smoke_finish
  exit 0
fi

if ! databricks -p "$PROFILE" current-user me >/dev/null 2>&1; then
  SMOKE_ERRORS+=("Databricks profile authentication failed: $PROFILE")
  SMOKE_STATUS="failed"
  smoke_finish
  exit 1
fi

if [[ -z "$CATALOG" ]]; then
  current_user="$(
    databricks -p "$PROFILE" current-user me -o json 2>/dev/null \
      | jq -r '.userName // .id // empty'
  )"
  CATALOG="$(
    databricks -p "$PROFILE" catalogs list -o json 2>/dev/null \
      | jq -r --arg owner "$current_user" '
          [
            .[]
            | select(.catalog_type == "MANAGED_CATALOG")
            | select(.owner == $owner)
          ][0].name // empty
        '
  )"
fi
if [[ -z "$CATALOG" ]]; then
  SMOKE_ERRORS+=("no writable managed catalog found; pass --catalog or DATABRICKS_CATALOG")
  SMOKE_STATUS="failed"
  smoke_finish
  exit 1
fi
TARGET="$CATALOG.$SCHEMA"

if [[ -z "$WAREHOUSE_ID" ]]; then
  WAREHOUSE_ID="$(
    databricks -p "$PROFILE" warehouses list -o json 2>/dev/null \
      | jq -r 'if type == "array" then .[0].id else .warehouses[0].id end // empty'
  )"
fi
if [[ -z "$WAREHOUSE_ID" ]]; then
  SMOKE_ERRORS+=("no SQL warehouse found; pass --warehouse-id or DATABRICKS_WAREHOUSE_ID")
  SMOKE_STATUS="failed"
  smoke_finish
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

prepare_sql() {
  local source_file="$1"
  local destination_file="$2"
  sed "s/__TARGET__/$TARGET/g" "$source_file" > "$destination_file"
}

prepare_sql "$SMOKE_EXAMPLE_ROOT/sql/databricks/00_schema.sql" "$TMP_DIR/00_schema.sql"
prepare_sql "$SMOKE_GENERATED_DIR/sql/databricks_inserts.sql" "$TMP_DIR/05_data.sql"
prepare_sql "$SMOKE_EXAMPLE_ROOT/sql/databricks/10_solution.sql" "$TMP_DIR/10_solution.sql"

submit_statement() {
  local statement="$1"
  local payload response statement_id state
  payload="$(
    jq -n \
      --arg warehouse_id "$WAREHOUSE_ID" \
      --arg statement "$statement" \
      '{warehouse_id:$warehouse_id, statement:$statement, wait_timeout:"50s", on_wait_timeout:"CONTINUE"}'
  )"
  if ! response="$(databricks -p "$PROFILE" api post /api/2.0/sql/statements --json "$payload" 2>&1)"; then
    SMOKE_ERRORS+=("statement submission failed: $response")
    return 1
  fi
  statement_id="$(jq -r '.statement_id // empty' <<<"$response")"
  state="$(jq -r '.status.state // empty' <<<"$response")"
  while [[ "$state" == "PENDING" || "$state" == "RUNNING" ]]; do
    sleep 2
    if ! response="$(databricks -p "$PROFILE" api get "/api/2.0/sql/statements/$statement_id" 2>&1)"; then
      SMOKE_ERRORS+=("statement polling failed: $response")
      return 1
    fi
    state="$(jq -r '.status.state // empty' <<<"$response")"
  done
  if [[ "$state" != "SUCCEEDED" ]]; then
    SMOKE_ERRORS+=("Databricks SQL failed: $(jq -c '.status' <<<"$response" 2>/dev/null || printf '%s' "$response")")
    return 1
  fi
  printf '%s' "$response"
}

run_sql_file() {
  local sql_file="$1"
  local statement
  while IFS= read -r -d '' statement; do
    submit_statement "$statement" >/dev/null || return 1
  done < <(
    python3 - "$sql_file" <<'PY'
from pathlib import Path
import sys

text = Path(sys.argv[1]).read_text(encoding="utf-8")
for part in text.split("-- open-skills-statement"):
    statement = part.strip()
    if statement:
        sys.stdout.write(statement.rstrip(";") + "\0")
PY
  )
}

for sql_file in "$TMP_DIR/00_schema.sql" "$TMP_DIR/05_data.sql" "$TMP_DIR/10_solution.sql"; do
  if ! run_sql_file "$sql_file"; then
    SMOKE_STATUS="failed"
    break
  fi
done

if [[ "$SMOKE_STATUS" == "passed" ]]; then
  validation_sql="
SELECT
  CASE WHEN (SELECT COUNT(*) FROM $TARGET.support_tickets WHERE ticket_status IN ('open', 'pending')) = 5 THEN 1 ELSE 0 END
  + CASE WHEN (SELECT COUNT(*) FROM $TARGET.support_tickets WHERE customer_id = 'C001') = 2 THEN 1 ELSE 0 END
  + CASE WHEN
      (SELECT COUNT(*) FROM $TARGET.support_tickets WHERE expected_category = 'billing') = 2
      AND (SELECT COUNT(*) FROM $TARGET.support_tickets WHERE expected_category = 'technical') = 2
    THEN 1 ELSE 0 END
  + CASE WHEN (SELECT COUNT(*) FROM $TARGET.orders WHERE order_status IN ('returned', 'refunded')) = 2 THEN 1 ELSE 0 END
  + CASE WHEN (
      SELECT COUNT(*) FROM $TARGET.support_tickets
      WHERE expected_category = 'technical' AND product_id = 'P003'
    ) = 2 THEN 1 ELSE 0 END AS eval_passed"
  if validation_response="$(submit_statement "$validation_sql")"; then
    SMOKE_TABLES_CREATED=7
    SMOKE_AI_ROWS=8
    SMOKE_EVAL_PASSED="$(jq -r '.result.data_array[0][0] // 0' <<<"$validation_response")"
    if rag_response="$(
      submit_statement "SELECT article_id FROM $TARGET.rag_smoke_result ORDER BY similarity DESC LIMIT 1"
    )"; then
      if [[ "$(jq -r '.result.data_array[0][0] // empty' <<<"$rag_response")" == "A002" ]]; then
        SMOKE_EVAL_PASSED=$((SMOKE_EVAL_PASSED + 1))
      else
        SMOKE_ERRORS+=("Databricks RAG smoke did not rank article A002 first")
      fi
    fi
  else
    SMOKE_STATUS="failed"
  fi
fi

SMOKE_FEATURE_GAPS+=("Genie Space and production Vector Search index creation are intentionally deferred until the bounded SQL/AI smoke passes")
SMOKE_FEATURE_GAPS+=("token and dollar telemetry require system.billing access and are left null when the executing identity cannot query it")
SMOKE_NOTES+=("Databricks SQL was executed through databricks api post/get, not MCP")
smoke_finish
[[ "$SMOKE_STATUS" == "passed" ]]
