---
name: arch-migration-plan
description: Produces a phased migration plan from a chosen target architecture, with reversible checkpoints at every phase boundary (non-negotiable), interface locks, per-phase test plans, named owners, critical path, and parallelism opportunities. Phases are 3–8 typically, each ≤2 weeks of work, each ending in a state the system can roll back to. Output is migration-plan.md with the dependency graph rendered as Mermaid and a phase-by-phase narrative the team can execute. Use this skill after arch-assessment has produced an options matrix and the user has picked a target; or when the user says "plan the migration", "break this refactor into phases", "we need a migration plan with checkpoints", "what's the order of work". Pairs with arch-assessment (consumes the chosen option), with arch-rollout-strategy (downstream — once code is migrated, rollout strategy ships it), with arch-dependency-upgrade (specialised variant for major dep upgrades), with task-breakdown (per-phase tasks decompose via that skill), with requirement-audit (every phase ends with an audit gate), and with devops-engineer agent (CI/CD + observability gates per phase).
status: shipped
owner_agent: architecture-shepherd
---

# Arch Migration Plan

Translates a chosen target architecture into a phased plan a
team can execute over weeks or months without getting stuck
mid-migration.

> **A phase that cannot be rolled back is too big — split it.**
> The reversible-checkpoint discipline is the load-bearing
> constraint of this skill. Every phase ends with a state the
> system can be rolled back to. No exceptions.

## Why this exists

Migrations without reversible checkpoints fail in predictable
ways:

1. **Sunk-cost lock-in.** Three months in, the team realises the
   target is wrong, but they're past the point of cheap reversal.
   The project completes anyway because sunk cost overrides
   judgement.
2. **One mega-phase.** "Migration sprint" ships everything at
   once; the inevitable bug surfaces in production; rollback
   means reverting weeks of work.
3. **Unowned phases.** "The team" owns Phase 3 → nobody owns
   Phase 3 → Phase 3 drifts → critical path slips.
4. **No interface locks.** Downstream consumers don't know when
   the new contract freezes; they keep depending on the old; the
   migration finishes with a separate cleanup project nobody
   funded.
5. **Tests after migration.** Verification deferred to the end;
   regressions accumulate; the final phase becomes a months-long
   stabilisation period.

This skill enforces phased decomposition with reversibility,
ownership, interface locks, and per-phase verification.

## When to fire

Fire when:

- `arch-assessment` has produced an options matrix and the user
  has chosen a target → next step is "how do we get there?".
- The user says *"plan the migration"*, *"break this into
  phases"*, *"we need a migration plan with checkpoints"*.
- A previously-stalled migration needs re-planning.

Do **not** fire when:

- No target architecture is chosen yet — run `arch-assessment`
  first.
- The change is a single-PR refactor (use language-specific
  dev skills + code review).
- The change is a *dependency upgrade* (use `arch-dependency-
  upgrade` — specialised variant of this skill).
