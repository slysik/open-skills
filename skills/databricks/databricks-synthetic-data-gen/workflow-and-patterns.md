# Synthetic Data — Generation Workflow & Patterns

> Detail moved out of the router. Router: SKILL.md

## Generation Planning Workflow

**Before generating any code, you MUST present a plan for user approval.**

### ⚠️ MUST DO: Confirm Catalog Before Proceeding

**You MUST explicitly ask the user which catalog to use.** Do not assume or proceed without confirmation.

Example prompt to user:
> "Which Unity Catalog should I use for this data?"

When presenting your plan, always show the selected catalog prominently:
```
📍 Output Location: catalog_name.schema_name
   Volume: /Volumes/catalog_name/schema_name/raw_data/
```

This makes it easy for the user to spot and correct if needed.

### Step 1: Gather Requirements

Ask the user about:
- **Catalog/Schema** — Which catalog to use?
- **Domain** — E-commerce, support tickets, IoT, financial? (Use industry terms)

**If user doesn't specify a story:** Propose one. Don't generate bland data — suggest an incident, anomaly, or trend that shows Databricks value (e.g., "I'll include a system outage that causes ticket spike and churn — this lets you demo root cause analysis").

### Step 2: Present Plan with Story

Show a clear specification with **the business story and your assumptions surfaced**:

```
📍 Output Location: {user_catalog}.support_demo
   Volume: /Volumes/{user_catalog}/support_demo/raw_data/

📖 Story: A payment system outage causes support ticket spike. Resolution times
   degrade, enterprise customers churn, revenue drops $2.3M. With Databricks we
   identify the root cause, affected customers, and prevent future impact.
```

| Table | Description | Rows | Key Assumptions |
|-------|-------------|------|-----------------|
| customers | Customer profiles with tier, MRR | 10,000 | Enterprise 10% but 60% of revenue |
| tickets | Support tickets with priority, resolution_time | 80,000 | Spike during outage, SLA breaches |
| incidents | System events (outages, deployments) | 50 | Payment outage mid-month |
| churn_events | Customer cancellations with reason | 500 | Spike after poor support experience |

**Business metrics:**
- `customers.mrr` — Revenue at risk ($)
- `tickets.resolution_hours` — SLA performance
- `churn_events.lost_mrr` — Churn impact ($)

**The story this data tells:**
- Incident table shows payment outage on March 15
- Tickets spike 5x during outage, resolution time degrades from 4h → 18h
- Enterprise customers with SLA breaches churn 3 weeks later
- Total impact: $2.3M lost MRR, traceable to one incident
- **Databricks value:** Root cause analysis, identify at-risk customers, build alerting

**Ask user**: "Does this story work? Any adjustments?"

### Step 3: Ask About Data Features

- [x] Skew (non-uniform distributions) - **Enabled by default**
- [x] Joins (referential integrity) - **Enabled by default**
- [ ] Bad data injection (for data quality testing)
- [ ] Multi-language text
- [ ] Incremental mode (append instead of overwrite)

### Pre-Generation Checklist

- [ ] **Catalog confirmed** - User explicitly approved which catalog to use
- [ ] Output location shown prominently in plan (easy to spot/change)
- [ ] Table specification shown and approved
- [ ] Assumptions about distributions confirmed
- [ ] User confirmed compute preference (Databricks Connect on serverless recommended)
- [ ] Data features selected

**Do NOT proceed to code generation until user approves the plan, including the catalog.**

### Post-Generation Checklist

After generating data, use `get_volume_folder_details` to validate the output matches requirements:
- Row counts match the plan
- Schema matches expected columns and types
- Data distributions look reasonable (check column stats)

## Use Databricks Connect Spark + Faker Pattern 

