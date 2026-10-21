# Ontology definition, generation 2 (TMDL)

Last verified: 2026-10-21 (Microsoft Learn: `rest/api/fabric/articles/item-management/definitions/ontology-definition` ms.date 2026-09-10; REST pages `rest/api/fabric/ontology/items/*`; `fabric/iq/ontology/overview` 2026-10-16 and `old-experience/overview`; TMDL language reference `analysis-services/tmdl/tmdl-overview`; `rest/api/fabric/articles/long-running-operation`). The Ontology item is **Preview**.

> **Verification status, read first.**
> - Verified verbatim on Learn: the REST operations, scopes and permissions, the part layout and required parts, the TMDL syntax rules, the `.platform` fields, the retirement date and the migration action.
> - **Not verified:** the TMDL code blocks on the definition page were only seen through a summary that collapsed tabs and line breaks, so the example tree in [tmdl-example/](tmdl-example/) is **reconstructed** from the part list plus the TMDL indentation rules. Treat it as a starting shape. Always confirm against the output of a real `getDefinition` call (round-trip an existing generation-2 item) before relying on a property name.
> - Error codes, size limits and the inheritance rollout warning below come from the unread part of the page (summary only) and are marked **(summary)**.
> - No live Fabric call was made while writing this file.

## 1. Which generation am I working on?

Learn names two experiences: the **old experience** (entity-type JSON tree, generation 1 layout, covered by the rest of this skill) and the **new experience** (TMDL, this file). The old experience **retires on 2027-01-31**; new instances cannot be created in the UI but can still be created through the APIs and CI/CD.

Decide by the **part layout returned by `getDefinition`**, not by assumption:
| Layout in `parts[]` | Treat as |
|---|---|
| `EntityTypes/...`, `RelationshipTypes/...` | Generation 1, old JSON recipe (rest of this skill) |
| `database.tmdl`, `entities/*.tmdl`, `tables/*.tmdl`, `.platform` with `config.version` "2.0" | Generation 2, TMDL (this file) |

Hint only: `GET /v1/workspaces/{workspaceId}/ontologies/{ontologyId}` returns a read-only `properties.generation` (integer 1 or 2, "the generation created, regardless of creation mode"). Learn does not state which number maps to which experience, so confirm with the part layout. Creating an item with **no definition creates generation 2**. Run `python3 references/scripts/ontology_tmdl.py detect <dir|envelope.json>` to classify a saved definition.

## 2. REST operations (verified)
Base `https://api.fabric.microsoft.com/v1`. All five pages say the Ontology item is in Preview; supported identities: user, service principal, managed identity.

| Operation | Verb and path | Scope | Permission |
|---|---|---|---|
| Create | `POST /workspaces/{workspaceId}/ontologies` | `Item.ReadWrite.All` | contributor workspace role; needs a supported Fabric capacity |
| Get | `GET /workspaces/{workspaceId}/ontologies/{ontologyId}` | `Item.Read.All` or `Item.ReadWrite.All` | read on the ontology |
| Get definition | `POST /workspaces/{workspaceId}/ontologies/{ontologyId}/getDefinition` (optional `?format=`) | `Item.ReadWrite.All` | read **and write** on the ontology |
| Update definition | `POST /workspaces/{workspaceId}/ontologies/{ontologyId}/updateDefinition` (optional `?updateMetadata=true`) | `Item.ReadWrite.All` | read and write on the ontology |
| List | `GET /workspaces/{workspaceId}/ontologies` (paged) | `Workspace.Read.All` or `Workspace.ReadWrite.All` | viewer |
| Delete | `DELETE /workspaces/{workspaceId}/ontologies/{ontologyId}` (optional `?hardDelete=`) | `Item.ReadWrite.All` | write on the item |

