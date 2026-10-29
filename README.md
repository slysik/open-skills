<div align="center">

<img src="assets/open-skills-cli-slide.png" alt="Open Skills CLI slide for Databricks, Snowflake, and Microsoft Fabric + Foundry" width="100%" />

# Databricks · Microsoft Fabric · Snowflake — Agent Skills

**115 production skills** that turn Claude Code, Codex, or pi into a data-platform engineer.
Build everything on **Databricks, Snowflake, and Microsoft Fabric** through CLIs and REST APIs —
**no MCP, no UI, no glue code.**

[![Skills](https://img.shields.io/badge/skills-115-FF3621)](#-skill-catalog)
[![Avg router](https://img.shields.io/badge/avg_router-125.0_lines-29B5E8)](#-how-these-skills-are-optimized)
[![Harness](https://img.shields.io/badge/harness-Claude_Code_·_Codex_·_pi-11A37F)](#-works-with-your-agent)
[![Architecture](https://img.shields.io/badge/architecture-CLI_+_REST,_no_MCP-555)](#-design-principles)
[![Landing](https://img.shields.io/badge/landing-GitHub_Pages-8b5cf6)](https://slysik.github.io/open-skills/)

### → [**Open the landing page**](https://slysik.github.io/open-skills/) ←

</div>

---

## ⚡ Install in one step

Each install command copies skills into **one** harness. It does **not**
automatically make them available in all three tools at once.

Installs **all 115 skills** into Codex:

```bash
just install-open-skills
```

### Pick exactly what you want

```bash
# with just from a local clone
just install-databricks            # Databricks skills into Codex
just install-snowflake             # Snowflake skills into Codex
just install-microsoft-ai          # Microsoft Fabric + Foundry skills into Codex

# choose a different harness explicitly
just install -- --harness claude --platform databricks
just install -- --harness pi --platform snowflake

# generic just form also works for local installs
just install -- --platform databricks-ai
just install -- --platform snowflake-ai
just install -- --platform microsoft-ai

# a single skill
just install databricks-genie

# into Codex or pi instead of Claude Code
just install-platform fabric codex

# just list everything first
just list
```

| Flag | Effect |
|---|---|
| *(none)* | install all 115 skills |
| `--platform databricks\|fabric\|snowflake\|foundry` | install one platform group (repeatable; aliases include `databricks-ai`, `snowflake-ai`, `microsoft-ai`, `dbx`, `snow`, and `ai-foundry`) |
| `<skill-name> …` | install named skills only |
| `--harness claude\|codex\|pi` | choose target agent (auto-detected by default) |
| `--dir PATH` | install into a custom directory |
| `--list` | print the catalog and exit |

> Prefer to read before you run? The installer is a single audited [`install.sh`](install.sh) — download, read, run.

---

## 🤖 Works with your agent

These are **plain skill folders** (`SKILL.md` + `references/`), portable across harnesses. No server, no MCP.

| Harness | Install target | Notes |
|---|---|---|
| **Claude Code** | `~/.claude/skills/` | Auto-detected. Restart or `/doctor` to load. |
| **Codex** | `~/.codex/skills/` | Static copies — re-run installer after upstream updates. |
| **pi** | `~/.agents/skills/` | Loaded automatically on next run. |

## Cross-platform smoke test

The customer-support benchmark builds the same seven-table AI solution on
Databricks, Snowflake, and Microsoft Fabric + Foundry. It is CLI-first, uses REST
only when a CLI operation is unavailable, and never uses MCP tools.

```bash
just smoke-dry-run

# Cloud execution after configuring each platform:
just smoke-databricks
just smoke-snowflake
just smoke-microsoft
just smoke-report
```

See [`examples/customer-support-ai/`](examples/customer-support-ai/) for the
dataset, SQL, prompts, eval expectations, and result contract.

---

## 🧭 Simple routing

Use platform umbrella skills for broad prompts. For example, after installing the
Snowflake platform group, a prompt like "help me design this in Snowflake" should
trigger the `snowflake` router skill, which then routes to `snowflake-cortex`,
`snowflake-kafka`, or `cortex-code` based on the task.

---

## 🧠 How these skills are optimized

Every skill was rewritten to a measured standard, not vibes:

- **Thin-router architecture** — `SKILL.md` is a *router*, not a manual. Average **125.0 lines** (target < 100, hard cap 150). 84 of 115 routers are under 150.
- **Progressive disclosure** — the router loads only a concept map + a "load which sub-doc" table. Heavy detail lives in `references/` and is pulled into context **only when the task needs it**, so a typical invocation reads tens of lines instead of thousands.
- **CLI-first, REST-second, MCP-never** — vendor CLI / REST is the only required path. No MCP servers to install, register, or keep alive. (One Databricks skill was rewritten specifically because it wrongly mandated an MCP tool that registered zero tools.)
- **Connection contract** — every auth doc follows the same 4 headings: *Interactive · Service principal · Verify · Troubleshoot* — so the agent never guesses how to authenticate.
- **Preservation-tested trims** — routers were shrunk by moving body to `references/` *verbatim*; an automated check proves no command or code line was lost in the process.

**Suite totals:** 115 skills · 125.0 avg router lines · 220,671 total lines of curated playbook.

> **Adding more skills.** New skills are added through the **same open-skills agent-harness optimization framework** — drop a thin-router `SKILL.md` (+ `references/`) under `skills/<platform>/<skill>/`, run `scripts/build_catalog.py` to refresh `catalog.json`, and `scripts/validate_skills.py` to enforce the router-line / preservation contract. The self-healing runtime (`_runtime/` + per-skill `scripts/sense-state · verify-auth · diagnose-error · assert · generate-blueprint`) and the one-step installer pick the new skill up automatically — no bespoke wiring. Every skill ships to every harness (Claude Code · Codex · pi) the same way.

---

## 🎯 Design principles

1. **Applied AI through coding-agent harnesses** — the agent does the work via terminal: CLIs, REST calls, SQL, and scripts.
2. **No MCP.** Dependencies you have to babysit are a liability; standard CLIs are everywhere.
3. **No UI.** Everything is reproducible from a shell — scriptable, diffable, CI-able.
4. **One source of truth.** Skills are versioned folders; the installer just copies them where your agent looks.

---

## 📚 Skill catalog


### Databricks (46)

*Lakehouse · Unity Catalog · Spark · MLflow · Genie*

<details>
<summary><b>Show 46 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `azure-databricks-architecture` | Azure-specific Databricks architecture for customer design sessions, PoCs and production hardening: control/compute plane, VNet injection, secure cluster con... | 41 |
| `databricks-agent-bricks` | Create Agent Bricks: Knowledge Assistants (KA) for document Q&A and Supervisor Agents for multi-agent orchestration (MAS). | 144 |
| `databricks-ai-functions` | Use Databricks built-in AI Functions (ai_classify, ai_decide, ai_extract, ai_summarize, ai_mask, ai_translate, ai_fix_grammar, ai_gen, ai_analyze_sentiment,... | 182 |
| `databricks-ai-runtime` | Databricks AI Runtime, the `databricks air` CLI commands for submitting and managing GPU training workloads on Databricks serverless compute. Use for: writin... | 316 |
| `databricks-aibi-dashboards` | Create Databricks AI/BI dashboards. Must use when creating, updating, or deploying Lakeview dashboards as Databricks Dashboard have a unique json structure.... | 310 |
| `databricks-app-apx` | Build full-stack Databricks applications using APX framework (FastAPI + React). | 101 |
| `databricks-app-design` | Design the UX of custom-code Databricks Apps (AppKit/React) data screens — KPI/overview pages, reports, charts, tables, and Genie/chat data assistants — mapp... | 74 |
| `databricks-app-python` | Builds Databricks applications. Prefers AppKit (TypeScript + React SDK) for new apps; falls back to Python frameworks (Dash, Streamlit, Gradio, Flask, FastAP... | 134 |
| `databricks-apps` | Build apps on Databricks Apps platform. Use when asked to create data apps, analytics tools, or custom interactive visualizations. A plain "create a dashboar... | 241 |
| `databricks-apps-python` | Python backend for Databricks Apps — FastAPI (default), Flask, Dash, Streamlit, Gradio, Reflex. **Default for a new Databricks App is `databricks-apps` (AppK... | 212 |
| `databricks-bundles` | Create and configure Declarative Automation Bundles (formerly Asset Bundles) with best practices for multi-environment deployments (CICD). Use when working w... | 60 |
| `databricks-config` | Manage Databricks workspace connections: check current workspace, switch profiles, list available workspaces, or authenticate to a new workspace. Use when th... | 71 |
| `databricks-core` | Databricks CLI operations and the parent/entry-point skill for Databricks CLI use: authentication, profile selection, and bundles. Load this first for CLI, a... | 166 |
| `databricks-dabs` | Create, configure, validate, deploy, run, and manage Declarative Automation Bundles (DABs, formerly Databricks Asset Bundles). Use when working with Databric... | 55 |
| `databricks-data-discovery` | Discover, explore, and query Databricks data via Genie — the CLI equivalent of the Genie One MCP. MUST be invoked whenever the user asks to find or locate da... | 145 |
| `databricks-dbsql` | Databricks SQL (DBSQL) advanced features and SQL warehouse capabilities. This skill MUST be invoked when the user mentions: "DBSQL", "Databricks SQL", "SQL w... | 304 |
| `databricks-docs` | Databricks documentation reference via llms.txt index. Use when other skills do not cover a topic, looking up unfamiliar Databricks features, or needing auth... | 68 |
| `databricks-execution-compute` | Execute code and manage compute on Databricks: run Python/Scala/SQL/R via serverless, classic, or interactive clusters, and create/resize/delete clusters and... | 173 |
| `databricks-genie` | Create and query Databricks Genie Spaces for natural language SQL exploration. Use when building Genie Spaces, exporting and importing Genie Spaces, migratin... | 61 |
| `databricks-genie-agents` | Create, manage, and query Databricks Genie Agents (formerly Genie Spaces): curated agents over Unity Catalog tables, Metric Views, and documents in UC volume... | 58 |
| `databricks-iceberg` | Apache Iceberg tables on Databricks — Managed Iceberg tables, External Iceberg Reads (fka Uniform), Compatibility Mode, Iceberg REST Catalog (IRC), Iceberg v... | 152 |
| `databricks-jobs` | Develop and deploy Lakeflow Jobs on Databricks via DABs, Python SDK, or the CLI. Use when creating data engineering jobs with notebooks, Python wheels, SQL,... | 353 |
| `databricks-lakebase` | Databricks Lakebase Postgres: projects, scaling, connectivity, Lakebase synced tables, and Data API. Use when asked about Lakebase databases, OLTP storage, o... | 391 |
| `databricks-lakebase-autoscale` | Patterns and best practices for Lakebase Autoscaling (next-gen managed PostgreSQL). Use when creating or managing Lakebase Autoscaling projects, configuring... | 133 |
| `databricks-lakebase-provisioned` | Patterns and best practices for Lakebase Provisioned (Databricks managed PostgreSQL) for OLTP workloads. Use when creating Lakebase instances, connecting app... | 98 |
| `databricks-lakeflow-connect` | Build managed ingestion pipelines into Databricks using Lakeflow Connect. Use when ingesting from SaaS apps (Salesforce, Workday Reports, ServiceNow, Google... | 261 |
| `databricks-metric-views` | Unity Catalog metric views: define, create, query, and manage governed business metrics in YAML. Use when building standardized KPIs, revenue metrics, order... | 107 |
| `databricks-migration` | Port Databricks notebooks and jobs to Microsoft Fabric. Provides an exhaustive dbutils to notebookutils substitution table: fs operations (mount removal via... | 41 |
| `databricks-ml-training` | Train ML models on Databricks. Use for: classification/regression/deep-learning (XGBoost, scikit-learn, LightGBM, PyTorch) with Optuna, @prod/@challenger ali... | 283 |
| `databricks-mlflow-evaluation` | MLflow 3 GenAI agent evaluation. Use when writing mlflow.genai.evaluate() code, creating @scorer functions, using built-in scorers (Guidelines, Correctness,... | 166 |
| `databricks-model-serving` | Databricks Model Serving endpoint lifecycle and ops. Use when asked to: CRUD serving endpoints (CLI or MLflow Deployments client); configure traffic routing... | 261 |
| `databricks-parsing` | Parse documents (PDF, DOCX, PPTX, images) using ai_parse_document, or build custom RAG pipelines. Use when the user asks to parse documents or build a custom... | 85 |
| `databricks-pipelines` | Develop Lakeflow Spark Declarative Pipelines (formerly Delta Live Tables) on Databricks. Use when building batch or streaming data pipelines with Python or S... | 154 |
| `databricks-python-sdk` | Databricks development guidance including Python SDK, Databricks Connect, CLI, and REST API. Use when working with databricks-sdk, databricks-connect, or Dat... | 633 |
| `databricks-serverless` | Serverless compute for Databricks jobs, Lakeflow pipelines and Declarative Automation Bundles (DABs), with STANDARD or PERFORMANCE_OPTIMIZED and classic only... | 175 |
| `databricks-serverless-migration` | Migrate Databricks workloads from classic compute to serverless compute. Use when migrating notebooks, jobs, pipelines, or Scala JARs (`spark_jar_task`) from... | 277 |
| `databricks-setup-local` | Previews, provisions, or diagnoses a uv-managed local Python .venv with `databricks environments setup-local`. Use when the user wants to set up or fix one f... | 103 |
| `databricks-spark-declarative-pipelines` | Creates, configures, and updates Databricks Lakeflow Spark Declarative Pipelines (SDP/LDP) using serverless compute. Handles data ingestion with streaming ta... | 141 |
| `databricks-spark-structured-streaming` | Comprehensive guide to Spark Structured Streaming for production workloads. Use when building streaming pipelines, working with Kafka ingestion, implementing... | 71 |
| `databricks-synthetic-data-gen` | Generate realistic synthetic data using Spark + Faker (strongly recommended). Supports serverless execution, multiple output formats (Parquet/JSON/CSV/Delta)... | 267 |
| `databricks-unity-catalog` | Unity Catalog governance, access control, and observability. Use to grant or revoke access (GRANT/REVOKE), reason about the privilege model and ownership, se... | 248 |
| `databricks-unity-gateway` | Use when querying or calling pay-per-token foundation models, or when creating, updating, listing, or querying Unity Gateway (also called Unity AI Gateway) s... | 117 |
| `databricks-unstructured-pdf-generation` | Build RAG / unstructured-document evaluation datasets and demo documents (e.g. for a Genie Agent with an attached volume) on Databricks: generate synthetic P... | 134 |
| `databricks-vector-search` | Databricks Vector Search endpoints and indexes for RAG and semantic search; covers index types, search modes, end-to-end RAG patterns | 340 |
| `databricks-zerobus-ingest` | Push records from apps, services, devices, or scripts directly into Unity Catalog Delta tables with Zerobus Ingest: SDKs (Python, TypeScript, Go, Java, Rust,... | 188 |
| `mlflow-onboarding` | Onboards users to MLflow by determining their use case (GenAI agents/apps or traditional ML/deep learning) and guiding them through relevant quickstart tutor... | 256 |

</details>


### Microsoft Fabric (49)

*OneLake · Eventhouse · Power BI · Dataflows · Warehouse*

<details>
<summary><b>Show 49 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `activator-authoring-cli` | DEPRECATED alias, renamed upstream. Use the `activator-cli` skill instead (authoring: create/update/delete alert rules). Kept so old trigger names still rout... | 10 |
| `activator-cli` | Creates and inspects Fabric Activator (Reflex) alerts: rules, their data sources, conditions, and the Teams or email action they fire, plus decoding an exist... | 117 |
| `activator-consumption-cli` | DEPRECATED alias, renamed upstream. Use the `activator-cli` skill instead (consumption: inspect/list/decode alerts). Kept so old trigger names still route. T... | 10 |
| `azmon-mirroredcatalogs-operations-cli` | Brings Azure Monitor, Application Insights, and Log Analytics telemetry into Fabric as Eventhouse external delta tables and correlates it with business data.... | 1093 |
| `dataflows-authoring-cli` | DEPRECATED alias, renamed upstream. Use the `dataflows-cli` skill instead (authoring). Kept so old trigger names still route. Triggers: dataflows authoring cli. | 10 |
| `dataflows-cli` | Manages Fabric Dataflow Gen2 items, including creation, M editing, connections, output destinations, getDefinition and updateDefinition inspection, executeQu... | 108 |
| `dataflows-consumption-cli` | DEPRECATED alias, renamed upstream. Use the `dataflows-cli` skill instead (consumption). Kept so old trigger names still route. Triggers: dataflows consumpti... | 10 |
| `dataflows-save-as-authoring-cli` | DEPRECATED alias, renamed upstream. Use the `dataflows-cli` skill instead (Gen1 to Gen2 save-as). Kept so old trigger names still route. Triggers: dataflows... | 10 |
| `deployment-pipelines-authoring-cli` | Manages Fabric deployment pipelines for ALM promotion across dev, test, and prod stages, including stage creation, workspace assignment, selective forward or... | 370 |
| `e2e-fabric-cost-estimation` | Estimates Fabric capacity cost before a migration by profiling Spark, SQL, Power BI, and Real-Time workloads, then recommending SKU size and comparing Reserv... | 588 |
| `e2e-medallion-architecture` | Implement end-to-end Medallion Architecture (Bronze/Silver/Gold) lakehouse patterns in Microsoft Fabric using PySpark, Delta Lake, and Fabric Pipelines. Use... | 34 |
| `eventhouse-authoring-cli` | DEPRECATED alias, renamed upstream. Use the `eventhouse-cli` skill instead (authoring). Kept so old trigger names still route. Triggers: eventhouse authoring... | 10 |
| `eventhouse-cli` | Authors and queries Fabric Eventhouse and KQL databases: tables, functions, policies, materialized views, ingestion, and read-only KQL for real-time and time... | 106 |
| `eventhouse-consumption-cli` | DEPRECATED alias, renamed upstream. Use the `eventhouse-cli` skill instead (consumption (read-only KQL)). Kept so old trigger names still route. Triggers: ev... | 10 |
| `eventschemaset-cli` | Governs Event Schema Sets, the Fabric registries of event types and message payload schemas. Covers create, rename, update and delete of a definition, and li... | 96 |
| `eventstream-authoring-cli` | DEPRECATED alias, renamed upstream. Use the `eventstream-cli` skill instead (authoring). Kept so old trigger names still route. Triggers: eventstream authori... | 10 |
| `eventstream-cli` | Owns Fabric Eventstream items end to end: sources, operators, destinations, routing, retention, throughput and connection strings, plus read-only topology ch... | 94 |
| `eventstream-consumption-cli` | DEPRECATED alias, renamed upstream. Use the `eventstream-cli` skill instead (consumption). Kept so old trigger names still route. Triggers: eventstream consu... | 10 |
| `fabriciq` | Answer business questions by querying Power BI reports and dashboards through the FabricIQ MCP endpoint. Orchestrates: discover Power BI artifacts, inspect r... | 38 |
| `fabriciq-ontology-authoring-cli` | DEPRECATED alias, renamed upstream. Use the `fabriciq-ontology-cli` skill instead (authoring). Kept so old trigger names still route. Triggers: fabriciq onto... | 10 |
| `fabriciq-ontology-cli` | Manages Fabric IQ Ontology items, including entity and relationship types, data bindings, and definition updates in both the old JSON format (generation 1, r... | 98 |
| `fabriciq-ontology-consumption-cli` | DEPRECATED alias, renamed upstream. Use the `fabriciq-ontology-cli` skill instead (consumption). Kept so old trigger names still route. Triggers: fabriciq on... | 10 |
| `git-integration-operations-cli` | Runs the Fabric Git integration lifecycle through fab api or az rest, including connecting a workspace to Azure DevOps or GitHub, committing, updating from G... | 623 |
| `hdinsight-migration` | Port Azure HDInsight Spark clusters and Hive workloads to Microsoft Fabric. Removes legacy HiveContext and standalone SparkContext constructors, replacing th... | 43 |
| `microsoft-fabric` | Build and operate Microsoft Fabric workloads from the CLI / REST / Fabric notebooks: Data Pipelines (Data Factory in Fabric), Dataflows Gen2, Lakehouse + One... | 96 |
| `mlv-operations-cli` | Manage Microsoft Fabric Materialized Lake View (MLV) refresh schedules and job execution via REST APIs. Create, update, and delete refresh schedules (interva... | 40 |
| `onelake-catalog-govern-cli` | Governs Microsoft Fabric OneLake catalog health, protection, and trust through Fabric Admin, Core, and Power BI REST APIs. Use for tenant or owner-scoped aud... | 161 |
| `pipeline-migration` | Migrate Synapse Data Factory pipeline artifacts to Microsoft Fabric Data Factory. Handles: linked services → Fabric connections, dataset definitions inlined... | 47 |
| `powerbi-report-authoring` | DEPRECATED alias, renamed upstream. Use the `powerbi-report-cli` skill instead (report authoring (PBIR)). Kept so old trigger names still route. Triggers: po... | 10 |
| `powerbi-report-cli` | Plan, design, author, preview, publish, and manage Power BI reports across requirements, page design, local PBIR/PBIP edits, validation, screenshots, Fabric... | 240 |
| `powerbi-report-design` | DEPRECATED alias, renamed upstream. Use the `powerbi-report-cli` skill instead (report design). Kept so old trigger names still route. Triggers: powerbi repo... | 10 |
| `powerbi-report-management` | DEPRECATED alias, renamed upstream. Use the `powerbi-report-cli` skill instead (publish/rebind/management). Kept so old trigger names still route. Triggers:... | 10 |
| `powerbi-report-planning` | DEPRECATED alias, renamed upstream. Use the `powerbi-report-cli` skill instead (report planning). Kept so old trigger names still route. Triggers: powerbi re... | 10 |
| `project-osmos` | Orchestrate Project Osmos for long-running Fabric and OneLake data-engineering outcomes, including task status, messages, follow-ups, cancellation, and delet... | 177 |
| `search-consumption-cli` | Find and discover Microsoft Fabric items across workspaces when the workspace is unknown. Use when the user wants to: (1) find an item by name across workspa... | 33 |
| `semantic-model-authoring` | Develops and manages Power BI semantic models across Desktop, PBIP projects, and Fabric Service. Handles: (1) creating new models (Import, DirectQuery, Direc... | 38 |
| `semantic-model-consumption` | Execute raw DAX queries and inspect metadata of Microsoft Fabric Power BI semantic models via the MCP server ExecuteQuery tool. Use when the user already kno... | 33 |
| `spark-authoring-cli` | DEPRECATED alias, renamed upstream. Use the `spark-cli` skill instead (notebook authoring). Kept so old trigger names still route. Triggers: spark authoring... | 10 |
| `spark-cli` | Manages Fabric Spark work, including notebook cell code with %%configure, %%sql, PySpark and notebookutils, named notebook runs, Livy sessions, triage of fai... | 101 |
| `spark-consumption-cli` | DEPRECATED alias, renamed upstream. Use the `spark-cli` skill instead (consumption). Kept so old trigger names still route. Triggers: spark consumption cli. | 10 |
| `spark-operations-cli` | DEPRECATED alias, renamed upstream. Use the `spark-cli` skill instead (operations and failure triage). Kept so old trigger names still route. Triggers: spark... | 10 |
| `spark-python-data-source` | Build custom Python data sources for Apache Spark using the PySpark DataSource API — batch and streaming readers/writers for external systems. Use this skill... | 49 |
| `sqldb-cli` | Manages a Fabric SQL database item, the OLTP SQL Server engine, including running T-SQL through sqlcmd, temporal and vector similarity search, schema and sys... | 96 |
| `sqldw-authoring-cli` | DEPRECATED alias, renamed upstream. Use the `sqldw-cli` skill instead (authoring (DDL/DML)). Kept so old trigger names still route. Triggers: sqldw authoring... | 10 |
| `sqldw-cli` | Manage Fabric Warehouse, Lakehouse SQL endpoints, and Mirrored Databases: DDL/DML, COPY INTO, read-only T-SQL, Query Insights diagnostics, and Capacity Metri... | 139 |
| `sqldw-consumption-cli` | DEPRECATED alias, renamed upstream. Use the `sqldw-cli` skill instead (read-only queries). Kept so old trigger names still route. Triggers: sqldw consumption... | 10 |
| `sqldw-operations-cli` | DEPRECATED alias, renamed upstream. Use the `sqldw-cli` skill instead (operations and Query Insights). Kept so old trigger names still route. Triggers: sqldw... | 10 |
| `synapse-migration` | Port Azure Synapse Analytics Spark workloads to Microsoft Fabric. Translates mssparkutils calls to notebookutils (including the env→runtime namespace change)... | 37 |
| `variable-library-cli` | Manages Fabric Variable Library items, including definitions, libraryVariables and valueSets overrides. Covers which consumers can reference a variable and w... | 109 |

</details>


### Snowflake (4)

*Cortex AI · Snowpark · Kafka · Dynamic Tables*

<details>
<summary><b>Show 4 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `snowflake` | Route high-level Snowflake work to the right Open Skills Snowflake skill. Use whenever the user mentions Snowflake, Snowflake SQL, warehouses, databases, sch... | 33 |
| `cortex-code` | Routes Snowflake-related operations to Cortex Code CLI for specialized Snowflake expertise. Use when user asks about Snowflake databases, data warehouses, SQ... | 57 |
| `snowflake-cortex` | Build Snowflake objects (databases, schemas, warehouses, tables, stages, streams, tasks, dynamic tables, RBAC) and design Snowflake Cortex AI workloads (LLM... | 85 |
| `snowflake-kafka` | Build, configure, debug, and explain the Snowflake Kafka Connector — both the classic v3 file-based Snowpipe path and the v4 Snowpipe Streaming path. Use whe... | 75 |

</details>


### Microsoft Foundry (13)

*Azure AI Foundry · Agents · Projects · Endpoints*

<details>
<summary><b>Show 13 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `foundry-agent-tools` | Give Microsoft Foundry agents tools — code interpreter, file search (RAG), custom function tools, and connected/grounded agents — in the agent definition via... | 45 |
| `foundry-agents-authoring` | Create, update, version, and delete Microsoft Foundry agents via az rest — both prompt agents (serverless) and hosted agents (container). Use when the user w... | 56 |
| `foundry-agents-runtime` | Run Microsoft Foundry agents and get answers via the Responses API and threads/runs, using az rest. Use when the user wants to "run a foundry agent", "ask th... | 43 |
| `foundry-config` | Connect to Microsoft Foundry (Azure AI Foundry / Foundry Agent Service): pick resource + project, build the project endpoint, get a data-plane token, and ver... | 79 |
| `foundry-connections` | Register and inspect Microsoft Foundry connections — Azure AI Search, Storage, Key Vault, other AI services — so agents and projects can reach external resou... | 60 |
| `foundry-content-safety` | Apply and inspect Microsoft Foundry content safety — content filters (RAI policies), prompt shields / jailbreak detection, and groundedness — on deployments... | 46 |
| `foundry-docs` | Authoritative Microsoft Foundry documentation index — use as a fallback when another foundry-* skill doesn't cover a topic, to look up an unfamiliar Foundry... | 39 |
| `foundry-evaluation` | Evaluate Microsoft Foundry agents and models — create evals, run them over a dataset, score with graders (string check, label model, AI judge). Use when the... | 46 |
| `foundry-fine-tuning` | Fine-tune models on Microsoft Foundry — prepare JSONL training data, launch and monitor a fine-tuning job, then deploy the tuned model. Use when the user wan... | 49 |
| `foundry-infra-azd` | Provision Microsoft Foundry infrastructure — resource (AIServices account), project, and model deployments — with the Azure CLI or azd / Bicep / Terraform. U... | 47 |
| `foundry-model-catalog` | Browse the Microsoft Foundry model catalog and deploy models (serverless GlobalStandard or managed) so agents can use them. Use when the user wants to "list/... | 48 |
| `foundry-observability` | Trace and monitor Microsoft Foundry agents — wire Application Insights, capture OpenTelemetry traces of agent/tool calls, and query usage, latency, and error... | 46 |
| `foundry-rag-search` | Build retrieval-augmented generation on Microsoft Foundry: index documents into a built-in vector store (or Azure AI Search) and ground agent answers via fil... | 48 |

</details>


### Azure (3)

*Agent skills*

<details>
<summary><b>Show 3 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `azure-cosmos-db` | Azure Cosmos DB architecture for NoSQL workloads: data modeling (embed vs reference, partition key and hierarchical keys, limits), throughput (provisioned, a... | 34 |
| `csa-playbook` | Cloud Solution Architect playbook for Azure data and AI platforms (Microsoft Fabric, Azure Databricks, Cosmos DB, Purview): architectural design session (ADS... | 43 |
| `microsoft-purview` | Microsoft Purview architecture for data governance, data security and compliance on Azure data platforms: product map (Unified Catalog, Data Map, governance... | 32 |

</details>


---

## 🛠️ Uninstall

Skills are just folders. Remove what you installed:

```bash
rm -rf ~/.claude/skills/databricks-genie     # one skill
ls ~/.claude/skills                          # see what's there
```

## 📄 License

MIT — see [LICENSE](LICENSE).

<div align="center"><sub>Built for agents that build data platforms.</sub></div>
