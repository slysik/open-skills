# The Zebra / Insight Global — Agentic Platform Architect

Tomorrow's interview prep. Goal: sound like the 75% implementer / 25%
coordinator they describe, with concrete code to back it up.

---

## The headline question

> *"Design agentic AI experiences using frameworks such as LangChain,
> Semantic Kernel, and AutoGen including multi-agent orchestration,
> tool/function calling, memory management, and feedback loops."*

### 60-second answer (memorize this shape)

> "I treat 'agentic experience' as a four-layer design problem: **task
> decomposition, tool surface, memory, and feedback**. The framework —
> LangChain, Semantic Kernel, AutoGen, or the Anthropic Agent SDK — is
> mostly an opinion about how those layers compose, so I pick based on
> stack fit, not brand. For a data org like The Zebra's, I'd anchor the
> agent runtime in **FastAPI on Kubernetes**, push long-running
> orchestration to **Dagster/Prefect**, use **Kafka** as the event spine
> between agents and tools, and ground every data interaction in a
> **Snowflake Cortex semantic view** so generated SQL respects grain and
> dedup. I've built this exact pattern at smaller scale — let me walk
> through it."

Then pivot into the four layers using your codebase as proof points.

---

### Layer 1 — Multi-agent orchestration (roles & coordination)

**Talking point:** *"Single-agent systems hit a context-window and
attention wall. The fix is role specialization with explicit handoffs."*

**Proof from this repo — `apps/custom_7_micro_sdlc_agent`:**
- Three specialized agents — **Planner → Builder → Reviewer** — coordinated
  by a kanban state machine (Idle → Plan → Build → Review →
  Shipped/Errored → Archived).
- Each agent has a narrow system prompt, its own session id, and writes
  artifacts to disk (`plans/`, `reviews/`) so the next agent's context is
  small and verifiable.
- WebSocket streaming of tool calls + token counts per phase = built-in
  observability.

**Mapping to LangChain / SK / AutoGen vocabulary:**
- LangChain LangGraph → my kanban state machine is exactly a state graph
  with conditional edges. I implemented it as a SQLite-backed FSM because
  it's simpler to reason about and debug.
- AutoGen GroupChat → my Planner/Builder/Reviewer is the same idea
  (specialist agents, deterministic handoff). I use deterministic
  transitions instead of a "manager" LLM because for SDLC the order is
  known — saves tokens and removes a failure mode.
- Semantic Kernel Planners → equivalent to my Planner agent, but I prefer
  emitting an explicit plan artifact (markdown) so a human can edit before
  Build runs. That **is** the human-in-the-loop control the JD asks for.

**Coordination patterns I'd bring to The Zebra:**
1. **Deterministic when possible, LLM-routed when not.** State machines for
   known flows (claims triage, quote enrichment); supervisor pattern only
   when next-step is genuinely uncertain.
2. **Escalation paths as first-class transitions** — every agent has a
   `needs_human` exit. The kanban "Errored" lane is the escalation.
3. **Kafka topics as the bus** — agents publish `agent.event.*`; Dagster
   sensors and other agents subscribe. Replayable, audit-friendly, and
   lets you fan out one event to N agents without point-to-point coupling.

---

### Layer 2 — Tool / function calling

**Talking point:** *"The tool surface is where governance lives. A loose
tool surface is how LLMs leak data and write bad SQL."*

**Proof from this repo:**
- `apps/custom_2_echo_agent` and `custom_3_calc_agent` — minimal custom
  tools registered through the Agent SDK with `allowed_tools` /
  `disallowed_tools` allowlists. That allowlist pattern is the seed of a
  platform-wide guardrail framework.
- `apps/custom_5_qa_agent` — read-only tool surface (no edit tools), plus
  optional MCP integration (Firecrawl). Demonstrates **MCP as a
  standardized AI service interface** — which the JD calls out as
  impressive ("Model Context Protocol–style services").
- `apps/custom_8_ultra_stream_agent` — Stream agent + Inspector agent share
  a SQLite log store; tools are scoped per role.

