---
name: arch-assessment
description: Produces a structured current-state architecture assessment — services + data stores + async boundaries diagram, hot paths (SLA-critical), pain points anchored to incidents/metrics, risk register (severity × likelihood), and an options matrix of 3+ candidate target architectures with trade-offs (time, reversibility, team fit, cost). Every fact is tagged (inferred) or (confirmed) — honesty about uncertainty is non-negotiable. Output is architecture-assessment.md, the load-bearing input to arch-migration-plan. Use this skill when the user is contemplating an architectural change ("should we split this monolith", "are we on the right database", "should we move to event-driven", "do an architecture review") and needs a documented baseline before deciding what to change. Pairs with project-knowledge-base (consumes the conceptual map), with cognitive-alignment (lock load-bearing terms like service / tenant / queue), with memory-ontology (records the assessment for future architectural passes), with arch-migration-plan (downstream consumer of the chosen option), and with scenario-analysis (if the assessment surfaces an organisation-level scenario, hand off there).
status: shipped
owner_agent: architecture-shepherd
---

# Arch Assessment

Pre-decision documentation. Before any architectural upgrade is
committed to, this skill produces an honest snapshot of *what
exists today*, *what's painful*, *what the realistic options
are*, and *what the risks of each are*.

> **Understand what you have before deciding what to change.**
> The most expensive architectural failures start with skipped
> assessment.

## Why this exists

Architectural decisions made without assessment have predictable
failure shapes:

1. **Solving the wrong problem.** The team picks a target
   architecture for a problem that isn't the actual bottleneck.
   The migration completes; the original pain persists.
2. **Surprise complexity.** Three weeks into migration, the team
   discovers a system the assessment didn't catch — a hidden
   integration, an undocumented batch job, a sleeping background
   worker.
3. **Overconfidence in inferred state.** "We're event-driven" →
   actually 70% sync calls with one queue. The migration plan
   was designed for the imagined system, not the real one.
4. **Single-option execution.** Without an options matrix, the
   first reasonable architecture sticks. Six months later it's
   obvious another option was better, but switching cost is
   prohibitive.
5. **Decision evaporates.** A year later, nobody remembers *why*
   the choice was made; the next architect re-litigates
   everything.

This skill enforces an honest, structured assessment before any
decision lands.

## When to fire

Fire when:

- The user describes an architectural change they're
  considering: *"should we split this monolith"*, *"move to
  event-driven"*, *"upgrade the database major version"*, *"do
  an architecture review"*.
- A scenario-strategist scenario surfaces an architectural
  decision needing baseline analysis.
- Quarterly / annual architecture review cycle.
- Post-incident review reveals architectural fragility worth
  documenting and addressing.

Do **not** fire when:

- The change is a single-service refactor with no cross-service
  impact (use language-specific dev skills + code review).
