---
name: cortex-code
description: Routes Snowflake-related operations to Cortex Code CLI for specialized Snowflake expertise. Use when user asks about Snowflake databases, data warehouses, SQL queries on Snowflake, Cortex AI features, Snowpark, dynamic tables, data governance in Snowflake, Snowflake security, or mentions "Cortex" explicitly. Do NOT use for general programming, local file operations, non-Snowflake databases, web development, or infrastructure tasks unrelated to Snowflake.
license: Proprietary. See LICENSE for complete terms
metadata:
  author: Snowflake Integration Team
  version: "1.0.0"
  compatibility: Requires Cortex Code CLI installed and configured
---

# Cortex Code Integration Skill

## Install

```bash
# Install via npm skills ecosystem
npx skills add snowflake-labs/subagent-cortex-code --copy

# Prerequisite: Cortex Code CLI must be installed and configured
which cortex  # verify installation
```

This skill enables your coding agent to leverage Cortex Code's specialized Snowflake expertise by intelligently routing Snowflake-related operations to Cortex Code CLI in headless mode.

## Architecture & Routing Principle

**Routing Rule**: ONLY Snowflake operations → Cortex Code. Everything else → your coding agent.

- **Dynamic Discovery** at session initialization.
- **LLM-Based Semantic Routing** (not keyword matching).
- **Security Wrapper** with customizable envelopes (`RO`, `RW`, `RESEARCH`, `DEPLOY`).
- **Stateless Execution** with context enrichment and audit logs.

## Minimal Execution Flow (Fast Path)

If the session has already run discovery once:
1. (If `approval_mode: prompt`) ask user for approval of predicted tools.
2. Call `execute_cortex.py` with enriched context and the chosen envelope (e.g., `RO` or `RW`).
3. Return the parsed event stream output to the user.

---

## Core Scripts

- `scripts/discover_cortex.py` — enumerates capabilities and caches them.
- `scripts/route_request.py` — semantic LLM classifier.
- `scripts/security_wrapper.py` — runs upfront predictions & prompts user in `prompt` mode.
- `scripts/execute_cortex.py` — stream JSON execution wrapper with envelope enforcement.
- `scripts/read_cortex_sessions.py` — loads context from recent Cortex work.

---

## References

- **[Security Architecture](references/security.md)** — Detailed descriptions of approval modes (prompt, auto, envelope_only) and security envelopes.
- **[Session & Execution Workflows](references/workflow.md)** — Step-by-step guides for discovery, custom routing, prompt enrichment, and event stream parsing.
- **[Troubleshooting Guide](references/troubleshooting.md)** — Solutions for missing CLI, connection refused, permission issues, missing logs, and credential blocking.
