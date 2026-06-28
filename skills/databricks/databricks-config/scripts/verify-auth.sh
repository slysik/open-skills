#!/usr/bin/env bash
# verify-auth.sh (Databricks) — Connect & Ground auth troubleshooter.
# PAT/OAuth expiry is the #1 session-killer — check it first.
# Profile: --profile <p> | $DATABRICKS_PROFILE | default slysik-aws.
# On failure: clean envelope, exit RC_AUTH, runnable fix.
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"

PROFILE="${DATABRICKS_PROFILE:-slysik-aws}"
[ "${1:-}" = "--profile" ] && { PROFILE="$2"; shift 2; }

runtime_require databricks jq || exit $?

# expiry / token check first
desc="$(databricks auth describe -p "$PROFILE" 2>&1)"
if [ $? -ne 0 ]; then
  echo "$desc" >&2
  emit_fail "Databricks auth describe failed for profile '$PROFILE' (expired or unconfigured)" \
            "databricks auth login -p $PROFILE   # re-establish OAuth/PAT" "$RC_AUTH"
  exit $?
fi

# confirm identity round-trips
me="$(databricks current-user me -p "$PROFILE" -o json 2>/dev/null)"
if [ $? -ne 0 ] || [ -z "$me" ]; then
  emit_fail "token present but identity call failed for profile '$PROFILE'" \
            "databricks auth login -p $PROFILE" "$RC_AUTH"
  exit $?
fi

data="$(jq -n --arg profile "$PROFILE" --argjson me "$me" '{
  profile: $profile, identity: ($me.userName // $me.displayName // null), active: ($me.active // null)
}')"
emit_ok "$data"
