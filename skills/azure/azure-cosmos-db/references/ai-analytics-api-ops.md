# Cosmos DB: AI, analytics, API selection and operations

Last verified: 2026-10-19. Source: Microsoft Learn `azure/cosmos-db/vector-search` (2026-09-29), `vector-database` (2026-05-22), `gen-ai/agent-kit` (2026-07-20), `fabric/mirroring/azure-cosmos-db` (2026-10-06), `synapse-link` and `analytical-store-introduction` (2026-07-20), `mongodb/how-to-migrate-documentdb` (2026-06-02), `nosql/best-practice-dotnet` (2026-06-15), `nosql/performance-tips-dotnet-sdk-v3` (2026-07-21), `troubleshoot-request-rate-too-large` (2026-05-13), `migrate` (2026-04-27). The `gen-ai/` index returned 404, so full-text search, hybrid search (RRF), semantic cache and MCP toolkit pages were **not verified**.

## 1. Vector search (NoSQL API)
| Index | Max dimensions | Use |
|---|---|---|
| `flat` | 505 | Brute force, 100% recall, small sets |
| `quantizedFlat` | 4,096 | Brute force on quantized vectors; recommended at about 50,000 vectors or fewer in scope |
| `diskANN` | 4,096 | Approximate; generally best above 50,000 vectors in scope |

- Container vector policy: `datatype` float32/float16/int8/uint8, `dimensions` (default 1,536), `distanceFunction` cosine (default)/dotproduct/euclidean, optional `quantizerType` product (default) or spherical.
- Enable with `az cosmosdb update ... --capabilities EnableNoSQLVectorSearch` (auto-approved, up to about 15 minutes).
- Limits: quantizedFlat and diskANN need at least 1,000 vectors indexed (below that a full scan runs and RU can be higher); ingestion above 5M vectors in a short time may need extra index build time; not supported on accounts with shared throughput; vector indexing cannot be disabled once enabled; no wildcards or array-nested vector paths; **policy and index cannot be edited after creation**; hierarchical partition keys need an email to the product team to configure the account.
- Queries: `VectorDistance(...)` with `ORDER BY` and always `TOP N`; tune recall with `searchListSizeMultiplier`; DiskANN results can vary slightly between runs.
- PREVIEW (private sign-up): ultra-high-throughput vector search. The page does not label the main feature GA or preview; GA is inferred, treat as `UNVERIFIED`.
- RAG, LLM caching and agent memory are described as use cases of the vector store; integrations listed: LangChain (vector store and LLM caching), LlamaIndex, Semantic Kernel memory connector (Python), "Build Your Own Copilot" C# samples. A dedicated semantic-cache feature is not described on the page.
- Agent Kit: open-source package of 111 rules in 12 categories (vector search, full-text BM25, hybrid, LangGraph patterns); works with Claude Code, GitHub Copilot, Gemini CLI. Status unlabelled; worth reviewing.

## 2. Analytics: Fabric mirroring (use this), Synapse Link (do not)
**Fabric mirroring for Cosmos DB** (page carries no preview banner; other Microsoft pages call it GA):
- NoSQL API only; not in sovereign clouds; **continuous backup required** (7-day tier recommended and free, standard continuous-backup charges apply).
- Replication consumes no RUs; Fabric replication compute and OneLake storage (up to capacity size) are free; querying through Data Explorer in Fabric does use RUs; SQL, Power BI and Spark queries are charged to Fabric capacity.
- Does not use analytical store or change feed; lands as Delta/Parquet in OneLake; latency "a few minutes", possibly longer.
- Limits: **multi-write-region accounts unsupported**; OneLake CMK unsupported; read-only account keys unsupported; nested data appears as JSON strings (use `OPENJSON`); Entra RBAC needs `readMetadata` and `readAnalytics`; vector-search accounts supported; VNet/private-endpoint accounts via a VNet data gateway plus trusted workspace setup; mirror one database at a time; SQL endpoint 1,000-property limit.
- See the Fabric onelake-integration reference for the shortcut-versus-mirror decision.

**Synapse Link for Cosmos DB**: Learn says "no longer supported for new projects. Don't use this feature" and points to Fabric mirroring. The same banner appears on the analytical store page; whether analytical store alone is deprecated is `UNVERIFIED`. Analytical store limits: 1,000 properties, nesting depth 127, auto-sync usually within 2 minutes (up to 5 for shared-throughput databases with many containers), not backed up.

**Change feed to Eventstream/Databricks/Functions** remains the pattern for event-driven pipelines (see modeling-throughput).

