# Snowflake Cortex AI — Working Reference

Cortex AI is Snowflake's in-database AI surface. Four product pillars matter
for an agentic platform:

| Pillar | What it is | When to use |
|---|---|---|
| **Cortex LLM functions** | SQL functions that call hosted LLMs (Anthropic, Meta, Mistral, Snowflake Arctic). | Inline summarization, classification, extraction during a transform. |
| **Cortex Search** | Managed hybrid (vector + keyword) retrieval service over a Snowflake table. | Governed RAG without standing up Pinecone/Weaviate. |
| **Cortex Analyst** | Text-to-SQL service that reasons over a **semantic view** (YAML model). REST endpoint. | Natural-language Q&A over governed metrics. |
| **Document AI / AI_PARSE_DOCUMENT** | Layout-aware PDF/image → structured JSON. | Ingesting policy PDFs, claims forms. |

## 1. LLM functions — the workhorses

```sql
-- Generate / chat
SNOWFLAKE.CORTEX.COMPLETE(model, prompt_or_messages, options)

-- Task-specific (cheaper, prompt-tuned)
SNOWFLAKE.CORTEX.SUMMARIZE(text)
SNOWFLAKE.CORTEX.CLASSIFY_TEXT(text, ['auto','home','life'])
SNOWFLAKE.CORTEX.EXTRACT_ANSWER(question, source_text)
SNOWFLAKE.CORTEX.SENTIMENT(text)
SNOWFLAKE.CORTEX.TRANSLATE(text, 'en','es')

-- Embeddings
SNOWFLAKE.CORTEX.EMBED_TEXT_1024('snowflake-arctic-embed-l-v2.0', text)
```

**Model selection rule of thumb (2025):**

- `claude-3-5-sonnet` / `claude-4-sonnet` — production reasoning, tool-style outputs.
- `mistral-large2` — cheaper general purpose.
- `llama3.1-70b` / `llama3.3-70b` — open-weight fallback.
- `snowflake-arctic-embed-l-v2.0` — default embeddings (1024-dim, multilingual).

Cost note: Cortex bills **credits per million tokens** by model + warehouse
runtime for the SQL. Always pin a small warehouse for AI calls and let the
function do the heavy lift.

### Bulk / row-wise pattern

```sql
INSERT INTO MART_PROD.PUBLIC.POLICY_SUMMARIES
SELECT
  policy_id,
  AI_PROD.PROMPTS.SUMMARIZE_POLICY(full_text) AS summary,
  CURRENT_TIMESTAMP()
FROM STG_PROD.PUBLIC.POLICY_DOCS
WHERE summary IS NULL
LIMIT 5000;   -- batch to control credit burn
```

Wrap in a Dagster/Prefect asset; chunk by `LIMIT` + watermark; alert on
token-spend per asset.

## 2. Cortex Search — managed RAG

```sql
-- Build the index (re-syncs from base table)
CREATE OR REPLACE CORTEX SEARCH SERVICE AI_PROD.SEARCH.POLICY_KB
  ON content                              -- text column
  ATTRIBUTES policy_id, state, product    -- filter facets
  WAREHOUSE = WH_AI
  TARGET_LAG = '1 hour'
AS (
  SELECT policy_id, state, product, content
  FROM MART_PROD.PUBLIC.POLICY_CHUNKS
);

-- Query (hybrid search, returns scored rows)
SELECT * FROM TABLE(
  AI_PROD.SEARCH.POLICY_KB!SEARCH(
    'cancellation refund window in Texas', 5,
    {'filter': {'@eq': {'state':'TX'}}}
  )
);
```

Surface to an agent as a **tool**: a FastAPI route or MCP tool that wraps the
SEARCH call and returns top-k passages with citations.

## 3. Cortex Analyst — governed text-to-SQL

Cortex Analyst answers natural-language questions by generating SQL **only
against a semantic view** you've declared (YAML or `CREATE SEMANTIC VIEW`
DDL). This is the antidote to "LLM writes hallucinated SQL".

Endpoint: `POST https://<account>.snowflakecomputing.com/api/v2/cortex/analyst/message`

Body:
```json
{
  "messages":[{"role":"user","content":[{"type":"text","text":"avg premium by state last 30d"}]}],
  "semantic_view":"AI_PROD.SEMANTIC.QUOTES_SV"
}
```

Response includes generated SQL + suggested follow-ups. Your FastAPI service
runs the SQL with the calling user's role for row-level security.

See [../semantic-views/semantic-views.md](../semantic-views/semantic-views.md)
for how to design the semantic view so the JD's "respect data grain,
deduplication, business semantics" requirement is met.

## 4. Document AI / AI_PARSE_DOCUMENT

```sql
SELECT AI_PARSE_DOCUMENT(
  TO_FILE('@RAW_PROD.PUBLIC.LANDING','policy_2024.pdf'),
  {'mode':'LAYOUT'}
):content::STRING AS extracted;
```

For trained extraction models, use the Document AI UI to define a model from
a few labeled PDFs, then call:
```sql
SELECT POLICY_EXTRACT!PREDICT(TO_FILE('@stage','file.pdf'));
```

## 5. Guardrails & cost controls

- `SNOWFLAKE.CORTEX.CLASSIFY_TEXT` for **input** routing (toxic/PII/off-topic).
- Resource monitors per `WH_AI` with hard suspend at credit threshold.
- `QUERY_TAG` per agent invocation: `ALTER SESSION SET QUERY_TAG='agent=triage,run=...'`
  → easy attribution in `ACCOUNT_USAGE.QUERY_HISTORY` for cost dashboards.
- Cache embeddings — never re-embed the same chunk hash.

## 6. Calling Cortex from the FastAPI / Anthropic agent layer

Two integration shapes:

1. **SQL tool**: Anthropic tool-use → Python tool runs a parameterized SQL
   that calls Cortex (e.g., `CORTEX_SEARCH_POLICY_KB(query, k)`). Cleanest
   governance — RBAC enforced by Snowflake.
2. **REST tool**: Anthropic tool-use → call Cortex Analyst REST endpoint;
   return the generated SQL + the executed result.

Pattern in this codebase already uses the same shape — see
`apps/custom_5_qa_agent` and `apps/custom_7_micro_sdlc_agent`: tools are thin
wrappers; the model decides when to call them.
