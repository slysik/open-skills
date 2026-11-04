---
name: semantic-view-patterns
title: Apply Semantic View Patterns
summary: Tutorials and apply-mode for 25 Snowflake Semantic View modeling patterns spanning joins, metrics, and dimensions.
description: "Use when learning Snowflake Semantic View patterns, teaching SV concepts, applying patterns to existing SVs, or building new SVs with best practices. Triggers: semantic view patterns, sv patterns, walk me through, time intelligence, range join, asof join, semi-additive, window metrics, derived metrics, role playing dimensions, accumulating snapshot, sv diagnostics, fan trap, USING clause, NON ADDITIVE BY."
license: MIT
metadata:
  author: Snowflake Solutions Team
  version: "1.0.0"
  updated: "2026-06-28"
---

# Semantic View Patterns Router

Interactive, end-to-end tutorials for 25 Snowflake Semantic View (SV) modeling patterns. Each pattern ships with annotated DDL and YAML, seed data, and live `SEMANTIC_VIEW()` queries. Two modes:

- **Tutorial mode** — deploy a working example into your account, walk through the DDL/YAML, run live queries, then clean up. Triggers: "walk me through", "teach me", "what patterns are available".
- **Apply mode** — read your existing SV (or table list), map the pattern's structural roles to your columns, and generate adapted DDL/YAML. Triggers: "apply X to my SV", "my tables are…", "help me implement".

If ambiguous, ask which mode the user wants.

## Route the task

| User intent | Load |
|---|---|
| Learn about Semantic View patterns | [references/pattern-tutorials.md](references/pattern-tutorials.md) |
| Apply a pattern to existing SV or tables | [references/apply-mode.md](references/apply-mode.md) |

## Default behavior

1. If the user asks about SV patterns, patterns, or mentions a specific pattern (time intelligence, range join, etc.), ask which mode they want: tutorial (walk through) or apply (adapt to their SV).
2. Load the appropriate reference based on their choice.
3. Both modes require the user's existing SV definition or table list as input.