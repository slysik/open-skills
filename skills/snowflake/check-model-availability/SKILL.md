---
name: check-model-availability
title: Snowflake Cortex Model Availability Checker
title: Snowflake Cortex Model Availability Router
summary: Verify Cortex model availability in base vs agentic mode, with deployment readiness checks. Provides deployment guidance for ML models.
description: "Use when asked about Snowflake Cortex model availability, checking model status, verifying deployment readiness, or understanding differences between base and agentic Cortex modes. Triggers: 'check if model X is available', 'verify model Y in base vs agentic mode', 'Cortex model status', 'model deployment check', 'Cortex availability'."
license: MIT
metadata:
  author: Snowflake Solutions Team
  version: "1.0.0"
  updated: "2026-06-28"
---

# Snowflake Cortex Model Availability Router

Check Cortex model availability in base vs agentic mode, with deployment readiness analysis and version compatibility verification. Identifies gaps and provides migration guidance.

## Route the task

| User intent | Load |
|---|---|
| Check model availability (base vs agentic) | [references/model-availability-check.md](references/model-availability-check.md) |
| Analyze deployment readiness | [references/deployment-readiness.md](references/deployment-readiness.md) |
| Compare base vs agentic features | [references/base-vs-agentic.md](references/base-vs-agentic.md) |

## Default behavior

1. If user asks about model availability, load model-availability-check.md
2. If user asks about deployment readiness, load deployment-readiness.md  
3. If user asks about base vs agentic differences, load base-vs-agentic.md
4. Default to model-availability-check.md