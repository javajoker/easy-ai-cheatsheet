---
name: squad-verify
description: The acceptance gate between a squad member's output and the repo (Gate 3) — audit the dispatch return against the acceptance criteria fixed before routing, via a gate ladder (cheapest sufficient first) schema → deterministic results oracle → cross-validate (cross-vendor, signal-only) → in-house judgment, in requirement-audit PASS/PARTIAL/FAIL format with evidence per row; PASS integrates from the sandbox, PARTIAL integrates only with gaps explicitly accepted by the user, FAIL drives the escalation ladder (one retry with named gaps → next-ranked member → in-house) — and the outcome feeds the ledger and, when it contradicts ROSTER.md, a rating-feedback proposal (Gate 4). Use this skill whenever a dispatch return awaits judgment ("verify what came back", "is the squad output good", squad-lead step 5), and for scoring eval returns (eval-run phase 2 borrows this format). The required verifier power is set by the task class, not by choice: verifiable-output tasks (code/data/anything runnable) can be certified by a deterministic oracle even under a common lead (Situation 2); judgment-output tasks at ship stakes always need a powerful in-house judge. Cross-validation is a signal that escalates disagreement — never an integration decision (no member self-certifies into the repo or the State Ledger). Verify depth on the judgment rung scales with the member's rating: A verify-light (spot checks), B/C full. Pairs with squad-dispatch (upstream record + quarantined sandbox), squad-route (the next-ranked fallback + cross-validation peers), requirement-audit (the row format), squad-plan (the per-node gate kind), and ROSTER.md (rating feedback).
---

# Squad Verify

The gate that makes delegation safe. The layer's bargain is: generation
goes to cheap members, **the verifier is the one node whose quality is
non-negotiable** — assurance is bounded by the verifier, not the
generator. Nothing crosses from sandbox to repo, and no delta merges
into the State Ledger, without this skill's PASS.

