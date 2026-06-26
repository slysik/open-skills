---
name: mlflow-onboarding
description: Onboards users to MLflow by determining their use case (GenAI agents/apps or traditional ML/deep learning) and guiding them through relevant quickstart tutorials and initial integration. If an experiment ID is available, it should be supplied as input to help determine the use case. Use when the user asks to get started with MLflow, set up tracking, add observability, or integrate MLflow into their project. Triggers on "get started with MLflow", "set up MLflow", "onboard to MLflow", "add MLflow to my project", "how do I use MLflow".
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# MLflow Onboarding

MLflow supports two broad use cases that require different onboarding paths:

- **GenAI applications and agents**: LLM-powered apps, chatbots, RAG pipelines, tool-calling agents. Key MLflow features include **tracing** for observability, **evaluation** with LLM judges, and **prompt management**, among others.
- **Traditional ML / deep learning models**: scikit-learn, PyTorch, TensorFlow, XGBoost, etc. Key MLflow features include **experiment tracking** (parameters, metrics, artifacts), **model logging**, and **model deployment**, among others.

Determining which use case applies is the first and most important step. The onboarding path, quickstart tutorials, and integration steps differ significantly between the two.

## Step 1: Determine the Use Case

Before recommending tutorials or integration steps, determine which use case the user is working on. Use the signals below, checking them in order. **If the signals are ambiguous or absent, you MUST ask the user directly.**

### Signal 1: Check the Codebase

Search the user's project for imports and usage patterns that indicate the use case:

**GenAI indicators** (any of these suggest GenAI):
- Imports from LLM client libraries: `openai`, `anthropic`, `google.generativeai`, `google.genai`, `langchain`, `langchain_openai`, `langgraph`, `llamaindex`, `litellm`, `autogen`, `crewai`, `dspy`
- Imports from MLflow GenAI modules: `mlflow.genai`, `mlflow.tracing`, `mlflow.openai`, `mlflow.langchain`
- Usage of chat completions, embeddings, or agent frameworks
- Prompt templates or prompt engineering code

**Traditional ML indicators** (any of these suggest ML):
- Imports from ML frameworks: `sklearn`, `torch`, `tensorflow`, `keras`, `xgboost`, `lightgbm`, `catboost`, `statsmodels`, `scipy`
- Imports from MLflow ML modules: `mlflow.sklearn`, `mlflow.pytorch`, `mlflow.tensorflow`
- Model training loops, `.fit()` calls, hyperparameter tuning code
- Dataset loading with tabular/image/time-series data

```bash
# Search for GenAI indicators
grep -rl --include='*.py' -E '(import openai|import anthropic|from langchain|from langgraph|import litellm|from mlflow\.genai|from mlflow\.tracing|mlflow\.openai|mlflow\.langchain|ChatCompletion|chat\.completions)' .

# Search for ML indicators
grep -rl --include='*.py' -E '(from sklearn|import torch|import tensorflow|import keras|import xgboost|import lightgbm|mlflow\.sklearn|mlflow\.pytorch|mlflow\.tensorflow|\.fit\()' .
```

### Signal 2: Check the Experiment Type Tag

If the codebase or project directory is the MLflow repository itself, skip to Signal 3 — the MLflow repo contains code for all use cases and does not indicate the user's intent.

If the experiment ID is known, check its `mlflow.experimentKind` tag. This tag is set by MLflow to indicate the experiment type:

```bash
mlflow experiments get --experiment-id <EXPERIMENT_ID> --output json > /tmp/exp_detail.json
jq -r '.tags["mlflow.experimentKind"] // "not set"' /tmp/exp_detail.json
```

- **`genai_development`** → GenAI use case
- **`custom_model_development`** → Traditional ML use case
- **Not set** → Proceed to Signal 3

If the experiment ID is not known, skip to Signal 3.

### Signal 3: Ask the User

If the codebase and experiment signals are inconclusive, ask directly:

> Are you building a **GenAI application** (e.g., an LLM-powered chatbot, RAG pipeline, or tool-calling agent) or a **traditional ML/deep learning model** (e.g., training a classifier, regression model, or neural network)?

**Do not guess.** The onboarding paths are different enough that starting down the wrong one wastes the user's time.

## Step 2: Recommend Quickstart Tutorials

Once the use case is determined, recommend the appropriate quickstart tutorials from the MLflow documentation. Present them to the user and ask if they'd like to follow along or jump directly to integrating MLflow into their project.

### GenAI Path

The MLflow GenAI documentation is at: https://mlflow.org/docs/latest/genai/getting-started/

Choose the most relevant tutorials based on the user's context and what they've told you. Available tutorials include:

- **Tracing Quickstart** (https://mlflow.org/docs/latest/genai/tracing/quickstart/) — Enabling automatic tracing for LLM calls. Covers starting an MLflow server, creating an experiment, enabling autologging, and viewing traces in the UI.
  - Python + OpenAI variant: https://mlflow.org/docs/latest/genai/tracing/quickstart/python-openai/
  - TypeScript + OpenAI variant: https://mlflow.org/docs/latest/genai/tracing/quickstart/typescript-openai
  - OpenTelemetry (language-agnostic) variant: also linked from the quickstart page
- **Evaluation Quickstart** (https://mlflow.org/docs/latest/genai/eval-monitor/quickstart/) — Evaluating GenAI application quality using LLM judges (scorers). Covers defining datasets, prediction functions, and built-in + custom scorers.
- **Version Tracking Quickstart** (https://mlflow.org/docs/latest/genai/version-tracking/quickstart/) — Prompt management, application versioning, and connecting tracing to versioned prompts.

If none of these match the user's needs, look up the MLflow GenAI documentation for more relevant guides.

### Traditional ML Path

The MLflow ML documentation is at: https://mlflow.org/docs/latest/ml/getting-started/

Choose the most relevant tutorials based on the user's context and what they've told you. Available tutorials include:

- **Tracking Quickstart** (https://mlflow.org/docs/latest/ml/tracking/quickstart/) — Experiment tracking with scikit-learn: autologging, manual parameter/metric/model logging, and exploring results in the MLflow UI.
- **Deep Learning Tutorial** (https://mlflow.org/docs/latest/ml/getting-started/deep-learning/) — Training a PyTorch model with MLflow logging: parameters, metrics, checkpoints, and system metrics (GPU utilization, memory).
- **Hyperparameter Tuning Tutorial** (https://mlflow.org/docs/latest/ml/getting-started/hyperparameter-tuning/) — Running hyperparameter searches with Optuna + MLflow, comparing results, and selecting the best model.

If none of these match the user's needs, look up the MLflow ML documentation for more relevant guides.


## When to load which sub-doc

| Sub-doc | Use when |
|---|---|
| [integration.md](integration.md) | **Step 3** — integrate MLflow into the user's project (autolog, decorators, tracking setup per use case). |

## Verification

After integration, verify that MLflow is capturing data correctly:

### GenAI Verification

1. Run the application and trigger at least one LLM call
2. Check for traces:
   ```bash
   mlflow traces search \
     --experiment-id <EXPERIMENT_ID> \
     --max-results 5 \
     --extract-fields 'info.trace_id,info.state,info.request_time' \
     --output json > /tmp/verify_traces.json
   jq '.traces | length' /tmp/verify_traces.json
   ```
3. If traces appear, open the MLflow UI to inspect them visually

### ML Verification

1. Run the training script
2. Check for runs:
   ```bash
   mlflow runs search \
     --experiment-id <EXPERIMENT_ID> \
     --max-results 5 \
     --output json > /tmp/verify_runs.json
   jq '.runs | length' /tmp/verify_runs.json
   ```
3. If runs appear, open the MLflow UI to inspect logged parameters, metrics, and artifacts
