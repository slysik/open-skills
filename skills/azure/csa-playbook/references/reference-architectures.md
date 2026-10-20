# Reference architectures (Mermaid)

Last verified: 2026-10-19. These are design patterns built from Learn-verified capabilities; they are not official Microsoft diagrams. Preview items are flagged. Labels containing parentheses are quoted so Mermaid renders them.

## 1. Modern data estate: Fabric + Databricks + Cosmos DB + Purview

```mermaid
flowchart LR
  subgraph apps[Operational]
    cos[(Cosmos DB for NoSQL)]
    sqlo[(Azure SQL)]
  end
  subgraph dbx[Azure Databricks]
    dl[(ADLS Gen2 + Unity Catalog)]
    ml[Mosaic AI / MLflow]
  end
  subgraph fab[Microsoft Fabric]
    ol[(OneLake)]
    sm[Direct Lake semantic model]
    da[Data agent]
  end
  cos -->|"Fabric mirroring (NoSQL API, continuous backup)"| ol
  sqlo -->|mirroring| ol
  dl -->|"mirrored catalog (metadata)"| ol
  ol --> sm --> bi[Power BI]
  ol --> da
  dl --> ml
  pv[Purview] -.scan, labels, lineage.-> fab
  pv -.scan.-> dbx
  pv -.scan.-> cos
```
Use when: operational data feeds analytics and AI, with Databricks for engineering/ML. Trade-off: two compute platforms mean two security models; pick one owner for row/column security. Synapse Link for Cosmos DB is not supported for new projects (Learn); use Fabric mirroring.

## 2. Real-time / IoT

```mermaid
flowchart LR
  dev[Devices / PLCs] --> hub[Event Hubs or IoT Hub]
  hub --> es[Fabric Eventstream]
  es --> eh[(Eventhouse / KQL)]
  es --> lh[(Lakehouse bronze)]
  eh --> rtd[Real-time dashboard]
  eh --> act[Activator alerts]
  lh --> sm[Direct Lake model]
```
Use when: second-level telemetry, anomaly alerting. Trade-off: Eventhouse is the only Fabric store where OneLake availability is opt-in; Real-Time Intelligence skips the interactive-delay throttling stage and begins rejecting at the 60-minute stage; keep streaming on its own capacity.

## 3. RAG / agentic AI over operational and analytical data

```mermaid
flowchart LR
  docs[Documents] --> chunk[Chunk + embed]
  chunk --> vec[(Vector store)]
  cos[(Cosmos DB: agent memory + vectors)] --> agent[Agent app]
  vec --> agent
  ol[(OneLake gold tables)] --> da[Fabric data agent]
  da --> agent
  agent --> llm[Azure OpenAI / Foundry model]
  agent --> user[User]
  pv[Purview + labels] -.governs.-> ol
  pv -.governs.-> vec
```
Vector choices (Learn): Cosmos DB NoSQL offers `flat` (max 505 dims), `quantizedFlat` and `diskANN` (max 4096 dims); Eventhouse stores vectors without a native ANN index; SQL database in Fabric vector status is `UNVERIFIED`. Data agent limits: 5 sources, 25 rows/columns per response, read-only. Keep preview items (ontology, Foundry tools in Fabric) out of the critical path.

## 4. Multi-region DR

```mermaid
flowchart TB
  subgraph r1[Region A primary]
    c1[(Cosmos write region)]
    f1[Fabric capacity A]
    d1[Databricks workspace A]
  end
  subgraph r2[Region B secondary]
    c2[(Cosmos read region)]
    f2[Fabric capacity B: rebuilt from Git]
    d2[Databricks workspace B]
  end
  c1 -->|replication| c2
  f1 -->|"BCDR switch: OneLake data only"| f2
  git[Git + IaC] --> f2
  git --> d2
  user[Clients] --> afd[Front door / traffic manager]
  afd --> r1
  afd --> r2
```
Use when: tier 1/2 workloads. Trade-off: Fabric BCDR covers OneLake lakehouse and warehouse data only; KQL, notebooks, pipelines and the rest are rebuilt from Git; Fabric replication is asynchronous with no published numeric RPO.

## 5. Regulated-industry landing zone (FSI, healthcare)

```mermaid
flowchart TB
  idp[Entra ID + Conditional Access] --> hub
  subgraph hub[Hub VNet]
    fw[Firewall + DNS]
  end
  subgraph spoke[Data spoke VNet]
    pe1[Private endpoints: ADLS, Key Vault, Cosmos]
    dbx[Databricks: VNet injection, no public IP]
    gw[VNet data gateway]
  end
  hub --- spoke
  fab[Fabric: tenant private link, outbound access protection] --> gw
  kv[Key Vault: CMK, soft delete, purge protection]
  mon[Log Analytics + Defender + Purview audit]
  spoke --> mon
  fab --> mon
```
Notes: Fabric private link breaks on-prem gateway registration (VNet data gateway works) and starter Spark pools, and does not secure outbound traffic; trusted workspace access is for F SKUs and not for Spark (use managed private endpoints); Cosmos DB customer-managed keys need Key Vault with soft delete and purge protection and a vault reachable by public access or the trusted-services bypass. Databricks networking facts: see the `azure-databricks-architecture` skill (VNet injection, SCC, Private Link, storage firewall).
