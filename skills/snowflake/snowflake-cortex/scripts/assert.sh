#!/usr/bin/env bash
# assert.sh (Snowflake) — executable assertions returning JSON pass/fail.
# On fail, chains into diagnose.sh so the envelope carries a runnable fix (Phase 4).
# Usage: assert.sh --check <connection|warehouse_running|table_exists|sql> [params]
#   warehouse_running --wh W
#   table_exists --db D --schema S --table T
#   sql --sql "<query>"   (passes if >=1 row)
# See _runtime/contract.md.
set -u
RUNTIME="$(cd "$(dirname "$0")/../../_runtime" && pwd)"
. "$RUNTIME/lib/emit.sh"; . "$RUNTIME/lib/diagnose.sh"
PLATFORM="snowflake-cortex"

CHECK="" WH="" DB="" SCHEMA="" TABLE="" SQL="" ROLE=""
while [ $# -gt 0 ]; do case "$1" in
  --check) CHECK="$2"; shift 2;; --wh) WH="$2"; shift 2;; --db) DB="$2"; shift 2;;
  --schema) SCHEMA="$2"; shift 2;; --table) TABLE="$2"; shift 2;; --sql) SQL="$2"; shift 2;;
  --role) ROLE="$2"; shift 2;; *) shift;; esac; done
[ -n "$CHECK" ] || { emit_fail "no --check provided" "assert.sh --check connection" "$RC_UNKNOWN"; exit $?; }

# run a query; sets QOUT (json) / QERR (text) / QRC
runq() { QOUT="$(snow sql -q "$1" --format json 2>/tmp/assert_err.$$)"; QRC=$?; QERR="$(cat /tmp/assert_err.$$ 2>/dev/null)"; rm -f /tmp/assert_err.$$; }
# fail via diagnose so we attach a fix
failx() { diagnose "$PLATFORM" "$1" "${ROLE:-<ROLE>}" "${DB:-<DB>}" "${WH:-<WAREHOUSE>}"; emit_fail "assert '$CHECK' failed: $DIAG_DIAGNOSIS" "$DIAG_FIX" "$DIAG_CODE" "$(jq -n --arg c "$CHECK" '{check:$c}')"; }

case "$CHECK" in
  connection)
    runq "select current_user() as u"
    [ "$QRC" -eq 0 ] && [ -n "$QOUT" ] && emit_ok "$(jq -n --arg c "$CHECK" '{check:$c,passed:true}')" || failx "${QERR:-authentication failed: token expired}"
    ;;
  warehouse_running)
    [ -n "$WH" ] || { emit_fail "warehouse_running needs --wh" "assert.sh --check warehouse_running --wh COMPUTE_WH" "$RC_UNKNOWN"; exit $?; }
    runq "show warehouses like '$WH'"
    if [ "$QRC" -ne 0 ]; then failx "${QERR:-warehouse $WH does not exist}"; else
      state="$(printf '%s' "$QOUT" | jq -r '.[0].state // .[0].STATE // empty')"
      if [ "$state" = "STARTED" ]; then emit_ok "$(jq -n --arg w "$WH" '{check:"warehouse_running",warehouse:$w,state:"STARTED",passed:true}')"
      else failx "warehouse '$WH' state=$state cannot be resumed automatically"; fi
    fi
    ;;
  table_exists)
    { [ -n "$DB" ] && [ -n "$SCHEMA" ] && [ -n "$TABLE" ]; } || { emit_fail "table_exists needs --db --schema --table" "assert.sh --check table_exists --db D --schema S --table T" "$RC_UNKNOWN"; exit $?; }
    runq "show tables like '$TABLE' in schema $DB.$SCHEMA"
    if [ "$QRC" -ne 0 ]; then failx "${QERR:-object $DB.$SCHEMA.$TABLE does not exist}"; else
      n="$(printf '%s' "$QOUT" | jq 'length')"
      [ "${n:-0}" -gt 0 ] && emit_ok "$(jq -n --arg t "$DB.$SCHEMA.$TABLE" '{check:"table_exists",table:$t,passed:true}')" || failx "table $DB.$SCHEMA.$TABLE does not exist"
    fi
    ;;
  sql)
    [ -n "$SQL" ] || { emit_fail "sql needs --sql" "assert.sh --check sql --sql \"select 1\"" "$RC_UNKNOWN"; exit $?; }
    runq "$SQL"
    if [ "$QRC" -ne 0 ]; then failx "${QERR:-query failed: object does not exist or no privilege}"; else
      n="$(printf '%s' "$QOUT" | jq 'length')"
      [ "${n:-0}" -gt 0 ] && emit_ok "$(jq -n --argjson n "${n:-0}" '{check:"sql",rows:$n,passed:true}')" || failx "query returned 0 rows"
    fi
    ;;
  *) emit_fail "unknown check '$CHECK'" "assert.sh --check connection|warehouse_running|table_exists|sql" "$RC_UNKNOWN";;
esac
exit $?
