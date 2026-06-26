---

name: fabriciq-ontology-consumption-cli
description: >
  Explore Fabric IQ Ontology (preview) items (read-only) from the CLI to ground an agent before it
  queries data. Explore, describe, and summarize what an ontology exposes — its entity types, keys,
  relationships, and the bindings that map each concept onto a lakehouse or Eventhouse source — then
  route the underlying data query to the matching per-datasource consumption skill
  (eventhouse-consumption-cli, spark-consumption-cli, sqldw-consumption-cli). Read-only discovery via
  Get Item Definition; never writes to or alters an ontology. Use to explore or summarize an ontology,
  describe its schema and data lineage, build agent grounding context, or run an ontology-backed
  query over the source records.
  Triggers: "query fabric ontology", "explore fabric ontology", "list ontology entities",
  "enumerate ontology entity types", "describe ontology", "ontology grounding context",
  "ground query with ontology", "query ontology entity data", "fabric iq ontology consumption",
  "ontology-backed query", "ontology entity bindings"
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
> 1. Ontology is **preview**. The item type value is `Ontology`. Wire format and limitations may change; validate against the current docs before production use.
> 2. This skill is **read-only**. It never calls `createItem` or `updateDefinition`. For schema changes, delegate to **`fabriciq-ontology-authoring-cli`**.
> 3. This skill does **not** query source data directly. It enumerates ontology grounding context, then **delegates** the actual data read to the per-datasource consumption skill that matches the binding source kind (see [Query Routing](#query-routing)).
> 4. Projections (a semantic query layer over ontology entities) are **not yet GA**. Until they ship, all data queries run against the **source** table (`LakehouseTable` or `KustoTable`) using the columns declared in the binding's `propertyBindings[]`.
> 5. To find the workspace details (including its ID) from workspace name: list all workspaces and use JMESPath filtering.
> 6. To find the ontology item ID from workspace ID and item name: list all items of type `Ontology` in that workspace and use JMESPath filtering.

# fabriciq-ontology-consumption-cli — Fabric Ontology Consumption via CLI

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
