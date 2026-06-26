---

name: e2e-medallion-architecture
description: >
  Implement end-to-end Medallion Architecture (Bronze/Silver/Gold) lakehouse patterns
  in Microsoft Fabric using PySpark, Delta Lake, and Fabric Pipelines. Use when the user
  wants to: (1) design a Bronze/Silver/Gold data lakehouse, (2) set up multi-layer
  workspace with lakehouses for each tier, (3) build ingestion-to-analytics pipelines
  with data quality enforcement, (4) optimize Spark configurations per medallion layer,
  (5) orchestrate Bronze-to-Silver-to-Gold flows via notebooks. Triggers: "medallion architecture",
  "bronze silver gold", "lakehouse layers", "e2e data pipeline", "end-to-end lakehouse",
  "data lakehouse pattern", "multi-layer lakehouse", "build medallion", "setup medallion".
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

# End-to-End Medallion Architecture

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
