# Security Architecture

The Cortex Code Integration Skill includes a comprehensive security wrapper around Cortex execution to ensure safe, compliant, and controlled tool access.

## Approval Modes

The wrapper supports three distinct approval modes configured in the skill's install directory (`config.yaml`), or via organization policy:

### 1. prompt (default)
* **Security level:** High (recommended for interactive and production sessions).
* **Behavior:**
  * Displays an interactive approval prompt listing predicted tools and execution confidence before running.
  * Blocks any execution unless the user explicitly enters `yes`.
  * Best for general use and untrusted prompts.

### 2. auto
* **Security level:** Medium (for automated pipelines and trusted contexts).
* **Behavior:**
  * Auto-approves all predicted tool calls.
  * Enforces the security envelope blocklist.
  * Generates mandatory structured JSONL audit logs.

### 3. envelope_only
* **Security level:** Medium (for low-latency, trusted pipelines).
* **Behavior:**
  * Skips tool prediction entirely for faster execution.
  * Auto-approves execution with mandatory structured JSONL audit logs.
  * Relies entirely on the security envelope's blocklist to restrict actions.

---

## Configuration & Policy Overrides

* **`config.yaml`:** Optional user-level settings in the skill's install directory. If not present, default fallback values are applied (`prompt` mode, `RO` envelope, safe defaults).
* **Organization Policy:** Enterprise override defined in `~/.snowflake/cortex/claude-skill-policy.yaml`. If present, this policy takes precedence over any local `config.yaml` options.

---

## Built-In Protections

1. **Prompt Sanitization:** Automatically scrubs PII (such as email addresses, phone numbers, and keys) from prompts before routing.
2. **Credential Blocking:** Blocks routing of queries that mention credential directories (e.g., `~/.ssh/`, `.env`, keys).
3. **Secure Caching:** Uses a SHA-256 validated cache in `~/.cache/cortex-skill/` to protect session capabilities and state.
4. **Audit Logging:** Logs structured JSONL lines describing every action when in auto or envelope_only mode.

---

## Security Envelope Strategy

Choose envelopes based on the operation risk level:

* **RO (Read-Only):** Blocks Edit, Write, and destructive Bash commands. Best for database queries and data analysis.
* **RW (Read-Write):** Allows data modifications but blocks destructive system operations (like `rm -rf`, `sudo`).
* **RESEARCH:** Grants read access and web tools for exploratory work; blocks local writes.
* **DEPLOY:** Allows deployments; blocks destructive system commands.
* **NONE:** Custom fine-grained blocklist via `--disallowed-tools` parameter.
