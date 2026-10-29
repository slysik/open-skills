---
name: fabric-apps-rayfin
description: "Build TypeScript backend apps that run on Microsoft Fabric as a managed Fabric App (MSSQL only) with the @microsoft/rayfin CLI (Rayfin): scaffold, model entities, develop, deploy. USE FOR: Rayfin, rayfin-cli, Fabric Apps, TS backend on Fabric, rayfin dev/up/login. DO NOT USE FOR: Power BI reports (powerbi-report-*), Lakehouse/Warehouse SQL (sqldw-*), Fabric Data Factory pipelines (microsoft-fabric)."
license: MIT
metadata:
  author: slysik
  version: "0.1.0"
  updated: "2026-10-29"
---

# Fabric Apps — Rayfin Skill

Build full-stack **TypeScript** backend apps that run on **Microsoft Fabric** as a managed
**Fabric App** (MSSQL only) with the `@microsoft/rayfin-cli` (bin `rayfin`). You define
entities as decorated TypeScript classes; Rayfin generates the DB schema, REST + GraphQL APIs,
and type-safe clients, then deploys with Microsoft Entra ID auth, Functions, blob storage, and
static hosting built in.

> **Preview gating.** Fabric Apps is a tenant-admin-gated preview — a Fabric tenant admin must
> enable the preview setting before `rayfin dev` / `rayfin up` can provision an app.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/agent-rules.md](references/agent-rules.md) | The condensed do/don't list. **Read before generating** entities, queries, permission decorators, functions, connectors, or deploy commands. |
| [references/known-limitations.md](references/known-limitations.md) | Platform constraints that silently break deploys (MSSQL text caps, no many-to-many, FK `_id` naming, reserved entity names) + region/tenant gaps for Functions/Storage/deep-linking and the 1.36 connector changes. |

**Live source of truth** (documented against `@microsoft/rayfin-*` v1.36.2 — always re-check
version tags before copying a snippet): [`AGENTS.md`](https://rayfin.ai/AGENTS.md) ·
[`agent-rules`](https://rayfin.ai/docs/reference/agent-rules.md) ·
[`known-limitations`](https://rayfin.ai/docs/reference/known-limitations.md) ·
[`llms.txt`](https://rayfin.ai/llms.txt). Every doc route has a `.md` mirror and
`sdk_version` / `cli_version` / `last_updated` frontmatter.

## Versions

- All `@microsoft/rayfin-*` packages (SDK, connectors, **CLI**) share **one version**. Pin them
  to the **same exact** version (e.g. `1.36.2`); mixed versions produce type errors or two
  copies of `@microsoft/rayfin-data`.
- Check the project's installed `@microsoft/rayfin-*` versions before using any tagged API
  (`[New in 1.36]` etc.) — if the installed packages are older than the tag, the feature is not
  available there. (See [agent-rules](references/agent-rules.md) → Versions for the package-level detail.)
- Run the CLI with **`npx rayfin`** so it matches the installed packages.

## Development loop

```bash
npx rayfin login                                  # before anything touching Fabric
npm create @microsoft/rayfin@latest <dir>         # scaffold (tsconfig, schema boilerplate, agent files)
npm run dev                                        # = rayfin dev: provisions backend in Fabric, applies
                                                   #   schema + runtime, writes rayfin/.env + .env.local,
                                                   #   starts frontend (+ Functions when enabled). Long-running → background.
npx rayfin up                                      # deploy (publish frontend, wire + test connectors)
```

- `--encryption-fallback-enabled` only on machines with **no OS keychain** (dev containers,
  Codespaces) — it stores tokens in plaintext.
- `rayfin dev` is long-running: start it as a background process, stop it with Ctrl+C.
- Restart `npm run dev` after editing `rayfin.yml` or `rayfin/data/` — the schema is applied at
  session start. `rayfin dev` never publishes the frontend or wires connectors; use `rayfin up`
  for both. Leave `rayfin dev --provider` at its `fabric` default.

## Must

- Use **TC39 Stage 3 decorators**. Never enable `experimentalDecorators` or
  `emitDecoratorMetadata`; include `ESNext.Decorators` in the tsconfig `lib`.
- One deploy target: a managed **Fabric app, MSSQL only**.
- Scaffold new projects with `npm create @microsoft/rayfin@latest`.
- Pin every `@microsoft/rayfin-*` to one exact version; run the CLI via `npx rayfin`.
- Give **every entity an explicit permission decorator** (`@role` / `@anonymous` /
  `@authenticated`). Omitting one silently applies `authenticated: *` — full CRUD for any
  signed-in user. Add a row-level `policy: (claims, item) => …` for user-scoped data.
- Read [agent-rules](references/agent-rules.md) and [known-limitations](references/known-limitations.md)
  before generating entities, queries, permissions, functions, connectors, or deploy commands.

## Prefer

- Keep data access in `client.data.<Entity>` unless a Function is strictly required.
- `@text({ max: 200 })` (the option is `max`, not `maxLength`) — always set `max` on MSSQL.
- `@one(() => Target)` with a lazy arrow for relationships; the FK column is
  `{property}_id` and must be `@uuid()` to match the PK. Use `import`, not `import type`, for
  entity classes referenced inside `@one()` / `@many()` arrows.
- Query chain `.select()` → `.where()` → `.orderBy()` → `.execute()`; `findById('uuid')` (no
  `findByPk`); filter by `{property}_id` (not a dot-path — dot-paths are for `.select()` only);
  sort `'asc'`/`'desc'`; paginate with `.first(n).executePaginated().after(endCursor)`.
- Externalize config in `rayfin/.env` + `.env.local` (written by `rayfin dev`); publishable
  `pk-*` keys are safe client-side; never expose service secrets or `ctx.Tokens`.

## Avoid

- Mixing `@microsoft/rayfin-*` versions, or running the CLI other than via `npx rayfin`.
- Naming an entity after a GraphQL built-in (`Date`, `String`, `Int`, `UUID`, `Query`,
  `Mutation`, or any `__` prefix) — the CLI rejects it; rename the class or pass a name with
  `@entity('EventDate')`.
- Many-to-many — not supported; model an explicit join entity with two `@one()` fields.
- `count()` for row counts — it counts non-null **numeric** values, not rows; select minimal
  fields and use `results.length` (or page and sum `items.length`).
- Combining grouped `.aggregate(...)` with `.select()` / `.orderBy()` / `.first()` / `.after()`
  — Data API Builder rejects `groupBy` + `items`; sort the returned array in TypeScript instead.
- Relying on Functions/Storage before a `rayfin up` succeeds in your target workspace (not
  every region/tenant has them; Storage is experimental; Kusto connectors are held back in 1.36).
- `onAuthStateChange` — the callback is `onSessionChange`; gate UI on `isAuthenticated` or a
  `user` property (sessions are opaque), and call `ensureSignedInWithFabric()` from a click
  handler, never on page load or after an `await`.