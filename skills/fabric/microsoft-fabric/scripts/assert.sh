#!/usr/bin/env bash
# assert.sh (Fabric) — executable assertions returning JSON pass/fail.
# On fail, chains into diagnose.sh for a runnable fix (Phase 4).
# Usage: assert.sh --check <token|workspace_exists|capacity_active> [params]
#   workspace_exists --name N
#   capacity_active --name N
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"; . "$RUNTIME/lib/diagnose.sh"
PLATFORM="microsoft-fabric"
FABRIC_API="https://api.fabric.microsoft.com"

CHECK="" NAME=""
while [ $# -gt 0 ]; do case "$1" in
  --check) CHECK="$2"; shift 2;; --name) NAME="$2"; shift 2;; *) shift;; esac; done
[ -n "$CHECK" ] || { emit_fail "no --check provided" "assert.sh --check token" "$RC_UNKNOWN"; exit $?; }

failx() { diagnose "$PLATFORM" "$1"; emit_fail "assert '$CHECK' failed: $DIAG_DIAGNOSIS" "$DIAG_FIX" "$DIAG_CODE" "$(jq -n --arg c "$CHECK" '{check:$c}')"; }

case "$CHECK" in
  token)
    out="$(az account get-access-token --resource "$FABRIC_API" 2>&1)"
    [ $? -eq 0 ] && emit_ok "$(jq -n '{check:"token",passed:true}')" || failx "$out"
    ;;
  workspace_exists)
    [ -n "$NAME" ] || { emit_fail "workspace_exists needs --name" "assert.sh --check workspace_exists --name 'My workspace'" "$RC_UNKNOWN"; exit $?; }
    out="$(az rest --method get --url "$FABRIC_API/v1/workspaces" --resource "$FABRIC_API" 2>&1)"
    if [ $? -ne 0 ]; then failx "$out"; else
      hit="$(printf '%s' "$out" | jq -r --arg n "$NAME" '[.value[]?|select(.displayName==$n)]|length')"
      [ "${hit:-0}" -gt 0 ] && emit_ok "$(jq -n --arg n "$NAME" '{check:"workspace_exists",name:$n,passed:true}')" || failx "workspace '$NAME' does not exist"
    fi
    ;;
  capacity_active)
    [ -n "$NAME" ] || { emit_fail "capacity_active needs --name" "assert.sh --check capacity_active --name Trial-..." "$RC_UNKNOWN"; exit $?; }
    out="$(az rest --method get --url "$FABRIC_API/v1/capacities" --resource "$FABRIC_API" 2>&1)"
    if [ $? -ne 0 ]; then failx "$out"; else
      state="$(printf '%s' "$out" | jq -r --arg n "$NAME" '.value[]?|select(.displayName==$n)|.state' | head -1)"
      [ "$state" = "Active" ] && emit_ok "$(jq -n --arg n "$NAME" '{check:"capacity_active",name:$n,state:"Active",passed:true}')" || failx "capacity '$NAME' state=${state:-not-found}"
    fi
    ;;
  *) emit_fail "unknown check '$CHECK'" "assert.sh --check token|workspace_exists|capacity_active" "$RC_UNKNOWN";;
esac
exit $?
