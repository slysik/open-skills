---
name: databricks-spark-declarative-pipelines
description: "Creates, configures, and updates Databricks Lakeflow Spark Declarative Pipelines (SDP/LDP) using serverless compute. Handles data ingestion with streaming tables, materialized views, CDC, SCD Type 2, and Auto Loader ingestion patterns. Use when building data pipelines, working with Delta Live Tables, ingesting streaming data, implementing change data capture, or when the user mentions SDP, LDP, DLT, Lakeflow pipelines, streaming tables, or bronze/silver/gold medallion architectures."
---
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"

# Lakeflow Spark Declarative Pipelines (SDP)

---

## Critical Rules (always follow)

### Syntax: CREATE OR REFRESH (not CREATE OR REPLACE)
- **MUST** use `CREATE OR REFRESH` for SDP objects:
  - `CREATE OR REFRESH STREAMING TABLE` - for streaming tables
  - `CREATE OR REFRESH MATERIALIZED VIEW` - for materialized views
- **NEVER** use `CREATE OR REPLACE` - that is standard SQL syntax, not SDP syntax

### Simplicity First
- **MUST** create the minimal number of tables to solve the task
- Simplicity first: prefer single pipeline even for multi-schema setups - use fully qualified names (`catalog.schema.table`)
- When asked to "create a silver table" or "create a gold table", create **ONE table** - not a multi-layer pipeline
- Don't add intermediate tables, staging tables, or helper views unless explicitly requested
- A silver transformation = 1 streaming table reading from bronze
- A gold aggregation = 1 materialized view reading from silver
- Create bronze→silver→gold chains when the user asks for a "pipeline" or "medallion architecture" or full/detailed ingestion. Otherwise keep it simple - don't over engineer.

### Language Selection
- **MUST** know the language (Python or SQL). For simple task / pipeline / table creation, pick SQL. For complex pipeline with parametrized information, or if the user mentions python-related items pick python. If you have a doubt, ask the user. Stick with that language unless told otherwise.

| User Says | Action |
|-----------|--------|
| "Python pipeline", "Python SDP", "use Python", "udf", "pandas", "ml inference", "pyspark" | **User wants Python** |
| "SQL pipeline", "SQL files", "use SQL" | **User wants SQL** |
| "Create a simple pipeline", "create a table", "an aggregation" | **Pick SQL as it's simple** |

### Other Rules
- **MUST** create serverless pipelines by default. Only use classic clusters if user explicitly requires R language, Spark RDD APIs, or JAR libraries.
- **MUST** choose the right workflow based on context (see below).
- When the user provides table schema and asks for code, respond directly with the code. Don't ask clarifying questions if the request is clear.

## Tools
- List files in volume: `databricks fs ls dbfs:/Volumes/{catalog}/{schema}/{volume}/{path} --profile {PROFILE}`
- Query data: `databricks experimental aitools tools query --profile {PROFILE} --warehouse abc123 "SELECT 1 FROM catalog.schema.table"`
- Discover schema: `databricks experimental aitools tools discover-schema --profile {PROFILE} catalog.schema.table1 catalog.schema.table2`
- Pipelines CLI: `databricks pipelines init|deploy|run|logs|stop` or use `databricks pipelines --help` for more options

## Choose Your Workflow

**First, determine which workflow to use:**

### Option A: Standalone New Pipeline Project (use `databricks pipelines init`)

Use this when the user wants to **create a new, standalone SDP project** that will have its own DAB:
- User asks: "Create a new pipeline", "Build me an SDP", "Set up a new data pipeline"
- No existing `databricks.yml` in the workspace
- The pipeline IS the project (not part of a larger demo/app)


Use `databricks pipeline` CLI commands:
```bash
databricks pipelines init --output-dir . --config-file init-config.json
```

**Example init-config.json:**
```json
{
  "project_name": "customer_pipeline",
  "initial_catalog": "prod_catalog",
  "use_personal_schema": "no",
  "initial_language": "sql"
}
```

→ See [1-project-initialization.md](references/1-project-initialization.md)
→ 


### Option B: Pipeline within Existing Bundle (edit the bundle)

Use this when the pipeline is **part of an existing DAB project**:
- There's already a `databricks.yml` file in the project
- User is adding a pipeline to an existing app/demo

→ See [1-project-initialization.md](references/1-project-initialization.md) for adding pipelines to existing bundles

### Option C: Rapid Iteration with MCP Tools (no bundle management)

Use this when you need to **quickly create, test, and iterate** on a pipeline without managing bundle files:
- User wants to "just run a pipeline and see if it works"
- Part of a larger demo where bundle is managed separately, or the DAB bundle will be created at the end as you want to quickly test the project first
- Prototyping or experimenting with pipeline logic
- User explicitly asks to use MCP tools

→ See [2-mcp-approach.md](references/2-mcp-approach.md) for MCP-based workflow

---

## Required Checklist

Before writing pipeline code, make sure you have:
```
- [ ] Language selected: Python or SQL
- [ ] Read the syntax basics: **SQL**: Always Read [sql/1-syntax-basics.md](references/sql/1-syntax-basics.md), **Python**: Always Read [python/1-syntax-basics.md](references/python/1-syntax-basics.md)
- [ ] Workflow chosen: Standalone DAB / Existing DAB / MCP iteration
- [ ] Compute type: serverless (default) or classic
- [ ] Schema strategy: single schema with prefixes vs. multi-schema
- [ ] Consider [Multi-Schema Patterns](#multi-schema-patterns) and [Modern Defaults](#modern-defaults)
```

**Then read additional guides based on what the pipeline needs, when you need it:**
| If the pipeline needs... | Read |
|--------------------------|------|
| File ingestion (Auto Loader, JSON, CSV, Parquet) | `references/sql/2-ingestion.md` or `references/python/2-ingestion.md` |
| Kafka, Event Hub, or Kinesis streaming | `references/sql/2-ingestion.md` or `references/python/2-ingestion.md` |
| Deduplication, windowed aggregations, joins | `references/sql/3-streaming-patterns.md` or `references/python/3-streaming-patterns.md` |
| CDC, SCD Type 1/2, or history tracking | `references/sql/4-cdc-patterns.md` or `references/python/4-cdc-patterns.md` |
| Performance tuning, Liquid Clustering | `references/sql/5-performance.md` or `references/python/5-performance.md` |

---


## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/development-guide.md](references/development-guide.md) | Quick reference, task-based routing, official docs map, general SDP guidance, **Best Practices (2026)**, **Post-Run Validation (required)**, common issues, advanced config, platform constraints. |
| [references/1-project-initialization.md](references/1-project-initialization.md) | Scaffolding a new SDP project. |
| [references/2-mcp-approach.md](references/2-mcp-approach.md) | Optional MCP-based workflow (convenience; CLI/REST is primary). |
| [references/3-advanced-configuration.md](references/3-advanced-configuration.md) | Advanced pipeline configuration. |
| [references/4-dlt-migration.md](references/4-dlt-migration.md) | Migrating legacy DLT → SDP. |
## Related Skills

- **[databricks-jobs](../databricks-jobs/SKILL.md)** - for orchestrating and scheduling pipeline runs
- **[databricks-bundles](../databricks-bundles/SKILL.md)** - for multi-environment deployment of pipeline projects
- **[databricks-synthetic-data-gen](../databricks-synthetic-data-gen/SKILL.md)** - for generating test data to feed into pipelines
- **[databricks-unity-catalog](../databricks-unity-catalog/SKILL.md)** - for catalog/schema/volume management and governance
