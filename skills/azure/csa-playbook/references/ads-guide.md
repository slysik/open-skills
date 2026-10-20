# ADS facilitation guide

Last verified: 2026-10-19 (method content; product statements link to product skills).

## 1. Shape of a 3-hour ADS
| Block | Min | Output |
|---|---|---|
| Outcomes and constraints | 20 | Top 3 business outcomes, hard constraints (regulatory, region, date, budget) |
| Current state | 30 | One-page estate map: sources, volumes, latency, tools, teams, pain |
| Target principles | 20 | 5 to 7 agreed principles (for example "one copy of data", "private by default") |
| Architecture options | 50 | 2 to 3 options with the trade-off table |
| Risks, security, DR | 30 | Risk list with owner; DR tier per workload |
| Decisions and next steps | 20 | Decision log, PoC scope, owners, dates |

Pre-read to request: architecture diagrams, data volumes, SLAs, security policy, last audit findings, current spend.

## 2. Discovery questions by persona

**CDO / head of data**
- Which 3 decisions or products does this platform have to improve, and how is that measured today?
- Who owns data quality and definitions? Is there a glossary?
- What data must never leave a boundary (region, tenant, cloud)?
- Which AI use cases are real versus aspirational? Who signs off on AI risk?

**CISO / security architect**
- Which frameworks apply (GDPR, HIPAA, PCI, SOC 2, internal)? Residency rules?
- Is public network access allowed for data services? Is private connectivity mandatory?
- Key management: Microsoft-managed or customer-managed? Who owns rotation?
- How are identities governed (groups, service principals, managed identities)? Any shared keys today?
- What is the stance on Copilot and AI features processing data outside the capacity region?

**Data engineering lead**
- Batch versus streaming split; largest table; peak load window; late-arriving data?
- Current orchestration, CI/CD and testing; how long does a failed run take to recover?
- Skills mix (SQL, PySpark, low-code)? Existing Databricks or Synapse investment?
- What breaks at month-end?

**Application owner**
- Read/write ratio, latency target at p99, peak requests, item/document size, growth per year?
- Multi-region users? Required consistency? Tolerance for stale reads?
- Access patterns: point reads, queries, aggregations, search, vector?

**FinOps / finance**
- Current run cost and its drivers; commitment appetite; chargeback model?

## 3. Vertical lenses
| Vertical | Typical drivers | Constraints to probe |
|---|---|---|
| FSI | Risk, fraud, regulatory reporting, real-time payments | Residency, auditability, private networking, key control, DR tier 1 |
| Retail | Personalization, demand forecasting, omnichannel inventory | Seasonal peak sizing, global distribution, low-latency catalog |
| Healthcare | Clinical analytics, interoperability, ambient/AI assist | PHI, HIPAA, consent, de-identification, AI data handling |
| Manufacturing | IoT, predictive maintenance, quality, supply chain | Edge-to-cloud ingest, time-series volume, OT network boundaries |

## 4. Requirements-to-architecture mapping template
| Requirement | Type (functional / NFR) | Metric and target | Candidate component | Product skill | Risk | Decision |
|---|---|---|---|---|---|---|
| Example: dashboards under 3 s for 200 users | NFR | p95 < 3 s | Direct Lake model on F64 | microsoft-fabric | guardrails | D-004 |

Rule: every NFR needs a number. If the customer cannot give one, record an assumption and an owner to confirm.

## 5. Options table (use for each decision)
| Option | Fit | Cost shape | Risk | Reversibility | Preview dependency |
|---|---|---|---|---|---|

## 6. Decision log template
| ID | Date | Decision | Alternatives considered | Rationale | Owner | Revisit when |
|---|---|---|---|---|---|---|

## 7. Close the session
Read back the decisions, list open questions with owners, propose PoC scope (see [poc-framework.md](poc-framework.md)), send the notes within 24 hours.
