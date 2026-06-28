#!/usr/bin/env bash
# verify-auth.sh (Fabric) — Connect & Ground auth troubleshooter.
# Token-expiry check first; surfaces expiresOn so the agent can pre-empt expiry.
# On failure: clean envelope, exit RC_AUTH, runnable fix.
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"
FABRIC_API="https://api.fabric.microsoft.com"

runtime_require az jq || exit $?

tok="$(az account get-access-token --resource "$FABRIC_API" -o json 2>&1)"
if [ $? -ne 0 ] || [ -z "$tok" ]; then
  echo "$tok" >&2
  emit_fail "Azure/Fabric access token unavailable or expired" \
            "az login   # then re-run; for capacity/member ops use: fab auth status" "$RC_AUTH"
  exit $?
fi

# confirm the token actually works against Fabric REST
wss="$(az rest --method get --url "$FABRIC_API/v1/workspaces" --resource "$FABRIC_API" 2>/dev/null)"
if [ -z "$wss" ]; then
  emit_fail "token issued but Fabric REST call failed (tenant/permission?)" \
            "az login --tenant cae2035f-5769-4043-8ccc-caaa469650ba" "$RC_AUTH"
  exit $?
fi

data="$(jq -n --argjson tok "$tok" --argjson wss "$wss" '{
  identity: ($tok.subscription // null),
  expiresOn: ($tok.expiresOn // null),
  tenant: ($tok.tenant // null),
  workspaces: ($wss.value | length)
}')"
# overlay az account user.name as the human identity
ident="$(az account show --query "user.name" -o tsv 2>/dev/null)"
data="$(printf '%s' "$data" | jq --arg id "$ident" '.identity = ($id // .identity)')"
emit_ok "$data"
