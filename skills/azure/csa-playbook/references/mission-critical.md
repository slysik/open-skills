# Mission-critical patterns

Last verified: 2026-10-19. Product numbers come from Learn pages cited in the Fabric reliability reference and the Cosmos DB research (consistency-levels, reliability-cosmos-db, continuous-backup pages). `UNVERIFIED` where no page stated it.

## 1. Tiering
| Tier | Example workloads | Target RPO / RTO (design targets, not SLAs) | Typical pattern |
|---|---|---|---|
| 1 | Payments, patient-facing, trading | Near zero / minutes | Active-active or active-passive with automatic failover, tested quarterly |
| 2 | Operational reporting, customer analytics | Minutes to hours / hours | Warm standby or rebuild from Git plus replicated data |
| 3 | Exploration, dev, batch ML | Hours to days / days | Rebuild from IaC and source |

Agree the tier with the business owner, then derive the design. Never promise an RPO/RTO the service does not publish.

## 2. Active-active vs active-passive
| | Active-active | Active-passive |
|---|---|---|
| Availability | Highest | High |
| Complexity | Conflict handling, global consistency choices | Failover runbook |
| Cost | Roughly 2x or more | Standby cost |
| Data | Multi-write needs conflict policy | Single writer |
| Use when | Tier 1 with global users | Tier 1/2 with a clear primary region |

### Cosmos DB reference facts (Learn, 2026-10-19)
- Consistency: Strong is not available with multi-region writes (a distributed system cannot give RPO 0 and RTO 0 together). Strong and Bounded Staleness reads cost about 2x the RUs of the other levels. Session is the common default.
- RPO by configuration: single region under 240 minutes; multi-region with Session, Consistent Prefix or Eventual under 15 minutes; Bounded Staleness equals K and T; Strong (single-write) 0.
- Service-managed failover can take an hour or more to declare; unreplicated writes can be lost unless Strong. Forced failover (customer-initiated) takes seconds to minutes. A region offline for an outage can take 3+ days to restore.
- 99.999% is stated for multi-region accounts; other SLA percentages `UNVERIFIED` (SLA document not fetched).
- Per-partition automatic failover: GA status `UNVERIFIED`.

### Fabric reference facts
- Zone failures are handled automatically; regional DR needs the BCDR switch for OneLake data and Git for everything else; replication is asynchronous and no numeric RPO is published; failover is initiated by Microsoft and typically under an hour (not contractual). See the Fabric `resiliency-dr.md`.

## 3. Failure and chaos testing
| Test | How | Pass criterion |
|---|---|---|
| Zone loss | Fail over zone-redundant dependency in a test setup, or simulate by blocking a dependency | No data loss, recovery within target |
| Region loss | Planned failover drill (Cosmos forced failover in a non-prod account; Fabric rebuild from Git into a second capacity) | Measured RTO within target, data gap measured |
| Throttling | Load beyond provisioned throughput / capacity | Clients back off, no cascading failure, alerts fire |
| Credential revoke | Rotate or revoke a key in a test | Detected, runbook works |
| Poison message | Inject malformed event | Dead-letter, pipeline continues |
| Restore | Restore from backup to a new account/workspace | Restore time and completeness recorded |

Always rehearse in non-prod first, with a rollback and an owner on call. Restores have caveats worth testing (Cosmos continuous-backup restore does not restore firewall, VNet, RBAC, private endpoint settings or stored procedures and re-applies TTL).

## 4. SLO and error-budget thinking
1. Define SLIs the customer feels: freshness (data age), availability (successful queries), latency (p95), correctness (reconciliation).
2. Set SLOs per tier, for example "gold tables fresh within 30 min, 99% of days".
3. Error budget = 1 minus SLO. Spend it on releases; freeze changes when it is exhausted.
4. Alert on burn rate, not on single failures.

## 5. Runbook template
| Section | Content |
|---|---|
| Trigger | Alert or symptom |
| Impact | Who and what |
| Diagnose | Dashboards, queries, logs |
| Decide | Fix forward or fail over; decision owner |
| Act | Numbered commands/steps |
| Verify | Checks that prove recovery |
| Communicate | Template message and channel |
| After | Review within 5 working days |
