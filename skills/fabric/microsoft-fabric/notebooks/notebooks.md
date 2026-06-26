# Microsoft Fabric — Python / PySpark Notebooks

Notebooks are the transformation engine that sits between bronze and gold.
Pipelines orchestrate; notebooks reshape. This doc covers the patterns a
Senior Fabric Data Engineer is expected to know cold.

## 1. The Fabric notebook execution model

- A notebook runs on a **Spark session** attached to the workspace's
  **Spark pool** (default or custom). First cell triggers session start
  (~30–60 s); subsequent cells share the session.
- Languages per cell: PySpark (default), SparkSQL (`%%sql`), Scala
  (`%%spark`), SparkR (`%%sparkr`), and "pure" Python via `%%pyspark` with
  no Spark calls (still uses the executor for execution).
- Notebooks access OneLake via the **`abfss://`** path or the friendly
  **table API** (`spark.read.table("lh_bronze.orders_raw")`) when a
  Lakehouse is attached.
- They are invoked from a pipeline via the **Notebook activity**, which
  passes parameters through `mssparkutils.notebook.exit()` /
  `mssparkutils.notebook.run()`.

## 2. The four-cell notebook contract

Every production notebook in the team should start with the same four cells.
This is what code review enforces.

### Cell 1 — Parameters (tagged `parameters`)
```python
# parameters
p_source_system = "erp"
p_table         = "orders"
p_run_date      = "2026-05-20"
p_run_id        = "manual-dev"
p_environment   = "dev"
```
Tag the cell with `parameters` (Edit → Cell properties → Tags). The pipeline's
Notebook activity injects values by **overriding** this cell.

### Cell 2 — Imports + Spark config
```python
from pyspark.sql import functions as F, types as T, Window
from delta.tables import DeltaTable
import json, hashlib, datetime as dt

spark.conf.set("spark.sql.session.timeZone", "UTC")
spark.conf.set("spark.databricks.delta.schema.autoMerge.enabled", "true")
spark.conf.set("spark.sql.shuffle.partitions", "200")
```

### Cell 3 — Helper functions (logging + DQ)
```python
def log_event(stage, status, rows=None, error=None):
    spark.sql(f"""
      INSERT INTO lh_ops.dbo.notebook_events
      VALUES ('{p_run_id}', '{stage}', '{status}',
              {rows if rows is not None else 'NULL'},
              {"'"+error.replace("'", "''")+"'" if error else 'NULL'},
              current_timestamp())
    """)

def assert_unique(df, keys):
    dup = (df.groupBy(*keys).count().filter("count > 1").limit(1).count())
    if dup:
        raise ValueError(f"Duplicate keys in {keys}")
```

### Cell 4 — Main logic wrapped in try/except → `notebook.exit`
```python
try:
    # ... read, transform, write ...
    mssparkutils.notebook.exit(json.dumps({
        "status":  "Succeeded",
        "rows_in":  rows_in,
        "rows_out": rows_out
    }))
except Exception as e:
    log_event("main", "Failed", error=str(e))
    raise   # surface to the pipeline as a Failed activity
```

The pipeline reads the JSON via `@activity('Transform').output.exitValue`
and routes downstream activities accordingly.

## 3. Reading and writing OneLake

```python
# Friendly (Lakehouse attached to notebook)
df = spark.read.table("lh_bronze.orders_raw")

# Explicit ABFS path (no attachment needed; works cross-workspace)
df = (spark.read.format("delta").load(
        "abfss://ws-data-prod@onelake.dfs.fabric.microsoft.com/"
        "lh_bronze.Lakehouse/Tables/orders_raw"))

# Write with schema evolution + partitioning
(df.write.format("delta")
    .mode("append")
    .partitionBy("load_date")
    .option("mergeSchema", "true")
    .saveAsTable("lh_silver.orders"))
```

Cross-workspace reads: use the **OneLake shortcut** (Lakehouse → New
shortcut → OneLake) so the read looks local. Avoids hardcoding workspace
GUIDs in notebooks.

## 4. JSON parsing (a JD-stated requirement)

REST APIs land messy JSON in bronze. Three patterns by shape.

### 4.1 Flat JSON
```python
df = spark.read.json("abfss://.../bronze/Files/api_orders/2026-05-20/*.json")
df.printSchema()
df.select("order_id", "customer_id", "total", "currency").show()
```

### 4.2 Nested JSON — explode + dot-walk
```python
raw = spark.read.json(path)

orders = (raw
    .withColumn("line", F.explode("lines"))
    .select(
        F.col("order_id"),
        F.col("customer.id").alias("customer_id"),
        F.col("customer.email").alias("customer_email"),
        F.col("line.sku").alias("sku"),
        F.col("line.qty").cast("int").alias("qty"),
        F.col("line.price").cast("decimal(18,2)").alias("price"),
        F.to_timestamp("created_at").alias("created_at")))
```

### 4.3 Schema-on-read for stringified JSON columns
When the source column is a `string` containing JSON (common with Kafka /
Event Hubs landing into bronze):

