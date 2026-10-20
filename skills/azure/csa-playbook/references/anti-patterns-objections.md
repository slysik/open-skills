# Anti-patterns and customer objections

Last verified: 2026-10-19 (facts from Learn pages gathered in the Fabric and Cosmos research).

## 1. Anti-pattern catalog
| # | Anti-pattern | Why it hurts | Better |
|---|---|---|---|
| 1 | One capacity/workspace for dev, test, prod | Dev load throttles prod | Capacity per environment |
| 2 | Everyone is Contributor | Bypasses OneLake security roles | Viewer plus data roles |
| 3 | Row security defined in three engines | Drift and leaks via shortcuts | One owner, one model per path |
| 4 | Cosmos partition key `/id` for query-heavy data, or low cardinality (status, country) | Cross-partition fan-out or hot partition | High-cardinality key that appears in queries; hierarchical key if tenant-skewed |
| 5 | Unbounded arrays embedded in a Cosmos item | 2 MB item cap, rewrite cost | Reference with a separate item |
| 6 | Copying data nightly that a shortcut/mirror could expose | Cost, latency, drift | Shortcut or mirror |
| 7 | Buying reservations before measuring | Locked-in wrong size | 4+ weeks of measured use |
| 8 | Promising an RPO the service does not publish | Contract and trust risk | State what is published; design tiers |
| 9 | Preview feature on the critical path | No GA commitment | Fallback plan or wait |
| 10 | Portal-only changes in prod | Unrepeatable, undetected drift | Git + pipeline |
| 11 | Hard-coded GUIDs in notebooks | Breaks promotion | Variable libraries |
| 12 | Relying on Synapse Link for new Cosmos analytics | Not supported for new projects | Fabric mirroring |
| 13 | Two writers to one Delta path | Corruption/conflicts | One writer per table path |
| 14 | Sensitivity labels assumed to block CSV export | Not enforced for CSV/TXT | DLP plus export controls |
| 15 | Key-based auth left on | Shared secret sprawl | Entra-only (Cosmos `disableLocalAuth=true`) |
| 16 | Ignoring AI meters | Surprise CU use | Size for Copilot and AI meter |
| 17 | Treating zone redundancy as DR | Region loss not covered | Tiered DR plan |
| 18 | Never testing restore | Backup that does not restore | Scheduled restore drill |

## 2. Common objections and crisp answers
| Objection | Answer |
|---|---|
| "Fabric is just Power BI with extras." | One OneLake, one security surface and one capacity across ingestion, Spark, warehouse, real-time and BI. Decision is whether that simplification outweighs engine-level control. |
| "We already have Databricks, why Fabric?" | You do not have to choose. Mirror the Unity Catalog metadata into Fabric so BI reads without a copy; keep engineering and ML in Databricks. Decide who owns security. |
| "Capacity pricing is unpredictable." | It is fixed per SKU with smoothing; spikes are absorbed, sustained overload throttles in staged steps. Optional overage bills at 3x only if enabled. Measure two weeks, then reserve. |
| "Is Direct Lake production ready?" | It is documented with per-SKU guardrails (files, row groups, rows, model size). Check them for the SKU; Direct Lake on OneLake does not fall back to DirectQuery, so breaches fail instead of degrading. |
| "Cosmos DB is too expensive." | Cost is driven by partitioning, indexing policy and consistency. Autoscale is cheaper if peak usage is 66% of hours or fewer; point reads cost about 1 RU for 1 KB; strong reads cost about 2x. Tune before dismissing. |
| "We need strong consistency globally." | Strong is not available with multi-region writes and strong reads cost about 2x. Ask which flows truly need it; Session fits most. |
| "Can Purview scan everything?" | Source coverage varies and lineage has gaps; the Purview skill is not yet written, so verify the specific source on Learn before promising. `UNVERIFIED` here. |
| "Is Copilot safe for our data?" | Enabled by default on paid capacities; prompts, schema and history may be sent; some regions process in the US or EU unless the cross-geo setting allows it; table contents are not sent unless directed. Security must approve the setting. |
| "Why not stay on Synapse?" | Migrate new work to Fabric. Synapse Link for Cosmos is no longer supported for new projects, and Learn provides ADF, Synapse Spark and Eventhouse migration paths. |
| "Private link everywhere is mandatory." | Fine, but plan around the limits: on-prem gateway cannot register, Spark starter pools are disabled, Copilot is unsupported, it is inbound only. |
| "How do we know the PoC represents prod?" | Charter with numeric criteria, realistic skew, a failure test and a cost extrapolation with ranges. |
