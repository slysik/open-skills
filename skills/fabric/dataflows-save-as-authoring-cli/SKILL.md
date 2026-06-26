---

name: dataflows-save-as-authoring-cli
description: >
  Assess, plan, and execute dataflow Gen1 → Gen2.1 CI/CD save-as operations via CLI
  (az rest / curl) against Power BI REST and Fabric REST APIs. Scan workspaces or
  entire tenants for Gen1 dataflows, evaluate save-as readiness with seven risk signals
  (incremental refresh, BYOSA storage, Power Automate triggers, pipeline dependencies,
  linked entities, DirectQuery, caller-not-owner), produce a Save-As Readiness Snapshot (markdown + JSON),
  and invoke the SaveAsNativeArtifact API to create upgraded Gen2.1 copies of Gen1 dataflows.
  **Invoke this skill** whenever the user wants to: (1) discover Gen1 dataflows in a workspace or tenant,
  (2) assess save-as readiness and risk signals, (3) upgrade or migrate Gen1 into a Gen2.1 copy,
  (4) validate post-save-as data integrity, (5) detect residual Gen1 references.
  Triggers: "save Gen1 dataflow", "convert dataflow Gen1", "upgrade dataflow", "migrate dataflow",
  "dataflow readiness", "Gen1 to Gen2", "dataflow save-as assessment", "saveAsNativeArtifact",
  "dataflow save-as scan".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare this skill's local `SKILL.md` `metadata.version` / `metadata.updated` against the remote `catalog.json` entry at `https://raw.githubusercontent.com/slysik/open-skills/main/catalog.json`; if remote is newer or differs, tell the user to reinstall with `install.sh`.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find the workspace details (including its ID) from workspace name: list all workspaces and, then, use JMESPath filtering
> 2. To find the item details (including its ID) from workspace ID, item type, and item name: list all items of that type in that workspace and, then, use JMESPath filtering

# dataflows-save-as-authoring-cli — Dataflow Save-As Gen1 → Gen2.1 CI/CD via CLI

A save-as companion for creating upgraded Gen2.1 copies from Power BI Gen1 dataflows using readiness assessment and guarded execution.

> We currently cannot perform an in-place migration of your dataflow. We can use save-as to create an upgraded Gen2.1 copy while preserving the original Gen1 dataflow.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
