# CSA interview prep: 25 scenario questions

Last verified: 2026-10-19. Every product number below was stated on a Microsoft Learn page fetched that day (Fabric, Cosmos DB and Azure Databricks research). `UNVERIFIED` items are flagged. Format: question, concise model answer, and the trade-off to name out loud.

## Platform choice
**1. A retailer has Databricks and Power BI. Do they need Fabric?**
Not necessarily. Keep Databricks for engineering and ML; mirror the Unity Catalog catalog into Fabric (metadata only, data read through shortcuts) so Power BI uses Direct Lake without a copy. *Trade-off: two platforms and two security models; name who owns row/column security.*

**2. Lakehouse or Warehouse in Fabric?**
Lakehouse for Spark, files, ML and mixed skills; Warehouse for T-SQL teams needing DML and multi-table transactions. Both use the same T-SQL engine for reads, and the lakehouse SQL endpoint cannot modify data. *Trade-off: skills and transaction needs, not performance.*

**3. Direct Lake or Import?**
Direct Lake for large Delta-backed models; check the F-SKU guardrails (for example F64: 5,000 files and 1,500M rows per table, F32: 300M rows and 40 GB model size). Direct Lake on OneLake never falls back to DirectQuery, so a breach fails refresh. *Trade-off: freshness and scale versus guardrails and layout discipline.*

**4. Cosmos DB, Fabric SQL database or Azure SQL for an app back end?**
Cosmos for global low-latency NoSQL with elastic scale; relational OLTP with joins fits SQL. Do not choose Cosmos for join-heavy relational data. *Trade-off: modeling effort and RU cost versus relational flexibility.*

## Capacity and cost
**5. Users report slow reports at 9 am. First steps?**
Open the Capacity Metrics app, check smoothed utilization and throttling stage. Interactive delay starts when smoothed future usage passes 10 minutes; rejection starts past 60 minutes. Then find top items by CU, move background jobs off the morning window, or isolate BI on its own capacity. *Trade-off: scale up versus reschedule versus split.*

**6. How do you size Fabric for a PoC?**
Start with pay-as-you-go F SKU one step below the estimate, measure 1 to 2 weeks, then decide; reserve only after steady state. Reservation discount percentage is `UNVERIFIED`; check the pricing page. *Trade-off: PoC cost versus risk of mis-sizing.*

**7. Autoscale or manual throughput in Cosmos DB?**
Autoscale costs 1.5x the manual per-RU rate on single-write accounts; if the container hits its max for 66% of hours or fewer, autoscale is cheaper. On multi-region-write accounts with more than one region the rate matches manual. *Trade-off: unit price versus idle waste.*

**8. What can make a pause save less than expected?**
OneLake storage keeps billing while paused, and pausing adds remaining smoothed overage to the bill. *Trade-off: compute saved versus a one-off overage charge.*

## Security
**9. CISO wants everything private. What breaks in Fabric?**
Tenant private link plus blocking public access: on-prem data gateway cannot register (VNet data gateway works), starter Spark pools are disabled, Copilot and the Capacity Metrics app are unavailable, trial capacity unsupported; it protects inbound only, so outbound needs managed private endpoints, trusted workspace access or outbound access protection. *Trade-off: isolation versus features and operations.*

**10. Where should row-level security live?**
Pick one model per consumption path. OneLake security for anything crossing engines (honoured by lakehouse, Spark, Direct Lake on OneLake and the SQL endpoint in user-identity mode); SQL-native only for warehouse-only consumers. Warehouse SQL RLS is not translated to OneLake policies, so a shortcut can expose full data. *Trade-off: consistency versus maximal native features.*

**11. What is risky about switching the SQL endpoint to user-identity mode?**
It briefly takes all endpoints in the workspace offline, cancels queries and irrecoverably deletes existing SQL roles. Schedule a change window. *Trade-off: unified security versus migration pain.*

**12. Cosmos DB without keys?**
Set `disableLocalAuth=true`, use Entra ID with the native data-plane roles (Built-in Data Reader `...0001`, Data Contributor `...0002`); clients using keys fail. *Trade-off: removes secret sprawl but needs RBAC rollout and SDK support.*

