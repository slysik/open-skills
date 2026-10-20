# CSA skill gap audit

Last verified: 2026-10-19. Method: Microsoft Learn pages fetched by research agents; every tag below is the page's own wording. Items the pages did not state are `UNVERIFIED`, not assumed.

## Area A – Microsoft Fabric (done in this pass)

### What existed
`skills/fabric/microsoft-fabric` (66-line router + sub-docs: auth, capacity, cicd, data-pipelines, notebooks, patterns, recipes, interview-prep). 31 other Fabric skills are CLI/REST how-tos (spark, sqldw, eventhouse, eventstream, semantic-model, powerbi, migrations, fabriciq).

### Gaps versus the architect checklist
| Requirement | Status before | Action |
|---|---|---|
| Workload selection matrix, Direct Lake vs Import vs DQ | missing (only a Warehouse-vs-Lakehouse Q&A) | `references/architect/workload-selection.md` |
| Capacity sizing, smoothing, throttling, pause, overage, FinOps | partial, **stale** | `references/architect/capacity-finops.md`; patched `capacity/capacity.md` |
| Security: roles, OneLake security, RLS/CLS, labels, private link, MPE, TWA, OAP, CMK | missing | `references/architect/security-governance.md` |
| Resiliency and DR, RPO/RTO by workload | missing (resiliency.md covers pipelines only) | `references/architect/resiliency-dr.md` |
| OneLake shortcuts, mirroring, Iceberg, migration | missing | `references/architect/onelake-integration.md` |
| Governance and ALM | partial (`cicd/cicd.md` is hands-on) | `references/architect/alm-governance.md` |
| AI-readiness | missing | `references/architect/ai-readiness.md` |
| Databricks coexistence | missing | `references/architect/databricks-coexistence.md` |
| ADS/PoC/interview framing | partial (interview-prep is data-engineer level) | deferred to shared CSA playbook (Step 3) |

### Stale statements found in existing files
1. `capacity/capacity.md` section 2 described throttling at 100% / 150% / 200% CU consumption. Learn (`enterprise/throttling`, ms.date 2026-08-14) defines stages by smoothed *future* usage: up to 10 min = overage protection (nothing throttled), more than 10 and up to 60 min = interactive delay (20 s), more than 60 min and up to 24 h = interactive rejection, more than 24 h = background rejection. **Patched.**
2. `capacity/capacity.md` says interactive operations are smoothed over a 5-minute window. Learn says a minimum of 5 minutes and up to 64 minutes depending on CU use. **Patched.**
3. `microsoft-fabric/SKILL.md` description mentions `az fabric CLI`; `fab` is not logged in on this machine and the router says it is "not installed". Re-check which CLI is current. `UNVERIFIED`.

### Not verifiable from fetched pages (open items)
- F-SKU reservation discount percentage; per-SKU feature table; Capacity Metrics app details; surge protection.
- Warehouse restore points and retention; per-workload backup beyond the DR guide.
- Per-source mirroring limits and per-source GA status; shortcut transformations.
- Fabric REST API overview, Terraform provider, `fab` CLI GA status.
- Fabric MCP status; Fabric + Azure AI Search/Foundry integration page; planning item status.
- Mirrored Azure Databricks catalog GA status; OneLake catalog federation in Databricks GA status.
- Default states of tenant settings.

## Area B – Azure Databricks (done in this pass)
Existing: 45 platform-agnostic `databricks-*` skills, no Azure layer. Added `skills/databricks/azure-databricks-architecture/` (router + networking-security, identity-uc-storage, reliability-ai-ops). Fabric interop is covered once, in `skills/fabric/microsoft-fabric/references/architect/databricks-coexistence.md`, and linked.
Unverified from research: supported VNet-injection regions; NCC, serverless egress control, managed DR, predictive optimization, Agent Bricks and MLflow 3 GA labels; CMK Key Vault prerequisites for DBFS/managed disk pages; per-connector federation limits; Azure Policy / Defender coverage; Azure Monitor diagnostic-settings setup; per-task retry limits; Lakeflow pipeline limits. Not live-tested: no Databricks workspace call was made (profile `slysik-azure` is not authenticated).

