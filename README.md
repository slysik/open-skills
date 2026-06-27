<div align="center">

# Databricks · Microsoft Fabric · Snowflake — Agent Skills

**78 production skills** that turn Claude Code, Codex, or pi into a data-platform engineer.
Build everything on **Databricks, Snowflake, and Microsoft Fabric** through CLIs and REST APIs —
**no MCP, no UI, no glue code.**

[![Skills](https://img.shields.io/badge/skills-78-FF3621)](#-skill-catalog)
[![Avg router](https://img.shields.io/badge/avg_router-70.5_lines-29B5E8)](#-how-these-skills-are-optimized)
[![Harness](https://img.shields.io/badge/harness-Claude_Code_·_Codex_·_pi-11A37F)](#-works-with-your-agent)
[![Architecture](https://img.shields.io/badge/architecture-CLI_+_REST,_no_MCP-555)](#-design-principles)
[![Landing](https://img.shields.io/badge/landing-GitHub_Pages-8b5cf6)](https://slysik.github.io/open-skills/)

### → [**Open the landing page**](https://slysik.github.io/open-skills/) ←

</div>

---

## ⚡ Install in one step

Installs **all 78 skills** into Claude Code:

```bash
just install-codex
```

### Pick exactly what you want

```bash
# with just from a local clone
just install-databricks-ai         # Databricks skills into Codex
just install-snowflake-ai          # Snowflake skills into Codex
just install-microsoft-ai          # Microsoft Fabric + Foundry skills into Codex

# generic just form also works
just install databricks-ai
just install snowflake-ai
just install microsoft-ai

# one platform
just install-platform snowflake

# a single skill
just install databricks-genie

# into Codex or pi instead of Claude Code
just install-platform fabric codex

# just list everything first
just list
```

| Flag | Effect |
|---|---|
| *(none)* | install all 78 skills |
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

- **Thin-router architecture** — `SKILL.md` is a *router*, not a manual. Average **70.5 lines** (target < 100, hard cap 150). 76 of 78 routers are under 150.
- **Progressive disclosure** — the router loads only a concept map + a "load which sub-doc" table. Heavy detail lives in `references/` and is pulled into context **only when the task needs it**, so a typical invocation reads tens of lines instead of thousands.
- **CLI-first, REST-second, MCP-never** — vendor CLI / REST is the only required path. No MCP servers to install, register, or keep alive. (One Databricks skill was rewritten specifically because it wrongly mandated an MCP tool that registered zero tools.)
- **Connection contract** — every auth doc follows the same 4 headings: *Interactive · Service principal · Verify · Troubleshoot* — so the agent never guesses how to authenticate.
- **Preservation-tested trims** — routers were shrunk by moving body to `references/` *verbatim*; an automated check proves no command or code line was lost in the process.

**Suite totals:** 78 skills · 70.5 avg router lines · 122,433 total lines of curated playbook.

---

## 🎯 Design principles

1. **Applied AI through coding-agent harnesses** — the agent does the work via terminal: CLIs, REST calls, SQL, and scripts.
2. **No MCP.** Dependencies you have to babysit are a liability; standard CLIs are everywhere.
3. **No UI.** Everything is reproducible from a shell — scriptable, diffable, CI-able.
4. **One source of truth.** Skills are versioned folders; the installer just copies them where your agent looks.

---

## 📚 Skill catalog


### Databricks (29)

*Lakehouse · Unity Catalog · Spark · MLflow · Genie*

<details>
<summary><b>Show 29 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `databricks-agent-bricks` | Create and manage Databricks Agent Bricks: Knowledge Assistants (KA) for document Q&A, Genie Spaces for SQL exploration, and Supervisor Agents (MAS) for mult... | 67 |
| `databricks-ai-functions` | Use Databricks built-in AI Functions (ai_classify, ai_extract, ai_summarize, ai_mask, ai_translate, ai_fix_grammar, ai_gen, ai_analyze_sentiment, ai_similari... | 101 |
| `databricks-aibi-dashboards` | Create Databricks AI/BI dashboards. Use when creating, updating, or deploying Lakeview dashboards. CRITICAL: You MUST test ALL SQL queries via execute_sql BE... | 94 |
| `databricks-app-apx` | Build full-stack Databricks applications using APX framework (FastAPI + React). | 101 |
| `databricks-app-python` | Builds Databricks applications. Prefers AppKit (TypeScript + React SDK) for new apps; falls back to Python frameworks (Dash, Streamlit, Gradio, Flask, FastAP... | 134 |
| `databricks-bundles` | Create and configure Declarative Automation Bundles (formerly Asset Bundles) with best practices for multi-environment deployments (CICD). Use when working w... | 60 |
| `databricks-config` | Manage Databricks workspace connections: check current workspace, switch profiles, list available workspaces, or authenticate to a new workspace. Use when th... | 71 |
| `databricks-dbsql` | Databricks SQL (DBSQL) advanced features and SQL warehouse capabilities. This skill MUST be invoked when the user mentions: "DBSQL", "Databricks SQL", "SQL w... | 64 |
| `databricks-docs` | Databricks documentation reference via llms.txt index. Use when other skills do not cover a topic, looking up unfamiliar Databricks features, or needing auth... | 64 |
| `databricks-execution-compute` | Execute code and manage compute on Databricks. Use this skill when the user mentions: "run code", "execute", "run on databricks", "serverless", "no cluster",... | 82 |
| `databricks-genie` | Create and query Databricks Genie Spaces for natural language SQL exploration. Use when building Genie Spaces, exporting and importing Genie Spaces, migratin... | 61 |
| `databricks-iceberg` | Apache Iceberg tables on Databricks — Managed Iceberg tables, External Iceberg Reads (fka Uniform), Compatibility Mode, Iceberg REST Catalog (IRC), Iceberg v... | 148 |
| `databricks-jobs` | Use this skill proactively for ANY Databricks Jobs task - creating, listing, running, updating, or deleting jobs. Triggers include: (1) 'create a job' or 'ne... | 103 |
| `databricks-lakebase-autoscale` | Patterns and best practices for Lakebase Autoscaling (next-gen managed PostgreSQL). Use when creating or managing Lakebase Autoscaling projects, configuring... | 133 |
| `databricks-lakebase-provisioned` | Patterns and best practices for Lakebase Provisioned (Databricks managed PostgreSQL) for OLTP workloads. Use when creating Lakebase instances, connecting app... | 98 |
| `databricks-metric-views` | Unity Catalog metric views: define, create, query, and manage governed business metrics in YAML. Use when building standardized KPIs, revenue metrics, order... | 81 |
| `databricks-migration` | Port Databricks notebooks and jobs to Microsoft Fabric. Provides an exhaustive dbutils to notebookutils substitution table: fs operations (mount removal via... | 41 |
| `databricks-mlflow-evaluation` | MLflow 3 GenAI agent evaluation. Use when writing mlflow.genai.evaluate() code, creating @scorer functions, using built-in scorers (Guidelines, Correctness,... | 148 |
| `databricks-model-serving` | Deploy and query Databricks Model Serving endpoints. Use when (1) deploying MLflow models or AI agents to endpoints, (2) creating ChatAgent/ResponsesAgent ag... | 88 |
| `databricks-parsing` | Parse documents (PDF, DOCX, PPTX, images) using ai_parse_document, or build custom RAG pipelines. Use when the user asks to parse documents or build a custom... | 85 |
| `databricks-python-sdk` | Databricks development guidance including Python SDK, Databricks Connect, CLI, and REST API. Use when working with databricks-sdk, databricks-connect, or Dat... | 57 |
| `databricks-spark-declarative-pipelines` | Creates, configures, and updates Databricks Lakeflow Spark Declarative Pipelines (SDP/LDP) using serverless compute. Handles data ingestion with streaming ta... | 141 |
| `databricks-spark-structured-streaming` | Comprehensive guide to Spark Structured Streaming for production workloads. Use when building streaming pipelines, working with Kafka ingestion, implementing... | 65 |
| `databricks-synthetic-data-gen` | Generate realistic synthetic data using Spark + Faker (strongly recommended). Supports serverless execution, multiple output formats (Parquet/JSON/CSV/Delta)... | 86 |
| `databricks-unity-catalog` | Unity Catalog system tables and volumes. Use when querying system tables (audit, lineage, billing) or working with volume file operations (upload, download,... | 107 |
| `databricks-unstructured-pdf-generation` | Generate PDF documents from HTML and upload to Unity Catalog volumes. Use for creating test PDFs, demo documents, reports, or evaluation datasets. | 89 |
| `databricks-vector-search` | Patterns for Databricks Vector Search: create endpoints and indexes, query with filters, manage embeddings. Use when building RAG applications, semantic sear... | 138 |
| `databricks-zerobus-ingest` | Build Zerobus Ingest clients for near real-time data ingestion into Databricks Delta tables via gRPC. Use when creating producers that write directly to Unit... | 138 |
| `mlflow-onboarding` | Onboards users to MLflow by determining their use case (GenAI agents/apps or traditional ML/deep learning) and guiding them through relevant quickstart tutor... | 140 |

</details>


### Microsoft Fabric (32)

*OneLake · Eventhouse · Power BI · Dataflows · Warehouse*

<details>
<summary><b>Show 32 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `activator-authoring-cli` | Create alerts, notifications, and automated actions on Fabric data and events via Fabric REST API and `az rest` CLI. **Invoke this skill** whenever the user... | 40 |
| `activator-consumption-cli` | Inspect existing alerts, notifications, and automated actions in Fabric via read-only REST API calls using `az rest` CLI. **Invoke this skill** whenever the... | 42 |
| `dataflows-authoring-cli` | Create, update, delete, and refresh Fabric Dataflows Gen2 via write-side CLI against Fabric Items and Connections APIs. Builds mashup.pq + queryMetadata defi... | 42 |
| `dataflows-consumption-cli` | Monitor, inspect, and query saved Fabric Dataflows Gen2 via read-only CLI. List dataflows, decode base64 definitions (mashup.pq, queryMetadata.json, .platfor... | 42 |
| `dataflows-save-as-authoring-cli` | Assess, plan, and execute dataflow Gen1 → Gen2.1 CI/CD save-as operations via CLI (az rest / curl) against Power BI REST and Fabric REST APIs. Scan workspace... | 42 |
| `e2e-medallion-architecture` | Implement end-to-end Medallion Architecture (Bronze/Silver/Gold) lakehouse patterns in Microsoft Fabric using PySpark, Delta Lake, and Fabric Pipelines. Use... | 34 |
| `eventhouse-authoring-cli` | Execute KQL management commands (table management, ingestion, policies, functions, materialized views) against Fabric Eventhouse and KQL Databases via CLI. U... | 38 |
| `eventhouse-consumption-cli` | Run KQL queries against Fabric Eventhouse for real-time intelligence and time-series analytics using `az rest` against the Kusto REST API. Covers KQL operato... | 39 |
| `eventstream-authoring-cli` | Create, wire, and publish Microsoft Fabric Eventstream real-time event streaming topologies via the Fabric Items REST API. Build graph-based definitions with... | 38 |
| `eventstream-consumption-cli` | List, inspect, and monitor Microsoft Fabric Eventstream real-time event ingestion pipelines via the Fabric Items REST API. Discover Eventstreams across works... | 38 |
| `fabriciq` | Answer business questions by querying Power BI reports and dashboards through the FabricIQ MCP endpoint. Orchestrates: discover Power BI artifacts, inspect r... | 38 |
| `fabriciq-ontology-authoring-cli` | Create and evolve Fabric IQ Ontology (preview) items from CLI — define entity types, properties (including timeseries), relationship types, and bind them to... | 29 |
| `fabriciq-ontology-consumption-cli` | Explore Fabric IQ Ontology (preview) items (read-only) from the CLI to ground an agent before it queries data. Explore, describe, and summarize what an ontol... | 42 |
| `hdinsight-migration` | Port Azure HDInsight Spark clusters and Hive workloads to Microsoft Fabric. Removes legacy HiveContext and standalone SparkContext constructors, replacing th... | 43 |
| `microsoft-fabric` | Build and operate Microsoft Fabric workloads from the CLI / REST / Fabric notebooks: Data Pipelines (Data Factory in Fabric), Dataflows Gen2, Lakehouse + One... | 66 |
| `mlv-operations-cli` | Manage Microsoft Fabric Materialized Lake View (MLV) refresh schedules and job execution via REST APIs. Create, update, and delete refresh schedules (interva... | 40 |
| `pipeline-migration` | Migrate Synapse Data Factory pipeline artifacts to Microsoft Fabric Data Factory. Handles: linked services → Fabric connections, dataset definitions inlined... | 47 |
| `powerbi-report-authoring` | Create and modify Power BI report files in PBIR/PBIP format using the `powerbi-report-author` and `powerbi-desktop` CLIs. Use when the user wants to: (1) imp... | 39 |
| `powerbi-report-design` | Generate Power BI report visual design guidance before PBIR files are written. Use when the user wants to: (1) choose tone, signature, page archetypes, chart... | 35 |
| `powerbi-report-management` | Manage Power BI report workspace items in Microsoft Fabric via `az rest` CLI against the Fabric REST API. Use when the user wants to: (1) create reports from... | 36 |
| `powerbi-report-planning` | Build a guided requirements-to-implementation workflow for new Power BI reports and dashboards from semantic models, datasets, or PBIP projects. Use when the... | 38 |
| `search-consumption-cli` | Find and discover Microsoft Fabric items across workspaces when the workspace is unknown. Use when the user wants to: (1) find an item by name across workspa... | 33 |
| `semantic-model-authoring` | Develops and manages Power BI semantic models across Desktop, PBIP projects, and Fabric Service. Handles: (1) creating new models (Import, DirectQuery, Direc... | 38 |
| `semantic-model-consumption` | Execute raw DAX queries and inspect metadata of Microsoft Fabric Power BI semantic models via the MCP server ExecuteQuery tool. Use when the user already kno... | 33 |
| `spark-authoring-cli` | Develop Microsoft Fabric Spark/data engineering workflows and write code in Fabric Notebook cells with intelligent routing to specialized resources. Provides... | 40 |
| `spark-consumption-cli` | Analyze lakehouse data interactively using Fabric Lakehouse Livy API sessions and PySpark/Spark SQL for advanced analytics, DataFrames, cross-lakehouse joins... | 31 |
| `spark-operations-cli` | Diagnose failed Spark jobs, unhealthy Livy sessions, and performance bottlenecks in Microsoft Fabric via read-only CLI triage. Use when the user wants to: (1... | 43 |
| `spark-python-data-source` | Build custom Python data sources for Apache Spark using the PySpark DataSource API — batch and streaming readers/writers for external systems. Use this skill... | 49 |
| `sqldw-authoring-cli` | Execute authoring T-SQL (DDL, DML, data ingestion, transactions, schema changes) against Microsoft Fabric Data Warehouse and SQL endpoints from agentic CLI e... | 34 |
| `sqldw-consumption-cli` | Execute read-only T-SQL queries against Fabric Data Warehouse, Lakehouse SQL Endpoints, and Mirrored Databases via CLI. Default skill for any lakehouse data... | 35 |
| `sqldw-operations-cli` | Analyze Fabric Data Warehouse performance via CLI using sqlcmd and queryinsights views. Diagnose slow queries, SQL pool pressure, cache coldness, and recomme... | 38 |
| `synapse-migration` | Port Azure Synapse Analytics Spark workloads to Microsoft Fabric. Translates mssparkutils calls to notebookutils (including the env→runtime namespace change)... | 37 |

</details>


### Snowflake (4)

*Cortex AI · Snowpark · Kafka · Dynamic Tables*

<details>
<summary><b>Show 4 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `snowflake` | Route high-level Snowflake work to the right Open Skills Snowflake skill. Use whenever the user mentions Snowflake, Snowflake SQL, warehouses, databases, sch... | 33 |
| `cortex-code` | Routes Snowflake-related operations to Cortex Code CLI for specialized Snowflake expertise. Use when user asks about Snowflake databases, data warehouses, SQ... | 483 |
| `snowflake-cortex` | Build Snowflake objects (databases, schemas, warehouses, tables, stages, streams, tasks, dynamic tables, RBAC) and design Snowflake Cortex AI workloads (LLM... | 85 |
| `snowflake-kafka` | Build, configure, debug, and explain the Snowflake Kafka Connector — both the classic v3 file-based Snowpipe path and the v4 Snowpipe Streaming path. Use whe... | 203 |

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
