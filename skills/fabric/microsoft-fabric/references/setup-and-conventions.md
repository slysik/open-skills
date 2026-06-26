# Fabric — Environment, Bootstrapping, Conventions, Smoke Test

> Connection/auth is in [`../auth/auth.md`](../auth/auth.md) (REST-primary). This
> doc holds environment variables, optional `fab` CLI bootstrap, naming
> conventions, and the smoke test. Load when standing up a new environment.

## Required environment

```bash
# Identity
export AZURE_TENANT_ID=...
export AZURE_CLIENT_ID=...          # service principal app (client) id
export AZURE_CLIENT_SECRET=...      # or federated credential / managed identity
export FABRIC_TENANT_ID="$AZURE_TENANT_ID"

# Targets
export FABRIC_CAPACITY_NAME=fab-cap-prod
export FABRIC_WORKSPACE_NAME=ws-data-prod
export FABRIC_LAKEHOUSE_NAME=lh_bronze
export FABRIC_REGION=eastus2          # capacity region; OneLake follows capacity

export FABRIC_API=https://api.fabric.microsoft.com/v1
```

## Bootstrapping (REST primary; `fab` optional)

```bash
# Azure CLI for capacity + Entra ID
az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID"

# Token for raw REST (the primary path — fab is not installed here)
export FABRIC_TOKEN=$(az account get-access-token --resource https://api.fabric.microsoft.com --query accessToken -o tsv)
curl -s -H "Authorization: Bearer $FABRIC_TOKEN" "$FABRIC_API/workspaces" | jq '.value[] | {id, displayName}'

# Optional convenience CLI
pip install ms-fabric-cli
fab auth login --service-principal --tenant "$AZURE_TENANT_ID" --client-id "$AZURE_CLIENT_ID" --client-secret "$AZURE_CLIENT_SECRET"
fab config set encryption_fallback_enabled true   # headless keyring fallback
```

## Defaults & conventions

- **One capacity per environment** (`fab-cap-{dev,test,prod}`); workspaces named
  `ws-<domain>-<env>`. Never share a prod capacity with dev — throttling cascades.
- **Medallion** in OneLake: `lh_bronze/silver/gold` (or schema-per-layer). Pick one per workspace.
- **Pipeline names**: `pl_<source>_to_<sink>_<freq>`; orchestrators `pl_master_<domain>`.
- **Parameters over hardcoding**: every pipeline takes ≥ `pRunDate`, `pSourceSystem`,
  `pEnvironment`; source tables come from a metadata control table, not per-pipeline JSON.
- **Connections**: prefer workspace/managed identity; secrets in Key Vault via Fabric
  Key Vault connections — never inline in pipeline JSON.
- **Git first**: connect each workspace to a repo before building; Deployment Pipelines
  drive dev→test→prod promotion.
- **Resiliency first**: retry on every Copy, an `On Failure` logging path, idempotent loads.

## 60-second smoke test

```bash
fab ls /.capacities                                   # capacities (optional CLI)
fab ls /                                               # workspaces
fab ls "/$FABRIC_WORKSPACE_NAME.Workspace"             # items
# Raw REST equivalent (primary):
curl -s -H "Authorization: Bearer $FABRIC_TOKEN" "$FABRIC_API/workspaces" \
  | jq '.value[] | select(.displayName=="'"$FABRIC_WORKSPACE_NAME"'")'
```

If any fail → [`../auth/auth.md`](../auth/auth.md) → Troubleshoot.

## Quick recipes (CLI form; load recipes.md for full detail)

```bash
# Create workspace assigned to a capacity (REST)
CAP_ID=$(fab get /.capacities/$FABRIC_CAPACITY_NAME.Capacity -q id -o tsv)
curl -s -X POST -H "Authorization: Bearer $FABRIC_TOKEN" -H "Content-Type: application/json" \
  "$FABRIC_API/workspaces" -d "{\"displayName\":\"$FABRIC_WORKSPACE_NAME\",\"capacityId\":\"$CAP_ID\"}"

fab create "/$FABRIC_WORKSPACE_NAME.Workspace/$FABRIC_LAKEHOUSE_NAME.Lakehouse"
fab create "/$FABRIC_WORKSPACE_NAME.Workspace/pl_demo.DataPipeline" --definition ./pipelines/pl_demo.json
fab job run "/$FABRIC_WORKSPACE_NAME.Workspace/pl_demo.DataPipeline"
fab job run-status "/$FABRIC_WORKSPACE_NAME.Workspace/pl_demo.DataPipeline" --last
```
