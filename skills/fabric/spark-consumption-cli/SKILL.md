---

name: spark-consumption-cli
description: >
  Analyze lakehouse data interactively using Fabric Lakehouse Livy API sessions and PySpark/Spark SQL for advanced analytics,
  DataFrames, cross-lakehouse joins, Delta time-travel, and unstructured/JSON data. Use when the user explicitly
  asks for PySpark, Spark DataFrames, Livy sessions, or Python-based analysis — NOT for simple SQL queries.
  Triggers: "PySpark", "Spark SQL", "analyze with PySpark", "Spark DataFrame", "Livy session",
  "lakehouse with Python", "PySpark analysis", "PySpark data quality", "Delta time-travel with Spark".
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

# Data Engineering Consumption — CLI Skill

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
