# Microsoft Fabric — Pipeline Failure Handling

**Use this doc when a Fabric Data Pipeline run has already failed and you need
to (a) figure out why, (b) fix the root cause, and (c) recover without
double-loading data or losing the watermark.**

For design-time patterns that prevent failure, see [`resiliency.md`](resiliency.md).

## 1. The 5-step triage loop

```
            ┌──────────────────────────────────────────────────┐
            │  1. LOCATE the failed run (Monitor hub / REST)   │
            └─────────────────────┬────────────────────────────┘
                                  ▼
            ┌──────────────────────────────────────────────────┐
            │  2. CLASSIFY the error (table in §3)             │
            └─────────────────────┬────────────────────────────┘
                                  ▼
            ┌──────────────────────────────────────────────────┐
            │  3. INSPECT activity input/output + copy-log     │
            └─────────────────────┬────────────────────────────┘
                                  ▼
            ┌──────────────────────────────────────────────────┐
            │  4. FIX (code / config / data / capacity)        │
            └─────────────────────┬────────────────────────────┘
                                  ▼
            ┌──────────────────────────────────────────────────┐
            │  5. RECOVER (rerun from failed activity, idemp.) │
            └──────────────────────────────────────────────────┘
```

## 2. Step 1 — Locate the failed run

### Portal
**Monitor hub** → filter `Item type = Data pipeline`, `Status = Failed` →
click the run → activity Gantt opens. Hover the red ❌ to see the error
preview; click it for the full JSON.

### CLI
```bash
fab job run-list "/$FABRIC_WORKSPACE_NAME.Workspace/pl_sql_to_bronze.DataPipeline" \
  --top 50 --query "status=='Failed'"
```

### REST
```bash
curl -s -H "Authorization: Bearer $FABRIC_TOKEN" \
  "$FABRIC_API/workspaces/$WS_ID/items/$PL_ID/jobs/instances?\$filter=status eq 'Failed'" \
  | jq '.value[] | {id, startTimeUtc, endTimeUtc, failureReason: .failureReason.errorCode}'
```

Save the `RunId` — you'll need it for activity-level inspection and for the
rerun.

## 3. Step 2 — Classify the error

The error code in `failureReason.errorCode` tells you which bucket you're in.
Match it against this table:

| Error class | Typical errorCode / message | Root cause | Fix lives in |
|---|---|---|---|
| **Auth / permissions** | `UserErrorOdbcInvalidQueryString`, `Forbidden`, `401`, `Token expired`, `AADSTS50034` | SP missing role on source/sink; expired secret; workspace identity not granted | Connection / Entra / RBAC |
| **Connection / network** | `SqlFailedToConnect`, `Connection timeout`, `Name or service not known`, `gateway is offline` | Source down, firewall, gateway not running, private endpoint not approved | Network / gateway |
| **Schema / data** | `TypeConversionFailure`, `ColumnCountMismatch`, `InvalidColumnName`, `ParquetInvalidColumn` | Source schema changed, NULL into NOT NULL, wider type than sink | Source contract / mapping |
| **Capacity / throttling** | `CapacityExceeded`, `429`, `TooManyRequests`, `OperationCanceled` (with `quota`) | Fabric capacity smoothing kicked in; concurrent pipeline limit | Capacity / concurrency |
| **Source throttling** | `SqlTransientFault`, `40501` (Azure SQL), Salesforce `REQUEST_LIMIT_EXCEEDED` | Source-side limits | Retry / parallelism tuning |
| **Sink lock / conflict** | `DeltaConcurrentAppend`, `ConcurrentAppendException`, `WarehouseTransactionConflict` | Two pipelines writing the same Delta table / Warehouse table | Serialize writes / partition |
| **Timeout** | `RequestTimeout`, activity `policy.timeout` exceeded | Long query, big file, undersized DIUs | Tuning |
| **Code / logic** | `UserErrorPipelineExpressionEvaluationFailed`, `InvalidTemplate` | Bad `@expression`, missing parameter, divide-by-zero | Pipeline JSON |
| **External / Notebook** | `LivySessionFailed`, `SparkJobDefinitionFailure`, `PythonException` | Notebook/Spark code crashed | Notebook code |
| **Storage** | `AdlsGen2OperationFailed`, `Path not found`, `ContainerNotFound` | OneLake path wrong, file vacuumed, wrong workspace | Path / lifecycle |
| **Service / unknown** | `InternalServerError`, `ServiceBusyException` | Fabric service blip | Retry; if persistent, file a support case |

