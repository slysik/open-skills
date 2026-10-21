# Fabric architect: Fabric IQ (ontology, planning, MCP)

Last verified: 2026-10-21. Source: Microsoft Learn `fabric/iq/overview` (2026-07-08), `iq/ontology/*` (overview, tenant settings, namespaces, inheritance, version history, import-export, rules, graph, bind data, generate from semantic models, ontology agent; 2026-09 to 2026-10-20), `rest/api/fabric/articles/item-management/definitions/ontology-definition` (2026-09-10), `rest/api/fabric/ontology/items`, `iq/plan/*` (overview 2026-07-28, prerequisites 2026-09-23, limitations 2026-10-09, writeback, database connection), `iq/connectors/fabric-iq-mcp` (2026-10-21), `iq/connectors/microsoft-365-copilot-overview` (2026-09-23). Tags are the pages' own; the IQ workload page is titled "IQ (preview)". Pages not found are marked `NOT FOUND`; unverified claims are `UNVERIFIED`. This is the decision layer; the build mechanics for the ontology item live in the upstream `fabriciq-ontology-cli` skill (see the format warning in section 3).

## 1. Status at a glance
| Item | Status as Learn states it | Notes |
|---|---|---|
| Ontology item | **Preview** (every ontology page) | Old experience retires **2027-01-31**; it can no longer be created in the UI, only via APIs or CI/CD |
| Namespaces, inheritance, version history, RDF/OWL import-export, rules, graph, ontology agent, generate-from-semantic-model | Preview (each page) | |
| Ontology entity actions; policy-governed multi-hop relationships | **NOT FOUND** on Learn | Do not promise them. The graph page has a path-query pane and optional graph execution |
| Planning | Overview has no status label ("now available worldwide as part of the Microsoft Fabric SKU"); Git and deployment-pipeline pages tag **Plan preview** | Keynote said GA; cite the Learn wording and flag the conflict |
| Data agent | GA per its concept page | See `ai-readiness.md` |
| Fabric IQ MCP | **Generally available** (read-only) | Power BI reports and semantic models only |
| Copilot Chat data answers over Power BI | GA | Needs a Microsoft 365 Copilot Premium licence |

## 2. Ontology: what to know for a design session
**When to use it**: a shared business vocabulary (entities, relationships, metrics, rules) across sources, grounding for agents. **When not to**: a single-model BI problem a semantic model already solves; any workload that cannot depend on a preview item.

Prerequisites: tenant settings "Users can create Fabric items" and "Users can create ontology (preview) items" (OneLake catalog, Govern, Configurations, Tenant settings); a Fabric-enabled capacity (no specific F SKU stated); semantic-model sources need Read and Build permission; the ontology agent needs the Copilot cross-geo setting if the capacity is outside the US/EU data boundary.

| Capability | Facts (all Preview) |
|---|---|
| Namespaces | Every ontology has an undeletable `Default` namespace; each concept (entity or relationship type) is in exactly one namespace; a namespace cannot be deleted while referenced |
| Inheritance | Single parent; circular inheritance rejected; derived types do **not** inherit data bindings or non-is-a relationships; inherited property name and type are immutable |
| Version history | Manual named versions; Restore replaces the whole definition; needs Read/Write on the item |
| Import / export | Import into an **empty** ontology from TTL, RDF/RDFS or OWL; export as TTL or RDF (OWL is import-only); import summary shows Preserved, Auto-fixed, Not supported and cannot be reopened |
| Rules | Natural-language rules (name + definition), not executed by the ontology; read-only MCP tool `list_ontology_rules`; no Activator integration in the new experience |
| Bindings | Sources: Eventhouse, KQL database, Lakehouse, Mirrored database, Semantic model, SQL database, Warehouse (plus shortcuts, views, materialized views); key must be string or integer; semantic-model DAX measures appear as **metrics** and the DAX stays owned by the source model |
| Graph | Opt-in ("Manage graph"); only Delta tables from lakehouses or mirrored databases are eligible (semantic-model-bound entities are not); entity key required; materialization takes "several minutes to several hours" |
| Ontology agent | Plan mode (no changes) and Act mode; Contributor or higher to apply changes; row caps 1,000 (KQL, SQL, GQL) and 200 (DAX); 10 attachments of 5 MB; 24-hour conversations; no CMK for conversation data |

Operational limits live in the definition format (section 3). No capacity-sizing or quota page was found.

