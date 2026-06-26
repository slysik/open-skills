# Microsoft Fabric — End-to-End Recipes

This doc contains production-ready code blocks and schemas for common Fabric
data engineering tasks. Use these templates as foundations for your pipelines.

---

## Recipe 1: SQL Server to Bronze Lakehouse (Watermarked Incremental Load)

This recipe implements the pattern described in `data-pipelines.md` §4. It
incremental-copies a SQL table to a Lakehouse Delta table based on a watermark.

### 1.1 The Control Table (Run inside the Gold Warehouse / SQL Endpoint)
Create this table to track watermarks across your systems:

```sql
-- Create schema for metadata
CREATE SCHEMA ctl;
GO

CREATE TABLE ctl.ingest_watermark (
    source_system VARCHAR(50) NOT NULL,
    source_table VARCHAR(100) NOT NULL,
    load_watermark VARCHAR(50) NOT NULL,
    last_updated_at DATETIME2 DEFAULT SYSUTCDATETIME(),
    CONSTRAINT PK_ingest_watermark PRIMARY KEY NONCLUSTERED (source_system, source_table) NOT ENFORCED
);
GO

-- Seed the watermark for the orders table
INSERT INTO ctl.ingest_watermark (source_system, source_table, load_watermark)
VALUES ('ERP_PROD', 'dbo.orders', '1900-01-01 00:00:00');
GO

-- Create table to log pipeline errors
CREATE TABLE ctl.pipeline_errors (
    run_id VARCHAR(50) NOT NULL,
    pipeline_name VARCHAR(100) NOT NULL,
    source_system VARCHAR(50),
    source_table VARCHAR(100),
    error_message VARCHAR(MAX),
    occurred_at DATETIME2 DEFAULT SYSUTCDATETIME()
);
GO
```

### 1.2 The Ingest Script (To advance watermark after successful Copy)
This runs inside the `Script` activity (`Advance_Watermark` in the reference pipeline):

```sql
-- Parameters injected via pipeline expression:
-- @{pipeline().parameters.pSourceSystem}
-- @{pipeline().parameters.pTable}
-- @{pipeline().TriggerTime}

DECLARE @SourceSystem VARCHAR(50)  = '@{pipeline().parameters.pSourceSystem}';
DECLARE @SourceTable  VARCHAR(100) = '@{pipeline().parameters.pTable}';
DECLARE @NewWatermark VARCHAR(50)  = '@{pipeline().TriggerTime}';

MERGE ctl.ingest_watermark AS t
USING (SELECT @SourceSystem AS src, @SourceTable AS tbl) AS s
ON t.source_system = s.src AND t.source_table = s.tbl
WHEN MATCHED THEN
    UPDATE SET load_watermark = @NewWatermark, last_updated_at = SYSUTCDATETIME()
WHEN NOT MATCHED THEN
    INSERT (source_system, source_table, load_watermark, last_updated_at)
    VALUES (s.src, s.tbl, @NewWatermark, SYSUTCDATETIME());
```

---

## Recipe 2: REST API to Bronze Files (With Pagination and PySpark Parsing)

This recipe ingests transactional data from a REST API that supports Cursor/Offset pagination, lands it as JSON in OneLake Files, and parses it using PySpark.

### 2.1 The Pipeline Loop (Cursor Pagination)
Use a **Web Activity** to get the first page, then an **Until Activity** to loop until the API indicates there are no more records.

```jsonc
/* Inside the Until Activity -> Activities array */
[
  {
    "name": "Fetch_API_Page",
    "type": "Copy",
    "typeProperties": {
      "source": {
        "type": "RestSource",
        "httpRequestTimeout": "00:02:00",
        "requestMethod": "GET",
        "additionalHeaders": {
          "Authorization": "Bearer @{variables('vToken')}"
        },
        /* Injects the next page cursor from our variable */
        "relativeUrl": {
          "value": "/v1/transactions?cursor=@{variables('vNextCursor')}&limit=1000",
          "type": "Expression"
        }
      },
      "sink": {
        "type": "BinarySink",
        "storeSettings": {
          "type": "LakehouseFilesSinkSettings"
        }
      },
      "sinkSettings": {
        "fileSystem": "lh_bronze",
        "folderPath": {
          "value": "Files/api_transactions/@{pipeline().parameters.pRunDate}",
          "type": "Expression"
        },
        "fileName": {
          "value": "tx_page_@{variables('vPageNumber')}.json",
          "type": "Expression"
        }
      }
    }
  },
  {
    "name": "Lookup_Next_Cursor",
    "type": "Lookup",
    "dependsOn": [{ "activity": "Fetch_API_Page", "dependencyConditions": ["Succeeded"] }],
    "typeProperties": {
      "source": {
        "type": "JsonSource",
        "storeSettings": {
          "type": "LakehouseFilesSourceSettings"
        }
      },
      "dataset": {
        "referenceName": "ds_lakehouse_files",
        "type": "DatasetReference",
        "parameters": {
          "pPath": "Files/api_transactions/@{pipeline().parameters.pRunDate}/tx_page_@{variables('vPageNumber')}.json"
        }
      },
      "firstRowOnly": true
    }
  },
  {
    "name": "Update_Cursor_Variable",
    "type": "SetVariable",
    "dependsOn": [{ "activity": "Lookup_Next_Cursor", "dependencyConditions": ["Succeeded"] }],
    "typeProperties": {
      "variableName": "vNextCursor",
      "value": { "value": "@activity('Lookup_Next_Cursor').output.firstRow.pagination.next_cursor", "type": "Expression" }
    }
  },
  {
    "name": "Increment_Page_Number",
    "type": "SetVariable",
    "dependsOn": [{ "activity": "Update_Cursor_Variable", "dependencyConditions": ["Succeeded"] }],
    "typeProperties": {
      "variableName": "vPageNumber",
      "value": { "value": "@add(variables('vPageNumber'), 1)", "type": "Expression" }
    }
  }
]
```

