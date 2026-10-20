# Prompt: Upgrade Fabric / Azure Databricks / Cosmos DB / Purview skills for the Cloud & AI Data Platform CSA role

Copy everything below the line into a fresh Claude Code session opened in `/Users/slysik/open-skills`.

---

## Role and goal

You are helping me prepare for a **Microsoft Cloud Solution Architect – Cloud & AI Data Platform** role. The role supports customers building secure, scalable, AI-ready data solutions on Azure. I lead architectural design sessions (ADS), proof-of-concepts (PoC), and production deployments for mission-critical workloads. I focus on performance, resiliency, security, and measurable business value. I work with Microsoft Fabric, Azure Databricks, Azure Cosmos DB, and Microsoft Purview, and I use repeatable IP and execution frameworks to speed adoption.

Upgrade the skills in this repo so each one carries **architect-grade patterns, trade-offs, and best practices**, not only CLI how-tos. When I load a skill I should be able to run a customer design session, size and de-risk a PoC, and harden a production deployment.

## Repo context (verify, do not assume)

- Skills live under `skills/<platform>/<skill-name>/SKILL.md`, with a short router `SKILL.md` and detail in sibling `references/` files.
- Existing: `skills/fabric/*` (32 skills, including `microsoft-fabric`, `e2e-medallion-architecture`, `spark-*`, `sqldw-*`, `eventhouse-*`, `eventstream-*`, `semantic-model-*`, `fabriciq*`, `synapse-migration`, `pipeline-migration`), `skills/databricks/*` (45 skills, mostly platform-agnostic or AWS-flavored), `skills/foundry/*`.
- **No Cosmos DB skill and no Purview skill exist yet.** Cosmos DB and Purview need new skills. Azure-specific Databricks needs a new skill, or a clearly separated Azure layer on top of the existing ones.
- Read `scripts/validate_skills.py`, `scripts/skill_repo.py`, `scripts/build_catalog.py`, and `README.md` first. Follow the existing frontmatter rules (`name`, `description` only at top level), the router line cap, router-link checks, and the catalog build.
- Do not recreate removed legacy skills. Treat custom skills as local conventions. For Databricks platform facts, prefer the installed official `databricks:*` skills (load `databricks-core` first). Pass `--profile slysik-azure` explicitly for any live Databricks check, and never auto-select a profile.

## Step 0 – Plan before writing

Ask me for anything missing: the customer verticals I expect (for example FSI, retail, healthcare, manufacturing), whether I have an Azure subscription or Fabric trial available for live verification, and which of the four areas to do first. Then produce a short plan listing which skills you will create or modify, and wait for my OK. Check that my Azure, Fabric, and Databricks tokens or PATs are not expired before any live call.

## Step 1 – Gap audit

For each of the four areas, read the existing skill(s) and write a one-page gap audit in `_inbox/csa-gap-audit.md`. Cover:
- What exists, and what is missing versus the architect checklist below.
- Statements that look stale. Anything version-sensitive (GA vs preview, SKUs, limits, feature names, pricing model) must be checked against current Microsoft Learn docs (`learn.microsoft.com`) and the Databricks docs. Cite the URL and date checked. Mark anything you could not verify as `UNVERIFIED`. Do not guess.

## Step 2 – Content requirements per area

Every skill or reference file must be decision-oriented. For each topic include: **when to use it, when not to use it, the trade-offs, the anti-patterns, a reference architecture, and a short customer-facing talk track**. Keep each router `SKILL.md` within the line cap and push detail into `references/`.

