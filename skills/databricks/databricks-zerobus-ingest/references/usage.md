# Zerobus — Minimal example, detailed guides, workflow

> Detail moved out of the router. Router: ../SKILL.md (or SKILL.md)

## Minimal Python Example (JSON)

```python
import json
from zerobus.sdk.sync import ZerobusSdk
from zerobus.sdk.shared import RecordType, StreamConfigurationOptions, TableProperties

sdk = ZerobusSdk(server_endpoint, workspace_url)
options = StreamConfigurationOptions(record_type=RecordType.JSON)
table_props = TableProperties(table_name)

stream = sdk.create_stream(client_id, client_secret, table_props, options)
try:
    record = {"device_name": "sensor-1", "temp": 22, "humidity": 55}
    stream.ingest_record(json.dumps(record))
    stream.flush()
finally:
    stream.close()
```

---

## Detailed guides

| Topic | File | When to Read |
|-------|------|--------------|
| Setup & Auth | [1-setup-and-authentication.md](1-setup-and-authentication.md) | Endpoint formats, service principals, SDK install |
| Python Client | [2-python-client.md](2-python-client.md) | Sync/async Python, JSON and Protobuf flows, reusable client class |
| Multi-Language | [3-multilanguage-clients.md](3-multilanguage-clients.md) | Java, Go, TypeScript, Rust SDK examples |
| Protobuf Schema | [4-protobuf-schema.md](4-protobuf-schema.md) | Generate .proto from UC table, compile, type mappings |
| Operations & Limits | [5-operations-and-limits.md](5-operations-and-limits.md) | ACK handling, retries, reconnection, throughput limits, constraints |

---

You must always follow all the steps in the Workflow

## Workflow
0. **Display the plan of your execution**
1. **Determinate the type of client**
2. **Get schema** Always use 4-protobuf-schema.md. Execute using the `execute_code` MCP tool
3. **Write Python code to a local file follow the instructions in the relevant guide to ingest with zerobus** in the project (e.g., `scripts/zerobus_ingest.py`).
4. **Execute on Databricks** using the `execute_code` MCP tool (with `file_path` parameter)
5. **If execution fails**: Edit the local file to fix the error, then re-execute
6. **Reuse the context** for follow-up executions by passing the returned `cluster_id` and `context_id`

---

## Important
- Never install local packages
- Always validate MCP server requirement before execution
- **Serverless limitation**: The Zerobus SDK cannot pip-install on serverless compute. Use classic compute clusters, or use the [Zerobus REST API](https://docs.databricks.com/aws/en/ingestion/zerobus-rest-api) (Beta) for notebook-based ingestion without the SDK.
- **Explicit table grants**: Service principals need explicit `MODIFY` and `SELECT` grants on the target table. Schema-level inherited permissions may not be sufficient for the `authorization_details` OAuth flow.

---

### Context Reuse Pattern

The first execution auto-selects a running cluster and creates an execution context. **Reuse this context for follow-up calls** - it's much faster (~1s vs ~15s) and shares variables/imports:

**First execution** - use `execute_code` tool:
- `file_path`: "scripts/zerobus_ingest.py"

Returns: `{ success, output, error, cluster_id, context_id, ... }`

Save `cluster_id` and `context_id` for follow-up calls.

**If execution fails:**
1. Read the error from the result
2. Edit the local Python file to fix the issue
3. Re-execute with same context using `execute_code` tool:
   - `file_path`: "scripts/zerobus_ingest.py"
   - `cluster_id`: "<saved_cluster_id>"
   - `context_id`: "<saved_context_id>"

**Follow-up executions** reuse the context (faster, shares state):
- `file_path`: "scripts/validate_ingestion.py"
- `cluster_id`: "<saved_cluster_id>"
- `context_id`: "<saved_context_id>"

### Handling Failures

When execution fails:
1. Read the error from the result
2. **Edit the local Python file** to fix the issue
3. Re-execute using the same `cluster_id` and `context_id` (faster, keeps installed libraries)
4. If the context is corrupted, omit `context_id` to create a fresh one

---

### Installing Libraries

Databricks provides Spark, pandas, numpy, and common data libraries by default. **Only install a library if you get an import error.**

Use `execute_code` tool:
- `code`: "%pip install databricks-zerobus-ingest-sdk>=1.0.0"
- `cluster_id`: "<cluster_id>"
- `context_id`: "<context_id>"

The library is immediately available in the same context.

**Note:** Keeping the same `context_id` means installed libraries persist across calls.