## 4. Step 3 — Inspect the failing activity

For each failed activity, three artifacts matter:

### a) Activity error (the headline)
```bash
RUN_ID=4f1b...
curl -s -H "Authorization: Bearer $FABRIC_TOKEN" \
  "$FABRIC_API/workspaces/$WS_ID/items/$PL_ID/jobs/instances/$RUN_ID" \
  | jq '.failureReason'
```

In the portal: click ❌ → **Error** tab → "Show more" for the stack.

### b) Activity input/output
Portal: click the activity → **Input** / **Output** glyphs. Confirm the
parameters and expressions resolved to what you expected — half of "pipeline
failures" are really "expression evaluated to empty string" issues.

### c) Copy activity log (when Copy enabled `logSettings`)

If you followed the reference pipeline in [`data-pipelines.md`](data-pipelines.md),
bad rows landed in OneLake:

```
abfss://<workspace>@onelake.dfs.fabric.microsoft.com/lh_ops.Lakehouse/Files/copy-logs/<pipeline>/<runId>/
    ├── copyactivity-logs/      # row-level warnings/errors
    └── session-logs/           # per-session
```

Read it from a notebook:

```python
df = spark.read.json(
    "abfss://ws-data-prod@onelake.dfs.fabric.microsoft.com/"
    "lh_ops.Lakehouse/Files/copy-logs/pl_sql_to_bronze/4f1b.../copyactivity-logs/"
)
df.filter("Level = 'Error'").select("OperationName","OperationItem","Message").show(50, False)
```

This is how you turn `4 rows failed schema check` into `customer_id=1729 has a
NULL email but sink column is NOT NULL`.

## 5. Step 4 — Fix by error class

The single most common five fixes:

1. **Expired SP secret** → rotate in Entra ID, update the Fabric **Connection**
   that uses it, save. No pipeline edit needed.
2. **Gateway offline** → on the gateway host: `Get-Service "Power BI Enterprise
   Gateway Service" | Restart-Service`. Verify status in Fabric portal →
   **Manage connections and gateways** → gateway → green dot. Rerun.
3. **Schema drift** → add the new column to sink (or enable schema evolution
   on the Delta sink: `mergeSchema=true`), update mapping in Copy activity.
4. **Capacity throttling** → either scale capacity (`az fabric capacity update`),
   reduce pipeline `concurrency`, lower `parallelCopies` on Copy, or move
   non-critical pipelines off the prod capacity.
5. **Idempotency burned by partial run** → see §6, *Recover safely*.

### Rotate a connection secret (CLI)

```bash
# Get the connection
fab ls /.connections --query "displayName=='conn-sql-prod'"
# Update its credential (interactive prompt for the new secret/token)
fab connection update conn-sql-prod
```

### Scale capacity to clear a throttling backlog

```bash
# F SKU bump (e.g. F4 -> F8). Effective in ~30s; billed pro-rated.
az fabric capacity update \
  --resource-group rg-fabric-prod \
  --capacity-name fab-cap-prod \
  --sku '{"name":"F8","tier":"Fabric"}'
```

## 6. Step 5 — Recover safely

The golden rule: **never blindly rerun a failed pipeline that already wrote
data**. Three recovery modes, pick by what the run actually did:

### Mode A — Rerun from failed activity (the common case)
If your pipeline is idempotent (watermark only advances on success, MERGE-based
silver, etc.), use Fabric's built-in **rerun from failed activity**:

Portal: Monitor hub → run → **Rerun** → ▾ → **Rerun from failed activity**.

CLI:
```bash
fab job run "/$FABRIC_WORKSPACE_NAME.Workspace/pl_sql_to_bronze.DataPipeline" \
  --rerun-from-failed --run-id "$RUN_ID"
```

REST:
```bash
curl -s -X POST -H "Authorization: Bearer $FABRIC_TOKEN" \
  "$FABRIC_API/workspaces/$WS_ID/items/$PL_ID/jobs/instances?jobType=Pipeline" \
  -d "{
    \"executionData\": {
      \"runId\": \"$RUN_ID\",
      \"rerunMode\": \"FromFailedActivity\"
    }
  }"
```

### Mode B — Rerun the whole pipeline after manual cleanup
Use when the Copy activity wrote partial data **and** the sink doesn't support
MERGE on rerun (e.g. straight append into bronze). Steps:

