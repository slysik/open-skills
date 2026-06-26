---
name: databricks-config
description: "Manage Databricks workspace connections: check current workspace, switch profiles, list available workspaces, or authenticate to a new workspace. Use when the user mentions \"switch workspace\", \"which workspace\", \"current profile\", \"databrickscfg\", \"connect to workspace\", or \"databricks auth\"."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# Databricks — Connection (CLI-first)

**Primary path = Databricks CLI** (v0.288+), token-based profiles in
`~/.databrickscfg`, passed with `-p <profile>`. The MCP server
`mcp__databricks__manage_workspace` is an **optional convenience only** — it has
registered **0 tools** in this environment, so never depend on it. CLI works today.

Standard connection contract: **Interactive · Service principal · Verify · Troubleshoot**.

## Interactive (dev default)

```bash
databricks -p slysik-aws current-user me          # who am I
databricks -p slysik-aws warehouses list          # reachable SQL warehouses
databricks -p slysik-aws clusters list
databricks -p slysik-aws catalogs list            # Unity Catalog
```

Profiles (`~/.databrickscfg`):
- **slysik-aws** (PRIMARY) → `dbc-61514402-8451.cloud.databricks.com`
- **slysik-aws-backup** → `dbc-a092293f-ea93.cloud.databricks.com`

New workspace / re-auth:

```bash
databricks auth login -p <profile> --host https://<workspace>.cloud.databricks.com
```

## Service principal (headless / cron)

Each workspace has an `-sp` profile variant (e.g. `slysik-aws-sp`) using
OAuth M2M (client-credentials). Use these for jobs, CI, and cron.

```bash
databricks -p slysik-aws-sp current-user me
# ~/.databrickscfg SP block: host + client_id + client_secret (OAuth M2M)
```

Set `serverless_compute_id = auto` (or a `cluster_id`) in the profile so SQL/exec
has compute without an interactive pick.

## Verify (single command)

```bash
databricks -p slysik-aws current-user me && databricks -p slysik-aws warehouses list
```

Prints identity + at least one warehouse when the profile is healthy.

## Troubleshoot

| Symptom | Cause | Fix |
|---|---|---|
| `default auth: cannot configure default credentials` | No / wrong profile | Pass `-p slysik-aws`; or `databricks auth login -p <profile>`. |
| `account workspaces list` fails | No `account_id` / accounts host configured | Account API not set up; use the two workspace profiles. Add account host + `account_id` to enable. |
| MCP tool not found | MCP server registers 0 tools | Expected — use the CLI. MCP is optional convenience, not required. |
| Switch resets after restart | MCP switch is session-scoped | Set the profile in `~/.databrickscfg` for permanence. |

> If the `mcp__databricks__manage_workspace` tool ever does register tools, it may
> be used as a convenience for status/list/switch — but the CLI remains the
> contract and the only required dependency.
