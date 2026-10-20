# Well-Architected review checklists for data workloads

Last verified: 2026-10-19. Structure follows the five Azure Well-Architected pillars. Product-specific items cite what Learn stated (Cosmos DB WAF service guide, ms.date 2025-11-21; Fabric pages listed in the Fabric skill). Items marked `(verify)` are good practice not tied to a fetched page.

## Scoring rubric
For each item score 0 (absent), 1 (partial / manual), 2 (in place and tested). Pillar score = sum / (2 x items). Rating: below 50% = high risk, 50 to 79% = medium, 80% and up = healthy. Record evidence (link, screenshot, config) next to every 2. An untested control scores at most 1.

## Reliability
- [ ] Workload tiers defined (tier 1/2/3) with RPO/RTO per tier
- [ ] Zone redundancy enabled where offered; single points of failure listed
- [ ] DR approach chosen per tier and rehearsed in the last 12 months
- [ ] Everything rebuildable from Git and IaC (items, pipelines, models, infra)
- [ ] Retry with backoff in every client; idempotent loads
- [ ] Back-pressure and dead-letter handling for streaming
- [ ] Backups configured and a restore tested (not just enabled)
- [ ] Dependency map including preview features and their fallback
- Cosmos DB specifics (Learn): at least 2 regions and availability zones; keep a read region plus service-managed failover for single-write accounts; test failover and failback end to end; continuous backup retention matched to requirements; validate partition-level failover behaviour.
- Fabric specifics: capacity BCDR switch decided; non-OneLake items in Git; region availability checked for every feature in the design.

## Security
- [ ] Identity: groups not individuals; managed identities / service principals with least privilege; no shared keys (Cosmos: consider disabling key-based auth)
- [ ] Network: public access decision documented; private endpoints/links where policy requires; outbound control decided
- [ ] Data protection: classification and labels; row/column security owner named; masking where needed
- [ ] Encryption: key ownership decided; CMK scope and exclusions understood (Fabric CMK excludes Spark shuffle data, environment libraries, some metadata, Warehouse caches)
- [ ] Secrets in Key Vault; rotation owner
- [ ] Audit: control-plane and data-plane logs enabled and retained; alerts on privileged changes
- [ ] Threat protection enabled (Cosmos: Defender for Cosmos DB, NoSQL only)
- [ ] AI data handling reviewed (Copilot cross-geo processing, prompt/response logging)
- [ ] Azure Policy guardrails (Cosmos: at least 2 regions, zone redundancy, local auth disabled, public access disabled)

## Cost optimization
- [ ] Capacity/throughput model matches load shape (Cosmos: serverless vs provisioned vs autoscale; Fabric: F SKU isolation, pause for non-prod)
- [ ] Measured utilization, not guesses, drove the size
- [ ] Budgets and alerts per environment; tags for chargeback
- [ ] Storage lifecycle: TTL, retention, vacuum, tiering
- [ ] No duplicate copies where a shortcut or mirror would do
- [ ] Reservations only after 4+ weeks of measured steady state
- [ ] Idle resources found and removed monthly
- [ ] Hidden meters understood (egress, BCDR doubling write cost, Copilot and AI meter)

## Operational excellence
- [ ] IaC for infrastructure; Git for items; no portal-only changes in prod
- [ ] CI/CD with promotion gates and rollback
- [ ] Monitoring: SLIs defined; dashboards; alerts routed to an on-call owner
- [ ] Runbooks for the top 10 incidents; post-incident reviews
- [ ] Naming, tagging and workspace/account conventions enforced
- [ ] Data quality checks with ownership
- [ ] Capacity/throughput throttling alerts (Cosmos: alert on 429s and normalized RU; Fabric: Capacity Metrics app)
- [ ] Documentation of decisions (decision log)

## Performance efficiency
- [ ] Workload placed on the right engine (see Fabric workload-selection)
- [ ] Data layout tuned (Delta file size / row groups; Cosmos partition key and indexing policy)
- [ ] Client configuration best practice (Cosmos: singleton client, direct mode, preferred regions, bulk mode)
- [ ] Load tested at 2x expected peak with realistic skew
- [ ] Caching and pre-aggregation where reads dominate
- [ ] Known guardrails checked for the chosen SKU (Direct Lake guardrails per F SKU)
- [ ] Regional proximity of compute and data; no cross-region chatter

## Review output template
| Pillar | Score | Top 3 gaps | Owner | Fix by |
|---|---|---|---|---|
