# Fabric architect: security and governance

Last verified: 2026-10-19 (Learn: `security/permission-model`, `fundamentals/roles-workspaces` 2026-04-24, `onelake/security/get-started-security` 2026-09-01, `onelake/security/sql-analytics-endpoint-onelake-security` 2026-07-22, `governance/information-protection` 2026-07-13, `security/security-private-links-overview` 2026-10-13, `security/security-trusted-workspace-access` 2026-08-13, `security/workspace-outbound-access-protection-overview` 2026-02-09, `security/workspace-customer-managed-keys` 2025-10-15, `admin/tenant-settings-index` 2026-08-28).

## 1. Layered model (design in this order)
1. **Identity**: Entra authentication, Conditional Access (one common policy covering Power BI Service, Azure Data Explorer, Azure SQL Database, Azure Storage, Cosmos DB; an over-strict policy breaks dataflows; CAE unsupported). Assign roles to security groups.
2. **Fabric access**: workspace roles and item permissions.
3. **Data security**: OneLake security roles, or engine-native security.
4. **Network**: private links, managed private endpoints, trusted workspace access, outbound access protection.
5. **Encryption**: Microsoft-managed keys, optional workspace CMK.
6. **Governance**: sensitivity labels, domains, endorsement, audit.

A user needs access at every layer.

## 2. Workspace roles (what they really grant)
| Role | Key capabilities | Gotcha |
|---|---|---|
| Admin | Everything incl. delete workspace, add admins, workspace identity, connect Git | Admin/Member/Contributor bypass OneLake security roles (except RLS in user-identity mode) |
| Member | Add members/lower roles, reshare | Same data bypass |
| Contributor | Create/modify items, ReadAll via OneLake APIs/Spark | Same data bypass |
| Viewer | SQL endpoint read (ReadData), view output | **No ReadAll**: no OneLake or Spark access unless OneLake security grants it |

Item permissions: Read (metadata only), ReadData (SQL data, delegated mode), ReadAll (OneLake data via DefaultReader role), Write. Sharing grants Read by default. Removing an item permission does not remove workspace-role access. Highest role wins across groups.

## 3. Data-plane security: pick one model per consumption path
| Control | Applies to | Notes |
|---|---|---|
| **OneLake security** (roles; grant only; folder, table, row, column) | Lakehouse, Spark, Graph, Direct Lake on OneLake, SQL endpoint in *user's identity mode* (all GA per page); Eventhouse RLS and third-party engines are PREVIEW | No deny roles. Dynamic Data Masking not supported. RLS: single expression per table, no dynamic/multi-table. Renaming/dropping a policy column breaks sync |
| **SQL-native** (GRANT, RLS via `CREATE SECURITY POLICY`, CLS, Dynamic Data Masking) | Warehouse and SQL endpoint in delegated mode | Filter predicates only, no block predicates. Direct Lake falls back to DirectQuery. Admin/Member/Contributor see unmasked data. DDM is not protection against inference |
| **Semantic model** RLS/OLS | That model only | Compute-level security applies only to that engine |

Critical traps:
- New SQL endpoints default to **delegated identity mode**, where OneLake roles do not apply. Switching to user's-identity mode (Admin/Member, once per endpoint) briefly takes all endpoints in the workspace offline, cancels running queries, **irrecoverably deletes existing SQL roles**, ignores SQL RLS/CLS and removes inline functions. Plan it as a change window.
- In user-identity mode SQL `GRANT` on tables is ignored; views, procedures and functions can still use it.
- Warehouse SQL RLS/CLS is **not** translated to OneLake policies: a user reading through a shortcut can see the full warehouse data.
- Shortcut with OneLake security: producer role identities must map 1:1 to consumer Fabric Read grants; nested groups are not resolved across the boundary.
- OneLake security sync to the SQL endpoint takes up to 5 minutes.