**At The Zebra I'd standardize:**
- An internal **tool registry** (one repo, Pydantic schemas, semver'd) so
  every team's agent picks tools from the same catalog. This is the
  "reusable AI accelerators / platform components" deliverable.
- For Snowflake, the standard tools are `cortex_search(service, query, k)`,
  `cortex_analyst(semantic_view, question)`, and `run_governed_sql(sql)`
  — each authenticates as the calling user's Snowflake role so RBAC and
  masking apply automatically. The LLM literally cannot exfiltrate data a
  human couldn't.
- An MCP server in front of the registry so any agent runtime
  (LangChain/SK/AutoGen/Agent SDK) consumes the same surface.

---

### Layer 3 — Memory management

**Talking point:** *"There are four kinds of memory and people conflate
them: session, episodic, semantic, and procedural."*

| Memory | What | Where I put it |
|---|---|---|
| Session | Current conversation | SDK `resume` / LangChain `MessagesState` |
| Episodic | Past runs, ratings, traces | Snowflake table `AI_PROD.OBS.AGENT_TRACES` |
| Semantic | Facts about the business | Cortex Search service over a curated KB |
| Procedural | "How we do things" | Prompt UDFs + system-prompt fragments in a registry |

**Proof from this repo:**
- `custom_3_calc_agent` shows session continuity via `resume` — that's
  Memory 1.
- `custom_7_micro_sdlc_agent` persists tickets, plans, reviews to SQLite —
  that's Memory 2 at toy scale; production version is a Snowflake table
  with a `query_tag` join key back to `ACCOUNT_USAGE.QUERY_HISTORY` for
  cost attribution.
- `custom_8_ultra_stream_agent`'s Inspector queries the persisted log
  store with NL — that's the read path for episodic memory and a preview
  of how a Cortex-Analyst-backed "ask your traces" tool would feel.

**Token efficiency angle (the JD calls this out):**
- Summarize-and-forget: roll old turns into a 200-token recap before each
  new turn (pattern used in `ultra_stream_agent`'s context-window
  management).
- Retrieve-not-stuff: keep system prompt small, pull semantic memory only
  when a tool says it's relevant.
- Cache embeddings keyed by content hash; never re-embed.

---

### Layer 4 — Feedback loops

**Talking point:** *"An agent platform without a feedback loop decays.
Every production trace is a free training/eval signal — capture it or
you're flying blind."*

**The loop I'd build at The Zebra:**

```
agent run ─▶ Kafka topic "agent.trace"
                 │
                 ▼
            Dagster asset (Prefect flow)
                 │  • parse trace
                 │  • Cortex CLASSIFY_TEXT for failure mode
                 │  • Cortex SUMMARIZE for short reason
                 ▼
        Snowflake AI_PROD.OBS.AGENT_TRACES
                 │
                 ├─▶ weekly review dashboard (BI)
                 ├─▶ regression eval set (golden Q&A vs Cortex Analyst)
                 └─▶ prompt-optimizer job: bad traces → updated prompt UDF
```

**Proof from this repo:**
- `custom_4_social_hype_agent` and `custom_8_ultra_stream_agent` already
  ingest streams and classify with an LLM — same pattern, just pointed
  inward at agent telemetry.
- Cost tracking + session metadata across `custom_3`, `6`, `7`, `8` shows
  I instrument from day one.

**Human-in-the-loop:**
- Kanban lanes (`custom_7`) are the simple HITL UI — humans can move a
  ticket from Build back to Plan. Same pattern for claims triage: an
  agent proposes, a human approves before bind.
- Thumbs-up/down on every agent response → row in `AGENT_FEEDBACK` →
  drives the prompt-optimizer (this is what Foundry's prompt optimizer
  does too; my `microsoft-foundry` skill has the analog).

---

## Framework opinions (use only if asked)

- **LangChain / LangGraph**: best for fast prototyping; LangGraph is the
  right primitive for stateful multi-agent. Watch out for abstraction
  churn — pin versions.
- **Semantic Kernel**: shines in .NET shops and where you want planners +
  skills as first-class. For a Python-first data org I'd lean LangGraph
  or the Anthropic Agent SDK.
- **AutoGen**: best when the orchestration genuinely needs LLM-routed
  conversation between agents. For deterministic SDLC-style flows it's
  overkill.
- **Anthropic Agent SDK / Claude Code**: what I've been building on
  recently — minimal abstraction, MCP-native, great for tool-heavy
  workflows. Pairs well with Cortex tools.

The real answer is: *"frameworks are interchangeable; what matters is the
tool registry, semantic context layer, memory schema, and feedback
pipeline. Those are the platform."*

---

## Snowflake Cortex talking points (their stack)

The JD specifically names **Snowflake Cortex semantic views** and **dbt
graphs**. Be ready to:

1. **Define a semantic view** verbally — logical tables, relationships,
   metrics with explicit aggregation, synonyms, verified queries. See
   `../semantic-views/semantic-views.md` for the DDL you should be able to
   sketch on a whiteboard.
2. **Explain why Cortex Analyst beats free-form text-to-SQL** — grain
   correctness, RBAC inheritance, audit trail, verified queries.
3. **Compare Cortex Search to bringing-your-own vector DB** — managed
   hybrid retrieval, no separate infra, governance follows the data.
4. **Bulk inference economics** — `CORTEX.COMPLETE` row-wise on a
   warehouse vs. egressing rows to OpenAI; resource monitors per `WH_AI`;
   `QUERY_TAG` for per-agent cost attribution.
5. **Document AI** for ingesting policy PDFs and claims forms.

If they ask "have you used Cortex in production?" — be honest: *"I've
designed against it and I've built the equivalent pattern outside
Snowflake; here's exactly how I'd port it in,"* then sketch the architecture
from `../cortex-vs-claude-code.md`.

---

## STAR stories to have loaded

Pick 2-3 from below; rehearse in <2 min each.

1. **Multi-agent orchestration** — Planner/Builder/Reviewer (`custom_7`).
   *Situation:* needed to ship features faster without overloading a
   single agent's context. *Task:* design a multi-agent SDLC.
   *Action:* split roles, persist artifacts, kanban FSM, WebSocket
   telemetry. *Result:* clear handoffs, bounded context per agent,
   deterministic flow with human-in-the-loop.
2. **Streaming + classification feedback loop** — `custom_8`.
   Two agents, shared store, NL inspection — the prototype of an
   internal "ask your traces" tool.
3. **Tool surface design** — `custom_5_qa_agent` read-only + MCP. Talk
   about how that would scale to a tool registry exposed via MCP across
   all teams' agents.
4. **Production-shape web agent** — `custom_6_tri_copy_writer` and
   `custom_7` — Vue frontend + FastAPI backend with structured JSON
   responses, cost tracking, file context. That's the same shape as a
   FastAPI agent on K8s for The Zebra.

---

## Questions to ask them (signal seniority)

1. *"What's the current state of the Cortex semantic-view layer — is
   there a dbt-driven generation pattern already, or is that part of
   what this role builds?"*
2. *"Where does the agent runtime live today — is there a FastAPI
   service, or are agents running inside Dagster jobs? How do you see
   the split between online and offline agent work?"*
3. *"What's the current feedback-loop maturity — are agent traces
   landing in Snowflake yet, and is anyone closing the loop on prompt
   updates from production failures?"*
4. *"How is tool-surface governance handled across teams — is there a
   shared registry, or are teams defining tools ad-hoc?"*
5. *"On the 75/25 implementer/coordinator split — what does the first
   90 days look like? Which architectural investment do you think is
   highest leverage right now?"*
6. *"Insurance is regulated — how are PII boundaries enforced today on
   the AI side? Snowflake masking + role inheritance, or something at
   the app layer?"*

---

## Final reminders

- Lead with **"I've built this pattern"** then name the app folder.
- Always tie back to **grain, governance, cost, latency** — those four
  words map exactly to what the JD optimizes for.
- When you don't know something Cortex-specific, pivot to: *"I'd verify
  the exact syntax in docs, but the shape is X"* — then describe the
  shape. They want architects, not memorizers.
- The 75/25 framing means: when in doubt, give the implementation
  detail, not the meta.
