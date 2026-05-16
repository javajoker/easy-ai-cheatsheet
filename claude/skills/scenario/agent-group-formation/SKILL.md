---
name: agent-group-formation
description: Picks the right N agents from the catalogue to staff a workflow, assigns each phase to exactly one lead agent (with any number of supporters), and names the conductor responsible for cross-phase tracking. Reads claude/agents/CHECKLIST.md at runtime to know what's shipped vs stub vs missing — does not hardcode the agent list. When a required role has no shipped agent, emits a missing row with either a "closest shipped agent + documented gap" recommendation or a "create new agent" recommendation. Output is agent-group.md ready for agent-handoff-protocol to contract. Use this skill when the user asks "which agents should handle this", "form the team", "who owns each phase", "build the group". Pairs with workflow-design (upstream — needs the phase list), with agent-handoff-protocol (downstream — defines what passes between agents), with scenario-checklist (same row format at skill granularity), and with the catalogue at claude/agents/CHECKLIST.md (source of truth for what's available).
status: shipped
owner_agent: scenario-strategist
---

# Agent Group Formation

Phase 3 of the `scenario-strategist` agent. Maps a workflow's
phases to specific agents from the catalogue with clear ownership.

> **One lead per phase.** Co-leadership means nobody is on the
> hook. Supporters support; the lead owns.

## Why this exists

A workflow without staffing assignments is a wishlist. Predictable
failures when staffing is implicit:

- **No lead.** Multiple agents touch the phase; the phase declared
  "done" by attrition rather than by a named owner saying so.
- **Wrong lead.** A phase routes to the loudest agent in the
  conversation rather than the agent whose deliverable contract
  matches the phase's gate.
- **Missing role.** A phase needs a role no agent owns; nobody
  notices until the phase tries to deliver.
- **Hardcoded staffing.** The plan names `lifecycle-pilot` because
  that's the name today; the plan rots when the catalogue
  evolves.

This skill formalises staffing — reads the catalogue fresh, assigns
leads, names supporters, identifies missing roles, names the
conductor.

## When to fire

Fire when:

- `workflow-design` has produced a locked workflow and the next
  step is to staff it.
- The user asks *"who handles each phase"*, *"form the team"*,
  *"build the agent group"*.
- A workflow is being re-staffed because an agent gap was filled
  (or one closed).

Do **not** fire when:

- The workflow is single-phase (the single phase's owner is
  obvious; no formation needed).
- The user has already named the staffing and just wants the
  conductor's protocol (skip to `agent-handoff-protocol`).
- The workflow is single-agent across all phases (just record
  that agent as lead-and-conductor; no real formation work).

## Inputs

Required:

- `workflow-design.md` — the phase list with per-phase owner role.
- `claude/agents/CHECKLIST.md` — the current agent catalogue
  status (shipped / stub / missing).

Asked once (cap at 2):

1. **Conductor preference.** Default: this agent (`scenario-
   strategist`) when the workflow spans multiple agents; the lead
   agent of Phase 1 when the workflow is mostly within one
   agent's domain.
2. **Org constraints.** Any agents that are unavailable for this
   scenario (e.g. team capacity, conflict of interest)?

## The procedure

### Phase 1 — Read the catalogue

Open `claude/agents/CHECKLIST.md`. Pull:

- Every agent with `status: shipped` (or `shipped (scaffold)`).
- Their `focus_area` from the per-agent table.
- Their declared `fires_on` triggers and `skills_used` from the
  individual AGENT.md frontmatter.

**Do not hardcode the agent list.** Read fresh each time — the
catalogue evolves; what shipped last week may have grown new
companions; what was missing may now exist.

If the catalogue is missing (no `agents/` dir or no `CHECKLIST.md`),
emit a clear error: this skill cannot form a group without an
agent catalogue. Recommend bootstrapping the agents layer first.

### Phase 2 — Match phase roles to agents

For each phase in the workflow design, the per-phase owner role
maps to one of:

| Role hint | Likely agent (current catalogue) |
|---|---|
| "build the product end-to-end" | `lifecycle-pilot` |
| "drive the launch" | `lifecycle-pilot` |
| "architectural change" | `architecture-shepherd` |
| "ops / deployment / observability / runbook" | `devops-engineer` |
| "knowledge base / enterprise docs" | `knowledge-curator` |
| "decide / plan / coordinate / form group" | `scenario-strategist` |