## 4. Network controls
| Control | Direction | Requirements and limits |
|---|---|---|
| Tenant private link + Block Public Internet Access | Inbound, whole tenant | Not for trial. Breaks: on-prem data gateway registration (VNet data gateway works), starter Spark pools, Copilot, Capacity Metrics app, cross-tenant shortcuts. Takes up to 24 h for a new capacity |
| Workspace private link | Inbound, selected workspaces | Single-tenant only |
| Managed private endpoints | Outbound from Spark (notebooks, lakehouses, SJDs); Eventstream PREVIEW | Workspace admin creates. No ADLS/Blob shortcut over MPE yet |
| Trusted workspace access | Outbound to firewalled ADLS Gen2 | GA, **F SKU only**. Needs workspace identity plus resource instance rule (ARM/PowerShell, max 200, not portal). Works for shortcuts, pipelines, import semantic models, COPY, AzCopy. **Not Spark** (use MPE). Not cross-tenant. A workload-identity Conditional Access policy covering all service principals breaks it |
| Workspace outbound access protection | Outbound, default deny + allow list | Not trial. Cannot enable if the workspace has unsupported items. Incompatible with external data sharing. General GA tag not stated: `UNVERIFIED` |

Private link is inbound only; it does not secure outbound traffic to data sources.

## 5. Encryption
- Default: Microsoft-managed keys.
- **Workspace CMK**: all F SKUs, not trial. Tenant setting "Apply customer-managed keys", Key Vault with soft-delete and purge protection, versionless RSA key (2048/3072/4096), Fabric checks daily for a new version, revocation blocks access in about 60 minutes. Eventhouse support is preview. **Not covered by CMK**: Spark shuffle/temp data, environment libraries, pipeline and ML metadata, Warehouse caches. Cannot enable if the workspace holds unsupported items.

## 6. Sensitivity labels
- Need Purview Information Protection licence, labels defined *and published*, tenant setting on, and Pro/PPU for Power BI items.
- Mandatory labeling is fully supported for Power BI items only, not enforced for lakehouse, pipeline or warehouse.
- Inheritance: Power BI to Power BI, Fabric to Fabric, Fabric to Power BI. **Not** Power BI to Fabric.
- Label-based access control is enforced only in the home tenant, in .pbix files and supported exports (Excel, PDF, PowerPoint); not for cross-tenant sharing or CSV/TXT export. Encryption and marking are not applied inside Fabric, only to exports.
- Information Protection does not support Private Link.

## 7. Tenant settings to review first
Publish to web; external data sharing and accepting external shares; guest access and inviting guests; shareable links to everyone; export formats; who can create workspaces; service principal API access; Azure Private Links and Block Public Internet Access; Apply customer-managed keys; OneLake access from apps outside Fabric and short-lived user-delegated SAS; cross-region processing for Azure OpenAI/AI. Defaults are mostly `UNVERIFIED`; always read the live admin portal (now also under OneLake catalog, Govern, Configurations).

## 8. Governance and audit
- Domains group data by business area and can receive delegated tenant settings. Endorsement: promoted, certified, master data (delegate certification to domain admins).
- Purview DLP, Information Protection and Audit need extra Purview licensing. Compliance listed: HIPAA BAA, ISO/IEC 27001, 27017, 27018, 27701.
- Audit log covers control-plane events (7-day default search, Exchange Online "Audit Logs" role). **OneLake data-plane access needs OneLake diagnostics.** CMK operations are logged. Retention: `UNVERIFIED`.

## 9. Regulated-industry starter (FSI, healthcare)
Tenant Block Public Internet Access + private link; per-environment capacities; workspace identity + trusted workspace access for ADLS; MPE for Spark; outbound access protection on prod workspaces; workspace CMK; OneLake security roles in user-identity mode; labels with Purview DLP; OneLake diagnostics to a locked workspace; no trial or Copilot in scope until cross-geo AI settings are reviewed.

## 10. Anti-patterns
- Everyone is Contributor "so it works" (bypasses OneLake security).
- Row security defined in three places (OneLake roles, SQL RLS, model RLS) with no owner.
- Assuming sensitivity labels block CSV export.
- Flipping the SQL endpoint identity mode in prod mid-day.
- Enabling private link then discovering the on-prem gateway cannot register.

## 11. Talk track
"We secure Fabric in layers: identity, workspace role, data security, network, keys, governance. The one decision people miss is where row and column security lives. We pick OneLake security for everything that crosses engines, and keep SQL-native only for Warehouse-only consumers, so a shortcut never exposes more than the source allowed."