## 3. Ontology as code: format warning
- Learn's current definition page describes the **new** Ontology item as **TMDL-based**: parts `.platform` (type `Ontology`, `config.version` 2.0, `logicalId`), `database.tmdl` (`compatibilityLevel: 1000000`), `model.tmdl`, `namespaces/default.tmdl`, `namespaces/{ns}.tmdl`, `entities/{ns}#{name}.tmdl`, `entityRelationships.tmdl`, `relationships.tmdl`, `tables/{name}.tmdl`, `metrics/{name}.tmdl`, `expressions.tmdl`, `rules/{rule}.tmdl`, all `InlineBase64`. Minimum write payload: `.platform` + `database.tmdl`; the service adds `model.tmdl` and `namespaces/default.tmdl`.
- The upstream `skills/fabric/fabriciq-ontology-cli/references/authoring.md` (line 54 onward) authors the **old JSON tree** (`definition.json`, `EntityTypes/{id}/definition.json`, `DataBindings/`, `RelationshipTypes/`). Learn says the old experience retires 2027-01-31. **Treat the upstream authoring recipe as the old-experience path** until it is reconciled; new ontologies should follow the TMDL definition page.
- Definition limits (from the definition page; the lower half was a model summary, so `UNVERIFIED`-level): entity properties 1,000 per entity; rules 1,000 per model; key properties 100; tables+columns about 16,000 combined; names 512 chars; descriptions and rule statements 4,000 chars; expression bodies 100,000 chars.
- REST: item type Ontology supports create, get, list, update, delete, get definition and update definition (`rest/api/fabric/ontology/items`). The page text did not show paths or scopes: the expected form `https://api.fabric.microsoft.com/v1/workspaces/{workspaceId}/ontologies` (plus `/getDefinition`, `/updateDefinition`) is `UNVERIFIED`; the upstream skill creates the item through the generic `POST /v1/workspaces/{ws}/items` with type Ontology. Git and deployment pipelines tag Ontology preview.

```json
{ "parts": [
  { "path": ".platform", "payload": "<base64 of platform json, type Ontology>", "payloadType": "InlineBase64" },
  { "path": "database.tmdl", "payload": "<base64 of: database / compatibilityLevel: 1000000>", "payloadType": "InlineBase64" }
] }
```

## 4. Planning
**When to use**: finance or operations teams that need budgets, forecasts and what-if scenarios on top of a semantic model, with write-back to a governed store. **When not to**: pure reporting; a workspace on workspace-level private links (plan items are unsupported there).

- Build steps documented: create a plan item (a SQL database in Fabric for plan metadata is auto-created in the workspace), connect it to **one** semantic model (cannot be changed later; not My workspace), add planning sheets (sheet types named: Planning, PowerTable, Intelligence, Infobridge), optionally set up an organizational-account connection for collaboration.
- Prerequisites: tenant setting "Allow XMLA endpoints and Analyze in Excel with on-premises semantic models"; capacity XMLA endpoint Read Only or Read Write; XMLA-dependent scenarios need an F SKU or P1 to P5 and **do not support Power BI Pro or PPU**; "Service principals can call Fabric public APIs" only for service-principal auth.
- **Write-back** target is a SQL database in Fabric. Trigger documented as manual ("Writeback > Writeback"); the overview's "automatically" wording is `UNVERIFIED`. Types: Long, Wide, Long with Changes, Wide with Changes. Rewrites replace rows matching all dimension columns; deleting a sheet row does **not** delete it from the table; if dimensions change, drop and recreate the destination table. Do not query `__fabric_plan_sys_db`.
- Limits: 25 sheets and 50 visuals per item; writeback 1.2 million cells per operation; Infobridge query 10 million cells; bulk input 10 million rows; Excel export 20 million cells (raw). Renaming the semantic model or workspace breaks the plan item. Deployment pipelines fail with 100 Data Input items.
- **Event triggers**: the phrase is `NOT FOUND`; the closest documented feature is PowerTable database-trigger automation (Create, Update, Delete Record, Form Submission), with up to 10 records per trigger. Billing meter names and units: `NOT FOUND`.
- Mechanisms: portal; no REST, Terraform or CLI found. Git/deployment pipelines tag Plan preview.

## 5. Fabric IQ MCP and Copilot Chat
- Endpoint `https://fabriciq.svc.cloud.microsoft/v1/mcp/fabriciq` (private-link alternative `https://api.fabric.microsoft.com/v1/mcp/fabriciq`), Streamable HTTP, six tools: `DiscoverArtifacts`, `ResolveFabricItem`, `GetReportMetadata`, `GetSemanticModelSchema`, `ValueSearch`, `ExecuteQuery` (single model, default 250 rows).
- Auth: delegated OAuth through Entra, scopes `Item.Read.All` and `Item.Execute.All`; **service principal and app-only auth are not supported**. GitHub Copilot CLI uses a preregistered Entra app (config in `~/.copilot/mcp-config.json`, type `http`, optional header `X-Variants: Fabric.Routing.FabricIQ.V1`, no Authorization header); other clients need a single-tenant app registration.
- **It does not support Fabric ontologies or data agents.** Not available in Power BI-only or sovereign regions.
- Copilot Chat: needs the Microsoft 365 Copilot Premium licence and the tenant settings "Fabric data available in M365 Copilot", "Share Fabric data with your Microsoft 365 services" and the Azure OpenAI cross-geo setting; data agents and ontologies appear only if published as a Microsoft 365 agent. Copilot Cowork plugin: `UNVERIFIED`.
- The upstream `fabriciq` skill drives this MCP for Power BI Q&A.

## 6. Anti-patterns
- Building production grounding on an ontology while it is preview, with no fallback.
- Authoring new ontologies with the old JSON tree that retires 2027-01-31.
- Promising entity actions or "policy-governed multi-hop" relationships (no Learn page).
- Expecting the IQ MCP to serve an ontology.
- Choosing Planning for a Pro/PPU-only tenant that needs XMLA scenarios.
- Treating plan write-back as automatic or as delete-aware.

## 7. Talk track
"Fabric IQ is the business-meaning layer: the ontology names entities, relationships and metrics once and binds them to the governed tables, so agents answer with your definitions. It is preview, so we keep it off the critical path, and for planning we write back to a SQL database in Fabric that finance can audit."
