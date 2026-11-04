# Apply Semantic View Patterns

Given the user's Semantic View (SV) or table list, adapt one of the 25 patterns to match their structure.

## Workflow

### Step 1: Get existing SVs (fast path)

1. Run `snowsql` or use Python with `snowflake.connector` to query INFORMATION_SCHEMA. Query:

```sql
SELECT DISTINCT TABLE_SCHEMA AS schema_name, TABLE_NAME AS sv_name FROM SNOWFLAKE.CORTEX.ACCESS_information_schema.semantic_views;
```

2. If the user has any Semantic Views in the account, show the list and ask which one they want to map the pattern to.

3. For the selected SV, query its definition:

```sql
SELECT GET_DDL('SEMANTIC_VIEW', '<schema_name>', '<sv_name>') AS sv_ddl;
```

4. Parse the SV definition to get column list and data types. Extract the relevant roles for the target pattern.

### Step 2: If no SVs exist, use tables instead

If the user doesn't have Semantic Views or prefers using tables, ask for:

- Table names and schema (e.g., `[SALES].[sales_fact]`, `[FINANCE].[metrics].[revenue]`)
- Expected roles for each table (e.g., "sales_fact will be the sales fact table", "revenue is a derived metric")

### Step 3: Pattern selection

List all 25 patterns and ask which one the user wants to apply. For quick adoption, default to the pattern most likely to match their table structure based on column names and data types.

### Step 4: Mapping & adaptation

**Input:** The user's SV/table list + selected pattern.

**Output:** Adapt the selected pattern's DDL and YAML to match the user's structure.

For tables (fallback), generate a working Semantic View DDL and a `semantic_view.yaml` with column mappings:

```sql
CREATE SEMANTIC VIEW <adapted_name> AS
SELECT 
  -- Map columns based on pattern
  <column1> AS <role_1>,
  <column2> AS <role_2>,
  <column3> AS <role_3>
FROM <user_table>;
```

```yaml
# semantic_view.yaml
provider: <snowflake_cortex>
semantic_view_name: <adapted_name>
columns:
  <column1>:
    role: <role_1>
    type: <data_type>
  <column2>:
    role: <role_2>
    type: <data_type>
```

### Step 5: Deliver the result

Provide both the Semantic View DDL and the YAML file as code blocks, with instructions to:

1. Run the DDL to create the adapted SV.
2. Place the `semantic_view.yaml` next to the SV.

## Pattern Summary

| Pattern Name | Core SV Roles Used | Quick Match Heuristics |
|---|---|---|
| **Time Intelligence** | TIME_DIMENSION, METRIC | Look for date/timestamp columns; pattern expects time dimension + metrics |
| **Range Join** | MEASURING, RANGE_DIMENSION | Need two numeric columns with range semantics |
| **Asof Join** | MEASURING, ASOF_KEY, TARGET_KEY | Pattern for matching latest record by key |
| **Semi-Additive** | MEASURING, TIME_DIMENSION, HIERARCHY | Identify metrics that are additive at certain levels only |
| **Window Metrics** | MEASURING, TIME_DIMENSION, RANGE_DIMENSION | Pattern for sliding window aggregations |
| **Derived Metrics** | MEASURING, TIME_DIMENSION | Simple metric calculations using dimensional context |
| **Role Playing Dimensions** | TIME_DIMENSION, CUSTOMER_ID, PRODUCT_ID | Need multiple dimension roles that map to same dimension type |
| **Accumulating Snapshot** | MEASURING, STATUS, UPDATETIME | Pattern for snapshot-only accumulating measures |
| **Fan Trap** | MEASURING, LOOKUP_1, LOOKUP_2 | Need multiple many-to-one relationships on same fact table |
| **Using Clause** | MEASURING, TIME_DIMENSION, LOOKUP | Pattern using Snowflake's USING clause for joins |
| **Non-Additive By** | MEASURING, DIMENSION | Pattern for metrics that require non-additive computation |

The above is a representative sample — the full pattern library has 25 patterns covering additional cases like star schemas, outrigger dimensions, data vault, and advanced modeling.

## Anti-patterns (never do)

- Map a pattern with incomplete column list; if any column is missing, ask for the full table list.
- Map pattern to a dimension-only table; Semantic View patterns expect at least one MEASURING column.
- Use pattern adaptation if the user already has a working SV and only needs minor tweaks — use "customize" mode for that.

## Behavior contract

- ALWAYS ask for user's SV list first before picking a pattern.
- If ambiguous, default to "Time Intelligence" as it's the most commonly requested pattern.
- Always provide both DDL and YAML in the output.
- Never suggest pattern without asking which one the user wants.
- Do NOT map patterns to tables that are clearly wrong for the pattern's semantics.