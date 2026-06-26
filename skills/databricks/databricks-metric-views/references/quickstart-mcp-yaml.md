# Metric Views — Quick Start, MCP Tools, YAML Spec Quick Reference

> Detail moved out of the router. Router: ../SKILL.md (or SKILL.md)

## Quick Start

### Inspect Source Table Schema

Before creating a metric view, call `get_table_stats_and_schema` to understand available columns for dimensions and measures:

```
get_table_stats_and_schema(
    catalog="catalog",
    schema="schema",
    table_names=["orders"],
    table_stat_level="SIMPLE"  # Use "DETAILED" for cardinality, min/max, histograms
)
```

### Create a Metric View

```sql
CREATE OR REPLACE VIEW catalog.schema.orders_metrics
WITH METRICS
LANGUAGE YAML
AS $$
  version: 1.1
  source: catalog.schema.orders
  comment: "Orders KPIs for sales analysis"
  filter: order_date > '2020-01-01'
  dimensions:
    - name: Order Month
      expr: DATE_TRUNC('MONTH', order_date)
      comment: "Month of order"
    - name: Order Status
      expr: CASE
        WHEN status = 'O' THEN 'Open'
        WHEN status = 'P' THEN 'Processing'
        WHEN status = 'F' THEN 'Fulfilled'
        END
      comment: "Human-readable order status"
  measures:
    - name: Order Count
      expr: COUNT(1)
    - name: Total Revenue
      expr: SUM(total_price)
      comment: "Sum of total price"
    - name: Revenue per Customer
      expr: SUM(total_price) / COUNT(DISTINCT customer_id)
      comment: "Average revenue per unique customer"
$$
```

### Query a Metric View

All measures must use the `MEASURE()` function. `SELECT *` is NOT supported.

```sql
SELECT
  `Order Month`,
  `Order Status`,
  MEASURE(`Total Revenue`) AS total_revenue,
  MEASURE(`Order Count`) AS order_count
FROM catalog.schema.orders_metrics
WHERE extract(year FROM `Order Month`) = 2024
GROUP BY ALL
ORDER BY ALL
```

## Reference Files

| Topic | File | Description |
|-------|------|-------------|
| YAML Syntax | [yaml-reference.md](yaml-reference.md) | Complete YAML spec: dimensions, measures, joins, materialization |
| Patterns & Examples | [patterns.md](patterns.md) | Common patterns: star schema, snowflake, filtered measures, window measures, ratios |

## MCP Tools

Use the `manage_metric_views` tool for all metric view operations:

| Action | Description |
|--------|-------------|
| `create` | Create a metric view with dimensions and measures |
| `alter` | Update a metric view's YAML definition |
| `describe` | Get the full definition and metadata |
| `query` | Query measures grouped by dimensions |
| `drop` | Drop a metric view |
| `grant` | Grant SELECT privileges to users/groups |

### Create via MCP

```python
manage_metric_views(
    action="create",
    full_name="catalog.schema.orders_metrics",
    source="catalog.schema.orders",
    or_replace=True,
    comment="Orders KPIs for sales analysis",
    filter_expr="order_date > '2020-01-01'",
    dimensions=[
        {"name": "Order Month", "expr": "DATE_TRUNC('MONTH', order_date)", "comment": "Month of order"},
        {"name": "Order Status", "expr": "status"},
    ],
    measures=[
        {"name": "Order Count", "expr": "COUNT(1)"},
        {"name": "Total Revenue", "expr": "SUM(total_price)", "comment": "Sum of total price"},
    ],
)
```

### Query via MCP

```python
manage_metric_views(
    action="query",
    full_name="catalog.schema.orders_metrics",
    query_measures=["Total Revenue", "Order Count"],
    query_dimensions=["Order Month"],
    where="extract(year FROM `Order Month`) = 2024",
    order_by="ALL",
    limit=100,
)
```

### Describe via MCP

```python
manage_metric_views(
    action="describe",
    full_name="catalog.schema.orders_metrics",
)
```

### Grant Access

```python
manage_metric_views(
    action="grant",
    full_name="catalog.schema.orders_metrics",
    principal="data-consumers",
    privileges=["SELECT"],
)
```

## YAML Spec Quick Reference

```yaml
version: 1.1                    # Required: "1.1" for DBR 17.2+
source: catalog.schema.table    # Required: source table/view
comment: "Description"          # Optional: metric view description
filter: column > value          # Optional: global WHERE filter

dimensions:                     # Required: at least one
  - name: Display Name          # Backtick-quoted in queries
    expr: sql_expression        # Column ref or SQL transformation
    comment: "Description"      # Optional (v1.1+)

measures:                       # Required: at least one
  - name: Display Name          # Queried via MEASURE(`name`)
    expr: AGG_FUNC(column)      # Must be an aggregate expression
    comment: "Description"      # Optional (v1.1+)

joins:                          # Optional: star/snowflake schema
  - name: dim_table
    source: catalog.schema.dim_table
    on: source.fk = dim_table.pk

materialization:                # Optional (experimental)
  schedule: every 6 hours
  mode: relaxed
```

