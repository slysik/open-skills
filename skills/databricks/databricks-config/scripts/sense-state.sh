#!/usr/bin/env bash
# sense-state.sh (Databricks) — JIT live-state sensor.
# Emits the runtime envelope with current identity + catalogs + warehouses.
# Profile: --profile <p> | $DATABRICKS_PROFILE | default slysik-aws.
# stdout = JSON only. See _runtime/contract.md.
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"

PROFILE="${DATABRICKS_PROFILE:-slysik-aws}"
[ "${1:-}" = "--profile" ] && { PROFILE="$2"; shift 2; }

runtime_require databricks jq || exit $?

me="$(databricks current-user me -p "$PROFILE" -o json 2>/dev/null)"
if [ $? -ne 0 ] || [ -z "$me" ]; then
  emit_fail "Databricks auth failed for profile '$PROFILE'" \
            "databricks auth login -p $PROFILE  (or pass --profile <name>)" "$RC_AUTH"
  exit $?
fi

cats="$(databricks catalogs list -p "$PROFILE" -o json 2>/dev/null)";   [ -n "$cats" ] || cats='[]'
whs="$(databricks warehouses list -p "$PROFILE" -o json 2>/dev/null)";  [ -n "$whs" ] || whs='[]'

data="$(jq -n --arg profile "$PROFILE" --argjson me "$me" --argjson cats "$cats" --argjson whs "$whs" '
  {
    profile:  $profile,
    identity: ($me.userName // $me.displayName // null),
    active:   ($me.active // null),
    catalogs:   [ $cats[]? | .name ] | map(select(. != null)),
    warehouses: [ $whs[]?  | { name: .name, state: .state } ]
  }')"

emit_ok "$data"
