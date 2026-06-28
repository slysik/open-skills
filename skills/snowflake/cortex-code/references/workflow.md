# Session & Execution Workflows

This document details how the skill manages session initialization, LLM-based routing, context enrichment, and headless execution.

## Session Initialization

When this skill is first loaded, it runs a discovery step once per session:

### Step 1: Discover Cortex Capabilities
```bash
PYTHON=$(command -v python3 2>/dev/null || command -v python 2>/dev/null || echo python3)
$PYTHON scripts/discover_cortex.py
```
This script:
1. Executes `cortex skill list` to enumerate all available Cortex skills.
2. Reads each skill's `SKILL.md` frontmatter and triggers.
3. Caches capabilities in `/tmp/cortex-capabilities.json` or `~/.cache/cortex-skill/cortex-capabilities.json`.
4. Returns a structured JSON mapping.

### Step 2: Load Routing Context
The cached capabilities are loaded into memory to inform subsequent routing choices.

---

## Handling User Requests (Step-by-Step)

### Step 1: Analyze Request & Route
Every request is analyzed to decide whether it should run locally or be sent to Cortex:
```bash
$PYTHON scripts/route_request.py --prompt "USER_PROMPT_HERE"
```
* **Cortex Route:** Handles Snowflake database operations, warehouses, tables, SQL queries, Snowpark, dynamic tables, streams, tasks, and Cortex AI features.
* **Local Coding Agent Route:** Handles local file editing, general programming (unless Snowpark), non-Snowflake databases, git actions, and web dev.

### Step 2: Choose security envelope & check approval
Based on the routing decision and approval mode:
* In `prompt` mode, call the security wrapper upfront:
  ```bash
  $PYTHON scripts/security_wrapper.py --prompt "ENRICHED_PROMPT" --envelope "RW"
  ```
* In `auto` or `envelope_only` modes, tool calls are auto-approved.

### Step 3: Enrich Context for Cortex
Stateless invocations require context, which is compiled dynamically:
1. **Claude conversation history:** Last 2-3 exchanges.
2. **Recent Cortex session history:** Queried via:
   ```bash
   $PYTHON scripts/read_cortex_sessions.py --limit 3
   ```

### Step 4: Execute Cortex Code
The wrapper executes the prompt headlessly:
```bash
$PYTHON scripts/execute_cortex.py \
  --prompt "ENRICHED_PROMPT" \
  --connection "connection_name" \
  --envelope "RW" \
  --disallowed-tools "tool1" "tool2"
```
* Uses print mode for prompt delivery and stream JSON mode for non-TTY parsing.
* Parses NDJSON event streams (`type: assistant`, `type: tool_use`, `type: result`).

---

## Custom Routing Rules

You can customize the decision boundaries by editing `scripts/route_request.py`:

```python
# Add custom patterns
FORCE_CORTEX_PATTERNS = [
    "snowflake",
    "cortex",
    "warehouse",
    "snowpark"
]

FORCE_CLAUDE_PATTERNS = [
    "local file",
    "git commit",
    "python script" # unless Snowpark
]
```
