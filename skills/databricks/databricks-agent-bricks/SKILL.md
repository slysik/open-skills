---
name: databricks-agent-bricks
description: "Create and manage Databricks Agent Bricks: Knowledge Assistants (KA) for document Q&A, Genie Spaces for SQL exploration, and Supervisor Agents (MAS) for multi-agent orchestration. Use when building conversational AI applications on Databricks."
---

# Agent Bricks

Create and manage Databricks Agent Bricks - pre-built AI components for building conversational applications.

## Overview

Agent Bricks are three types of pre-built AI tiles in Databricks:

| Brick | Purpose | Data Source |
|-------|---------|-------------|
| **Knowledge Assistant (KA)** | Document-based Q&A using RAG | PDF/text files in Volumes |
| **Genie Space** | Natural language to SQL | Unity Catalog tables |
| **Supervisor Agent (MAS)** | Multi-agent orchestration | Model serving endpoints |

## Prerequisites

Before creating Agent Bricks, ensure you have the required data:

### For Knowledge Assistants
- **Documents in a Volume**: PDF, text, or other files stored in a Unity Catalog volume
- Generate synthetic documents using the `databricks-unstructured-pdf-generation` skill if needed

### For Genie Spaces
- **See the `databricks-genie` skill** for comprehensive Genie Space guidance
- Tables in Unity Catalog with the data to explore
- Generate raw data using the `databricks-synthetic-data-gen` skill
- Create tables using the `databricks-spark-declarative-pipelines` skill

### For Supervisor Agents
- **Model Serving Endpoints**: Deployed agent endpoints (KA endpoints, custom agents, fine-tuned models)
- **Genie Spaces**: Existing Genie spaces can be used directly as agents for SQL-based queries
- Mix and match endpoint-based and Genie-based agents in the same Supervisor Agent

### For Unity Catalog Functions
- **Existing UC Function**: Function already registered in Unity Catalog
- Agent service principal has `EXECUTE` privilege on the function

### For External MCP Servers
- **Existing UC HTTP Connection**: Connection configured with `is_mcp_connection: 'true'`
- Agent service principal has `USE CONNECTION` privilege on the connection


## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/mcp-workflow-example.md](references/mcp-workflow-example.md) | Agent Bricks — MCP tools, workflow, best practices, multi-modal supervisor example |

## Related Skills

- **[databricks-genie](../databricks-genie/SKILL.md)** - Comprehensive Genie Space creation, curation, and Conversation API guidance
- **[databricks-unstructured-pdf-generation](../databricks-unstructured-pdf-generation/SKILL.md)** - Generate synthetic PDFs to feed into Knowledge Assistants
- **[databricks-synthetic-data-gen](../databricks-synthetic-data-gen/SKILL.md)** - Create raw data for Genie Space tables
- **[databricks-spark-declarative-pipelines](../databricks-spark-declarative-pipelines/SKILL.md)** - Build bronze/silver/gold tables consumed by Genie Spaces
- **[databricks-model-serving](../databricks-model-serving/SKILL.md)** - Deploy custom agent endpoints used as MAS agents
- **[databricks-vector-search](../databricks-vector-search/SKILL.md)** - Build vector indexes for RAG applications paired with KAs

## See Also

- `1-knowledge-assistants.md` - Detailed KA patterns and examples
- `databricks-genie` skill - Detailed Genie patterns, curation, and examples
- `2-supervisor-agents.md` - Detailed MAS patterns and examples
