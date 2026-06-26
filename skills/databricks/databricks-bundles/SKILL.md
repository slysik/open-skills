---
name: databricks-bundles
description: "Create and configure Declarative Automation Bundles (formerly Asset Bundles) with best practices for multi-environment deployments (CICD). Use when working with: (1) Creating new DAB projects, (2) Adding resources (dashboards, pipelines, jobs, alerts), (3) Configuring multi-environment deployments, (4) Setting up permissions, (5) Deploying or running bundle resources"
license: MIT
metadata:
  author: slysik
  version: "0.2.0"
  updated: "2026-06-23"
---

# DABs Writer

## Overview
Create DABs for multi-environment deployment (dev/staging/prod).

## Reference Files

- **[structure-and-commands.md](structure-and-commands.md)** - Bundle structure (databricks.yml, resources, targets, variables) + common CLI commands
- **[SDP_guidance.md](SDP_guidance.md)** - Spark Declarative Pipeline configurations
- **[alerts_guidance.md](alerts_guidance.md)** - SQL Alert schemas (critical - API differs)
## Common Issues

| Issue | Solution |
|-------|----------|
| **App deployment fails** | Check logs: `databricks apps logs <app-name>` for error details |
| **App not connecting to Unity Catalog** | Check logs for backend connection errors; verify warehouse ID and permissions |
| **Wrong permission level** | Dashboards: CAN_READ/RUN/EDIT/MANAGE; Jobs: CAN_VIEW/MANAGE_RUN/MANAGE |
| **Path resolution fails** | Use `../src/` in resources/*.yml, `./src/` in databricks.yml |
| **Catalog doesn't exist** | Create catalog first or update variable |
| **"admins" group error on jobs** | Cannot modify admins permissions on jobs |
| **Volume permissions** | Use `grants` not `permissions` for volumes |
| **Hardcoded catalog in dashboard** | Use dataset_catalog parameter (CLI v0.281.0+), create environment-specific files, or parameterize JSON |
| **App not starting after deploy** | Apps require `databricks bundle run <resource_key>` to start |
| **App env vars not working** | Environment variables go in `app.yaml` (source dir), not databricks.yml |
| **Wrong app source path** | Use `../` from resources/ dir if source is in project root |
| **Debugging any app issue** | First step: `databricks apps logs <app-name>` to see what went wrong |

## Key Principles

1. **Path resolution**: `../src/` in resources/*.yml, `./src/` in databricks.yml
2. **Variables**: Parameterize catalog, schema, warehouse
3. **Mode**: `development` for dev/staging, `production` for prod
4. **Groups**: Use `"users"` for all workspace users
5. **Job permissions**: Verify custom groups exist; can't modify "admins"

## Related Skills

- **[databricks-spark-declarative-pipelines](../databricks-spark-declarative-pipelines/SKILL.md)** - pipeline definitions referenced by DABs
- **[databricks-app-apx](../databricks-app-apx/SKILL.md)** - app deployment via DABs
- **[databricks-app-python](../databricks-app-python/SKILL.md)** - Python app deployment via DABs
- **[databricks-config](../databricks-config/SKILL.md)** - profile and authentication setup for CLI/SDK
- **[databricks-jobs](../databricks-jobs/SKILL.md)** - job orchestration managed through bundles

## Resources

- [DABs Documentation](https://docs.databricks.com/dev-tools/bundles/)
- [Bundle Resources Reference](https://docs.databricks.com/dev-tools/bundles/resources)
- [Bundle Configuration Reference](https://docs.databricks.com/dev-tools/bundles/settings)
- [Supported Resource Types](https://docs.databricks.com/aws/en/dev-tools/bundles/resources#resource-types)
- [Examples Repository 1](https://github.com/databricks-solutions/databricks-dab-examples)
