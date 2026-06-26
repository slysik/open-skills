# MLflow Onboarding — Step 3: Integration into the project

> Detail moved out of the router. Router: SKILL.md

## Step 3: Integrate MLflow into the User's Project

After the user has reviewed the quickstart tutorials (or opted to skip them), offer to help integrate MLflow directly into their codebase. **Always ask for the user's consent before making changes to their code.**

### GenAI Integration

The core integration for GenAI apps is **tracing** — capturing LLM calls, tool invocations, and agent steps automatically.

**If asked to create an example project:** Do not assume the user has LLM API keys (e.g., OpenAI, Anthropic). Instead, create traces with mock data using `@mlflow.trace` and `mlflow.start_span()` to demonstrate tracing without requiring external API access. For example:

```python
import mlflow

mlflow.set_experiment("example-genai-app")

@mlflow.trace
def mock_chat(query: str) -> str:
    with mlflow.start_span(name="retrieve_context") as span:
        context = "Mock retrieved context for: " + query
        span.set_inputs({"query": query})
        span.set_outputs({"context": context})
    with mlflow.start_span(name="generate_response") as span:
        response = "Mock response based on: " + context
        span.set_inputs({"context": context, "query": query})
        span.set_outputs({"response": response})
    return response

mock_chat("What is MLflow?")
```

**What to set up (for an existing project):**

1. **Autologging** — If the user's code uses a supported framework, a single line automatically traces all calls to their LLM provider. See https://mlflow.org/docs/latest/genai/tracing/ for the full list of supported providers. If the provider is supported:

   ```python
   import mlflow

   # Pick the one that matches the user's LLM provider:
   mlflow.openai.autolog()       # OpenAI SDK
   mlflow.anthropic.autolog()    # Anthropic SDK
   mlflow.gemini.autolog()       # Google Gemini (google-genai SDK)
   mlflow.langchain.autolog()    # LangChain / LangGraph
   mlflow.litellm.autolog()      # LiteLLM
   ```

   Add this call once at application startup (e.g., top of `main.py`, `app.py`, or the entry point module). It must execute before any LLM calls are made.

   If the provider is **not** supported by autologging, skip to step 3 (Custom tracing) and use `@mlflow.trace` to manually instrument the relevant functions.

2. **Experiment configuration** — Set the experiment so traces are organized:

   ```python
   mlflow.set_experiment("my-genai-app")
   ```

   Or via environment variable: `export MLFLOW_EXPERIMENT_NAME="my-genai-app"`

3. **Custom tracing** (optional) — For functions that aren't automatically traced (custom tools, business logic), use the `@mlflow.trace` decorator:

   ```python
   @mlflow.trace
   def my_custom_tool(query: str) -> str:
       # ... tool logic ...
       return result
   ```

**Where to add it:** Find the application's entry point or initialization module and add the autologging call there. Search for the main LLM client instantiation (e.g., `openai.OpenAI()`, `ChatOpenAI()`) to find the right location.

### Traditional ML Integration

The core integration for ML is **experiment tracking** — capturing parameters, metrics, and models from training runs.

**What to set up:**

1. **Autologging** — If the user's code uses a supported framework, a single line automatically logs parameters, metrics, and models during training. See https://mlflow.org/docs/latest/ml/ for the full list of supported frameworks. If the framework is supported:

   ```python
   import mlflow

   # Pick the one that matches the user's ML framework:
   mlflow.sklearn.autolog()      # scikit-learn
   mlflow.pytorch.autolog()      # PyTorch / PyTorch Lightning
   mlflow.tensorflow.autolog()   # TensorFlow / Keras
   mlflow.xgboost.autolog()      # XGBoost
   mlflow.lightgbm.autolog()     # LightGBM
   ```

   Add this call once before training starts. It automatically captures `model.fit()` calls, logged metrics, and model artifacts.

   If the framework is **not** supported by autologging, skip to step 3 (Manual logging) and use `mlflow.log_param()`, `mlflow.log_metric()`, and `mlflow.log_artifact()` to log data explicitly.

2. **Experiment configuration** — Set the experiment so runs are organized:

   ```python
   mlflow.set_experiment("my-ml-experiment")
   ```

   Or via environment variable: `export MLFLOW_EXPERIMENT_NAME="my-ml-experiment"`

3. **Manual logging** (optional) — For metrics or parameters not captured by autologging:

   ```python
   with mlflow.start_run():
       mlflow.log_param("custom_param", value)
       mlflow.log_metric("custom_metric", value)
   ```

**Where to add it:** Find the training script or module where `model.fit()` (or equivalent) is called. Add the autologging call before the training loop begins.

