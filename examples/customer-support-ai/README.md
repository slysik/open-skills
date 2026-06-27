# Customer Support AI Smoke Test

This example asks each platform to build the same customer-support resolution
copilot from one high-level prompt. The benchmark is intentionally small and
deterministic so failures point to skill or platform gaps instead of data drift.

## Constraints

- CLI first.
- REST APIs only where the platform CLI has no equivalent.
- No MCP tools.
- Keep AI calls bounded to the eight seed tickets.
- Write one JSON result per platform under `reports/customer-support-ai/raw/`.

## Dataset

The generator creates the same seven tables for every platform:

1. `customers`
2. `products`
3. `orders`
4. `order_items`
5. `support_tickets`
6. `ticket_messages`
7. `knowledge_articles`

Generate the data:

```bash
python3 examples/customer-support-ai/data/generate.py
```

Output is written to `examples/customer-support-ai/generated/`:

- CSV files for inspection and alternate loaders.
- SQL insert files for Databricks, Snowflake, and Fabric Warehouse.
- `knowledge_base.md` for Foundry file-search RAG.
- `manifest.json` with row counts and estimated source tokens.

## Smoke Harnesses

Dry-run all command paths without creating cloud objects:

```bash
just smoke-databricks --dry-run
just smoke-snowflake --dry-run
just smoke-microsoft --dry-run
```

Execute against configured environments:

```bash
just smoke-databricks
just smoke-snowflake
just smoke-microsoft
```

See each script's `--help` output for required environment variables and CLI
options.

## Success Criteria

- All seven tables are created and populated.
- `customer_360` and `ticket_operations` analytical views are queryable.
- Ticket summary, category, and sentiment enrichment completes.
- A knowledge-base retrieval path returns relevant articles.
- The platform writes a result JSON with elapsed time, row counts, tokens when
  exposed, cost when exposed, errors, and missing features.
- `scripts/compare_customer_support_smoke.py` creates the comparison matrix.

## Canonical Prompt

The prompt in `prompts/build-solution.md` is the request an agent should receive.
The test is successful only when the agent discovers and uses the relevant
installed skills without the prompt naming individual skills.