### A. Microsoft Fabric (extend `microsoft-fabric` and related skills)
- Workload selection: Lakehouse vs Warehouse vs Eventhouse vs SQL database in Fabric, Direct Lake vs Import vs DirectQuery, and Fabric vs Azure Databricks vs Synapse. Include a decision matrix.
- Capacity: F-SKU sizing, smoothing and bursting, throttling, the Capacity Metrics app, workload isolation across capacities, pause/resume cost control, reservations.
- OneLake: shortcuts (ADLS, S3, GCS, Dataverse), mirroring (Azure SQL, Cosmos DB, Snowflake, open mirroring), Delta/Iceberg interop, OneLake security.
- Security: workspace roles vs item permissions, OneLake data access roles, row/column-level security, sensitivity labels, private links, managed private endpoints, trusted workspace access, customer-managed keys, outbound access protection, tenant settings.
- Resiliency and DR: region availability, OneLake DR and BCDR settings, failover runbook, RPO/RTO by workload.
- Governance and ALM: domains, endorsement, Git integration, deployment pipelines, CI/CD with `fab` CLI and REST, environments.
- AI-readiness: Fabric Data Agent, Copilot, Fabric IQ and ontology, AI Functions in notebooks, Azure OpenAI and Foundry integration, vector support in Eventhouse and SQL.
- Migration playbooks: Synapse, ADF, and HDInsight to Fabric, and Databricks-to-Fabric coexistence.
- Cost and FinOps: capacity chargeback, workspace-per-capacity patterns, anti-patterns that burn CUs.

### B. Azure Databricks (new Azure layer, for example `skills/databricks/azure-databricks-architecture/`)
- Azure-specific architecture: control plane vs compute plane, VNet injection, secure cluster connectivity (no public IP), Private Link (front-end and back-end), hub-and-spoke, NSGs, firewall egress, serverless network connectivity configurations.
- Identity: Microsoft Entra ID, SCIM and automatic identity management, service principals vs managed identities, Azure Key Vault-backed secret scopes, token hygiene.
- Storage: ADLS Gen2 with Unity Catalog, access connectors and managed identities, external locations, managed vs external tables, storage firewall.
- Unity Catalog on Azure: metastore-per-region design, catalog-per-environment, system tables, lineage, row filters and column masks, ABAC, Delta Sharing, Lakehouse Federation.
- Fabric interop: OneLake shortcuts to Databricks tables, mirroring Azure Databricks catalogs into Fabric, reading OneLake from Databricks, and a "Fabric vs Databricks vs both" decision guide with a reference architecture.
- Reliability and performance: Photon, serverless vs classic, cluster policies, autoscaling, Delta optimization (liquid clustering, predictive optimization), Lakeflow pipelines, job retries, repair runs, multi-region DR.
- AI: Mosaic AI Model Serving, Vector Search, Agent Bricks, Azure OpenAI and Foundry integration, MLflow, AI Gateway or Unity Gateway.
- Ops: DABs CI/CD with Azure DevOps and GitHub Actions, cost management and tagging, Azure Monitor and diagnostic logs.
- Cross-link to the existing `databricks-*` skills instead of duplicating them.

### C. Azure Cosmos DB (new skill, for example `skills/azure/azure-cosmos-db/`)
- Data modeling for NoSQL: embed vs reference, partition key selection (hot partition, cross-partition cost, hierarchical partition keys), item-size limits, denormalization, change feed patterns.
- Throughput: provisioned vs autoscale vs serverless, RU estimation and tuning, query cost analysis, indexing policy, burst capacity, throughput buckets.
- Global distribution and resiliency: multi-region writes, consistency levels with the trade-off of each, availability zones, service-managed failover, SLAs, conflict resolution, backup (continuous vs periodic) and point-in-time restore.
- Security: Entra ID RBAC with no keys (disable local auth), managed identity, private endpoints, firewall, customer-managed keys, Always Encrypted, Defender for Cosmos DB, audit via diagnostic logs.
- AI-readiness: integrated vector search (DiskANN), full-text and hybrid search, RAG and agent memory patterns, Semantic Cache, Foundry and LangChain integration, MCP.
- Analytics and integration: Fabric mirroring for Cosmos DB, change feed to Eventstream or Databricks, Azure Synapse Link status (verify whether it is deprecated or changed), Spark connector.
- API selection: NoSQL vs MongoDB vs PostgreSQL (Citus) vs Cassandra vs Gremlin vs Table, with a decision guide and migration paths. Include a note on DocumentDB if relevant.
- Operations: SDK best practices (retry, preferred regions, direct mode, bulk), monitoring, alerts on 429s and RU, IaC (Bicep/Terraform), and load-test method for a PoC.

