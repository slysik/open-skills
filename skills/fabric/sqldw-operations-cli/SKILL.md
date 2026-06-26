---

name: sqldw-operations-cli
description: >
  Analyze Fabric Data Warehouse performance via CLI using sqlcmd and queryinsights views.
  Diagnose slow queries, SQL pool pressure, cache coldness, and recommend clustering keys.
  Triggers: "DW slow query analysis", "slowest queries warehouse",
  "queryinsights long running", "warehouse CPU resource consumers",
  "SQL pool pressure window", "pressure events warehouse",
  "DW cache warmth cold start", "cache warmth analysis",
  "warehouse cluster key recommendation", "cluster tables performance",
  "DW performance baseline comparison", "performance degraded warehouse",
  "warehouse user query patterns", "queryinsights diagnostics",
  "DW optimization sqlcmd".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find the item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace and, then, use JMESPath filtering

# SQL DW Performance & Diagnostics — CLI Skill

This skill provides performance analysis, deep diagnostics, and optimization guidance for Microsoft Fabric Data Warehouse via **`sqlcmd`** and the built-in **`queryinsights`** views. All queries are read-only.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
