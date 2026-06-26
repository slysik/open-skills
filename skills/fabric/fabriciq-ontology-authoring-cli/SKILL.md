---

name: fabriciq-ontology-authoring-cli
description: 'Create and evolve Fabric IQ Ontology (preview) items from CLI — define entity types, properties (including timeseries), relationship types, and bind them to OneLake lakehouse tables (static + timeseries) or Eventhouse / KQL database tables (timeseries only). Uses the Fabric item-definition REST API (Create Item / Update Item Definition) with `InlineBase64` parts. Use to create a Fabric Ontology item; add or alter entity types, properties, or keys; add timeseries properties and bindings; bind an entity type to a lakehouse or Eventhouse table; add relationship types and contextualizations; or script ontology deployment from source. Triggers: "create fabric ontology", "add ontology entity type", "bind entity type to lakehouse", "bind entity type to eventhouse", "ontology timeseries binding", "add ontology relationship type", "ontology contextualization", "fabric iq ontology authoring", "update ontology definition"'
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
> 1. Ontology is **preview**. The item type value is `Ontology`. Features and wire format may change; validate against the current docs before production use.
> 2. To find the workspace details (including its ID) from workspace name: list all workspaces and use JMESPath filtering.
> 3. To find the item details (including its ID) from workspace ID, item type (`Ontology`), and item name: list all items of that type in that workspace and use JMESPath filtering.
> 4. Authoring a relationship type requires **two distinct entity types** that already exist in the ontology. The `source.entityTypeId` and `target.entityTypeId` values are the **entity type IDs you assigned**, not item IDs.
> 5. Data bindings reference a source table by `workspaceId`, `itemId`, `sourceTableName`, and — for lakehouse sources — `sourceSchema`. Lakehouse (`LakehouseTable`) sources carry the lakehouse item ID; Eventhouse (`KustoTable`) sources carry the **Eventhouse item ID** plus `clusterUri` and `databaseName`. Key column(s) on the source side must match the entity type's key property(ies). Eventhouse sources are `TimeSeries`-only; the static (`NonTimeSeries`) binding must come from a lakehouse.

# fabriciq-ontology-authoring-cli — Fabric Ontology Authoring via CLI

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
