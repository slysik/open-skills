#!/usr/bin/env bash
# emit.sh — shared JSON-envelope emitter for the self-healing blueprint runtime.
#
# Envelope (stdout only): {"status","data","diagnosis","fix"}
# Human text goes to stderr. See ../contract.md.
#
# Source it:   . "$RUNTIME/lib/emit.sh"
# Or run it:   emit.sh ok '{"a":1}' | jq .
#              emit.sh fail "diagnosis" "fix cmd" 3
#
# Works with or without jq (printf fallback). bash 3.2 compatible.

# --- exit-code constants -----------------------------------------------------
RC_OK=0
RC_UNKNOWN=1
RC_AUTH=3
RC_GRANT=4
RC_DRIFT=5
export RC_OK RC_UNKNOWN RC_AUTH RC_GRANT RC_DRIFT

# --- internal: JSON-escape a string when jq is unavailable -------------------
_emit_escape() {
  # escape backslash, double-quote, and control chars (tab/newline/cr)
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  s="${s//	/\\t}"
  s="${s//$'\n'/\\n}"
  s="${s//$'\r'/\\r}"
  printf '%s' "$s"
}

# --- core: print one envelope to stdout, return the given exit code ----------
# usage: _emit <status> <diagnosis> <fix> <exitcode> [data-json]
_emit() {
  local status="$1" diagnosis="$2" fix="$3" code="${4:-$RC_UNKNOWN}" data="${5:-}"
  [ -n "$data" ] || data='{}'
  if command -v jq >/dev/null 2>&1; then
    jq -cn \
      --arg s "$status" --arg d "$diagnosis" --arg f "$fix" \
      --argjson data "$data" \
      '{status:$s, data:$data, diagnosis:$d, fix:$f}'
  else
    printf '{"status":"%s","data":%s,"diagnosis":"%s","fix":"%s"}\n' \
      "$(_emit_escape "$status")" "$data" \
      "$(_emit_escape "$diagnosis")" "$(_emit_escape "$fix")"
  fi
  return "$code"
}

emit_ok()       { _emit ok       ""    ""    "$RC_OK"            "${1:-}"; }
emit_fail()     { _emit fail     "$1"  "$2"  "${3:-$RC_UNKNOWN}" "${4:-}"; }
emit_degraded() { _emit degraded "$1"  "$2"  "${3:-$RC_UNKNOWN}" "${4:-}"; }

# --- preflight: ensure required commands exist -------------------------------
# usage: runtime_require jq snow databricks
# emits a fail envelope (exit RC_UNKNOWN) naming the first missing dependency.
runtime_require() {
  local cmd
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
      emit_fail "required command not found: $cmd" "install $cmd and re-run" "$RC_UNKNOWN"
      return "$RC_UNKNOWN"
    fi
  done
  return 0
}

# --- CLI dispatch (when executed directly, not sourced) ----------------------
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  cmd="${1:-}"
  shift 2>/dev/null || true
  case "$cmd" in
    ok)       emit_ok "${1:-}" ;;
    fail)     emit_fail "${1:-}" "${2:-}" "${3:-$RC_UNKNOWN}" "${4:-}" ;;
    degraded) emit_degraded "${1:-}" "${2:-}" "${3:-$RC_UNKNOWN}" "${4:-}" ;;
    require)  runtime_require "$@" ;;
    *) echo "usage: emit.sh ok|fail|degraded|require ..." >&2; exit 2 ;;
  esac
  exit $?
fi
