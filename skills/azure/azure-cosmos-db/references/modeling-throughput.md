# Cosmos DB: modeling, partitioning and throughput

Last verified: 2026-10-19. Source: Microsoft Learn `azure/cosmos-db/` pages: `partitioning-overview` (2026-10-05), `hierarchical-partition-keys` (2026-04-27), `modeling-data` (2026-07-31), `concepts-limits` (2026-08-25), `request-units` (2026-07-21), `provision-throughput-autoscale` (2026-04-29), `how-to-choose-offer` (2026-07-21), `serverless` (2026-04-27), `burst-capacity` (2026-04-27), `index-policy` (2026-09-21), `throughput-buckets` (2026-05-15), `change-feed` (2026-06-02). Pages not fetched: `throughput-serverless`, `serverless-performance`, `change-feed-modes`, FAQs.

## 1. Hard limits that shape design
| Limit | Value |
|---|---|
| Item size | 2 MB (UTF-8 JSON length); 16 MB documents are MongoDB API only |
| Logical partition | 20 GB; temporary raise via support ticket but SLA is not honoured when raised |
| Physical partition | up to 10,000 RU/s and 50 GB; at least 4 replicas |
| Partition key value | max 2,048 bytes (101 bytes without large partition keys) |
| `id` | max 1,023 bytes; ASCII alphanumerics recommended |
| Request / response | 2 MB request, 4 MB response page, 5 s per operation or query page |
| Transactional batch | 100 operations, same partition key |
| Max RU per container or database | 1,000,000 (support ticket to raise) |
| Manual minimum | 400 RU/s or MAX(400, GB x 1, highest-ever RU/s / 100) |
| Autoscale minimum max-RU/s | MAX(1,000, GB x 10, highest-ever / 10), rounded up to 1,000 |
| Shared-throughput database | max 25 containers before the minimum rises |
| Account | 500 databases+containers combined; 250 accounts per subscription (up to 1,000 via support) |
| Query | 512 KB text, 10 JOINs, composite index max 8 properties and 100 paths |
| Per container | 100 stored procedures, 50 UDFs, 10 unique keys |
| Serverless | 1 region only, 500 databases+containers, 20 GB per logical partition |
| Free tier | 1 account per subscription, 1,000 RU/s and 25 GB free for the account lifetime, opt in at creation |
| Scaling | synchronous between the minimum and 100x the minimum; beyond that asynchronous, minutes to hours |

## 2. Partition key selection
Choose a **string, high-cardinality** key that appears in your most frequent queries and spreads RU and storage evenly.
- Good: tenantId + userId (hierarchical), deviceId, orderId for point-read heavy stores.
- Bad: low cardinality (status, type, country); high cardinality that no query filters on (random GUID) causes cross-partition fan-out.
- `/id` is fine for point-read/write-heavy workloads, bad for mixed query workloads.
- Cross-partition queries cost about 2 to 3 RU per physical partition; they matter once a container exceeds 30,000 RU/s or 100 GB.
- Key is immutable; moving partitions needs container copy jobs. Option: a **global secondary index** (eventually consistent, extra storage and RU) for a second access path.
- Multi-item ACID transactions only via stored procedures/triggers within one logical partition.

### Hierarchical partition keys (HPK)
Up to 3 levels (`kind: MultiHash`, `version: 2`), set at creation only, NoSQL API only. Prefixes can exceed 20 GB and 10k RU/s. Level 1 should have thousands of values and more values than physical partitions for write-heavy workloads; low first-level cardinality limits ingestion to one physical partition until it reaches 50 GB and splits (splits can take 4 to 6 hours). Putting the item id as the last level guarantees scale past 20 GB. Prefix filters route targeted; filters only on a middle or last level fan out. Minimum SDKs: .NET 3.33.0, Java 4.42.0, JavaScript 4.0.0; **Python support is contradictory on the page**; HPK GA status is not stated: `UNVERIFIED`. Index policy: include each level when you exclude root.

## 3. Embed or reference
| Embed when | Reference when |
|---|---|
| One-to-few, contained, read together, rarely changes, bounded | One-to-many or many-to-many, changes often, unbounded |

Anti-patterns: unbounded arrays (all comments in a post), embedding fast-changing shared data (stock price inside every portfolio, causing fan-out updates). Hybrid is fine: denormalize a few fields and keep precomputed aggregates updated transactionally. No foreign keys; referential integrity is the application's job. JOIN works only within a single item. Mixed types in one container co-located by key are fine with a `type` field. Fabric mirroring caveats: SQL endpoint 1,000-property limit, flatten where possible.