### D. Microsoft Purview (new skill, for example `skills/azure/microsoft-purview/`)
- Product map: Unified Catalog (Data Map, data products, glossary, OKRs, critical data elements, data quality), plus compliance solutions (Information Protection, DLP, Insider Risk, Data Lifecycle Management, eDiscovery). Verify current naming, as Purview has been re-branded.
- Scanning and lineage: sources for Fabric, Azure Databricks (Unity Catalog), Cosmos DB, ADLS, Azure SQL, Snowflake, S3. Scan rule sets, classification, integration runtimes and managed VNet, lineage coverage and gaps.
- Governance operating model: governance domains, data owners and stewards, data product lifecycle, access policies, request workflow, quality rules and scores.
- Integration patterns: Purview with Fabric (sensitivity label inheritance, Fabric governance settings, DLP on Fabric), Purview with Databricks Unity Catalog, and Purview and Cosmos DB.
- AI governance: DSPM for AI, oversight of Copilot and Foundry apps, sensitivity labels feeding Copilot, data-leak guardrails for AI workloads.
- Security and compliance mapping: GDPR, HIPAA, PCI, SOC 2, data residency; RBAC roles, private endpoints, managed identity for scans.
- Automation: Purview REST/Atlas APIs, Python SDK, Terraform/Bicep, CI/CD of glossary and policies.
- Pricing model and the common sizing mistakes in a PoC.

## Step 3 – Cross-cutting architect content

Add one shared reference (for example `skills/azure/csa-playbook/`) that all four areas link to:
- **ADS facilitation guide**: discovery questions by persona (CDO, CISO, data engineering lead, app owner), a requirements-to-architecture mapping template, and a decision-log template.
- **PoC execution framework**: success criteria, scope guardrails, a 2–4 week plan template, test data strategy, cost caps, exit criteria, and a readiness-to-production checklist.
- **Well-Architected review checklists** for data workloads (reliability, security, cost, operational excellence, performance), with a scoring rubric.
- **Reference architectures** as Mermaid diagrams: modern data estate (Fabric + Databricks + Cosmos DB + Purview), real-time/IoT, RAG/agentic AI over operational + analytical data, multi-region DR, and a regulated-industry landing zone. Use the existing `diagram-kit` conventions if suitable.
- **Mission-critical patterns**: RPO/RTO tiers, active-active vs active-passive, chaos and failover testing, SLO and error-budget thinking, runbooks.
- **Cost and business value**: TCO comparison method, value-driver mapping to KPIs, and a one-page executive summary template.
- **Anti-pattern catalog** and "common customer objections" with crisp answers.
- **Interview prep appendix**: 25 likely scenario questions with concise model answers and the trade-off to name out loud.

## Step 4 – Quality bar and verification

- Every factual claim about product behavior, limits, SKUs, or GA/preview status must trace to a doc link you actually opened. Put the check date in the file (`Last verified: YYYY-MM-DD`). Mark preview features clearly. If you cannot verify, say so.
- Prefer small, runnable examples (CLI, REST, Bicep, SQL, PySpark) that I can test. Run any command you can safely run. Do not run anything that creates paid resources, changes tenant settings, or deletes data without asking me first.
- No secrets, keys, tenant IDs, or subscription IDs in any file. Flag any you find in the repo immediately.
- Keep the router `SKILL.md` files short, with trigger-rich `description` frontmatter (USE FOR / DO NOT USE FOR), and put depth in `references/`.
- Do not duplicate content that exists in another skill. Link to it.

## Step 5 – Definition of done

1. Run `python3 scripts/validate_skills.py` and the catalog build, and fix all errors and warnings. Show me the output.
2. Run `jev diff` and report the risk score.
3. Re-check the result against this prompt, area by area, and give me a table: requirement, status (done, partial, missing, unverified), and file path. Do not claim completion beyond what the table shows.
4. List open items and `UNVERIFIED` claims that I should check against a live environment.
5. Do not commit or push. Show me the diff summary and wait for my go-ahead.

## Working style

Work one area at a time, in this order: Cosmos DB, Purview, Azure Databricks, Fabric, then the shared playbook. Use subagents for parallel doc research only. Keep one writer per set of files. After each area, stop and summarize what changed and what is unverified, then ask whether to continue.
