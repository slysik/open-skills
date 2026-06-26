---
name: snowflake-cortex
description: "Build Snowflake objects (databases, schemas, warehouses, tables, stages, streams, tasks, dynamic tables, RBAC) and design Snowflake Cortex AI workloads (LLM functions, Cortex Search, Cortex Analyst, semantic views, Document AI) for agentic data platforms. USE FOR: create snowflake database, create warehouse, create role, grant, create table, create stage, create stream, create task, create dynamic table, build dbt model on snowflake, write merge, design semantic view, Cortex Analyst, Cortex Search, COMPLETE function, EMBED_TEXT, SUMMARIZE, CLASSIFY_TEXT, EXTRACT_ANSWER, TRANSLATE, Document AI, Snowpark, vector search, hybrid search, RAG on snowflake, text-to-SQL, agentic data workflows on snowflake, compare Cortex AI vs Claude Code, prep for snowflake/cortex interview, The Zebra agentic platform interview, Insight Global AI architect interview. DO NOT USE FOR: building agents in Python/TypeScript SDKs (use claude-agent-sdk patterns), Foundry/Azure deployment (use microsoft-foundry)."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# Snowflake + Cortex AI Skill

Purpose: help build Snowflake objects quickly and reason about Cortex AI as the
"in-database" agentic surface. Optimized for the Zebra/Insight Global Agentic
Platform Architect interview, where the data stack is **dbt + Snowflake +
Cortex semantic views** and the agent stack is **FastAPI + Kubernetes +
Dagster/Prefect + Kafka + OpenAI/Anthropic**.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [connection.md](connection.md) | **Connect.** `snow` CLI (primary; snowsql/Python = fallback), key-pair SP auth, verify, troubleshoot (incl. the connections.toml top-level-key bug). |
| [patterns.md](patterns.md) | Most-performant defaults: Dynamic Tables, warehouse isolation (WH_TRANSFORM/BI/AI), Cortex-in-view guardrails. |
| [objects/objects.md](objects/objects.md) | Creating DBs, schemas, warehouses, roles, tables, stages, streams, tasks, dynamic tables, masking policies. Reference SQL templates. |
| [cortex-ai/cortex-ai.md](cortex-ai/cortex-ai.md) | Calling Cortex LLM functions, Cortex Search, Cortex Analyst, Document AI; choosing models; cost/latency tradeoffs. |
| [semantic-views/semantic-views.md](semantic-views/semantic-views.md) | Designing Cortex **semantic views** + dbt graph context layer so AI outputs respect grain, dedup, and business semantics (the JD calls this out explicitly). |
| [cortex-vs-claude-code.md](cortex-vs-claude-code.md) | Articulating where Cortex AI and Claude Code overlap, where they diverge, and how to combine them in an agentic platform. |
| [interview-prep/zebra-agentic-architect.md](interview-prep/zebra-agentic-architect.md) | Talking points, STAR stories drawn from `building-specialized-agents/`, and the prepared answer to "Design agentic AI experiences using LangChain/Semantic Kernel/AutoGen…". |

## Mental model

Cortex AI = LLM + retrieval + structured-data reasoning **co-located with the data**.
Claude Code / Agent SDK = general-purpose agent runtime that **calls out** to data
systems via tools/MCP. In a real platform you use both:

```
                 ┌─────────────────────────────────────────┐
   user ─▶ FastAPI (K8s) ─▶ orchestrator (Dagster/Prefect, Kafka events)
                 │
                 ├─▶ Anthropic / OpenAI  (general reasoning, tool calls)
                 │           │
                 │           └─▶ MCP / function tools ──┐
                 │                                      ▼
                 └─▶ Snowflake Cortex (in-DB)   ◀──  SQL + semantic view
                        • COMPLETE / EMBED      ──▶ governed answers
                        • Cortex Search (RAG)
                        • Cortex Analyst (text-to-SQL over semantic view)
                        • Document AI (PDF → structured)
```

## Defaults & conventions

- Always create **per-environment** databases: `RAW_<env>`, `STG_<env>`,
  `MART_<env>` and a dedicated `AI_<env>` database for Cortex artifacts
  (search services, semantic views, vector tables).
- Warehouses: separate `WH_TRANSFORM`, `WH_BI`, `WH_AI` (Cortex calls bill
  through the warehouse running the SQL — isolate so AI cost is observable).
- Roles: `*_OWNER`, `*_RW`, `*_RO` per database; functional role
  `CORTEX_USER` granted `DATABASE ROLE SNOWFLAKE.CORTEX_USER`.
- Dynamic tables for incremental transforms; Streams + Tasks only when DT
  features are insufficient.
- Every Cortex call is wrapped in a view or UDF so prompts/models live in
  source-controlled SQL, not ad-hoc strings — this is the "prompt framework /
  guardrails" the JD calls out.

## Quick recipes (load full sub-doc for details)

```sql
-- Cortex one-shot
SELECT SNOWFLAKE.CORTEX.COMPLETE(
  'claude-3-5-sonnet',
  [{'role':'user','content':'Summarize: ' || policy_text}],
  {'temperature':0.1,'max_tokens':400}
) AS summary
FROM stg_policies;

-- Cortex Search (hybrid vector + keyword)
SELECT * FROM TABLE(
  AI_PROD.SEARCH.POLICY_KB!SEARCH('what is the cancellation window?', 5)
);

-- Cortex Analyst against a semantic view (text-to-SQL with guardrails)
-- exposed via REST: POST /api/v2/cortex/analyst/message
```
