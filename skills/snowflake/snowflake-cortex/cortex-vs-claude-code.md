# Cortex AI vs Claude Code (Agent SDK) — Same Goals, Different Layers

You already know Claude Code / the Anthropic Agent SDK from
`building-specialized-agents/`. Cortex AI is a **different layer** of the
stack solving overlapping problems. Knowing both — and when to reach for
which — is a strong interview signal.

## One-line framing

> Claude Code is a **general agent runtime** that lives next to the
> developer/app and calls *out* to data via tools. Cortex AI is **AI
> co-located with the data** — you call *in* with SQL or REST, and
> governance is enforced by the database.

## Side-by-side

| Capability | Claude Code / Agent SDK | Snowflake Cortex AI |
|---|---|---|
| Where it runs | Your laptop / FastAPI / K8s | Inside Snowflake (compute = warehouse) |
| Primary interface | Python/TS SDK, MCP tools | SQL functions + REST (Search, Analyst) |
| Reasoning model | Claude (Sonnet/Opus/Haiku) | Claude, Mistral, Llama, Arctic |
| Tool calling | First-class (custom tools, MCP) | Implicit via SQL composition; Analyst constrains tool surface to a semantic view |
| Memory | Session/`resume`, transcripts on disk | None native — you persist in tables |
| Multi-agent orchestration | Yes (Planner/Builder/Reviewer pattern in `custom_7_micro_sdlc_agent`) | No — orchestrate from outside (Dagster/Prefect/FastAPI) |
| RAG | Bring your own (vector DB, MCP) | Cortex Search (managed hybrid) |
| Text-to-SQL | LLM writes SQL freely (risky) | Cortex Analyst, constrained to semantic view (governed) |
| Data egress | Data leaves the DB | **Data stays in Snowflake** — huge for PII / GDPR / CCPA |
| Governance | App-level | RBAC, masking policies, row access policies enforced automatically |
| Cost model | Per-token to provider | Snowflake credits (per-token model rate × warehouse runtime) |
| Best at | Long-horizon agent loops, dev tooling, file/code edits, MCP fan-out | Bulk inference over rows, governed RAG, NL-to-metrics |

## Where they overlap

- **Tool calling**: both let an LLM invoke functions with structured args.
  Cortex's "tools" are SQL functions and the semantic view; Claude Code's
  tools are arbitrary Python/MCP.
- **Embeddings + retrieval**: `EMBED_TEXT_1024` + Cortex Search ≈ what you'd
  hand-roll with `pgvector` + a retrieval tool in an Agent SDK setup.
- **Prompt templating**: Cortex puts prompts in SQL UDFs; Agent SDK puts
  them in Python — both are versionable artifacts, both belong in git.

## Where they differ (and why it matters for The Zebra)

1. **Governance gravity.** An insurtech has PII (drivers, VINs, claims).
   Cortex executes under the caller's role, honors masking policies and row
   access policies — the LLM literally cannot see what the role can't.
   Claude Code calling out has to rebuild that boundary in the tool layer.
2. **Determinism on metrics.** Cortex Analyst + a semantic view gives a
   reproducible, grain-correct SQL for "what's the bind rate by state?".
   A free-form Claude tool will sometimes invent a join. The JD is explicit
   about this — they want grain/dedup respected.
3. **Cost shape.** Cortex bulk inference (millions of rows) is cheap and
   parallel because it's collocated with the data. Pulling rows out to call
   an OpenAI/Anthropic endpoint pays egress + per-row latency.
4. **Loop length.** Claude Code is built for long, multi-step agent loops
   with file editing and MCP. Cortex calls are single-shot (stateless). For
   a multi-step plan you need an outside orchestrator — Dagster/Prefect
   (offline) or a FastAPI agent on K8s (online).

## How to combine them in the platform you'd build at The Zebra

```
                 ┌────────────────────── Anthropic / OpenAI ────────────┐
                 │                                                       │
                 ▼                                                       │
  user ─▶ FastAPI agent (K8s)        tool: cortex_search(query, k) ──▶ Snowflake
            │  • prompt framework    tool: cortex_analyst(question) ──▶ Snowflake
            │  • MCP registry        tool: run_governed_sql(sql)    ──▶ Snowflake
            │  • guardrails / PII
            │
            ├─▶ Kafka topic "agent.events"
            │       └─▶ Dagster sensor ─▶ asset: bulk_summarize_quotes
            │                              SELECT … CORTEX.COMPLETE(...)
            │
            └─▶ feedback loop: traces + ratings → Snowflake table
                              → weekly review → update prompts / verified queries
```

**Heuristic for "which surface?":**
- One row, conversational, multi-step → **FastAPI agent** (Anthropic) calling
  Cortex tools.
- Millions of rows, batch, no human in the loop → **SQL with Cortex
  functions** orchestrated by Dagster.
- "Show me X by Y" governed analytics → **Cortex Analyst** on a semantic
  view, surfaced as a tool to the agent.
- PDF/claims ingest → **Document AI** in Snowflake, then standard SQL
  pipeline.

## Sound-bite for the interview

> *"I think of Cortex as the data-plane AI runtime and Claude/OpenAI behind
> FastAPI as the control-plane agent runtime. The semantic view + dbt graph
> is the contract between them — it's where business meaning lives, and it's
> what stops an LLM from inventing a join. The agent layer brings memory,
> multi-step orchestration and tool fan-out; Cortex brings governance,
> bulk inference and grain-correct retrieval."*