These mappings are *starting points*. The match is confirmed by
checking the agent's AGENT.md `fires_on` triggers — if the phase
description fits a `fires_on` line, the match is good.

### Phase 3 — Identify supporting agents

For each phase, scan the lead agent's `companion_agents` field.
Common patterns:

- A `lifecycle-pilot` phase that touches production likely needs
  `devops-engineer` as supporter (CI/CD, observability, secrets).
- An `architecture-shepherd` phase doing rollout likely needs
  `devops-engineer` for the gates.
- A `knowledge-curator` phase building a search index likely needs
  `devops-engineer` for the hosting.
- Any phase with multi-agent coordination needs `scenario-
  strategist` as background conductor.

Don't over-staff. Supporters earn their seat by being needed for
specific deliverables, not by being plausibly relevant.

### Phase 4 — Identify the conductor

The conductor is the *one* agent responsible for tracking the
workflow across phases. Their job:

- Confirm sync-point convergence.
- Watch re-plan triggers.
- Surface phase-gate failures to the user.
- Hold the handoff protocol contracts (`agent-handoff-protocol`).

**Default rules:**

- Multi-agent workflow (≥3 distinct lead agents): `scenario-
  strategist` is the conductor.
- Workflow mostly within one agent's domain: that agent's lead is
  the conductor.
- Workflow has a clear deliverable owner (e.g. lifecycle ends at
  a launch report): the deliverable's owner is the conductor.

The conductor is named in the output and persisted in memory.

### Phase 5 — Identify missing roles

If a phase's owner role doesn't fit any shipped agent:

- **Closest-fit recommendation.** Identify the shipped agent whose
  scope is nearest, name the gap explicitly, document the manual
  fallback. Mark the phase row `(gap)` so handoff protocol knows
  this phase has weaker contract verification.
- **New-agent recommendation.** Suggest a new agent (kebab-case
  name + one-line role) and add it to `claude/agents/CHECKLIST.md`
  under "Missing roles surfaced by group formation".

Do not silently route the phase to an ill-fitting agent. The gap
must be visible.

### Phase 6 — Emit the group

Write `agent-group.md` using
[references/agent-group-template.md](references/agent-group-template.md).

After writing:

1. Surface to the user; confirm the staffing.
2. Persist as `type: project` memory (`agent_group_<slug>_v1`).
3. Hand off to `agent-handoff-protocol` for the per-transition
   contracts.

### Phase 7 — Re-formation triggers

Re-run if:

- An agent is added to the catalogue that better fits a phase.
- A missing-role gap is filled (new agent shipped).
- An agent's scope shifts (its `fires_on` or `skills_used` change
  materially).
- The workflow is re-designed (`workflow-design` re-runs).

## Anti-patterns

- **Hardcoding agent names.** The catalogue evolves. Read fresh.
- **Two leads.** Co-leadership = no leadership. Pick one.
- **Empty supporter list.** Most phases have ≥1 natural supporter
  from the lead's `companion_agents`. An empty list often means
  Phase 2 was lazy.
- **No conductor.** Multi-agent workflow without a named conductor
  → sync points fail; nobody watches re-plan triggers.
- **Silent gap-routing.** Routing a phase to an ill-fitting agent
  to avoid surfacing a gap creates a downstream failure that's
  harder to diagnose than the upfront "(gap)" tag.
- **Over-staffing.** Listing five supporters for a phase means
  none of them know they're load-bearing. Cap at 2–3.

## Companion skills

- `workflow-design` — upstream input.
- `agent-handoff-protocol` — downstream consumer.
- `scenario-checklist` — same row format at skill granularity.
- `cognitive-alignment` — if role-language is ambiguous, lock it
  before staffing.
- `memory-ontology` — persist the formed group.

## Reference files

- [references/agent-group-template.md](references/agent-group-template.md) —
  canonical group document.
- `references/role-to-agent-map.md` — current mapping of common
  role hints to shipped agents (regenerate when catalogue
  changes).
