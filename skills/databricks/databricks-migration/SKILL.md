---

name: databricks-migration
description: >
  Port Databricks notebooks and jobs to Microsoft Fabric. Provides an exhaustive dbutils
  to notebookutils substitution table: fs operations (mount removal via OneLake Shortcuts),
  secret scope to Key Vault URL conversion, notebook run and exit, widget replacement with
  parameter-tagged cells, and library install replacement with Fabric Environments.
  Covers Unity Catalog three-level namespace reduction to Lakehouse two-level schemas,
  DBFS path conversion to OneLake, Databricks Jobs to Spark Job Definitions, MLflow
  tracking URI removal, and Photon to Native Execution Engine substitution. Use when the
  user wants to: (1) replace dbutils with notebookutils, (2) collapse Unity Catalog
  namespaces to Lakehouse schemas, (3) convert Databricks Jobs or Delta Live Tables.
  Triggers: "migrate from databricks", "databricks to fabric", "dbutils to notebookutils",
  "dbutils fabric", "unity catalog migration", "dbfs to onelake",
  "databricks notebook migration", "delta live tables fabric", "photon native execution".
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
> 1. To find workspace details (including its ID) from a workspace name: list all workspaces, then use JMESPath filtering
> 2. To find item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace, then use JMESPath filtering
> 3. `dbutils.widgets` has **no direct equivalent** in Fabric — use notebook parameters (cell tag `parameters`) or `notebookutils.runtime.context` for context injection
> 4. `dbutils.library` (runtime library install) has **no equivalent** — use Fabric Environments for reproducible library management
> 5. Unity Catalog uses a 3-level namespace (`catalog.schema.table`); Fabric Lakehouse uses 2-level (`schema.table` within a named Lakehouse)

# Databricks → Microsoft Fabric Migration

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
