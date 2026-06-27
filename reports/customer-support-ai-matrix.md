# Customer Support AI Smoke-Test Matrix

Generated: 2026-06-27 14:06 UTC

This report compares the same seven-table customer-support workload across Databricks, Snowflake, and Microsoft Fabric + Foundry. Harnesses are CLI-first, use REST only where no suitable CLI operation exists, and use no MCP tools.

## Benchmark

- Seven deterministic tables and 69 total source rows.
- Eight ticket rows, each enriched with summary, category, and sentiment.
- Six knowledge articles for retrieval.
- Ten evaluation prompts: five structured, four RAG, one answer-quality.
- Cloud runs are intentionally bounded; dry-run results validate command routing only.

## Execution

| Platform | Status | CLI/API path | Duration | Tables | AI rows | Eval | Score |
|---|---:|---|---:|---:|---:|---:|---:|
| Databricks | passed | databricks | 71s | 7/7 | 8/8 | 6/10 | 67/100 |
| Snowflake | passed | snow | 38s | 7/7 | 8/8 | 6/10 | 67/100 |
| Fabric + Foundry | passed | az + sqlcmd + curl | 47s | 7/7 | 8/8 | 6/10 | 73/100 |

## Cost And Tokens

| Platform | Input tokens | Output tokens | Embedding tokens | Cached tokens | Compute USD | AI USD | Total USD |
|---|---:|---:|---:|---:|---:|---:|---:|
| Databricks | not captured | not captured | not captured | not captured | not captured | not captured | not captured |
| Snowflake | not captured | not captured | not captured | not captured | not captured | not captured | not captured |
| Fabric + Foundry | 827 | 195 | not captured | not captured | not captured | 0.0032 | not captured |

## Performance

| Platform | Total duration | P50 latency | P95 latency | Errors |
|---|---:|---:|---:|---|
| Databricks | 71s | not captured | not captured | none reported |
| Snowflake | 38s | not captured | not captured | none reported |
| Fabric + Foundry | 47s | not captured | not captured | none reported |

## Feature Coverage

| Platform | Data/SQL | AI enrichment | RAG | Natural-language SQL | Observability |
|---|---|---|---|---|---|
| Databricks | Unity Catalog + Delta + SQL Warehouse | AI Functions | AI Similarity smoke; Vector Search follows core pass | Genie follows core pass | Query profile, system.billing, MLflow |
| Snowflake | Snowflake tables/views + X-Small warehouse | Cortex AI Functions | Cortex Search service | Cortex Analyst follows core pass | Query history + Cortex usage history |
| Fabric + Foundry | Fabric Warehouse through sqlcmd | Fabric Warehouse AI Functions | Foundry vector store + file_search | Fabric semantic model/Fabric IQ follows core pass | Capacity Metrics + Foundry traces |

## Missing Features And Friction

| Platform | Feature gaps | Notes | Expected skill routing |
|---|---|---|---|
| Databricks | Genie Space and production Vector Search index creation are intentionally deferred until the bounded SQL/AI smoke passes<br>token and dollar telemetry require system.billing access and are left null when the executing identity cannot query it | Databricks SQL was executed through databricks api post/get, not MCP | databricks-config<br>databricks-dbsql<br>databricks-ai-functions<br>databricks-vector-search<br>databricks-genie<br>databricks-mlflow-evaluation |
| Snowflake | Cortex Analyst semantic-view provisioning is deferred until the core Cortex AI and Search smoke passes<br>account-level token and credit history can be unavailable to non-admin smoke identities | all execution used Snowflake CLI; Cortex Search is created by SQL and queried with SEARCH_PREVIEW | snowflake<br>snowflake-cortex<br>cortex-code |
| Fabric + Foundry | Fabric semantic model and Fabric IQ provisioning are deferred until Warehouse AI SQL succeeds<br>Fabric Capacity Metrics cost export is not yet automated by this harness | AI cost covers the Foundry gpt-4.1 response only; Fabric capacity and vector indexing are excluded<br>Fabric used sqlcmd; Foundry used az rest and curl multipart; no MCP tools | microsoft-fabric<br>sqldw-authoring-cli<br>semantic-model-authoring<br>foundry-config<br>foundry-rag-search<br>foundry-agents-authoring<br>foundry-agents-runtime<br>foundry-evaluation<br>foundry-observability |

## Interpretation

- `dry_run` proves the local data, CLI dependencies, argument parsing, and result contract.
- `passed` requires cloud object creation, seven loaded tables, bounded AI enrichment, and SQL assertions.
- Cost and token cells remain `not captured` until the platform exposes them to the executing identity.
- A platform should not be ranked on price or latency until all three runs use the same region, model class, and eval set.
