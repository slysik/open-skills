# Databricks — Most-Performant Default Patterns

What an expert reaches for first, and why it's the performant choice. Load when
designing a build; the router stays thin.

## Compute
- **Serverless / Photon first.** Default to serverless SQL warehouses and
  serverless jobs; Photon is on by default and vectorizes execution.
  *Performant default:* serverless removes cluster spin-up latency and auto-scales.
- Job clusters only for long custom-dependency workloads. Always set **auto-stop**
  (warehouses) / short **auto-termination** (clusters) to kill idle spend.
- Right-size: start small, let autoscaling grow. Don't pre-provision big.

## Storage & layout
- **Medallion** (bronze→silver→gold) via **DLT / Spark Declarative Pipelines** —
  declarative, auto-managed checkpoints, expectations for data quality.
- **Liquid clustering** over manual Z-ORDER/partitioning for new tables —
  self-tuning, no partition-skew foot-guns. *Performant default.*
- Delta with `OPTIMIZE` + predictive optimization; enable Deletion Vectors.

## Governance
- **Unity Catalog is the default** for every table/model/volume — one permission
  model, lineage, and discovery. Three-level namespace `catalog.schema.object`.

## Deploy & ops
- **Databricks Asset Bundles** (`databricks bundle deploy`) for jobs/pipelines/
  models as code — reproducible, env-parameterized, Git-friendly.
- Cost guardrails: budget policies, tags per workload, system tables for spend.

## Performant-default callouts
| Workload | Reach for | Why |
|---|---|---|
| ETL/medallion | DLT + Auto Loader | incremental, schema-evolving, checkpointed |
| Ad-hoc SQL/BI | Serverless SQL warehouse | instant, Photon, auto-stop |
| New big table | Liquid clustering | self-tuning, no partition skew |
| ML serving | Model Serving (serverless) | scale-to-zero endpoints |
| Deploy | Asset Bundles | jobs-as-code, env params |
