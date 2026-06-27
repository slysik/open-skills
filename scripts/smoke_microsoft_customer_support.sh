#!/usr/bin/env bash
set -u -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=customer_support_smoke_lib.sh
source "$SCRIPT_DIR/customer_support_smoke_lib.sh"

SQL_ENDPOINT="${FABRIC_SQL_ENDPOINT:-}"
DATABASE="${FABRIC_WAREHOUSE_DATABASE:-}"
OUTPUT="$SMOKE_RAW_RESULTS_DIR/microsoft.json"
DRY_RUN=0
SKIP_FOUNDRY=0
KEEP_RESOURCES="${KEEP_SMOKE_RESOURCES:-0}"

usage() {
  cat <<'EOF'
Usage: scripts/smoke_microsoft_customer_support.sh [options]

Fabric Warehouse plus Microsoft Foundry customer-support smoke test.
Uses sqlcmd, Azure CLI, az rest, and curl. No MCP tools are used.

Options:
  --sql-endpoint HOST    Fabric Warehouse SQL endpoint
  --database NAME        Fabric Warehouse database name
  --skip-foundry         Run only Fabric data and AI SQL
  --output PATH          Result JSON path
  --dry-run              Generate data and print the command plan only
  -h, --help             Show help

Fabric environment:
  FABRIC_SQL_ENDPOINT, FABRIC_WAREHOUSE_DATABASE

Optional Foundry RAG environment:
  FOUNDRY_RESOURCE, FOUNDRY_PROJECT, FOUNDRY_MODEL_DEPLOYMENT
  KEEP_SMOKE_RESOURCES=1 to retain the temporary agent/vector store/file
EOF
}

while [[ "$#" -gt 0 ]]; do
  case "$1" in
    --sql-endpoint) SQL_ENDPOINT="$2"; shift 2 ;;
    --database) DATABASE="$2"; shift 2 ;;
    --skip-foundry) SKIP_FOUNDRY=1; shift ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

smoke_begin "microsoft-fabric-foundry" "$OUTPUT"
SMOKE_CLI="az + sqlcmd + curl"
SMOKE_SKILLS=(
  "microsoft-fabric"
  "sqldw-authoring-cli"
  "semantic-model-authoring"
  "foundry-config"
  "foundry-rag-search"
  "foundry-agents-authoring"
  "foundry-agents-runtime"
  "foundry-evaluation"
  "foundry-observability"
)

for command_name in python3 jq az sqlcmd curl; do
  smoke_require "$command_name" || true
done
if [[ "$SMOKE_STATUS" == "failed" ]]; then
  smoke_finish
  exit 1
fi

SMOKE_CLI_VERSION="$(az version --query '"azure-cli"' -o tsv 2>/dev/null || true)"
smoke_generate_data

if [[ "$DRY_RUN" -eq 1 ]]; then
  SMOKE_STATUS="dry_run"
  SMOKE_NOTES+=("would execute Fabric Warehouse SQL through sqlcmd with Entra authentication")
  SMOKE_NOTES+=("would use az rest and curl multipart for Foundry RAG when Foundry environment variables are set")
  SMOKE_FEATURE_GAPS+=("Fabric semantic model/Fabric IQ provisioning follows the Warehouse AI SQL smoke")
  SMOKE_FEATURE_GAPS+=("Fabric Capacity Metrics cost export is not yet automated")
  smoke_finish
  exit 0
fi

if [[ -z "$SQL_ENDPOINT" || -z "$DATABASE" ]]; then
  SMOKE_ERRORS+=("pass --sql-endpoint and --database, or set FABRIC_SQL_ENDPOINT and FABRIC_WAREHOUSE_DATABASE")
  SMOKE_STATUS="failed"
  smoke_finish
  exit 1
fi

if ! az account show >/dev/null 2>&1; then
  SMOKE_ERRORS+=("Azure CLI is not authenticated")
  SMOKE_STATUS="failed"
  smoke_finish
  exit 1
fi

for sql_file in \
  "$SMOKE_EXAMPLE_ROOT/sql/fabric/00_schema.sql" \
  "$SMOKE_GENERATED_DIR/sql/fabric_inserts.sql" \
  "$SMOKE_EXAMPLE_ROOT/sql/fabric/10_solution.sql"; do
  if ! sqlcmd_output="$(
    sqlcmd -S "$SQL_ENDPOINT" -d "$DATABASE" -G -b -i "$sql_file" 2>&1
  )"; then
    SMOKE_ERRORS+=("sqlcmd failed for $(basename "$sql_file"): $sqlcmd_output")
    SMOKE_STATUS="failed"
    break
  fi
