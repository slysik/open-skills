#!/usr/bin/env bash
# assert.sh (Databricks) — executable assertions returning JSON pass/fail.
# On fail, chains into diagnose.sh for a runnable fix (Phase 4).
# Usage: assert.sh --check <connection|catalog_exists|warehouse_running> [params]
#   catalog_exists --catalog C
#   warehouse_running --name N
# Profile: --profile p | $DATABRICKS_PROFILE | default slysik-aws.
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"; . "$RUNTIME/lib/diagnose.sh"
PLATFORM="databricks-config"
PROFILE="${DATABRICKS_PROFILE:-slysik-aws}"

CHECK="" CAT="" NAME="" ROLE=""
while [ $# -gt 0 ]; do case "$1" in
  --check) CHECK="$2"; shift 2;; --catalog) CAT="$2"; shift 2;; --name) NAME="$2"; shift 2;;
  --profile) PROFILE="$2"; shift 2;; --role) ROLE="$2"; shift 2;; *) shift;; esac; done
[ -n "$CHECK" ] || { emit_fail "no --check provided" "assert.sh --check connection" "$RC_UNKNOWN"; exit $?; }

failx() { diagnose "$PLATFORM" "$1" "${ROLE:-<PRINCIPAL>}" "" "" "${CAT:-<CATALOG>}"; emit_fail "assert '$CHECK' failed: $DIAG_DIAGNOSIS" "$DIAG_FIX" "$DIAG_CODE" "$(jq -n --arg c "$CHECK" '{check:$c}')"; }

case "$CHECK" in
  connection)
    out="$(databricks current-user me -p "$PROFILE" -o json 2>&1)"
    [ $? -eq 0 ] && emit_ok "$(jq -n --arg c "$CHECK" '{check:$c,passed:true}')" || failx "$out"
    ;;
  catalog_exists)
    [ -n "$CAT" ] || { emit_fail "catalog_exists needs --catalog" "assert.sh --check catalog_exists --catalog samples" "$RC_UNKNOWN"; exit $?; }
    out="$(databricks catalogs get "$CAT" -p "$PROFILE" -o json 2>&1)"
    if [ $? -eq 0 ]; then emit_ok "$(jq -n --arg c "$CAT" '{check:"catalog_exists",catalog:$c,passed:true}')"
    else failx "catalog $CAT does not exist or no privilege: $out"; fi
    ;;
  warehouse_running)
    [ -n "$NAME" ] || { emit_fail "warehouse_running needs --name" "assert.sh --check warehouse_running --name 'Serverless Starter Warehouse'" "$RC_UNKNOWN"; exit $?; }
    out="$(databricks warehouses list -p "$PROFILE" -o json 2>&1)"
    if [ $? -ne 0 ]; then failx "$out"; else
      state="$(printf '%s' "$out" | jq -r --arg n "$NAME" '.[]|select(.name==$n)|.state' | head -1)"
      [ "$state" = "RUNNING" ] && emit_ok "$(jq -n --arg n "$NAME" '{check:"warehouse_running",name:$n,state:"RUNNING",passed:true}')" || failx "warehouse '$NAME' state=${state:-not-found}"
    fi
    ;;
  *) emit_fail "unknown check '$CHECK'" "assert.sh --check connection|catalog_exists|warehouse_running" "$RC_UNKNOWN";;
esac
exit $?
