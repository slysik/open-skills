#!/usr/bin/env bash
# open-skills :: one-step skills installer
# Databricks · Microsoft Fabric · Snowflake · Foundry agent skills for Claude Code, Codex, and pi.
#
#   Install everything (Claude Code):
#     curl -fsSL https://raw.githubusercontent.com/slysik/open-skills/main/install.sh | bash
#
#   Install one platform:
#     curl -fsSL .../install.sh | bash -s -- --platform snowflake
#
#   Install one skill, into Codex:
#     curl -fsSL .../install.sh | bash -s -- --harness codex databricks-genie
#
#   List what is available:
#     curl -fsSL .../install.sh | bash -s -- --list
#
set -euo pipefail

REPO="slysik/open-skills"
BRANCH="${OPEN_SKILLS_BRANCH:-${DSF_BRANCH:-main}}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
TARBALL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd)"

# ---- colours -------------------------------------------------------------
if [ -t 1 ]; then B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; C=$'\033[36m'; Y=$'\033[33m'; R=$'\033[31m'; X=$'\033[0m'
else B=""; D=""; G=""; C=""; Y=""; R=""; X=""; fi
say()  { printf "%s\n" "$*"; }
ok()   { printf "${G}✓${X} %s\n" "$*"; }
warn() { printf "${Y}!${X} %s\n" "$*"; }
die()  { printf "${R}✗ %s${X}\n" "$*" >&2; exit 1; }

# ---- args ----------------------------------------------------------------
HARNESS=""; DEST=""; LIST=0; WANT_ALL=0; LOCAL=0; VERIFY=0
PLATFORMS=(); SKILLS=()
PLATFORM_NAMES="databricks fabric snowflake foundry"
add_platform_arg() {
  case "$1" in
    dbx|databricks|databricks-ai) PLATFORMS+=(databricks) ;;
    msfabric|microsoft-fabric|fabric) PLATFORMS+=(fabric) ;;
    snow|snowflake|snowflake-ai) PLATFORMS+=(snowflake) ;;
    azure-foundry|ai-foundry|foundry) PLATFORMS+=(foundry) ;;
    microsoft-ai|microsoft) PLATFORMS+=(fabric foundry) ;;
    *) PLATFORMS+=("$1") ;;
  esac
}
add_skill_or_platform_arg() {
  case "$1" in
    dbx|databricks|databricks-ai|msfabric|microsoft-fabric|fabric|snow|snowflake|snowflake-ai|azure-foundry|ai-foundry|foundry|microsoft-ai|microsoft)
      add_platform_arg "$1" ;;
    *)
      SKILLS+=("$1") ;;
  esac
}
while [ $# -gt 0 ]; do
  case "$1" in
    --harness)  HARNESS="${2:-}"; shift 2 ;;
    --platform) add_platform_arg "${2:-}"; shift 2 ;;
    --dir)      DEST="${2:-}"; shift 2 ;;
    --local)    LOCAL=1; shift ;;
    --verify)   VERIFY=1; shift ;;
    --all)      WANT_ALL=1; shift ;;
    --list|-l)  LIST=1; shift ;;
    -h|--help)
      sed -n '2,16p' "$0" 2>/dev/null || true
      printf "\nFlags: --harness claude|codex|pi  --platform databricks|fabric|snowflake|foundry  --all  --list  --dir PATH  --local\n"
      printf "Aliases: databricks-ai, snowflake-ai, microsoft-ai, dbx, snow, ai-foundry\n"
      exit 0 ;;
    -*)         die "unknown flag: $1" ;;
    *)          add_skill_or_platform_arg "$1"; shift ;;
  esac
done

# ---- resolve destination -------------------------------------------------
detect_harness() {
  [ -n "$HARNESS" ] && { echo "$HARNESS"; return; }
  [ -d "$HOME/.claude" ] && { echo claude; return; }
  [ -d "$HOME/.codex" ]  && { echo codex;  return; }
  [ -d "$HOME/.agents" ] && { echo pi;     return; }
  echo claude
}
if [ -z "$DEST" ]; then
  H="$(detect_harness)"
  case "$H" in
    claude) DEST="$HOME/.claude/skills" ;;
    codex)  DEST="$HOME/.codex/skills" ;;
    pi)     DEST="$HOME/.agents/skills" ;;
    *)      die "unknown harness: $H (use --harness claude|codex|pi)" ;;
  esac
else H="custom"; fi

# ---- source skills -------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"; }
if [ "$LOCAL" = "1" ]; then
  ROOT="$SCRIPT_DIR"
  TMP=""
  [ -d "$ROOT/skills" ] || die "--local requires running install.sh from an open-skills checkout"
else
  need curl; need tar
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  printf "${D}downloading %s …${X}\n" "$REPO"
  curl -fsSL "$TARBALL" | tar -xz -C "$TMP" || die "download/extract failed"
  ROOT="$(find "$TMP" -maxdepth 1 -type d -name 'open-skills-*' | head -1)"
