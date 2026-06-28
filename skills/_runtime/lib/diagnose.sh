#!/usr/bin/env bash
# diagnose.sh — shared error-pattern catalog for the self-healing repair loop.
# Maps a raw platform error string to {status, diagnosis, fix, code}.
# Sets globals DIAG_STATUS / DIAG_DIAGNOSIS / DIAG_FIX / DIAG_CODE.
# Sourced by each <platform>/scripts/diagnose-error.sh. bash 3.2 compatible.
#
# Codes come from emit.sh (RC_AUTH=3, RC_GRANT=4, RC_DRIFT=5, RC_UNKNOWN=1).

_dmatch() { printf '%s' "$1" | grep -qiE "$2"; }

# diagnose <platform> <error> [role] [db] [warehouse] [catalog]
diagnose() {
  local platform="$1" err="$2"
  local role="${3:-<ROLE>}" db="${4:-<DB>}" wh="${5:-<WAREHOUSE>}" cat="${6:-<CATALOG>}"
  DIAG_STATUS="" DIAG_DIAGNOSIS="" DIAG_FIX="" DIAG_CODE="$RC_UNKNOWN"

  # --- NOT auto-fixable: tenant-gated preview features → degraded, never retry ---
  if _dmatch "$err" "FeatureNotAvailable|not available in your (tenant|region)|preview.*allowlist"; then
    DIAG_STATUS="degraded"
    DIAG_DIAGNOSIS="Tenant/preview-gated feature — allowlist, not a grant. Do not retry."
    DIAG_FIX="Request tenant allowlisting for this preview; no scriptable fix (e.g. ADB-UC managed tables in OneLake)."
    DIAG_CODE="$RC_UNKNOWN"; return 0
  fi

  # --- auth / token → route to verify-auth ---
  if _dmatch "$err" "401|unauthorized|invalid_client|token.*expired|authentication failed|cannot get access token"; then
    DIAG_STATUS="fail"
    DIAG_DIAGNOSIS="Authentication/token failure."
    DIAG_FIX="bash $platform/scripts/verify-auth.sh   # re-establish credentials"
    DIAG_CODE="$RC_AUTH"; return 0
  fi

  # --- suspended/resumable compute → state drift ---
  if _dmatch "$err" "warehouse.*(suspend|cannot be resumed)|no active warehouse"; then
    DIAG_STATUS="fail"
    DIAG_DIAGNOSIS="Warehouse suspended / not running."
    DIAG_FIX="ALTER WAREHOUSE $wh RESUME;"
    DIAG_CODE="$RC_DRIFT"; return 0
  fi

  # --- missing privilege → exact GRANT (platform-specific) ---
  if _dmatch "$err" "insufficient privileges|access control error|permission_denied|does not have.*privilege|not authorized to"; then
    DIAG_STATUS="fail"; DIAG_CODE="$RC_GRANT"
    case "$platform" in
      snowflake*|*cortex*|*kafka*)
        DIAG_DIAGNOSIS="Snowflake: role '$role' is missing a privilege."
        DIAG_FIX="GRANT USAGE ON DATABASE $db TO ROLE $role; GRANT USAGE ON ALL SCHEMAS IN DATABASE $db TO ROLE $role; GRANT SELECT ON ALL TABLES IN DATABASE $db TO ROLE $role;"
        ;;
      databricks*)
        DIAG_DIAGNOSIS="Databricks UC: principal lacks catalog/schema privilege."
        DIAG_FIX="GRANT USE CATALOG ON CATALOG $cat TO \`$role\`; GRANT USE SCHEMA, SELECT ON SCHEMA $cat.<schema> TO \`$role\`;"
        ;;
      *fabric*|*onelake*)
        DIAG_DIAGNOSIS="Fabric: identity lacks workspace/item role (guest cannot admin capacity)."
        DIAG_FIX="Assign the correct workspace role via fab CLI (member identity), e.g. fab acl set ... ; capacity ops need fabricdev, not guest."
        ;;
      *)
        DIAG_DIAGNOSIS="Missing privilege."
        DIAG_FIX="Grant the required privilege to $role."
        ;;
    esac
    return 0
  fi

  # --- object missing → drift / name check ---
  if _dmatch "$err" "does not exist|not found|object.*unknown|table or view not found"; then
    DIAG_STATUS="fail"
    DIAG_DIAGNOSIS="Referenced object does not exist (name/state drift)."
    DIAG_FIX="Re-run sense-state.sh and confirm the object name/path before retrying."
    DIAG_CODE="$RC_DRIFT"; return 0
  fi

  # --- unmatched → degraded with guidance (avoids blind retry) ---
  DIAG_STATUS="degraded"
  DIAG_DIAGNOSIS="Unrecognized error; no pattern matched."
  DIAG_FIX="Inspect manually: $(printf '%s' "$err" | head -c 160)"
  DIAG_CODE="$RC_UNKNOWN"; return 0
}