The verifier is **in-house (premium Claude) by default** — that spend is
the product, not overhead. The one principled way to relax that (so a
*common* lead can certify a *powerful* member's output — Situation 2) is
to move the decision onto a **deterministic results oracle**, which
bounds assurance by the oracle instead of by the lead. That option is
real but task-class-limited — see "When the lead is common" below.

## The gate ladder

Climb only as far as the cheapest rung that can actually *decide* the
criterion. Each rung up costs more; most criteria are settled before the
top.

1. **`schema`** (free, already run at dispatch) — the return parsed and
   matched the kit's output schema. Structural, not semantic.
2. **`deterministic` / results oracle** (free) — *run the result and
   check the outcome*: compile, execute the test suite in the sandbox,
   diff against an expected artifact, grep an invariant, reconcile
   extracted numbers against the source. This is **blackbox
   results-oriented** verification: it never reads the member's
   reasoning, so the *oracle's* power bounds assurance, not the lead's.
   The oracle must be **generator-independent** (the member never writes
   the tests it is graded by — that is self-grading) and **trap-covered**
   (passing ≠ correct if coverage is thin; a powerful member will
   Goodhart a weak oracle).
3. **`cross-validate`** (members' cost — signal only) — when no oracle
   exists, dispatch the same task to ≥2 **cross-vendor** members and
   compare. See the next section: it is a *filter*, not a verdict.
4. **`in-house` judgment** (premium) — the rung of last resort, for
   criteria no machine can decide. Depth scales with the member's
   rating:
   - **A-rated member:** verify-light — run all mechanical checks, spot
     check judgment criteria (sample, don't read everything).
   - **B/C-rated:** full — every criterion checked.
   - Tighten sampling around the member's *known* weak spots — the
     scorecard's PARTIAL/trap rows say where to look (see EXAMPLES.md
     Example 2).

Across all rungs, hunt the **plausible-wrong** specifically: output that
reads well and is subtly wrong (asserting buggy behaviour, inverted
negation, translated brand term). That is the failure mode external
delegation imports, and the one consensus is worst at catching.

## Procedure

### Phase 0 — Load the contract

From the dispatch record: the acceptance criteria (fixed at classify
time, *before* routing — if they're missing or were edited after
dispatch, stop; that's a process failure to surface, not to paper over),
the sandbox location, the member's rating (it sets judgment-rung depth),
and the node's declared `gate` (the planned rung — `squad-plan` sets it;
this skill may climb higher but never silently lower).

### Phase 1 — Audit

`requirement-audit` format — one row per criterion, verdict + evidence —
walking the gate ladder above per criterion: settle on `schema` /
`deterministic` where you can, escalate to `cross-validate` /
`in-house` only for criteria the cheaper rungs can't decide.

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

## Cross-validation (the signal-only rung)

When no results oracle exists and you want to *reduce how often the
premium judge is needed*, dispatch the same task to **≥2 cross-vendor
members** and compare returns. The rules that keep it honest:

- **It reduces variance, not bias.** Cross-validation catches
  *uncorrelated* (random) errors and is blind to *correlated* (shared
  blind-spot) ones. Two frontier models that share training data can be
  confidently wrong *together*; their agreement is not proof of
  correctness. So it is a filter, never a certificate.
- **Decorrelation is mandatory.** Peers must be **different vendors**
  (the roster's OpenAI / Google / local spread is the substrate). Two
  instances of the same model is theatre — `squad-route` selects
  cross-vendor peers or the rung does not apply.
- **The verdict is a signal, with exactly two legal effects:**
  1. **High agreement + sub-`ship` stakes** → may **PASS** the row
     (cheap path for low-stakes judgment output).
  2. **Disagreement, OR `ship` stakes, OR any node where members had the
     same input and could share a blind spot** → **escalate** the row to
     the deterministic oracle (if one exists) or to in-house judgment.
- **It never integrates by itself.** A peer-agreement PASS still flows
  through Gate 3; a member's verdict can pass low-stakes output or
  escalate the hard case, but it can **never** be the reason a delta
  merges into the State Ledger or the repo at `ship` stakes. That bright
  line preserves the self-grading prohibition.
- **Cost reality:** cross-validation is K× the member spend. For
  verifiable output, a free deterministic oracle is both safer *and*
  cheaper — prefer it. Reach for cross-validation only when no oracle
  exists.

## When the lead is common (Situation 2)

If the conductor/verifier is deliberately a *cheaper* model (Situation 2
— common lead, powerful members), the verifier-power requirement does
not disappear; it is **set by the task class**:

| Task shape | Who can certify it | Common lead OK? |
|---|---|---|
| **Verifiable output** (code, data, anything runnable) | A deterministic results oracle | ✅ — the oracle bounds assurance, the lead just runs it |
| **Judgment output, sub-`ship`** | Cross-validation (cross-vendor) as a pass-filter | ⚠️ partial — uncorrelated errors only |
| **Judgment output, `ship`** | A powerful in-house judge — nothing weaker | ❌ — the verify step must revert to a powerful judge |

The honest limit: you can make the *generator* anything, but the
*verifier's* required power is fixed by what the task is. A common lead
is sound exactly when a results oracle (or a low-stakes cross-validation
filter) carries the decision — and unsound the moment a `ship`-stakes
judgment call has no oracle behind it. `squad-plan` enforces this at
plan time (it blocks a frontier-tier node under a common-lead job unless
the node carries an oracle or an escalating cross-validate gate); this
skill enforces it at verify time (a `ship`-stakes judgment row never
settles on `schema`/`deterministic`/`cross-validate` alone).

## Anti-patterns

- **Consensus mistaken for correctness.** "Three models agreed" is a
  signal, not a certificate — they may share the same blind spot. At
  `ship` stakes, agreement *escalates*, it does not pass.
- **Self- or peer-grading as the gate.** A member checking its own or a
  peer's work *as the integration decision* re-imports the exact risk
  the gate exists to stop. Peer agreement may filter low-stakes output
  or escalate the hard case; it never merges a delta by itself.
- **Member-authored oracle.** A results oracle the member wrote (its own
  tests) is self-grading wearing a deterministic costume. The oracle is
  authored in-house or by the kit.
- **Climbing past the deciding rung.** Asking in-house judgment "does
  this compile?" when the sandbox already answered burns the tokens the
  layer exists to save. Settle each criterion on the cheapest rung that
  can decide it.
- **Common lead on a ship-stakes judgment call.** A cheap verifier
  certifying a powerful member's prose/semantics at `ship` stakes with
  no oracle behind it — the one configuration the verifier-power table
  forbids. Escalate the verify step to a powerful judge.
- **Criteria drift.** Relaxing a criterion because the output "is fine
  really" — if the criterion was wrong, fix it for the *next* task,
  visibly; this task is judged by the contract it was dispatched under.
- **Verify-none for A-members.** A-rated buys lighter sampling on the
  judgment rung, never zero. The oracle/schema rungs always run.
- **Ladder skipping or looping.** Straight-to-in-house wastes the retry
  that usually lands; multiple retries to the same member is the
  unbounded-cost hole the ladder exists to cap.
- **Swallowing the outcome.** A verify that doesn't land in the ledger
  and the rolling record leaves routing exactly as smart as before.

## Companion skills

| When… | Use |
|---|---|
| The record + sandbox under judgment | `squad-dispatch` |
| Picking the fallback on escalation, and cross-vendor peers | `squad-route` |
| The per-node planned gate kind (incl. the common-lead oracle guard) | `squad-plan` |
| The audit row format | `requirement-audit` |
| Rating moves the feedback proposes | ROSTER.md update discipline (Gate 4) |
