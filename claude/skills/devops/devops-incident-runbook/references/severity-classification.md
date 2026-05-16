# Severity Classification

Decision rules for assigning SEV1 / SEV2 / SEV3 to an incident.
Routes paging, postmortem requirement, and external comms.

## SEV1 — page immediately

**Customer-visible outage or material risk.** Any of:

- Service unavailable for ≥5 min for any meaningful user
  cohort.
- Data loss or corruption (any, regardless of size).
- Security breach or active exploit.
- Regulatory violation in progress.
- Revenue-impacting (transactions failing, payments not
  processing).
- Critical SLA breach with contractual penalties.

**Response.** Page on-call immediately; incident channel
spun up; named incident commander; external comms within 15 min
(status page + customer email for impacted).

**Postmortem.** **Required**, filed within 5 business days.

## SEV2 — page during business hours

**Degraded service or near-miss.** Any of:

- Performance degradation (p95 >2× baseline) sustained ≥30 min.
- Partial functionality loss (one feature down, rest works).
- Capacity threshold reached (autoscaler maxed, but no rejection
  yet).
- Single-region outage with traffic shifted (customers
  unaffected but redundancy lost).
- Repeated failed deploys / rollbacks (operational concern).
- High-severity alert that hasn't cleared in 30 min.

**Response.** Notify channel; on-call engages within
business-hours SLA (typically 1h); incident channel optional;
external comms only if customer-visible.

**Postmortem.** **If novel** (haven't seen this class before)
OR if root cause indicates a SEV1 risk → file within 10 business
days. Otherwise optional but recommended.

## SEV3 — next-day investigation

**Concerning but non-urgent.** Any of:

- Single-instance failure with auto-recovery working.
- Alert firing repeatedly at low rate.
- Performance regression < 2× baseline.
- Internal-only impact (engineer-facing tool down).
- Build / pipeline flakiness.

**Response.** Logged for triage; next business day investigation.

**Postmortem.** Optional; judgement of investigator.

---

## Decision tree

```
Is anyone currently affected (customer or internal critical workflow)?
├── YES → Is data loss or security risk involved?
│        ├── YES → SEV1
│        └── NO  → Is service unavailable (not just degraded)?
│                 ├── YES → SEV1
│                 └── NO  → SEV2 (degradation)
└── NO  → Is the system at imminent risk (near-threshold)?
         ├── YES → SEV2 (near-miss)
         └── NO  → SEV3
```

---

## Re-classification

Severity can change as the incident evolves:

- **Up-classification.** A SEV2 that hasn't resolved in 1h and
  now has customer reports → SEV1. Incident commander decides.
- **Down-classification.** A SEV1 that's mitigated and steady →
  remains SEV1 for postmortem purposes but on-call can stand
  down.

Re-classification is logged in the incident channel.

---

## Common mis-classification

- **Internal-only outage classified SEV1.** Unless it blocks
  customer-facing work, it's SEV2 or SEV3. Most internal-only
  alerts are SEV3.
- **Single user report classified SEV1 prematurely.** Verify
  cohort before paging. One angry tweet ≠ outage.
- **Degradation classified SEV3 when sustained.** Sustained
  degradation is SEV2; only transient blips are SEV3.

---

## Per-severity SLA defaults

| Severity | Initial response | Updates cadence | Resolution target |
|---|---|---|---|
| SEV1 | 5 min | every 15 min | 1 hour |
| SEV2 | 1 hour | every 1 hour | 1 business day |
| SEV3 | next business day | as progress made | within sprint |

These are defaults; per-project SLAs in
`INSTRUCTIONS/projects/<slug>/` may differ.