- The team has a current assessment <6 months old (refresh
  selectively; don't re-do the whole assessment).
- The user wants the migration plan, not the assessment —
  confirm assessment is locked first, then hand off to
  `arch-migration-plan`.

## Inputs

Required:

- Repo access (read-only — assessment does not modify code).
- `INSTRUCTIONS/projects/<slug>/project-context.md` — stack +
  conventions.

Recommended:

- `project-knowledge-base` output if it exists — saves
  re-discovering the conceptual model.
- Recent incident postmortems — anchor pain-point findings.
- Production observability dashboards — anchor hot-path
  findings.

Asked once (cap at 4):

1. **Scope.** Whole system / specific service / specific concern
   (e.g. just the data layer).
2. **Triggering concern.** What prompted the assessment?
   Performance? Cost? Team capability? Compliance? Roadmap
   change?
3. **Decision authority.** Who picks the target architecture
   after the assessment lands.
4. **Time available for assessment.** Days / weeks — drives how
   deep the inferred-vs-confirmed pass goes.

## The opinionated assessment structure

Five sections; always in this order.

### 1. Current-state diagram

A diagram (Mermaid or PlantUML — renderable) showing:

- **Services** (each box: service name, language, owning team).
- **Data stores** (databases, caches, queues, blob storage,
  search indexes).
- **Async boundaries** (queues, event buses, scheduled jobs).
- **External integrations** (third-party APIs, identity providers,
  payment processors, observability vendors).
- **User entry points** (web, mobile, API, admin).

Use distinct shapes / colours for service / data / async /
external — readers should be able to scan the diagram and parse
the topology in 30 seconds.

### 2. Hot paths

The paths that matter for SLAs and business outcomes. For each:

- **Path name** (e.g. "Signup → first session").
- **Traversed components** in order.
- **SLA target** (latency, throughput, availability).
- **Current performance** (real numbers from observability).
- **Failure mode if path degrades** (business impact).

Typically 3–7 hot paths per system. Order by criticality.

### 3. Pain points

What hurts about the current architecture *today*. Each pain
point:

- **Symptom** in plain language.
- **Anchor** — incident, metric, support ticket pattern, or
  developer-survey quote. Anonymous "we feel slow" doesn't
  count.
- **Affected component(s)**.
- **Cost of doing nothing** — operational, business, or team-
  velocity impact.

This section drives the options matrix later; without specific
pain, the matrix has no criteria to optimise.

### 4. Risk register

Risks of the *current* architecture if no change happens. Per
risk:

- **Risk** (one sentence).
- **Severity** (high / med / low — what happens if it occurs).
- **Likelihood** (high / med / low — over the next 12 months).
- **Detect signal** (what would tell us the risk is materialising).
- **Mitigation if it materialises** (what we'd do).

Severity × likelihood gives the priority. High × high is
top-priority; low × low is acceptable.

### 5. Options matrix

**3+ candidate target architectures.** Each with:

- **Name** (e.g. "Split into auth + core services").
- **Description** (one paragraph; what this option means in
  practice).
- **Addresses which pain points** (from §3) — explicit map.
- **Time-to-migrate estimate** (weeks).
- **Reversibility** (high / med / low — can we back out cheaply
  if it turns out wrong).
- **Team capability fit** (high / med / low — do we have the
  skills).
- **Operational cost change** (% delta).
- **Risk profile** (one paragraph; what could go wrong).
- **Critical assumption** (the one belief that, if wrong, makes
  this option fail).

Always include **Option 0 — do nothing / minimum action** as the
baseline. The other options justify themselves against it.

## The inferred-vs-confirmed discipline

This is the load-bearing discipline of the whole skill.

Every fact in the assessment is tagged:

- `(confirmed)` — verified against code, docs, observability,
  or named source. Citation required.
- `(inferred)` — best guess based on partial evidence. Marked
  for verification.

**An assessment with no `(inferred)` tags is suspicious** — it
means either the system is fully documented (rare) or the
assessor isn't being honest about uncertainty.

After the assessment is drafted, the user (or named expert)
walks through the `(inferred)` tags and either confirms them
(promotes to `(confirmed)` with citation) or corrects them.
This walkthrough is when the assessment gains its real value —
the documented knowledge transfer.

## The procedure

### Phase 1 — Read the obvious

Open without making the user answer questions yet:

- README.md.
- Architecture docs under `docs/architecture/` if any.
- `INSTRUCTIONS/projects/<slug>/`.
- `project-knowledge-base/` output if exists.
- Top-level package manifests (declares stack).
- Compose / k8s / Terraform files (declares topology).
- CI config (declares deploy paths).

This produces a first-draft current-state diagram with most
boxes `(inferred)`.

### Phase 2 — Cognitive alignment

Run `cognitive-alignment` on the load-bearing terms surfaced:
*service*, *tenant*, *queue*, *region*, *cluster*, *event* —
each carries hidden assumptions. Lock them.

If the user uses terminology the codebase doesn't (or vice
versa), the gap is itself a finding.

### Phase 3 — Confirm topology

Walk the user (or a named expert) through the draft diagram.
For each `(inferred)` box / edge:

- Confirm → promote to `(confirmed)` + citation.
- Correct → update; tag what was wrong.
- "Don't know" → leave `(inferred)`, flag for follow-up
  research.

### Phase 4 — Identify hot paths

From the diagram + observability data + user input:

- Which paths see the most traffic / value?
- Which paths have explicit SLAs?
- Which paths break first when something goes wrong?

Document each hot path per §2 above.

### Phase 5 — Surface pain points

Pull pain anchors from:

- Recent incident postmortems.
- Persistent slow-query alerts.
- Recurring support ticket patterns.
- Recent eng-team retro themes.
- Stakeholder interviews.

Don't accept anonymous pain; anchor every entry.

### Phase 6 — Build the risk register

Brainstorm what would happen if no change is made:

- Scaling limits (when does the current architecture hit a wall).
- Failure modes (single points of failure).
- Team / knowledge risks (bus-factor-1 components).
- Compliance / regulatory shifts.
- Cost-curve risks (when does ops cost become unsustainable).

Each risk gets severity × likelihood + detect signal +
mitigation.

### Phase 7 — Generate options

Generate 3+ options. Discipline:

- **One must be Option 0 (do nothing).** This is the baseline.
- **At least 2 must be meaningfully different paths** (not
  three flavours of the same migration).
- **Each option maps to specific pain points** — options that
  don't address pain are decorative.
- **Each option names its critical assumption** — the belief
  that, if wrong, makes the option fail.

### Phase 8 — Emit the assessment

Write `architecture-assessment.md` using
[references/assessment-template.md](references/assessment-template.md).

After writing:

1. Surface to the user; walk through `(inferred)` tags.
2. Lock the assessment (version 1).
3. Persist as `type: project` memory (`arch_assessment_<slug>_v1`).
4. Hand off to:
   - User (or named decision authority) for option selection.
   - `arch-migration-plan` once an option is chosen.
   - `scenario-strategist` if the assessment reveals
     organisation-level scope (not just architecture).

### Phase 9 — Decision recording

After the user picks an option, append to the assessment:

- **Chosen option** + date + decision authority.
- **Rationale** (one paragraph).
- **Override-of-recommendation** if applicable (if the user
  picked something other than the highest-scored option,
  document why).

Persist the decision via `memory-ontology` (`arch_decision_
<slug>_v1`).

## Anti-patterns

- **No `(inferred)` tags.** The assessor wasn't honest about
  uncertainty. The assessment is worth less than it looks.
- **Diagram-only assessment.** A diagram without pain points,
  risks, and options is a pretty picture, not a decision input.
- **Pain without anchors.** "We feel slow" is not pain; it's
  vibes. Anchor everything.
- **Two options.** Two options = "the option I want vs. the
  straw-man". Force three.
- **Skipping Option 0.** Without a do-nothing baseline, every
  option looks worth doing. The cost of inaction is often the
  real story.
- **Decision before walkthrough.** Locking the assessment
  before the user reviews `(inferred)` tags means the
  walkthrough was skipped; the assessment is brittle.
- **Recommendation == decision.** This skill recommends; the
  user (decision authority) decides. Document override
  rationale if the user picks differently.

## Companion skills

- `project-knowledge-base` — consumes the conceptual map.
- `cognitive-alignment` — non-negotiable upfront.
- `memory-ontology` — record assessment + decision.
- `arch-migration-plan` — downstream consumer.
- `arch-rollout-strategy` — downstream (rolling out the chosen
  option).
- `arch-breaking-change-comms` — if the chosen option breaks
  consumers.
- `scenario-strategist` — if scope exceeds pure architecture.
- `requirement-audit` — assessment goals become later gates.

## Reference files

- [references/assessment-template.md](references/assessment-template.md) —
  canonical output document.
- `references/diagram-conventions.md` — Mermaid / PlantUML
  conventions for the current-state diagram.
- `references/pain-anchor-vocabulary.md` — what counts as an
  anchor (vs. anonymous gripe).
- `references/options-criteria-catalogue.md` — common criteria
  for scoring options.
