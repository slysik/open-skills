---
name: microsoft-fabric
description: "Build and operate Microsoft Fabric workloads from the CLI / REST / Fabric notebooks: Data Pipelines (Data Factory in Fabric), Dataflows Gen2, Lakehouse + OneLake, Warehouse, Spark notebooks, Eventstream / Real-Time Intelligence, Semantic Models, Deployment Pipelines, workspaces, capacities, domains, Git integration, and monitoring. USE FOR: create fabric workspace, assign capacity, create lakehouse, create warehouse, build fabric data pipeline, copy activity, dataflow gen2, on-prem data gateway, parameterize pipeline, schedule trigger, pipeline failure / retry / resiliency, dead-letter, idempotent ingestion, monitor pipeline runs, alerting on failure, az fabric CLI, fab CLI, Fabric REST API, OneLake shortcuts, medallion bronze/silver/gold, compare Fabric Data Factory vs ADF vs Synapse pipelines. ARCHITECT USE FOR: Fabric design session, capacity sizing, Direct Lake guardrails, OneLake security, private link, workspace CMK, Fabric DR / BCDR, shortcut vs mirroring, Fabric vs Databricks, data agent, Copilot data residency. DO NOT USE FOR: Snowflake (use snowflake-cortex), IBM watsonx (use watsonx-data-fabric), pure Azure ADF outside Fabric (use the ADF deck under /Users/slysik/fabric)."
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

## Architect layer (design sessions, PoC sizing, production hardening)

Decision-oriented references, each with trade-offs, anti-patterns, a reference architecture and a talk track. Verified against Microsoft Learn on 2026-10-19; items Learn did not state are marked `UNVERIFIED`.

| Reference | Use when |
|---|---|
| [references/architect/workload-selection.md](references/architect/workload-selection.md) | Lakehouse vs Warehouse vs Eventhouse vs SQL db; Direct Lake vs Import vs DQ; Fabric vs Databricks vs Synapse |
| [references/architect/capacity-finops.md](references/architect/capacity-finops.md) | SKU sizing, smoothing, throttling, pause, overage, isolation, FinOps |
| [references/architect/security-governance.md](references/architect/security-governance.md) | Roles, OneLake security, RLS/CLS, labels, private link, MPE, TWA, CMK, tenant settings |
| [references/architect/resiliency-dr.md](references/architect/resiliency-dr.md) | Zone vs regional failure, BCDR switch, recovery runbook, RPO/RTO tiers |
| [references/architect/onelake-integration.md](references/architect/onelake-integration.md) | Shortcut vs mirror vs copy, Iceberg interop, ADF/Synapse migration |
| [references/architect/alm-governance.md](references/architect/alm-governance.md) | Git, deployment pipelines, variable libraries, domains, endorsement |
| [references/architect/ai-readiness.md](references/architect/ai-readiness.md) | Data agent, Copilot data handling, IQ/ontology, AI functions, vector placement |
| [references/architect/databricks-coexistence.md](references/architect/databricks-coexistence.md) | Mirrored catalog, OneLake federation, Databricks-to-OneLake patterns |

## Related upstream skills (microsoft/skills-for-fabric)

| Task | Skill |
|---|---|
| SKU sizing and PAYG/reservation comparison with live pricing | [e2e-fabric-cost-estimation](../e2e-fabric-cost-estimation/SKILL.md) |
| Governance audit: domains, labels, tags, endorsement | [onelake-catalog-govern-cli](../onelake-catalog-govern-cli/SKILL.md) |
| Dev/test/prod promotion | [deployment-pipelines-authoring-cli](../deployment-pipelines-authoring-cli/SKILL.md) |
| Git connect, commit, update, conflicts | [git-integration-operations-cli](../git-integration-operations-cli/SKILL.md) |
| Parameterization | [variable-library-cli](../variable-library-cli/SKILL.md) |
| SQL database in Fabric (OLTP) | [sqldb-cli](../sqldb-cli/SKILL.md) |

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
