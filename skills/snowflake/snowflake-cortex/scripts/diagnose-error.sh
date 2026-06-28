#!/usr/bin/env bash
# diagnose-error.sh (snowflake-cortex) — parse a raw error into an exact, applyable fix.
# Usage: diagnose-error.sh --error "<text>" [--role R] [--db D] [--wh W] [--catalog C]
# Emits the runtime envelope; degraded => do NOT retry-loop. See _runtime/contract.md.
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"
. "$RUNTIME/lib/diagnose.sh"
PLATFORM="snowflake-cortex"

ERR="" ROLE="" DB="" WH="" CAT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --error)   ERR="$2"; shift 2;;
    --role)    ROLE="$2"; shift 2;;
    --db)      DB="$2"; shift 2;;
    --wh)      WH="$2"; shift 2;;
    --catalog) CAT="$2"; shift 2;;
    *) shift;;
  esac
done
[ -n "$ERR" ] || { emit_fail "no --error provided" "diagnose-error.sh --error \"<text>\"" "$RC_UNKNOWN"; exit $?; }

diagnose "$PLATFORM" "$ERR" "${ROLE:-<ROLE>}" "${DB:-<DB>}" "${WH:-<WAREHOUSE>}" "${CAT:-<CATALOG>}"
data="$(jq -n --arg p "$PLATFORM" --arg e "$ERR" '{platform:$p, error:$e}')"
case "$DIAG_STATUS" in
  degraded) emit_degraded "$DIAG_DIAGNOSIS" "$DIAG_FIX" "$DIAG_CODE" "$data";;
  *)        emit_fail     "$DIAG_DIAGNOSIS" "$DIAG_FIX" "$DIAG_CODE" "$data";;
esac
exit $?
