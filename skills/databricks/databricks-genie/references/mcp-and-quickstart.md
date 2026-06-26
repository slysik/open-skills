# Genie — MCP tools + quick start

> Detail moved out of the router. Router: ../SKILL.md (or SKILL.md)

## MCP Tools

| Tool | Purpose |
|------|---------|
| `manage_genie` | Create, get, list, delete, export, and import Genie Spaces |
| `ask_genie` | Ask natural language questions to a Genie Space |
| `get_table_stats_and_schema` | Inspect table schemas before creating a space |
| `execute_sql` | Test SQL queries directly |

### manage_genie - Space Management

| Action | Description | Required Params |
|--------|-------------|-----------------|
| `create_or_update` | Idempotent create/update a space | display_name, table_identifiers (or serialized_space) |
| `get` | Get space details | space_id |
| `list` | List all spaces | (none) |
| `delete` | Delete a space | space_id |
| `export` | Export space config for migration/backup | space_id |
| `import` | Import space from serialized config | warehouse_id, serialized_space |

**Example tool calls:**
```
# MCP Tool: manage_genie
# Create a new space
manage_genie(
    action="create_or_update",
    display_name="Sales Analytics",
    table_identifiers=["catalog.schema.customers", "catalog.schema.orders"],
    description="Explore sales data with natural language",
    sample_questions=["What were total sales last month?"]
)

# MCP Tool: manage_genie
# Get space details with full config
manage_genie(action="get", space_id="space_123", include_serialized_space=True)

# MCP Tool: manage_genie
# List all spaces
manage_genie(action="list")

# MCP Tool: manage_genie
# Export for migration
exported = manage_genie(action="export", space_id="space_123")

# MCP Tool: manage_genie
# Import to new workspace
manage_genie(
    action="import",
    warehouse_id="warehouse_456",
    serialized_space=exported["serialized_space"],
    title="Sales Analytics (Prod)"
)
```

### ask_genie - Conversation API (Query)

Ask natural language questions to a Genie Space. Pass `conversation_id` for follow-up questions.

```
# MCP Tool: ask_genie
# Start a new conversation
result = ask_genie(
    space_id="space_123",
    question="What were total sales last month?"
)
# Returns: {question, conversation_id, message_id, status, sql, columns, data, row_count}

# MCP Tool: ask_genie
# Follow-up question in same conversation
result = ask_genie(
    space_id="space_123",
    question="Break that down by region",
    conversation_id=result["conversation_id"]
)
```

## Quick Start

### 1. Inspect Your Tables

Before creating a Genie Space, understand your data:

```
# MCP Tool: get_table_stats_and_schema
get_table_stats_and_schema(
    catalog="my_catalog",
    schema="sales",
    table_stat_level="SIMPLE"
)
```

### 2. Create the Genie Space

```
# MCP Tool: manage_genie
manage_genie(
    action="create_or_update",
    display_name="Sales Analytics",
    table_identifiers=[
        "my_catalog.sales.customers",
        "my_catalog.sales.orders"
    ],
    description="Explore sales data with natural language",
    sample_questions=[
        "What were total sales last month?",
        "Who are our top 10 customers?"
    ]
)
```

### 3. Ask Questions (Conversation API)

```
# MCP Tool: ask_genie
ask_genie(
    space_id="your_space_id",
    question="What were total sales last month?"
)
# Returns: SQL, columns, data, row_count
```

### 4. Export & Import (Clone / Migrate)

Export a space (preserves all tables, instructions, SQL examples, and layout):

```
# MCP Tool: manage_genie
exported = manage_genie(action="export", space_id="your_space_id")
# exported["serialized_space"] contains the full config
```

Clone to a new space (same catalog):

```
# MCP Tool: manage_genie
manage_genie(
    action="import",
    warehouse_id=exported["warehouse_id"],
    serialized_space=exported["serialized_space"],
    title=exported["title"],  # override title; omit to keep original
    description=exported["description"],
)
```

> **Cross-workspace migration:** Each MCP server is workspace-scoped. Configure one server entry per workspace profile in your IDE's MCP config, then `manage_genie(action="export")` from the source server and `manage_genie(action="import")` via the target server. See [spaces.md §Migration](spaces.md#migrating-across-workspaces-with-catalog-remapping) for the full workflow.

