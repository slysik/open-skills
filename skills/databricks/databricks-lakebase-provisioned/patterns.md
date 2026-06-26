# Lakebase Provisioned — Connection & Usage Patterns

> OAuth tokens, psycopg3 connect, token refresh, env vars, UC registration, model logging, optional MCP tools. Router: SKILL.md

## Common Patterns

### Generate OAuth Token

```python
from databricks.sdk import WorkspaceClient
import uuid

w = WorkspaceClient()

# Generate OAuth token for database connection
cred = w.database.generate_database_credential(
    request_id=str(uuid.uuid4()),
    instance_names=["my-lakebase-instance"]
)
token = cred.token  # Use this as password in connection string
```

### Connect from Notebook

```python
import psycopg
from databricks.sdk import WorkspaceClient
import uuid

# Get instance details
w = WorkspaceClient()
instance = w.database.get_database_instance(name="my-lakebase-instance")

# Generate token
cred = w.database.generate_database_credential(
    request_id=str(uuid.uuid4()),
    instance_names=["my-lakebase-instance"]
)

# Connect using psycopg3
conn_string = f"host={instance.read_write_dns} dbname=postgres user={w.current_user.me().user_name} password={cred.token} sslmode=require"
with psycopg.connect(conn_string) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT version()")
        print(cur.fetchone())
```

### SQLAlchemy with Token Refresh (Production)

For long-running applications, tokens must be refreshed (expire after 1 hour):

```python
import asyncio
import os
import uuid
from sqlalchemy import event
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker
from databricks.sdk import WorkspaceClient

# Token refresh state
_current_token = None
_token_refresh_task = None
TOKEN_REFRESH_INTERVAL = 50 * 60  # 50 minutes (before 1-hour expiry)

def _generate_token(instance_name: str) -> str:
    """Generate fresh OAuth token."""
    w = WorkspaceClient()
    cred = w.database.generate_database_credential(
        request_id=str(uuid.uuid4()),
        instance_names=[instance_name]
    )
    return cred.token

async def _token_refresh_loop(instance_name: str):
    """Background task to refresh token every 50 minutes."""
    global _current_token
    while True:
        await asyncio.sleep(TOKEN_REFRESH_INTERVAL)
        _current_token = await asyncio.to_thread(_generate_token, instance_name)

def init_database(instance_name: str, database_name: str, username: str) -> AsyncEngine:
    """Initialize database with OAuth token injection."""
    global _current_token
    
    w = WorkspaceClient()
    instance = w.database.get_database_instance(name=instance_name)
    
    # Generate initial token
    _current_token = _generate_token(instance_name)
    
    # Build URL (password injected via do_connect)
    url = f"postgresql+psycopg://{username}@{instance.read_write_dns}:5432/{database_name}"
    
    engine = create_async_engine(
        url,
        pool_size=5,
        max_overflow=10,
        pool_recycle=3600,
        connect_args={"sslmode": "require"}
    )
    
    # Inject token on each connection
    @event.listens_for(engine.sync_engine, "do_connect")
    def provide_token(dialect, conn_rec, cargs, cparams):
        cparams["password"] = _current_token
    
    return engine
```

### Databricks Apps Integration

For Databricks Apps, use environment variables for configuration:

```python
# Environment variables set by Databricks Apps:
# - LAKEBASE_INSTANCE_NAME: Instance name
# - LAKEBASE_DATABASE_NAME: Database name
# - LAKEBASE_USERNAME: Username (optional, defaults to service principal)

import os

def is_lakebase_configured() -> bool:
    """Check if Lakebase is configured for this app."""
    return bool(
        os.environ.get("LAKEBASE_PG_URL") or
        (os.environ.get("LAKEBASE_INSTANCE_NAME") and 
         os.environ.get("LAKEBASE_DATABASE_NAME"))
    )
```

Add Lakebase as an app resource via CLI:

```bash
databricks apps add-resource $APP_NAME \
    --resource-type database \
    --resource-name lakebase \
    --database-instance my-lakebase-instance
```

### Register with Unity Catalog

```python
from databricks.sdk import WorkspaceClient

w = WorkspaceClient()

# Register database in Unity Catalog
w.database.register_database_instance(
    name="my-lakebase-instance",
    catalog="my_catalog",
    schema="my_schema"
)
```

### MLflow Model Resources

Declare Lakebase as a model resource for automatic credential provisioning:

```python
from mlflow.models.resources import DatabricksLakebase

resources = [
    DatabricksLakebase(database_instance_name="my-lakebase-instance"),
]

# When logging model
mlflow.langchain.log_model(
    model,
    artifact_path="model",
    resources=resources,
    pip_requirements=["databricks-langchain[memory]"]
)
```

## MCP Tools

The following MCP tools are available for managing Lakebase infrastructure. Use `type="provisioned"` for Lakebase Provisioned.

### manage_lakebase_database - Database Management

| Action | Description | Required Params |
|--------|-------------|-----------------|
| `create_or_update` | Create or update a database | name |
| `get` | Get database details | name |
| `list` | List all databases | (none, optional type filter) |
| `delete` | Delete database and resources | name |

**Example usage:**
```python
# Create a provisioned database
manage_lakebase_database(
    action="create_or_update",
    name="my-lakebase-instance",
    type="provisioned",
    capacity="CU_1"
)

# Get database details
manage_lakebase_database(action="get", name="my-lakebase-instance", type="provisioned")

# List all databases
manage_lakebase_database(action="list")

# Delete with cascade
manage_lakebase_database(action="delete", name="my-lakebase-instance", type="provisioned", force=True)
```

### manage_lakebase_sync - Reverse ETL

| Action | Description | Required Params |
|--------|-------------|-----------------|
| `create_or_update` | Set up reverse ETL from Delta to Lakebase | instance_name, source_table_name, target_table_name |
| `delete` | Remove synced table (and optionally catalog) | table_name |

**Example usage:**
```python
# Set up reverse ETL
manage_lakebase_sync(
    action="create_or_update",
    instance_name="my-lakebase-instance",
    source_table_name="catalog.schema.delta_table",
    target_table_name="lakebase_catalog.schema.postgres_table",
    scheduling_policy="TRIGGERED"  # or SNAPSHOT, CONTINUOUS
)

# Delete synced table
manage_lakebase_sync(action="delete", table_name="lakebase_catalog.schema.postgres_table")
```

### generate_lakebase_credential - OAuth Tokens

Generate OAuth token (~1hr) for PostgreSQL connections. Use as password with `sslmode=require`.

```python
# For provisioned instances
generate_lakebase_credential(instance_names=["my-lakebase-instance"])
```

