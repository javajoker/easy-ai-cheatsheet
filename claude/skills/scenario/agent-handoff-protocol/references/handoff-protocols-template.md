# Handoff Protocols — <slug>

**Version:** 1
**Locked:** YYYY-MM-DD
**Conductor:** `<agent-name>`
**Status:** active | draft | superseded

---

## Context

- Brief: [scenario-brief.md](scenario-brief.md) v<N>
- Workflow: [workflow-design.md](workflow-design.md) v<N>
- Group: [agent-group.md](agent-group.md) v<N>

---

## Transitions

### Transition 1 — Phase 1 → Phase 2

| Field | Value |
|---|---|
| Producing agent | `<agent-name>` (Phase 1 lead) |
| Receiving agent | `<agent-name>` (Phase 2 lead) |
| Artifact | `<path/to/artifact.md>` (and any sibling files) |
| Acceptance criteria | (see below — 3–6 rows) |
| Rejection procedure | (see below) |
| Escalation | `<agent-name>` (conductor) — or named human if dispute is factual |

**Acceptance criteria**

| # | Criterion | Verification |
|---|---|---|
| A1 | <criterion> | <one-line verification snippet> |
| A2 | <criterion> | `requirement-audit` against rows X1, X2 |
| A3 | <criterion> | `<file>` contains sections A, B, C |
| A4 | <criterion> | dashboard `<url>`; metric ≥ X |

**Rejection procedure**

If receiver rejects, the rejection note must:

- Name the specific gap(s) using the [rejection vocabulary](references/rejection-vocabulary.md).
- Set a re-acceptance target date.
- Be logged in the Rejection Log below.

Re-acceptance target: typically next sync or +3 business days.

**Escalation**

If producer + receiver disagree on whether criteria are met:

1. Conductor `<agent-name>` reviews.
2. If conductor cannot decide (or is one of the parties), escalate
   to <named human authority from brief>.
3. Decision is logged in this protocol's change log.

---

### Transition 2 — Phase 2 → Phase 3

(Same structure repeated.)

---

(... one section per transition ...)

---

## Sync-point transitions

For sync points where multiple parallel phases converge:

### Sync point 1 — End of Phase 3 (P2 + P3 → P4)

| Field | Value |
|---|---|
| Producing agents | `<agent-name>` (P2), `<agent-name>` (P3) |
| Receiving agent | `<agent-name>` (P4) |
| Convergence artifact | <path> — produced jointly |
| Acceptance criteria | (same shape as above) |
| Rejection procedure | If incompatible: re-spec convergence contract; one of P2/P3 reworks. |
| Escalation | Conductor confirms convergence. |

---

## Rejection log

| Date | Transition | Rejected by | Gaps named | Re-acceptance target | Outcome |
|---|---|---|---|---|---|
| (empty initially; conductor appends) | | | | | |

---

## Two-rejection rule

If any transition is rejected twice, the workflow has a structural
issue. Conductor escalates to:

1. Re-audit the producing phase's scope in `workflow-design.md`.
2. If scope is right, re-audit the acceptance criteria — are they
   appropriate for the receiver's actual need?
3. If criteria are right, re-audit the producing agent's
   capability fit — was the group formation correct?

Resolution is logged in this document's change log.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial lock | <name> |