```python
from databricks.connect import DatabricksSession, DatabricksEnv
from pyspark.sql import functions as F
from pyspark.sql.types import StringType
import pandas as pd

# Setup serverless with dependencies (MUST list all libs used in UDFs)
env = DatabricksEnv().withDependencies("faker", "holidays")
spark = DatabricksSession.builder.withEnvironment(env).serverless(True).getOrCreate()

# Pandas UDF pattern - import lib INSIDE the function
@F.pandas_udf(StringType())
def fake_name(ids: pd.Series) -> pd.Series:
    from faker import Faker  # Import inside UDF
    fake = Faker()
    return pd.Series([fake.name() for _ in range(len(ids))])

# Generate with spark.range, apply UDFs
customers_df = spark.range(0, 10000, numPartitions=16).select(
    F.concat(F.lit("CUST-"), F.lpad(F.col("id").cast("string"), 5, "0")).alias("customer_id"),
    fake_name(F.col("id")).alias("name"),
)

# Write to Volume as Parquet (default for raw data)
# Path is a folder with table name: /Volumes/catalog/schema/raw_data/customers/
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{SCHEMA}")
spark.sql(f"CREATE VOLUME IF NOT EXISTS {CATALOG}.{SCHEMA}.raw_data")
customers_df.write.mode("overwrite").parquet(f"/Volumes/{CATALOG}/{SCHEMA}/raw_data/customers")
```

**Partitions by scale:** `spark.range(N, numPartitions=P)`
- <100K rows: 8 partitions
- 100K-500K: 16 partitions
- 500K-1M: 32 partitions
- 1M+: 64+ partitions

**Output formats:**
- **Parquet to Volume** (default): `df.write.parquet("/Volumes/.../raw_data/table")` — raw data for pipelines
- **Delta Table**: `df.write.saveAsTable("catalog.schema.table")` — if user wants queryable tables
- **JSON/CSV**: small dimension tables, replicate legacy systems

## Performance Rules

Generated scripts must be highly performant. **Never** do these:

| Anti-Pattern | Why It's Slow | Do This Instead |
|--------------|---------------|-----------------|
| Python loops on driver | Single-threaded, no parallelism | Use `spark.range()` + Spark operations |
| `.collect()` then iterate | Brings all data to driver memory | Keep data in Spark, use DataFrame ops |
| Pandas → Spark → Pandas | Serialization overhead, defeats distribution | Stay in Spark, use `pandas_udf` only for UDFs |
| Read/write temp files | Unnecessary I/O | Chain DataFrame transformations |
| Scalar UDFs | Row-by-row processing | Use `pandas_udf` for batch processing |

**Good pattern:** `spark.range()` → Spark transforms → `pandas_udf` for Faker → write directly

## Common Patterns

### Weighted Categories (never uniform)
```python
F.when(F.rand() < 0.6, "Free").when(F.rand() < 0.9, "Pro").otherwise("Enterprise")
```

### Log-Normal Amounts (in a pandas UDF)
Use `np.random.lognormal(mean, sigma)` — always positive, long tail:
- Enterprise: `lognormal(7.5, 0.8)` → ~$1800 median
- Pro: `lognormal(5.5, 0.7)` → ~$245 median
- Free: `lognormal(4.0, 0.6)` → ~$55 median

### Date Range (Last 6 Months)
```python
END_DATE = datetime.now()
START_DATE = END_DATE - timedelta(days=180)
```

### Infrastructure (always create in script)
```python
spark.sql(f"CREATE SCHEMA IF NOT EXISTS {CATALOG}.{SCHEMA}")
spark.sql(f"CREATE VOLUME IF NOT EXISTS {CATALOG}.{SCHEMA}.raw_data")
```

### Referential Integrity (FK pattern)
Write master table to Delta first, then read back for FK joins (no `.cache()` on serverless):
```python
# 1. Write master table
customers_df.write.mode("overwrite").saveAsTable(f"{CATALOG}.{SCHEMA}.customers")

# 2. Read back for FK lookup
customer_lookup = spark.table(f"{CATALOG}.{SCHEMA}.customers").select("customer_idx", "customer_id")

# 3. Generate child table with valid FKs via join
orders_df = spark.range(N_ORDERS).select(
    (F.abs(F.hash(F.col("id"))) % N_CUSTOMERS).alias("customer_idx")
)
orders_with_fk = orders_df.join(customer_lookup, on="customer_idx")
```

