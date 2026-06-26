# AI Functions — Common Patterns

> Detail moved out of the router. Router: ../SKILL.md (or SKILL.md)

## Common Patterns

### Pattern 1: Text Analysis Pipeline

Chain multiple task-specific functions to enrich a text column in one pass:

```sql
SELECT
    id,
    content,
    ai_analyze_sentiment(content)               AS sentiment,
    ai_summarize(content, 30)                   AS summary,
    ai_classify(content,
        ARRAY('technical', 'billing', 'other')) AS category,
    ai_fix_grammar(content)                     AS content_clean
FROM raw_feedback;
```

### Pattern 2: PII Redaction Before Storage

```python
from pyspark.sql.functions import expr

df_clean = (
    spark.table("raw_messages")
    .withColumn(
        "message_safe",
        expr("ai_mask(message, array('person', 'email', 'phone', 'address'))")
    )
)
df_clean.write.format("delta").mode("append").saveAsTable("catalog.schema.messages_safe")
```

### Pattern 3: Document Ingestion from a Unity Catalog Volume

Parse PDFs/Office docs, then enrich with task-specific functions:

```python
from pyspark.sql.functions import expr

df = (
    spark.read.format("binaryFile")
    .load("/Volumes/catalog/schema/landing/documents/")
    .withColumn("parsed", expr("ai_parse_document(content)"))
    .selectExpr("path",
                "parsed:pages[*].elements[*].content AS text_blocks",
                "parsed:error AS parse_error")
    .filter("parse_error IS NULL")
    .withColumn("summary",  expr("ai_summarize(text_blocks, 50)"))
    .withColumn("entities", expr("ai_extract(text_blocks, array('date', 'amount', 'vendor'))"))
)
```

### Pattern 4: Semantic Matching / Deduplication

```sql
-- Find near-duplicate company names
SELECT a.id, b.id, ai_similarity(a.name, b.name) AS score
FROM companies a
JOIN companies b ON a.id < b.id
WHERE ai_similarity(a.name, b.name) > 0.85;
```

### Pattern 5: Complex JSON Extraction with `ai_query` (last resort)

Use only when the output schema has nested arrays or requires multi-step reasoning that no task-specific function handles:

```python
from pyspark.sql.functions import expr, from_json, col

df = (
    spark.table("parsed_documents")
    .withColumn("ai_response", expr("""
        ai_query(
            'databricks-claude-sonnet-4',
            concat('Extract invoice as JSON with nested itens array: ', text_blocks),
            responseFormat => '{"type":"json_object"}',
            failOnError     => false
        )
    """))
    .withColumn("invoice", from_json(
        col("ai_response.response"),
        "STRUCT<numero:STRING, total:DOUBLE, "
        "itens:ARRAY<STRUCT<codigo:STRING, descricao:STRING, qtde:DOUBLE, vlrUnit:DOUBLE>>>"
    ))
)
```

### Pattern 6: Time Series Forecasting

```sql
SELECT *
FROM ai_forecast(
    observed  => TABLE(SELECT date, sales FROM daily_sales),
    horizon   => '2026-12-31',
    time_col  => 'date',
    value_col => 'sales'
);
-- Returns: date, sales_forecast, sales_upper, sales_lower
```

