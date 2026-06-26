---

name: activator-authoring-cli
description: >
  Create alerts, notifications, and automated actions on Fabric data and events
  via Fabric REST API and `az rest` CLI. **Invoke this skill** whenever the user
  wants to:
  (1) create, update, or delete an alert or notification flow,
  (2) send a Teams message, email, or run a Fabric item when something happens,
  (3) connect alert logic to Eventhouse, Eventstream, Real-time Hub, or DTB / Ontology data,
  (4) adjust thresholds, filters, event triggers, or actions,
  (5) troubleshoot or change an existing Activator/Reflex definition.
  Invoke this skill **before** asking clarifying questions — clarification is part of this skill, not a preamble to it.
  Triggers: "create an alert", "create an activator", "create a reflex",
  "create an activator item", "create an alert item",
  "notify me when", "let me know when",
  "take action when", "send me an email when", "send a teams message when",
  "run a pipeline when", "update an alert", "delete an alert", "activator rule"
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill (e.g., `/fabric-skills:check-updates`).
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find the item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace and, then, use JMESPath filtering

# activator-authoring-cli — Activator Item & Rule Authoring via CLI

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
