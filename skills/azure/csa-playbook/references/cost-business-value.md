# Cost and business value

Last verified: 2026-10-19 (method content; cost mechanics cite Learn pages in the Fabric and Cosmos research).

## 1. TCO comparison method
1. **Boundary**: same workload, same SLAs, same period (3 years).
2. **Baseline**: current run cost (licences, infrastructure, support, people time on operations).
3. **Options**: 2 to 3 (for example stay, Fabric, Databricks, both).
4. **Cost lines per option**
   - Platform: compute/capacity, storage, networking/egress, licences, support plan.
   - Migration: one-time engineering, parallel run, training, tooling.
   - Operations: people, on-call, tooling.
   - Risk: expected cost of an outage times probability (use ranges).
5. **Measure, then extrapolate**: take utilization from the PoC; show low/base/high.
6. **Sensitivity**: vary the top 3 assumptions; show which flips the answer.
7. **Never quote list prices as TCO.** Prices are regional; reservation discounts are `UNVERIFIED` for Fabric until checked on the pricing page.

### Cost mechanics worth knowing (Learn)
- Fabric: F SKUs bill per second (one-minute minimum), pausing stops billing but OneLake storage keeps billing; overage costs 3x the pay-as-you-go CU rate; mirroring compute is free and free storage is 1 TB per CU purchased; BCDR roughly doubles write cost; external shortcut sources bill egress at the provider.
- Cosmos DB: autoscale costs 1.5x the manual per-RU rate on single-write accounts and the same as manual on multi-region-write accounts with more than one region; if the container uses its full max for 66% of hours or fewer, autoscale is cheaper; strong/bounded-staleness reads cost about 2x the RUs; the 7-day continuous backup tier has no storage charge while 30 and 35 days do (restore is charged per GB).

## 2. Value drivers mapped to KPIs
| Driver | KPI | Typical measure | Evidence source |
|---|---|---|---|
| Faster decisions | Data freshness, time to insight | Minutes from event to dashboard | Pipeline metrics |
| Lower run cost | Cost per query / per TB / per report | Currency per unit | Cost management |
| Productivity | Engineer hours saved, release frequency | Hours per month, deploys per week | Git/CI data |
| Risk reduction | Audit findings, incident count, RTO | Count, minutes | Audit, incident log |
| Revenue | Conversion, churn, fraud loss avoided | Percent or currency | Business system |
| AI enablement | Use cases in production | Count with owner | Portfolio |

By vertical: FSI (fraud loss avoided, regulatory report cycle time), retail (forecast accuracy, stock-outs), healthcare (readmission analytics, time to clinical insight, compliance incidents), manufacturing (unplanned downtime, scrap rate).

Rule: each driver needs a baseline, a target, an owner on the customer side and a date.

## 3. One-page executive summary template
```
Title: <Customer> data platform decision
Date / author / status

1. Decision requested (one sentence)
2. Why now (business outcome and constraint)
3. Recommendation (architecture in 3 lines + diagram)
4. Evidence (PoC results versus criteria: pass/partial/fail)
5. Cost (3-year range, key assumptions)
6. Value (top 3 KPIs, baseline -> target)
7. Risks and mitigations (top 3, owners)
8. Preview / unverified dependencies and fallback
9. Next steps (owner, date)
```
Keep to one page. Put detail in an appendix.