**13. CMK in Fabric: what is not covered?**
Spark shuffle/temp data, environment libraries, pipeline and ML metadata, and Warehouse caches; the key must be versionless in a vault with soft delete and purge protection, revocation blocks access in about 60 minutes. *Trade-off: control versus residual unprotected areas and availability risk.*

**14. Databricks writing into OneLake via a Unity Catalog external location?**
It is Beta and any Member/Contributor/Admin of that Fabric workspace can read, write and delete the data, bypassing Unity Catalog. Use a dedicated locked-down workspace. *Trade-off: single storage versus a governance bypass.*

**15. Secure an Azure Databricks workspace for a regulated customer.**
Premium plan; VNet injection with SCC (no public IPs); front-end plus back-end Private Link with public access disabled for full isolation; hub-spoke with a dedicated web-auth workspace; storage firewall (warning: enabling via CLI deletes the managed access connector, remap external locations first); serverless access via NCC private endpoints and an NSP service tag; CMK; compliance security profile for standards such as HIPAA and PCI-DSS (adds a charge). *Trade-off: security versus the one-way settings and operational complexity.*

## Resiliency
**16. RPO/RTO for Fabric?**
Zone failures are automatic. Regional DR needs the capacity BCDR switch (OneLake lakehouse and warehouse data only), replication is asynchronous, no numeric RPO is published, Microsoft-initiated failover typically takes under an hour (not contractual); everything else is rebuilt from Git. *Trade-off: do not promise numbers; tier workloads.*

**17. Cosmos DB multi-region: which consistency level?**
Session for most. Strong is unavailable with multi-region writes and costs about 2x read RUs; RPO under 15 minutes for Session/Consistent Prefix/Eventual with multiple regions, 0 for Strong single-write. *Trade-off: latency/RU cost versus data-loss window.*

**18. Cosmos DB failover mechanics?**
Service-managed failover can take an hour or more to declare and may lose unreplicated writes (unless Strong); customer-forced failover is faster. Test failover and failback end to end. Per-partition automatic failover GA status is `UNVERIFIED`. *Trade-off: automation versus speed and loss.*

**19. How do you test DR?**
Rebuild a workspace from Git into a second capacity, force a Cosmos failover in non-prod, restore a backup; record time and gaps. *Trade-off: engineering time versus untested plans.*

## Data design
**20. Choose a Cosmos DB partition key for multi-tenant orders.**
High cardinality, present in queries, even RU and storage. Logical partition max 20 GB and 10,000 RU/s per physical partition. If tenants are skewed, use a hierarchical key (up to 3 levels; HPK GA status `UNVERIFIED`) or a synthetic key; avoid `/id` for query-heavy workloads. *Trade-off: query locality versus hot partitions; the key is immutable.*

**21. Embed or reference in Cosmos?**
Embed bounded, co-read, rarely changing data; reference unbounded or frequently changing data. Item limit is 2 MB. *Trade-off: read cost versus update fan-out.*

**22. Shortcut, mirror or copy?**
Shortcut when data stays in place; mirror operational databases (compute free, free storage 1 TB per CU, needs running capacity); copy to transform or isolate. *Trade-off: freshness and simplicity versus source load and independence.*

**23. Cosmos DB analytics: Synapse Link?**
Not supported for new projects per Learn; use Fabric mirroring (NoSQL API, needs continuous backup, no multi-write accounts, nested data as JSON strings). *Trade-off: no RU cost for replication versus mirroring limits.*

## AI
**24. Customer wants a Fabric data agent over sales data. What do you check?**
Paid F2+ capacity, tenant AI settings including cross-geo, data quality and a curated semantic model, limits (5 sources, 25 rows/columns, read-only), region match between source and agent capacity. Status: GA per concept page though the release table says preview. *Trade-off: speed versus governance; keep previews off the critical path.*

**25. Where to store vectors for RAG?**
Cosmos DB NoSQL with DiskANN (up to 4096 dims; quantizedFlat best up to about 50,000 vectors in scope) when the app is the system of record; Eventhouse for vectors beside telemetry (no native ANN index); Azure AI Search for rich hybrid search (integration page `UNVERIFIED`). *Trade-off: operational simplicity versus search features.*
