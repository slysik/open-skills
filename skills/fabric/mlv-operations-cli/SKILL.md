---

name: mlv-operations-cli
description: >
  Manage Microsoft Fabric Materialized Lake View (MLV) refresh schedules and job execution
  via REST APIs. Create, update, and delete refresh schedules (interval-based: hourly, daily, weekly).
  Trigger on-demand refreshes, monitor job status, and cancel running jobs. Uses human-in-the-loop
  confirmations for safety. Materialized Lake Views are also known as Spark Materialized Views,
  MLVs, or lakehouse materialized views in Fabric documentation.
  Note: MLV discovery (list MLVs, lineage, data quality) requires UI as REST APIs are not yet available.
  Triggers: "schedule MLV refresh", "manage MLV", "MLV refresh schedule",
  "schedule materialized lake view", "schedule materialized view",
  "automate MLV refresh", "trigger MLV refresh", "monitor MLV refresh",
  "MLV job status", "cancel MLV refresh", "refresh schedule",
  "MLV automation", "manage materialized lake view", "manage materialized view",
  "materialized view refresh", "spark materialized view schedule",
  "lakehouse materialized view", "refresh my materialized views"
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
> 2. To find the lakehouse details (including its ID) from workspace ID and lakehouse name: list all lakehouses in that workspace and, then, use JMESPath filtering
> 3. **MLV Discovery Gap**: REST APIs for listing MLVs in a lakehouse do not exist yet (GET /materializedLakeViews returns 404). For schedule CRUD/trigger/status, only workspace ID and lakehouse ID are needed (scheduling operates on the full lakehouse lineage). MLV table names are only needed if the user asks about specific view definitions.

# MLV Operations — CLI Skill

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
