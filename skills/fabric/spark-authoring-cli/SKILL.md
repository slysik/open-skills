---

name: spark-authoring-cli
description: >
  Develop Microsoft Fabric Spark/data engineering workflows and write code in Fabric Notebook cells
  with intelligent routing to specialized resources. Provides workspace/lakehouse management, notebook
  code authoring (PySpark, Scala, SparkR, SQL), and Materialized Lake View (MLV) authoring
  (Spark SQL MLVs support incremental refresh; PySpark is full-refresh only). Routes to data
  engineering patterns, development workflow, or infrastructure orchestration.
  Triggers: "develop notebook", "data engineering", "workspace setup", "pipeline design",
  "Delta Lake patterns", "Spark development", "lakehouse configuration",
  "write notebook code", "notebookutils", "notebook cell", "PySpark notebook",
  "%%sql cell", "%%configure", "fabric notebook", "run notebook", "notebook deployment",
  "materialized lake view", "MLV", "CREATE MATERIALIZED LAKE VIEW",
  "MLV incremental refresh", "review MLV for incremental refresh", "MLV refresh policy",
  "infrastructure provisioning"
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare local vs remote package.json version.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find the item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace and, then, use JMESPath filtering

# Spark Authoring — CLI Skill

This skill covers two complementary areas: (1) **managing Fabric Spark artifacts via REST APIs** (workspaces, lakehouses, notebooks, jobs, pipelines) and (2) **writing code inside Fabric Notebook cells** (PySpark, Scala, SparkR, SQL with correct lakehouse access, notebookutils, and Spark configuration). For notebook code authoring fundamentals and shared modules, MUST see [SPARK-NOTEBOOK-AUTHORING-CORE.md](../../common/SPARK-NOTEBOOK-AUTHORING-CORE.md).

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
