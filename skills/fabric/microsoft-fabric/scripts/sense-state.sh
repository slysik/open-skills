#!/usr/bin/env bash
# sense-state.sh (Fabric / OneLake) — JIT live-state sensor.
# Emits the runtime envelope with identity + workspaces + capacities.
# stdout = JSON only. See _runtime/contract.md.
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"
FABRIC_API="https://api.fabric.microsoft.com"

runtime_require az jq || exit $?

# token preflight — fail clean to verify-auth on expiry
if ! az account get-access-token --resource "$FABRIC_API" >/dev/null 2>&1; then
  emit_fail "Azure/Fabric token unavailable or expired" \
            "az login  (then re-run; see verify-auth.sh)" "$RC_AUTH"
  exit $?
fi

identity="$(az account show --query 'user.name' -o tsv 2>/dev/null)"
wss="$(az rest --method get --url "$FABRIC_API/v1/workspaces"  --resource "$FABRIC_API" 2>/dev/null)";  [ -n "$wss" ] || wss='{}'
caps="$(az rest --method get --url "$FABRIC_API/v1/capacities" --resource "$FABRIC_API" 2>/dev/null)"; [ -n "$caps" ] || caps='{}'

data="$(jq -n --arg identity "$identity" --argjson wss "$wss" --argjson caps "$caps" '
  {
    identity: ($identity // null),
    workspaces: [ $wss.value[]?  | { id: .id, name: .displayName } ],
    capacities: [ $caps.value[]? | { name: .displayName, sku: .sku, state: .state } ]
  }')"

emit_ok "$data"
