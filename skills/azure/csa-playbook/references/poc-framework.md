# PoC execution framework

Last verified: 2026-10-19 (method content; capacity and trial facts from Learn `enterprise/licenses`, `fundamentals/fabric-trial`).

## 1. Rules
- A PoC answers 2 to 4 questions that block a decision. It is not a mini-production.
- Written success criteria before any resource is created. Numeric where possible.
- Time-box 2 to 4 weeks. Fixed budget cap. Named customer owner who can say yes.
- Preview features only if the PoC question is about that feature.

## 2. Charter template
| Field | Content |
|---|---|
| Business outcome | One sentence |
| Questions to answer | 2 to 4 |
| In scope / out of scope | Explicit lists |
| Success criteria | Metric, target, how measured, who judges |
| Data | Source, volume, sensitivity, synthetic or masked? |
| Environment | Subscription, region, capacity/SKU, network posture |
| Budget cap and shutdown rule | Number and the person who can stop it |
| Team | Customer roles, Microsoft roles, weekly cadence |
| Exit decision | Proceed, adjust, stop; who decides, when |

## 3. Test data strategy
1. Prefer synthetic data with realistic skew and volume (see `databricks-synthetic-data-gen`).
2. If real data is needed: de-identify first, minimum columns, written approval from security.
3. Test the hard cases: hot keys, late data, schema drift, nulls, peak concurrency.
4. Never copy production PHI/PCI into a PoC subscription.

## 4. Plan template (3 weeks)
| Week | Goals | Gate |
|---|---|---|
| 0 | Charter signed, access granted, budget alerts set, data approved | Go/no-go |
| 1 | Environment, ingestion, baseline measurements | Baseline numbers captured |
| 2 | Core scenarios, security and failure tests, load test | Criteria half-evidenced |
| 3 | Gaps, cost extrapolation, readout | Readout and decision |

## 5. Cost caps for a low-budget lab
- Use pay-as-you-go F SKUs and pause when idle (pause ends throttling and billing resumes only on resume; OneLake storage still bills while paused).
- The Fabric trial is 60 days on F4 or F64 and lacks Copilot, AI features, Private Link and Trusted Workspace Access, so it cannot answer questions on those.
- Set Azure budgets with alerts at 50%, 80%, 100% before deploying; tag every resource with owner and expiry date; schedule teardown.
- Prefer serverless/autoscale options for intermittent loads; delete rather than stop anything that bills at rest.
- Do not create paid resources without the owner's written OK.

## 6. Measuring
| Dimension | How |
|---|---|
| Performance | p50/p95/p99 latency under a defined load, using the product's own metrics |
| Cost | Measured consumption over a representative window, then extrapolate; show the assumptions |
| Resiliency | Run a failure (kill a region/job, revoke a key in a test) and record time to recover |
| Security | Walk the checklist in [waf-checklists.md](waf-checklists.md); attempt a denied access and prove it fails |
| Operability | Time to deploy from Git into a clean environment |

## 7. Exit criteria and readout
Readout sections: what we tested, results versus criteria (pass/fail table), surprises, risks, cost extrapolation with ranges, recommendation, production plan and effort. Each criterion gets pass, partial or fail with evidence.

## 8. Readiness to production checklist
- [ ] Environments separated (dev/test/prod) with separate capacity or accounts
- [ ] Infrastructure and items in Git; deployment automated; rollback tested
- [ ] Identity via groups and managed identities; no shared keys
- [ ] Network posture decided and tested (private endpoints, firewall, egress)
- [ ] Encryption and key ownership decided
- [ ] Data classification and labels applied; lineage visible
- [ ] Monitoring, alerts, runbooks, on-call owner
- [ ] DR tier chosen and rehearsed (see [mission-critical.md](mission-critical.md))
- [ ] Cost alerts and chargeback tags
- [ ] Preview dependencies listed with a fallback
- [ ] Support plan and escalation path
