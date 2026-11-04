---
name: migrate-snowsql
title: Snowflake Snowsql to CLI Migration Router
title: Snowflake SnowsQL to CLI Migration Router
summary: Migrate SnowsQL scripts and stored procedures to Snowflake CLI with automated refactoring and validation. Provides migration planning, approval workflow, and deployment guidance.
description: "Use for Snowflake SnowsQL migration tasks: convert SnowsQL scripts, stored procedures, to Snowflake CLI, automate refactoring workflows, validate migrations, and provide deployment guidance. Triggers: 'migrate SnowsSQL', 'convert SnowsQL to CLI', 'stored procedure migration', 'SnowsQL migration', 'CLI conversion', 'Snowflake migration'."
license: MIT
metadata:
  author: Snowflake Migration Team
  version: "1.0.0"
  updated: "2026-06-28"
---

# Snowflake SnowsQL to CLI Migration Router

Migrate SnowsQL scripts, stored procedures, and workflows to Snowflake CLI with automated refactoring, validation, and deployment planning. Supports plan/approve workflow with comprehensive rollback capabilities.

## Route the task

| User intent | Load |
|---|---|
| SnowsSQL to CLI migration | [references/migration-planning.md](references/migration-planning.md) |
| Refactoring assistance | [references/refactoring-guide.md](references/refactoring-guide.md) |
| Deployment validation | [references/deployment-validation.md](references/deployment-validation.md) |

## Default behavior

1. If user asks about SnowsSQL migration, load migration-planning.md
2. If user asks about refactoring, load refactoring-guide.md
3. If user asks about deployment validation, load deployment-validation.md
4. Default to migration-planning.md