---

name: activator-consumption-cli
description: >
  Inspect existing alerts, notifications, and automated actions in Fabric via
  read-only REST API calls using `az rest` CLI. **Invoke this skill** whenever
  the user wants to:
  (1) list existing alerts in a workspace,
  (2) inspect how an alert or notification is configured,
  (3) read and decode an Activator/Reflex definition (ReflexEntities.json),
  (4) list rules, sources, and actions behind an alert,
  (5) understand why an alert fires or what action it takes.
  **Invoke this skill before answering questions** about an Activator/Reflex item
  in a Fabric workspace — the listing, lookup, and decoding workflows are part of
  this skill, not preamble to it.
  Triggers: "show my alerts", "what alerts do I have", "inspect this alert",
  "show me the rule", "show me the action", "show me the source",
  "get reflex definition", "list activators", "list alerts",
  "list reflex items", "show activator items", "activator details",
  "find activator named"
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill (e.g., `/fabric-skills:check-updates`).
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/open-skills/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find the item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace and, then, use JMESPath filtering

# activator-consumption-cli — Read-Only Activator Exploration via CLI

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
