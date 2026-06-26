# Databricks Python SDK — Common Patterns

> Verbatim from the original skill. Router: ../SKILL.md

## Common Patterns

### CRITICAL: Async Applications (FastAPI, etc.)

**The Databricks SDK is fully synchronous.** All calls block the thread. In async applications (FastAPI, asyncio), you MUST wrap SDK calls with `asyncio.to_thread()` to avoid blocking the event loop.

```python
import asyncio
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()

# WRONG - blocks the event loop
async def get_clusters_bad():
    return list(w.clusters.list())  # BLOCKS!

# CORRECT - runs in thread pool
async def get_clusters_good():
    return await asyncio.to_thread(lambda: list(w.clusters.list()))

# CORRECT - for simple calls
async def get_cluster(cluster_id: str):
    return await asyncio.to_thread(w.clusters.get, cluster_id)

# CORRECT - FastAPI endpoint
from fastapi import FastAPI
app = FastAPI()

@app.get("/clusters")
async def list_clusters():
    clusters = await asyncio.to_thread(lambda: list(w.clusters.list()))
    return [{"id": c.cluster_id, "name": c.cluster_name} for c in clusters]

@app.post("/query")
async def run_query(sql: str, warehouse_id: str):
    # Wrap the blocking SDK call
    response = await asyncio.to_thread(
        w.statement_execution.execute_statement,
        statement=sql,
        warehouse_id=warehouse_id,
        wait_timeout="30s"
    )
    return response.result.data_array
```

**Note:** `WorkspaceClient().config.host` is NOT a network call - it just reads config. No need to wrap property access.

---

### Wait for Long-Running Operations
```python
from datetime import timedelta

# Pattern 1: Use *_and_wait methods
cluster = w.clusters.create_and_wait(
    cluster_name="test",
    spark_version="14.3.x-scala2.12",
    node_type_id="i3.xlarge",
    num_workers=2,
    timeout=timedelta(minutes=30)
)

# Pattern 2: Use Wait object
wait = w.clusters.create(...)
cluster = wait.result()  # Blocks until ready

# Pattern 3: Manual polling with callback
def progress(cluster):
    print(f"State: {cluster.state}")

cluster = w.clusters.wait_get_cluster_running(
    cluster_id="...",
    timeout=timedelta(minutes=30),
    callback=progress
)
```

### Pagination
```python
# All list methods return iterators that handle pagination automatically
for job in w.jobs.list():  # Fetches all pages
    print(job.settings.name)

# For manual control
from databricks.sdk.service.jobs import ListJobsRequest
response = w.jobs.list(limit=10)
for job in response:
    print(job)
```

### Error Handling
```python
from databricks.sdk.errors import NotFound, PermissionDenied, ResourceAlreadyExists

try:
    cluster = w.clusters.get(cluster_id="invalid-id")
except NotFound:
    print("Cluster not found")
except PermissionDenied:
    print("Access denied")
```
