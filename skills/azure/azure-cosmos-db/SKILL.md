---
name: azure-cosmos-db
description: "Azure Cosmos DB architecture for NoSQL workloads: data modeling (embed vs reference, partition key and hierarchical keys, limits), throughput (provisioned, autoscale, serverless, RU tuning, burst capacity, indexing), global distribution and resiliency (consistency levels, RPO/RTO, multi-region writes, failover, backup and restore, SLA), security (Entra RBAC with local auth disabled, private endpoints, CMK, Always Encrypted, Defender, diagnostic logs), AI-readiness (vector, full-text and hybrid search, agent memory), analytics (Fabric mirroring, Synapse Link status), API selection (NoSQL, MongoDB, DocumentDB, PostgreSQL), SDK best practices and 429 troubleshooting. USE FOR: Cosmos DB design session, partition key choice, RU sizing, consistency choice, multi-region design, disable key auth, Cosmos DB for RAG, Cosmos to Fabric analytics, Cosmos PoC load test. DO NOT USE FOR: relational OLTP design (use sqldb/Azure SQL guidance), Fabric-only decisions (use microsoft-fabric), or provisioning accounts."
---

# Azure Cosmos DB (decision layer)

Facts come from Microsoft Learn pages fetched on 2026-10-19 (page `ms.date` or update date noted in each reference). Items the pages did not state are `UNVERIFIED`; preview items are flagged. Examples target the **API for NoSQL** unless stated.

## Pick a reference

| Need | Open |
|---|---|
| Partition key, embed vs reference, hard limits, RU/throughput choice, indexing, burst, change feed | [references/modeling-throughput.md](references/modeling-throughput.md) |
| Consistency levels, SLA/RPO/RTO, multi-region writes, failover, conflict resolution, backup/restore | [references/resiliency-consistency.md](references/resiliency-consistency.md) |
| Entra-only auth, data-plane RBAC, private endpoints, firewall, CMK, Always Encrypted, Defender, logs | [references/security-networking.md](references/security-networking.md) |
| Vector/full-text/hybrid search, agent memory, Fabric mirroring, Synapse Link status, API selection, SDK tips, 429s, migration, PoC load test | [references/ai-analytics-api-ops.md](references/ai-analytics-api-ops.md) |
| Session, PoC or review framework | [../csa-playbook/SKILL.md](../csa-playbook/SKILL.md) |

## Pair with
- Analytics landing in Fabric: [Fabric onelake-integration](../../fabric/microsoft-fabric/references/architect/onelake-integration.md) (mirroring facts).
- Governance and scanning: [microsoft-purview](../microsoft-purview/SKILL.md) (Cosmos scans need the account key; see the tension with disabling local auth).
- Microsoft also publishes an open-source Cosmos DB agent kit (111 rules in 12 categories, installable with `npx skills add AzureCosmosDB/cosmosdb-agent-kit`, status unlabelled); review it as a complement, not a replacement.

## Decide first (hard to undo)
1. **Partition key** is immutable; changing it means a container copy job or a new container.
2. **Hierarchical partition key** is set at container creation only.
3. **Consistency**: Strong is unavailable with multi-region writes.
4. **Conflict resolution mode** (custom merge procedure) is set at container creation only.
5. **Vector policy and index** cannot be edited after creation.
6. **Backup mode**: periodic can move to continuous, but continuous cannot go back to periodic.

## Talk track
"Cosmos DB is a model-first service: the partition key and access patterns decide cost and scale, not the SKU. We pick the key from the queries, choose Session unless a flow proves otherwise, run Entra-only authentication, and prove it with a load test that includes a hot-key case and a failover drill."
