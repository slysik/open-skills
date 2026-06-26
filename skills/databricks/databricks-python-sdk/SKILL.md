---
name: databricks-python-sdk
description: "Databricks development guidance including Python SDK, Databricks Connect, CLI, and REST API. Use when working with databricks-sdk, databricks-connect, or Databricks APIs."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# Databricks Development Guide

Guidance for the Databricks **Python SDK**, **Databricks Connect**, **CLI**, and
**REST API**. Router: deep method signatures live in `references/`.

- SDK docs: https://databricks-sdk-py.readthedocs.io/en/latest/
- GitHub: https://github.com/databricks/databricks-sdk-py

## Environment setup
- Use `.venv` or `uv` for the virtualenv.
- Spark ops: `uv pip install databricks-connect` · SDK ops: `uv pip install databricks-sdk`.
- Databricks CLI ≥ 0.278.0.
- Config: profile `DEFAULT` in `~/.databrickscfg`; env `DATABRICKS_HOST`, `DATABRICKS_TOKEN`.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/api-reference.md](references/api-reference.md) | Exact method signatures: auth, REST/CLI, SDK doc architecture, and the per-service Core API (clusters, jobs, SQL, warehouses, UC tables/catalogs/schemas, volumes, files, serving, vector search, pipelines, secrets, dbutils) + quick-ref links. |
| [references/patterns.md](references/patterns.md) | **CRITICAL for async apps** (FastAPI/asyncio must wrap SDK calls in `asyncio.to_thread`), long-running waits, pagination, error handling. |
| [examples/](examples/) | Runnable example scripts. |

## Databricks Connect (local Spark) — keep handy

```python
from databricks.connect import DatabricksSession
spark = DatabricksSession.builder.getOrCreate()                 # DEFAULT profile
spark = DatabricksSession.builder.profile("MY_PROFILE").getOrCreate()
df = spark.sql("SELECT * FROM catalog.schema.table"); df.show()
```

**IMPORTANT:** do NOT set `.master("local[*]")` — it breaks Databricks Connect.

## When uncertain about a method
1. Doc URL pattern: `…/workspace/{category}/{service}.html`
   (clusters→`compute/clusters`, jobs→`jobs/jobs`, tables→`catalog/tables`,
   warehouses→`sql/warehouses`, serving→`serving/serving_endpoints`).
2. Fetch and verify params/return types before answering.

## Related skills
- [databricks-config](../databricks-config/SKILL.md) — profile + auth setup
- [databricks-bundles](../databricks-bundles/SKILL.md) — deploy via DABs
- [databricks-jobs](../databricks-jobs/SKILL.md) — job orchestration
- [databricks-unity-catalog](../databricks-unity-catalog/SKILL.md) — catalog governance
- [databricks-model-serving](../databricks-model-serving/SKILL.md) — serving endpoints
- [databricks-vector-search](../databricks-vector-search/SKILL.md) — vector indexes
- [databricks-lakebase-provisioned](../databricks-lakebase-provisioned/SKILL.md) — managed PostgreSQL
