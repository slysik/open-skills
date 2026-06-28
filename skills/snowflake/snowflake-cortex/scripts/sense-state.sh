#!/usr/bin/env bash
# sense-state.sh (Snowflake) — JIT live-state sensor.
# Emits the runtime envelope with current identity + accessible objects.
# stdout = JSON only. See _runtime/contract.md.
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"

runtime_require snow jq || exit $?

# base identity
base="$(snow sql -q "select current_account() as account, current_role() as role, current_database() as database, current_warehouse() as warehouse" --format json 2>/dev/null)"
if [ $? -ne 0 ] || [ -z "$base" ]; then
  emit_fail "Snowflake query failed — token/connection invalid" \
            "snow connection test  (then re-run; see verify-auth.sh)" "$RC_AUTH"
  exit $?
fi

# accessible databases + warehouse states (best-effort; empty arrays on failure)
dbs="$(snow sql -q "show databases" --format json 2>/dev/null)";   [ -n "$dbs" ] || dbs='[]'
whs="$(snow sql -q "show warehouses" --format json 2>/dev/null)";  [ -n "$whs" ] || whs='[]'

data="$(jq -n --argjson base "$base" --argjson dbs "$dbs" --argjson whs "$whs" '
  {
    account:   ($base[0].ACCOUNT   // null),
    role:      ($base[0].ROLE      // null),
    database:  ($base[0].DATABASE  // null),
    warehouse: ($base[0].WAREHOUSE // null),
    databases:  [ $dbs[]? | (.name // .NAME) ] | map(select(. != null)),
    warehouses: [ $whs[]? | { name: (.name // .NAME), state: (.state // .STATE) } ]
  }')"

emit_ok "$data"
