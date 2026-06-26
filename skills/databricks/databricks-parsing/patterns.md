# Databricks Document Parsing — Common Patterns

> Detail moved out of the router. Router: SKILL.md

## Common Patterns

### Pattern 1: Parse with Options

```sql
SELECT ai_parse_document(
  content,
  map(
    'version', '2.0',
    'imageOutputPath', '/Volumes/catalog/schema/volume/images/',
    'descriptionElementTypes', '*'
  )
) AS parsed
FROM read_files('/Volumes/catalog/schema/volume/invoices/', format => 'binaryFile');
```

**Options:**

| Key | Values | Description |
|-----|--------|-------------|
| `version` | `'2.0'` | Output schema version |
| `imageOutputPath` | Volume path | Save rendered page images |
| `descriptionElementTypes` | `''`, `'figure'`, `'*'` | AI-generated descriptions (default: `'*'` for all) |

### Pattern 2: Parse + Extract Structured Data

Combine `ai_parse_document` with `ai_query` to extract specific fields.
Use `transform()` + `try_cast()` to concatenate element text, then pass
the full text to `ai_query` with `returnType => 'STRING'`.

```sql
WITH parsed_documents AS (
  SELECT
    path,
    ai_parse_document(content) AS parsed
  FROM read_files('/Volumes/catalog/schema/volume/invoices/', format => 'binaryFile')
),
parsed_text AS (
  SELECT
    path,
    concat_ws('\n\n',
      transform(
        try_cast(parsed:document:elements AS ARRAY<VARIANT>),
        element -> try_cast(element:content AS STRING)
      )
    ) AS text
  FROM parsed_documents
  WHERE try_cast(parsed:error_status AS STRING) IS NULL
)
SELECT
  path,
  ai_query(
    'databricks-claude-sonnet-4',
    concat(
      'Extract vendor name, invoice number, and total due from this document. ',
      'Return the result as a JSON object with keys: vendor, invoice_number, total_due. ',
      text
    ),
    returnType => 'STRING'
  ) AS structured_data
FROM parsed_text
WHERE text IS NOT NULL;
```

### Pattern 3: Custom RAG Pipeline

End-to-end: parse documents → chunk text → store in Delta table → create Vector Search index.

**Step 1 — Parse and chunk into a Delta table:**

`ai_parse_document` returns a VARIANT. You must use `variant_get` with an explicit
`ARRAY<VARIANT>` cast before calling `explode`, since `explode()` does not accept
raw VARIANT values.

```sql
CREATE OR REPLACE TABLE catalog.schema.parsed_chunks AS
WITH parsed AS (
  SELECT
    path,
    ai_parse_document(content) AS doc
  FROM read_files('/Volumes/catalog/schema/volume/docs/', format => 'binaryFile')
),
elements AS (
  SELECT
    path,
    explode(variant_get(doc, '$.document.elements', 'ARRAY<VARIANT>')) AS element
  FROM parsed
)
SELECT
  md5(concat(path, variant_get(element, '$.content', 'STRING'))) AS chunk_id,
  path AS source_path,
  variant_get(element, '$.content', 'STRING') AS content,
  variant_get(element, '$.type', 'STRING') AS element_type,
  current_timestamp() AS parsed_at
FROM elements
WHERE variant_get(element, '$.content', 'STRING') IS NOT NULL
  AND length(trim(variant_get(element, '$.content', 'STRING'))) > 10;
```

**Step 1a (production) — Incremental parsing with Structured Streaming:**

For production pipelines where new documents arrive over time, use Structured
Streaming with checkpoints for exactly-once processing. Each run processes only
new files (tracked via checkpoints), then stops with `trigger(availableNow=True)`.

See the official bundle example:
[databricks/bundle-examples/contrib/job_with_ai_parse_document](https://github.com/databricks/bundle-examples/tree/main/contrib/job_with_ai_parse_document)

**Stage 1 — Parse raw documents (streaming):**

```python
from pyspark.sql.functions import col, current_timestamp, expr

files_df = (
    spark.readStream.format("binaryFile")
    .option("pathGlobFilter", "*.{pdf,jpg,jpeg,png}")
    .option("recursiveFileLookup", "true")
    .load("/Volumes/catalog/schema/volume/docs/")
)

parsed_df = (
    files_df
    .repartition(8, expr("crc32(path) % 8"))
    .withColumn("parsed", expr("""
        ai_parse_document(content, map(
            'version', '2.0',
            'descriptionElementTypes', '*'
        ))
    """))
    .withColumn("parsed_at", current_timestamp())
    .select("path", "parsed", "parsed_at")
)

(
    parsed_df.writeStream.format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/Volumes/catalog/schema/checkpoints/01_parse")
    .option("mergeSchema", "true")
    .trigger(availableNow=True)
    .toTable("catalog.schema.parsed_documents_raw")
)
```

**Stage 2 — Extract text from parsed VARIANT (streaming):**

Uses `transform()` to extract element content from the VARIANT array, and
`try_cast` for safe access. Error rows are preserved but flagged.

```python
from pyspark.sql.functions import col, concat_ws, expr, lit, when

parsed_stream = spark.readStream.format("delta").table("catalog.schema.parsed_documents_raw")

text_df = (
    parsed_stream
    .withColumn("text",
        when(
            expr("try_cast(parsed:error_status AS STRING)").isNotNull(), lit(None)
        ).otherwise(
            concat_ws("\n\n", expr("""
                transform(
                    try_cast(parsed:document:elements AS ARRAY),
                    element -> try_cast(element:content AS STRING)
                )
            """))
        )
    )
    .withColumn("error_status", expr("try_cast(parsed:error_status AS STRING)"))
    .select("path", "text", "error_status", "parsed_at")
)

(
    text_df.writeStream.format("delta")
    .outputMode("append")
    .option("checkpointLocation", "/Volumes/catalog/schema/checkpoints/02_text")
    .option("mergeSchema", "true")
    .trigger(availableNow=True)
    .toTable("catalog.schema.parsed_documents_text")
)
```

Key techniques from the official example:
- **`repartition` by file hash** — parallelizes `ai_parse_document` across workers
- **`trigger(availableNow=True)`** — processes all pending files then stops (batch-like)
- **Checkpoints** — exactly-once guarantee; no re-parsing on re-runs
- **`transform()` + `try_cast`** — safer than `explode` + `variant_get` for text extraction
- **Three-stage pipeline** — separate parse/text/structured stages with independent checkpoints

**Step 1b — Enable Change Data Feed (required for Vector Search Delta Sync):**

```sql
ALTER TABLE catalog.schema.parsed_chunks
SET TBLPROPERTIES (delta.enableChangeDataFeed = true);
```

**Step 2 — Create a Vector Search index and query it:**

Use the **[databricks-vector-search](../databricks-vector-search/SKILL.md)** skill to create a
Delta Sync index on the chunked table and query it. Ensure CDF is enabled first
(Step 1b above).

