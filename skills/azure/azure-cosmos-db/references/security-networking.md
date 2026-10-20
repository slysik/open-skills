# Cosmos DB: security and networking

Last verified: 2026-10-19. Source: Microsoft Learn `azure/cosmos-db/` pages: `nosql/security/how-to-grant-data-plane-role-based-access` (2026-10-15), `reference-data-plane-security` (2026-04-27), `how-to-setup-managed-identity` (2026-04-27), `how-to-configure-private-endpoints` (2026-04-27), `how-to-configure-firewall` (2026-07-27), `database-encryption-at-rest` (2026-04-27), `how-to-setup-customer-managed-keys` (2026-04-29), `how-to-always-encrypted` (2026-04-27), `defender-for-cosmos-db` (2026-04-27), `monitor-resource-logs` (2026-04-27), Azure security baseline (2026-04-01), WAF service guide (2026-07-30). Not fetched: the security overview, VNet service endpoint page, Defender enablement page, CMK-on-existing-accounts page. Role definition IDs below are public built-in constants, not tenant identifiers.

## 1. Identity: go Entra-only
**Enforce**: set `properties.disableLocalAuth=true` on `Microsoft.DocumentDB/databaseAccounts` (needs `Microsoft.DocumentDb/databaseAccounts/*/write`). Validate by confirming a key/connection-string client now fails.

```bash
az resource update --resource-group <rg> --name <account> \
  --resource-type "Microsoft.DocumentDB/databaseAccounts" \
  --set properties.disableLocalAuth=true
```

Bicep: `disableLocalAuth: true` (API `2024-05-15`). The Azure Policy "Cosmos DB database accounts should have local authentication methods disabled" supports Audit/Deny.

**Two RBAC planes**
| Plane | Covers | Mechanism |
|---|---|---|
| Control plane | Account metadata, keys, backup/restore, databases and containers, account properties | Azure RBAC, actions `Microsoft.DocumentDB/*`. The built-in *Cosmos DB Operator* role excludes data access, keys, connection strings and `sqlRoleDefinitions/sqlRoleAssignments` write/delete |
| Data plane | Reads/writes of items and queries | Cosmos DB native RBAC (`sqlRoleDefinitions`, `sqlRoleAssignments`) using `dataActions`. `notDataActions` is **not** supported |

Built-in data-plane roles: **Data Reader** `00000000-0000-0000-0000-000000000001` (`readMetadata`, `items/read`, `executeQuery`, `readChangeFeed`) and **Data Contributor** `00000000-0000-0000-0000-000000000002` (`readMetadata`, `containers/*`, `containers/items/*`). SDKs need `readMetadata`; SDK queries need `executeQuery` and `readChangeFeed`. Scope can be account, database or container. Creating data-plane role definitions and assignments needs control-plane permissions.

```bash
az cosmosdb sql role assignment create -a <account> -g <rg> \
  --role-definition-id 00000000-0000-0000-0000-000000000002 \
  --principal-id <object-id> --scope "/"
```

The CLI flags came from a tool-extracted summary; verify with `az cosmosdb sql role assignment create --help`. The security baseline says Entra data-plane auth is supported only on the Core (SQL) API; that wording may be stale, so other APIs are `UNVERIFIED`. A data action `items/unmask` ("bypass Dynamic Data Masking") appears in the reference; the masking feature itself is `UNVERIFIED`.

