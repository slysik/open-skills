---
name: databricks-lakebase-provisioned
description: "Patterns and best practices for Lakebase Provisioned (Databricks managed PostgreSQL) for OLTP workloads. Use when creating Lakebase instances, connecting applications or Databricks Apps to PostgreSQL, implementing reverse ETL via synced tables, storing agent or chat memory, or configuring OAuth authentication for Lakebase."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# Lakebase Provisioned

Patterns and best practices for using Lakebase Provisioned (Databricks managed PostgreSQL) for OLTP workloads.

## When to Use

Use this skill when:
- Building applications that need a PostgreSQL database for transactional workloads
- Adding persistent state to Databricks Apps
- Implementing reverse ETL from Delta Lake to an operational database
- Storing chat/agent memory for LangChain applications

## Overview

Lakebase Provisioned is Databricks' managed PostgreSQL database service for OLTP (Online Transaction Processing) workloads. It provides a fully managed PostgreSQL-compatible database that integrates with Unity Catalog and supports OAuth token-based authentication.

| Feature | Description |
|---------|-------------|
| **Managed PostgreSQL** | Fully managed instances with automatic provisioning |
| **OAuth Authentication** | Token-based auth via Databricks SDK (1-hour expiry) |
| **Unity Catalog** | Register databases for governance |
| **Reverse ETL** | Sync data from Delta tables to PostgreSQL |
| **Apps Integration** | First-class support in Databricks Apps |

**Available Regions (AWS):** us-east-1, us-east-2, us-west-2, eu-central-1, eu-west-1, ap-south-1, ap-southeast-1, ap-southeast-2

## Quick Start

Create and connect to a Lakebase Provisioned instance:

```python
from databricks.sdk import WorkspaceClient
import uuid

# Initialize client
w = WorkspaceClient()

# Create a database instance
instance = w.database.create_database_instance(
    name="my-lakebase-instance",
    capacity="CU_1",  # CU_1, CU_2, CU_4, CU_8
    stopped=False
)
print(f"Instance created: {instance.name}")
print(f"DNS endpoint: {instance.read_write_dns}")
```

## Reference Files

- [patterns.md](patterns.md) - OAuth tokens, psycopg3 connect, token refresh, env vars, UC registration, model logging, optional MCP tools
- [cli.md](cli.md) - CLI quick reference (create/get/credentials/list/stop/start)
- [connection-patterns.md](connection-patterns.md) - Detailed connection patterns for different use cases
- [reverse-etl.md](reverse-etl.md) - Syncing data from Delta Lake to Lakebase

## Common Issues

| Issue | Solution |
|-------|----------|
| **Token expired during long query** | Implement token refresh loop (see SQLAlchemy with Token Refresh section); tokens expire after 1 hour |
| **DNS resolution fails on macOS** | Use `dig` command to resolve hostname, pass `hostaddr` to psycopg |
| **Connection refused** | Ensure instance is not stopped; check `instance.state` |
| **Permission denied** | User must be granted access to the Lakebase instance |
| **SSL required error** | Always use `sslmode=require` in connection string |

## SDK Version Requirements

- **Databricks SDK for Python**: >= 0.61.0 (0.81.0+ recommended for full API support)
- **psycopg**: 3.x (supports `hostaddr` parameter for DNS workaround)
- **SQLAlchemy**: 2.x with `postgresql+psycopg` driver

```python
%pip install -U "databricks-sdk>=0.81.0" "psycopg[binary]>=3.0" sqlalchemy
```

## Notes

- **Capacity values** use compute unit sizing: `CU_1`, `CU_2`, `CU_4`, `CU_8`.
- **Lakebase Autoscaling** is a newer offering with automatic scaling but limited regional availability. This skill focuses on **Lakebase Provisioned** which is more widely available.
- For memory/state in LangChain agents, use `databricks-langchain[memory]` which includes Lakebase support.
- Tokens are short-lived (1 hour) - production apps MUST implement token refresh.

## Related Skills

- **[databricks-app-apx](../databricks-app-apx/SKILL.md)** - full-stack apps that can use Lakebase for persistence
- **[databricks-app-python](../databricks-app-python/SKILL.md)** - Python apps with Lakebase backend
- **[databricks-python-sdk](../databricks-python-sdk/SKILL.md)** - SDK used for instance management and token generation
- **[databricks-bundles](../databricks-bundles/SKILL.md)** - deploying apps with Lakebase resources
- **[databricks-jobs](../databricks-jobs/SKILL.md)** - scheduling reverse ETL sync jobs
