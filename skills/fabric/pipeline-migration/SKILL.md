---

name: pipeline-migration
description: >
  Migrate Synapse Data Factory pipeline artifacts to Microsoft Fabric Data Factory.
  Handles: linked services → Fabric connections, dataset definitions inlined into
  pipeline activities, global parameters → Variable Libraries, SynapseNotebook
  activities → TridentNotebook. SSIS, SHIR-only, and Databricks activities are parked.
  Use when: (1) migrating Synapse pipelines to Fabric Data Factory,
  (2) converting SynapseNotebook activities to TridentNotebook,
  (3) translating linked services to Fabric connections,
  (4) converting global parameters to Fabric Variable Libraries,
  (5) inlining dataset definitions into Fabric pipeline activities.
  Triggers: "synapse pipeline to fabric", "data factory pipeline migration",
  "tridentnotebook pipeline activity", "global parameters to variable library",
  "linked service to fabric connection", "inline dataset fabric pipeline",
  "pipeline migration from synapse".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory for live migration runs)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.
> - **Skip in eval / guidance-only mode**: if the user's prompt explicitly forbids tool/API calls (e.g. *"Do not call any APIs or create any resources"*) or the skill is being invoked for offline JSON translation / eval, do **not** run the update check — answer the prompt directly. The check is only required for live-migration runs that will call Fabric or Synapse APIs.

> **CRITICAL NOTES**
> 1. To find workspace details (including its ID) from a workspace name: list all workspaces, then use JMESPath filtering
> 2. To find item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace, then use JMESPath filtering
> 3. Fabric does NOT have a "Dataset" item type — all dataset properties are **inlined** into activity `typeProperties`
> 4. Linked Services map to Fabric **Connections** — in pipeline activity JSON, `referenceName` on the activity's `linkedService` block uses the Fabric connection **display name** (not the connection GUID); the connection GUID is used only on Fabric REST API calls
> 5. Notebook activities change from `SynapseNotebook` to `TridentNotebook` and reference notebooks by **GUID**, not by name
> 6. Synapse global parameters become a **Variable Library** item in Fabric, referenced as `@pipeline().libraryVariables.<name>`. Variable Library `Number` types are not consumable in pipelines — Synapse `Float`/`Double` are mapped to `String` for runtime compatibility
> 7. The `Validation` activity type does not exist in Fabric — it must be rewritten as `GetMetadata` + `IfCondition`
> 8. **Triggers are intentionally excluded** from this skill — recreate schedules manually in Fabric after migration
> 9. SSIS package execution, SHIR-exclusive connectors, and Databricks activities are **parked** — see [pipeline-gotchas.md](resources/pipeline-gotchas.md)

# Synapse Pipelines → Microsoft Fabric Data Factory Migration

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
