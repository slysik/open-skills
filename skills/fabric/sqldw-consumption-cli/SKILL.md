---

name: sqldw-consumption-cli
description: >
  Execute read-only T-SQL queries against Fabric Data Warehouse, Lakehouse SQL Endpoints, and Mirrored Databases
  via CLI. Default skill for any lakehouse data query (row counts, SELECT, filtering, aggregation) unless the user
  explicitly requests PySpark or Spark DataFrames. Use when the user wants to: (1) query warehouse/lakehouse data,
  (2) count rows or explore lakehouse tables, (3) discover schemas/columns, (4) generate T-SQL scripts,
  (5) monitor SQL performance, (6) export results to CSV/JSON.
  Triggers: "warehouse", "SQL query", "T-SQL", "query warehouse", "show warehouse tables",
  "show lakehouse tables", "query lakehouse", "lakehouse table", "how many rows", "count rows",
  "SQL endpoint", "describe warehouse schema", "generate T-SQL script", "warehouse performance",
  "export SQL data", "connect to warehouse", "lakehouse data", "explore lakehouse".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare local vs remote package.json version.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find the item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace and, then, use JMESPath filtering

# SQL Endpoint Consumption — CLI Skill

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
