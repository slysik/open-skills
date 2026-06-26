# Microsoft Fabric — CI/CD & Deployment Process

A Senior Fabric Data Engineer does not build in production or manually export
JSON. Fabric offers direct **Git integration** at the workspace level, coupled
with **Deployment Pipelines** for promoting through Dev, Test, and Prod.

This doc covers the setup, promotion strategy, and automation scripts.

## 1. The Fabric Git Serialization Model

When a Fabric workspace is connected to Git (Azure DevOps or GitHub), Fabric
serializes items into a folder structure on the `main` or feature branch:

```
/ws-finance/
  ├── MyPipeline.DataPipeline/
  │     ├── item.metadata.json
  │     ├── item.config.json
  │     └── pipeline-content.json   # The raw JSON definition
  ├── SilverLakehouse.Lakehouse/
  │     ├── item.metadata.json
  │     └── item.config.json
  └── GoldWarehouse.Warehouse/
        ├── item.metadata.json
        └── item.config.json
```

### Git Integration Rules:
- Only **Workspace Members** or **Admins** can sync with Git.
- Unsupported items (e.g., Power BI streaming datasets) won't show up in the Git status pane.
- Fabric uses **logical IDs** (not physical GUIDs) in its folder names to keep paths clean.

---

## 2. Setting up the Git Integration (Azure DevOps / GitHub)

### Step 1: Connect Workspace to Git (Portal)
1. In the Dev workspace → **Workspace settings** → **Git integration**.
2. Select your Organization, Project, Repository, and Branch (e.g., `feature/analytics`).
3. Set your folder path (e.g., `/ws-finance`).
4. Click **Connect and sync**.

### Step 2: The Branching Strategy
We enforce the standard **GitHub Flow** / **GitFlow** variation:

```
                       ┌── feature/orders-ingest ──▶ [PR / Code Review]
                       │                                   │
  main (tracked by Dev) ───────────────────────────────────┴─────────────────
   │
   ├─► [Azure DevOps / GitHub Actions Triggered]
   │
   ▼
  Deploy to Test workspace ──► [Integration Tests Pass] ──► Deploy to Prod
```

1. **Dev workspace** is pinned to the `main` branch.
2. Engineers create a feature branch (`feature/<name>`) from their local machine or Git portal.
3. To work, an engineer connects **their own personal trial workspace** (`ws-slysik-dev`) to that feature branch to build and test.
4. When done, they submit a **Pull Request (PR)** to `main`.
5. Merging to `main` auto-syncs the Shared Dev workspace.

---

## 3. Fabric Deployment Pipelines (The Low-Code Path)

Fabric's native **Deployment Pipelines** are the cleanest way to promote changes
across environments. They are multi-stage workflows (Dev → Test → Prod) managed in the portal.

```
       Dev Workspace                Test Workspace                Prod Workspace
     ┌──────────────┐             ┌──────────────┐             ┌──────────────┐
     │  ws-data-dev │ ──Deploy──▶ │ ws-data-test │ ──Deploy──▶ │ ws-data-prod │
     └──────────────┘             └──────────────┘             └──────────────┘
            │                            │                            │
      Tracked Git:                  No Git Sync                  No Git Sync
      main branch                     Needed                       Needed
```

### 3.1 Creating a Deployment Pipeline via `fab` CLI

```bash
# Create a pipeline with three stages linked to our workspaces
fab create "/dp-analytics.DeploymentPipeline" \
  --definition '{
    "stages": [
      { "displayName": "Development", "workspaceId": "dev-ws-guid" },
      { "displayName": "Testing",     "workspaceId": "test-ws-guid" },
      { "displayName": "Production",  "workspaceId": "prod-ws-guid" }
    ]
  }'
```

### 3.2 Deployment Rules (The Secret to No-Code Rewriting)
When you promote a pipeline from Dev to Test, you must rewrite **Connection IDs**
and **Parameters** (e.g., Pointing from Dev SQL Server to Prod SQL Server).

Configure these **Deployment Rules** in the target stage (Test or Prod) via the Fabric portal:

1. In the Deployment Pipeline, select the **Testing** stage → click **Deployment rules**.
2. **Parameters Rule**: 
   - Rule type: *Parameter*
   - Target parameter: `pEnvironment`
   - Value: `test` (overwrites the `dev` default)
3. **Connection Rule**:
   - Rule type: *Connection*
   - Target connection: `conn-sql-dev`
   - Replaced by: `conn-sql-test` (a pre-configured Test connection with Test credentials)

Now, promoting the pipeline **automatically applies these rewrites**. The underlying pipeline definition remains identical, preserving the integrity of the code.

### 3.3 Executing a Promotion (CLI)

```bash
# Deploy from Dev (stage 0) to Test (stage 1)
fab deploy "/dp-analytics.DeploymentPipeline" \
  --from-stage 0 \
  --to-stage 1 \
  --note "Deploying March sprint incremental changes"
```

---

## 4. Automated CI/CD (The Code-Only Path)

If your organization prefers complete control using **GitHub Actions** or **Azure DevOps Pipelines** without the low-code Deployment Pipelines UI, use the Fabric REST API directly to perform deployments.

### GitHub Actions Workflow: `deploy-fabric.yml`