1. Identify rows from the failed run by `pipeline().RunId` (you log it as a
   column on bronze — if you don't, start; see `resiliency.md` §2.4).
2. Delete them:
   ```sql
   DELETE FROM lh_bronze.dbo.orders_raw WHERE _ingest_run_id = '4f1b...';
   ```
   Or on a Lakehouse Delta table:
   ```python
   from delta.tables import DeltaTable
   DeltaTable.forName(spark, "lh_bronze.orders_raw") \
     .delete("_ingest_run_id = '4f1b...'")
   ```
3. Confirm watermark **did not** advance (the failure handler in the reference
   pipeline ensures this). Otherwise reset:
   ```sql
   UPDATE ctl.ingest_watermark SET load_watermark = '<previous_value>'
     WHERE source_system='erp' AND source_table='orders';
   ```
4. Rerun the pipeline normally.

### Mode C — Replay a window (backfill)
Use when several scheduled runs failed silently or with bad data:

```bash
for d in 2026-05-15 2026-05-16 2026-05-17 2026-05-18; do
  fab job run "/$FABRIC_WORKSPACE_NAME.Workspace/pl_sql_to_bronze.DataPipeline" \
    --parameters "{\"pSourceSystem\":\"erp\",\"pTable\":\"orders\",\"pRunDate\":\"$d\"}"
done
```

For tumbling-window triggers, the portal exposes **Rerun** on each window slice.

## 7. Common error fingerprints (copy-paste lookup)

| Snippet you see in the error | Almost always means | Try first |
|---|---|---|
| `Login failed for user '<token-identified principal>'` | SP/MI not granted on Azure SQL | `CREATE USER [<sp-name>] FROM EXTERNAL PROVIDER; GRANT SELECT...` |
| `The remote name could not be resolved` | DNS / private endpoint / gateway | Test from the gateway host: `Resolve-DnsName <host>` |
| `Failure happened on 'Sink' side. ErrorCode=DeltaConcurrentAppend` | Two writers to same Delta table | Serialize with `concurrency: 1`, or partition writes |
| `OperationFailed: This request is not authorized to perform this operation using this permission` | OneLake/ADLS RBAC missing **Storage Blob Data Contributor** | Add role assignment on the storage account / workspace identity |
| `Cannot find the object "X" because it does not exist or you do not have permissions` | Warehouse table missing OR SP lacks `db_datareader` | Verify object and grant role |
| `The throttling limit has been reached` (Salesforce/Dynamics/Graph) | Source API rate limit | Lower `parallelCopies`; add Wait; spread over more windows |
| `Conversion failed when converting the nvarchar value` | Type mismatch in mapping | Cast in source query or fix Copy mapping |
| `The maximum number of concurrent connections has been reached` | Source connection pool exhausted | Reduce `parallelCopies`; close idle conns on source |
| `Operation on target X failed: livy session ... failed` | Notebook activity — open the notebook run for the real stack | Click the Livy session link in the activity output |
| `Capacity admin has paused ...` | Capacity paused (cost control) | Resume: `az fabric capacity resume ...` |

## 8. Make next time easier — minimum loggable contract

Every pipeline should write at least this on failure (the reference pipeline
does via `Log_Failure` + `Notify_Teams`):

| Column | Source expression |
|---|---|
| `run_id` | `@pipeline().RunId` |
| `pipeline_name` | `@pipeline().Pipeline` |
| `workspace` | `@pipeline().DataFactory` |
| `trigger_time` | `@pipeline().TriggerTime` |
| `parameters_json` | `@string(pipeline().parameters)` |
| `failed_activity` | `@activity('<name>').name` (from each Failed handler) |
| `error_code` | `@activity('<name>').error.errorCode` |
| `error_message` | `@activity('<name>').error.message` |
| `error_target` | `@activity('<name>').error.failureType` |

Land it in a `ctl.pipeline_errors` Warehouse table. Then post-mortems become a
SQL query, not a portal click-through.

```sql
-- Top failure causes in the last 7 days
SELECT error_code, COUNT(*) AS n, MAX(occurred_at) AS last_seen
FROM   ctl.pipeline_errors
WHERE  occurred_at >= DATEADD(day, -7, SYSUTCDATETIME())
GROUP  BY error_code
ORDER  BY n DESC;
```

See `resiliency.md` next — it turns each row of that table into a design rule.
