---
name: workflow-design
description: Designs the phase-by-phase workflow for a chosen scenario option — phases (3–7), per-phase deliverable + gate, critical path, parallelism, sync points. Operates at the agent level (which agents do what), not the task level (which file gets changed). Output is workflow-design.md which agent-group-formation then staffs and agent-handoff-protocol then contracts. Use this skill when the user has a brief + a chosen option and needs a plan; or when they say "design the workflow", "what phases does this have", "lay out the plan", "what's the order of work". Pairs with scenario-analysis (consumes the brief + chosen option), with agent-group-formation (downstream consumer that assigns agents), with task-breakdown (downstream consumer when a phase is concrete enough to decompose to tasks), and with requirement-audit (gates are auditable).
status: shipped
owner_agent: scenario-strategist
---

# Workflow Design

Phase 2 of the `scenario-strategist` agent. Produces an agent-level
workflow plan that other skills then staff and contract.

> **Workflow vs tasks.** `workflow-design` operates at the
> *agent* level — which roles do what, in what order, with what
> gates between them. `task-breakdown` (in `skills/ideas/`) operates
> at the *task* level — which file changes, which test gets
> written. The two compose: workflow-design's per-phase deliverable
> is often *"run task-breakdown to produce the task plan for this
> phase"*.

## Why this exists

Without an agent-level workflow plan, complex scenarios fall to one
of three failure modes:

1. **Big-bang execution.** The team starts coding without sequencing
   the dependencies. Work blocks itself.
2. **Implicit parallelism.** Two agents both think they're
   responsible for X; nobody is responsible for Y.
3. **No gates.** Phases bleed into each other; the team can't tell
   what's done from what's in-flight; nothing ever ends cleanly.

A workflow design fixes all three by enforcing explicit phases,
explicit gates, and explicit ownership *at the phase level*. The
lower-level staffing (which agent) and contracts (what passes
between agents) come next via `agent-group-formation` and
`agent-handoff-protocol`.

## When to fire

Fire when:

- The user has a locked scenario brief + chosen option (output of
  `scenario-analysis`) and asks *"now what's the plan"*.
- A multi-phase initiative needs a written plan before any
  individual agent starts work.
- A scenario has been re-planned (option changed; previous workflow
  needs to be redrawn).

Do **not** fire when:

- The scope is single-agent (no need for an agent-level workflow;
  the agent's own AGENT.md is the workflow).
- The scope is single-task (use `task-breakdown` directly, not
  this skill).
- The team already has a workflow they're executing and just wants
  audit / review (offer to *audit* with `requirement-audit`).

## Inputs

Required:

- `scenario-brief.md` — the goal, scope, success criteria.
- `options-analysis.md` with a recorded decision — the chosen
  option.

Asked once (cap at 3):

1. **Wall-clock target.** When does the chosen option need to be
   complete? (Affects how many phases are feasible.)
2. **Sequential vs parallel preference.** Some orgs prefer one
   thing at a time (clear, slow); others run in parallel (faster,
   coordination cost).
3. **Quarterly / sprint boundaries.** Do phase boundaries need to
   align with existing org rhythms?

## The procedure

### Phase 1 — Decompose the chosen option into phases

A workable phase has:

- **One coherent outcome.** Not "do everything related to X" —
  one specific accomplishment.
- **A defined deliverable.** What artifact proves the phase is
  done.
- **A defined gate.** What audit / review / approval moves us to
  the next phase.
- **Bounded duration.** ≤ a sprint (typically 2 weeks). Longer
  phases hide drift.

Phase count: typically **3–7**. Fewer than 3 means the chosen
option is too small for this skill (use direct execution). More
than 7 means you're decomposing too finely (those should be
*tasks* within phases, not phases themselves).

Default decomposition heuristics:

| Option shape | Phase decomposition starting point |
|---|---|
| Build + launch | discovery → spec → build → harden → launch → operate |
| Re-architect | assess → decide → migrate → roll-out → cut-over → deprecate |
| Enterprise initiative | scope → pilot → expand → standardise → govern |
| KB / docs build | architect → ingest → merge → publish → maintain |
| Vendor switch | evaluate → procure → integrate → migrate → decommission |

Adapt to the scenario; these are starting points, not constraints.

### Phase 2 — Per-phase deliverable + gate

For each phase, write:

- **Phase name** — short, verb-first ("Assess the auth layer").
- **Owner role** — the *role* not yet the named agent; that's
  Phase 3.
