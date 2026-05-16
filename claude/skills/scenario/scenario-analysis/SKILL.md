---
name: scenario-analysis
description: Anchors a fuzzy organisational scenario into a locked brief (goal, scope, constraints, success criteria, risks) then produces an options analysis with 2–4 weighted candidate approaches and an explicit recommendation. The brief is the artifact downstream skills + agents reference as "what we actually agreed we are doing". The options analysis exposes the trade-offs so the chosen direction is defensible six months later. Use this skill when the user describes a complex situation and asks for analysis before any single skill or agent runs ("we have this complex situation", "compare approaches to X", "build vs buy", "design the strategy", "what are our options"). Pairs with cognitive-alignment (non-negotiable upfront — vague briefs make vague analyses), with workflow-design (downstream once an option is chosen), with memory-ontology (records the decision rationale so it's not re-litigated), and with requirement-audit (the success criteria become the audit rows at the end).
status: shipped
owner_agent: scenario-strategist
---

# Scenario Analysis

Phase 1 of the `scenario-strategist` agent. Turns a vague situation
into a specific, structured brief and an honest options analysis.

> **The brief is the load-bearing artifact.** Every downstream
> decision references it. If the brief is vague, downstream work
> drifts, and the drift only becomes visible when it's expensive to
> fix. Get the brief right.

## Why this exists

Most complex scenarios fail at the *framing* step, not the
*execution* step. Predictable failure shapes:

- **Goal drift.** Three people each carry a different goal in their
  heads. The work meanders because nobody pushes back on the wrong
  thread.
- **Implicit out-of-scope.** What's out of scope is never written
  down, so out-of-scope work keeps getting requested mid-execution.
- **No success criteria.** "We'll know it when we see it" → nobody
  ever sees it; the project is declared done by exhaustion.
- **Single-option execution.** The team picks the first
  reasonable-looking approach without comparing it; six months in,
  it becomes obvious another option was better, but switching
  costs are now prohibitive.
- **Decision evaporates.** A year later, nobody remembers *why* the
  choice was made; the next leader re-litigates everything.

This skill enforces the framing discipline — brief first, options
second, recommendation third, decision recorded.

## When to fire

Fire when:

- The user describes a complex situation and asks how to approach
  it: *"we have this complex situation"*, *"compare approaches to
  X"*, *"build vs buy"*, *"should we re-architect"*, *"design the
  strategy"*.
- A workflow is about to start that spans multiple agents and the
  scope isn't pinned down.
- An option is being chosen and the trade-offs aren't documented.
- A revisit is needed because the situation has changed since the
  last brief was locked.

Do **not** fire when:

- The user's situation has an obvious single answer (let the right
  skill / agent run directly).
