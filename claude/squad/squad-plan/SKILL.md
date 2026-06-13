---
name: squad-plan
description: Decompose a multi-step job into a DAG of nodes — each node a kit (or task class) + target cost tier + declared ledger inputs/outputs + a gate kind — so different sub-tasks route to different members, independent nodes run in parallel, and the whole job executes under a budget with an 80% circuit breaker. The Captain function from the reference architecture: plans, never executes; binds nodes to TIERS at plan time and resolves tiers to members via squad-route at dispatch time (late binding — a roster change re-routes the next node with no plan edit). Encodes the efficiency patterns: try-cheap-first (draft on a low tier, escalate only what fails its gate), generator+verifier pairing, deterministic gates preferred per node, and plan reuse via docs/squad/playbook/ for recurring job shapes. Use this skill when a squad request has more than one stage ("analyze X then generate Y then validate Z", "this needs extraction + coding + checking", "plan this job across the squad", "run it in parallel where possible") — single-dispatch tasks skip planning entirely and go straight to squad-route. Output is docs/squad/jobs/<job-id>/plan.md + the opened ledger. Pairs with squad-state (the ledger nodes read/write), squad-route (per-node member resolution), squad-dispatch/squad-verify (per-node execution), kit-build (nodes want kits), and task-breakdown (the in-house sibling at file/task granularity).
---

# Squad Plan

The Captain: converts a job into an execution map and **stops** —
execution belongs to the loop (`squad-route` → `squad-dispatch` →
`squad-verify` per node, conducted by `squad-lead`). Planning earns its
tokens only on multi-stage jobs; the first decision is always whether a
plan is warranted at all.

## Procedure

### Phase 0 — Is this a job or a task?

A **task** (one stage, one member, one verify) skips planning —
`squad-route` directly. A **job** has ≥2 stages with a data dependency
or a parallelism opportunity. Before drafting, check
`docs/squad/playbook/` for an approved plan of the same shape — reuse
beats re-planning (the reference docs' path-caching, made explicit and
human-approved).

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
  the *cheapest sufficient* kind: `schema` (free, automatic) →
  `deterministic` (run the code, diff the output, grep the invariant —
  free) → `in-house` (premium judgment, reserved for nodes whose
  output no mechanical check can decide).

Dependencies form the DAG; nodes with disjoint inputs run in parallel.

### Phase 2 — Apply the efficiency patterns

Shape the DAG with the squad formations from the references, as
patterns not presets:

- **Try-cheap-first.** Draft nodes target low tiers; a `fix` node on a
  higher tier exists *behind the gate* and runs only on gate failure —
  the cheap path is the happy path. (`[Cheap: draft] → gate →
  (fail) → [Expensive: fix]`.)
- **Generator + verifier split.** Where a deterministic gate exists
  (compiler, test suite, schema), pair a cheap generator with the free
  gate instead of an expensive generator with no gate.
- **Context isolation by design.** If a node "needs" most of the
  ledger, the decomposition is wrong — split or merge nodes until each
  reads narrowly.

### Phase 3 — Budget and breaker

Set the **job budget** from the routing estimates of all nodes plus
expected escalation overhead. The ledger tracks `spent_so_far`; at
**80% of cap without the end in sight, the circuit breaker trips**:
execution pauses, the user gets the state summary (verified entries,
remaining nodes, spend) and chooses — raise the cap, simplify the
remaining plan, or take the rest in-house. Hitting the breaker is a
finding for the playbook, not a failure.

### Phase 4 — Record, gate, open

Write `docs/squad/jobs/<job-id>/plan.md` — the node table, the DAG
(Mermaid), the budget, and per-node gate kinds — and open the ledger
via `squad-state`. **Gate 2 applies to the plan as a whole**: jobs
above the budget threshold, touching sensitive data, or at `ship`
stakes get explicit approval before node 1 dispatches.

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
  ladder: schema → deterministic → judgment.
- **Breaker top-ups by reflex.** The breaker pauses *to ask a human a
  real question*. "Raise it and continue" without reading the state
  summary defeats it.
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
