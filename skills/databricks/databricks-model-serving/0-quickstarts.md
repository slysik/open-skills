# Model Serving — Quickstarts (Foundation Model APIs, agent + classical deploy, querying, workflows)

> Inline quickstarts moved out of the router; deeper detail in the numbered refs. Router: SKILL.md

## Foundation Model API Endpoints

ALWAYS use exact endpoint names from this table. NEVER guess or abbreviate.

### Chat / Instruct Models

| Endpoint Name | Provider | Notes |
|--------------|----------|-------|
| `databricks-gpt-5-2` | OpenAI | Latest GPT, 400K context |
| `databricks-gpt-5-1` | OpenAI | Instant + Thinking modes |
| `databricks-gpt-5-1-codex-max` | OpenAI | Code-specialized (high perf) |
| `databricks-gpt-5-1-codex-mini` | OpenAI | Code-specialized (cost-opt) |
| `databricks-gpt-5` | OpenAI | 400K context, reasoning |
| `databricks-gpt-5-mini` | OpenAI | Cost-optimized reasoning |
| `databricks-gpt-5-nano` | OpenAI | High-throughput, lightweight |
| `databricks-gpt-oss-120b` | OpenAI | Open-weight, 128K context |
| `databricks-gpt-oss-20b` | OpenAI | Lightweight open-weight |
| `databricks-claude-opus-4-6` | Anthropic | Most capable, 1M context |
| `databricks-claude-sonnet-4-6` | Anthropic | Hybrid reasoning |
| `databricks-claude-sonnet-4-5` | Anthropic | Hybrid reasoning |
| `databricks-claude-opus-4-5` | Anthropic | Deep analysis, 200K context |
| `databricks-claude-sonnet-4` | Anthropic | Hybrid reasoning |
| `databricks-claude-opus-4-1` | Anthropic | 200K context, 32K output |
| `databricks-claude-haiku-4-5` | Anthropic | Fastest, cost-effective |
| `databricks-claude-3-7-sonnet` | Anthropic | Retiring April 2026 |
| `databricks-meta-llama-3-3-70b-instruct` | Meta | 128K context, multilingual |
| `databricks-meta-llama-3-1-405b-instruct` | Meta | Retiring May 2026 (PT) |
| `databricks-meta-llama-3-1-8b-instruct` | Meta | Lightweight, 128K context |
| `databricks-llama-4-maverick` | Meta | MoE architecture |
| `databricks-gemini-3-1-pro` | Google | 1M context, hybrid reasoning |
| `databricks-gemini-3-pro` | Google | 1M context, hybrid reasoning |
| `databricks-gemini-3-flash` | Google | Fast, cost-efficient |
| `databricks-gemini-2-5-pro` | Google | 1M context, Deep Think |
| `databricks-gemini-2-5-flash` | Google | 1M context, hybrid reasoning |
| `databricks-gemma-3-12b` | Google | 128K context, multilingual |
| `databricks-qwen3-next-80b-a3b-instruct` | Alibaba | Efficient MoE |

### Embedding Models

| Endpoint Name | Dimensions | Max Tokens | Notes |
|--------------|-----------|------------|-------|
| `databricks-gte-large-en` | 1024 | 8192 | English, not normalized |
| `databricks-bge-large-en` | 1024 | 512 | English, normalized |
| `databricks-qwen3-embedding-0-6b` | up to 1024 | ~32K | 100+ languages, instruction-aware |

### Common Defaults

- **Agent LLM**: `databricks-meta-llama-3-3-70b-instruct` (good balance of quality/cost)
- **Embedding**: `databricks-gte-large-en`
- **Code tasks**: `databricks-gpt-5-1-codex-mini` or `databricks-gpt-5-1-codex-max`

