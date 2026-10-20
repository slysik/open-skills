# Azure Databricks: identity, Unity Catalog and storage

Last verified: 2026-10-19. Source: Microsoft Learn `azure/databricks/...` pages: `admin/users-groups/automatic-identity-management` (2026-10-15), `admin/users-groups/scim/` (2026-09-16), `admin/users-groups/service-principals` (2026-10-12), `dev-tools/auth/` (2026-10-12), `admin/access-control/tokens` (2026-10-09), `security/secrets/` (2026-09-11), `data-governance/unity-catalog/best-practices` (2026-09-11), `connect/unity-catalog/cloud-storage/*` (2026-09-11 to 2026-10-14), `data-governance/unity-catalog/filters-and-masks` (2026-10-09), `abac/` (2026-09-29), `admin/system-tables/` (2026-10-16), `opensharing/` (2026-10-12), `query-federation/` (2026-09-29). Learn now calls Delta Sharing "OpenSharing". Use the `databricks-unity-catalog` skill for SQL/CLI how-tos; this file is the decision layer.

## 1. Identity
| Decision | Guidance |
|---|---|
| Entra sync method | **Automatic identity management (AIM)** is recommended (on by default for accounts created after 2025-08-01). Only AIM syncs nested groups and Entra service principals; SCIM syncs direct members only. Needs identity-federated workspaces |
| SCIM | Account-level SCIM is recommended; workspace-level SCIM is legacy and Public Preview. Limits: 10,000 users+service principals and 5,000 groups per account and per workspace. Premium + account admin |
| Mixing AIM and SCIM | Duplicates identities. Fix by setting `externalId` to the Entra objectId |
| Cross-tenant | AIM does not support cross-tenant directories; use SCIM with B2B |
| Service principals | Databricks-managed for Databricks-only automation; Entra-managed when you also need other Azure resources. Creator becomes manager but still needs the "service principal user" role to run jobs as it |
| Auth method order (Learn) | OAuth token federation (recommended), OAuth M2M for unattended/CI-CD, OAuth U2M for users, OAuth OBO (Beta), Azure managed identity (Azure resources only), Entra service principal |
| PATs | Legacy. Default max lifetime 730 days; recommend under 90 via `maxTokenLifetimeDays` (applies to new tokens only); unused 90+ days auto-revoked; expiry emails about 7 days before. **No expiry notifications for OAuth secrets**, track them yourself. Deleted Entra users are deactivated but their PATs are **not** auto-revoked |

AIM gotchas: Entra-synced groups are created at account level but must be assigned to workspaces manually; service principals provision on first use; group renames do not sync until an admin opens the group page; disabling AIM leaves groups but removes all members; nested groups not directly provisioned are invisible to the API and Terraform; membership refresh timing depends on activity (browser login refreshes if last sync over 5 min).

### Key Vault-backed secret scopes
Read-only interface; supports only the **Vault access policy** permission model (Azure RBAC not supported). Creating a scope needs Key Vault Contributor/Contributor/Owner. Vault firewall: "selected networks" plus "Allow trusted Microsoft services", or all networks. Scope ACLs are scope-wide, so use a separate vault per access boundary.

## 2. Unity Catalog on Azure (design rules from Learn best practices)
- **One metastore per region.** Catalog is the primary isolation unit; prefer catalog-level managed storage (metastore-level storage is no longer required; new UC workspaces are created without it and get an auto-created workspace catalog).
- Bind a catalog to workspaces only when environment and data isolation needs match. Grants to groups; production MODIFY to service principals only.
- Never register the same external table in two metastores. Use a dedicated container for managed storage (never reuse the DBFS root container).
- ADLS handles 20,000 requests/s per account and extra containers do not help; stripe across storage accounts for scale.
- Managed tables preferred (auto-compaction, metadata caching). External tables for HMS upgrades, non-Delta formats, outside readers or DR needs.
- One external location per schema; never create tables or volumes at the root of an external location; do not grant READ FILES/WRITE FILES broadly (use volumes); do not mount DBFS on external-location storage; enable file events.
- Cross-region: Databricks-to-Databricks OpenSharing; lineage and ACLs do not cross metastores.
- Managed location resolution: schema, then catalog, then metastore. `MANAGED LOCATION` string max 512 chars; `ALTER ... SET MANAGED LOCATION` needs DBR 18.1+ and affects only new objects.

### Catalog-per-environment pattern
`prod_<domain>`, `test_<domain>`, `dev_<domain>` catalogs, each with its own managed location in its own container, bound to the matching workspaces; promotion through bundles (see reliability-ai-ops reference).