**Account managed identity** (used for CMK, not the application's identity): `az cosmosdb identity assign -n <acct> -g <rg>` (system-assigned) or add `--identities <resource-id>` (user-assigned); needs ARM API `2021-03-15`+ and the DocumentDB Account Contributor role.

## 2. Network controls
| Control | Facts |
|---|---|
| Private endpoint group IDs | NoSQL `Sql` (zone `privatelink.documents.azure.com`), NoSQL dedicated gateway `SqlDedicated` (`privatelink.sqlx.cosmos.azure.com`), Cassandra, MongoDB, Gremlin, Table each have their own group ID and zone; one endpoint per group ID used; Gremlin and Table accounts can also use `Sql` |
| Private endpoint behaviour | One IP for the global endpoint plus one per region; use a DNS zone group so regions added later update DNS (otherwise stale DNS causes outages); direct mode needs TCP ports 0-65535; limit 200 private endpoints per account; a rejected connection cannot be re-approved; **adding a PE to an existing account can cause about 5 minutes of downtime** unless you first add IP/VNet rules, wait 10 minutes, add the endpoint, then remove the rules |
| Disable public access | `publicNetworkAccess=Disabled` overrides all IP and VNet rules (and the "Azure datacenters" option); set at creation to avoid an open window; if all approved PEs are deleted without it, the account opens to all networks |
| IP firewall | Default open (token still required); blocked sources get 403; rules via `ipRules`; changes take up to 15 minutes; private IPs in the list fail the update; **"Accept connections from within Azure datacenters" adds 0.0.0.0 and admits all Azure customers' traffic**; changing public access in the portal removes earlier IP rules; service-endpoint subnets send VNet identity so IP rules reject them (use VNet ACLs); NSGs are not supported for the service (baseline) |

## 3. Encryption
- **At rest**: AES-256, always on, service-managed keys, covers databases, attachments and backups. TLS 1.2+ enforced.
- **Customer-managed keys** (second layer, per account): key in Key Vault with **soft delete and purge protection**; vault must be reachable via public access or the "trusted Microsoft services" bypass (a vault reachable only by private endpoint is **not** usable); permissions via access policy (Get, Wrap Key, Unwrap Key) or RBAC (*Key Vault Crypto Service Encryption User*); set at creation with `--key-uri` (versionless) and explicit locations; RSA 3072+ recommended; identity can be first-party, system- or user-assigned (`defaultIdentity`); **continuous backup accounts need a managed identity (user-assigned at creation) and do not support the first-party identity**. Rotation: new key version or swap URI; keep the old version enabled until Key Vault logs show no Cosmos activity (about 24 hours). **If the key is revoked, the only possible operation is account deletion.** Overhead: point reads about +5%, writes +6%, queries and change feed +15%. Not encrypted by CMK: account/database/container names, stored procedure names, indexing-policy paths, partition key values. Synapse Link and continuous backup data are not double-encrypted.
- **Always Encrypted** (client-side): GA status not stated: `UNVERIFIED`. SDKs .NET (`Microsoft.Azure.Cosmos.Encryption`), Java (`azure-cosmos-encryption`), JS/TS; no Python or Go. Encryption policy top-level paths only, immutable, set at container creation; deterministic or randomized (`AEAD_AES_256_CBC_HMAC_SHA256`); query filtering equality only on deterministic properties; limit 20 client encryption keys; rotating a key or adding encrypted properties needs migration to a new container.

## 4. Threat protection and audit
- **Defender for Azure Cosmos DB**: NoSQL only; alerts for potential SQL injection, anomalous access (TOR, bad IPs, unusual apps/locations) and suspicious activity (key-listing patterns, data extraction); not in government/sovereign clouds; alerts in Defender for Cloud and by email to subscription admins.
- **Diagnostic logs** (off by default): `DataPlaneRequests` (logs 403s and source IPs), `ControlPlaneRequests` (IAM assignments and firewall/VNet/private-link changes), `QueryRuntimeStatistics`, `PartitionKeyRUConsumption`, `PartitionKeyStatistics`, plus billable aggregates and per-API logs. Use resource-specific destination tables (`logAnalyticsDestinationType: Dedicated`). Full-text query logging is off (queries obfuscated) and costs extra. Delete diagnostic settings before deleting or moving the resource.
- Baseline gaps: **Customer Lockbox and Azure Backup are not supported**.

## 5. Hardening checklist (regulated customer)
- [ ] `disableLocalAuth=true`, data-plane RBAC via groups, least-privilege scopes
- [ ] `publicNetworkAccess=Disabled` at creation; private endpoints per group ID; DNS zone group
- [ ] CMK decision made with vault network, purge protection and revocation runbook understood
- [ ] Defender enabled (NoSQL); diagnostic logs to Log Analytics; alerts on 429s, control-plane changes
- [ ] Azure Policy: at least 2 regions, zone redundancy, local auth disabled, public access disabled
- [ ] Backup mode continuous with a restore drill (restore does not bring back RBAC, firewall, PE)
- [ ] Exceptions listed (for example Purview scans that need the account key; Fabric mirroring with private endpoints needs a VNet data gateway)

## 6. Anti-patterns
- Disabling local auth after apps already use keys, without a cutover plan.
- Enabling "Accept connections from within Azure datacenters" as a shortcut.
- Adding a private endpoint to a live account without the IP-rule dance.
- CMK with a private-only Key Vault.
- Assuming CMK covers partition key values or container names.

## 7. Talk track
"We remove keys entirely: Entra for data-plane access, private endpoints, public access off from day one. The exceptions are written down, because a few integrations still want a key or a gateway, and a security exception you can name is better than one you discover."