```python
order_schema = T.StructType([
    T.StructField("order_id",    T.StringType()),
    T.StructField("customer_id", T.StringType()),
    T.StructField("lines",       T.ArrayType(T.StructType([
        T.StructField("sku",   T.StringType()),
        T.StructField("qty",   T.IntegerType()),
        T.StructField("price", T.DecimalType(18, 2))]))),
    T.StructField("created_at",  T.TimestampType())
])

parsed = (raw
    .withColumn("j", F.from_json("payload", order_schema))
    .select("j.*"))
```

### 4.4 Untyped / schema-drift JSON
For sources where new fields appear weekly, store as `MAP<STRING,STRING>`
in silver and project to gold:

```python
df = (raw.withColumn("kv", F.from_json("payload",
        T.MapType(T.StringType(), T.StringType())))
        .select("order_id", "kv"))

gold = (df
    .withColumn("status",   F.col("kv")["status"])
    .withColumn("region",   F.col("kv")["region"])
    .withColumn("amount",   F.col("kv")["amount"].cast("decimal(18,2)")))
```

## 5. Incremental loads — the three CDC patterns

### 5.1 Watermark (timestamp-based)
Best for sources with a reliable `modified_at`. Covered end-to-end in
[`../data-pipelines/data-pipelines.md`](../data-pipelines/data-pipelines.md) §4.
Notebook side just does the MERGE:

```python
src = spark.read.table("lh_bronze.orders_raw") \
        .filter(F.col("_ingest_run_id") == p_run_id)

tgt = DeltaTable.forName(spark, "lh_silver.orders")
(tgt.alias("t")
   .merge(src.alias("s"), "t.order_id = s.order_id")
   .whenMatchedUpdate(condition = "s.modified_at > t.modified_at",
                      set = {c: f"s.{c}" for c in src.columns})
   .whenNotMatchedInsertAll()
   .execute())
```

### 5.2 SQL Server Change Data Capture (CDC)
When the source has CDC enabled (`sys.sp_cdc_enable_table`), pull from the
CDC change tables, not the base table:

```sql
-- inside a Copy activity source query
DECLARE @from_lsn binary(10) = sys.fn_cdc_get_min_lsn('dbo_orders');
DECLARE @to_lsn   binary(10) = sys.fn_cdc_get_max_lsn();

SELECT  __$operation,        -- 1=delete, 2=insert, 3=update-before, 4=update-after
        __$start_lsn,
        __$seqval,
        order_id, customer_id, total, modified_at
FROM    cdc.fn_cdc_get_all_changes_dbo_orders(@from_lsn, @to_lsn, 'all');
```

Store the **LSN watermark** (binary, not timestamp) in `ctl.ingest_watermark`.
Notebook side handles the operation codes:

```python
cdc = spark.read.table("lh_bronze.orders_cdc") \
            .filter(F.col("_ingest_run_id") == p_run_id)

# Latest change per key
w = Window.partitionBy("order_id").orderBy(F.col("__$start_lsn").desc(),
                                           F.col("__$seqval").desc())
latest = (cdc.withColumn("rn", F.row_number().over(w))
              .filter("rn = 1"))

tgt = DeltaTable.forName(spark, "lh_silver.orders")
(tgt.alias("t")
   .merge(latest.alias("s"), "t.order_id = s.order_id")
   .whenMatchedDelete(condition = "s.`__$operation` = 1")
   .whenMatchedUpdate(condition = "s.`__$operation` IN (2,4)",
                      set = {"customer_id":"s.customer_id","total":"s.total",
                             "modified_at":"s.modified_at"})
   .whenNotMatchedInsert(condition = "s.`__$operation` IN (2,4)",
                         values = {"order_id":"s.order_id",
                                   "customer_id":"s.customer_id",
                                   "total":"s.total",
                                   "modified_at":"s.modified_at"})
   .execute())
```

### 5.3 Change Tracking (lightweight CDC alternative)
Lighter than CDC; use when you only need "what changed" not "the before image":

```sql
DECLARE @last_version bigint = <stored_in_ctl>;
SELECT  CT.SYS_CHANGE_OPERATION,        -- I/U/D
        CT.SYS_CHANGE_VERSION,
        T.order_id, T.customer_id, T.total
FROM    CHANGETABLE(CHANGES dbo.orders, @last_version) AS CT
LEFT JOIN dbo.orders T ON T.order_id = CT.order_id;
```

Watermark column is `CHANGE_TRACKING_CURRENT_VERSION()`.

### 5.4 Partition pruning (the speedup)
Silver/gold tables that get MERGEd should be partitioned by `load_date` (or
the natural time column the queries filter on). Then the MERGE only touches
the affected partitions:

```python
(df.write.format("delta")
   .mode("append")
   .partitionBy("load_date")
   .saveAsTable("lh_silver.orders"))

# MERGE that prunes
(tgt.alias("t")
   .merge(src.alias("s"),
          "t.order_id = s.order_id AND t.load_date >= date_sub(current_date(), 7)")
   .whenMatchedUpdateAll()
   .whenNotMatchedInsertAll()
   .execute())
```

