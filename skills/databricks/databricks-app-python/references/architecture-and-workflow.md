# Databricks Apps — Quick Ref, Detailed Guides, Workflow, Core Architecture

> Detail moved out of the router. Router: ../SKILL.md (or SKILL.md)

## Python Framework Selection

| Framework | Best For | app.yaml Command |
|-----------|----------|------------------|
| **Dash** | Production dashboards, BI tools, complex interactivity | `["python", "app.py"]` |
| **Streamlit** | Rapid prototyping, data science apps, internal tools | `["streamlit", "run", "app.py"]` |
| **Gradio** | ML demos, model interfaces, chat UIs | `["python", "app.py"]` |
| **Flask** | Custom REST APIs, lightweight apps, webhooks | `["gunicorn", "app:app", "-w", "4", "-b", "0.0.0.0:8000"]` |
| **FastAPI** | Async APIs, auto-generated OpenAPI docs | `["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]` |
| **Reflex** | Full-stack Python apps without JavaScript | `["reflex", "run", "--env", "prod"]` |

**Default**: Recommend **Streamlit** for prototypes, **Dash** for production dashboards, **FastAPI** for APIs, **Gradio** for ML demos.

---

## Quick Reference

| Concept | Details |
|---------|---------|
| **Runtime** | Python 3.11, Ubuntu 22.04, 2 vCPU, 6 GB RAM |
| **Pre-installed** | Dash 2.18.1, Streamlit 1.38.0, Gradio 4.44.0, Flask 3.0.3, FastAPI 0.115.0 |
| **Auth (app)** | Service principal via `Config()` — auto-injected `DATABRICKS_CLIENT_ID`/`DATABRICKS_CLIENT_SECRET` |
| **Auth (user)** | `x-forwarded-access-token` header — see [1-authorization.md](1-authorization.md) |
| **Resources** | `valueFrom` in app.yaml — see [2-app-resources.md](2-app-resources.md) |
| **Cookbook** | https://apps-cookbook.dev/ |
| **Docs** | https://docs.databricks.com/aws/en/dev-tools/databricks-apps/ |

---

## Detailed Guides

**Authorization**: Use [1-authorization.md](1-authorization.md) when configuring app or user authorization — covers service principal auth, on-behalf-of user tokens, OAuth scopes, and per-framework code examples. (Keywords: OAuth, service principal, user auth, on-behalf-of, access token, scopes)

**App resources**: Use [2-app-resources.md](2-app-resources.md) when connecting your app to Databricks resources — covers SQL warehouses, Lakebase, model serving, secrets, volumes, and the `valueFrom` pattern. (Keywords: resources, valueFrom, SQL warehouse, model serving, secrets, volumes, connections)

**Frameworks**: See [3-frameworks.md](3-frameworks.md) for Databricks-specific patterns per framework — covers Dash, Streamlit, Gradio, Flask, FastAPI, and Reflex with auth integration, deployment commands, and Cookbook links. (Keywords: Dash, Streamlit, Gradio, Flask, FastAPI, Reflex, framework selection)

**Deployment**: Use [4-deployment.md](4-deployment.md) when deploying your app — covers Databricks CLI, Asset Bundles (DABs), app.yaml configuration, and post-deployment verification. (Keywords: deploy, CLI, DABs, asset bundles, app.yaml, logs)

**Lakebase**: Use [5-lakebase.md](5-lakebase.md) when using Lakebase (PostgreSQL) as your app's data layer — covers auto-injected env vars, psycopg2/asyncpg patterns, and when to choose Lakebase vs SQL warehouse. (Keywords: Lakebase, PostgreSQL, psycopg2, asyncpg, transactional, PGHOST)

**MCP tools**: Use [6-mcp-approach.md](6-mcp-approach.md) for managing app lifecycle via MCP tools — covers creating, deploying, monitoring, and deleting apps programmatically. (Keywords: MCP, create app, deploy app, app logs)

**Foundation Models**: See [examples/llm_config.py](examples/llm_config.py) for calling Databricks foundation model APIs — covers OAuth M2M auth, OpenAI-compatible client wiring, and token caching. (Keywords: foundation model, LLM, OpenAI client, chat completions)

---

## Workflow

1. Determine the task type:

   **New app from scratch?** → Use [AppKit](#appkit-preferred-for-new-apps) (`databricks apps init`). Fall back to [Python Framework Selection](#python-framework-selection) only if Python is required.
   **Setting up authorization?** → Read [1-authorization.md](1-authorization.md)
   **Connecting to data/resources?** → Read [2-app-resources.md](2-app-resources.md)
   **Using Lakebase (PostgreSQL)?** → Read [5-lakebase.md](5-lakebase.md)
   **Deploying to Databricks?** → Read [4-deployment.md](4-deployment.md)
   **Using MCP tools?** → Read [6-mcp-approach.md](6-mcp-approach.md)
   **Calling foundation model/LLM APIs?** → See [examples/llm_config.py](examples/llm_config.py)

2. Follow the instructions in the relevant guide
3. For full code examples, browse https://apps-cookbook.dev/

---

## Core Architecture

All Python Databricks apps follow this pattern:

```
app-directory/
├── app.py                 # Main application (or framework-specific name)
├── models.py              # Pydantic data models
├── backend.py             # Data access layer
├── requirements.txt       # Additional Python dependencies
├── app.yaml               # Databricks Apps configuration
└── README.md
```

### Backend Toggle Pattern

```python
import os
from databricks.sdk.core import Config

USE_MOCK = os.getenv("USE_MOCK_BACKEND", "true").lower() == "true"

if USE_MOCK:
    from backend_mock import MockBackend as Backend
else:
    from backend_real import RealBackend as Backend

backend = Backend()
```

### SQL Warehouse Connection (shared across all frameworks)

```python
from databricks.sdk.core import Config
from databricks import sql

cfg = Config()  # Auto-detects credentials from environment
conn = sql.connect(
    server_hostname=cfg.host,
    http_path=f"/sql/1.0/warehouses/{os.getenv('DATABRICKS_WAREHOUSE_ID')}",
    credentials_provider=lambda: cfg.authenticate,
)
```

### Pydantic Models

```python
from pydantic import BaseModel, Field
from datetime import datetime
from enum import Enum

class Status(str, Enum):
    ACTIVE = "active"
    PENDING = "pending"

class EntityOut(BaseModel):
    id: str
    name: str
    status: Status
    created_at: datetime

class EntityIn(BaseModel):
    name: str = Field(..., min_length=1)
    status: Status = Status.PENDING
```

---