- The user is mid-execution and just wants the next step
  surfaced (read the existing plan; surface; don't replan).

## Inputs

Required:

- `architecture-assessment.md` with a recorded decision (chosen
  option) — output of `arch-assessment`.

Asked once (cap at 4):

1. **Wall-clock target.** When does the migration need to be
   complete? Affects how many phases are feasible.
2. **Team capacity.** Engineers available; full-time vs.
   part-time on this migration.
3. **Parallel work tolerance.** Can two phases run concurrently
   (faster, coordination cost) or strict sequence (slower,
   simpler)?
4. **Hard deadlines / freeze windows.** Anything that pins
   specific dates (customer commitments, compliance dates,
   freeze windows from `devops-release-management`).

## The opinionated migration structure

### Phase count: 3–8

- **Fewer than 3** → the change is small; use a different
  mechanic (single PR, code review).
- **More than 8** → you're decomposing too finely; those should
  be *tasks* within phases.

### Phase duration: ≤ 2 weeks

Longer phases hide drift. If a phase needs more than 2 weeks,
split it.

### Per-phase required fields

| Field | Why |
|---|---|
| Name | Verb-first; short ("Extract auth tables") |
| Deliverable | The specific artifact that proves done |
| Reversible checkpoint | The state the system rolls back to if the phase fails verification |
| Owner | Named (team or individual) — never "the team" |
| Duration estimate | Weeks |
| Depends on | Prior phases (or "–") |
| Produces interface lock? | yes/no; if yes, what freezes |
| Test plan | What gets tested at the gate |
| Gate | audit / review / metric / decision (see `workflow-design`) |

### The non-negotiables

1. **Every phase has a rollback procedure** (verbatim commands,
   not gestures).
2. **Every phase has a named owner.**
3. **Every phase ends with a reversible checkpoint** — if not,
   split.
4. **Every interface lock has a notification moment** — when
   downstream consumers learn the contract has frozen.
5. **Test plan ships *with* the phase, not as a follow-up.**

## The procedure

### Phase 1 — Read the chosen option

Open `architecture-assessment.md`. Pull:

- Chosen option (and its description).
- Critical assumption (the belief that, if wrong, makes the
  option fail — this is what verification targets early).
- Addressed pain points.
- Time-to-migrate estimate (from the assessment).

If the assessment says one thing and the user expects another,
**stop** — re-align before planning. Misaligned planning
produces a plan for the wrong target.

### Phase 2 — Identify the load-bearing dependencies

What must exist before the rest can proceed? Common load-
bearing items:

- **Schema changes** — backward-compatible vs. breaking;
  breaking ones often need a multi-phase rollout.
- **Data migrations** — irreversible after cutover; need
  dedicated phase + careful checkpointing.
- **Interface contracts** — when do new APIs freeze; downstream
  notification cadence.
- **Capacity provisioning** — new infrastructure must exist
  before the migration starts.
- **Tooling / observability** — new dashboards must exist before
  cutover to verify health.

These items often become Phase 1 or 2.

### Phase 3 — Decompose into phases

Apply the structure. Common patterns:

| Migration shape | Phase decomposition starting point |
|---|---|
| Service extraction | Stand up new service (empty) → Mirror writes → Mirror reads → Cutover → Decommission old |
| Database migration | Schema change (backward-compat) → Dual-write → Backfill → Switch reads → Drop old |
| Sync → Async | Add queue infra → Producer also enqueues → Consumer reads from queue → Remove sync path |
| Major framework upgrade | Pin old + add new (compat layer) → Migrate modules → Cutover entrypoint → Remove compat layer |
| Monolith → services (per service) | Per-service extraction (Pattern 1) repeated; coordinate at sync points |

Adapt to the specifics; these are starting points.

### Phase 4 — Reversible-checkpoint discipline

For each drafted phase, ask:

- **What is the rollback procedure?** Verbatim commands.
- **What state does rollback restore?** Be specific (e.g.
  "previous container image deployed; old DB columns still
  populated; new columns dropped").
- **What does NOT rollback?** Data written via new path,
  consumer behaviour that learned about new contract, etc.

If the rollback is *"redeploy and pray"* or *"data loss is
unavoidable"*, the phase is too big. Split.

**Common non-reversibility traps:**

- DB schema changes that drop columns (split into add-new
  column → migrate reads → migrate writes → drop old).
- Data migrations with write-cutover (split into dual-write →
  backfill → switch-reads).
- API removals (split into deprecate → sunset → remove).
- Configuration changes consumers don't tolerate (split into
  add-new-config → migrate-consumers → remove-old-config).

### Phase 5 — Interface locks

Identify when each interface (API contract, DB schema, event
shape, config format) **freezes**. For each:

- **What** freezes.
- **When** in the phase sequence.
- **Who** is notified (downstream consumers — internal teams,
  external API users).
- **How** they're notified (per `arch-breaking-change-comms` if
  external; internal Slack + email otherwise).
- **Change procedure** if the lock breaks (typically:
  re-open phase; downstream impact assessment;
  conductor / lead approves resumption).