## 4. Throughput model choice
| Model | Use when | Watch out |
|---|---|---|
| **Provisioned (manual)** | Steady, predictable load (average hourly peak above 66% of max) | Idle waste; 100 RU/s increments |
| **Autoscale** | Variable or unpredictable; dev/test; scheduled spikes | 1.5x the manual per-RU rate on single-write accounts; equal rate on multi-region-write accounts with more than one region (then autoscale is always recommended); billed hourly on the highest scaled RU/s with a floor of 10% of max; scales between 0.1 x Tmax and Tmax; storage allowed 0.1 x Tmax GB (Tmax rises beyond that); dynamic per-partition scaling is default for accounts created after 2024-09-25 |
| **Serverless** | Intermittent traffic, long idle, dev/test, average-to-peak ratio below 10% | Single region, cannot add regions later, cannot set or read throughput, no shared-throughput databases, no lazy indexing, 5,000 RU/s per physical partition (page says container starts at 5,000 RU/s; performance page not fetched) |

Rule of thumb from Learn: if the container uses its full Tmax for 66% of hours or fewer, autoscale is cheaper. Avoid shared-database throughput for most workloads (noisy neighbours, 429s); prefer container-level. Multi-tenancy: partition-key-per-tenant (B2C) or account-per-tenant (B2B); avoid container-per-tenant or database-per-tenant.

### RU basics
A 1 KB point read costs 1 RU; point reads cost less than queries. Cost drivers: item size, indexed properties, consistency (Strong and Bounded Staleness reads about 2x), query complexity, scripts. RU/s is per region, so total = RU x number of regions.

## 5. Burst capacity and throughput buckets
- **Burst capacity**: each physical partition accumulates up to 5 minutes of idle capacity and spends it at up to 3,000 RU/s; only for partitions provisioned below 3,000 RU/s; provisioned throughput only; account-level opt-in taking 15 to 20 minutes; "not guaranteed", can be used for maintenance, so never rely on it for sustained load. GA status not stated: `UNVERIFIED`.
- **Throughput buckets (PREVIEW)**: up to 5 per container, each caps a percentage of container throughput; nothing is reserved; per-subscription enrollment and approval; not for shared-throughput or serverless; cannot use burst capacity. SDK minimums: .NET 3.50.0-preview.0, Java 4.75.0, Node 4.3.0, Python 4.11.0b1.

## 6. Indexing policy
Default indexes every property with range indexes (modes Consistent and None; Lazy exists but is not selectable and is unsafe). Good practice: include `/*` then exclude paths you never filter on, but then explicitly include the partition key path (each level for HPK). `id` and `_ts` always indexed in Consistent mode. Composite indexes are required for ORDER BY on 2+ properties: path order and direction must match, equality properties first, one range filter last. Policy updates are online and consume RUs at lower priority; replace an index by adding the new one, waiting for transformation to finish, then removing the old one. TTL needs indexing (mode None is not allowed with TTL). Spatial indexes (Point, Polygon, MultiPolygon, LineString) must be created explicitly. Disable indexing during large bulk loads, then re-enable.

## 7. Change feed
On by default for all accounts; cost is read RUs plus the lease container. **Latest version mode**: inserts and updates only, no deletes. **All versions and deletes mode**: creates, updates, deletes and TTL expirations including intermediate changes; requires continuous backup and is limited to the backup retention window; GA status `UNVERIFIED`. Ordering is guaranteed per partition key only; batch/bulk items share a modification time and may arrive in any order; delivery is at-least-once. Consume via Azure Functions, the change feed processor, the pull model or Spark.

## 8. Sizing method for a PoC
1. Write the top 5 to 10 access patterns with frequency, item size and latency target.
2. Estimate RU per pattern (portal capacity calculator, then verify with real queries and the returned RU charge).
3. Pick the key from the patterns; test the hot-key case explicitly.
4. Load test at 2x peak with realistic skew; watch normalized RU consumption per partition.
5. Decide manual vs autoscale from measured utilization; extrapolate cost with ranges.

## 9. Anti-patterns
- `/id`, status or country as the key for query-heavy data.
- Unbounded arrays inside one item.
- Autoscale for a flat, saturated workload (pay 1.5x for nothing).
- Shared database throughput with many busy containers.
- Raising RU/s to fix a hot partition.
- Cross-partition queries on the hot path.
- Treating burst capacity as headroom.

## 10. Talk track
"Cosmos DB bills for the shape of your queries. Give me your five most frequent access patterns and I will pick the partition key from them; the key is the one decision we cannot change later. Throughput model follows measured utilization: flat means manual, spiky means autoscale, mostly idle means serverless."
