---
name: microsoft-purview
description: "Microsoft Purview architecture for data governance, data security and compliance on Azure data platforms: product map (Unified Catalog, Data Map, governance domains, data products, glossary, OKRs, critical data elements, data quality, health management), compliance solutions (Information Protection, DLP, Insider Risk, Data Lifecycle Management, eDiscovery, Audit, Compliance Manager), scanning and lineage for Fabric, Azure Databricks Unity Catalog, Cosmos DB, ADLS Gen2, Azure SQL, Snowflake and S3, integration runtimes and private networking, governance operating model and roles, billing meters (governed assets, DGPU, Data Map capacity units), DSPM for AI, Copilot/Foundry governance, and Fabric integration. USE FOR: Purview design session, scan a source, managed VNet IR, private endpoint, data quality rules and scores, governance domain design, DSPM for AI, Purview vs Fabric governance, Purview PoC sizing, regulated data catalog. DO NOT USE FOR: Fabric-native OneLake catalog/security CLI work (use microsoft-fabric), Unity Catalog grants (use databricks-unity-catalog), or provisioning Purview accounts."
---

# Microsoft Purview (decision layer)

Purview has been renamed and reorganized repeatedly. Facts here come from Microsoft Learn pages fetched on 2026-10-20; every reference carries `Last verified`, and items the pages did not state are `UNVERIFIED`. Re-check the portal naming and billing before quoting to a customer.

## Pick a reference

| Need | Open |
|---|---|
| What Purview is today, renames, solution areas, billing meters, free vs enterprise | [references/product-map-billing.md](references/product-map-billing.md) |
| Scan a source, auth per source, integration runtimes, private endpoints, lineage coverage, limits | [references/scanning-lineage-networking.md](references/scanning-lineage-networking.md) |
| Governance domains, data products, glossary, CDEs, OKRs, data quality, access policies, roles | [references/governance-operating-model.md](references/governance-operating-model.md) |
| Fabric integration, DLP/labels, DSPM for AI, Copilot/Foundry governance, Compliance Manager, RBAC, automation gaps | [references/fabric-ai-compliance.md](references/fabric-ai-compliance.md) |
| Running the session, PoC or review | [../csa-playbook/SKILL.md](../csa-playbook/SKILL.md) |

## Pair with other skills
- Fabric-native governance (OneLake catalog Govern, domains, labels): `microsoft-fabric` and its `references/architect/security-governance.md` ([link](../../fabric/microsoft-fabric/references/architect/security-governance.md)).
- Unity Catalog access control and lineage system tables: [azure-databricks-architecture](../../databricks/azure-databricks-architecture/SKILL.md).
- Upstream `microsoft/skills-for-fabric` has an `onelake-catalog-govern-cli` skill (admin and data-owner governance audit, labels, tags, domains) that is not installed in this repo.

## Decide first
1. Which problem: **catalog and quality** (Unified Catalog / Data Map) or **protect and comply** (Information Protection, DLP, Insider Risk, Audit)? They have different licences, roles and billing.
2. Where does Fabric-native governance stop and Purview begin? Fabric governs inside Fabric; Purview adds protection, audit, risk and compliance and the cross-estate catalog.
3. Private networking requirement for scans (decides integration runtime type).
4. Who are the governance domain owners (at least two per domain) before any tooling.

## Talk track
"Purview is two things people conflate: a data catalog with quality and a compliance and security suite. We start with the business domains and owners, scan only the sources that feed governed data products, and use sensitivity labels and DLP where data leaves the platform. The tooling is the easy part; owners and definitions are the project."
