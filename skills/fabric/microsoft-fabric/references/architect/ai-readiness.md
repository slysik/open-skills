# Fabric architect: AI-readiness

Last verified: 2026-10-19 (Learn: `data-science/concept-data-agent` 2026-09-29, `fundamentals/copilot-fabric-overview` 2026-09-04, `fundamentals/copilot-ai-feature-state` 2026-07-12, `iq/overview` 2026-07-08, `iq/ontology/overview` 2026-10-16, `data-science/ai-functions/overview` 2026-09-19, `data-science/ai-services/ai-services-overview` 2026-10-12, `real-time-intelligence/vector-database` 2026-06-23, `database/sql/use-case-ai-application` 2026-09-15). **Status labels on Learn disagree with each other here; always re-check before a customer commitment.**

## 1. Status table (as stated by pages)
| Capability | Status | Notes |
|---|---|---|
| Fabric data agent | GA per concept page; release-status table (2026-06-19) still says Preview | Trust the newer page, say "GA per concept page" |
| Copilot in Fabric | Mixed. GA: Data Factory, SQL database, Power BI, KQL queryset, real-time dashboards. PREVIEW: notebooks, Warehouse SQL, operations agent for pipelines (Learn 2026-10-21; the June release table listed the operations agent as GA, now stale) | Overview text still says "in preview" |
| AI functions | UNVERIFIED (overview silent; table says Preview, stale) | Lean preview |
| Prebuilt Foundry Tools (formerly AI services) | PREVIEW | gpt-5.1, gpt-5-mini, text-embedding-ada-002; bring-your-own-key available |
| Fabric IQ (ontology) | PREVIEW | Old ontology experience retires 2027-01-31 |
| Graph in Fabric | Overview calls IQ items preview; graph page silent: UNVERIFIED | GQL (ISO 39075) |
| Eventhouse vector search | No label on page | No native ANN index |
| SQL database in Fabric vector | UNVERIFIED | `vector` type, `VECTOR_DISTANCE`, `VECTOR_SEARCH` described |
| Fabric IQ MCP | **GA** (Learn 2026-10-21) | Read-only; Power BI reports and semantic models only; does **not** serve ontologies or data agents; delegated OAuth only. Details in [fabric-iq-ontology-planning.md](fabric-iq-ontology-planning.md). Other Fabric MCP servers (local/remote item CRUD): still UNVERIFIED |

## 2. Data agent (design rules)
- Needs paid F2 or higher (or P1+ with Fabric), AI tenant settings incl. cross-geo processing where required, and read access to at least one source.
- Sources: lakehouse (tables only), warehouse, Power BI semantic model, KQL DB, mirrored database, ontology; Graph is PREVIEW.
- Limits: 5 sources per agent; 100 example queries per source (none for semantic models); responses capped at 25 rows and 25 columns; read-only; no unstructured files; English only; cannot change the LLM; source and agent capacity must share a region.
- Consumers: Microsoft 365 Copilot, Copilot Studio, Azure AI Foundry, Teams. Git and deployment pipelines supported.
- Quality comes from the model underneath: curated semantic model or ontology, descriptions, example queries. A messy schema gives a confidently wrong agent.

## 3. Copilot data handling (customer-security question #1)
Enabled by default on paid F2+ (not trial, not sovereign clouds). Azure OpenAI runs in US datacenters and the EU data boundary. Capacities in UK, Australia, Brazil, Canada, India, Asia, Japan, Korea, South Africa, Southeast Asia, UAE need the cross-geo tenant setting (UK processes in EU, others in US). Prompts, meta prompts, schema and conversation history may be sent; table contents are not unless directed. History for notebook Copilot and data agents is kept 28 days unless cleared.

## 4. Fabric IQ and ontology
For namespaces, inheritance, version history, RDF/OWL import, the TMDL definition format (and the old-format retirement on 2027-01-31) and Planning, see [fabric-iq-ontology-planning.md](fabric-iq-ontology-planning.md).

Ontology binds to semantic models, lakehouses, eventhouses, warehouses, SQL databases, mirrored databases, shortcuts, views and materialized views; can be generated from a semantic model (DAX measures become metrics); imports RDF, Turtle, OWL and exports RDF/Turtle; graph materialization is optional; respects OneLake security, RLS, OLS, CLS. Graph billing: 10 CU-s per CPU-second, minimum 100 GB. Tenant toggles and SKU requirements: `UNVERIFIED`.

## 5. AI functions and Foundry tools
- Functions: `ai.analyze_sentiment`, `classify`, `embed`, `extract`, `fix_grammar`, `generate_response`, `similarity`, `summarize`, `translate`. Surfaces: pandas and PySpark, Dataflow Gen2, T-SQL in Warehouse and SQL endpoint (`AI_EMBED` and `AI_SIMILARITY` not available in T-SQL). Multimodal input supported.
- Needs paid F2+, Azure OpenAI tenant switch, Runtime 1.3+. Default model `gpt-5-mini` (low reasoning); configurable to other chat-completions/responses-compatible models. Billed as "AI Functions" on the Copilot and AI meter; Spark compute separate.
- Foundry tools consumption: gpt-5.1 42.02 CU-s per 1K input and 336.13 per 1K output; gpt-5-mini 8.40 and 67.23; ada-002 3.36 per 1K input.

## 6. Vector and RAG placement
| Need | Where | Why |
|---|---|---|
| Small-scale vectors next to analytical/event data | Eventhouse (`Vector16`, `series_cosine_similarity()`) | No ANN index; scale via sharding |
| App-grade vector with transactions | SQL database in Fabric (`vector` type) status UNVERIFIED, or Azure Cosmos DB (DiskANN) | Index types and limits in the Cosmos skill |
| Enterprise search with hybrid ranking | Azure AI Search (integration page not retrieved: `UNVERIFIED`) | Mature search features |

## 7. Anti-patterns
- Pointing a data agent at raw bronze tables.
- Promising Copilot in a region that needs cross-geo approval without the CISO signing off.
- Treating preview items as production commitments (ontology, Foundry tools, notebook Copilot).
- Ignoring the Copilot and AI meter in capacity sizing.

## 8. Talk track
"AI-ready means governed, described, well-modelled data first. Fabric gives you the agent and the grounding layer on top of OneLake. We confirm which pieces are GA today, keep preview items out of the critical path, and settle the data-residency question for Copilot before anyone enables it."
