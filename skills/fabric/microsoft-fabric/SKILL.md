---
name: microsoft-fabric
description: "Build and operate Microsoft Fabric workloads from the CLI / REST / Fabric notebooks: Data Pipelines (Data Factory in Fabric), Dataflows Gen2, Lakehouse + OneLake, Warehouse, Spark notebooks, Eventstream / Real-Time Intelligence, Semantic Models, Deployment Pipelines, workspaces, capacities, domains, Git integration, and monitoring. USE FOR: create fabric workspace, assign capacity, create lakehouse, create warehouse, build fabric data pipeline, copy activity, dataflow gen2, on-prem data gateway, parameterize pipeline, schedule trigger, pipeline failure / retry / resiliency, dead-letter, idempotent ingestion, monitor pipeline runs, alerting on failure, az fabric CLI, fab CLI, Fabric REST API, OneLake shortcuts, medallion bronze/silver/gold, compare Fabric Data Factory vs ADF vs Synapse pipelines. DO NOT USE FOR: Snowflake (use snowflake-cortex), IBM watsonx (use watsonx-data-fabric), pure Azure ADF outside Fabric (use the ADF deck under /Users/slysik/fabric)."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# Microsoft Fabric Skill

Stand up and operate any component of **Microsoft Fabric** from CLI, REST, and
notebooks. **REST is the primary execution path** (the `fab` CLI is an optional
convenience and is not installed here); MCP is never required. Opinionated toward
**Fabric Data Factory pipelines** but structured to cover the full surface area.

## What Microsoft calls "Fabric"

| Capability | Fabric experience | Primary entry point |
|---|---|---|
| Orchestration / ETL | **Data Factory in Fabric** (Pipelines + Dataflows Gen2) | `/v1/workspaces/{ws}/dataPipelines` REST · `fab` |
| Lakehouse (Delta on OneLake) | **Lakehouse** | Notebooks · `/v1/workspaces/{ws}/lakehouses` REST |
| MPP SQL warehouse | **Warehouse** | T-SQL endpoint · `/v1/workspaces/{ws}/warehouses` REST |
| Spark notebooks / jobs | **Data Engineering** | `%%pyspark` · `/v1/workspaces/{ws}/notebooks` REST |
| Streaming + CDC | **Real-Time Intelligence** (Eventstream, KQL DB, Activator) | Eventstream · REST |
| BI semantic models | **Power BI in Fabric** | XMLA · Power BI REST · `semanticModels` |
| Governance | **OneLake catalog**, **Purview** | Fabric portal + Purview |
| Storage | **OneLake** (one lake per tenant) | `abfss://<ws>@onelake.dfs.fabric.microsoft.com/...` |
| Compute billing | **Fabric Capacity (F SKUs)** | Azure portal · `az` |

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [auth/auth.md](auth/auth.md) | **Connect.** `az` Entra token + Fabric REST (primary), SP/headless flow, verify, troubleshoot. |
| [patterns.md](patterns.md) | Most-performant default build: Direct Lake, OneLake shortcuts, idempotent loads, capacity-aware throttling. |
| [references/setup-and-conventions.md](references/setup-and-conventions.md) | Env vars, optional `fab` bootstrap, naming conventions, 60-second smoke test, quick recipes. |
| [data-pipelines/data-pipelines.md](data-pipelines/data-pipelines.md) | **Primary.** Create/run/monitor pipelines; activities, params, triggers, gateway, connections. |
| [data-pipelines/failure-handling.md](data-pipelines/failure-handling.md) | A pipeline failed — read run history, classify, fix, re-run. Triage decision tree. |
| [data-pipelines/resiliency.md](data-pipelines/resiliency.md) | Design-time resiliency: retries, backoff, idempotent loads, dead-letter, alerting, failover. |
| [recipes.md](recipes.md) | End-to-end recipes: medallion, incremental copy, nightly Warehouse load, event-driven landing, CI/CD. |

## Mental model

```
   ┌──────────────── Microsoft Fabric (SaaS) ────────────────┐
   │ Tenant ─ Capacity (F SKU) ─ Workspaces ─ Items          │
   │ Entra ID token → identity (users, groups, SPs, MIs)     │
   │   Data Factory  ─ orchestrate ─▶ Pipelines · Dataflows  │
   │   OneLake       ─ store      ─▶ Lakehouse / Warehouse   │
   │   Notebooks/Spark ─ transform ─▶ KQL · Eventstream      │
   │   Power BI      ─ consume    ─▶ DirectLake models       │
   └─────────────────────────────────────────────────────────┘
```

Read as: **Pipelines orchestrate · OneLake stores · Lakehouse/Warehouse serve ·
Notebooks/Spark transform · Power BI consumes.** Capacity = what you pay for;
workspace = unit of RBAC + Git.

## Cross-skill notes

- **ADF / Synapse Pipelines** (non-Fabric ancestors): deck at `/Users/slysik/fabric/…L300 Deck.pdf`.
  Fabric replaces Linked Services with **Connections** and IR with **on-prem data gateway**.
- **Snowflake parallels** (Tasks ≈ pipelines, Streams ≈ CDC, Snowpipe ≈ event Copy): `snowflake-cortex`.
- **IBM DataStage parallels**: `watsonx-data-fabric/datastage-dv`.
