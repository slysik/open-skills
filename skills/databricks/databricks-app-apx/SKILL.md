---
name: databricks-app-apx
description: "Build full-stack Databricks applications using APX framework (FastAPI + React)."
---

# Databricks APX Application

Build full-stack Databricks applications using APX framework (FastAPI + React).

## Trigger Conditions

**Invoke when user requests**:
- "Databricks app" or "Databricks application"
- Full-stack app for Databricks without specifying framework
- Mentions APX framework

**Do NOT invoke if user specifies**: Streamlit, Dash, Node.js, Shiny, Gradio, Flask, or other frameworks.

## Prerequisites Check

Option A)
Repository configured for use with APX.
1.. Verify APX MCP available: `mcp-cli tools | grep apx`
2. Verify shadcn MCP available: `mcp-cli tools | grep shadcn`
3. Confirm APX project (check `pyproject.toml`)

Option B)
Install APX
1. Verify uv available or prompt for install. On Mac, suggest: `brew install uv`.
2. Verify bun available or prompt for install. On Mac, suggest: 
```
brew tap oven-sh/bun
brew install bun
```
3. Verify git available or prompt for install.
4. Run APX setup commands:
```
uvx --from git+https://github.com/databricks-solutions/apx.git apx init
```


## Workflow Overview

Total time: 55-70 minutes

1. **Initialize** (5 min) - Start servers, create todos
2. **Backend** (15-20 min) - Models + routes with mock data
3. **Frontend** (20-25 min) - Components + pages
4. **Test** (5-10 min) - Type check + manual verification
5. **Document** (10 min) - README + code structure guide


## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/workflow-phases.md](references/workflow-phases.md) | APX — Phases 1-6 (init, backend, frontend, testing, deploy, docs) |

## Key Patterns

### Backend
- **3-model pattern**: Separate In, Out, and ListOut models
- **operation_id naming**: `listEntities` → `useListEntities()`
- **Type hints everywhere**: Enable validation and IDE support

### Frontend
- **Suspense hooks**: `useXSuspense(selector())`
- **Suspense boundaries**: Always provide skeleton fallback
- **Formatters**: Currency, dates, status colors
- **Never edit**: `lib/api.ts` or `types/routeTree.gen.ts`

## Success Criteria

- [ ] Type checking passes (`apx dev check` succeeds)
- [ ] API endpoints return correct data (curl verification)
- [ ] Frontend displays and mutates data correctly
- [ ] Loading states work (skeletons display)
- [ ] Documentation complete

## Common Issues

**Deployed app not working**: Ask to check deployed app logs (APX MCP will automatically retrieve and analyze them) or manually use `databricks apps logs <app-name>`
**Python type errors**: Use explicit casting for dict access, check Optional fields
**TypeScript errors**: Wait for OpenAPI regen, verify hook names match operation_ids
**OpenAPI not updating**: Check watcher status with `apx dev status`, restart if needed
**Components not added**: Run shadcn from project root with `--yes` flag

## Reference Materials

- **[backend-patterns.md](backend-patterns.md)** - Complete backend code templates
- **[frontend-patterns.md](frontend-patterns.md)** - Complete frontend page templates
- **[best-practices.md](best-practices.md)** - Best practices, anti-patterns, debugging

Read these files only when actively writing that type of code or debugging issues.

## Related Skills

- **[databricks-app-python](../databricks-app-python/SKILL.md)** - for Streamlit, Dash, Gradio, or Flask apps
- **[databricks-bundles](../databricks-bundles/SKILL.md)** - deploying APX apps via DABs
- **[databricks-python-sdk](../databricks-python-sdk/SKILL.md)** - backend SDK integration
- **[databricks-lakebase-provisioned](../databricks-lakebase-provisioned/SKILL.md)** - adding persistent PostgreSQL state to apps
