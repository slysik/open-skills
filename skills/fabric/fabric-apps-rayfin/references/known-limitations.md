# Rayfin — Known limitations (condensed mirror)

> **Source of truth:** <https://rayfin.ai/docs/reference/known-limitations.md> (Rayfin
> `@microsoft/rayfin-*` v1.36.2). This is a **condensed mirror**; **always re-check the live
> page** before designing around a limitation — region/tenant availability and version-gated
> behavior change between releases. Each entry below names the limitation and the workaround to
> use instead. See also [agent-rules](agent-rules.md).

## Service availability

- **Functions are not in every region or tenant.** Functions are GA as of Rayfin 1.36 (no flag
  needed), but the service is not available in every Fabric region or tenant. *Workaround:*
  deploy a minimal app with `services.functions.enabled: true` and confirm `npx rayfin up`
  succeeds in your target workspace before you design around it. Keep data access in
  `client.data.<Entity>` where a function is not strictly required.
- **Storage is experimental.** Enabled only with `RAYFIN_FEATURE_FLAGS=storage` or
  `services.storage.enabled: true`; not available in every region/tenant; `@microsoft/rayfin-
  storage` may change substantially between releases. *Workaround:* confirm a storage-enabled
  deploy succeeds in your target workspace before you depend on it; pin every Rayfin package
  to one exact version.
- **Deep linking rolls out per tenant** (depends on the Fabric portal). *Workaround:* call
  `isSupported()` before showing a share button or relying on URL state; keep the app fully
  usable when it resolves to `undefined`.

## Functions

- **Function connections run only as the app identity** *(changed in 1.36).* A deployed
  function's `ctx.Tokens.<Audience>` token belongs to the app identity (the owner of the
  Fabric app item), not the signed-in user. `services.functions.auth.type` accepts only
  `application`, so a function cannot call an external resource as the caller. *Workaround:*
  grant the app identity access to each resource the function calls; for per-user data at the
  source, query it through a SQL/semantic-model connector with `auth.type: delegated` instead
  of a function. Data the app owns stays caller-scoped via `ctx.getDataClient()`.
- **Local function connections use your own identity.** Under `rayfin dev`, `ctx.Tokens` holds
  tokens for the account you signed in with, not the app identity — a call that works locally
  can fail after `rayfin up` with an authorization error. *Workaround:* grant the app identity
  access before you deploy and test the deployed function once with `npx rayfin up`.
- **Five audiences only** *(changed in 1.36).* `AudienceType` has `Sql`, `Storage`, `Fabric`,
  `AzureAI`, and `ADO`. `CosmosDB`, `KeyVault`, `EventGrid`, `Kusto`, and `WorkIQ` were removed
  in 1.36. *Workaround:* for a service that accepts key-based access, store the credential with
  `npx rayfin secret set` and read it from `ctx.Secrets` in the function.

## Connectors

- **Connectors do not run under `rayfin dev`.** `rayfin dev` reads the `connectors:` block but
  does not wire it, so connector calls do not work in a dev session until deployed. *Workaround:*
  deploy with `npx rayfin up` (or `npx rayfin up connector apply`) and test against the deployed
  app; prove the connector returns rows with `rayfin connector invoke` / `rayfin connector
  inspect` before you build UI on it.
- **New Kusto connectors cannot be added** *(changed in 1.36).* Rayfin 1.36 holds the `kusto`
  (Eventhouse) connector type back; `rayfin connector add`, `types`, and `search` reject it
  with `Connector type "kusto" is not available in this release.` A project that already
  declares a Kusto connector keeps validating and deploying. *Workaround:* keep existing Kusto
  connectors as they are.
- **`rayfin connector inspect` does not support Kusto.** It works for `fabric-sqlanalytics`,
  `fabric-warehouse`, `fabric-sqldatabase`, and `fabric-semanticmodel`; a `kusto` connector
  fails with `Unsupported connector type: kusto`. *Workaround:* use
  `npx rayfin connector invoke <name> executeQuery` (posts to the deployed item, so needs a prior
  `npx rayfin up`).
- **Install connector packages at the pinned version.** An unversioned install of a connector
  package can resolve to a different release than the rest of your Rayfin packages, pulling its
  own `@microsoft/rayfin-data` and leaving two Rayfin version lines in one app. *Workaround:*
  run the version-pinned `npm install` that `rayfin connector add` prints, verbatim.
- **Decorated entity classes can break a browser bundle.** `connectorConfig.entities` accepts
  either an entity's class or a string array of its field names; the class form is required to
  select a relationship (the array form throws `ENTITIES_REQUIRED_FOR_RELATIONSHIP_SELECT`). But
  a bundler that lowers decorators on an entity class produces an invalid class expression, and
  the deployed page fails to parse at runtime. *Workaround:* in browser-loaded code, list each
  entity's fields as a string array unless you need relationship selects; if you use the class
  form, confirm the production build runs before you deploy.

## Data client

- **`count()` counts numeric values, not rows.** The fluent GraphQL client has no `count()` on
  the query chain; `count` exists only as an aggregation, and Data API Builder types its field
  argument as the entity's numeric fields — so it can only target a numeric column and returns
  the number of rows where it is non-null. *Workaround:* point `count` at a non-nullable numeric
  column when the entity has one; otherwise select minimal fields and use `results.length`, or
  page with `.executePaginated()` and sum `items.length` per page.
- **Grouped aggregation cannot be combined with row selection.** Data API Builder rejects a
  query that requests `groupBy` and `items` together, so `.aggregate(...)` is mutually exclusive
  with `.select()` / `.orderBy()` / `.first()` / `.after()`. *Workaround:* compute groups
  server-side and sort/limit the returned array in TypeScript.

## Schema / platform

- **Text without `max` breaks GraphQL schema generation on MSSQL.** Always set `@text({ max })
  — not `maxLength` — on MSSQL.
- **Foreign keys must use the `{property}_id` naming convention** and must be `@uuid()` to match
  the PK. An auth-derived `user_id` is `@text()`, not a FK.
- **Many-to-many is not supported** — model an explicit join entity with two `@one()` fields.
- **`dialect` is required when the data module is enabled** (`mssql` is the only supported
  value); declare `services.auth` and `services.data` explicitly in `rayfin.yml`, even as
  `enabled: false`.
- **Reserved entity names** — the CLI rejects any class named after a GraphQL built-in (`Date`,
  `String`, `Int`, `UUID`, `Query`, `Mutation`, or a `__` prefix); rename the class or pass a
  different name with `@entity('EventDate')`.
- **The session callback is `onSessionChange`, not `onAuthStateChange`.**