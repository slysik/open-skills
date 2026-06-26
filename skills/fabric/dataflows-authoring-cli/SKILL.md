---

name: dataflows-authoring-cli
description: >
  Create, update, delete, and refresh Fabric Dataflows Gen2 via write-side CLI
  against Fabric Items and Connections APIs. Builds mashup.pq + queryMetadata
  definitions, triggers parameterized refreshes, manages connections, and
  configures output destinations (Lakehouse, Warehouse, ADX, Azure SQL).
  Includes preview-driven authoring loop (executeQuery + customMashupDocument).
  Lists `supportedConnectionTypes`/`credentialType` per connector.
  For executing saved queries or reading refresh status, use
  `dataflows-consumption-cli`.
  Triggers: "create dataflow", "update dataflow", "delete dataflow",
  "trigger dataflow refresh", "refresh dataflow", "preview Power Query M",
  "preview mashup", "preview before save", "iterate dataflow M",
  "create Fabric data source connection", "create dataflow connection",
  "bind connection", "list supportedConnectionTypes",
  "dataflow output destination", "dataflow write to lakehouse",
  "dataflow write to warehouse", "dataflow write to ADX",
  "DataDestinations annotation".
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

# dataflows-authoring-cli — Dataflows Gen2 Authoring via CLI

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
