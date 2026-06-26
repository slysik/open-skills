---

name: powerbi-report-management
description: "Manage Power BI report workspace items in Microsoft Fabric via `az rest` CLI against the Fabric REST API. Use when the user wants to: (1) create reports from PBIR definitions, (2) get or download report definitions, (3) update report definitions or properties, (4) list workspace reports, (5) delete reports. For report layout authoring (pages, visuals, filters, formatting), use `powerbi-report-authoring`. Triggers: upload Power BI report, download PBIR definition, publish Power BI report to Fabric, manage Power BI reports."
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

# Power BI Report Management

Manage Power BI reports in Microsoft Fabric workspaces using `az rest` against
the Fabric REST API. This skill covers the full CRUD lifecycle for report items
and their PBIR definitions.

> **Scope**: Report item CRUD and definition management only. For report layout
> authoring (pages, visuals, filters, formatting), use `powerbi-report-authoring`.

> **Boundary**: This skill transports PBIR definitions to and from Fabric. PBIR
> content authoring remains owned by `powerbi-report-authoring`.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