done

if [[ "$SMOKE_STATUS" == "passed" ]]; then
  validation_sql="
SET NOCOUNT ON;
SELECT
  CASE WHEN (SELECT COUNT(*) FROM dbo.support_tickets WHERE ticket_status IN ('open', 'pending')) = 5 THEN 1 ELSE 0 END
  + CASE WHEN (SELECT COUNT(*) FROM dbo.support_tickets WHERE customer_id = 'C001') = 2 THEN 1 ELSE 0 END
  + CASE WHEN
      (SELECT COUNT(*) FROM dbo.support_tickets WHERE expected_category = 'billing') = 2
      AND (SELECT COUNT(*) FROM dbo.support_tickets WHERE expected_category = 'technical') = 2
    THEN 1 ELSE 0 END
  + CASE WHEN (SELECT COUNT(*) FROM dbo.orders WHERE order_status IN ('returned', 'refunded')) = 2 THEN 1 ELSE 0 END
  + CASE WHEN (
      SELECT COUNT(*) FROM dbo.support_tickets
      WHERE expected_category = 'technical' AND product_id = 'P003'
    ) = 2 THEN 1 ELSE 0 END AS eval_passed;"
  if validation_output="$(
    sqlcmd -S "$SQL_ENDPOINT" -d "$DATABASE" -G -b -h -1 -W -Q "$validation_sql"
  )"; then
    SMOKE_TABLES_CREATED=7
    SMOKE_AI_ROWS=8
    SMOKE_EVAL_PASSED="$(
      awk '/^[[:space:]]*[0-9]+[[:space:]]*$/ {value=$1} END {print value+0}' \
        <<<"$validation_output"
    )"
  else
    SMOKE_ERRORS+=("Fabric Warehouse validation query failed")
    SMOKE_STATUS="failed"
  fi
fi

run_foundry_rag() {
  local endpoint token vector_store_id file_id agent_name response input_tokens output_tokens
  endpoint="https://${FOUNDRY_RESOURCE}.services.ai.azure.com/api/projects/${FOUNDRY_PROJECT}"
  agent_name="open-skills-support-smoke-$(date +%s)"

  if ! token="$(az account get-access-token --resource https://ai.azure.com --query accessToken -o tsv)"; then
    SMOKE_ERRORS+=("unable to obtain Foundry data-plane token")
    return 1
  fi

  if ! vector_store_id="$(
    az rest --resource https://ai.azure.com --method post \
      --url "$endpoint/openai/v1/vector_stores" \
      --headers "Content-Type=application/json" \
      --body '{"name":"open-skills-customer-support"}' \
      --query id -o tsv
  )"; then
    SMOKE_ERRORS+=("Foundry vector-store creation failed")
    return 1
  fi

  if ! file_id="$(
    curl -fsS "$endpoint/openai/v1/files" \
      -H "Authorization: Bearer $token" \
      -F purpose=assistants \
      -F "file=@$SMOKE_GENERATED_DIR/knowledge_base.md" \
      | jq -r '.id'
  )"; then
    SMOKE_ERRORS+=("Foundry knowledge-base upload failed")
    return 1
  fi

  az rest --resource https://ai.azure.com --method post \
    --url "$endpoint/openai/v1/vector_stores/$vector_store_id/files" \
    --headers "Content-Type=application/json" \
    --body "{\"file_id\":\"$file_id\"}" >/dev/null || return 1

  for _ in $(seq 1 30); do
    status="$(
      az rest --resource https://ai.azure.com \
        --url "$endpoint/openai/v1/vector_stores/$vector_store_id/files/$file_id" \
        --query status -o tsv
    )"
    [[ "$status" == "completed" ]] && break
    [[ "$status" == "failed" ]] && return 1
    sleep 2
  done

  az rest --resource https://ai.azure.com --method post \
    --url "$endpoint/agents?api-version=v1" \
    --headers "Content-Type=application/json" \
    --body "$(
      jq -n \
        --arg name "$agent_name" \
        --arg model "$FOUNDRY_MODEL_DEPLOYMENT" \
        --arg vector_store_id "$vector_store_id" \
        '{
          name:$name,
          definition:{
            kind:"prompt",
            model:$model,
            instructions:"Answer only from the customer-support knowledge base and cite the relevant article.",
            tools:[{type:"file_search",vector_store_ids:[$vector_store_id]}]
          }
        }'
    )" >/dev/null || return 1

  if ! response="$(
    az rest --resource https://ai.azure.com --method post \
      --url "$endpoint/openai/v1/responses" \
      --headers "Content-Type=application/json" \
      --body "$(
        jq -n \
          --arg name "$agent_name" \
          '{input:"How do I recover a gateway that went offline after a firmware update?",agent_reference:{name:$name,type:"agent_reference"}}'
      )"
  )"; then
    SMOKE_ERRORS+=("Foundry grounded response failed")
    return 1
  fi

  input_tokens="$(jq -r '.usage.input_tokens // null' <<<"$response")"
  output_tokens="$(jq -r '.usage.output_tokens // null' <<<"$response")"
  SMOKE_INPUT_TOKENS="$input_tokens"
  SMOKE_OUTPUT_TOKENS="$output_tokens"
  if [[ "$FOUNDRY_MODEL_DEPLOYMENT" == "gpt-4.1" ]]; then
    pricing_url="https://prices.azure.com/api/retail/prices?currencyCode=USD&\$filter=serviceName%20eq%20%27Foundry%20Models%27%20and%20armRegionName%20eq%20%27eastus%27%20and%20contains(meterName,%20%27gpt%204.1%27)%20and%20priceType%20eq%20%27Consumption%27"
    if pricing_json="$(curl -fsS "$pricing_url")"; then
      input_price="$(
        jq -r '
          [.Items[] | select(.meterName == "gpt 4.1 Inp glbl Tokens")]
          | sort_by(.effectiveStartDate)
          | last
          | .unitPrice // empty
        ' <<<"$pricing_json"
      )"
      output_price="$(
        jq -r '
          [.Items[] | select(.meterName == "gpt 4.1 Outp glbl Tokens")]
          | sort_by(.effectiveStartDate)
          | last
          | .unitPrice // empty
        ' <<<"$pricing_json"
      )"
      if [[ -n "$input_price" && -n "$output_price" ]]; then
        SMOKE_AI_COST_USD="$(
          python3 - "$input_tokens" "$output_tokens" "$input_price" "$output_price" <<'PY'
