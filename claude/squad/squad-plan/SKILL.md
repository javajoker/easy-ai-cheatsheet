---
name: squad-plan
description: Decompose a multi-step job into a DAG of nodes — each node a kit (or task class) + target cost tier + declared ledger inputs/outputs + a gate kind — so different sub-tasks route to different members, independent nodes run in parallel, and the whole job executes under a budget with an 80% circuit breaker. The Captain function from the reference architecture: plans, never executes; binds nodes to TIERS at plan time and resolves tiers to members via squad-route at dispatch time (late binding — a roster change re-routes the next node with no plan edit). Encodes the efficiency patterns: try-cheap-first (draft on a low tier, escalate only what fails its gate), generator+verifier pairing, deterministic gates preferred per node, and plan reuse via docs/squad/playbook/ for recurring job shapes. Declares the job's verifier posture (powerful in-house by default, or common) and enforces the Situation-2 guard: a node bound to a tier more capable than the verifier must carry a deterministic results oracle or an escalating cross-validate gate, and a ship-stakes judgment-output node cannot run under a common verifier. Use this skill when a squad request has more than one stage ("analyze X then generate Y then validate Z", "this needs extraction + coding + checking", "plan this job across the squad", "run it in parallel where possible", "route the heavy reasoning to the frontier models") — single-dispatch tasks skip planning entirely and go straight to squad-route. Output is docs/squad/jobs/<job-id>/plan.md + the opened ledger. Pairs with squad-state (the ledger nodes read/write), squad-route (per-node member resolution + cross-vendor peers), squad-dispatch/squad-verify (per-node execution + gate ladder), kit-build (nodes want oracle-backed kits), and task-breakdown (the in-house sibling at file/task granularity).
---

# Squad Plan

The Captain: converts a job into an execution map and **stops** —
execution belongs to the loop (`squad-route` → `squad-dispatch` →
`squad-verify` per node, conducted by `squad-lead`). Planning earns its
tokens only on multi-stage jobs; the first decision is always whether a
plan is warranted at all.

## Procedure

### Phase 0 — Is this a job or a task? And who verifies?

A **task** (one stage, one member, one verify) skips planning —
`squad-route` directly. A **job** has ≥2 stages with a data dependency
or a parallelism opportunity. Before drafting, check
`docs/squad/playbook/` for an approved plan of the same shape — reuse
beats re-planning (the reference docs' path-caching, made explicit and
human-approved).

Inherit the **verifier posture** from the caller's `lead` mode flag
(resolved by `squad-lead`; default `powerful` when unset). The planner
does not choose it — the caller does — but it governs what nodes are
legal:

- **`powerful`** (default — `lead=powerful` / unset) — the lead/verifier
  is in-house premium Claude. Situation 1: any node tier is fine, because
  the powerful verifier can judge any member's output. Most jobs.
- **`common`** (`lead=common`) — the lead/verifier is deliberately a
  cheaper model (Situation 2: a low-cost conductor commanding powerful
  members). Legal, but it triggers the oracle guard in Phase 1: a weak
  verifier cannot certify a strong member's judgment output, so each such
  node must be carried by something objective instead.

Record the inherited posture in the plan header (`lead: powerful|common`);
it is the precondition the Phase-1 guard checks every node against. If
the caller set no flag, the header reads `lead: powerful` — never leave
it implicit.

### Phase 1 — Decompose into nodes

Each node gets:

- **`id`** and one-line purpose.
- **`kit`** — the kit it executes (preferred; precise contract +
  ratings), or a bare task class when no kit exists yet (flag it: a
  recurring node without a kit is a `kit-build` candidate).
