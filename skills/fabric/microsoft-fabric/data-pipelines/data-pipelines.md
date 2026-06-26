# Microsoft Fabric — Data Pipelines

Fabric Data Pipelines = the Data Factory orchestration experience inside
Fabric. Same authoring model as Azure Data Factory (ADF) and Synapse Pipelines
(activities, expressions `@`-syntax, parameters, variables, triggers) but
running on **Fabric capacity**, writing to **OneLake**, and exposed through the
**Fabric REST API** instead of the ADF/Synapse ARM surface.

This doc covers **creation**. For failures see `failure-handling.md`. For
design-time defenses see `resiliency.md`.

## 1. Anatomy of a Fabric pipeline

A pipeline is a JSON document with this top-level shape:

```jsonc
{
  "properties": {
    "activities": [ /* ordered DAG of activities */ ],
    "parameters": {
      "pRunDate":      { "type": "string", "defaultValue": "@utcnow()" },
      "pSourceSystem": { "type": "string" },
      "pEnvironment":  { "type": "string", "defaultValue": "dev" }
    },
    "variables": {
      "vWatermark": { "type": "String" },
      "vRowCount":  { "type": "Integer" }
    },
    "annotations": ["domain=finance", "owner=data-eng@contoso.com"],
    "concurrency": 4,
    "policy": { "elapsedTimeMetric": { "duration": "01:00:00" } }
  }
}
```

Key building blocks:

| Concept | What it is | Notes |
|---|---|---|
| **Activity** | One step (Copy, Lookup, ForEach, Notebook, …) | Has `dependsOn` (Succeeded/Failed/Skipped/Completed), `policy` (retry/timeout), `userProperties`. |
| **Connection** | Auth + endpoint for a source/sink | Created once at workspace/tenant scope; pipelines reference by `id`. **Replaces ADF Linked Services.** |
| **Dataset (implicit)** | Source/sink path + format inside an activity | Fabric inlines what ADF called Datasets — no separate dataset objects. |
| **Parameter** | Set at run start; immutable for the run | Used for templating. |
| **Variable** | Mutable during the run via `Set Variable` | Used for watermarks, row counts, retry counters. |
| **Trigger** | Schedule / tumbling window / storage event | In Fabric, triggers are configured via the **schedule** API on the item, not as separate trigger objects. |

## 2. Activity reference (the ones you actually use)

### Movement
- **Copy data** — the workhorse. Source → sink with built-in mapping,
  fault tolerance, staging, parallelism, partitioning.
- **Dataflow** — invoke a Dataflow Gen2 (low-code M / Power Query).

### Transformation
- **Notebook** — run a Fabric notebook (PySpark / SparkSQL / Spark Scala / SparkR).
- **Spark Job Definition** — run a packaged Spark job.
- **Script** / **Stored procedure** — execute T-SQL on the Warehouse or SQL endpoint.

### Control flow
- **Lookup** — read up to 5,000 rows; great for control-table-driven pipelines.
- **Get Metadata** — list files / get last modified for event-style logic.
- **ForEach** — iterate (sequential or parallel up to `batchCount=50`).
- **If Condition** / **Switch** — branching.
- **Until** — do-while with `timeout`.
- **Wait** — sleep.
- **Set Variable** / **Append Variable** — mutate run state.
- **Invoke Pipeline** — call another pipeline (sync or fire-and-forget).
- **Fail** — explicitly fail a run with a message/code.

### External
- **Web** / **Web hook** — call REST APIs; Web hook waits for callback.
- **Azure Function** — invoke an Azure Function.
- **Office 365 Outlook** — send mail (great for failure notifications without a Logic App).
- **Teams** — post to a channel.

### Lakehouse-specific
- **Office 365 Outlook**, **Functions**, etc., behave the same as ADF; the new
  ones in Fabric are **OneLake** sources/sinks (DFS Gen2 endpoint
  `abfss://<workspace>@onelake.dfs.fabric.microsoft.com/<lakehouse>.Lakehouse/Files/...`).

## 3. Creating a pipeline — three paths

### A. Fabric portal (low-code, fastest for one-offs)
1. Workspace → **+ New** → **Data pipeline** → name it `pl_<source>_to_<sink>`.
2. Drag activities, wire `Success` (green), `Failure` (red), `Completion`
   (blue), `Skipped` (gray) arrows.
3. **Parameters** tab for inputs; **Variables** for runtime state.
4. **Save** then **Run** (ad-hoc) or **Schedule**.

