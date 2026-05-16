# Rollout Strategy — <change>

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Decision authority:** <name>
**Status:** active | draft | superseded

---

## Context

- Change being rolled out: <one paragraph; reference migration plan if applicable>
- Migration plan: [migration-plan.md](migration-plan.md) v<N>
- Wall-clock target: YYYY-MM-DD
- Customer impact tolerance: zero / low / internal-only
- Reversibility: reversible | partially | one-way (e.g. write cutover)

---

## Strategy choice

**Chosen strategy:** big-bang | blue-green | canary | dark-launch | feature-flagged

**Rationale.** <one paragraph; why this strategy, not the others>

**Cost.** <infrastructure + ops cost for the strategy>

**Risk profile.** <one paragraph; what could go wrong>

(See [strategy-decision-matrix.md](strategy-decision-matrix.md) for
default mappings of change shapes to strategies.)

---

## Sequence

| Stage | Traffic % | Duration | Approver | Notes |
|---|---|---|---|---|
| Dev | 100% | <duration> | auto | full pre-prod soak |
| Staging | 100% | <duration> | auto | smoke + load tests |
| Prod canary | 1% | 24–48h | <name> | random subset; full observability on canary |
| Prod early | 10% | 24h | <name> | gates verified |
| Prod mid | 50% | 12–24h | <name> | gates verified |
| Prod full | 100% | – | <name> | – |

---

## Metric gates per stage

Every stage transition requires **all** gates green.

| Gate | Source | Threshold |
|---|---|---|
| Error rate | dashboard `<url>` | canary err_rate ≤ 1.05× baseline |
| Latency p99 | dashboard `<url>` | canary p99 ≤ 1.10× baseline |
| SLO burn-rate | per `devops-observability` | < 6× (slow burn threshold) |
| Custom business metric | dashboard `<url>` | <e.g. conversion rate within 95% of baseline> |
| Dependency saturation | dashboard `<url>` | < 80% |

(See [gate-vocabulary.md](gate-vocabulary.md) for concrete gate
examples per metric type.)

---

## Abort conditions

### Automatic (no human in loop)

- SLO fast-burn alert: error budget burned at >14.4× over 5 min.
- Error rate >3× baseline over 5 min.
- Canary p99 latency >2× baseline over 5 min.

Pipeline auto-aborts; rollback initiated; on-call paged.

### Human-initiated

- Pattern observed by on-call (e.g. customer reports correlated
  with canary).
- Counter-metric crossing threshold while north-star is up.
- External dependency degradation that would amplify under new
  behaviour.

On-call invokes abort + rollback per the per-stage rollback
procedure.

---

## Rollback per stage

| Stage | Procedure | Duration |
|---|---|---|
| Canary | `scripts/rollback/canary-revert.sh` (drops canary to 0%) | < 5 min |
| Early | `scripts/rollback/early-revert.sh` | < 5 min |
| Mid | `scripts/rollback/mid-revert.sh` | < 10 min |
| Full | Per `devops-release-management` Mode 1 (reverse deploy) | < 15 min |

Verbatim rollback commands in `scripts/rollback/` (one script per
stage). Approver named per stage.

(See [rollback-scripts-cookbook.md](rollback-scripts-cookbook.md)
for patterns per deploy system.)

---

## Communication

| Moment | Audience | Channel | Template |
|---|---|---|---|
| Stage transition | engineering | `#deploys` | "Ramping to <%> at <time>; gates <list>" |
| Abort | engineering + on-call | `#incidents` + PagerDuty | "Aborted ramp at <stage> due to <reason>; rolling back" |
| Customer-visible incident during ramp | customers | status page | "Investigating issue with <feature>; ETA <minutes>" |
| Completion | engineering + leadership | `#announcements` | "Rolled out <change> at <time>; metrics within target" |

---

## Post-rollout

- [ ] Metrics within target at 100% for ≥1 soak period.
- [ ] No regressions reported.
- [ ] Feature flags (if any) cleaned up per `devops-release-management` policy.
- [ ] Documentation updated.
- [ ] Rollout retrospective scheduled (within 1 week).

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial | <name> |
