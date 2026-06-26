---

name: eventstream-authoring-cli
description: >
  Create, wire, and publish Microsoft Fabric Eventstream real-time event streaming
  topologies via the Fabric Items REST API. Build graph-based definitions with 25
  source types (Event Hubs, IoT Hub, CDC connectors, Kafka, SampleData), 8
  transformation operators (Filter, Aggregate, GroupBy, Join, ManageFields, Union,
  Expand, SQL), 4 destination types (Lakehouse Delta, Eventhouse, Activator, Custom
  Endpoint), and DefaultStream/DerivedStream routing. Use when the user wants to:
  (1) author or publish an Eventstream topology, (2) add CDC sources with SQL-based
  Debezium payload flattening, (3) assemble multi-table fan-out routing,
  (4) modify or delete Eventstream definitions. Triggers: "create eventstream",
  "deploy eventstream", "design eventstream topology", "CDC source", "eventstream operator",
  "real-time ingestion pipeline", "eventstream definition", "update eventstream".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/open-skills/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find the item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace and, then, use JMESPath filtering
> 3. Eventstream ≠ Eventhouse. Eventstream is a real-time event ingestion and routing pipeline. For KQL database operations, use `eventhouse-authoring-cli` or `eventhouse-consumption-cli`.

# Eventstream Authoring — CLI Skill

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