### B. `fab` CLI from JSON definition (recommended for repeatable / Git-friendly)

```bash
# Author once, store in Git as ./pipelines/pl_sql_to_bronze.json
fab create "/$FABRIC_WORKSPACE_NAME.Workspace/pl_sql_to_bronze.DataPipeline" \
  --definition ./pipelines/pl_sql_to_bronze.json

# Update an existing one
fab update "/$FABRIC_WORKSPACE_NAME.Workspace/pl_sql_to_bronze.DataPipeline" \
  --definition ./pipelines/pl_sql_to_bronze.json

# Run with parameters
fab job run "/$FABRIC_WORKSPACE_NAME.Workspace/pl_sql_to_bronze.DataPipeline" \
  --parameters '{"pSourceSystem":"erp","pRunDate":"2026-05-20"}'
```

### C. Raw REST (when `fab` is missing an op or for CI)

```bash
WS_ID=$(curl -s -H "Authorization: Bearer $FABRIC_TOKEN" \
  "$FABRIC_API/workspaces" \
  | jq -r '.value[] | select(.displayName=="'"$FABRIC_WORKSPACE_NAME"'") | .id')

# Definition payload: base64-encoded JSON
DEF_B64=$(base64 -w0 ./pipelines/pl_sql_to_bronze.json)

curl -s -X POST -H "Authorization: Bearer $FABRIC_TOKEN" \
  -H "Content-Type: application/json" \
  "$FABRIC_API/workspaces/$WS_ID/dataPipelines" \
  -d "{
    \"displayName\": \"pl_sql_to_bronze\",
    \"definition\": {
      \"parts\": [
        { \"path\": \"pipeline-content.json\",
          \"payload\": \"$DEF_B64\",
          \"payloadType\": \"InlineBase64\" }
      ]
    }
  }"
```

To run it on demand:

```bash
PL_ID=$(curl -s -H "Authorization: Bearer $FABRIC_TOKEN" \
  "$FABRIC_API/workspaces/$WS_ID/dataPipelines" \
  | jq -r '.value[] | select(.displayName=="pl_sql_to_bronze") | .id')

curl -s -X POST -H "Authorization: Bearer $FABRIC_TOKEN" \
  -H "Content-Type: application/json" \
  "$FABRIC_API/workspaces/$WS_ID/items/$PL_ID/jobs/instances?jobType=Pipeline" \
  -d '{
    "executionData": {
      "parameters": { "pSourceSystem": "erp", "pRunDate": "2026-05-20" }
    }
  }'
```

## 4. A reference pipeline definition (incremental copy with watermark)

`./pipelines/pl_sql_to_bronze.json` — copy a SQL Server table into a Lakehouse
Delta table using a watermark, idempotent on re-run, with per-activity retry
and a failure handler.

