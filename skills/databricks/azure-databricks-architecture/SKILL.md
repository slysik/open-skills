---
name: azure-databricks-architecture
description: "Azure-specific Databricks architecture for customer design sessions, PoCs and production hardening: control/compute plane, VNet injection, secure cluster connectivity, front-end/back-end Private Link, hub-spoke, serverless NCC and egress control, storage firewall, Entra ID identity (AIM/SCIM, service principals, Key Vault scopes), ADLS Gen2 with Unity Catalog access connectors, catalog-per-environment design, row filters/masks/ABAC, DR (managed and DIY), serverless vs classic limits, AI (Model Serving, AI Search, Agent Bricks, Azure OpenAI), DABs CI/CD with Azure DevOps/GitHub, cost tags, and Fabric interop. USE FOR: Azure Databricks private networking, VNet injection sizing, Private Link web-auth, access connector, metastore per region, Databricks DR, Databricks on Azure vs Fabric, regulated Databricks landing zone. DO NOT USE FOR: running CLI/SQL commands (use databricks-core, databricks-unity-catalog, databricks-jobs, databricks-bundles), AWS or GCP Databricks, or Fabric-only design (use microsoft-fabric)."
---

# Azure Databricks architecture (decision layer)

Adds the Azure layer on top of the platform-agnostic `databricks-*` skills. Facts were taken from Microsoft Learn on 2026-10-19; each reference carries `Last verified`, and anything the pages did not state is `UNVERIFIED`. For CLI/profile work load `databricks-core` first and pass `--profile` explicitly; this skill is documentation-driven and needs no live workspace.

## Pick a reference

| Need | Open |
|---|---|
| VNet injection, SCC, Private Link, firewall/UDR, serverless NCC, storage firewall, CMK, compliance profile | [references/networking-security.md](references/networking-security.md) |
| Entra sync (AIM/SCIM), service principals, tokens, Key Vault scopes, Unity Catalog design, access connectors, ABAC, system tables, OpenSharing, federation | [references/identity-uc-storage.md](references/identity-uc-storage.md) |
| DR, Photon, serverless limits, Delta tuning, jobs, AI/serving, CI/CD, cost, audit | [references/reliability-ai-ops.md](references/reliability-ai-ops.md) |
| Fabric plus Databricks together (mirrored catalog, OneLake federation, Databricks to OneLake) | [../../fabric/microsoft-fabric/references/architect/databricks-coexistence.md](../../fabric/microsoft-fabric/references/architect/databricks-coexistence.md) |
| Running a design session, PoC or review | [../../azure/csa-playbook/SKILL.md](../../azure/csa-playbook/SKILL.md) |

## Link to existing skills (do not duplicate)

| Topic | Skill |
|---|---|
| CLI, auth, profiles | `databricks-core` |
| UC grants, volumes, system tables how-to | `databricks-unity-catalog` |
| Jobs, pipelines, serverless choice | `databricks-jobs`, `databricks-pipelines`, `databricks-serverless` |
| Bundles | `databricks-bundles`, `databricks-dabs` |
| Serving, search, agents | `databricks-model-serving`, `databricks-vector-search`, `databricks-agent-bricks` |

## Decide first (the choices that are hard to undo)

1. VNet and subnet CIDRs (cannot be changed after deployment).
2. Single dedicated web-auth workspace per region for Private Link (shared by every workspace in the region).
3. Storage firewall enablement (deletes the managed-resource-group access connector).
4. One metastore per region; catalog as the isolation unit.
5. Managed DR vs rebuild-from-code (pipelines, streaming tables, serving endpoints and secrets are not replicated by managed DR).
6. Who owns row/column security when Fabric also reads the data.

## Quick talk track

"SCC and VNet injection are the baseline; Private Link is added by policy. Unity Catalog gives one place for who can read what, reached through an access connector rather than keys. We size the network once, plan DR as code plus replicated data, and decide explicitly who owns security when Fabric reads the same tables."
