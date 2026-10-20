# Fabric architect: capacity, throttling, FinOps

Last verified: 2026-10-19 (Learn: `enterprise/licenses` 2026-06-15, `enterprise/throttling` 2026-08-14, `enterprise/pause-resume` 2026-04-20, `enterprise/enable-capacity-overage` 2026-09-11, `data-engineering/spark-job-concurrency-and-queueing` 2026-06-15, `onelake/onelake-consumption` 2026-09-21, `fundamentals/fabric-trial` 2026-08-12).

## 1. SKU table
| F SKU | CUs | Power BI equivalent | Spark VCores | Spark max with burst | Spark queue |
|---|---|---|---|---|---|
| F2 | 2 | none | 4 | 20 | 4 |
| F4 | 4 | none | 8 | 24 | 4 |
| F8 | 8 | EM/A1 | 16 | 48 | 8 |
| F16 | 16 | EM2/A2 | 32 | 96 | 16 |
| F32 | 32 | EM3/A3 | 64 | 192 | 32 |
| F64 | 64 | P1/A4 | 128 | 384 | 64 |
| F128 | 128 | P2/A5 | 256 | 768 | 128 |
| F256 | 256 | P3/A6 | 512 | 1,536 | 256 |
| F512 | 512 | P4/A7 | 1,024 | 3,072 | 512 |
| F1024 | 1,024 | P5/A8 | 2,048 | 6,144 | 1,024 |
| F2048 | 2,048 | none | 4,096 | 12,288 | 2,048 |

- 1 CU = 2 Spark VCores. 8 CUs = 1 Power BI v-core.
- Small SKUs do not follow a strict 3x burst (F2 shows 20 from a base of 4); the page does not explain why. Quote the table, not the multiplier.
- Free-licence viewers of Power BI content need F64 or larger. Below F64 each viewer needs Pro, PPU or a trial.
- P SKUs are being retired. F SKUs bill per second with a one-minute minimum; yearly reservation optional.
- **Reservation discount percentage: `UNVERIFIED`** (not on fetched pages). Check the Azure pricing page before quoting.

## 2. Smoothing and throttling (mental model)
- 30-second timepoints. **Interactive** operations smooth over a minimum of 5 minutes, up to 64 minutes depending on CU use. **Background** operations smooth over 24 hours.
- Background: Spark and notebook runs, refreshes, Warehouse and SQL-endpoint operations. Interactive: Power BI queries, XMLA read, paginated report view, SQL database usage.
- Throttling is driven by smoothed *future* usage:

| Smoothed future usage | Stage | Effect |
|---|---|---|
| 10 min or less | Overage protection | Nothing throttled |
| more than 10 min, up to 60 min | Interactive delay | New interactive jobs delayed 20 s |
| more than 60 min, up to 24 h | Interactive rejection | New interactive jobs rejected; background still starts |
| more than 24 h | Background rejection | All new requests rejected |

- In-flight operations finish. Real-Time Intelligence skips the delay stage; Eventstreams shed allocated CU instead of rejecting. Microsoft says the policy may change.
- Errors: `CapacityLimitExceeded`; Spark over limit returns `TooManyRequestsForCapacity` (HTTP 430). Throttled capacity rejects new Spark jobs rather than queueing.
- Spark queue is FIFO with a 24-hour expiry and applies to pipeline, scheduler and SJD jobs, not interactive notebooks.

## 3. Cost controls
| Lever | Detail | Caveat |
|---|---|---|
| Pause/resume (F only) | Pausing adds remaining smoothed overage to the Azure bill, ends throttling, resumes billing on restart | Content on a paused capacity is unavailable. OneLake storage still bills while paused |
| Capacity overage | F only. 3x pay-as-you-go CU rate, on by default for new capacities, default 25% rolling 24 h threshold | Charges can exceed the threshold. Email notifications are PREVIEW |
| On-demand Spark billing (formerly Autoscale Billing) | Spark runs on serverless compute outside the capacity; you set a max-CU limit | No burst or smoothing. GA label not on page: `UNVERIFIED` |
| Reservations | Yearly commitment | Discount % `UNVERIFIED` |
| Trial | 60 days, F4 or F64, 1 TB OneLake | No Copilot, AI features, Private Link or Trusted Workspace Access. Not for production |
| OneLake storage | Pay-as-you-go per GB, no CUs. Soft-deleted data billed as active | BCDR roughly doubles write cost |

OneLake transactions cost CUs on the *consumer* workspace's capacity; the capacity holding the data pays storage only. Shortcuts to ADLS/S3/GCS use no Fabric CUs but the provider bills egress. Since 2026-10-15 Spark OneLake operations appear in CU reports (rates unchanged), so Spark-heavy tenants will see higher reported usage.

## 4. Sizing method for a PoC
1. Inventory workloads by type: Spark, SQL/Warehouse, Power BI interactive, RTI, Copilot/AI.
2. Start one SKU below the estimate on a pay-as-you-go F SKU. Never size from the trial alone (it is F4 or F64 with limits).
3. Run representative load for 1 to 2 weeks. Read the Capacity Metrics app: peak smoothed utilization, throttling minutes, top items by CU.
4. Decide: scale up, split capacities, or reschedule. Only then buy a reservation.
5. Check Direct Lake guardrails for the chosen SKU (see `workload-selection.md`).

## 5. Isolation patterns
| Pattern | Use when |
|---|---|
| Capacity per environment (prod vs non-prod) | Always. Dev must not throttle prod |
| Separate capacity for self-service BI | Ad-hoc users must not starve ETL |
| Separate capacity per business unit | Chargeback matters |
| Dedicated capacity for Spark batch | Heavy overnight loads; consider on-demand Spark billing |
| Dev capacity paused outside working hours | Cost control (see `capacity/capacity.md` for the automation) |

Scaling across the F256 and F512 boundary may feel slower (throttling page). Fixes for throttling: raise the SKU temporarily, pause and resume, enable overage, or load-balance across capacities.

## 6. Anti-patterns that burn CUs
- Everything scheduled at midnight; stagger background jobs.
- Interactive notebooks left attached with large sessions.
- Dataflow Gen2 for large volume that Spark or Copy job would handle cheaper.
- Prod and dev on one capacity.
- Buying a reservation before measuring.
- Ignoring Copilot/AI meter: Copilot, AI Functions and Data Agent bill under the "Copilot and AI" meter.

## 7. Talk track
"Capacity is a shared pool with smoothing. Short spikes are fine; sustained overload is what throttles. We isolate prod from dev, measure for two weeks before committing, and only then reserve. If a nightly load is the problem we move it to its own capacity or use on-demand Spark billing."