### 2.2 PySpark Notebook: Parsers for Nesting & Schema Drift
This notebook is triggered immediately after the Until loop completes. It reads all JSON pages, explodes nested objects, and saves the output to Silver.

```python
# parameters
p_run_date = "2026-05-20"
p_run_id = "manual-dev"

from pyspark.sql import functions as F, types as T
from delta.tables import DeltaTable

# 1. Read all landed JSON files for this run date
raw_path = f"abfss://ws-finance@onelake.dfs.fabric.microsoft.com/lh_bronze.Lakehouse/Files/api_transactions/{p_run_date}/*.json"
df_raw = spark.read.option("multiline", "true").json(raw_path)

# 2. Schema definition for safety (prevents schema-drift failures)
tx_schema = T.StructType([
    T.StructField("transaction_id", T.StringType(), True),
    T.StructField("customer", T.StructType([
        T.StructField("customer_id", T.StringType(), True),
        T.StructField("country", T.StringType(), True)
    ]), True),
    T.StructField("items", T.ArrayType(T.StructType([
        T.StructField("sku", T.StringType(), True),
        T.StructField("quantity", T.IntegerType(), True),
        T.StructField("price", T.DecimalType(18, 2), True)
    ])), True),
    T.StructField("metadata", T.MapType(T.StringType(), T.StringType()), True)
])

# 3. Apply schema and dot-walk elements
# We explode the "items" array to flatten the transaction rows
df_parsed = (df_raw
    .withColumn("data", F.from_json("data", tx_schema))
    .withColumn("item", F.explode("data.items"))
    .select(
        F.col("data.transaction_id").alias("transaction_id"),
        F.col("data.customer.customer_id").alias("customer_id"),
        F.col("data.customer.country").alias("country"),
        F.col("item.sku").alias("sku"),
        F.col("item.quantity").alias("qty"),
        F.col("item.price").alias("price"),
        # Safely handle custom untyped metadata tags
        F.col("data.metadata")["promo_code"].alias("promo_code"),
        F.lit(p_run_id).alias("_ingest_run_id"),
        F.current_date().alias("load_date")
    ))

# 4. Write to Silver Delta Table with Auto-Merge enabled
(df_parsed.write.format("delta")
    .mode("append")
    .partitionBy("load_date")
    .option("mergeSchema", "true")
    .saveAsTable("lh_silver.transactions"))
```

---

## Recipe 3: Zero-Downtime Star Schema Materialization (Silver to Gold)

When loading dimension and fact tables, we want to update them without locking or dropping views that active Power BI reports are querying. We achieve this by performing a **swap load** using Delta tables.

```python
# parameters
p_run_id = "manual-dev"

from delta.tables import DeltaTable
import uuid

# Define Target Gold Table
gold_table = "lh_gold.dim_customer"
temp_table_name = f"lh_gold.dim_customer_temp_{str(uuid.uuid4())[:8]}"

# 1. Pull cleaned Silver data, deduplicate, and model on the fly
silver_df = spark.read.table("lh_silver.customers")

# Create a clean surrogate key and isolate active records
gold_df = (silver_df
    .filter("is_active = true")
    .select(
        # Create a deterministic surrogate key using MD5
        F.md5(F.concat_ws("||", "customer_id", "country")).alias("customer_sk"),
        F.col("customer_id").alias("natural_key"),
        F.col("name").alias("customer_name"),
        F.col("country"),
        F.lit(p_run_id).alias("_processed_run_id")
    ))

# 2. Write gold data to a temporary staging table
gold_df.write.format("delta").mode("overwrite").saveAsTable(temp_table_name)

# 3. Perform atomic swap to avoid downtime on active DirectLake queries
spark.sql(f"DROP TABLE IF EXISTS {gold_table}_old")

# If the target gold table doesn't exist yet, create it empty
if not spark.catalog.tableExists(gold_table):
    gold_df.limit(0).write.format("delta").saveAsTable(gold_table)

# Atomic Delta table property swap
# We swap the physical directories of the Delta paths
spark.sql(f"ALTER TABLE {gold_table} RENAME TO {gold_table}_old")
spark.sql(f"ALTER TABLE {temp_table_name} RENAME TO {gold_table}")

# Clean up
spark.sql(f"DROP TABLE {gold_table}_old")
print("Atomic swap complete! DirectLake queries were never blocked.")
```
