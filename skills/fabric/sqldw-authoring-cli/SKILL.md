---

name: sqldw-authoring-cli
description: >
  Execute authoring T-SQL (DDL, DML, data ingestion, transactions, schema changes) against Microsoft Fabric
  Data Warehouse and SQL endpoints from agentic CLI environments. Use when the user wants to: (1) create/alter/drop
  tables from terminal, (2) insert/update/delete/merge data via CLI, (3) run COPY INTO or OPENROWSET ingestion,
  (4) manage transactions or stored procedures, (5) perform schema evolution, (6) use time travel or snapshots,
  (7) generate ETL/ELT shell scripts, (8) create views/functions/procedures on Lakehouse SQLEP. Triggers:
  "create table in warehouse", "insert data via T-SQL", "load from ADLS", "COPY INTO", "run ETL with T-SQL", "alter warehouse table", "upsert with T-SQL", "merge into warehouse",
  "create T-SQL procedure", "warehouse time travel", "recover deleted warehouse data", "create warehouse schema", "deploy warehouse", "transaction
  conflict", "snapshot isolation error".
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

# SQL Endpoint Authoring — CLI Skill

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
