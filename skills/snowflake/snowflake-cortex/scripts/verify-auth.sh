#!/usr/bin/env bash
# verify-auth.sh (Snowflake) — Connect & Ground auth troubleshooter.
# Key-pair (SNOWFLAKE_JWT) has no PAT expiry; confirm the key still maps to the user.
# On failure: clean envelope, exit RC_AUTH, runnable fix. See _runtime/contract.md.
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"

runtime_require snow jq || exit $?

# canonical handshake — `snow connection test` validates key→user mapping
out="$(snow connection test 2>&1)"
if [ $? -ne 0 ]; then
  echo "$out" >&2
  emit_fail "Snowflake connection test failed — key/user mapping or config invalid" \
            "snow connection test   # then check ~/.snowflake/keys/*.p8 (mode 600) and config.toml default_connection_name" \
            "$RC_AUTH"
  exit $?
fi

# confirm an authenticated query round-trips
who="$(snow sql -q "select current_user() as user, current_role() as role, current_account() as account" --format json 2>/dev/null)"
if [ -z "$who" ]; then
  emit_fail "connection test passed but query round-trip failed" \
            "snow sql -q \"select current_user()\"   # check warehouse/role grants" "$RC_AUTH"
  exit $?
fi

data="$(jq -n --argjson who "$who" '{
  user: ($who[0].USER), role: ($who[0].ROLE), account: ($who[0].ACCOUNT), auth: "key-pair (SNOWFLAKE_JWT)"
}')"
emit_ok "$data"
