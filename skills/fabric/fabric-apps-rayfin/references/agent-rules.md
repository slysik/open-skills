# Rayfin — Agent rules (condensed mirror)

> **Source of truth:** <https://rayfin.ai/docs/reference/agent-rules.md> (Rayfin
> `@microsoft/rayfin-*` v1.36.2). This is a **condensed mirror** for low-context / offline
> use; **always re-check the live page before deploying** — Rayfin ships one shared version
> across every `@microsoft/rayfin-*` package (SDK, connectors, CLI) and API shapes differ
> between releases. Append `.md` to any doc route for a Markdown mirror; every page carries
> `sdk_version` / `cli_version` / `last_updated` frontmatter.

The short version of everything on the Rayfin site that changes whether generated code works.
Full detail lives in [Known limitations](known-limitations.md).

## Versions

- Every `@microsoft/rayfin-*` package — SDK, connectors, CLI — shares **one version number**.
  Install them all at the **same exact** version (e.g. `1.36.2`). Mixed versions produce type
  errors or two copies of `@microsoft/rayfin-data`.
- Read the project's `package.json` before using an API. Anything tagged "New in 1.36" on the
  site does not exist in older packages.
- Run the CLI from the project with **`npx rayfin`** so it matches the installed packages.

## Platform

- Rayfin uses **TC39 Stage 3 decorators**. Never enable `experimentalDecorators` or
  `emitDecoratorMetadata`. Include `ESNext.Decorators` in the tsconfig `lib`.
- One deployment target: a managed **Fabric app** (MSSQL only).
- Prefer `npm create @microsoft/rayfin@latest` for new projects — it generates a correct
  tsconfig, schema boilerplate, and agent files.

## Development loop

- Sign in before anything touching Fabric: `npx rayfin login`. Add
  `--encryption-fallback-enabled` only on machines with no OS keychain (dev containers,
  Codespaces) — it stores tokens in plaintext.
- `npm run dev` runs `rayfin dev`. It provisions or reuses the app's backend **in Fabric**,
  applies runtime settings and the data schema, writes `rayfin/.env` and `.env.local`, then
  starts the frontend (and Functions, when enabled) on the local machine. It is long-running —
  start it as a background process and stop it with Ctrl+C.
- The schema is applied when the session starts. **Restart `npm run dev` after editing
  `rayfin.yml` or files in `rayfin/data/`.**
- `rayfin dev` never publishes the frontend and does not wire connectors. Use `rayfin up` to
  publish and to test connectors. Leave `rayfin dev --provider` at its `fabric` default.

## Data modeling

- Define entities with `@entity()` in `rayfin/data/`, and register each one in
  `rayfin/data/schema.ts` as `type AppSchema = { Todo: Todo }`.
- Every field needs exactly one type decorator: `@uuid`, `@text`, `@int`, `@decimal`,
  `@boolean`, `@date`, `@email`, `@set`.
- Fields are **required by default**. For a nullable field use `{ optional: true }` **and** `?`
  together.
- `@text()`'s length option is `max`, not `maxLength` — `@text({ max: 200 })`. Always set `max`
  on MSSQL (see [Known limitations](known-limitations.md)).
- Never name an entity after a GraphQL built-in (`Date`, `String`, `Int`, `UUID`, `Query`,
  `Mutation`, or a `__` prefix). The CLI rejects it. Rename the class, or pass a different name
  with `@entity('EventDate')`.
- Use `@one(() => Target)` with a lazy arrow for relationships. Rayfin auto-generates the
  foreign key column, named `{property}_id`. A FK column referencing another entity must be
  `@uuid()` to match the PK. An auth-derived field (e.g. `user_id` from `claims.sub`) is
  `@text()`, not a foreign key.
- Use `import`, not `import type`, for entity classes referenced inside `@one()` / `@many()`
  arrows — the decorator needs the runtime class value.
- **Many-to-many is not supported.** Use an explicit join entity with two `@one()` fields.

## Security

- **Every entity needs an explicit permission decorator** (`@role`, `@anonymous`,
  `@authenticated`). Omitting one silently applies `authenticated: *` — full CRUD for any
  signed-in user — which is almost never what you want in production.
- Add a policy for row-level filtering on user-scoped data:
  `policy: (claims, item) => claims.sub.eq(item.user_id)`.
- Use `exclude` in role options to hide sensitive fields, e.g. `exclude: ['secret']`.
- Publishable keys (`pk-*`) are safe in client-side code. Never expose service secrets,
  connection strings, or tokens from `ctx.Tokens`.
- Keep `allowedRedirectUris` in `rayfin.yml` scoped to your app's own origins.
- Microsoft Entra ID is the only identity provider. Use Fabric SSO in browser apps (its popup
  flow works from any registered origin, incl. `http://localhost:5173`; only the iframe flow
  needs the Fabric portal), `signInWithEntraToken()` when code already holds a delegated token,
  and the embed host when your own portal embeds the app.
- Set `services.staticHosting.assetAccess` explicitly: `protected` (Fabric sign-in required to
  load the app) unless the app must be public.

## Querying

- The chain is `.select()` → `.where()` → `.orderBy()` → `.execute()`.
- Fetch one record with `client.data.Entity.findById('uuid')` — there is no `findByPk`.
- Filter by foreign-key columns using `{property}_id` (e.g. `customer_id`), not a dot-path
  (`customer.id`). Dot-paths are for `.select()` only.
- Sort directions are lowercase: `'asc'` or `'desc'`.
- Paginate with `.first(n).executePaginated()` and `.after(endCursor)`. Collection queries
  return a single page otherwise (default page size 100).
- `count()` does not exist on the fluent client; `count` is an aggregation that accepts
  **numeric fields only** (counts non-null numeric values, not rows). For a row count, select
  minimal fields and use `results.length` — see [Known limitations](known-limitations.md).
- Grouped aggregation cannot be combined with `.select()`, `.orderBy()`, `.first()`, or
  `.after()` — Data API Builder rejects `groupBy` + `items`. Sort the returned array in TS.

## Auth

- The session change callback is **`onSessionChange`**; `onAuthStateChange` does not exist.
- Session objects are opaque. Gate UI on `isAuthenticated` or the presence of a `user`
  property — do not introspect the session.
- Await `initEmbeddedAuth()` at startup before rendering authenticated content, even when a
  stored session already exists (in an embedded app it may belong to a different user).
- Call `ensureSignedInWithFabric()` directly from a click handler — never on page load or after
  an `await`, or the popup is blocked.
- After changing `services.auth` in `rayfin.yml`, restart `rayfin dev` or redeploy with
  `rayfin up` so the backend picks up the new settings.

## Configuration

- Always declare `services.auth` and `services.data` explicitly in `rayfin.yml`, even as
  `enabled: false`.
- If `services.data.enabled` is `true`, `dialect` is required — `mssql` is the only supported
  value.
- If `services.functions.enabled` is `true`, `services.functions.auth.type: application` is
  required.
- `RAYFIN_FEATURE_FLAGS` is not needed for Functions or connectors. Of the documented features,
  only experimental [storage](https://rayfin.ai/docs/storage) still uses it (`storage`).

## Functions

Read <https://rayfin.ai/docs/functions> before writing function code. Import
`UserDataFunctions`, `RayfinContext`, and `AudienceType` from
`@microsoft/fabric-user-data-functions`; `@microsoft/rayfin-functions` is the client invocation
SDK only. Register every function with `udf.func` (see [Known limitations](known-limitations.md)
for the app-identity token behavior and the five `AudienceType` members in 1.36).