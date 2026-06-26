---
name: databricks-aibi-dashboards
description: "Create Databricks AI/BI dashboards. Use when creating, updating, or deploying Lakeview dashboards. CRITICAL: You MUST test ALL SQL queries via execute_sql BEFORE deploying. Follow guidelines strictly."
---

# AI/BI Dashboard Skill

Create Databricks AI/BI dashboards (formerly Lakeview dashboards). **Follow these guidelines strictly.**

## CRITICAL: MANDATORY VALIDATION WORKFLOW

**You MUST follow this workflow exactly. Skipping validation causes broken dashboards.**

```
┌─────────────────────────────────────────────────────────────────────┐
│  STEP 1: Get table schemas via get_table_stats_and_schema(catalog, schema)  │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 2: Write SQL queries for each dataset                        │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 3: TEST EVERY QUERY via execute_sql() ← DO NOT SKIP!         │
│          - If query fails, FIX IT before proceeding                │
│          - Verify column names match what widgets will reference   │
│          - Verify data types are correct (dates, numbers, strings) │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 4: Build dashboard JSON using ONLY verified queries          │
├─────────────────────────────────────────────────────────────────────┤
│  STEP 5: Deploy via manage_dashboard(action="create_or_update")    │
└─────────────────────────────────────────────────────────────────────┘
```

**WARNING: If you deploy without testing queries, widgets WILL show "Invalid widget definition" errors!**

## Available MCP Tools

| Tool | Description |
|------|-------------|
| `get_table_stats_and_schema` | **STEP 1**: Get table schemas for designing queries |
| `execute_sql` | **STEP 3**: Test SQL queries - MANDATORY before deployment! |
| `manage_warehouse` (action="get_best") | Get available warehouse ID |
| `manage_dashboard` | **STEP 5**: Dashboard lifecycle management (see actions below) |

### manage_dashboard Actions

| Action | Description | Required Params |
|--------|-------------|-----------------|
| `create_or_update` | Deploy dashboard JSON (only after validation!) | display_name, parent_path, serialized_dashboard, warehouse_id |
| `get` | Get dashboard details by ID | dashboard_id |
| `list` | List all dashboards | (none) |
| `delete` | Move dashboard to trash | dashboard_id |
| `publish` | Publish a dashboard | dashboard_id, warehouse_id |
| `unpublish` | Unpublish a dashboard | dashboard_id |

**Example usage:**
```python
# Create/update dashboard
manage_dashboard(
    action="create_or_update",
    display_name="Sales Dashboard",
    parent_path="/Workspace/Users/me/dashboards",
    serialized_dashboard=dashboard_json,
    warehouse_id="abc123",
    publish=True  # auto-publish after create
)

# Get dashboard details
manage_dashboard(action="get", dashboard_id="dashboard_123")

# List all dashboards
manage_dashboard(action="list")
```

## Reference Files

| What are you building? | Reference |
|------------------------|-----------|
| Any widget (text, counter, table, chart) | [1-widget-specifications.md](1-widget-specifications.md) |
| Dashboard with filters (global or page-level) | [2-filters.md](3-filters.md) |
| Need a complete working template to adapt | [3-examples.md](3-examples.md) |
| Debugging a broken dashboard | [4-troubleshooting.md](5-troubleshooting.md) |

---


## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/implementation.md](references/implementation.md) | AI/BI Dashboards — Implementation Guidelines |

## Related Skills

- **[databricks-unity-catalog](../databricks-unity-catalog/SKILL.md)** - for querying the underlying data and system tables
- **[databricks-spark-declarative-pipelines](../databricks-spark-declarative-pipelines/SKILL.md)** - for building the data pipelines that feed dashboards
- **[databricks-jobs](../databricks-jobs/SKILL.md)** - for scheduling dashboard data refreshes