## Area C – Cosmos DB (done in this pass)
No Cosmos skill existed. Added `skills/azure/azure-cosmos-db/` (router + modeling-throughput, resiliency-consistency, security-networking, ai-analytics-api-ops). Facts verified 2026-10-19.
Unverified: SLA percentages other than 99.999%; RTO figures; backup RPO/RTO; hierarchical partition key GA (and Python support, pages contradict); burst capacity GA; per-partition automatic failover GA; all-versions-and-deletes change feed GA; Always Encrypted GA; Entra data-plane auth on non-NoSQL APIs; dynamic data masking feature; full-text search, hybrid search (RRF), semantic cache and MCP toolkit pages (gen-ai index 404); Azure DocumentDB GA; Cosmos DB for PostgreSQL retirement status; Java/Python SDK tip pages; Azure Monitor alert pages; vector search GA label (inferred); Cosmos DB in Fabric (separate item) status. Not live-tested: no Azure resources created. Tension to flag to customers: Purview Cosmos scans need the account key while security baselines say disable local auth.

## Area D – Purview (done in this pass)
No Purview skill existed. Added `skills/azure/microsoft-purview/` (router + product-map-billing, scanning-lineage-networking, governance-operating-model, fabric-ai-compliance). Facts verified 2026-10-20.
Unverified: Unified Catalog GA labels (overview untagged; CDEs, OKRs, glossary migration, health actions are Preview); data quality supported sources; Data Map API rate limits (limits page 404); price points (pricing page did not render numbers); Fabric protection policies and DLP prerequisites; Data Map data residency/regions; REST/Atlas APIs, Python SDK status, Terraform/Bicep pages (404); licence prerequisites (E5 / E5 Compliance); DSPM for AI pay-as-you-go pricing; Snowflake auth status after the July 2026 basic-auth deadline; conflicting statements between pages (Databricks UC scoped scan and managed PE; SHIR Java version).

## Upstream review: microsoft/skills-for-fabric (v0.3.18, 2026-09-25, MIT)
Requested by the user. 25 skills, weekly cadence. Findings:
- It has **no** Purview, security/networking, DR or architect-level skills; our `references/architect/` and the new Purview/Databricks/playbook skills are complementary, not duplicates.
- Useful upstream skills not installed locally: `onelake-catalog-govern-cli` (governance audit, labels, tags, domains; needs tenant admin), `e2e-fabric-cost-estimation` (SKU sizing and PAYG/RI/Autoscale comparison; requires the live Retail Prices API before quoting dollars), `deployment-pipelines-authoring-cli`, `git-integration-operations-cli`, `variable-library-cli`, `sqldb-cli`, `azmon-mirroredcatalogs-operations-cli`, `fabriciq`/`fabriciq-ontology-cli`. Local copies of activator/dataflows/eventhouse/eventstream/spark/sqldw skills use older `-authoring-cli` / `-consumption-cli` names; upstream merged them to `*-cli`. **Decision for the user: update/install upstream skills (not done).**
- Conventions to note: telemetry header `x-ms-fabric-skill: <name>` on every Fabric API call, a shared `common/` docs folder, 450-char description cap (0.3.14 notes), mode-dispatcher pattern. Our architect references do not call Fabric APIs, so the header rule does not apply to them.
- Upstream claims to treat with care (quoted from the review): no staged throttling model (only "observed defaults, not a documented contract" for rate limits; smoothing "~5-64 min / 24 h" uncited, which matches Learn); no Direct Lake numeric guardrails; e2e-medallion-architecture marks RLS/CLS supported on non-schema Lakehouses via an "internal runtime configuration path that may change"; COMMON-CORE preview/beta deprecation date 2026-03-31 has passed; a broken reference to `semantic-model-cli`.
- Pending: adopt the "live pricing before dollar figures" rule when writing any cost number.

## Shared playbook (done in this pass)
`skills/azure/csa-playbook/` (router + ads-guide, poc-framework, waf-checklists, mission-critical, cost-business-value, reference-architectures, anti-patterns-objections, interview-prep). Product facts reused from Fabric, Cosmos and Databricks research; Purview statements are pointers marked `UNVERIFIED`.