- Create body: `displayName` (required; letters, numbers, underscore; starts with a letter; under 100 chars), optional `description` (max 256), optional `definition`, optional `sensitivityLabelSettings`. Errors listed: `ItemDisplayNameAlreadyInUse`, `CorruptedPayload`, `WorkspaceItemsLimitExceeded`, `InvalidItemType`.
- `format`: no allowed values are listed on the REST pages; the only format named anywhere is **TMDL**. Do not pass other values.
- `updateMetadata=true` applies the `.platform` metadata; `updateDefinition` **overrides** the current definition (send the whole tree, not a delta).
- The skill's existing recipes call the generic `POST /v1/workspaces/{ws}/items` and `/items/{id}/getDefinition`; the typed `/ontologies/...` paths above are the documented ones for this item type.
- **Long-running operations**: create, getDefinition and updateDefinition can return `202` with an empty body and headers `Location`, `x-ms-operation-id`, `Retry-After`. Poll `GET /v1/operations/{operationId}` (status values seen: `Running`, `Succeeded`, `Failed`; no full list on the page) and read the result from `GET /v1/operations/{operationId}/result`. Existing LRO handling in [authoring.md](../authoring.md) still applies.

## 3. Part layout (verified)
| Path | Required | Content |
|---|---|---|
| `.platform` | yes | JSON: `metadata.type` "Ontology", `metadata.displayName`, `config.version` "2.0", `config.logicalId` |
| `database.tmdl` | yes | `database` + `compatibilityLevel: 1000000` |
| `model.tmdl` | returned by get; synthesized if omitted on write | `model`, `ref` lines, `reusableProperty` |
| `namespaces/default.tmdl` | returned by get; synthesized if omitted | reserved `default` namespace |
| `namespaces/{namespace}.tmdl` | no | additional namespaces |
| `entities/{namespace}#{name}.tmdl` | no | entity type; unqualified `Name.tmdl` is in the default namespace |
| `entityRelationships.tmdl` | no | entity relationships |
| `relationships.tmdl` | no | table-to-table relationships (TOM) |
| `tables/{name}.tmdl` | no | backing tables: columns, DirectLake partition, measures |
| `expressions.tmdl` | no | shared M expressions such as `DatabaseQuery` |
| `metrics/{name}.tmdl` | no | top-level metric |
| `rules/{rule}.tmdl` | no | one rule per file |

The smallest definition you can send is `.platform` + `database.tmdl`. `ref` lines are output-only. A property left at its default is accepted on write and omitted from what `getDefinition` returns. `entity`, `entityRelationship`, `rule` and `namespace` blocks are "TMSL++ extensions" layered on the Analysis Services tabular model. All parts use `payloadType: InlineBase64`.

## 4. TMDL syntax rules (verified, TMDL overview)
- **One tab per nesting level**; spaces are not equivalent ("not following these indentation rules generates a parsing error"). Level 1 object declaration, level 2 properties, level 3 multi-line expressions. `database` and direct children of `model` are not indented.
- `name: value` for non-expression properties (value on the same line); `=` for default properties and expressions (for example `partition orders = entity`, `expression DatabaseQuery =`).
- Names containing a dot, equals, colon, single quote or whitespace must be in single quotes (`entityRelationship 'Status Code For Plant'`); escape a quote by doubling it.
- Descriptions are `///` lines directly above the object, with no blank line between. Boolean shortcut: the bare property name means `true`.
- Multi-line expressions are indented one level deeper than the object's properties. Backtick-fenced expressions are read verbatim.
- Serializers write camelCase; reading is case-insensitive.

## 5. Example tree
[tmdl-example/](tmdl-example/) holds a small reconstructed definition (`.platform`, `database.tmdl`, `expressions.tmdl`, `tables/orders.tmdl`, `entities/orders.tmdl`, `rules/LargeOrderReview.tmdl`). Entity excerpt (tab indented):

```tmdl
/// A customer order.
entity orders
	lineageTag: <guid>
	backingTable: orders
	keyProperty: OrderId

	property OrderId
		dataType: string
		backingConfiguration
			valueColumn: orders.OrderId
```

