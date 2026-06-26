---
name: databricks-synthetic-data-gen
description: "Generate realistic synthetic data using Spark + Faker (strongly recommended). Supports serverless execution, multiple output formats (Parquet/JSON/CSV/Delta), and scales from thousands to millions of rows. For small datasets (<10K rows), can optionally generate locally and upload to volumes. Use when user mentions 'synthetic data', 'test data', 'generate data', 'demo dataset', 'Faker', or 'sample data'."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

> Catalog and schema are **always user-supplied** — never default to any value. If the user hasn't provided them, ask. For any UC write, **always create the schema if it doesn't exist** before writing data.

# Databricks Synthetic Data Generation

Generate realistic, story-driven synthetic data for Databricks using **Spark + Faker + Pandas UDFs** (strongly recommended).

## Data Must Tell a Business Story

Synthetic data should demonstrate how Databricks helps solve real business problems.

**The pattern:** Something goes wrong → business impact ($) → analyze root cause → identify affected customers → fix and prevent.

**Key principles:**
- **Problem → Impact → Analysis → Solution** — Include an incident, anomaly, or issue that causes measurable business impact. The data lets you find the root cause and act on it.
- **Industry-relevant but simple** — Use domain terms (e.g., "SLA breach", "churn", "stockout") but keep the schema easy to understand. A few tables, clear relationships.
- **Business metrics with $ impact** — Revenue, MRR, cost, conversion rate. Every story needs a dollar sign to show why it matters.
- **Tables explain each other** — Ticket spike? Incident table shows the outage. Revenue drop? Churn table shows who left and why. All data connects.
- **Actionable insights** — Data should answer: What happened? Who's affected? How much did it cost? How do we prevent it?

**Why no flat distributions:** Uniform data has no story — no spikes, no anomalies, no cohort, no 20/80, no skew, nothing to investigate. It can't show Databricks' value for root cause analysis.

## References

| When | Guide |
|------|-------|
| User mentions **ML model training** or complex time patterns | [references/1-data-patterns.md](references/1-data-patterns.md) — ML-ready data, time multipliers, row coherence |
| Errors during generation | [references/2-troubleshooting.md](references/2-troubleshooting.md) — Fixing common issues |

## Critical Rules

1. **Data tells a story** — Something goes wrong, impacts $, can be analyzed and fixed. Show Databricks value.
2. **All data serves the story** — Every table and column must be coherent and usable in dashboards or ML models. No orphan data, no random noise — if it doesn't help explain or plot a futur dashboard or predict, don't generate it.
3. **Industry terms, simple schema** — Use domain-specific vocabulary but keep it easy to understand (few tables, clear relationships)
4. **Never uniform distributions** — Skewed categories, log-normal amounts, 80/20 patterns. Flat = no story = useless
5. **Enough data for trends** — ~100K+ rows for main tables so patterns survive aggregation
6. **Ask for catalog/schema** — Never default, always confirm before generating
7. **Present plan for approval** — Show tables, distributions, assumptions before writing code
8. **Master tables first** — Generate parent tables, write to Delta, then create children with valid FKs
9. **Use Spark + Faker + Pandas UDFs** — Scalable, parallel. Polars only if user explicitly wants local + <30K rows
10. **Use Databricks Connect Serverless by default to generate data** — Update databricks-connect on python 3.12 if required (avoid using execute_code unless instructed to not use Databricks Connect)
11. **No `.cache()` or `.persist()`** — Not supported on serverless. Write to Delta, read back for joins
12. **No Python loops or `.collect()`** — Use Spark parallelism. No driver-side iteration, avoid Pandas↔Spark conversions


## Reference Files

- [workflow-and-patterns.md](workflow-and-patterns.md) - Generation planning workflow, Databricks Connect + Faker pattern, performance rules, common patterns (FK joins, write-back).

## Setup

Requires Python 3.12 and databricks-connect>=16.4. Use `uv`:

```bash
uv pip install "databricks-connect>=16.4,<17.4" faker numpy pandas holidays
```

## Related Skills

- **databricks-unity-catalog** — Managing catalogs, schemas, and volumes
- **databricks-bundles** — DABs for production deployment

## Common Issues

| Issue | Solution |
|-------|----------|
| `ImportError: cannot import name 'DatabricksEnv'` | Upgrade: `uv pip install "databricks-connect>=16.4"` |
| Python 3.11 instead of 3.12 | Python 3.12 required. Use `uv` to create env with correct version |
| `ModuleNotFoundError: faker` | Add to `withDependencies()`, import inside UDF |
| Faker UDF is slow | Use `pandas_udf` for batch processing |
| Out of memory | Increase `numPartitions` in `spark.range()` |
| Referential integrity errors | Write master table to Delta first, read back for FK joins |
| `PERSIST TABLE is not supported on serverless` | **NEVER use `.cache()` or `.persist()` with serverless** - write to Delta table first, then read back |
| `F.window` vs `Window` confusion | Use `from pyspark.sql.window import Window` for `row_number()`, `rank()`, etc. `F.window` is for streaming only. |
| Broadcast variables not supported | **NEVER use `spark.sparkContext.broadcast()` with serverless** |

See [references/2-troubleshooting.md](references/2-troubleshooting.md) for full troubleshooting guide.
