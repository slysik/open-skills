<div align="center">

# Databricks · Microsoft Fabric · Snowflake — Agent Skills

**64 production skills** that turn Claude Code, Codex, or pi into a data-platform engineer.
Build everything on **Databricks, Snowflake, and Microsoft Fabric** through CLIs and REST APIs —
**no MCP, no UI, no glue code.**

[![Skills](https://img.shields.io/badge/skills-64-FF3621)](#-skill-catalog)
[![Avg router](https://img.shields.io/badge/avg_router-76.2_lines-29B5E8)](#-how-these-skills-are-optimized)
[![Harness](https://img.shields.io/badge/harness-Claude_Code_·_Codex_·_pi-11A37F)](#-works-with-your-agent)
[![Architecture](https://img.shields.io/badge/architecture-CLI_+_REST,_no_MCP-555)](#-design-principles)
[![Landing](https://img.shields.io/badge/landing-GitHub_Pages-8b5cf6)](https://slysik.github.io/dbx-snowflake-fabric/)

### → [**Open the landing page**](https://slysik.github.io/dbx-snowflake-fabric/) ←

</div>

---

## ⚡ Install in one step

Installs **all 64 skills** into Claude Code:

```bash
curl -fsSL https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/install.sh | bash
```

### Pick exactly what you want

```bash
# one platform
curl -fsSL https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/install.sh | bash -s -- --platform snowflake

# a single skill
curl -fsSL https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/install.sh | bash -s -- databricks-genie

# into Codex or pi instead of Claude Code
curl -fsSL https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/install.sh | bash -s -- --harness codex --platform fabric

# just list everything first
curl -fsSL https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/install.sh | bash -s -- --list
```

| Flag | Effect |
|---|---|
| *(none)* | install all 64 skills |
| `--platform databricks\|fabric\|snowflake` | install one platform group (repeatable) |
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

---

## 🧠 How these skills are optimized

Every skill was rewritten to a measured standard, not vibes:

- **Thin-router architecture** — `SKILL.md` is a *router*, not a manual. Average **76.2 lines** (target < 100, hard cap 150). 62 of 64 routers are under 150.
- **Progressive disclosure** — the router loads only a concept map + a "load which sub-doc" table. Heavy detail lives in `references/` and is pulled into context **only when the task needs it**, so a typical invocation reads tens of lines instead of thousands.
- **CLI-first, REST-second, MCP-never** — vendor CLI / REST is the only required path. No MCP servers to install, register, or keep alive. (One Databricks skill was rewritten specifically because it wrongly mandated an MCP tool that registered zero tools.)
- **Connection contract** — every auth doc follows the same 4 headings: *Interactive · Service principal · Verify · Troubleshoot* — so the agent never guesses how to authenticate.
- **Preservation-tested trims** — routers were shrunk by moving body to `references/` *verbatim*; an automated check proves no command or code line was lost in the process.

**Suite totals:** 64 skills · 76.2 avg router lines · 120,572 total lines of curated playbook.

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
| `databricks-agent-bricks` | Create and manage Databricks Agent Bricks: Knowledge Assistants (KA) for document Q&A, Genie Spaces for SQL exploration, and Supervisor Agents (MAS) for mult... | 68 |
| `databricks-ai-functions` | Use Databricks built-in AI Functions (ai_classify, ai_extract, ai_summarize, ai_mask, ai_translate, ai_fix_grammar, ai_gen, ai_analyze_sentiment, ai_similari... | 102 |
| `databricks-aibi-dashboards` | Create Databricks AI/BI dashboards | 95 |
| `databricks-app-apx` | Build full-stack Databricks applications using APX framework (FastAPI + React). | 102 |
| `databricks-app-python` | Builds Databricks applications | 135 |
| `databricks-bundles` | Create and configure Declarative Automation Bundles (formerly Asset Bundles) with best practices for multi-environment deployments (CICD) | 61 |
| `databricks-config` | Manage Databricks workspace connections: check current workspace, switch profiles, list available workspaces, or authenticate to a new workspace | 72 |
| `databricks-dbsql` | >- | 65 |
| `databricks-docs` | Databricks documentation reference via llms.txt index | 65 |
| `databricks-execution-compute` | >- | 83 |
| `databricks-genie` | Create and query Databricks Genie Spaces for natural language SQL exploration | 62 |
| `databricks-iceberg` | Apache Iceberg tables on Databricks — Managed Iceberg tables, External Iceberg Reads (fka Uniform), Compatibility Mode, Iceberg REST Catalog (IRC), Iceberg v... | 149 |
| `databricks-jobs` | Use this skill proactively for ANY Databricks Jobs task - creating, listing, running, updating, or deleting jobs | 104 |
| `databricks-lakebase-autoscale` | Patterns and best practices for Lakebase Autoscaling (next-gen managed PostgreSQL) | 134 |
| `databricks-lakebase-provisioned` | Patterns and best practices for Lakebase Provisioned (Databricks managed PostgreSQL) for OLTP workloads | 99 |
| `databricks-metric-views` | Unity Catalog metric views: define, create, query, and manage governed business metrics in YAML | 82 |
| `databricks-migration` | > | 42 |
| `databricks-mlflow-evaluation` | MLflow 3 GenAI agent evaluation | 149 |
| `databricks-model-serving` | Deploy and query Databricks Model Serving endpoints | 89 |
| `databricks-parsing` | Parse documents (PDF, DOCX, PPTX, images) using ai_parse_document, or build custom RAG pipelines | 86 |
| `databricks-python-sdk` | Databricks development guidance including Python SDK, Databricks Connect, CLI, and REST API | 58 |
| `databricks-spark-declarative-pipelines` | Creates, configures, and updates Databricks Lakeflow Spark Declarative Pipelines (SDP/LDP) using serverless compute | 142 |
| `databricks-spark-structured-streaming` | Comprehensive guide to Spark Structured Streaming for production workloads | 66 |
| `databricks-synthetic-data-gen` | Generate realistic synthetic data using Spark + Faker (strongly recommended) | 87 |
| `databricks-unity-catalog` | Unity Catalog system tables and volumes | 108 |
| `databricks-unstructured-pdf-generation` | Generate PDF documents from HTML and upload to Unity Catalog volumes | 90 |
| `databricks-vector-search` | Patterns for Databricks Vector Search: create endpoints and indexes, query with filters, manage embeddings | 139 |
| `databricks-zerobus-ingest` | Build Zerobus Ingest clients for near real-time data ingestion into Databricks Delta tables via gRPC | 139 |
| `mlflow-onboarding` | Onboards users to MLflow by determining their use case (GenAI agents/apps or traditional ML/deep learning) and guiding them through relevant quickstart tutor... | 141 |

</details>


### Microsoft Fabric (32)

*OneLake · Eventhouse · Power BI · Dataflows · Warehouse*

<details>
<summary><b>Show 32 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `activator-authoring-cli` | > | 41 |
| `activator-consumption-cli` | > | 43 |
| `dataflows-authoring-cli` | > | 43 |
| `dataflows-consumption-cli` | > | 43 |
| `dataflows-save-as-authoring-cli` | > | 43 |
| `e2e-medallion-architecture` | > | 35 |
| `eventhouse-authoring-cli` | > | 39 |
| `eventhouse-consumption-cli` | > | 40 |
| `eventstream-authoring-cli` | > | 39 |
| `eventstream-consumption-cli` | > | 39 |
| `fabriciq` | > | 39 |
| `fabriciq-ontology-authoring-cli` | 'Create and evolve Fabric IQ Ontology (preview) items from CLI — define entity types, properties (including timeseries), relationship types, and bind them to... | 30 |
| `fabriciq-ontology-consumption-cli` | > | 43 |
| `hdinsight-migration` | > | 44 |
| `microsoft-fabric` | Build and operate Microsoft Fabric workloads from the CLI / REST / Fabric notebooks: Data Pipelines (Data Factory in Fabric), Dataflows Gen2, Lakehouse + One... | 67 |
| `mlv-operations-cli` | > | 41 |
| `pipeline-migration` | > | 48 |
| `powerbi-report-authoring` | >- | 40 |
| `powerbi-report-design` | >- | 36 |
| `powerbi-report-management` | Manage Power BI report workspace items in Microsoft Fabric via `az rest` CLI against the Fabric REST API | 37 |
| `powerbi-report-planning` | >- | 39 |
| `search-consumption-cli` | > | 34 |
| `semantic-model-authoring` | > | 39 |
| `semantic-model-consumption` | > | 34 |
| `spark-authoring-cli` | > | 41 |
| `spark-consumption-cli` | > | 32 |
| `spark-operations-cli` | > | 44 |
| `spark-python-data-source` | Build custom Python data sources for Apache Spark using the PySpark DataSource API — batch and streaming readers/writers for external systems | 50 |
| `sqldw-authoring-cli` | > | 35 |
| `sqldw-consumption-cli` | > | 36 |
| `sqldw-operations-cli` | > | 39 |
| `synapse-migration` | > | 38 |

</details>


### Snowflake (3)

*Cortex AI · Snowpark · Kafka · Dynamic Tables*

<details>
<summary><b>Show 3 skills</b></summary>

| Skill | What it does | Router |
|---|---|---|
| `cortex-code` | Routes Snowflake-related operations to Cortex Code CLI for specialized Snowflake expertise | 484 |
| `snowflake-cortex` | Build Snowflake objects (databases, schemas, warehouses, tables, stages, streams, tasks, dynamic tables, RBAC) and design Snowflake Cortex AI workloads (LLM ... | 86 |
| `snowflake-kafka` | Build, configure, debug, and explain the Snowflake Kafka Connector — both the classic v3 file-based Snowpipe path and the v4 Snowpipe Streaming path | 204 |

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