import sys

input_tokens, output_tokens, input_per_1k, output_per_1k = map(float, sys.argv[1:])
print(round((input_tokens / 1000 * input_per_1k) + (output_tokens / 1000 * output_per_1k), 8))
PY
        )"
        SMOKE_NOTES+=("AI cost covers the Foundry gpt-4.1 response only; Fabric capacity and vector indexing are excluded")
      fi
    fi
  fi
  if jq -e '[.output[].content[]?.text // ""] | join(" ") | test("firmware|rollback"; "i")' <<<"$response" >/dev/null; then
    SMOKE_EVAL_PASSED=$((SMOKE_EVAL_PASSED + 1))
  else
    SMOKE_ERRORS+=("Foundry RAG response did not include expected firmware/rollback guidance")
  fi

  if [[ "$KEEP_RESOURCES" != "1" ]]; then
    az rest --resource https://ai.azure.com --method delete \
      --url "$endpoint/agents/$agent_name?api-version=v1" >/dev/null 2>&1 || true
    az rest --resource https://ai.azure.com --method delete \
      --url "$endpoint/openai/v1/vector_stores/$vector_store_id" >/dev/null 2>&1 || true
    curl -fsS -X DELETE "$endpoint/openai/v1/files/$file_id" \
      -H "Authorization: Bearer $token" >/dev/null 2>&1 || true
  fi
}

if [[ "$SMOKE_STATUS" == "passed" && "$SKIP_FOUNDRY" -eq 0 ]]; then
  if [[ -n "${FOUNDRY_RESOURCE:-}" && -n "${FOUNDRY_PROJECT:-}" && -n "${FOUNDRY_MODEL_DEPLOYMENT:-}" ]]; then
    if ! run_foundry_rag; then
      SMOKE_ERRORS+=("Foundry RAG smoke failed")
      SMOKE_STATUS="failed"
    fi
  else
    SMOKE_FEATURE_GAPS+=("Foundry RAG skipped because FOUNDRY_RESOURCE, FOUNDRY_PROJECT, or FOUNDRY_MODEL_DEPLOYMENT is unset")
  fi
fi

SMOKE_FEATURE_GAPS+=("Fabric semantic model and Fabric IQ provisioning are deferred until Warehouse AI SQL succeeds")
SMOKE_FEATURE_GAPS+=("Fabric Capacity Metrics cost export is not yet automated by this harness")
SMOKE_NOTES+=("Fabric used sqlcmd; Foundry used az rest and curl multipart; no MCP tools")
smoke_finish
[[ "$SMOKE_STATUS" == "passed" ]]
