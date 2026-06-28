# Troubleshooting Guide

Solutions and diagnosis commands for common Cortex Code integration issues.

## 1. Error: "Cortex CLI not found"
* **Cause:** Cortex Code CLI is either not installed or not in your current shell's `PATH`.
* **Solution:**
  ```bash
  which cortex
  # If not found, check the default installation folder: ~/.snowflake/cortex/
  ```

---

## 2. Error: Approval prompt not appearing
* **Cause:** Misconfiguration in the active approval mode, or organization policy override.
* **Solution:**
  ```bash
  # Check active approval_mode in config.yaml
  cat ~/skills/cortex-code/config.yaml | grep approval_mode

  # Check organization policy overrides
  cat ~/.snowflake/cortex/claude-skill-policy.yaml 2>/dev/null
  ```

---

## 3. Error: "Prompt contains credential file path"
* **Cause:** Safety trigger. Your prompt contains paths matching credential directories (e.g., `~/.ssh/`, `.env`).
* **Solution:** Remove or rename local credential paths from your prompt or customize the allowlist in `config.yaml`.

---

## 4. Error: PII removed from prompts
* **Symptom:** Email addresses or phone numbers are replaced with placeholders like `[EMAIL]`.
* **Cause:** Prompt sanitization is on by default.
* **Solution:** You can optionally disable sanitization in `config.yaml` (not recommended):
  ```yaml
  security:
    sanitize_conversation_history: false
  ```

---

## 5. Error: "Permission denied" in Auto Mode
* **Cause:** The tool you're trying to execute is blocked by the active security envelope's blocklist.
* **Solution:** 
  1. Verify the current envelope being used (`RO`, `RW`, `RESEARCH`, `DEPLOY`).
  2. If the operation is safe, escalate to a less restrictive envelope (e.g., `RW` or `NONE` with custom `--disallowed-tools`).

---

## 6. Error: Audit log not created
* **Symptom:** No `audit.log` is generated in auto or envelope_only modes.
* **Solution:** Ensure the skill's install directory has proper write permissions and check `audit_log_path` in `config.yaml`.
  ```bash
  chmod 700 "$(cd "$(dirname "$0")/.." && pwd)"
  ```

---

## 7. Error: Tools still requiring interactive approval
* **Cause:** Incorrect execution invocation or stream JSON misconfiguration.
* **Solution:** Ensure the security wrapper executes Cortex Code using `cortex -p "..." --output-format stream-json` without `--input-format`.

---

## 8. Issue: Cortex returns "Connection refused"
* **Cause:** Active Snowflake connection is missing or configured incorrectly in Cortex.
* **Solution:**
  ```bash
  cortex connections list
  # Verify connection is active and check settings.json for cortexAgentConnectionName
  ```
