# Freeze Window Examples

Pre-worked freeze-window policies for common project types. Adapt
per project.

## Project type 1 — Consumer SaaS (high-volume B2C)

| Window | Type | Rationale |
|---|---|---|
| Friday 15:00 → Monday 09:00 (local TZ) | Deploy | No weekend on-call for non-emergencies |
| Last week of each quarter | Deploy | Q-end financial reporting |
| Holiday weekends (per region) | Deploy | Skeleton on-call |
| Major customer events (e.g. Black Friday) | Deploy | Stability over velocity |

**Override authority:** VP Eng or designated on-call lead.
**Override SLA:** documented justification + on-call confirmed.

## Project type 2 — B2B Enterprise

| Window | Type | Rationale |
|---|---|---|
| Friday 15:00 → Monday 09:00 (local TZ) | Deploy | Same |
| Last week of each quarter | Deploy | Customer Q-end demos |
| Customer's go-live week | Deploy (per customer) | Don't break customer's launch |
| Holiday weeks (US + EU coverage) | Deploy | Skeleton on-call |
| Annual conferences (industry events) | Deploy | Customer attention split |

**Note:** B2B may also have **customer-specific freeze windows**
declared via account-management. Track these per-customer.

## Project type 3 — Startup MVP (early stage, pre-launch)

| Window | Type | Rationale |
|---|---|---|
| (none) | – | Velocity > stability at this stage |

**Caveat.** As soon as the product is in the hands of users, the
default consumer-SaaS or B2B-Enterprise policy applies.

## Project type 4 — Regulated industry (healthcare, finance)

| Window | Type | Rationale |
|---|---|---|
| Friday 15:00 → Monday 09:00 | Deploy | Same |
| Last week of each quarter | Code (no merges) + Deploy | Q-end regulatory reporting |
| Major regulatory deadlines | Code + Deploy | Compliance attestation periods |
| Audit windows | Deploy | Auditors are looking; don't move targets |
| Holiday weeks | Deploy | Same |

**Stricter:** code freeze (no merges to main) is more common
than in non-regulated environments.

## Project type 5 — Infrastructure / platform (internal customers)

| Window | Type | Rationale |
|---|---|---|
| Friday 15:00 → Monday 09:00 | Deploy | Same |
| All hands events / company offsites | Deploy | Internal teams reduced response |
| Major upstream events (e.g. AWS re:Invent) | Deploy | Reduce variables during cloud changes |

## Project type 6 — Open-source library (volunteer maintainers)

| Window | Type | Rationale |
|---|---|---|
| Holiday weeks | Release | Maintainer availability |
| Late Friday → Monday | Release | Avoid weekend issue floods |
| Major language ecosystem releases | Wait + test | Verify against new ecosystem version first |

---

## Emergency override

Every freeze policy has an emergency override path:

| Override class | Approval needed |
|---|---|
| Security fix (active CVE exploit) | Security lead + VP Eng |
| Customer outage with no other mitigation | Incident commander + Eng manager |
| Regulatory mandate (specific to date) | Compliance + Legal + Eng |

Overrides are **logged**:

- `docs/freeze-overrides/YYYY-MM-DD-<slug>.md`
- Captures: trigger, justification, approver, what shipped,
  monitoring during the window, retrospective.

Frequent overrides indicate the freeze policy is wrong (too
strict) or the team has a culture problem (treating overrides as
routine).

---

## Code freeze vs deploy freeze

| Code freeze | Deploy freeze |
|---|---|
| No merges to main | Merges allowed; deploys paused |
| Strictest; used in regulated environments and pre-audit | More common; allows engineering progress while pausing customer exposure |
| Implies deploy freeze | Doesn't imply code freeze |

Most projects use **deploy freeze**; only switch to code freeze
when actively preparing for audit or in regulatory hold.

---

## Anti-patterns

- **No documented freeze policy.** Each release re-negotiates.
- **Freeze policy only in someone's head.** Document or it
  doesn't exist.
- **Heroic Friday deploys.** Most often violated by senior
  engineers thinking they're the exception.
- **No emergency override path.** Real emergencies need a path;
  pretending freezes are absolute leads to unauthorised overrides.
- **Override creep.** Overrides accumulate without retrospective.
  Quarterly review of override log — if overrides exceed N per
  quarter, fix the policy.
