#!/usr/bin/env bash
# dbx-snowflake-fabric :: one-step skills installer
# Databricks · Microsoft Fabric · Snowflake agent skills for Claude Code, Codex, and pi.
#
#   Install everything (Claude Code):
#     curl -fsSL https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/install.sh | bash
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

REPO="slysik/dbx-snowflake-fabric"
BRANCH="${DSF_BRANCH:-main}"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
TARBALL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"

# ---- colours -------------------------------------------------------------
if [ -t 1 ]; then B=$'\033[1m'; D=$'\033[2m'; G=$'\033[32m'; C=$'\033[36m'; Y=$'\033[33m'; R=$'\033[31m'; X=$'\033[0m'
else B=""; D=""; G=""; C=""; Y=""; R=""; X=""; fi
say()  { printf "%s\n" "$*"; }
ok()   { printf "${G}✓${X} %s\n" "$*"; }
warn() { printf "${Y}!${X} %s\n" "$*"; }
die()  { printf "${R}✗ %s${X}\n" "$*" >&2; exit 1; }

# ---- args ----------------------------------------------------------------
HARNESS=""; DEST=""; LIST=0; WANT_ALL=0
PLATFORMS=(); SKILLS=()
while [ $# -gt 0 ]; do
  case "$1" in
    --harness)  HARNESS="${2:-}"; shift 2 ;;
    --platform) PLATFORMS+=("${2:-}"); shift 2 ;;
    --dir)      DEST="${2:-}"; shift 2 ;;
    --all)      WANT_ALL=1; shift ;;
    --list|-l)  LIST=1; shift ;;
    -h|--help)
      sed -n '2,16p' "$0" 2>/dev/null || true
      printf "\nFlags: --harness claude|codex|pi  --platform databricks|fabric|snowflake  --all  --list  --dir PATH\n"
      exit 0 ;;
    -*)         die "unknown flag: $1" ;;
    *)          SKILLS+=("$1"); shift ;;
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

# ---- fetch + unpack ------------------------------------------------------
need() { command -v "$1" >/dev/null 2>&1 || die "missing required tool: $1"; }
need curl; need tar
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
printf "${D}downloading %s …${X}\n" "$REPO"
curl -fsSL "$TARBALL" | tar -xz -C "$TMP" || die "download/extract failed"
ROOT="$(find "$TMP" -maxdepth 1 -type d -name 'dbx-snowflake-fabric-*' | head -1)"
[ -d "$ROOT/skills" ] || die "skills/ not found in download"

# ---- list mode -----------------------------------------------------------
if [ "$LIST" = "1" ]; then
  printf "\n${B}Available skills${X} ${D}(%s)${X}\n" "$REPO"
  for plat in databricks fabric snowflake; do
    [ -d "$ROOT/skills/$plat" ] || continue
    n=$(find "$ROOT/skills/$plat" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
    printf "\n${C}%s${X} ${D}(%s)${X}\n" "$plat" "$n"
    for d in "$ROOT/skills/$plat"/*/; do printf "  • %s\n" "$(basename "$d")"; done
  done
  echo; exit 0
fi

# ---- build selection -----------------------------------------------------
declare -a SRCDIRS=()
add_dir() { [ -d "$1" ] && SRCDIRS+=("$1") || warn "skill not found: $(basename "$1")"; }

if [ ${#SKILLS[@]} -eq 0 ] && [ ${#PLATFORMS[@]} -eq 0 ]; then WANT_ALL=1; fi
if [ "$WANT_ALL" = "1" ]; then
  for d in "$ROOT"/skills/*/*/; do SRCDIRS+=("$d"); done
fi
for p in "${PLATFORMS[@]:-}"; do
  [ -z "$p" ] && continue
  [ -d "$ROOT/skills/$p" ] || die "no such platform: $p (databricks|fabric|snowflake)"
  for d in "$ROOT/skills/$p"/*/; do SRCDIRS+=("$d"); done
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
count=0
for d in "${SRCDIRS[@]}"; do
  name="$(basename "$d")"
  rm -rf "$DEST/$name"
  cp -R "$d" "$DEST/$name"
  rm -rf "$DEST/$name/.git"
  ok "$name"
  count=$((count+1))
done
printf "\n${G}Done.${X} %s skill(s) installed.\n" "$count"
case "$H" in
  claude) say "Restart Claude Code or run /doctor to pick up new skills." ;;
  codex)  say "Codex installs are static copies — re-run this script after upstream updates." ;;
  pi)     say "pi loads ~/.agents/skills automatically on next run." ;;
esac
