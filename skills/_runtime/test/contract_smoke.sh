#!/usr/bin/env bash
# contract_smoke.sh — conformance gate for the runtime contract.
# Every emitter must print valid JSON on stdout, carry a non-empty `fix` on
# failure, and return the contract's exit codes. Tests the jq path AND the
# printf fallback (jq removed from PATH). bash 3.2 compatible.

set -u
RUNTIME="$(cd "$(dirname "$0")/.." && pwd)"
EMIT="$RUNTIME/lib/emit.sh"
fail=0

pass() { printf 'ok   %s\n' "$1"; }
bad()  { printf 'FAIL %s\n' "$1"; fail=1; }

# assert stdout is a single valid JSON object with the expected status field
check_json_status() {
  local name="$1" expect="$2" out="$3"
  if ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    bad "$name: stdout not valid JSON -> $out"; return
  fi
  local got
  got="$(printf '%s' "$out" | jq -r '.status')"
  if [ "$got" != "$expect" ]; then bad "$name: status=$got want=$expect"; return; fi
  pass "$name"
}

# assert exit code
check_code() {
  local name="$1" want="$2" got="$3"
  if [ "$got" -eq "$want" ]; then pass "$name (exit $got)"; else bad "$name: exit=$got want=$want"; fi
}

# assert .fix non-empty
check_fix() {
  local name="$1" out="$2" f
  f="$(printf '%s' "$out" | jq -r '.fix')"
  if [ -n "$f" ] && [ "$f" != "null" ]; then pass "$name (fix present)"; else bad "$name: empty fix"; fi
}

echo "== jq path =="

out="$(bash "$EMIT" ok '{"a":1}')"; code=$?
check_json_status "emit_ok valid JSON" "ok" "$out"
check_code        "emit_ok exit 0" 0 "$code"
adata="$(printf '%s' "$out" | jq -r '.data.a')"
[ "$adata" = "1" ] && pass "emit_ok preserves data" || bad "emit_ok lost data (a=$adata)"

out="$(bash "$EMIT" fail "Insufficient privileges" "GRANT USAGE ON DATABASE DEMO TO ROLE INGEST" 4)"; code=$?
check_json_status "emit_fail valid JSON" "fail" "$out"
check_code        "emit_fail exit RC_GRANT" 4 "$code"
check_fix         "emit_fail" "$out"

out="$(bash "$EMIT" fail "token expired" "snow connection test -c demo" 3)"; code=$?
check_code "auth fail exit RC_AUTH" 3 "$code"

out="$(bash "$EMIT" degraded "FeatureNotAvailable: tenant-gated" "request allowlisting; do not retry")"; code=$?
check_json_status "emit_degraded status" "degraded" "$out"
check_fix         "emit_degraded" "$out"

# embedded quotes / control chars must stay valid JSON
out="$(bash "$EMIT" fail 'has "quotes" and	tab' 'echo "fix"')"
check_json_status "escaping stays valid JSON" "fail" "$out"

echo "== printf fallback (no jq) =="

# strip jq from PATH; emit.sh must still emit valid JSON (verified with jq after)
nojq_out="$(PATH= /bin/bash "$EMIT" fail 'jq missing path' 'brew install jq' 1)"; code=$?
check_json_status "fallback valid JSON" "fail" "$nojq_out"
check_code        "fallback exit code" 1 "$code"
check_fix         "fallback" "$nojq_out"

echo
if [ "$fail" -eq 0 ]; then echo "ALL PASS"; else echo "SMOKE FAILED"; fi
exit "$fail"