- **`required_inputs` / `outputs`** — named ledger keys
  (`squad-state`'s hydration and merge run on exactly these). Inputs
  name *keys*, never "everything so far."
- **`target_tier`** — a cost band + capability need
  (`free-bulk`, `low-volume`, `mid-coding`, `frontier-reasoning`,
  `in-house`), **not a member name**. Members resolve at dispatch time
  against the live roster — the late binding that makes the squad
  swappable when a product moves or degrades.
- **`gate`** — what must pass before the node's delta merges, choosing
  the *cheapest sufficient* kind on `squad-verify`'s gate ladder:
  `schema` (free, automatic) → `deterministic` results oracle (run the
  code, run the tests, diff the artifact, grep the invariant, reconcile
  against source — free) → `cross-validate` (≥2 cross-vendor members
  compared — members' cost, **signal only**: passes low-stakes
  agreement, escalates disagreement or ship stakes) → `in-house`
  (premium judgment, the rung of last resort).

Dependencies form the DAG; nodes with disjoint inputs run in parallel.

#### The Situation-2 guard (verifier posture = `common`)

When the job's verifier is `common`, a node may not rely on the lead to
judge output the lead is too weak to judge. For every node whose
`target_tier` is **more capable than the verifier** (e.g. a
`frontier-reasoning` node under a common lead):

- **Verifiable-output node** → its `gate` MUST be `deterministic` (a
  results oracle bounds assurance by the oracle, not the lead). ✅
- **Judgment-output node, sub-`ship`** → its `gate` may be
  `cross-validate` (cross-vendor, escalating). ⚠️ partial — accepted for
  low stakes only.
- **Judgment-output node at `ship` stakes** → **illegal under `common`**.
  There is no oracle and consensus hides correlated error; the node's
  verify step must escalate to a powerful in-house judge. Either change
  the posture for that node (mark its `gate: in-house` and accept the
  premium verify spend) or the plan does not pass Gate 2.

A node that trips the guard with no legal gate is a **plan error**, not a
runtime failure — surface it now. The guard is why `kit-build` is
encouraged to give kits mechanically-checkable acceptance criteria:
an **oracle-backed kit unlocks common-lead routing** for its task.

### Phase 2 — Apply the efficiency patterns

Shape the DAG with the squad formations from the references, as
patterns not presets:

- **Try-cheap-first.** Draft nodes target low tiers; a `fix` node on a
  higher tier exists *behind the gate* and runs only on gate failure —
  the cheap path is the happy path. (`[Cheap: draft] → gate →
  (fail) → [Expensive: fix]`.)
- **Generator + verifier split.** Where a deterministic gate exists
  (compiler, test suite, schema), pair a cheap generator with the free
  gate instead of an expensive generator with no gate. This is also the
  *only* sound way to run a powerful generator under a common lead —
  the oracle, not the lead, is the verifier.
- **Cross-vendor critic, for judgment output without an oracle.** When a
  node produces prose/semantics that no machine can check and stakes are
  below `ship`, a `cross-validate` gate across two different vendors is a
  cheap filter — but it escalates, it does not certify (see the guard).
- **Context isolation by design.** If a node "needs" most of the
  ledger, the decomposition is wrong — split or merge nodes until each
  reads narrowly.
- **Dedup before fan-out.** In a bulk fan-out (40 configs, 14 docs),
  collapse **identical-after-normalization** inputs to one dispatch and
  fan the verified result back across the duplicates — don't pay per
  copy. Near-duplicates that differ only in a parameter are a single
  kit call with that parameter in the payload, not N calls.
- **Reuse verified results (the result cache).** Before dispatching a
  node, check `squad-state`'s verified-result cache for an identical
  kit + payload that already PASSed; a hit reuses the verified delta for
  free. This is the result-level twin of `docs/squad/playbook/` (which
  caches plan *shapes*). The caveats are load-bearing: **only verified
  results cache**, a hit still respects the input's **data class**, and a
  cache entry inherits the `(stale)` discipline when its kit re-derives.

### Phase 3 — Budget and breaker

Set the **job budget** from the routing estimates of all nodes plus
expected escalation overhead **plus the orchestration tax** — the lead's
own planning, per-node routing, and verification tokens, which on a small
job can rival the member spend. Record the job's **baseline** too (what
in-house would cost end to end): a job whose all-in (members + tax +
verify) can't beat baseline should not be planned — say so and hand it
back to in-house. That guard is the answer to the orchestration-tax
critique: the tax is budgeted, not hidden. The ledger tracks
`spent_so_far`; at **80% of cap without the end in sight, the circuit
breaker trips**:
execution pauses, the user gets the state summary (verified entries,
remaining nodes, spend) and chooses — raise the cap, simplify the
remaining plan, or take the rest in-house. Hitting the breaker is a
finding for the playbook, not a failure.

### Phase 4 — Record, gate, open

Write `docs/squad/jobs/<job-id>/plan.md` — the **verifier posture**, the
node table (with each node's tier + gate kind), the DAG (Mermaid), and
the budget — and open the ledger via `squad-state`. **Gate 2 applies to
the plan as a whole**: jobs above the budget threshold, touching
sensitive data, or at `ship` stakes get explicit approval before node 1
dispatches. A plan that fails the Situation-2 guard (a `common`-verifier
job with an unguarded frontier judgment node) does **not** reach Gate 2
— fix the gate or the posture first.

### Phase 5 — Hand off to the loop

`squad-lead` walks the DAG: ready nodes (all `required_inputs`
verified) route → dispatch → verify → merge; parallel where
independent; per-node failures run the standard escalation ladder
without re-planning the job. On completion, if the job shape is
recurring, distill the plan (with actuals) into
`docs/squad/playbook/<shape>.md` for next time.

## Anti-patterns

- **Planning ceremony for tasks.** One stage = no plan. The skill's
  first job is declining to run.
- **Early binding.** Naming members in the plan freezes yesterday's
  roster into tomorrow's execution. Bind tiers; resolve late.
- **The God node.** A node that needs the whole ledger or produces
  "the result" is the monolith you were decomposing. Narrow inputs,
  named outputs.
- **Premium gates on mechanical questions.** Asking in-house judgment
  "does this compile?" burns the tokens the layer exists to save. Gate
  ladder: schema → deterministic → cross-validate → judgment.
- **Frontier node, common lead, no oracle.** A powerful generator under
  a weak verifier with nothing objective behind it — the Situation-2
  guard exists to catch exactly this at plan time. A judgment node here
  at `ship` stakes is illegal; give it an oracle, a sub-`ship`
  cross-validate filter, or an in-house verify step.
- **Cross-validate at ship stakes.** Consensus among members is a
  filter, not a certificate — correlated error passes it. At `ship`
  stakes a `cross-validate` gate must escalate, never PASS on its own.
- **Breaker top-ups by reflex.** The breaker pauses *to ask a human a
  real question*. "Raise it and continue" without reading the state
  summary defeats it.
- **Tax-blind budgeting.** A plan whose budget counts only member spend
  hides the orchestration tax and the verify cost — the very costs that
  can make a squad job lose to in-house. Budget all-in; compare to
  baseline; decline when it can't win.
- **Re-planning on node failure.** Node failures are the ladder's job.
  Re-plan only when the *decomposition* proved wrong (a node's contract
  was unfulfillable), and say so in the plan's history.

## Companion skills

| When… | Use |
|---|---|
| Opening/operating the job's shared memory | `squad-state` |
| Resolving a node's tier to a member | `squad-route` |
| Executing + gating a node | `squad-dispatch` + `squad-verify` |
| A recurring node has no kit | `kit-build` |
| In-house decomposition at file/task granularity | `task-breakdown` (ideas/) — this skill is its cross-member sibling |
| Multi-agent (not multi-member) coordination | `workflow-design` / `agent-group-formation` (scenario/) |
