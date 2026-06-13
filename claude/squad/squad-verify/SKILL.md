---
name: squad-verify
description: The acceptance gate between a squad member's output and the repo (Gate 3) — audit the dispatch return in-house against the acceptance criteria fixed before routing, in requirement-audit PASS/PARTIAL/FAIL format with evidence per row; PASS integrates from the sandbox, PARTIAL integrates only with gaps explicitly accepted by the user, FAIL drives the escalation ladder (one retry with named gaps → next-ranked member → in-house) — and the outcome feeds the ledger and, when it contradicts ROSTER.md, a rating-feedback proposal (Gate 4). Use this skill whenever a dispatch record awaits judgment ("verify what came back", "is the squad output good", squad-lead step 4), and for scoring eval returns (eval-run phase 2 borrows this format). Verification is always in-house — the premium tokens this layer deliberately spends — and verify depth scales with the member's rating: A verify-light (spot checks), B/C full. Pairs with squad-dispatch (upstream record + quarantined sandbox), squad-route (the next-ranked fallback), requirement-audit (the row format), and ROSTER.md (rating feedback).
---

# Squad Verify

The gate that makes delegation safe. The layer's bargain is: generation
goes to cheap members, **verification stays in-house** — that spend is
the product, not overhead. Nothing crosses from sandbox to repo without
this skill's PASS.

## Procedure

### Phase 0 — Load the contract

From the dispatch record: the acceptance criteria (fixed at classify
time, *before* routing — if they're missing or were edited after
dispatch, stop; that's a process failure to surface, not to paper over),
the sandbox location, and the member's rating (it sets verify depth).

### Phase 1 — Audit

`requirement-audit` format — one row per criterion, verdict + evidence:

- **Mechanical checks first**: diffs, greps, builds, test runs against
  the sandbox. Cheap, repeatable, quotable.
- **Judgment checks second**, reading only as much as the depth requires:
  - **A-rated member:** verify-light — run all mechanical checks, spot
    check judgment criteria (sample, don't read everything).
  - **B/C-rated:** full — every criterion checked.
  - Tighten sampling around the member's *known* weak spots — the
    scorecard's PARTIAL/trap rows say where to look (see EXAMPLES.md
    Example 2).
- Hunt the **plausible-wrong** specifically: output that reads well and
  is subtly wrong (asserting buggy behaviour, inverted negation,
  translated brand term). That's the failure mode external delegation
  imports.

### Phase 2 — Verdict and gate (Gate 3)

- **PASS** — integrate from the sandbox (now it's allowed), note any
  trivial fixes made in-house in the report.
- **PARTIAL** — surface the gap rows; integrate **only** what the user
  explicitly accepts; the rest follows the FAIL path.
- **FAIL** — nothing integrates. Escalation ladder, in order:
  1. **One retry** to the same member, with the failed rows quoted as
     named gaps in the new prompt. One. Per member, per task.
  2. **Next-ranked member** from the routing decision's fallback —
     weighing whether its verify-plus-likely-fix cost still beats
     in-house at this point.
  3. **In-house.** Salvage verified-PASS portions of the rejected work —
     never pay twice for passing rows.

### Phase 3 — Close the loop

- Write the verification report into the dispatch record; fill the
  ledger line's outcome + escalation count.
- **Rating feedback:** if the outcome contradicts the roster (an A
  failing at its stakes level; a C quietly acing full verifies), append
  the event to the member's rolling record, and when the roster's
  demotion/promotion rule trips (two failures / sustained passes),
  propose the move as a Gate 4 diff citing this report.

## Anti-patterns

- **Outsourced verification.** A member checking its own or a peer's
  work re-imports the exact risk the gate exists to stop. In-house,
  always.
- **Criteria drift.** Relaxing a criterion because the output "is fine
  really" — if the criterion was wrong, fix it for the *next* task,
  visibly; this task is judged by the contract it was dispatched under.
- **Verify-none for A-members.** A-rated buys lighter sampling, never
  zero. Mechanical checks always run.
- **Ladder skipping or looping.** Straight-to-in-house wastes the retry
  that usually lands; multiple retries to the same member is the
  unbounded-cost hole the ladder exists to cap.
- **Swallowing the outcome.** A verify that doesn't land in the ledger
  and the rolling record leaves routing exactly as smart as before.

## Companion skills

| When… | Use |
|---|---|
| The record + sandbox under judgment | `squad-dispatch` |
| Picking the fallback on escalation | `squad-route` |
| The audit row format | `requirement-audit` |
| Rating moves the feedback proposes | ROSTER.md update discipline (Gate 4) |