fi
[ -d "$ROOT/skills" ] || die "skills/ not found in download"

print_platform() {
  plat="$1"
  [ -d "$ROOT/skills/$plat" ] || return 0
  n=$(find "$ROOT/skills/$plat" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
  printf "\n${C}%s${X} ${D}(%s)${X}\n" "$plat" "$n"
  if [ -d "$ROOT/skills/$plat/$plat" ]; then printf "  • %s\n" "$plat"; fi
  for d in "$ROOT/skills/$plat"/*/; do
    name="$(basename "$d")"
    [ "$name" = "$plat" ] && continue
    printf "  • %s\n" "$name"
  done
}

add_platform_dirs() {
  plat="$1"
  if [ -d "$ROOT/skills/$plat/$plat" ]; then SRCDIRS+=("$ROOT/skills/$plat/$plat/"); fi
  for d in "$ROOT/skills/$plat"/*/; do
    [ -d "$d" ] || continue
    [ "$(basename "$d")" = "$plat" ] && continue
    SRCDIRS+=("$d")
  done
}

# ---- list mode -----------------------------------------------------------
if [ "$LIST" = "1" ]; then
  printf "\n${B}Available skills${X} ${D}(%s)${X}\n" "$REPO"
  for plat in $PLATFORM_NAMES; do
    print_platform "$plat"
  done
  echo; exit 0
fi

# ---- build selection -----------------------------------------------------
declare -a SRCDIRS=()
add_dir() { [ -d "$1" ] && SRCDIRS+=("$1") || warn "skill not found: $(basename "$1")"; }

if [ ${#SKILLS[@]} -eq 0 ] && [ ${#PLATFORMS[@]} -eq 0 ]; then WANT_ALL=1; fi
if [ "$WANT_ALL" = "1" ]; then
  for p in $PLATFORM_NAMES; do
    [ -d "$ROOT/skills/$p" ] || continue
    add_platform_dirs "$p"
  done
fi
for p in "${PLATFORMS[@]:-}"; do
  [ -z "$p" ] && continue
  [ -d "$ROOT/skills/$p" ] || die "no such platform: $p ($PLATFORM_NAMES)"
  add_platform_dirs "$p"
done
for s in "${SKILLS[@]:-}"; do
  [ -z "$s" ] && continue
  found="$(find "$ROOT/skills" -mindepth 2 -maxdepth 2 -type d -name "$s" | head -1)"
  add_dir "$found"
done

[ ${#SRCDIRS[@]} -gt 0 ] || die "nothing selected"

# ---- install -------------------------------------------------------------
mkdir -p "$DEST"
printf "\n${B}Installing into${X} %s ${D}(%s)${X}\n" "$DEST" "$H"

# preservation-safe copy: identical -> no-op (idempotent); differing existing
# dir -> backed up to <name>.bak before replace (never silently clobber edits).
install_dir() {  # <src> <destdir>
  src="$1"; dst="$2"; name="$(basename "$dst")"
  if [ -d "$dst" ]; then
    if diff -rq "$src" "$dst" >/dev/null 2>&1; then
      printf "${D}=${X} %s ${D}(unchanged)${X}\n" "$name"; return 0
    fi
    rm -rf "$dst.bak"; mv "$dst" "$dst.bak"
    warn "$name changed — previous version saved to $name.bak"
  fi
  cp -R "$src" "$dst"
  rm -rf "$dst/.git"
  # runtime scripts must be executable
  find "$dst" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  ok "$name"
}

count=0
for d in "${SRCDIRS[@]}"; do
  install_dir "${d%/}" "$DEST/$(basename "$d")"
  count=$((count+1))
done

# ---- ship the shared self-healing runtime (sense/verify/diagnose/assert) ---
if [ -d "$ROOT/skills/_runtime" ]; then
  install_dir "$ROOT/skills/_runtime" "$DEST/_runtime"
  ok "_runtime (shared contract + emit/diagnose/repair)"
fi

printf "\n${G}Done.${X} %s skill(s) installed.\n" "$count"

# ---- optional post-install auth verification -----------------------------
if [ "$VERIFY" = "1" ]; then
  printf "\n${B}Verifying auth${X}\n"
  for va in "$DEST"/*/scripts/verify-auth.sh; do
    [ -f "$va" ] || continue
    sk="$(basename "$(dirname "$(dirname "$va")")")"
    st="$(bash "$va" 2>/dev/null | (command -v jq >/dev/null 2>&1 && jq -r '.status' || cat))"
    case "$st" in
      ok)   ok "$sk auth ok" ;;
      *)    warn "$sk auth not ready — run: bash $va" ;;
    esac
  done
fi
case "$H" in
  claude) say "Restart Claude Code or run /doctor to pick up new skills." ;;
  codex)  say "Codex installs are static copies — re-run this script after upstream updates." ;;
  pi)     say "pi loads ~/.agents/skills automatically on next run." ;;
esac
