---

name: eventstream-consumption-cli
description: >
  List, inspect, and monitor Microsoft Fabric Eventstream real-time event ingestion
  pipelines via the Fabric Items REST API. Discover Eventstreams across workspaces,
  decode base64-encoded graph topologies to trace event flow from source through
  operators to destination nodes. Validate source connection IDs, destination wiring,
  retention policies (1-90 days), and throughput levels. Use when the user wants to:
  (1) list or search Eventstreams in a workspace, (2) decode and trace graph topology
  from source to destination, (3) validate source and destination configurations,
  (4) check retention and throughput settings.
  Triggers: "list eventstreams", "show eventstream", "inspect eventstream",
  "explain eventstream", "eventstream health", "monitor eventstream",
  "describe eventstream", "check eventstream configuration", "eventstream retention".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find the item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace and, then, use JMESPath filtering
> 3. Eventstream ≠ Eventhouse. Eventstream is a real-time event ingestion and routing pipeline. For KQL queries, use `eventhouse-consumption-cli`.

# Eventstream Consumption — CLI Skill

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
