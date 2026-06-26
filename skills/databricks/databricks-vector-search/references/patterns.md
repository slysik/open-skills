# Databricks Vector Search — Patterns

> Advanced patterns moved out of the router. Router: ../SKILL.md

## Common Patterns

### Create Storage-Optimized Endpoint

```python
# For large-scale, cost-effective deployments
endpoint = w.vector_search_endpoints.create_endpoint(
    name="my-storage-endpoint",
    endpoint_type="STORAGE_OPTIMIZED"
)
```

### Delta Sync with Self-Managed Embeddings

```python
# Source table must have: primary key + embedding vector column
index = w.vector_search_indexes.create_index(
    name="catalog.schema.my_index",
    endpoint_name="my-vs-endpoint",
    primary_key="id",
    index_type="DELTA_SYNC",
    delta_sync_index_spec={
        "source_table": "catalog.schema.documents",
        "embedding_vector_columns": [
            {
                "name": "embedding",  # Pre-computed embedding column
                "embedding_dimension": 768
            }
        ],
        "pipeline_type": "TRIGGERED"
    }
)
```

### Direct Access Index

```python
import json

# Create index for manual CRUD
index = w.vector_search_indexes.create_index(
    name="catalog.schema.direct_index",
    endpoint_name="my-vs-endpoint",
    primary_key="id",
    index_type="DIRECT_ACCESS",
    direct_access_index_spec={
        "embedding_vector_columns": [
            {"name": "embedding", "embedding_dimension": 768}
        ],
        "schema_json": json.dumps({
            "id": "string",
            "text": "string",
            "embedding": "array<float>",
            "metadata": "string"
        })
    }
)

# Upsert data
w.vector_search_indexes.upsert_data_vector_index(
    index_name="catalog.schema.direct_index",
    inputs_json=json.dumps([
        {"id": "1", "text": "Hello", "embedding": [0.1, 0.2, ...], "metadata": "doc1"},
        {"id": "2", "text": "World", "embedding": [0.3, 0.4, ...], "metadata": "doc2"},
    ])
)

# Delete data
w.vector_search_indexes.delete_data_vector_index(
    index_name="catalog.schema.direct_index",
    primary_keys=["1", "2"]
)
```

### Query with Embedding Vector

```python
# When you have pre-computed query embedding
results = w.vector_search_indexes.query_index(
    index_name="catalog.schema.my_index",
    columns=["id", "text"],
    query_vector=[0.1, 0.2, 0.3, ...],  # Your 768-dim vector
    num_results=10
)
```

### Hybrid Search (Semantic + Keyword)

Hybrid search combines vector similarity (ANN) with BM25 keyword scoring. Use it when queries contain exact terms that must match — SKUs, error codes, proper nouns, or technical terminology — where pure semantic search might miss keyword-specific results. See [search-modes.md](search-modes.md) for detailed guidance on choosing between ANN and hybrid search.

```python
# Combines vector similarity with keyword matching
results = w.vector_search_indexes.query_index(
    index_name="catalog.schema.my_index",
    columns=["id", "content"],
    query_text="SPARK-12345 executor memory error",
    query_type="HYBRID",
    num_results=10
)
```

## Filtering

### Standard Endpoint Filters (Dictionary)

```python
# filters_json uses dictionary format
results = w.vector_search_indexes.query_index(
    index_name="catalog.schema.my_index",
    columns=["id", "content"],
    query_text="machine learning",
    num_results=10,
    filters_json='{"category": "ai", "status": ["active", "pending"]}'
)
```

### Storage-Optimized Filters (SQL-like)

Storage-Optimized endpoints use SQL-like filter syntax via the `databricks-vectorsearch` package's `filters` parameter (accepts a string):

```python
from databricks.vector_search.client import VectorSearchClient

vsc = VectorSearchClient()
index = vsc.get_index(endpoint_name="my-storage-endpoint", index_name="catalog.schema.my_index")

# SQL-like filter syntax for storage-optimized endpoints
results = index.similarity_search(
    query_text="machine learning",
    columns=["id", "content"],
    num_results=10,
    filters="category = 'ai' AND status IN ('active', 'pending')"
)

# More filter examples
# filters="price > 100 AND price < 500"
# filters="department LIKE 'eng%'"
# filters="created_at >= '2024-01-01'"
```

### Trigger Index Sync

```python
# For TRIGGERED pipeline type, manually sync
w.vector_search_indexes.sync_index(
    index_name="catalog.schema.my_index"
)
```

### Scan All Index Entries

```python
# Retrieve all vectors (for debugging/export)
scan_result = w.vector_search_indexes.scan_index(
    index_name="catalog.schema.my_index",
    num_results=100
)
```


## Embedding Models

Databricks provides built-in embedding models:

| Model | Dimensions | Context Window | Use Case |
|-------|------------|----------------|----------|
| `databricks-gte-large-en` | 1024 | 8192 tokens | English text, high quality |
| `databricks-bge-large-en` | 1024 | 512 tokens | English text, general purpose |

```python
# Use with managed embeddings
embedding_source_columns=[
    {
        "name": "content",
        "embedding_model_endpoint_name": "databricks-gte-large-en"
    }
]
```

