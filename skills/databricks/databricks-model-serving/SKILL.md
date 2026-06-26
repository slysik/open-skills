---
name: databricks-model-serving
description: "Deploy and query Databricks Model Serving endpoints. Use when (1) deploying MLflow models or AI agents to endpoints, (2) creating ChatAgent/ResponsesAgent agents, (3) integrating UC Functions or Vector Search tools, (4) querying deployed endpoints, (5) checking endpoint status. Covers classical ML models, custom pyfunc, and GenAI agents."
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# Databricks Model Serving

Deploy MLflow models and AI agents to scalable REST API endpoints.

## Quick Decision: What Are You Deploying?

| Model Type | Pattern | Reference |
|------------|---------|-----------|
| **Traditional ML** (sklearn, xgboost) | `mlflow.sklearn.autolog()` | [1-classical-ml.md](1-classical-ml.md) |
| **Custom Python model** | `mlflow.pyfunc.PythonModel` | [2-custom-pyfunc.md](2-custom-pyfunc.md) |
| **GenAI Agent** (LangGraph, tool-calling) | `ResponsesAgent` | [3-genai-agents.md](3-genai-agents.md) |

## Prerequisites

- **DBR 16.1+** recommended (pre-installed GenAI packages)
- Unity Catalog enabled workspace
- Model Serving enabled

## Reference Files

| Topic | File | When to Read |
|-------|------|--------------|
| **Quickstarts** | [0-quickstarts.md](0-quickstarts.md) | Foundation Model APIs, deploy agent/classical, query endpoints, common workflows, optional MCP tools |
| Classical ML | [1-classical-ml.md](1-classical-ml.md) | sklearn, xgboost, autolog |
| Custom PyFunc | [2-custom-pyfunc.md](2-custom-pyfunc.md) | Custom preprocessing, signatures |
| GenAI Agents | [3-genai-agents.md](3-genai-agents.md) | ResponsesAgent, LangGraph |
| Tools Integration | [4-tools-integration.md](4-tools-integration.md) | UC Functions, Vector Search |
| Development & Testing | [5-development-testing.md](5-development-testing.md) | MCP workflow, iteration |
| Logging & Registration | [6-logging-registration.md](6-logging-registration.md) | mlflow.pyfunc.log_model |
| Deployment | [7-deployment.md](7-deployment.md) | Job-based async deployment |
| Querying Endpoints | [8-querying-endpoints.md](8-querying-endpoints.md) | SDK, REST, MCP tools |
| Package Requirements | [9-package-requirements.md](9-package-requirements.md) | DBR versions, pip |

## Common Issues

| Issue | Solution |
|-------|----------|
| **Invalid output format** | Use `self.create_text_output_item(text, id)` - NOT raw dicts! |
| **Endpoint NOT_READY** | Deployment takes ~15 min. Use `manage_serving_endpoint(action="get")` to poll. |
| **Package not found** | Specify exact versions in `pip_requirements` when logging model |
| **Tool timeout** | Use job-based deployment, not synchronous calls |
| **Auth error on endpoint** | Ensure `resources` specified in `log_model` for auto passthrough |
| **Model not found** | Check Unity Catalog path: `catalog.schema.model_name` |

### Critical: ResponsesAgent Output Format

**WRONG** - raw dicts don't work:
```python
return ResponsesAgentResponse(output=[{"role": "assistant", "content": "..."}])
```

**CORRECT** - use helper methods:
```python
return ResponsesAgentResponse(
    output=[self.create_text_output_item(text="...", id="msg_1")]
)
```

Available helper methods:
- `self.create_text_output_item(text, id)` - text responses
- `self.create_function_call_item(id, call_id, name, arguments)` - tool calls
- `self.create_function_call_output_item(call_id, output)` - tool results

---

## Related Skills

- **[databricks-agent-bricks](../databricks-agent-bricks/SKILL.md)** - Pre-built agent tiles that deploy to model-serving endpoints
- **[databricks-vector-search](../databricks-vector-search/SKILL.md)** - Create vector indexes used as retriever tools in agents
- **[databricks-genie](../databricks-genie/SKILL.md)** - Genie Spaces can serve as agents in multi-agent setups
- **[databricks-mlflow-evaluation](../databricks-mlflow-evaluation/SKILL.md)** - Evaluate model and agent quality before deployment
- **[databricks-jobs](../databricks-jobs/SKILL.md)** - Job-based async deployment used for agent endpoints

## Resources

- [Model Serving Documentation](https://docs.databricks.com/machine-learning/model-serving/)
- [MLflow 3 ResponsesAgent](https://mlflow.org/docs/latest/llms/responses-agent-intro/)
- [Agent Framework](https://docs.databricks.com/generative-ai/agent-framework/)
