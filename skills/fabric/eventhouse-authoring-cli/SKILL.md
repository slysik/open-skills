---

name: eventhouse-authoring-cli
description: >
  Execute KQL management commands (table management, ingestion, policies, functions, materialized views)
  against Fabric Eventhouse and KQL Databases via CLI.
  Use when the user wants to:
    1. Create or alter KQL tables, columns, or functions
    2. Ingest data into an Eventhouse (inline, from storage, streaming)
    3. Configure retention, caching, or partitioning policies
    4. Create or manage materialized views and update policies
    5. Manage data mappings for ingestion pipelines
    6. Deploy KQL schema via scripts
  Triggers: "create kql table", "kql ingestion", "ingest into eventhouse",
  "kql function", "materialized view", "kql retention policy", "eventhouse schema",
  "kql authoring", "create eventhouse table", "kql mapping"
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

# eventhouse-authoring-cli — Eventhouse Authoring and Management via CLI

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
