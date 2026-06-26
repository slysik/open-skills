---

name: powerbi-report-authoring
description: >-
  Create and modify Power BI report files in PBIR/PBIP format using the
  `powerbi-report-author` and `powerbi-desktop` CLIs. Use when the user wants
  to: (1) implement an approved report spec or design brief, (2) add or edit
  pages, visuals, filters, slicers, bookmarks, themes, or formatting, (3)
  validate PBIR and verify rendering in Power BI Desktop. For open-ended visual
  design, use `powerbi-report-design` first. For end-to-end requirements and
  approval workflow, use `powerbi-report-planning` first. Triggers: "edit PBIR",
  "create Power BI report page", "add visual to PBIP", "format report visual",
  "validate Power BI report", "reload Desktop screenshot", "implement an approved PBIP report spec", "edit PBIR pages/visuals".
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

# Power BI Report Authoring Skill (PBIR/PBIP Format)

This skill enables reading, editing, and creation of Power BI report
definition files in the **PBIR (Power BI Report)** format used by **PBIP
(Power BI Project)** files.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
