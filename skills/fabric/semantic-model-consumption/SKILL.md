---

name: semantic-model-consumption
description: >
  Execute raw DAX queries and inspect metadata of Microsoft Fabric Power BI semantic models via the MCP server ExecuteQuery tool.
  Use when the user already knows the DAX to write, wants to run EVALUATE statements, or needs to inspect model metadata
  (tables, columns, measures, relationships, hierarchies) using INFO functions.
  For natural-language business questions (where you generate the DAX), use `fabriciq`.
  For creating, deploying, or managing semantic model definitions, use `semantic-model-authoring`.
  Triggers: "run DAX query", "execute EVALUATE", "semantic model metadata", "list semantic model tables",
  "INFO.VIEW.TABLES", "get measure expression", "DAX against", "query the model".
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

# Power BI Semantic Model Consumption

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
