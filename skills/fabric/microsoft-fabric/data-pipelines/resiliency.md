# Microsoft Fabric — Pipeline Resiliency

**Use this doc to design Fabric Data Pipelines that fail less often, fail
loudly when they do, and recover automatically when they can.**

For triaging a pipeline that has already failed, see
[`failure-handling.md`](failure-handling.md).

## Resiliency cheat sheet (the 10 rules)

1. **Retry every transient-prone activity** with capped exponential backoff.
2. **Make every load idempotent** (watermark / MERGE / dedupe key).
3. **Stamp every row with `_ingest_run_id`** so you can delete a bad run.
4. **Advance watermarks only on success** — never mid-pipeline.
5. **Dead-letter bad rows**, don't fail the run for data quality alone.
6. **Cap concurrency** at the pipeline + activity + capacity level.
7. **Add a circuit breaker** (`Until` + error counter) for flapping sources.
8. **Serialize writes** to the same Delta/Warehouse table.
9. **Alert on Failed + on Long-Running**, not just Failed.
10. **Promote with Deployment Pipelines + Git**, never edit prod by hand.

The rest of this doc expands each rule with the exact JSON / SQL / CLI.

---

## 1. Retries with capped exponential backoff

Every activity has a `policy` block. Set it on **anything that touches the
network**: Copy, Lookup, Web, Stored procedure, Script, Notebook.

```jsonc
"policy": {
  "timeout":            "0.01:00:00",   // hard timeout per attempt
  "retry":              3,              // up to 3 retries (4 attempts total)
  "retryIntervalInSeconds": 60,         // base interval; Fabric applies exponential backoff
  "secureInput":        false,
  "secureOutput":       false
}
```

Guidelines:

| Activity | retry | retryIntervalInSeconds | timeout |
|---|---|---|---|
| Copy (cloud source, idempotent sink) | 3 | 60 | source-dependent, default `0.02:00:00` |
| Copy (on-prem via gateway) | 5 | 120 | `0.04:00:00` (gateway recycles) |
| Lookup | 2 | 30 | `0.00:05:00` |
| Web / Web hook (REST API) | 3 | 30 | `0.00:10:00` |
| Notebook / Spark Job | 1 | 300 | `0.06:00:00` |
| Stored procedure / Script | 2 | 30 | `0.00:30:00` |

**Anti-pattern**: setting `retry: 10` on a Notebook activity that runs for an
hour — you'll burn capacity for half a day before the run gives up.

## 2. Idempotency — four patterns

Idempotency means "running the same pipeline twice produces the same result
as running it once". Without it, retries and re-runs corrupt data.

### 2.1 Watermark pattern (incremental append)
Implemented in the reference pipeline (`data-pipelines.md` §4). Key points:

- A control table `ctl.ingest_watermark(source_system, source_table, load_watermark)`.
- Read it via Lookup at the top.
- Filter source by `WHERE modified_at > @watermark`.
- Advance via `MERGE` **only after** the Copy succeeds.
- If the Copy fails, watermark stays put; the next run picks up the same
  window. Safe to re-run.

### 2.2 MERGE pattern (silver/gold)
For dimension tables and SCDs, drive silver from bronze with MERGE so partial
re-ingests in bronze don't produce duplicates downstream:

```sql
MERGE silver.customer AS tgt
USING (
  SELECT customer_id,
         MAX(modified_at) AS modified_at,
         ARG_MAX(name, modified_at)  AS name,
         ARG_MAX(email, modified_at) AS email
  FROM   bronze.customer_raw
  WHERE  _ingest_run_id IN (SELECT run_id FROM ctl.unprocessed_runs)
  GROUP  BY customer_id
) AS src
  ON tgt.customer_id = src.customer_id
WHEN MATCHED AND src.modified_at > tgt.modified_at THEN
  UPDATE SET name = src.name, email = src.email, modified_at = src.modified_at
WHEN NOT MATCHED THEN
  INSERT (customer_id, name, email, modified_at)
  VALUES (src.customer_id, src.name, src.email, src.modified_at);
```