## 3. Storage access on Azure
1. Create an **Access Connector** (Contributor/Owner on the resource group); system-assigned or user-assigned managed identity.
2. Grant it **Storage Blob Data Contributor** on the account or a container (with Storage Blob Delegator at account level for container scope). Grantor needs Owner or User Access Administrator.
3. Keep connector, workspace, metastore and storage in the same region.
4. File events need Storage Queue Data Contributor, Storage Account Contributor and EventGrid EventSubscription Contributor (or EventGrid Data Contributor); otherwise configure manually.
5. External locations need hierarchical namespace, no immutability (WORM) containers, ASCII-only paths; with public access disabled "Allow Azure trusted services" is needed. `CREATE EXTERNAL LOCATION` is required on both the metastore and the credential.
6. Firewalled account on a VNet-injected workspace: add the connector as a Resource instance (`Microsoft.Databricks/accessConnectors`) and clear the trusted-services exception. Serverless needs its own setup (see networking-security).

Managed identity works with firewalled storage; a service principal credential cannot pass network rules.

## 4. Fine-grained access: filters, masks, ABAC
- Table-level row filters and column masks are GA; **ABAC is recommended**. Limits: not on views; DBR 12.2 LTS+; no time travel, deep/shallow clones, or path-based access with table-level filters/masks; **tables with filters/masks cannot be shared via OpenSharing**; dedicated compute needs DBR 15.4+ plus serverless for fine-grained control (writes DBR 16.3+); set ANSI mode on or a type mismatch silently becomes NULL and can return all rows; one distinct filter and mask per column per user.
- ABAC: row filter and column mask policies show no preview tag (GA label not explicit); Beta: metastore-level policies, DENY policies, ABAC on views (DBR 19+, max 20 layered policies), time travel with ABAC. Compute: serverless, or standard/dedicated DBR 16.4+. Quotas: 10,000 policies per metastore; 100 per catalog; 100 per schema; 50 per table; 20 principals per policy; 6 (filter) / 3 (mask) MATCH COLUMNS conditions.
- Gotchas: policies use **governed tags** (changes take a few minutes); pipeline owners/run-as identities of materialized views and streaming tables must be in EXCEPT or masked data is persisted; clones need an EXCEPT principal; AI Search indexes ignore policies; conflicting policies error.
- Note the interop consequence: UC masks/filters do not apply to data read through OneLake paths by other engines (see Fabric `databricks-coexistence.md`).

## 5. System tables
`system.billing.usage` and `list_prices` (GA, 365 days; list_prices indefinite); `system.access.audit` (Public Preview, 365 days); `system.access.table_lineage` / `column_lineage` (365 days, no preview tag); preview tables include `inbound_network` (30 days), `outbound_network`, `workspaces_latest`; `node_timeline` 90 days. Configurable retention (Beta) 30 to 3,650 days. Free to query (you pay the compute). Grant USE CATALOG on `system`, USE SCHEMA and SELECT on the schemas. Streaming reads need DBR 16.4+ and `skipChangeCommits=true`. `system.lineage` and `system.operational_data` are deprecated and empty.

## 6. Sharing and federation
- **OpenSharing** (formerly Delta Sharing): Databricks-to-Databricks (no tokens; notebooks, volumes, models, metric views) or Open (bearer token or OIDC federation; tabular only). Cannot share: tables with row filters/masks (ABAC tables ok if the share owner is in EXCEPT), liquid clustering with partition filtering, collations, SHALLOW CLONE tables, tables on OneLake. Cross-region egress charges apply.
- **Lakehouse Federation**: query federation (JDBC pushdown to MySQL, PostgreSQL, Teradata, Oracle, Redshift, Salesforce Data 360, Snowflake, SQL Server, Synapse, BigQuery, Databricks) and catalog federation (direct object-store access on Databricks compute: HMS, Snowflake, Palantir Foundry, Workday, OneLake). Both read-only. Use Lakeflow Connect for high volume, low latency. Per-connector limits `UNVERIFIED`.
- Azure Policy and Microsoft Defender coverage for Databricks: `UNVERIFIED`, not researched.

## 7. Anti-patterns
- Granting ADLS access with account keys or SAS instead of access connector + managed identity.
- One shared Key Vault scope for every team.
- AIM and SCIM both enabled.
- Workspace-local groups for entitlements that should be account groups.
- Production tables writable by humans.
- Treating row filters as portable: they block sharing and are bypassed by non-UC readers of the same files.

## 8. Talk track
"Identity flows from Entra through AIM to account groups; permissions are granted to groups in Unity Catalog; storage is reached only through an access connector's managed identity. That gives one place to answer who can read what, and it removes keys from the picture."
