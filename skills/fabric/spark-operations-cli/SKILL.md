---

name: spark-operations-cli
description: >
  Diagnose failed Spark jobs, unhealthy Livy sessions,
  and performance bottlenecks in Microsoft Fabric via read-only CLI triage.
  Use when the user wants to: (1) diagnose why a Spark job, notebook run, or Lakehouse job failed,
  (2) triage stuck or dead Livy sessions, (3) identify OOM, shuffle spill, or data skew,
  (4) retrieve driver and executor logs or Spark Advisor findings,
  (5) copy event logs and start a local Spark History Server,
  (6) diagnose all Spark activities within a failed pipeline run.
  Triggers: "diagnose my failed notebook", "why did my spark job fail",
  "triage spark failure", "diagnose pipeline run failure", "why did my pipeline fail",
  "livy session stuck in starting", "spark executor OOM",
  "check spark advisor findings", "shuffle spill diagnosis",
  "why did my lakehouse job fail", "diagnose lakehouse table load",
  "data skew diagnosis", "open spark history server locally",
  "analyze spark failure logs", "spark job triage".
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
> 3. **Skill disambiguation**: `spark-operations-cli` is for **read-only triage and diagnosis** of existing jobs and sessions. For creating notebooks, running new jobs, or Spark development, use `spark-authoring-cli`. For interactive PySpark analysis and Livy session creation, use `spark-consumption-cli`.

# Spark Operations — CLI Skill

This skill provides diagnostics for Microsoft Fabric Spark job failures, Livy session health, and performance bottlenecks using Fabric REST APIs and CLI tools (`az rest`). All diagnostic operations are read-only; session cleanup (e.g., stopping zombie sessions) requires explicit user confirmation. For Spark development and notebook authoring, use `spark-authoring-cli`. For interactive PySpark analysis, use `spark-consumption-cli`.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