In a Notebook activity, equivalent Delta MERGE:

```python
(DeltaTable.forName(spark, "lh_silver.customer").alias("tgt")
    .merge(src_df.alias("src"), "tgt.customer_id = src.customer_id")
    .whenMatchedUpdate(
        condition = "src.modified_at > tgt.modified_at",
        set = {"name": "src.name", "email": "src.email", "modified_at": "src.modified_at"})
    .whenNotMatchedInsertAll()
    .execute())
```

### 2.3 Dedupe-on-read (bronze stays append-only)
Bronze stays an append-only audit log; silver dedupes:

```sql
SELECT *
FROM (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY modified_at DESC,
                                                                _ingest_run_id DESC) rn
  FROM bronze.customer_raw
) t
WHERE rn = 1;
```

### 2.4 Run-ID stamping (the universal escape hatch)
Add a `_ingest_run_id` column to every bronze table, populated by the Copy
activity using `additionalColumns`:

```jsonc
"source": {
  "type": "SqlServerSource",
  "additionalColumns": [
    { "name": "_ingest_run_id",   "value": { "value": "@pipeline().RunId",       "type": "Expression" } },
    { "name": "_ingest_trigger",  "value": { "value": "@pipeline().TriggerTime","type": "Expression" } },
    { "name": "_ingest_pipeline", "value": { "value": "@pipeline().Pipeline",    "type": "Expression" } }
  ]
}
```

Now a bad run is a one-liner to undo (`DELETE WHERE _ingest_run_id = ...`),
and every row is traceable back to a Monitor-hub run.

## 3. Dead-letter for bad rows

Failing a pipeline because 7 of 4 million rows have a NULL FK is bad design.
Use Copy activity **fault tolerance** to split them off instead.

```jsonc
"typeProperties": {
  "enableSkipIncompatibleRow": true,    // type/constraint violations -> log
  "enableSkipIncompatibleRowWhenWrite": true,
  "redirectIncompatibleRowSettings": {
    "linkedServiceName": { "referenceName": "ws-onelake", "type": "LinkedServiceReference" },
    "path": "lh_ops.Lakehouse/Files/dead-letter/@{pipeline().Pipeline}/@{pipeline().RunId}"
  },
  "logSettings": {
    "enableCopyActivityLog": true,
    "copyActivityLogSettings": { "logLevel": "Warning" },
    "logLocationSettings": { /* same path as above */ }
  }
}
```

Then add a post-Copy `If Condition` that fails the run only when the bad-row
ratio exceeds a threshold (e.g. 1%):

```jsonc
{
  "name": "Check_BadRowRatio",
  "type": "IfCondition",
  "dependsOn": [{ "activity": "Copy_Incremental", "dependencyConditions": ["Succeeded"] }],
  "typeProperties": {
    "expression": {
      "value": "@greater(div(activity('Copy_Incremental').output.rowsSkipped, activity('Copy_Incremental').output.rowsRead), 0.01)",
      "type": "Expression"
    },
    "ifTrueActivities": [
      { "name": "Fail_TooDirty", "type": "Fail",
        "typeProperties": { "message": "Bad row ratio exceeded 1%", "errorCode": "DQ_RATIO_EXCEEDED" } }
    ]
  }
}
```

## 4. Concurrency control

Three layers, all matter:

| Layer | Knob | Default | When to lower |
|---|---|---|---|
| **Pipeline** | `properties.concurrency` | unbounded (queue depth) | Same pipeline must not overlap with itself (e.g. long-running ETL) → set to `1` |
| **Activity (ForEach)** | `batchCount` | 20 | If source API throttles or sink locks → set to `4`–`8` |
| **Copy** | `parallelCopies`, `dataIntegrationUnits` | auto | If source throttles → lower `parallelCopies`; if you need throughput → raise `dataIntegrationUnits` (costs more CU) |
| **Capacity** | F SKU + smoothing | F2/F4 trial | If you see `429`/CapacityExceeded → scale up, or move pipelines to a separate capacity |

