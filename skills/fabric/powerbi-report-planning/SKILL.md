---

name: powerbi-report-planning
description: >-
  Build a guided requirements-to-implementation workflow for new Power BI
  reports and dashboards from semantic models, datasets, or PBIP projects. Use
  when the user wants to: (1) plan then implement a report, (2) define audience,
  scope, page plan, design direction, dependencies, and delivery target, (3)
  create a locked report spec with approval before PBIR authoring. For direct
  edits to existing report files, use `powerbi-report-authoring`. For design-only
  critique or redesign, use `powerbi-report-design`. Triggers: "build me a
  dashboard", "create a new report", "plan then implement", "define and build
  Power BI report", "walk me through creating a report".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

# Power BI Report Planning Skill

This skill orchestrates the full lifecycle for a new Power BI report:

**Define -> Inspect -> Spec -> Approve -> Build -> Validate -> Publish**

It is intentionally broader than a pure requirements-gathering flow: it captures
the report spec **and** continues into implementation after the user approves.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