- The user explicitly wants execution help, not analysis ("yes I
  know the options, just help me do option B").
- The decision is unambiguous and the framing is already locked.

## Inputs

Required (gathered via conversation; not necessarily uploaded
files):

- **Situation description.** What the user is grappling with, in
  their own words.

Asked once (cap at 4 questions; offer reasonable defaults):

1. **Time horizon.** Days / weeks / months / quarters? (Changes
   which options are feasible.)
2. **Decision authority.** Who decides? (The skill produces a
   *recommendation*; the named authority decides.)
3. **Reversibility tolerance.** Are we willing to choose a path
   that's hard to back out of?
4. **Known constraints.** Budget cap, headcount, regulatory, fixed
   deadlines.

## The procedure

### Phase 1 — Cognitive alignment

Run a `cognitive-alignment` pass on the situation description.
Surface every load-bearing term. Confirm each with the user before
proceeding.

*"We need to re-platform"* has at least four load-bearing terms
(*re-platform*, *we*, *need*, the implicit *off what onto what*).
Lock them.

If alignment surfaces material disagreement among stakeholders
the user names, **stop** — escalate back to the user; an analysis
based on disagreed terminology is worse than no analysis.

### Phase 2 — Author the scenario brief

Write `scenario-brief.md` using
[references/scenario-brief-template.md](references/scenario-brief-template.md).

Required sections:

- **Goal.** One paragraph, in the user's words after alignment.
  Not a list of features; not a list of tasks. The *outcome* the
  team is aiming for.
- **Scope.** Two lists — *in* and *out*. The *out* list does the
  harder work; it's what stops scope creep.
- **Constraints.** Time, budget, headcount, regulatory, technical
  ceilings. Each with the consequence if violated.
- **Success criteria.** How will we know it worked? Each criterion
  is testable. Pre-agreed before any work starts.
- **Risks.** What could go wrong; blast radius; mitigation if any.
- **Non-negotiables.** Specific positions the team will not move
  on (regulatory, ethical, strategic). Names the things that are
  *not* trade-off-able.

After writing, **surface to the user and lock**. A locked brief
is a memory entry (`type: project`, `scenario_<slug>_brief_v1`).

### Phase 3 — Generate options

Brainstorm 2–4 candidate approaches. The skill enforces:

- **At least 2** (a single-option "analysis" is a confirmation
  bias machine).
- **At most 4** (more than four and the comparison becomes
  unreadable; you don't really have four; you have two pairs).
- **One option must include doing nothing / minimum action.**
  This is the baseline against which others justify themselves.
- **Options must be meaningfully different**, not three flavours
  of the same path.

For each option, capture:

- **Description.** One paragraph; what this option actually means
  in practice.
- **Critical assumption.** The one belief that, if wrong, makes
  this option fail.
- **Estimated time / cost / risk.** Coarse but explicit.

### Phase 4 — Score against weighted criteria

Define the criteria the user cares about. Common ones:

| Criterion | When it matters most |
|---|---|
| Time-to-delivery | Deadline-driven scenarios |
| Reversibility | High-uncertainty / experimental scenarios |
| Team capability fit | Skill-constrained scenarios |
| Ongoing operational cost | Long-lived scenarios |
| Strategic alignment | Decisions visible to leadership / board |
| Risk of failure | High-stakes / regulated scenarios |
| Customer impact | Product / GTM-related scenarios |

**Each criterion gets an explicit weight** (1–5). Don't hand-wave
"all are important" — that's how scoring becomes meaningless.
Force a ranking.

Score each option per criterion (1–5). Weighted total per option:
`sum(weight × score)`.

### Phase 5 — Pick the recommendation

The recommendation is the highest-weighted-score option *unless*
a non-quantifiable factor overrides — in which case the override
is documented as **rationale**. Numerical scoring informs; it does
not decide.

Write `options-analysis.md` using
[references/options-analysis-template.md](references/options-analysis-template.md).

Required sections:

- The scored matrix.
- The recommendation with one-paragraph rationale.
- The dissent (which option the team would pick if the
  recommendation turns out wrong, and why).
- The decision authority.
- The decision deadline.

### Phase 6 — Decision recording

After the user (or the named decision authority) picks:

1. Annotate `options-analysis.md` with the decision and
   timestamp.
2. Persist via `memory-ontology` (`type: project`, `scenario_
   <slug>_decision_v1`) with the *why* documented. This is the
   load-bearing memory that prevents re-litigation.
3. Hand off to `workflow-design` with the chosen option as input.

### Phase 7 — When to revisit

The brief is locked, but not forever. The skill emits a
**revisit-trigger list** — events that would invalidate the
analysis:

- A constraint changed (deadline shifted, budget cut, headcount
  change).
- The critical assumption of the chosen option turned out wrong.
- A non-negotiable changed (rare but happens — regulatory shift).
- A meaningfully better option emerged.

If any trigger fires, re-run this skill against the updated
situation. The old brief becomes `superseded`; the new one is
versioned (`scenario_<slug>_brief_v2`).

## Anti-patterns

- **Skipping cognitive alignment.** Every term that means
  different things to different stakeholders is a future fight.
  Lock them up front.
- **One option masquerading as analysis.** A scoring matrix with
  one option is a justification, not an analysis.
- **Implicit weighting.** "All criteria are important" → the
  highest-scored option wins by default, which means whichever
  criterion has the most rows wins. Force explicit weights.
- **Brief without success criteria.** *"We'll know it when we see
  it"* is the universal sign of a project that won't end on its
  own.
- **Out-of-scope omitted.** The *out* list is the harder list and
  the more valuable list. Don't skip it.
- **Numerical scoring as decision.** Scoring informs; humans
  decide. If the numbers say A but the org will reject A, document
  the override and pick B with rationale.
- **No decision recording.** A locked brief that lives only in
  conversation evaporates at `/compact`. Persist via memory.

## Companion skills

- `cognitive-alignment` — non-negotiable upfront.
- `workflow-design` — downstream consumer.
- `agent-group-formation` — downstream consumer.
- `memory-ontology` — persist brief + decision.
- `requirement-audit` — success criteria become audit rows.

## Reference files

- [references/scenario-brief-template.md](references/scenario-brief-template.md) —
  the canonical brief template.
- [references/options-analysis-template.md](references/options-analysis-template.md) —
  the canonical options analysis template with worked example.
- `references/scoring-criteria-catalogue.md` — common criteria
  with rationale for when each one matters most.
