---
name: csa-playbook
description: "Cloud Solution Architect playbook for Azure data and AI platforms (Microsoft Fabric, Azure Databricks, Cosmos DB, Purview): architectural design session (ADS) facilitation, PoC execution framework, Well-Architected review checklists with scoring, reference architectures (Mermaid), mission-critical patterns (RPO/RTO, failover testing, SLOs), TCO and business-value framing, anti-patterns and customer objections, and interview scenarios. USE FOR: run a design session, discovery questions by persona, scope or size a PoC, PoC exit criteria, production readiness checklist, well-architected review of a data workload, multi-region DR design, regulated-industry landing zone, TCO comparison, executive summary, CSA interview prep. DO NOT USE FOR: CLI/REST how-tos for a single product (use the product skill, e.g. microsoft-fabric), or live resource provisioning."
---

# CSA Playbook: Azure Data and AI Platform

Method layer on top of the product skills. Product facts live in the product skills and carry `Last verified` dates; this playbook tells you **how to run the conversation, the PoC and the review**.

Last verified: 2026-10-19. Product claims in these files were taken from Microsoft Learn pages fetched that day; anything not stated by those pages is marked `UNVERIFIED`. Re-check before quoting to a customer.

## Pick a reference

| Situation | Open |
|---|---|
| Preparing or running an architectural design session | [references/ads-guide.md](references/ads-guide.md) |
| Scoping, sizing, running or closing a PoC | [references/poc-framework.md](references/poc-framework.md) |
| Reviewing a workload for reliability, security, cost, ops, performance | [references/waf-checklists.md](references/waf-checklists.md) |
| Need a diagram for the whiteboard or the deck | [references/reference-architectures.md](references/reference-architectures.md) |
| Designing for RPO/RTO, failover tests, SLOs, runbooks | [references/mission-critical.md](references/mission-critical.md) |
| TCO comparison, value drivers, executive summary | [references/cost-business-value.md](references/cost-business-value.md) |
| Customer pushback or a design smell | [references/anti-patterns-objections.md](references/anti-patterns-objections.md) |
| Interview or scenario practice | [references/interview-prep.md](references/interview-prep.md) |

## Product skills to pair with

| Area | Skill | Status |
|---|---|---|
| Microsoft Fabric architecture | `microsoft-fabric` (see its `references/architect/`) | written |
| Azure Databricks | `azure-databricks-architecture` (plus existing `databricks-*` skills) | written |
| Cosmos DB | `azure-cosmos-db` | written |
| Purview | `microsoft-purview` | written |

All four product areas now have skills; still verify version-sensitive facts on Microsoft Learn before quoting them to a customer.

## Operating rules for a CSA session

1. Start from the business outcome and the constraint, not the product.
2. Name the trade-off out loud for every recommendation.
3. Separate GA from preview in every recommendation; keep preview off the critical path.
4. Say "I do not know, I will verify" instead of quoting an unpublished number (for example an RPO).
5. Leave every session with a decision log, an owner per open item and a next date.
6. Keep PoCs cheap: pay-as-you-go F SKU, small data, capped budget, automatic shutdown.