> These are pay-per-token endpoints available in every workspace. For production, consider provisioned throughput mode. See [supported models](https://docs.databricks.com/aws/en/machine-learning/foundation-model-apis/supported-models).


## Quick Start: Deploy a GenAI Agent

### Step 1: Install Packages (in notebook or via MCP)

```python
%pip install -U mlflow==3.6.0 databricks-langchain langgraph==0.3.4 databricks-agents pydantic
dbutils.library.restartPython()
```

Or via MCP:
```
execute_code(code="%pip install -U mlflow==3.6.0 databricks-langchain langgraph==0.3.4 databricks-agents pydantic")
```

### Step 2: Create Agent File

Create `agent.py` locally with `ResponsesAgent` pattern (see [3-genai-agents.md](3-genai-agents.md)).

### Step 3: Upload to Workspace

```
manage_workspace_files(
    action="upload",
    local_path="./my_agent",
    workspace_path="/Workspace/Users/you@company.com/my_agent"
)
```

### Step 4: Test Agent

```
execute_code(
    file_path="./my_agent/test_agent.py",
    cluster_id="<cluster_id>"
)
```

### Step 5: Log Model

```
execute_code(
    file_path="./my_agent/log_model.py",
    cluster_id="<cluster_id>"
)
```

### Step 6: Deploy (Async via Job)

See [7-deployment.md](7-deployment.md) for job-based deployment that doesn't timeout.

### Step 7: Query Endpoint

```
manage_serving_endpoint(
    action="query",
    name="my-agent-endpoint",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

---

## Quick Start: Deploy a Classical ML Model

```python
import mlflow
import mlflow.sklearn
from sklearn.linear_model import LogisticRegression

# Enable autolog with auto-registration
mlflow.sklearn.autolog(
    log_input_examples=True,
    registered_model_name="main.models.my_classifier"
)

# Train - model is logged and registered automatically
model = LogisticRegression()
model.fit(X_train, y_train)
```

Then deploy via UI or SDK. See [1-classical-ml.md](1-classical-ml.md).

---

## MCP Tools

> **If MCP tools are not available**, use the SDK/CLI examples in the reference files below.

### Development & Testing

| Tool | Purpose |
|------|---------|
| `manage_workspace_files` (action="upload") | Upload agent files to workspace |
| `execute_code` | Install packages, test agent, log model |

### Deployment

| Tool | Purpose |
|------|---------|
| `manage_jobs` (action="create") | Create deployment job (one-time) |
| `manage_job_runs` (action="run_now") | Kick off deployment (async) |
| `manage_job_runs` (action="get") | Check deployment job status |

### manage_serving_endpoint - Querying

| Action | Description | Required Params |
|--------|-------------|-----------------|
| `get` | Check endpoint status (READY/NOT_READY/NOT_FOUND) | name |
| `list` | List all endpoints | (none, optional limit) |
| `query` | Send requests to endpoint | name + one of: messages, inputs, dataframe_records |

**Example usage:**
```python
# Check endpoint status
manage_serving_endpoint(action="get", name="my-agent-endpoint")

# List all endpoints
manage_serving_endpoint(action="list")

# Query a chat/agent endpoint
manage_serving_endpoint(
    action="query",
    name="my-agent-endpoint",
    messages=[{"role": "user", "content": "Hello!"}],
    max_tokens=500
)

# Query a traditional ML endpoint
manage_serving_endpoint(
    action="query",
    name="sklearn-classifier",
    dataframe_records=[{"age": 25, "income": 50000, "credit_score": 720}]
)
```

---

## Common Workflows

### Check Endpoint Status After Deployment

```
manage_serving_endpoint(action="get", name="my-agent-endpoint")
```

Returns:
```json
{
    "name": "my-agent-endpoint",
    "state": "READY",
    "served_entities": [...]
}
```

### Query a Chat/Agent Endpoint

```
manage_serving_endpoint(
    action="query",
    name="my-agent-endpoint",
    messages=[
        {"role": "user", "content": "What is Databricks?"}
    ],
    max_tokens=500
)
```

### Query a Traditional ML Endpoint

```
manage_serving_endpoint(
    action="query",
    name="sklearn-classifier",
    dataframe_records=[
        {"age": 25, "income": 50000, "credit_score": 720}
    ]
)
```

---