## 3. API selection
| API | Choose when | Notes |
|---|---|---|
| **NoSQL** | New cloud-native apps; need hierarchical keys, vector, 99.999% multi-region, change feed, Fabric mirroring | Feature-richest; Learn recommends it for high scale with 99.999% SLA and multi-region failover |
| **MongoDB (RU-based)** | Existing Mongo apps, wire protocol compatibility | Documented at API versions 4.2 and 4.0 on the landing page |
| **Azure DocumentDB** (`Microsoft.DocumentDB/mongoClusters`) | MQL feature depth, vCore model | A separate service; Learn directs MongoDB migrations to consider it; GA/preview `UNVERIFIED` |
| **Cassandra / Gremlin / Table** | Lift-and-shift of those workloads | Gremlin and Table accounts can use `Sql` private endpoints |
| **PostgreSQL (Citus)** | Distributed Postgres | Hub still lists it; retirement for new customers `UNVERIFIED`, verify before recommending |

MongoDB to DocumentDB migration (portal): offline or online (online needs continuous backup); indexes are not migrated; shard key cannot be changed; network bypass mode uses a preview API version.

## 4. SDK and client best practices (.NET guidance; verify other SDKs)
Singleton `CosmosClient`; Direct mode (default); latest SDK; production host at least 4 cores and 8 GB, CPU under 70%, accelerated networking; same region as the account; set `ApplicationPreferredRegions` or `ApplicationRegion`; enable service-managed failover; explicit Newtonsoft.Json reference 13.0.3+ (13.0.4 recommended; required for SDK 3.54.0+); `IdleTcpConnectionTimeout` at least 10 minutes; `PortReuseMode=PrivatePortPool`; `EnableContentResponseOnWrite=false` for write-heavy loads; enable Bulk for throughput; do not call create-if-not-exists or metadata reads on the hot path (separate limits, no SLA); never block on async; never parse the Diagnostics string. Availability: cross-region hedging (`AvailabilityStrategy.CrossRegionHedgingStrategy`), partition-level circuit breaker (off by default, env var `AZURE_COSMOS_CIRCUIT_BREAKER_ENABLED`; defaults 10 consecutive read failures, 5 write failures), `ExcludeRegions` per request (SDK 3.37.0+). Java and Python tip pages were not fetched.

## 5. 429 troubleshooting
- 1 to 5% of requests as 429 with acceptable latency is healthy with even partition distribution. SDKs retry up to about 9 times or 30 seconds cumulative wait.
- Find hot partitions: Insights, Throughput, "Normalized RU Consumption (%) By PartitionKeyRangeID"; identify the key with `CDBPartitionKeyRUConsumption`.
- Causes: RU above provisioned; **metadata rate limiting (raising RU/s does not help)**; transient service error; `TXN_WAIT_FOR_TRANSACTION_END` (concurrent transactions on the same logical key).
- Fixes: tune indexing policy, change the partition key (container copy), raise RU/s. Scale-up is instant up to physical partitions x 10,000 RU/s; above that it is asynchronous and can take up to 5 to 6 hours. Autoscale scales to max only if normalized RU is 100% for a sustained period in a 5-second interval. "Redistribute throughput across partitions" is Preview.
- Alerts: normalized RU consumption, 429 counts, data size, host CPU/memory (Azure Monitor alert pages not fetched).

## 6. Migration
Small datasets: Azure Data Factory Cosmos connector or the Spark connector. Large scale: custom bulk-executor tool (about 500K RU/s per node), pre-size the container, set `indexingMode` to none during load, about 200 MB source files. Hub also lists Azure Database Migration Service for MongoDB and Cassandra CQL/Spark paths. A dedicated "data migration tool" status is `UNVERIFIED`.

## 7. PoC load-test method
1. Take the five access patterns and target p99 from the ADS.
2. Create the container with the intended key and indexing policy via Bicep.
3. Generate synthetic data with realistic skew (include a hot-key tenant at 10x average).
4. Run read/write mix at 1x, 2x, 4x with the .NET/Java/Python SDK in Direct mode, same region.
5. Record RU per operation, p50/p95/p99, 429 rate, normalized RU per partition.
6. Failover drill in a non-prod multi-region account; measure client recovery time.
7. Restore drill from continuous backup; record gaps (firewall, RBAC, procedures).
8. Extrapolate cost with ranges; decide manual vs autoscale; document the key decision.
Keep the lab inside the credit budget: serverless or the free tier (1,000 RU/s, 25 GB) for functional tests, short-lived autoscale for load tests, tear down the same day, no multi-region accounts left running.

## 8. Anti-patterns
- Using Synapse Link for new analytics.
- Choosing MongoDB API for a greenfield app to "stay portable" and losing NoSQL-only features.
- Treating vector index settings as editable.
- Metadata or create-if-not-exists calls on every request.
- Long-lived multi-region accounts left in a PoC subscription.

## 9. Talk track
"For AI, Cosmos DB gives you operational data, vectors and agent memory in one transactional store; we choose DiskANN once we pass tens of thousands of vectors and accept that the index policy is fixed at creation. For analytics we mirror into Fabric rather than build a second pipeline, and we note the two limits that bite: no multi-write accounts and nested JSON strings."
