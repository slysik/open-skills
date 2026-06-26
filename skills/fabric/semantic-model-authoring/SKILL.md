---

name: semantic-model-authoring
description: >
  Develops and manages Power BI semantic models across Desktop, PBIP projects, and Fabric Service. Handles:
  (1) creating new models (Import, DirectQuery, Direct Lake),
  (2) editing existing models (e.g. measures, tables, columns, relationships),
  (3) deploying models to Fabric workspaces,
  (4) working with PBIP project files,
  (5) refreshing semantic models,
  (6) configuring data sources and permissions,
  (7) DAX performance optimization.
  Supports both Power BI Desktop and Fabric Service development workflows. For read-only DAX queries, use `semantic-model-consumption`.
  Does NOT handle report layout/visual authoring, workspace administration, or RLS/OLS role membership management.
  Triggers: "create semantic model", "edit semantic model", "add a DAX measure to semantic model", "refresh semantic model", "set semantic model permissions", "Prepare semantic model for AI/Copilot".
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
> 3. Always consider the [Tool selection priority](#tool-selection-priority) when choosing which tool to use for each operation. Do not default to TMDL edits or `az rest` if MCP is available and connected to the target model.

# Power BI Semantic Model Authoring — CLI Skill

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
