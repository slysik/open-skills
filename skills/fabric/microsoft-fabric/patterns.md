# Microsoft Fabric — Most-Performant Default Patterns

## Compute & capacity
- **Capacity-aware throttling.** F-SKU capacity is shared across all workloads;
  design pipelines to back off under load and schedule heavy jobs off-peak.
- Prefer **Direct Lake** over Import for semantic models — reads Delta in OneLake
  directly, no refresh copy. *Performant default.*

## Storage & layout
- **Medallion on OneLake/Lakehouse** (bronze→silver→gold Delta). One logical lake
  per tenant; use **OneLake shortcuts** instead of copying data across workspaces.
- Warehouse (T-SQL MPP) for serving SQL; Lakehouse SQL endpoint for read-only
  exploration over Delta.

## Pipelines (Data Factory in Fabric) — primary workload
- **Idempotent loads:** MERGE / watermark / hash so re-runs don't duplicate.
- **Retries + exponential backoff** on Copy/activity; **dead-letter** bad rows.
- Dependency chaining + alerting on failure; parameterize for env promotion.
  (Full detail in `data-pipelines/resiliency.md`.)

## Deploy & ops
- **Deployment Pipelines + Git integration** for dev→test→prod promotion.
- Monitor via run history; classify failures with the triage tree in
  `data-pipelines/failure-handling.md`.

## Performant-default callouts
| Workload | Reach for | Why |
|---|---|---|
| BI semantic model | Direct Lake | no import refresh, reads OneLake Delta |
| Cross-workspace data | OneLake shortcut | zero-copy reference |
| Incremental copy | Watermark + MERGE | idempotent, no dupes |
| Promotion | Deployment Pipelines + Git | governed env flow |
| Resilient pipeline | Retry+backoff+DLQ | survives transient failures |