```jsonc
{ "properties": { "concurrency": 1, "activities": [ ... ] } }
```

## 5. Circuit breaker (stop retrying a dead source)

If a source has been failing for >30 minutes, retrying every 5 minutes is just
burning capacity. Wrap it in an `Until` with a counter and bail out:

```jsonc
{
  "name": "Try_With_CircuitBreaker",
  "type": "Until",
  "typeProperties": {
    "expression": { "value": "@or(equals(variables('vSuccess'), true), greaterOrEquals(variables('vAttempt'), 5))", "type": "Expression" },
    "timeout":    "0.01:00:00",
    "activities": [
      { "name": "Inc_Attempt", "type": "SetVariable",
        "typeProperties": { "variableName": "vAttempt", "value": { "value": "@add(variables('vAttempt'),1)", "type": "Expression" } } },
      { "name": "Try_Web_Call", "type": "WebActivity",
        "policy": { "retry": 0, "timeout": "0.00:02:00" },
        "typeProperties": { "url": "https://api.example.com/data", "method": "GET" } },
      { "name": "Mark_Success", "type": "SetVariable",
        "dependsOn": [{ "activity": "Try_Web_Call", "dependencyConditions": ["Succeeded"] }],
        "typeProperties": { "variableName": "vSuccess", "value": true } },
      { "name": "Backoff_Wait", "type": "Wait",
        "dependsOn": [{ "activity": "Try_Web_Call", "dependencyConditions": ["Failed"] }],
        "typeProperties": { "waitTimeInSeconds": { "value": "@mul(30, variables('vAttempt'))", "type": "Expression" } } }
    ]
  }
}
```

After 5 attempts the loop exits; a follow-up `If Condition` on
`@variables('vSuccess')` fires the alert. The capacity is freed instead of
queued.

## 6. Serialize writes to the same table

`DeltaConcurrentAppend` / `WarehouseTransactionConflict` happens when two
runs MERGE the same table. Options:

- **Pipeline `concurrency: 1`** — simplest; rejects overlapping runs.
- **Sequential `ForEach`** — `isSequential: true`.
- **Partition by load window** — each run writes to a different partition
  (e.g. `load_date=2026-05-20`); MERGE happens in a single nightly compaction
  job.
- **Optimistic retry on the MERGE**: wrap the Script/Notebook activity in
  `retry: 5, retryIntervalInSeconds: 30` — Delta's optimistic concurrency
  will resolve most collisions.

## 7. Alerting (Failed *and* Long-Running)

Two alerts per pipeline, minimum:

### 7.1 In-pipeline failure handler
Already in the reference pipeline (§4 of `data-pipelines.md`): every leaf
activity has a `Failed` dependency edge to a `Script` (log) + Outlook/Teams
(notify). This catches what the pipeline itself knows is broken.

### 7.2 External "missing heartbeat" alert
For "the pipeline didn't run at all" (trigger disabled, capacity paused,
quota exhausted), you need an external watcher:

- **Data Activator** (Fabric) — point at the pipeline run history table and
  trigger when `last_success > 2 hours ago`.
- **Azure Monitor / Log Analytics** — Fabric streams pipeline run telemetry
  via the **Workspace Monitoring** preview; build a KQL alert:

```kql
FabricPipelineRuns
| where TimeGenerated > ago(2h)
| summarize last_success = maxif(TimeGenerated, Status == "Succeeded") by PipelineName
| where last_success < ago(2h) or isnull(last_success)
```

- **Power Automate** flow on the Fabric REST API run history (lowest tech bar).

### 7.3 Long-running alert
Set `policy.elapsedTimeMetric.duration` at pipeline level — Fabric emits an
**ElapsedTimeRuleEvaluation** event when a run blows past it. Wire that into
the same alerting channel as failures.