```jsonc
{
  "properties": {
    "parameters": {
      "pSourceSystem":  { "type": "string" },
      "pTable":         { "type": "string" },
      "pRunDate":       { "type": "string", "defaultValue": "@utcnow()" }
    },
    "variables": {
      "vHighWatermark": { "type": "String" },
      "vRowsCopied":    { "type": "Integer" }
    },
    "activities": [

      /* 1. Read current high-watermark from control table in Warehouse */
      {
        "name": "Lookup_Watermark",
        "type": "Lookup",
        "policy": { "timeout": "0.00:05:00", "retry": 2, "retryIntervalInSeconds": 30 },
        "typeProperties": {
          "source": {
            "type": "DataWarehouseSource",
            "sqlReaderQuery": {
              "value": "SELECT ISNULL(MAX(load_watermark),'1900-01-01') AS wm FROM ctl.ingest_watermark WHERE source_system=@{pipeline().parameters.pSourceSystem} AND source_table=@{pipeline().parameters.pTable}",
              "type": "Expression"
            }
          },
          "firstRowOnly": true
        }
      },

      /* 2. Stash the watermark in a variable */
      {
        "name": "Set_Watermark",
        "type": "SetVariable",
        "dependsOn": [{ "activity": "Lookup_Watermark", "dependencyConditions": ["Succeeded"] }],
        "typeProperties": {
          "variableName": "vHighWatermark",
          "value": { "value": "@activity('Lookup_Watermark').output.firstRow.wm", "type": "Expression" }
        }
      },

      /* 3. Incremental Copy SQL -> Lakehouse Delta */
      {
        "name": "Copy_Incremental",
        "type": "Copy",
        "dependsOn": [{ "activity": "Set_Watermark", "dependencyConditions": ["Succeeded"] }],
        "policy": { "timeout": "0.02:00:00", "retry": 3, "retryIntervalInSeconds": 60 },
        "typeProperties": {
          "source": {
            "type": "SqlServerSource",
            "sqlReaderQuery": {
              "value": "SELECT * FROM @{pipeline().parameters.pTable} WHERE modified_at > '@{variables('vHighWatermark')}'",
              "type": "Expression"
            },
            "partitionOption": "DynamicRange",
            "partitionSettings": { "partitionColumnName": "id", "partitionUpperBound": "@{int(activity('Lookup_Watermark').output.firstRow.maxid)}", "partitionLowerBound": "0" }
          },
          "sink": {
            "type": "LakehouseTableSink",
            "tableActionOption": "Append"   /* MERGE handled downstream in silver */
          },
          "enableStaging": false,
          "parallelCopies": 4,
          "dataIntegrationUnits": 8,
          "enableSkipIncompatibleRow": true,   /* fault tolerance: log bad rows, keep going */
          "logSettings": {
            "enableCopyActivityLog": true,
            "copyActivityLogSettings": { "logLevel": "Warning" },
            "logLocationSettings": {
              "linkedServiceName": { "referenceName": "ws-onelake", "type": "LinkedServiceReference" },
              "path": "lh_ops.Lakehouse/Files/copy-logs/@{pipeline().Pipeline}/@{pipeline().RunId}"
            }
          }
        }
      },

      /* 4. Capture row count for monitoring */
      {
        "name": "Set_RowCount",
        "type": "SetVariable",
        "dependsOn": [{ "activity": "Copy_Incremental", "dependencyConditions": ["Succeeded"] }],
        "typeProperties": {
          "variableName": "vRowsCopied",
          "value": { "value": "@activity('Copy_Incremental').output.rowsCopied", "type": "Expression" }
        }
      },

      /* 5. Advance the watermark only on success */
      {
        "name": "Advance_Watermark",
        "type": "Script",
        "dependsOn": [{ "activity": "Set_RowCount", "dependencyConditions": ["Succeeded"] }],
        "typeProperties": {
          "scripts": [{
            "type": "NonQuery",
            "text": {
              "value": "MERGE ctl.ingest_watermark AS t USING (SELECT @{pipeline().parameters.pSourceSystem} src, @{pipeline().parameters.pTable} tbl, '@{pipeline().TriggerTime}' wm) AS s ON t.source_system=s.src AND t.source_table=s.tbl WHEN MATCHED THEN UPDATE SET load_watermark=s.wm WHEN NOT MATCHED THEN INSERT (source_system,source_table,load_watermark) VALUES (s.src,s.tbl,s.wm);",
              "type": "Expression"
            }
          }]
        }
      },

      /* 6. Failure handler — runs only if any of the above failed */
      {
        "name": "Log_Failure",
        "type": "Script",
        "dependsOn": [
          { "activity": "Copy_Incremental",   "dependencyConditions": ["Failed"] },
          { "activity": "Advance_Watermark",  "dependencyConditions": ["Failed"] }
        ],
        "typeProperties": {
          "scripts": [{
            "type": "NonQuery",
            "text": {
              "value": "INSERT ctl.pipeline_errors(run_id,pipeline_name,source_system,source_table,error_message,occurred_at) VALUES ('@{pipeline().RunId}','@{pipeline().Pipeline}',@{pipeline().parameters.pSourceSystem},@{pipeline().parameters.pTable},'@{activity('Copy_Incremental').error.message}','@{utcnow()}');",
              "type": "Expression"
            }
          }]
        }
      },

      /* 7. Notify on failure */
      {
        "name": "Notify_Teams",
        "type": "Office365Outlook",
        "dependsOn": [{ "activity": "Log_Failure", "dependencyConditions": ["Succeeded"] }],
        "typeProperties": {
          "to":      "data-oncall@contoso.com",
          "subject": "Fabric pipeline FAILED: @{pipeline().Pipeline} (@{pipeline().parameters.pTable})",
          "body":    "RunId: @{pipeline().RunId}\nWorkspace: @{pipeline().DataFactory}\nError: @{activity('Copy_Incremental').error.message}"
        }
      }
    ]
  }
}
```

What to notice:

- Retries are **per activity** in `policy.retry` + `policy.retryIntervalInSeconds`.
- `enableSkipIncompatibleRow` + `logSettings` push bad rows to a OneLake folder
  instead of failing the run (a form of dead-letter).
- The watermark is only advanced on success, so re-runs are **idempotent**.
- `Log_Failure` and `Notify_Teams` depend on `Failed`, giving you the standard
  failure-branch pattern without a separate orchestrator.

## 5. Triggers (schedules)

Fabric exposes scheduling as a property on the pipeline item:

```bash
fab job schedule create "/$FABRIC_WORKSPACE_NAME.Workspace/pl_sql_to_bronze.DataPipeline" \
  --enabled true \
  --type Cron \
  --expression "0 0 */1 * * *"   # hourly
```

Raw REST:

```bash
curl -s -X POST -H "Authorization: Bearer $FABRIC_TOKEN" \
  -H "Content-Type: application/json" \
  "$FABRIC_API/workspaces/$WS_ID/items/$PL_ID/jobs/Pipeline/schedules" \
  -d '{
    "enabled": true,
    "configuration": {
      "type": "Cron",
      "interval": 60,
      "startDateTime": "2026-05-20T00:00:00",
      "endDateTime":   "2099-01-01T00:00:00",
      "localTimeZoneId": "UTC"
    }
  }'
```

For event-based ("when a blob lands"), use a **Storage event trigger** on an
ADLS Gen2 / Blob source — configured in the portal under
**Triggers → New → Storage events**.

## 6. Connections & gateways

- **Cloud connection** (e.g. Azure SQL with Entra auth): created in Fabric
  portal → **Manage connections and gateways** → New → Cloud. The pipeline
  references it by GUID, not by credential.
- **On-prem source**: install the **On-premises data gateway** (same binary as
  Power BI gateway, version Nov 2023+), register it in Fabric under
  **Gateways**, then create a connection that uses the gateway. Pipelines
  see no difference — same Copy activity.
- **Managed identity** (workspace identity): the cleanest option for accessing
  Azure resources (Key Vault, Storage, SQL with Entra). Grant the workspace
  identity the right RBAC role on the target resource; no secret needed.

## 7. Monitoring (the read path)

```bash
# Last 20 runs of a pipeline
fab job run-list "/$FABRIC_WORKSPACE_NAME.Workspace/pl_sql_to_bronze.DataPipeline" --top 20

# Detailed status of a specific run
fab job run-status "/$FABRIC_WORKSPACE_NAME.Workspace/pl_sql_to_bronze.DataPipeline" \
  --run-id 4f1b...

# Raw REST: list job instances
curl -s -H "Authorization: Bearer $FABRIC_TOKEN" \
  "$FABRIC_API/workspaces/$WS_ID/items/$PL_ID/jobs/instances" \
  | jq '.value[] | {id, status, startTimeUtc, endTimeUtc, failureReason}'
```

In the portal: **Monitor hub** → filter by item type **Data pipeline**. Each
run shows the activity-level Gantt with input/output, error message, and a
"Rerun from failed activity" button — covered in detail in `failure-handling.md`.

## 8. CI / CD

1. **Git-connect the workspace** (Workspace settings → Git integration →
   Azure DevOps or GitHub). Fabric serializes pipelines as JSON under
   `/<item>.DataPipeline/pipeline-content.json`.
2. Branch per feature; merge to `main` deploys back to the dev workspace.
3. **Deployment Pipelines** (Fabric feature) promote dev → test → prod with
   rules that rewrite connection IDs and parameters per stage.
4. CI: `fab` commands run from GitHub Actions / Azure DevOps using a service
   principal with workspace **Member** or **Admin** role.

```yaml
# .github/workflows/fabric-deploy.yml (snippet)
- name: Install fab
  run: pip install ms-fabric-cli
- name: Login
  run: |
    fab auth login --service-principal \
      --tenant "${{ secrets.AZURE_TENANT_ID }}" \
      --client-id "${{ secrets.AZURE_CLIENT_ID }}" \
      --client-secret "${{ secrets.AZURE_CLIENT_SECRET }}"
- name: Deploy pipeline
  run: |
    fab update "/ws-data-test.Workspace/pl_sql_to_bronze.DataPipeline" \
      --definition pipelines/pl_sql_to_bronze.json
```

Next, see:
- [`failure-handling.md`](failure-handling.md) — triage a failed run.
- [`resiliency.md`](resiliency.md) — design patterns so they don't fail.