- **Deliverable** — the specific artifact that proves done.
- **Gate** — what verification moves us forward.
  - **Audit gate** — `requirement-audit` against pre-agreed rows.
  - **Review gate** — named human reviewer signs off.
  - **Metric gate** — a measured threshold (e.g. "p95 < 200ms").
  - **Decision gate** — a recorded decision from a named authority.

Gates are non-negotiable. A phase without a gate cannot be declared
done.

### Phase 3 — Critical path + parallelism

Draw the dependency graph between phases (Mermaid in the output).
Identify:

- **Critical path** — the longest dependency chain. This determines
  the wall-clock minimum.
- **Slack** — phases that have time before the critical path needs
  their output. These are candidates for parallelism.
- **Sync points** — moments where multiple parallel phases must
  converge before the next phase begins.
- **Inter-phase locks** — when one phase produces an artifact that
  freezes for downstream consumers (e.g. API contract locked at
  end of "spec" phase).

Output a Mermaid diagram + a one-paragraph narration of the
critical path.

### Phase 4 — Sync points + interface locks

For each sync point, document:

- **Which phases must converge.**
- **What artifact each phase contributes.**
- **Who confirms convergence.** (Often the conductor; see
  `agent-group-formation`.)

For each interface lock, document:

- **What freezes.**
- **When.**
- **Downstream consumers** — who depends on the frozen artifact.
- **Change procedure** — what happens if the lock needs to break
  (typically: re-open phase, downstream impact assessment).

### Phase 5 — Risk-adjusted slack

For each phase, allocate slack proportional to risk:

| Risk source | Slack rule |
|---|---|
| Critical assumption from `scenario-analysis` rides on this phase | +30% slack |
| Phase uses untested tooling | +20% slack |
| Phase requires coordination with external party | +20% slack |
| Phase has a hard external deadline | -0% slack (pull forward instead) |

Don't pad uniformly — that's a confidence-game, not a plan.
Allocate where risk lives.

### Phase 6 — Emit the workflow design

Write `workflow-design.md` using
[references/workflow-design-template.md](references/workflow-design-template.md).

After writing:

1. Surface to the user with the critical path called out.
2. Confirm the wall-clock target is achievable given the critical
   path. If not, *renegotiate* — either remove a phase, reduce
   scope (back to `scenario-analysis`), or accept the slip.
3. Persist as `type: project` memory (`workflow_<slug>_v1`).
4. Hand off to `agent-group-formation` to assign roles.

### Phase 7 — Watch for re-planning triggers

Workflows are not immutable. The skill emits a re-plan-trigger
list, and the conductor watches for them:

- A phase's deliverable is rejected at its gate twice — the phase
  is mis-scoped; re-design.
- A critical path phase slips — downstream phases re-sequence.
- A sync point's contributing phases produce incompatible
  artifacts — interface contract was wrong; re-spec.
- An interface lock is broken — downstream re-assessment required.
- The scenario brief is re-locked (`scenario-analysis` re-run) —
  workflow re-design likely.

## Anti-patterns

- **Phases that are tasks in disguise.** "Write the test for X" is
  a task, not a phase. Phases produce *artifacts* that have *gates*.
- **Gates without verification.** "We'll know when it's done"
  isn't a gate. Audit / review / metric / decision.
- **No critical path.** A workflow that doesn't name the critical
  path is a wish-list. Identify it; protect it.
- **Uniform slack.** Padding every phase by 20% is a confidence
  game. Allocate where risk lives.
- **Implicit owners.** Every phase has *one* owner role. "The team"
  is not an owner.
- **Skipping interface locks.** Phases that produce contracts (API,
  schema, taxonomy) must declare when those contracts freeze.
  Without locks, downstream work churns.
- **Workflow as tasks.** This skill operates at the agent / phase
  level. If you find yourself naming files, you've drifted into
  `task-breakdown` territory.

## Companion skills

- `scenario-analysis` — upstream input (brief + chosen option).
- `agent-group-formation` — downstream consumer (assigns named
  agents to roles).
- `agent-handoff-protocol` — downstream consumer (contracts
  between phases).
- `task-breakdown` — used *inside* a phase to decompose to tasks.
- `requirement-audit` — gates are auditable.
- `memory-ontology` — persist the workflow.

## Reference files

- [references/workflow-design-template.md](references/workflow-design-template.md) —
  canonical workflow document.
- `references/phase-decomposition-patterns.md` — worked starting
  points for common option shapes.
- `references/gate-vocabulary.md` — the four gate kinds with
  worked examples for each.
