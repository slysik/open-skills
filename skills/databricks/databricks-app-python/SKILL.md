---
name: databricks-app-python
description: "Builds Databricks applications. Prefers AppKit (TypeScript + React SDK) for new apps; falls back to Python frameworks (Dash, Streamlit, Gradio, Flask, FastAPI, Reflex) when Python is required. Handles OAuth authorization, app resources, SQL warehouse and Lakebase connectivity, model serving, foundation model APIs, and deployment. Use when building web apps, dashboards, ML demos, or REST APIs for Databricks, or when the user mentions AppKit, Streamlit, Dash, Gradio, Flask, FastAPI, Reflex, or Databricks app."
---

# Databricks Applications

Build Python-based Databricks applications. For full examples and recipes, see the **[Databricks Apps Cookbook](https://apps-cookbook.dev/)**.

---

## AppKit (Preferred for New Apps)

**[AppKit](https://github.com/databricks/appkit)** is the recommended SDK for new Databricks apps. It is a TypeScript + React SDK with a plugin architecture, built-in caching, telemetry, and end-to-end type safety.

### Requirements
- Node.js v22+
- Databricks CLI v0.295.0+

### Scaffold a new app
```bash
databricks apps init
```
This interactive command scaffolds the full project, installs dependencies, and optionally deploys.

### Deploy
```bash
databricks apps deploy
```

### AppKit plugins
| Plugin | Purpose |
|--------|---------|
| **Analytics** | SQL queries against Databricks SQL Warehouses — file-based, typed, cached |
| **Genie** | Conversational AI/BI interface with natural language queries |
| **Files** | Browse/upload Unity Catalog Volumes |
| **Lakebase** | OLTP PostgreSQL via Lakebase with OAuth token management |

### AI-assisted development
```bash
# Install agent skills for AI-powered scaffolding
databricks experimental aitools skills install

# Query AppKit docs inline
npx @databricks/appkit docs "your question here"
```

### AppKit documentation
- **[AppKit Docs](https://databricks.github.io/appkit/docs/)** — getting started, plugins, API reference
- **[AI-assisted development](https://databricks.github.io/appkit/docs/development/ai-assisted-development)** — guidance for code assistants
- **[llms.txt](https://databricks.github.io/appkit/llms.txt)** — machine-readable docs for AI context

---

## Python Apps (alternative)

Use Python when: the team is Python-only, you need Streamlit/Dash/Gradio/Gradio, or you are extending an existing Python app.

## Critical Rules for Python apps (always follow)

- **MUST** confirm framework choice or use [Python Framework Selection](#python-framework-selection) below
- **MUST** use SDK `Config()` for authentication (never hardcode tokens)
- **MUST** use `app.yaml` `valueFrom` for resources (never hardcode resource IDs)
- **MUST** use `dash-bootstrap-components` for Dash app layout and styling
- **MUST** use `@st.cache_resource` for Streamlit database connections
- **MUST** deploy Flask with Gunicorn, FastAPI with uvicorn (not dev servers)

## Required Steps for Python apps

Copy this checklist and verify each item:
```
- [ ] Framework selected
- [ ] Auth strategy decided: app auth, user auth, or both
- [ ] App resources identified (SQL warehouse, Lakebase, serving endpoint, etc.)
- [ ] Backend data strategy decided (SQL warehouse, Lakebase, or SDK)
- [ ] Deployment method: CLI or DABs
```

---


## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [references/architecture-and-workflow.md](references/architecture-and-workflow.md) | Databricks Apps — Quick Ref, Detailed Guides, Workflow, Core Architecture |

## Common Issues

| Issue | Solution |
|-------|----------|
| **Connection exhausted** | Use `@st.cache_resource` (Streamlit) or connection pooling |
| **Auth token not found** | Check `x-forwarded-access-token` header — only available when deployed, not locally |
| **App won't start** | Check `app.yaml` command matches framework; check `databricks apps logs <name>` |
| **Resource not accessible** | Add resource via UI, verify SP has permissions, use `valueFrom` in app.yaml |
| **Import error on deploy** | Add missing packages to `requirements.txt` (pre-installed packages don't need listing) |
| **Lakebase app crashes on start** | `psycopg2`/`asyncpg` are NOT pre-installed — MUST add to `requirements.txt` |
| **Port conflict** | Apps must bind to `DATABRICKS_APP_PORT` env var (defaults to 8000). Never use 8080. Streamlit is auto-configured; for others, read the env var in code or use 8000 in app.yaml command |
| **Streamlit: set_page_config error** | `st.set_page_config()` must be the first Streamlit command |
| **Dash: unstyled layout** | Add `dash-bootstrap-components`; use `dbc.themes.BOOTSTRAP` |
| **Slow queries** | Use Lakebase for transactional/low-latency; SQL warehouse for analytical queries |

---

## Platform Constraints

| Constraint | Details |
|------------|---------|
| **Runtime** | Python 3.11, Ubuntu 22.04 LTS |
| **Compute** | 2 vCPUs, 6 GB memory (default) |
| **Pre-installed frameworks** | Dash, Streamlit, Gradio, Flask, FastAPI, Shiny |
| **Custom packages** | Add to `requirements.txt` in app root |
| **Network** | Apps can reach Databricks APIs; external access depends on workspace config |
| **User auth** | Public Preview — workspace admin must enable before adding scopes |

---

## Official Documentation

- **[AppKit](https://databricks.github.io/appkit/docs/)** — preferred SDK for new apps (TypeScript + React)
- **[Databricks Apps Overview](https://docs.databricks.com/aws/en/dev-tools/databricks-apps/)** — main docs hub
- **[Apps Cookbook](https://apps-cookbook.dev/)** — ready-to-use code snippets (Streamlit, Dash, Reflex, FastAPI)
- **[Authorization](https://docs.databricks.com/aws/en/dev-tools/databricks-apps/auth)** — app auth and user auth
- **[Resources](https://docs.databricks.com/aws/en/dev-tools/databricks-apps/resources)** — SQL warehouse, Lakebase, serving, secrets
- **[app.yaml Reference](https://docs.databricks.com/aws/en/dev-tools/databricks-apps/app-runtime)** — command and env config
- **[System Environment](https://docs.databricks.com/aws/en/dev-tools/databricks-apps/system-env)** — pre-installed packages, runtime details

## Related Skills

- **[databricks-app-apx](../databricks-app-apx/SKILL.md)** - full-stack apps with FastAPI + React
- **[databricks-bundles](../databricks-bundles/SKILL.md)** - deploying apps via DABs
- **[databricks-python-sdk](../databricks-python-sdk/SKILL.md)** - backend SDK integration
- **[databricks-lakebase-provisioned](../databricks-lakebase-provisioned/SKILL.md)** - adding persistent PostgreSQL state
- **[databricks-model-serving](../databricks-model-serving/SKILL.md)** - serving ML models for app integration
