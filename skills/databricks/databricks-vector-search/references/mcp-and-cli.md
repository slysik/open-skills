# Databricks Vector Search — CLI & MCP (optional)

> CLI quick-reference + optional MCP tools. Per CLI-first policy, MCP is a convenience, not required. Router: ../SKILL.md

## CLI Quick Reference

```bash
# List endpoints
databricks vector-search endpoints list

# Create endpoint
databricks vector-search endpoints create \
    --name my-endpoint \
    --endpoint-type STANDARD

# List indexes on endpoint
databricks vector-search indexes list-indexes \
    --endpoint-name my-endpoint

# Get index status
databricks vector-search indexes get-index \
    --index-name catalog.schema.my_index

# Sync index (for TRIGGERED)
databricks vector-search indexes sync-index \
    --index-name catalog.schema.my_index

# Delete index
databricks vector-search indexes delete-index \
    --index-name catalog.schema.my_index
```


## MCP Tools

The following MCP tools are available for managing Vector Search infrastructure. For a full end-to-end walkthrough, see [end-to-end-rag.md](end-to-end-rag.md).

### manage_vs_endpoint - Endpoint Management

| Action | Description | Required Params |
|--------|-------------|-----------------|
| `create_or_update` | Create endpoint (STANDARD or STORAGE_OPTIMIZED). Idempotent | name |
| `get` | Get endpoint details | name |
| `list` | List all endpoints | (none) |
| `delete` | Delete endpoint (indexes must be deleted first) | name |

```python
# Create or update an endpoint
result = manage_vs_endpoint(action="create_or_update", name="my-vs-endpoint", endpoint_type="STANDARD")
# Returns {"name": "my-vs-endpoint", "endpoint_type": "STANDARD", "created": True}

# List all endpoints
endpoints = manage_vs_endpoint(action="list")

# Get specific endpoint
endpoint = manage_vs_endpoint(action="get", name="my-vs-endpoint")
```

### manage_vs_index - Index Management

| Action | Description | Required Params |
|--------|-------------|-----------------|
| `create_or_update` | Create index. Idempotent, auto-triggers sync for DELTA_SYNC | name, endpoint_name, primary_key |
| `get` | Get index details | name |
| `list` | List indexes. Optional endpoint_name filter | (none) |
| `delete` | Delete index | name |

```python
# Create a Delta Sync index with managed embeddings
result = manage_vs_index(
    action="create_or_update",
    name="catalog.schema.my_index",
    endpoint_name="my-vs-endpoint",
    primary_key="id",
    index_type="DELTA_SYNC",
    delta_sync_index_spec={
        "source_table": "catalog.schema.docs",
        "embedding_source_columns": [{"name": "content", "embedding_model_endpoint_name": "databricks-gte-large-en"}],
        "pipeline_type": "TRIGGERED"
    }
)

# Get a specific index
index = manage_vs_index(action="get", name="catalog.schema.my_index")

# List all indexes on an endpoint
indexes = manage_vs_index(action="list", endpoint_name="my-vs-endpoint")

# List all indexes across all endpoints
all_indexes = manage_vs_index(action="list")
```

### query_vs_index - Query (Hot Path)

Query index with `query_text`, `query_vector`, or hybrid (`query_type="HYBRID"`). Prefer `query_text` over `query_vector` — MCP tool calls can truncate large embedding arrays (1024-dim).

```python
# Query an index
results = query_vs_index(
    index_name="catalog.schema.my_index",
    columns=["id", "content"],
    query_text="machine learning best practices",
    num_results=5
)

# Hybrid search (combines vector + keyword)
results = query_vs_index(
    index_name="catalog.schema.my_index",
    columns=["id", "content"],
    query_text="SPARK-12345 memory error",
    query_type="HYBRID",
    num_results=10
)
```

### manage_vs_data - Data Operations

| Action | Description | Required Params |
|--------|-------------|-----------------|
| `upsert` | Insert/update records | index_name, inputs_json |
| `delete` | Delete by primary key | index_name, primary_keys |
| `scan` | Scan index contents | index_name |
| `sync` | Trigger sync for TRIGGERED indexes | index_name |

```python
# Upsert data into a Direct Access index
manage_vs_data(
    action="upsert",
    index_name="catalog.schema.my_index",
    inputs_json=[{"id": "doc1", "content": "...", "embedding": [0.1, 0.2, ...]}]
)

# Trigger manual sync for a TRIGGERED pipeline index
manage_vs_data(action="sync", index_name="catalog.schema.my_index")

# Scan index contents
manage_vs_data(action="scan", index_name="catalog.schema.my_index", num_results=100)
```

