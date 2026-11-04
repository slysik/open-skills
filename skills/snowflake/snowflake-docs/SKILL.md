---
name: snowflake-docs
id: snowflake-docs
description: "Use for ALL Snowflake documentation lookups: feature questions, SQL syntax, best practices, how-to guides, configuration, and troubleshooting. This is the required entry point for any question about Snowflake products or features. Triggers: Snowflake docs, how do I, SQL syntax, CREATE, ALTER, DROP, warehouse, stage, Cortex, Snowpipe, dynamic table, stored procedure, UDF, MCP, Snowpark, Streamlit, Native App, data sharing, replication, security, roles, grants, what is, how does, Snowflake feature."
license: MIT
metadata:
  author: Gilberto Hernandez
  version: "1.0.0"
  updated: "2026-06-28"
---

# Snowflake Docs Router

Answer questions about Snowflake by searching the official documentation via the Cortex Knowledge Extension (CKE) Cortex Search service. If the CKE is not installed yet, install it automatically first.

## Route the task

| User intent | Load |
|---|---|
| Any Snowflake product, feature, or SQL question: syntax references, best practices, how-to guides, configuration, and troubleshooting | [references/CKE-installation-check.md](references/CKE-installation-check.md) |

## Default behavior

1. If the user asks about Snowflake documentation, features, syntax, best practices, or any Snowflake product question, check for CKE installation first.
2. Load the CKE installation check to discover the service and get the database name.
3. If not installed, follow the setup steps and require user confirmation before proceeding.
4. Once CKE is available, use the discovered database name to query the documentation service.