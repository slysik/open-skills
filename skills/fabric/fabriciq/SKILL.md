---

name: fabriciq
description: >
  Answer business questions by querying Power BI reports and dashboards through the FabricIQ MCP endpoint.
  Orchestrates: discover Power BI artifacts, inspect report/model schemas, resolve entity values, generate DAX, execute queries.
  Returns plain-language answers from Power BI semantic models.
  Use when the user asks a natural-language question about Power BI report or dashboard content (not raw DAX).
  Triggers: "ask power bi", "PBI question", "discover report", "report data",
  "dashboard data", "what are the top", "show me the power bi data",
  "which products sold", "compare sales in report".
metadata:
  version: "0.2.0"
  updated: "2026-06-25"
---

> **Update Check — ONCE PER SESSION (mandatory)**
> The first time this skill is used in a session, run the **check-updates** skill before proceeding.
> - **GitHub Copilot CLI / VS Code**: invoke the `check-updates` skill.
> - **Claude Code / Cowork / Cursor / Windsurf / Codex**: compare local vs remote package.json version.
> - Skip if the check was already performed earlier in this session.

> **CRITICAL NOTES**
> 1. To find artifact details (including artifact ID) from a search query: use `DiscoverArtifacts` with the search term — do not call workspace/item list APIs
> 2. To find the semantic model behind a report: call `GetReportMetadata` and extract the model GUID from the response
> 3. When the user provides a Power BI URL: call `ResolveReportIdFromUrl` to get the correct report GUID before proceeding

# Power BI Consumption — FabricIQ Skill

> ⚠️ **STOP — Read this entire skill document in full before taking any action.** Do not begin orchestrating tool calls until you have read and internalized all sections below, including Workflow, DAX Rules, Verified Answers, and Error Recovery. Skipping ahead leads to incorrect queries and missed instructions.

You help users analyze Power BI data. You orchestrate each step: discover artifacts, inspect report and model schemas, resolve values, and execute queries. Uses the FabricIQ MCP server.

## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/guidelines-and-examples.md](references/guidelines-and-examples.md) | Detailed rules, tool selection rationale, Must/Prefer/Avoid matrices, and quick start code templates. |
