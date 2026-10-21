# Fabric architect: ALM, CI/CD and governance operating model

Last verified: 2026-10-19 (Learn: `cicd/git-integration/intro-to-git-integration` 2026-09-01, `cicd/deployment-pipelines/intro-to-deployment-pipelines` 2026-09-24, `cicd/best-practices-cicd` 2026-06-15, `cicd/variable-library/variable-library-overview` 2026-09-01; fab CLI docs at microsoft.github.io/fabric-cli). Hands-on steps and workflows live in [../../cicd/cicd.md](../../cicd/cicd.md); this file is the decision layer.

## 1. Git integration
- Providers: Azure DevOps, GitHub, GitHub Enterprise (cloud only). Workspace-level; subfolders preserved; unsupported items are ignored, not deleted.
- Items with **no preview tag** on the page: Lakehouse, Notebook, Environment, Spark Job Definition, GraphQL, User Data Functions, Data Agents, Copy Job, Dataflow Gen2, Pipeline, Mirrored database, Mount ADF, Warehouse, Mirrored Databricks Catalog, Eventhouse, Eventstream, KQL DB, Activator, SQL database, Variable Library, Graph Model.
- **PREVIEW** in Git: ML experiments and models, mirrored Snowflake, Airflow, dbt Job, Operations Agent, Power BI report/semantic model/paginated report (as listed), Cosmos DB, Deployment plan, Ontology, Plan, Event Schema Set, Digital twin builder, Anomaly detection. Re-check the page before promising Git coverage for a given item.

## 2. Deployment pipelines
- 2 to 10 stages (default 3). Items are paired across stages; unpaired items with the same name create duplicates instead of overwriting.
- Deployment rules switch data sources and parameters per stage. New UI and deployment plans are PREVIEW (ordering, pre/post actions and API usage: see [deployment-plans-monitoring.md](deployment-plans-monitoring.md); `fabric-cicd` does not support plans). Semantic models not on Enhanced Metadata have been retired from deployment pipelines since 2026-02-12.
- Automate through the deployment pipelines REST APIs.

## 3. Variable libraries (the right way to parameterize)
Consumers: Pipeline, lakehouse shortcut, Notebook, Dataflow Gen2, Copy job, UDF, Eventstream. Limits: 1,000 variables and 1,000 value sets; fewer than 10,000 cells in alternative value sets; item size at most 1 MB; name at most 256 chars; one active value set per library, and each deployment stage can have its own.

## 4. Choose a promotion model
| Model | Use when | Trade-off |
|---|---|---|
| Git + deployment pipelines | Mostly low-code teams, Power BI heavy | Easy, less code review of promotion logic |
| Git branches per environment + `fab` CLI/REST in Actions or Azure Pipelines | Engineering-led, strong review culture | More plumbing, full control |
| Release branches to prod | Regulated change control | Slower |

Best practices from Learn: separate workspaces per team and per environment; separate dev/test/prod data stores; parameterize per stage; private workspace per feature branch with small commits (large commits hit a max size); revert with git revert/reset then update the workspace; test on a capacity similar to production; updating an app needs the API, not the UI.

## 5. fab CLI
`pip install ms-fabric-cli` (Python 3.10 to 3.13). `fab auth login` supports interactive, service principal (secret, certificate, federated token) and managed identity. Commands include ls, cd, cp, mv, rm, ln, import, export, bulk-export, deploy, start, jobs, api, acl, assign, table, label. The Fabric REST index and CI/CD article list the `fab` CLI, the Terraform provider and the `fabric-cicd` library as automation options (Learn, 2026-10-21); GA labels and supported item types per tool are not stated on Learn: `UNVERIFIED`. Local note: `fab` currently reports "Not logged in" on this machine. Terraform provider: listed on Learn but no Learn page documents its resource list: `UNVERIFIED`.

## 6. Governance operating model
| Element | Decision |
|---|---|
| Domains | One per business area; delegate selected tenant settings to domain admins |
| Endorsement | Promoted by owners; Certified by domain admins; Master data for golden tables |
| Workspaces | One per team x environment; naming standard; capacity assigned by environment |
| Labels | Published sensitivity labels; default label per domain (domain defaults are PREVIEW) |
| Catalog | OneLake catalog for discovery; Purview for tenant-wide governance (see Purview skill when created) |
| Audit | Purview audit for control plane; OneLake diagnostics for data plane |

## 7. Anti-patterns
- Editing prod in the portal "just once".
- Hard-coded workspace and lakehouse GUIDs in notebooks and pipelines.
- One workspace for dev, test and prod.
- Branching strategy invented per team.
- Assuming every item type is in Git.

## 8. Talk track
"Everything promotable lives in Git, parameters live in variable libraries, and prod is only ever changed by a pipeline. Which promotion mechanism we use is a team-skills decision; the discipline is the same."
