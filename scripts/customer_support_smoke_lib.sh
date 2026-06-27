#!/usr/bin/env bash

SMOKE_REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SMOKE_EXAMPLE_ROOT="$SMOKE_REPO_ROOT/examples/customer-support-ai"
SMOKE_GENERATED_DIR="$SMOKE_EXAMPLE_ROOT/generated"
SMOKE_RAW_RESULTS_DIR="$SMOKE_REPO_ROOT/reports/customer-support-ai/raw"

smoke_now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

smoke_now_epoch() {
  date +%s
}

smoke_require() {
  local command_name="$1"
  if ! command -v "$command_name" >/dev/null 2>&1; then
    SMOKE_ERRORS+=("required command not found: $command_name")
    SMOKE_STATUS="failed"
    return 1
  fi
}

smoke_array_json() {
  if [[ "$#" -eq 0 ]]; then
    printf '[]'
    return
  fi
  printf '%s\n' "$@" | jq -R . | jq -s .
}

smoke_begin() {
  SMOKE_PLATFORM="$1"
  SMOKE_OUTPUT="$2"
  SMOKE_STATUS="passed"
  SMOKE_STARTED_AT="$(smoke_now_iso)"
  SMOKE_STARTED_EPOCH="$(smoke_now_epoch)"
  SMOKE_CLI=""
  SMOKE_CLI_VERSION=""
  SMOKE_TABLES_CREATED=0
  SMOKE_AI_ROWS=0
  SMOKE_EVAL_TOTAL=10
  SMOKE_EVAL_PASSED=0
  SMOKE_INPUT_TOKENS="null"
  SMOKE_OUTPUT_TOKENS="null"
  SMOKE_EMBEDDING_TOKENS="null"
  SMOKE_CACHED_TOKENS="null"
  SMOKE_COMPUTE_COST_USD="null"
  SMOKE_AI_COST_USD="null"
  SMOKE_TOTAL_COST_USD="null"
  SMOKE_P50_MS="null"
  SMOKE_P95_MS="null"
  SMOKE_ERRORS=()
  SMOKE_FEATURE_GAPS=()
  SMOKE_NOTES=()
  SMOKE_SKILLS=()
  mkdir -p "$(dirname "$SMOKE_OUTPUT")"
}

smoke_generate_data() {
  python3 "$SMOKE_EXAMPLE_ROOT/data/generate.py" --output "$SMOKE_GENERATED_DIR" >/dev/null
}

smoke_finish() {
  local finished_at duration row_counts errors gaps notes skills
  set +u
  finished_at="$(smoke_now_iso)"
  duration=$(( $(smoke_now_epoch) - SMOKE_STARTED_EPOCH ))
  row_counts="{}"
  if [[ -f "$SMOKE_GENERATED_DIR/manifest.json" ]]; then
    row_counts="$(jq -c '.row_counts' "$SMOKE_GENERATED_DIR/manifest.json")"
  fi
  errors="$(smoke_array_json "${SMOKE_ERRORS[@]}")"
  gaps="$(smoke_array_json "${SMOKE_FEATURE_GAPS[@]}")"
  notes="$(smoke_array_json "${SMOKE_NOTES[@]}")"
  skills="$(smoke_array_json "${SMOKE_SKILLS[@]}")"
  set -u

  if ! jq -n \
    --arg platform "$SMOKE_PLATFORM" \
    --arg status "$SMOKE_STATUS" \
    --arg started_at "$SMOKE_STARTED_AT" \
    --arg finished_at "$finished_at" \
    --arg cli "$SMOKE_CLI" \
    --arg cli_version "$SMOKE_CLI_VERSION" \
    --argjson duration_seconds "$duration" \
    --argjson tables_created "$SMOKE_TABLES_CREATED" \
    --argjson row_counts "$row_counts" \
    --argjson ai_rows "$SMOKE_AI_ROWS" \
    --argjson eval_total "$SMOKE_EVAL_TOTAL" \
    --argjson eval_passed "$SMOKE_EVAL_PASSED" \
    --argjson input_tokens "$SMOKE_INPUT_TOKENS" \
    --argjson output_tokens "$SMOKE_OUTPUT_TOKENS" \
    --argjson embedding_tokens "$SMOKE_EMBEDDING_TOKENS" \
    --argjson cached_tokens "$SMOKE_CACHED_TOKENS" \
    --argjson compute_cost_usd "$SMOKE_COMPUTE_COST_USD" \
    --argjson ai_cost_usd "$SMOKE_AI_COST_USD" \
    --argjson total_cost_usd "$SMOKE_TOTAL_COST_USD" \
    --argjson p50_ms "$SMOKE_P50_MS" \
    --argjson p95_ms "$SMOKE_P95_MS" \
    --argjson errors "$errors" \
    --argjson feature_gaps "$gaps" \
    --argjson notes "$notes" \
    --argjson skills "$skills" \
    '{
      platform: $platform,
      status: $status,
      started_at: $started_at,
      finished_at: $finished_at,
      duration_seconds: $duration_seconds,
      cli: $cli,
      cli_version: $cli_version,
      tables_created: $tables_created,
      row_counts: $row_counts,
      ai_rows: $ai_rows,
      evaluation: {total: $eval_total, passed: $eval_passed},
      tokens: {
        input: $input_tokens,
        output: $output_tokens,
        embedding: $embedding_tokens,
        cached: $cached_tokens
      },
      cost_usd: {
        compute: $compute_cost_usd,
        ai: $ai_cost_usd,
        total: $total_cost_usd
      },
      latency_ms: {p50: $p50_ms, p95: $p95_ms},
      errors: $errors,
      feature_gaps: $feature_gaps,
      notes: $notes,
      skills_expected: $skills
    }' > "$SMOKE_OUTPUT"; then
    printf 'failed to write smoke result: %s\n' "$SMOKE_OUTPUT" >&2
    return 1
  fi

  printf '%s\n' "$SMOKE_OUTPUT"
}
