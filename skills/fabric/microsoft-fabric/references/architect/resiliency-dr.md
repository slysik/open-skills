# Fabric architect: resiliency and disaster recovery

Last verified: 2026-10-19 (Learn: `security/reliability-fabric` 2025-09-19, `onelake/onelake-disaster-recovery` 2026-03-11, `security/experience-specific-guidance` 2026-10-06, `admin/region-availability` 2026-09-25). For pipeline-level retry, idempotency and dead-letter design see [../../data-pipelines/resiliency.md](../../data-pipelines/resiliency.md).

## 1. What Microsoft does vs what you do
| Concern | Microsoft | Customer |
|---|---|---|
| Zone failure | Spreads resources across availability zones automatically; no configuration | Resubmit failed Spark jobs, restart failed warehouse queries, enable ZRS on non-OneLake storage such as ADLS Gen2 |
| OneLake durability | ZRS where available else LRS: at least 11 nines (LRS), 12 nines (ZRS). Soft delete keeps deleted files 7 days | Nothing |
| Regional disaster | Initiates failover (typically under one hour, not contractual) | Enable the capacity BCDR switch beforehand; rebuild everything outside OneLake |

## 2. Capacity BCDR switch (OneLake data only)
- Per capacity, needs capacity admin. Covers **Lakehouse and Warehouse OneLake data only**; not KQL databases or other non-OneLake data.
- Data is stored in two regions; the secondary is the Azure paired region and cannot be changed. Needs a supported pair.
- After a change, wait 30 days before changing again. Enabling can take long in some regions (East US 2, Central US, East US, West US, Japan East/West, North Europe, West Europe).
- Billed as BCDR Storage and BCDR Operations (about double write cost; see capacity-finops).
- Replication is **asynchronous**: unreplicated data is lost. No numeric RPO is published. State this to customers; do not invent one.
- Power BI BCDR is on by default where the paired region supports it (Sweden Central is an exception).

## 3. What happens after failover
Portal and Power BI become read-only; lakehouse/warehouse items cannot be opened (files reachable through the OneLake global endpoint and APIs); new primary has local redundancy only; KQL databases and querysets are inaccessible; notebook code and ML model/experiment content are not saved; OneLake catalog read-only. If the tenant home region itself is down, Microsoft recovers it first.

## 4. Customer recovery runbook (outline)
1. Before: enable the DR switch; keep every artifact in Git; back up non-OneLake data to another region.
2. After failover: create capacity C2 (ideally outside the primary geo), workspace W2, items with the same names.
3. Restore per item type:

| Item | Recovery |
|---|---|
| Lakehouse | Copy data with a Spark script (failover timestamp from Support) or Azure Storage Explorer |
| Warehouse | Repopulate through an interim lakehouse and T-SQL; keep schema and security code in Git; or run two warehouses in separate regions |
| Notebook, SJD, pipeline, Dataflow Gen2, Copy job, GraphQL, ML model | Git, `.pqt` templates, or manual re-creation |
| SQL database | Periodic `.bacpac` export to another region, then import |
| KQL database | Two independent databases in different regions with parallel ingestion |
| Eventstream | No data loss if destinations support DR |
| Activator | Git is the only path |

Warehouse restore points and retention, and Eventhouse/lakehouse backup beyond the DR guide: `UNVERIFIED` (page not retrieved). Do not quote retention numbers until checked.

## 5. RPO/RTO tiers (design guidance, not Microsoft SLAs)
| Tier | Target | Pattern |
|---|---|---|
| Tier 3: analytics, rebuildable | RPO hours-days, RTO days | Git + IaC + re-run pipelines in new region |
| Tier 2: business reporting | RPO minutes-hours, RTO hours | BCDR switch + Git + tested rebuild script |
| Tier 1: mission critical | RPO near zero | Dual-run: two capacities/regions with parallel ingestion; Fabric-native DR alone cannot promise near-zero RPO |

## 6. Region and feature availability
Check `admin/region-availability` before committing a design: some regions are Power BI-only; Fabric App, Digital twin builder, Ontology, Operations agent and Schema Registry (preview) are missing in some regions; Database Hub is missing in North Europe. Managed private endpoints and outbound access protection require Data Engineering in the home and capacity region.

## 7. Test it
Run a game day each year: rebuild a workspace from Git into a second capacity, measure time, record gaps. Untested DR is a plan, not a capability.

## 8. Anti-patterns
- "OneLake is ZRS, so we have DR" (zone resilience is not regional DR).
- Enabling BCDR and assuming KQL, notebooks and pipelines are covered.
- No Git for items, so there is nothing to rebuild from.
- Promising an RPO the docs do not state.

## 9. Talk track
"Zone failures are handled for you. Regional disasters are a shared job: Microsoft fails over OneLake data if you turned the switch on, and you rebuild the rest from Git. We agree the tier per workload, rehearse the rebuild, and I will not quote an RPO that Microsoft has not published."
