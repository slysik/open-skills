---

name: dataflows-consumption-cli
description: >
  Monitor, inspect, and query saved Fabric Dataflows Gen2 via read-only CLI.
  List dataflows, decode base64 definitions (mashup.pq, queryMetadata.json,
  .platform), discover parameters, retrieve refresh status and job history,
  classify queries by staging, and execute queries against saved dataflows via
  the read-side `executeQuery` mashup engine (Arrow IPC response). Runs
  persisted or ad-hoc read-only executeQuery requests; parses/renders Arrow
  results. For previewing
  candidate M before persisting, or for `supportedConnectionTypes`/`credentialType`
  discovery and connection configuration, use `dataflows-authoring-cli`
  (not this skill).
  Triggers: "list dataflows", "inspect dataflow", "decode dataflow definition",
  "dataflow parameters", "dataflow refresh status", "refresh history",
  "last refresh status", "dataflow job history", "execute dataflow query",
  "executeQuery saved query", "executeQuery fetch rows", "ad-hoc dataflow query",
  "parse Arrow response", "Arrow IPC", "dataflow staging analysis".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/dbx-snowflake-fabric/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find a dataflow by name: list all dataflows in the workspace and filter by `displayName` client-side — there is no server-side name filter
> 3. `getDefinition` is a **POST**, not GET — even though it reads data

# dataflows-consumption-cli — Dataflows Gen2 Consumption via CLI

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
