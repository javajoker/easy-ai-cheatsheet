# Risk Register Template (agent-level reference)

Used inside `arch-assessment` output and `arch-migration-plan` output.
Canonical detail in those skills.

The risk register is a structured table with the same shape across
agents (lifecycle-pilot, devops-engineer also use this shape for
their respective risk registers).

---

## Format

| # | Risk | Severity | Likelihood | Detect signal | Mitigation if it materialises |
|---|---|---|---|---|---|
| R1 | <one sentence> | high / med / low | high / med / low (within stated horizon) | <how we'd know — alert, metric, observation> | <what we'd do — verbatim where possible> |

## Severity vocabulary

- **high** — customer-visible outage, data loss, regulatory breach,
  irreversible business impact.
- **med** — degraded performance, partial functionality loss, internal
  workflow disruption, recoverable in days.
- **low** — minor inconvenience, easily reversible, isolated to small
  cohort.

## Likelihood vocabulary

Anchored to a stated time horizon (typically next 12 months):

- **high** — expected to occur within the horizon (>50% probability).
- **med** — plausible but not expected (10–50%).
- **low** — possible edge case (<10%).

## Priority derivation

`priority = f(severity, likelihood)` per this matrix:

|  | likelihood: low | med | high |
|---|---|---|---|
| **severity: high** | P2 | P1 | P0 |
| **severity: med** | P3 | P2 | P1 |
| **severity: low** | P3 | P3 | P2 |

P0 risks are addressed before declaring the migration plan locked.
P1 risks have explicit mitigation in the plan. P2/P3 risks are
monitored.

## Anti-patterns

- **Unanchored likelihood.** "Could happen" without a time horizon
  is meaningless. State the horizon.
- **No detect signal.** A risk we can't detect is a risk we can't
  mitigate. Either define the signal or accept the risk.
- **Mitigation as aspiration.** *"We'd respond"* is not a mitigation.
  Verbatim commands or a named runbook.
