---

name: hdinsight-migration
description: >
  Port Azure HDInsight Spark clusters and Hive workloads to Microsoft Fabric.
  Removes legacy HiveContext and standalone SparkContext constructors, replacing them with
  the pre-instantiated SparkSession. Converts WASB and ABFS storage paths to OneLake
  abfss URLs via Shortcuts. Transforms Hive DDL (STORED AS ORC, external tables) to
  Delta Lake schemas inside Fabric Lakehouse. Maps Oozie workflow actions — spark, hive,
  shell, sqoop, coordinator — to Fabric Pipeline activities and schedule triggers.
  Introduces notebookutils for file and credential operations previously handled via
  subprocess or HDFS client calls. Use when the user wants to:
  (1) retire an HDInsight cluster and move to Fabric,
  (2) convert WASB paths or Hive DDL,
  (3) replace Oozie coordinators with Fabric Pipelines.
  Triggers: "migrate from hdinsight", "hdi to fabric", "hivecontext sparksession fabric",
  "wasb to onelake", "hive ddl to delta", "oozie to fabric pipelines",
  "hive metastore lakehouse", "hdinsight spark migration".
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
> 3. HDInsight has no `mssparkutils` or `dbutils` equivalent — `notebookutils` is net-new capability being introduced
> 4. `HiveContext` and `SQLContext` are legacy Spark 1.x/2.x APIs — Fabric uses Spark 3.x `SparkSession` exclusively
> 5. `wasb://` paths are deprecated and require a Storage Account key or SAS — replace with OneLake shortcuts

# HDInsight → Microsoft Fabric Migration

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
