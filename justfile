set shell := ["bash", "-uc"]

repo := "https://raw.githubusercontent.com/slysik/open-skills/main/install.sh"

default:
    @just --list

# Install from the local checkout. Pass any install.sh flags after the recipe.
install *args:
    @bash install.sh --local {{args}}

# Install from GitHub without cloning the repo.
install-remote *args:
    @curl -fsSL {{repo}} | bash -s -- {{args}}

# Show available platforms and skills.
list:
    @bash install.sh --local --list

# Install all skills into Codex.
install-codex:
    @bash install.sh --local --harness codex

# Install one platform into a target harness, defaulting to Codex.
install-platform platform harness="codex":
    @bash install.sh --local --harness {{harness}} --platform {{platform}}

# Install Databricks AI skills into a target harness, defaulting to Codex.
install-databricks-ai harness="codex":
    @bash install.sh --local --harness {{harness}} databricks-ai

# Install Snowflake AI skills into a target harness, defaulting to Codex.
install-snowflake-ai harness="codex":
    @bash install.sh --local --harness {{harness}} snowflake-ai

# Install Microsoft AI skills (Fabric + Foundry) into a target harness, defaulting to Codex.
install-microsoft-ai harness="codex":
    @bash install.sh --local --harness {{harness}} microsoft-ai

# Install only Snowflake skills into a target harness, defaulting to Codex.
install-snowflake harness="codex":
    @bash install.sh --local --harness {{harness}} --platform snowflake

# Install only Microsoft Foundry skills into a target harness, defaulting to Codex.
install-foundry harness="codex":
    @bash install.sh --local --harness {{harness}} --platform foundry

# Rebuild generated catalog artifacts.
catalog:
    @scripts/build_catalog.py --write

# Validate skill metadata, router links, and generated catalog artifacts.
validate:
    @scripts/validate_skills.py

# Regenerate catalog artifacts and validate.
check:
    @scripts/build_catalog.py --write
    @scripts/validate_skills.py

# Capture a reusable learning as a local JSONL candidate.
learn skill summary:
    @scripts/log_skill_learning.py --skill "{{skill}}" --summary "{{summary}}"

# Dry-run promotion of approved learning candidates.
promote:
    @scripts/promote_skill_learnings.py

# Generate the deterministic seven-table customer-support smoke dataset.
smoke-data:
    @python3 examples/customer-support-ai/data/generate.py

# Run the Databricks CLI smoke test. Pass --dry-run to avoid cloud execution.
smoke-databricks *args:
    @scripts/smoke_databricks_customer_support.sh {{args}}

# Run the Snowflake CLI smoke test. Pass --dry-run to avoid cloud execution.
smoke-snowflake *args:
    @scripts/smoke_snowflake_customer_support.sh {{args}}

# Run the Fabric + Foundry CLI/API smoke test. Pass --dry-run to avoid cloud execution.
smoke-microsoft *args:
    @scripts/smoke_microsoft_customer_support.sh {{args}}

# Render the cost, token, performance, and feature-gap comparison.
smoke-report:
    @scripts/compare_customer_support_smoke.py

# Validate all three command paths locally without creating billable resources.
smoke-dry-run:
    @scripts/smoke_databricks_customer_support.sh --dry-run
    @scripts/smoke_snowflake_customer_support.sh --dry-run
    @scripts/smoke_microsoft_customer_support.sh --dry-run
    @scripts/compare_customer_support_smoke.py