`OPTIMIZE` + `ZORDER BY` weekly to keep file counts sane:
```sql
OPTIMIZE lh_silver.orders WHERE load_date >= current_date - INTERVAL 30 DAYS
  ZORDER BY (customer_id);
VACUUM lh_silver.orders RETAIN 168 HOURS;   -- 7 days; default safe value
```

## 6. SQL query optimization in the Warehouse

The JD calls out SQL optimization. Standard playbook in Fabric Warehouse
(MPP, distribution-aware):

1. **Statistics**: Fabric Warehouse auto-creates stats, but stale stats on
   high-churn fact tables hurt — `UPDATE STATISTICS dbo.fact_orders;` after
   large loads.
2. **Distribution-aware joins**: large fact-to-dim joins should hash on the
   join key on both sides; check `EXPLAIN` for `BROADCAST` vs `SHUFFLE`.
3. **Avoid SELECT \*** in views feeding semantic models — DirectLake reads
   only referenced columns when projection is explicit.
4. **Push predicates down** to Lakehouse / SQL endpoint, not into a CTE that
   the optimizer can't see through.
5. **Result-set caching** is automatic on the Warehouse; same query within
   the cache window returns instantly. Validate by re-running and checking
   `sys.dm_exec_requests` for `result_cache_hit`.
6. **Materialize hot aggregates** in gold as Delta tables, not as views over
   silver — DirectLake on a pre-aggregated table is the fastest BI path.

## 7. Calling notebooks from pipelines (the contract)

Pipeline side:
```jsonc
{
  "name": "Transform_Silver",
  "type": "TridentNotebook",
  "policy": { "timeout": "0.02:00:00", "retry": 1, "retryIntervalInSeconds": 300 },
  "typeProperties": {
    "notebookId": "<notebook-item-id>",
    "workspaceId": "<workspace-id>",
    "parameters": {
      "p_source_system": { "value": "@pipeline().parameters.pSourceSystem", "type": "Expression" },
      "p_table":         { "value": "@pipeline().parameters.pTable",        "type": "Expression" },
      "p_run_date":      { "value": "@pipeline().parameters.pRunDate",      "type": "Expression" },
      "p_run_id":        { "value": "@pipeline().RunId",                    "type": "Expression" },
      "p_environment":   { "value": "@pipeline().parameters.pEnvironment",  "type": "Expression" }
    }
  }
}
```

Notebook receives these as overrides to the `parameters`-tagged cell.

## 8. Notebook → notebook orchestration (when you don't want a pipeline)

```python
# Run silver, then gold; pass the row count between them
silver_out = mssparkutils.notebook.run(
    "/Notebooks/transform_silver",
    timeout_seconds = 3600,
    arguments = {"p_run_id": p_run_id, "p_table": p_table})

mssparkutils.notebook.run(
    "/Notebooks/transform_gold",
    timeout_seconds = 1800,
    arguments = {"p_run_id": p_run_id,
                 "p_silver_rows": json.loads(silver_out)["rows_out"]})
```

Use for tightly coupled steps where pipeline overhead isn't worth it.
Otherwise prefer pipelines for cross-team visibility in Monitor hub.

## 9. Performance gotchas (the senior-level ones)

| Symptom | Cause | Fix |
|---|---|---|
| First cell takes 60s | Cold Spark session | Use a **High-concurrency Spark pool** + session pinning, or attach a custom Spark pool with minimum nodes |
| Stage with 1 task takes hours | Skew on join key | Salt the key, or use `/*+ SKEW */` hint, or broadcast the small side |
| Small files in Delta (`OPTIMIZE` takes hours) | Streaming/append with no compaction | Schedule weekly `OPTIMIZE` + tune `spark.sql.shuffle.partitions` down |
| MERGE rewrites entire table | No partitioning, or predicate doesn't prune | Partition by `load_date`; include partition filter in MERGE condition |
| OOM on driver | `df.toPandas()` on a big DF | Use `df.limit(1000).toPandas()` for inspection only |
| Notebook activity times out at 1h | Default activity timeout | Bump `policy.timeout`; consider breaking into smaller notebooks |
| `Py4JJavaError: ... no module named X` | Library not on the Spark pool | Add to **Workspace settings → Environment → Libraries**, or `%pip install` at cell top (session-scoped) |
| Different behavior in dev vs prod | Different Spark pool versions | Pin a **Fabric runtime version** (e.g. 1.2) per environment in the Environment item |

## 10. Code-review checklist for notebooks

```
[ ] First cell is tagged `parameters` and contains only assignments
[ ] No hardcoded workspace GUIDs / paths — use Lakehouse references or env vars
[ ] `spark.conf.set` for timezone (UTC) and schema autoMerge
[ ] try/except wraps main logic; `mssparkutils.notebook.exit` on success
[ ] Logs to lh_ops.dbo.notebook_events at start, success, failure
[ ] MERGE includes partition predicate
[ ] No `df.collect()` / `df.toPandas()` on unbounded data
[ ] No `df.count()` used as a control-flow condition (expensive)
[ ] Pip installs declared in the Environment, not ad-hoc `%pip` in prod cells
[ ] Notebook is in Git and deployed via Deployment Pipeline rules
```
