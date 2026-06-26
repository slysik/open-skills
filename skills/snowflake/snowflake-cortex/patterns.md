# Snowflake — Most-Performant Default Patterns

## Transforms
- **Dynamic Tables are the default** incremental transform — declarative target
  freshness, auto-managed refresh, no orchestration glue.
  *Use Streams + Tasks only when DT features are insufficient* (e.g. complex
  imperative logic, external calls).
- dbt models compile to these; keep `RAW_<env>` → `STG_<env>` → `MART_<env>`.

## Warehouses & cost
- **Isolate by purpose:** `WH_TRANSFORM`, `WH_BI`, `WH_AI`. Cortex calls bill
  through the warehouse running the SQL — isolating `WH_AI` makes AI cost
  observable. *Performant default.*
- `AUTO_SUSPEND = 60`, `AUTO_RESUME = TRUE`; size up for throughput, not idle.
- Per-environment databases; `*_OWNER/_RW/_RO` roles per DB.

## Cortex AI
- Wrap every Cortex call in a **view or UDF** so prompts/models live in
  source-controlled SQL, not ad-hoc strings (the guardrail layer).
- Grant functional role `CORTEX_USER` → `DATABASE ROLE SNOWFLAKE.CORTEX_USER`.
- **Cortex Search** for hybrid vector+keyword RAG; **Cortex Analyst** over a
  **semantic view** for governed text-to-SQL (respects grain/dedup/business semantics).

## Performant-default callouts
| Workload | Reach for | Why |
|---|---|---|
| Incremental transform | Dynamic Table | declarative freshness, no orchestrator |
| RAG retrieval | Cortex Search service | hybrid vector+keyword, in-DB |
| Text-to-SQL | Cortex Analyst + semantic view | governed, grain-aware |
| One-shot LLM | `SNOWFLAKE.CORTEX.COMPLETE` in a UDF | versioned prompt, isolated WH_AI cost |
| Streaming ingest | Snowpipe Streaming (v4 Kafka) | no files/pipes, low latency |
