---

name: eventhouse-consumption-cli
description: >
  Run KQL queries against Fabric Eventhouse for real-time intelligence
  and time-series analytics using `az rest` against the Kusto REST API. Covers KQL operators
  (where, summarize, join, render), Eventhouse schema discovery (.show tables), time-series
  patterns with bin(), and ingestion monitoring.
  Use when the user wants to:
    1. Run read-only KQL queries against an Eventhouse or KQL Database
    2. Discover Eventhouse table schema and metadata
    3. Analyse real-time or time-series data with KQL operators
    4. Monitor ingestion health and active KQL queries
    5. Export KQL results to JSON
  Triggers: "kql query", "kusto query", "eventhouse query", "kql database",
  "real-time intelligence", "time-series kql", "query eventhouse",
  "explore eventhouse", "show tables kql"
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/open-skills/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find the item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace and, then, use JMESPath filtering

# eventhouse-consumption-cli — Read-Only KQL Queries via CLI

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
