# Semantic Views + dbt Graph as the Context Layer

The Zebra JD: *"leveraging dbt graphs and Snowflake Cortex semantic views… to
ensure AI-generated outputs respect data grain, deduplication, and business
semantics."* This is the **context layer**. Without it, an LLM writing SQL
will fan-out joins and double-count premiums.

## What a Cortex semantic view is

A first-class Snowflake object (`CREATE SEMANTIC VIEW`) that declares:
- **Logical tables** (with primary keys → grain)
- **Relationships** (FK joins → blocks accidental fan-outs)
- **Dimensions** (with synonyms, descriptions)
- **Metrics** (with explicit aggregation: SUM/COUNT_DISTINCT/etc.)
- **Filters / verified queries**

Cortex Analyst is constrained to only generate SQL against this object, so
the LLM cannot invent a join path that breaks grain.

## Minimal example (insurance quotes)

```sql
CREATE OR REPLACE SEMANTIC VIEW AI_PROD.SEMANTIC.QUOTES_SV
  TABLES (
    QUOTES    AS MART_PROD.PUBLIC.FCT_QUOTES    PRIMARY KEY (quote_id),
    DRIVERS   AS MART_PROD.PUBLIC.DIM_DRIVERS   PRIMARY KEY (driver_id),
    STATES    AS MART_PROD.PUBLIC.DIM_STATES    PRIMARY KEY (state_code)
  )
  RELATIONSHIPS (
    QUOTES (driver_id)  REFERENCES DRIVERS (driver_id),
    QUOTES (state_code) REFERENCES STATES  (state_code)
  )
  DIMENSIONS (
    DRIVERS.age_band       WITH SYNONYMS ('age group','driver age')
                           COMMENT = 'Bucketed driver age',
    STATES.region          WITH SYNONYMS ('region','area'),
    QUOTES.product         WITH SYNONYMS ('line of business','LOB')
  )
  METRICS (
    QUOTES.quote_count          AS COUNT(DISTINCT quote_id)
                                COMMENT = 'Distinct quotes; never SUM rows',
    QUOTES.avg_premium_usd      AS AVG(premium_cents)/100,
    QUOTES.bound_rate           AS COUNT_IF(is_bound)
                                   / NULLIF(COUNT(DISTINCT quote_id),0)
                                COMMENT = 'Bind / quote ratio'
  )
  COMMENT = 'Governed view for quote analytics. Grain = quote_id.';
```

Now `Cortex Analyst` answering *"average premium by region last 30 days"*
will produce SQL that joins on declared FKs and aggregates with the declared
metric expression — grain preserved by construction.

## Pairing with dbt

dbt is where the **upstream graph** is governed. Pattern:

1. dbt builds `fct_quotes`, `dim_drivers`, `dim_states` with tested PKs and
   `unique`/`not_null` tests — this is the dedup contract.
2. A dbt model emits the `CREATE SEMANTIC VIEW` SQL (templated from
   `schema.yml` `meta:` blocks: synonyms, descriptions, metric formulas).
3. CI: a dbt test queries `Cortex Analyst` with a fixed set of NL questions
   and asserts the generated SQL + numbers match a golden set. Regression =
   broken context layer.

This is the "feedback loop" the JD wants: production NL questions get logged,
periodically reviewed, and either (a) added as **verified queries** in the
semantic view or (b) reveal a missing dimension/metric to add.

## Synonyms drive recall

Insurance has heavy jargon: "premium", "rate", "binder", "endorsement",
"down-payment". Capture all of these in `WITH SYNONYMS (...)` — Analyst uses
them for matching the user phrase to a metric. This is the single highest-ROI
lever for accuracy.

## Verified queries

```sql
ALTER SEMANTIC VIEW AI_PROD.SEMANTIC.QUOTES_SV
  ADD VERIFIED QUERY 'bind rate last 30 days by state'
  USING $$
    SELECT s.state_code, q.bound_rate
    FROM SEMANTIC_VIEW(AI_PROD.SEMANTIC.QUOTES_SV
         METRICS q.bound_rate
         DIMENSIONS s.state_code)
    WHERE q.created_at > DATEADD(day,-30,CURRENT_DATE);
  $$;
```

Verified queries are returned verbatim by Analyst when the user asks a
matching question — zero hallucination, low latency, audit-friendly.
