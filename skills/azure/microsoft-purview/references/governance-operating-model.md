# Purview: governance operating model, data quality and roles

Last verified: 2026-10-20. Source: Microsoft Learn `unified-catalog-governance-domains` (2025-11-18), `unified-catalog-data-products` (2025-11-18), `unified-catalog-glossary-terms` (2026-04-24), OKRs page (2025-11-18, title says preview), critical data elements (2026-09-05, Preview), `unified-catalog-data-health-management` (2025-11-18), data quality overview/rules/scores (2026-03 to 2026-09), `data-governance-roles-permissions` (2026-06-01), `unified-catalog-data-product-access-policies` (2025-11-19). `purview/data-products` returned 404; the canonical page is `unified-catalog-data-products`.

## 1. Building blocks
| Concept | What it is | Notes |
|---|---|---|
| **Governance domain** | Container for governed assets, e.g. functional unit, line of business, data domain, regulatory, project | Holds data products, glossary terms, OKRs and critical data elements (Preview). Glossary terms can carry policies that apply to products in the domain |
| **Data product** | Group of data assets (tables, files, Power BI reports) | Owned by one governance domain, discoverable across many; each has an access policy |
| **Glossary term** | Business definition; can carry policies (access, health goals, terms of use) | Migrating the classic glossary is Preview |
| **Critical data element (CDE)** | Business-critical field mapped to columns across sources | Preview. Draft, Published, Expired; name up to 256 chars, description up to 10,000; bulk CSV import (Preview) up to 1,000 rows |
| **OKR** | Objectives and key results for governance goals | Preview. Progress: on track, behind, at risk |
| **Health management** | Controls, data quality, actions (Preview), reports | Controls run daily at the Basic SKU |

## 2. Operating model (recommended sequence)
1. Name 3 to 5 governance domains aligned to how the business is organized, with **at least two domain owners each** (Learn tip).
2. Define 10 to 20 glossary terms and 3 to 5 CDEs that matter to the first use case.
3. Scan the sources behind 2 to 3 data products (see scanning reference); group assets into data products; publish.
4. Attach access policies and set data quality rules; track scores per product.
5. Review health reports monthly; retire what nobody uses.

## 3. Data product access policies
Settings: usage purposes (three by default), manager approval, privacy and compliance review, approvers (users or groups), optional access-provider tier, attestations, terms of use; policies inherit from domains, glossary terms and CDEs; statuses Pending, Declined, Approved, Completed. **Approvers provision access to the underlying assets manually; the product does not enforce policies such as attestations.** A "Disable Access Management" option exists; a product must be unpublished to edit policies. Tell customers this is a request-and-approve workflow, not automatic entitlement.

## 4. Data quality
- Lifecycle: assign a data quality steward; register and scan the source in the Data Map; add the asset to a data product; set up the connection; profile; create rules; run the scan; review scores; alerts and actions.
- **Auth: data quality scans run with Managed Identity only.** Runtime Apache Spark 3.5 and Delta Lake 3.2.1. **The data source and the Purview account must be in the same Azure region.**
- Concurrent job limits: manual scans 10, scheduled scans 25, manual profile 10, rule suggestion 10. **Maximum 200 active rules per asset; the scan fails above that.**
- Out-of-box rules: Freshness, Unique values, String format match, Data type match, Duplicate rows, Empty/blank fields, Table lookup, Custom (ADF expression, regex or Spark SQL; no joins or DML/DCL). Freshness is not supported for Snowflake, Databricks Unity Catalog, BigQuery, Synapse or Azure SQL. AI-generated suggestions via "Suggest rules".
- Scores: rule score = passed / (passed + failed + miscast + empty) x 100; asset score = average of rule scores; product = average of asset scores; domain = average of product scores. Asset trend shows the last 50 runs.
- Supported sources for data quality: `UNVERIFIED` (page not retrieved). Check before promising DQ on a specific source.
- Billing: DGPU based (see product-map-billing).

## 5. Roles
| Level | Roles |
|---|---|
| Tenant role groups | Purview Administrators, Data Source Administrators, Data Governance |
| Catalog level | Data Governance Administrator, Data Health Owner, Data Health Reader, Global Asset Curator, Global Catalog Reader, Governance Domain Creator, Local Catalog Reader |
| Governance domain | Governance Domain Owner, Governance Domain Reader, Data Product Owner, Data Steward, Data Quality Steward, Data Quality Reader, Data Quality Metadata Reader, Data Profile Steward, Data Profile Reader |

Data Product Owner and Data Steward also need Data Map read on the assets. Unified Catalog permissions layer on top of Data Map permissions. Entra roles map to Purview role groups (for example Global Administrator maps to Data Catalog Curators, Data Estate Insights Readers, Organization Management, Purview Administrators); an Entra role overrides a scoped administrative-unit assignment. Use PIM for Groups for just-in-time access; direct user assignments cannot be JIT-managed.

## 6. Where Purview and Fabric governance meet
Fabric's native governance lives in the OneLake catalog Govern area; Purview adds protection, audit, risk and compliance and does not move governance out of Fabric. See [fabric-ai-compliance.md](fabric-ai-compliance.md) and the Fabric security-governance reference.

## 7. Anti-patterns
- Governance by tool rollout with no domain owners.
- Hundreds of glossary terms nobody owns.
- Treating access policies as enforcement.
- Exceeding 200 rules on an asset or running DQ across regions.
- Scoring "data quality" with only completeness rules.

## 8. Talk track
"Start with who owns a domain and what three terms and elements matter. Then show a data product with a quality score the business agrees with. Access requests are an approval workflow; actual permissions still come from the platform."
