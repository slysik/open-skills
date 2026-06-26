---

name: powerbi-report-design
description: >-
  Generate Power BI report visual design guidance before PBIR files are
  written. Use when the user wants to: (1) choose tone, signature, page
  archetypes, chart types, layout, color, typography, theme direction, or
  accessibility approach, (2) redesign/restyle an existing report, apply a
  brand, or critique chart/layout choices, (3) produce a design contract for
  `powerbi-report-authoring`. For end-to-end requirements, approval, and build
  sequencing, use `powerbi-report-planning`. Triggers: "design Power BI report",
  "make dashboard look professional", "choose chart type", "apply brand to
  report", "redesign report", "create design brief".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

# Power BI Report Design Skill

This skill provides design guidance for Power BI reports. It commits a design identity (tone + signature), routes user requests to the right archetype per page, and applies cross-cutting design principles (color, typography, iconography, layout, interactivity, accessibility).

**Scope boundary** — This skill decides *what* a report should look like and *why*. It does **not** write PBIR files. After producing a design contract, hand off to `powerbi-report-authoring` for all file mechanics: page/visual creation, theme registration, expression encoding, formatting objects, and validation.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
