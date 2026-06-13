---
name: eval-run
description: Execute an approved eval spec against named squad members and turn the results into (measured) evidence — dispatch each golden task through squad-dispatch (the same sandbox/caps/transcript path as real work), score returns in-house against the spec's rubric, write one scorecard per member under docs/squad/evals/<task-class>/, and propose the member-sheet + ROSTER.md updates as a human-approved diff (Gate 4) with evaluated: <task-class>@<member-version> stamps for idempotency. Use this skill when the user says "run the eval", "evaluate <members> for <task class>", "score gemini-cli on translation", "re-run the stale evals", or when squad-route hits an unrated pair the user wants rated. Requires an approved eval-spec (runs eval-design first if missing). Scoring is always in-house — never ask a member to grade itself or a peer. Pairs with eval-design (the spec), squad-dispatch (the invocation path), squad-verify (shared scoring format), member-retune (queues targeted re-runs), and memory-ontology (multi-session eval passes).
---

# Eval Run

Turns an approved spec into ratings. The deliverables are scorecards
(per member), `(measured)` lines on member sheets, rating moves in
ROSTER.md, and the idempotency stamps that stop the next run from
re-measuring what hasn't changed.

## Procedure

### Phase 0 — Preconditions

- An approved `docs/squad/evals/<task-class>/eval-spec.md` exists (else
  run `eval-design` — its Gate 1 must close first).
- Each named member has a working invocation contract (smoke-tested at
  onboarding) and its sheet's data-handling covers the fixtures' data
  class (specs default to `public`-class fixtures for exactly this
  reason).
- Check each member's `evaluated:` stamps: a member already stamped
  `<task-class>@<current member_version>` is skipped unless the user
  says re-run — idempotency mirrors `tuned-for:` in the maintenance
  layer.

### Phase 1 — Dispatch the golden tasks

Every task goes through [`squad-dispatch`](../squad-dispatch/), not a
bare CLI call: sandbox, cost cap, timeout, transcript. This is
deliberate — the eval thereby also measures the three things vendor docs
never tell you: **invocation reliability** (did calls fail/hang?),
**latency**, and **actual cost**. Record all three per task alongside
the output. Dispatch failures score the task FAIL with the failure noted
(a member you can't reliably call is not capable, whatever its output
quality).

### Phase 2 — Score in-house

Score each return against the spec's rubric — PASS/PARTIAL/FAIL with
evidence per row, `requirement-audit` style. Scoring is **in-house,
always**: a member never grades itself or a peer (that would route
trust through the thing trust is being established for). Prefer the
spec's mechanical checks (diffs, greps, test runs) and quote their
output as evidence.

### Phase 3 — Write the scorecards

One per member: `docs/squad/evals/<task-class>/<member>-<date>.md` —
per-task rows, the totals, latency/cost/reliability observations, and a
**rating recommendation** with its reasoning:

| Result shape | Recommended rating |
|---|---|
| All PASS incl. traps, clean reliability | A |
| Solid PASS majority, traps passed, fixable PARTIALs | B |
| Trap failures or weak majority | C |
| Reliability failures or FAIL majority | stay U (and say what would change it) |

Ratings follow the trap tasks more than the totals: a member that fails
traps produces plausible-wrong output, which is the most expensive kind
to verify.

### Phase 4 — Land the evidence (Gate 4)

Propose as one reviewable diff:

- Member sheet: `(measured)` capability lines citing the scorecard; the
  eval-history row; the `evaluated: <task-class>@<member_version>` stamp.
- ROSTER.md: the rating cell, citing the scorecard. `(stale)` suffixes
  cleared if this was a re-measurement.

User approves; it lands. If the pass spanned sessions or more members
remain, write a `memory-ontology` note recording where the pass stopped.

## Anti-patterns

- **Self-grading.** Asking the member (or another member) to score
  outputs corrupts the only evidence chain the layer has.
- **Bare-CLI dispatch.** Skipping `squad-dispatch` for evals loses the
  reliability/latency/cost measurements and tests a path real work won't
  use.
- **Rating generosity.** "It almost passed the trap" is a C. The rubric
  decided before the run; apply it as written.
- **Stamp skipping.** Landing ratings without `evaluated:` stamps makes
  every future run a full re-run — the idempotency is the point.
- **Cherry-picking.** All tasks in the spec run and all results land in
  the scorecard, including the embarrassing ones.

## Companion skills

| When… | Use |
|---|---|
| No spec exists yet | `eval-design` |
| Invoking the golden tasks | `squad-dispatch` |
| The scoring row format | `squad-verify` / `requirement-audit` |
| A version change queued this re-run | `member-retune` |
| The pass spans sessions | `memory-ontology` |
