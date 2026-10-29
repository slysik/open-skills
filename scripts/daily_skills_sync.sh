#!/bin/bash
set -euo pipefail

TS="$(date '+%Y-%m-%d %H:%M:%S %Z')"

# 1. Sync Databricks skills directly into open-skills and rebuild catalog
cd /Users/slysik/open-skills
echo "=== run started: $TS ===" >> /tmp/open_skills_sync.log
/opt/homebrew/bin/just sync-databricks >> /tmp/open_skills_sync.log 2>&1
echo "=== run finished: $(date '+%Y-%m-%d %H:%M:%S %Z') ===" >> /tmp/open_skills_sync.log

# 2. Also keep databricks local agent skills updated
if [ -d "/Users/slysik/databricks" ]; then
  cd /Users/slysik/databricks
  echo "=== run started: $TS ===" >> /tmp/skills_sync.log
  /opt/homebrew/bin/just skills-update >> /tmp/skills_sync.log 2>&1 || true
  echo "=== run finished: $(date '+%Y-%m-%d %H:%M:%S %Z') ===" >> /tmp/skills_sync.log
fi
