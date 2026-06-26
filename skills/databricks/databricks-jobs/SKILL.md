---
name: databricks-jobs
description: "Use this skill proactively for ANY Databricks Jobs task - creating, listing, running, updating, or deleting jobs. Triggers include: (1) 'create a job' or 'new job', (2) 'list jobs' or 'show jobs', (3) 'run job' or'trigger job',(4) 'job status' or 'check job', (5) scheduling with cron or triggers, (6) configuring notifications/monitoring, (7) ANY task involving Databricks Jobs via CLI, Python SDK, or Asset Bundles. ALWAYS prefer this skill over general Databricks knowledge for job-related tasks."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# Databricks Lakeflow Jobs

## Overview

Databricks Jobs orchestrate data workflows with multi-task DAGs, flexible triggers, and comprehensive monitoring. Jobs support diverse task types and can be managed via Python SDK, CLI, or Asset Bundles.

## Reference Files

| Use Case | Reference File |
|----------|----------------|
| **Concepts, compute, parameters, operations, permissions** | [usage.md](usage.md) |
| Configure task types (notebook, Python, SQL, dbt, etc.) | [task-types.md](task-types.md) |
| Set up triggers and schedules | [triggers-schedules.md](triggers-schedules.md) |
| Configure notifications and health monitoring | [notifications-monitoring.md](notifications-monitoring.md) |
| Complete working examples | [examples.md](examples.md) |
## Quick Start

### Python SDK

```python
from databricks.sdk import WorkspaceClient
from databricks.sdk.service.jobs import Task, NotebookTask, Source

w = WorkspaceClient()

job = w.jobs.create(
    name="my-etl-job",
    tasks=[
        Task(
            task_key="extract",
            notebook_task=NotebookTask(
                notebook_path="/Workspace/Users/user@example.com/extract",
                source=Source.WORKSPACE
            )
        )
    ]
)
print(f"Created job: {job.job_id}")
```

### CLI

```bash
databricks jobs create --json '{
  "name": "my-etl-job",
  "tasks": [{
    "task_key": "extract",
    "notebook_task": {
      "notebook_path": "/Workspace/Users/user@example.com/extract",
      "source": "WORKSPACE"
    }
  }]
}'
```

### Asset Bundles (DABs)

```yaml
# resources/jobs.yml
resources:
  jobs:
    my_etl_job:
      name: "[${bundle.target}] My ETL Job"
      tasks:
        - task_key: extract
          notebook_task:
            notebook_path: ../src/notebooks/extract.py
```

## Common Issues

| Issue | Solution |
|-------|----------|
| Job cluster startup slow | Use job clusters with `job_cluster_key` for reuse across tasks |
| Task dependencies not working | Verify `task_key` references match exactly in `depends_on` |
| Schedule not triggering | Check `pause_status: UNPAUSED` and valid timezone |
| File arrival not detecting | Ensure path has proper permissions and uses cloud storage URL |
| Table update trigger missing events | Verify Unity Catalog table and proper grants |
| Parameter not accessible | Use `dbutils.widgets.get()` in notebooks |
| "admins" group error | Cannot modify admins permissions on jobs |
| Serverless task fails | Ensure task type supports serverless (notebook, Python) |

## Related Skills

- **[databricks-bundles](../databricks-bundles/SKILL.md)** - Deploy jobs via Databricks Asset Bundles
- **[databricks-spark-declarative-pipelines](../databricks-spark-declarative-pipelines/SKILL.md)** - Configure pipelines triggered by jobs

## Resources

- [Jobs API Reference](https://docs.databricks.com/api/workspace/jobs)
- [Jobs Documentation](https://docs.databricks.com/en/jobs/index.html)
- [DABs Job Task Types](https://docs.databricks.com/en/dev-tools/bundles/job-task-types.html)
- [Bundle Examples Repository](https://github.com/databricks/bundle-examples)