### Phase 6 — Critical path + parallelism

Draw the dependency graph (Mermaid).

- **Critical path** — longest chain. Determines wall-clock
  minimum.
- **Slack** — phases with time before critical path needs their
  output. Candidates for parallelism.
- **Sync points** — moments where parallel work must converge.
- **Risk-adjusted slack** — per `workflow-design` rules; add
  slack proportional to risk, not uniform padding.

Verify the wall-clock target is achievable. If not, options:

- Reduce scope (back to `arch-assessment` to pick a smaller
  option).
- Parallelise more (coordination cost; risk goes up).
- Add capacity (rare to be feasible mid-plan).
- Accept the slip (negotiate with decision authority).

### Phase 7 — Per-phase test plan

For each phase, document:

- **Unit / integration tests** added or updated.
- **Verification commands** run at the gate.
- **Performance benchmarks** (if perf is part of the target).
- **Smoke tests** post-deploy if the phase ships to staging /
  prod.

Test plan ships *with* the phase, not as cleanup. A phase
without test plan is an aspiration.

### Phase 8 — Emit the migration plan

Write `migration-plan.md` using
[references/migration-plan-template.md](references/migration-plan-template.md).

After writing:

1. Surface to the user with the critical path called out.
2. Confirm wall-clock + capacity feasibility.
3. Lock plan (version 1).
4. Persist as `type: project` memory (`migration_plan_<slug>_v1`).
5. Hand off:
   - `task-breakdown` to decompose Phase 1's deliverable to
     tasks the team can execute.
   - `arch-rollout-strategy` for the deployment side of each
     phase that ships to production.
   - `devops-engineer` agent for CI/CD + observability gates.

### Phase 9 — Watch for re-planning triggers

The plan is versioned, not immutable. Re-plan when:

- A phase's deliverable is rejected at its gate twice.
- A critical-path phase slips by >X% (define X up front; 20%
  default).
- A sync point's contributing phases produce incompatible
  artifacts.
- An interface lock is broken mid-phase.
- The chosen option's critical assumption proves wrong (early
  verification often catches this — when it does, revert to
  `arch-assessment` to pick a different option).

## Anti-patterns

- **Mega-phase.** A 6-week phase hides 6 weeks of drift. Split.
- **No rollback procedure.** "We'd revert the deploy" is not a
  procedure. Verbatim.
- **Implicit owner.** "The team" owns it → nobody owns it.
- **Interface lock with no notification.** Downstream consumers
  discover the freeze via broken integrations. Tell them.
- **Test plan as follow-up.** Tests deferred = regressions
  accumulated. Tests ship with the phase.
- **Uniform slack padding.** Risk-adjusted, not uniform.
- **Plan that ignores assessment's critical assumption.** The
  assumption is what could kill the option; verify it as early
  as possible in the plan — often Phase 1 includes "prove the
  critical assumption holds" as the deliverable.
- **Hand-off without context.** Each downstream skill (`task-
  breakdown`, `arch-rollout-strategy`, `devops-engineer`)
  needs the plan + relevant phase context. Don't toss artifacts
  over the wall.

## Companion skills

- `arch-assessment` — upstream input.
- `arch-rollout-strategy` — downstream (production rollout per
  phase).
- `arch-dependency-upgrade` — specialised variant for dep
  upgrades.
- `arch-breaking-change-comms` — interface lock notification.
- `task-breakdown` — per-phase task decomposition.
- `requirement-audit` — gates each phase transition.
- `devops-engineer` agent — CI / observability / runbook for
  rollout.
- `memory-ontology` — persist the plan.

## Reference files

- [references/migration-plan-template.md](references/migration-plan-template.md) —
  canonical output document.
- `references/rollback-procedure-patterns.md` — verbatim
  rollback procedures for common stack changes.
- `references/decomposition-patterns.md` — pre-worked phase
  decompositions for common migration shapes.
- `references/non-reversibility-traps.md` — catalogue of
  changes that look reversible but aren't.