Other constructs the Learn page shows (shapes reconstructed, **(summary)**): `entityRelationship` with `fromEntity`, `toEntity` and `backingConfiguration` of `relationship: <name>` or a table-backed form (`type: table`, `table`, `fromRelationship`, `toRelationship`; the junction table must not also be an entity's `backingTable`); `relationship` blocks with `fromColumn` and `toColumn`; time-series properties (`dataType: complex` with a `complexDataType` JSON and `backingConfiguration` of `type: timeSeries`, `orderingColumn`, `valueColumn`); `resourceLink` blocks; `rule` with `statement`, `ruleReferencedEntity` (`propertyScope: specific`), `ruleReferencedProperty`, `ruleReferencedRelationship`.

## 6. Types, names and limits
- Entity property `dataType`: `string`, `int64`, `double`, `dateTime`, `boolean`, `decimal`, `Any`, `TimeSeries<T>` or `complex` **(summary)**. Column `dataType` must be set or binding fails with `PropertyTypeIncompatible` **(summary)**. No property-to-column compatibility matrix was found: bind matching types.
- `lineageTag`: any string up to 512 chars (GUID by convention). Entities match by lineage tag then name, so a rename that keeps the tag replaces in place **(summary)**. `entity` references use `Namespace#Name`; `displayName` and `namespace` on entities are server-derived.
- Limits **(summary)**: 10,000 entities, relationships, namespaces and metrics; 1,000 rules; 1,000 properties per entity; 1,000 partitions per table; names 512 chars (reusable properties 128); descriptions and rule statements 4,000 chars; expression bodies 100,000 chars; document 1,000,000 JSON nodes.
- **Metrics**: DAX is rejected as an explicit metric (`ExplicitMetricDaxNotAllowed`, **summary**); DAX comes from a **table measure** surfaced as a metric. Explicit metrics use dialect KQL, SQL, Generic or NaturalLanguage **(summary)**. Only explicit metrics round-trip through `getDefinition`.
- **Inheritance** keywords (`baseEntityType`, `overriddenMetadataFields`, `redefines`, `reusableProperty`) are, per the page **(summary)**, rolling out gradually and rejected on tenants where disabled; `baseEntityType` is immutable after creation; inheritance is single-parent and derived types do not inherit data bindings.

## 7. Migrating from the old experience (verified, ontology overview)
- Use the **in-product action** (a banner button in the old ontology) to create a **copy** in the new experience. It creates a **separate new item**; the original stays until the old experience retires.
- Carried over: entity types, properties and bindings, relationship types.
- Manual work: reconnect downstream consumers (agents, dashboards, other integrations), recreate rules, set up Activator alerts again.
- No migration API is documented. This skill cannot convert a generation-1 definition automatically; do not hand-translate the JSON tree to TMDL for production use.

## 8. Authoring workflow (generation 2)
1. Resolve workspace and item; read the part layout with `getDefinition` (LRO) and save the envelope.
2. `python3 references/scripts/ontology_tmdl.py detect envelope.json`. If it prints `generation-1-json`, stop and use the legacy recipe, or migrate with the in-product copy.
3. `python3 references/scripts/ontology_tmdl.py unpack envelope.json work/`; edit `.tmdl` files with **tabs**.
4. `python3 references/scripts/ontology_tmdl.py check work/` (offline; cannot prove service acceptance).
5. Show the user a diff of changed parts (see [preview-and-confirm.md](preview-and-confirm.md)); get confirmation.
6. `python3 references/scripts/ontology_tmdl.py pack work/ -o body.json`, then `POST .../updateDefinition` with the body; poll the LRO; read back with `getDefinition` and compare.
7. Run the unit tests after changing the helper: `cd references/scripts && python3 -m unittest -v test_ontology_tmdl`.

## 9. Open items to verify with a real item
- Exact property names in every TMDL block (indentation and keywords were reconstructed).
- Accepted `format` query values; whether getDefinition returns more than TMDL.
- Which `properties.generation` value is the new experience.
- Whether the typed `/ontologies/...` paths and the generic `/items/...` paths behave identically for update.
