---
name: snowflake
description: "Route high-level Snowflake work to the right Open Skills Snowflake skill. Use whenever the user mentions Snowflake, Snowflake SQL, warehouses, databases, schemas, tables, RBAC, stages, streams, tasks, dynamic tables, Snowpark, Cortex AI, Cortex Search, Cortex Analyst, semantic views, Document AI, Kafka to Snowflake ingestion, Snowpipe Streaming, or asks generally to build, query, debug, optimize, migrate, govern, or design something on Snowflake. This is the umbrella Snowflake trigger for broad prompts such as 'help me with Snowflake', 'build this in Snowflake', 'debug my Snowflake pipeline', or 'design a Snowflake architecture'."
metadata:
  version: "0.1.0"
  updated: "2026-06-26"
---

# Snowflake Router

Use this skill as the first stop for broad Snowflake requests, then load the
smallest matching specialist skill.

## Route the task

| User intent | Load |
|---|---|
| Create or manage databases, schemas, warehouses, roles, grants, tables, stages, streams, tasks, dynamic tables, SQL, Snowpark, Cortex AI, Cortex Search, Cortex Analyst, semantic views, Document AI, RAG, or general Snowflake architecture | [snowflake-cortex](../snowflake-cortex/SKILL.md) |
| Configure or debug Kafka ingestion into Snowflake, Snowflake Kafka Connector, Snowpipe Streaming, connector v3/v4, schematization, `RECORD_METADATA`, `RECORD_CONTENT`, or demo stacks | [snowflake-kafka](../snowflake-kafka/SKILL.md) |
| Delegate a Snowflake-specific operation to an installed Cortex Code CLI with approval/envelope controls | [cortex-code](../cortex-code/SKILL.md) |

## Default behavior

1. If the user only says "Snowflake" or gives a broad Snowflake architecture,
   SQL, governance, performance, or Cortex AI request, load
   [snowflake-cortex](../snowflake-cortex/SKILL.md).
2. If the request includes Kafka, Connect, Snowpipe Streaming, connector config,
   channels, or topic-to-table mapping, load
   [snowflake-kafka](../snowflake-kafka/SKILL.md).
3. Use [cortex-code](../cortex-code/SKILL.md) only when the user explicitly wants
   Cortex Code CLI routing or the local Cortex Code workflow is already configured.
4. Keep Snowflake work CLI/SQL-first. Do not ask the user which Snowflake skill to
   use unless the request genuinely spans multiple specialist skills.
