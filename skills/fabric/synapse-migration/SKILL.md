---

name: synapse-migration
description: >
  Port Azure Synapse Analytics Spark workloads to Microsoft Fabric.
  Translates mssparkutils calls to notebookutils (including the env→runtime namespace change),
  replaces Linked Services with Fabric Data Connections and OneLake Shortcuts.
  Covers Spark Pools, Lake Databases, Notebooks, and Spark Job Definitions.
  Use when the user wants to:
  (1) port Synapse Spark notebooks to Fabric Lakehouse or Spark Job Definitions,
  (2) replace mssparkutils or Linked Services in Synapse code.
  Triggers: "migrate from synapse", "synapse to fabric", "mssparkutils to notebookutils",
  "synapse linked service replacement", "port synapse notebooks", "synapse workspace migration".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare local vs remote package.json version.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find workspace details (including its ID) from a workspace name: list all workspaces, then use JMESPath filtering
> 2. To find item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace, then use JMESPath filtering
> 3. `mssparkutils` and `notebookutils` share the same API surface in most cases — the namespace is the primary change
> 4. Linked Services have no direct REST API equivalent in Fabric — they are replaced by Data Connections (for external sources) and OneLake Shortcuts (for storage mounts)

# Synapse Analytics → Microsoft Fabric Migration

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
