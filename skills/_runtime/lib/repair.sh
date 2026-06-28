#!/usr/bin/env bash
# repair.sh — bounded self-healing retry harness.
# Runs a build command; on failure, diagnoses and (optionally) applies the fix,
# then retries. Max 3 attempts, then escalates to `degraded`.
#
# SAFETY: default is DRY — it emits the proposed fix and stops, because fixes
# (e.g. GRANT) mutate the account. Pass --auto-fix to actually run the fix.
#
# Usage:
#   repair_run <platform> <apply-fn> -- <build-cmd...>
#     <apply-fn> : a shell function name that executes "$DIAG_FIX" for the platform
#                  (only called when REPAIR_AUTO=1). Use ":" for none.
# Env: REPAIR_AUTO=1 enables apply; REPAIR_MAX overrides attempt cap (default 3).
set -u
: "${REPAIR_MAX:=3}"
: "${REPAIR_AUTO:=0}"

repair_run() {
  local platform="$1" apply_fn="$2"; shift 2
  [ "$1" = "--" ] && shift
  local attempt=1 out code
  while [ "$attempt" -le "$REPAIR_MAX" ]; do
    out="$("$@" 2>&1)"; code=$?
    if [ "$code" -eq 0 ]; then
      emit_ok "$(jq -n --arg p "$platform" --argjson a "$attempt" '{platform:$p, attempts:$a}')"
      return 0
    fi
    diagnose "$platform" "$out"
    if [ "$DIAG_STATUS" = "degraded" ]; then
      emit_degraded "$DIAG_DIAGNOSIS" "$DIAG_FIX" "$DIAG_CODE"
      return "$DIAG_CODE"
    fi
    if [ "$REPAIR_AUTO" != "1" ]; then
      emit_fail "$DIAG_DIAGNOSIS (dry-run; not applied)" "$DIAG_FIX" "$DIAG_CODE"
      return "$DIAG_CODE"
    fi
    echo "attempt $attempt failed; applying fix: $DIAG_FIX" >&2
    "$apply_fn" "$DIAG_FIX" || true
    attempt=$((attempt + 1))
  done
  emit_degraded "exhausted $REPAIR_MAX repair attempts on $platform" \
                "manual intervention required; last fix: $DIAG_FIX" "$RC_UNKNOWN"
  return "$RC_UNKNOWN"
}
