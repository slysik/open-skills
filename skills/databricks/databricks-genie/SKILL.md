---
name: databricks-genie
description: "Create and query Databricks Genie Spaces for natural language SQL exploration. Use when building Genie Spaces, exporting and importing Genie Spaces, migrating Genie Spaces between workspaces or environments, or asking questions via the Genie Conversation API."
---

# Databricks Genie

Create, manage, and query Databricks Genie Spaces - natural language interfaces for SQL-based data exploration.

## Overview

Genie Spaces allow users to ask natural language questions about structured data in Unity Catalog. The system translates questions into SQL queries, executes them on a SQL warehouse, and presents results conversationally.

## When to Use This Skill

Use this skill when:
- Creating a new Genie Space for data exploration
- Adding sample questions to guide users
- Connecting Unity Catalog tables to a conversational interface
- Asking questions to a Genie Space programmatically (Conversation API)
- Exporting a Genie Space configuration (serialized_space) for backup or migration
- Importing / cloning a Genie Space from a serialized payload
- Migrating a Genie Space between workspaces or environments (dev → staging → prod)
    - Only supports catalog remapping where catalog names differ across environments
    - Not supported for schema and/or table names that differ across environments
    - Not including migration of tables between environments (only migration of Genie Spaces)


## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/mcp-and-quickstart.md](references/mcp-and-quickstart.md) | Genie — MCP tools + quick start |

## Reference Files

- [spaces.md](spaces.md) - Creating and managing Genie Spaces
- [conversation.md](conversation.md) - Asking questions via the Conversation API

## Prerequisites

Before creating a Genie Space:

1. **Tables in Unity Catalog** - Bronze/silver/gold tables with the data
2. **SQL Warehouse** - A warehouse to execute queries (auto-detected if not specified)

### Creating Tables

Use these skills in sequence:
1. `databricks-synthetic-data-gen` - Generate raw parquet files
2. `databricks-spark-declarative-pipelines` - Create bronze/silver/gold tables

## Common Issues

See [spaces.md §Troubleshooting](spaces.md#troubleshooting) for a full list of issues and solutions.
## Related Skills

- **[databricks-agent-bricks](../databricks-agent-bricks/SKILL.md)** - Use Genie Spaces as agents inside Supervisor Agents
- **[databricks-synthetic-data-gen](../databricks-synthetic-data-gen/SKILL.md)** - Generate raw parquet data to populate tables for Genie
- **[databricks-spark-declarative-pipelines](../databricks-spark-declarative-pipelines/SKILL.md)** - Build bronze/silver/gold tables consumed by Genie Spaces
- **[databricks-unity-catalog](../databricks-unity-catalog/SKILL.md)** - Manage the catalogs, schemas, and tables Genie queries
