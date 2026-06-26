---

name: search-consumption-cli
description: >
  Find and discover Microsoft Fabric items across workspaces when the workspace is unknown.
  Use when the user wants to: (1) find an item by name across workspaces,
  (2) list items of specific type across workspaces, (3) identify which workspace contains an item,
  (4) return item/workspace IDs for downstream API calls.
  Triggers: "which workspace has", "where is", "what items do I have", "do I have",
  "find item", "find all items", "search for item", "discover items", "find across workspaces".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill (e.g., `/fabric-skills:check-updates`).
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: read the local `package.json` version, then compare it against the remote version via `git fetch origin main --quiet && git show origin/main:package.json` (or the GitHub API). If the remote version is newer, show the changelog and update instructions.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. The Catalog Search API finds **items**, not workspaces. To find a workspace by name, use `GET /v1/workspaces` (see [COMMON-CLI.md § Resolve Workspace Properties by Name](../../common/COMMON-CLI.md#resolve-workspace-properties-by-name)).
> 2. The search text matches against item **display name**, **description**, and **workspace name**.
> 3. Dataflow (Gen1) and Dataflow (Gen2) are not supported.

# Catalog Search — CLI Skill

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