This workflow runs when a PR is merged into `main`. It packages the pipeline JSON from the repository, logins using an Entra ID Service Principal, and updates the Test and Prod workspaces using raw REST calls.

```yaml
name: Deploy Fabric Workloads

on:
  push:
    branches: [ main ]
    paths:
      - 'ws-finance/**'

jobs:
  deploy:
    runs-on: ubuntu-latest
    env:
      AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
      TEST_WS_ID: "test-workspace-guid-from-kv"
      PROD_WS_ID: "prod-workspace-guid-from-kv"

    steps:
    - name: Checkout Code
      uses: actions/checkout@v3

    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'

    - name: Install dependencies
      run: |
        pip install ms-fabric-cli
        sudo apt-get install jq -y

    - name: Authenticate with Fabric CLI
      run: |
        fab auth login --service-principal \
          --tenant "$AZURE_TENANT_ID" \
          --client-id "$AZURE_CLIENT_ID" \
          --client-secret "$AZURE_CLIENT_SECRET"

    - name: Fetch Azure Access Token
      id: get_token
      run: |
        # Fetch token directly for REST API calls
        TOKEN=$(curl -s -X POST -H "Content-Type: application/x-www-form-urlencoded" \
          "https://login.microsoftonline.com/$AZURE_TENANT_ID/oauth2/v2.0/token" \
          -d "grant_type=client_credentials" \
          -d "client_id=$AZURE_CLIENT_ID" \
          -d "client_secret=$AZURE_CLIENT_SECRET" \
          -d "scope=https://api.fabric.microsoft.com/.default" | jq -r '.access_token')
        echo "FABRIC_TOKEN=$TOKEN" >> $GITHUB_ENV

    - name: Deploy Pipelines to Test Workspace
      run: |
        # Read the pipeline content from git and update the pipeline item in Test
        # We loop through all changed pipeline directories
        for pipeline_dir in ws-finance/*.DataPipeline; do
          if [ -d "$pipeline_dir" ]; then
            name=$(basename "$pipeline_dir" .DataPipeline)
            echo "Deploying pipeline: $name to Testing Workspace"
            
            # Base64 encode the content
            payload_b64=$(base64 -w0 "$pipeline_dir/pipeline-content.json")
            
            # Get the item ID in the Test workspace
            item_id=$(curl -s -H "Authorization: Bearer $FABRIC_TOKEN" \
              "https://api.fabric.microsoft.com/v1/workspaces/$TEST_WS_ID/items" \
              | jq -r --arg n "$name" '.value[] | select(.displayName==$n) | .id')
              
            if [ -z "$item_id" ]; then
              echo "Creating new pipeline: $name"
              curl -s -X POST -H "Authorization: Bearer $FABRIC_TOKEN" \
                -H "Content-Type: application/json" \
                "https://api.fabric.microsoft.com/v1/workspaces/$TEST_WS_ID/dataPipelines" \
                -d "{\"displayName\":\"$name\",\"definition\":{\"parts\":[{\"path\":\"pipeline-content.json\",\"payload\":\"$payload_b64\",\"payloadType\":\"InlineBase64\"}]}}"
            else
              echo "Updating existing pipeline: $name (ID: $item_id)"
              curl -s -X POST -H "Authorization: Bearer $FABRIC_TOKEN" \
                -H "Content-Type: application/json" \
                "https://api.fabric.microsoft.com/v1/workspaces/$TEST_WS_ID/items/$item_id/updateDefinition" \
                -d "{\"parts\":[{\"path\":\"pipeline-content.json\",\"payload\":\"$payload_b64\",\"payloadType\":\"InlineBase64\"}]}"
            fi
          fi
        done
```

---

## 5. Deployment Runbook Template (For Production Releases)

Ensure this runbook accompanies every release PR.

### 5.1 Pre-deployment Steps
1. [ ] Verify all integration tests in `ws-data-test` passed.
2. [ ] Validate that the target capacity (`fab-cap-prod`) has at least 30% headroom.
3. [ ] Confirm that no active pipeline runs are writing to the target bronze tables.

### 5.2 Deployment Execution
1. [ ] Execute DevOps pipeline deployment trigger.
2. [ ] Check the Deployment Pipeline status UI to verify all connections resolved.
3. [ ] If database schemas changed, run the SQL Migrations DDL scripts on the production Warehouse first.

### 5.3 Post-deployment Sanity Checks
1. [ ] Run an ad-hoc trial of `pl_master_orchestrator` with parameters set to `pEnvironment=prod`.
2. [ ] Verify entries were written to `lh_ops.dbo.notebook_events`.
3. [ ] Check that the Power BI semantic models in `ws-data-prod` are set to `DirectLake` mode (not importing) to prevent memory ballooning.

### 5.4 Rollback Procedure (If things break)
1. Revert the PR on GitHub to restore `main` to the previous commit.
2. Run the Github Action deploy workflow again on the reverted commit.
3. If structural schemas are broken, restore the Lakehouse tables to a previous state using Delta Lake's **Time Travel**:
   ```sql
   -- Restore table back to before the deployment
   RESTORE TABLE lh_bronze.orders TO TIMESTAMP AS OF '2026-05-19 23:59:00';
   ```