```jsonc
"policy": { "elapsedTimeMetric": { "duration": "01:00:00" } }
```

## 8. Capacity-aware design

Fabric capacity is **shared across all items in the workspace**. A runaway
notebook will throttle your pipeline. Mitigations:

- **Separate capacities by tier**: `fab-cap-prod-etl` (pipelines + Spark) vs.
  `fab-cap-prod-bi` (semantic models + reports). Bursty BI doesn't kill ETL.
- **Pause non-prod capacities** out of hours:
  ```bash
  az fabric capacity suspend  --resource-group rg-fabric-dev --capacity-name fab-cap-dev
  az fabric capacity resume   --resource-group rg-fabric-dev --capacity-name fab-cap-dev
  ```
- **Use the Capacity Metrics App** (Fabric) to find the top CU consumers; move
  them or rewrite.
- **Smoothing window**: Fabric averages CU usage over 24h for background ops,
  5min for interactive — long pipelines benefit from smoothing, but you still
  burst the interactive budget; schedule heavy work off-peak.

## 9. Multi-region / disaster recovery

Fabric capacity is regional; OneLake data is regional. For DR:

- **Geo-redundant OneLake (preview/GA depending on tenant)** — turn on for
  prod capacities; data replicates to a paired region. RPO ~ minutes; failover
  is a portal action.
- **Git as the source of truth**: pipeline JSON in Git can be deployed to a
  capacity in another region in minutes.
- **Cross-region runbook**:
  1. `fab auth login` against the DR tenant/region.
  2. `fab import` workspace items from the Git repo.
  3. Re-point Connections to DR endpoints (Key Vault references make this
     a config change, not a code change).
  4. Resume schedules.
- **Stateless pipelines + idempotent loads** = DR is "re-run from the last
  watermark on the new capacity", not a custom recovery script.

## 10. Promotion: Deployment Pipelines + Git

Never edit prod by hand. The contract:

1. **Workspaces**: `ws-data-dev`, `ws-data-test`, `ws-data-prod` — one
   capacity each (or shared dev/test capacity).
2. **Git**: dev workspace is Git-connected; feature branches → PR → main.
3. **Deployment Pipeline** binds the three workspaces:
   ```bash
   fab create "/dp-data.DeploymentPipeline" \
     --definition '{"stages":[
        {"displayName":"Dev","workspaceId":"<dev>"},
        {"displayName":"Test","workspaceId":"<test>"},
        {"displayName":"Prod","workspaceId":"<prod>"}]}'
   fab deploy "/dp-data.DeploymentPipeline" --from Dev --to Test
   ```
4. **Deployment rules** rewrite per stage:
   - Connection IDs (dev SQL → prod SQL).
   - Parameters (`pEnvironment` default `dev` → `prod`).
   - Lakehouse references (silver in dev workspace → silver in prod workspace).

Combined with resilient pipelines, this gives you a system where:

- A bad change in dev never touches prod.
- A prod incident can be rolled back by redeploying the previous Git commit.
- DR is a `fab deploy` to a paired region.

---

## Appendix — the resiliency checklist (paste into your PR template)

```
[ ] All network-touching activities have policy.retry >= 2 + retryIntervalInSeconds
[ ] Pipeline-level concurrency set (1 if non-overlapping)
[ ] All bronze writes stamp _ingest_run_id, _ingest_trigger, _ingest_pipeline
[ ] Watermark / MERGE / dedupe pattern documented for this pipeline
[ ] Copy activity has logSettings + dead-letter path in lh_ops
[ ] Failure-branch activities log to ctl.pipeline_errors AND notify oncall
[ ] elapsedTimeMetric.duration set for long-running alert
[ ] External heartbeat alert exists (Activator / KQL / Power Automate)
[ ] Pipeline is in Git; no portal-only edits
[ ] Deployment rules map all Connections + parameters per stage
[ ] DR plan: pipeline runs unchanged on the paired-region workspace
```
