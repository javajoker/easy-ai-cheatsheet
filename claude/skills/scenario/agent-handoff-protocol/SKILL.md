---
name: agent-handoff-protocol
description: Defines the handoff contract between each pair of agents in a formed group — what artifact passes, what acceptance criteria the receiving agent applies, what the rejection procedure is, who escalates. Eliminates the "I assumed the other agent was handling that" failure mode. Output is handoff-protocols.md with one row per transition, plus per-handoff verification snippets the conductor runs at each transition. Use this skill after agent-group-formation has named who leads what; or when the user says "define the handoffs", "what passes between these agents", "how do I know when phase N is accepted", "set up the acceptance criteria". Pairs with agent-group-formation (upstream), with requirement-audit (acceptance criteria are auditable), with the receiving agent's AGENT.md (where the criteria often update the agent's deliverable contract), and with workflow-design (each transition is a workflow boundary).
status: shipped
owner_agent: scenario-strategist
---

# Agent Handoff Protocol

Phase 4 of the `scenario-strategist` agent. Defines the contracts
between agents in a formed group so transitions are explicit,
verifiable, and dispute-resolvable.

> **Every handoff has six fields filled in.** Producing agent.
> Receiving agent. Artifact. Acceptance criteria. Rejection
> procedure. Escalation. If a field is empty, the handoff will
> fail.

## Why this exists

Multi-agent workflows fail at handoffs more often than at the
work itself. Failure shapes:

- **Implicit handoff.** Agent A finishes a phase; Agent B doesn't
  know they were supposed to pick up. Days lost.
- **Mis-acceptance.** Agent B accepts a phase output, discovers
  three days in that the artifact doesn't meet their downstream
  need. Rework cost = days × every consumer.
- **No rejection path.** Agent B notices a gap; sends a vague
  "this doesn't work"; Agent A doesn't know what to fix.
- **Stuck dispute.** A and B disagree; no escalation path; the
  workflow stalls until a human spots it.

This skill fills in the six-field contract for every transition
in the group so none of those failures land silently.

## When to fire

Fire when:

- `agent-group-formation` has produced an `agent-group.md` and
  the next step is defining how agents pass work.
- The user says *"define the handoffs"*, *"set up the acceptance
  criteria"*, *"how do I know when X is accepted"*.
- A workflow is re-staffed (new lead means new handoff into and
  out of that phase).

Do **not** fire when:

- The workflow is single-agent (no inter-agent handoffs to
  contract).
- The handoffs are already documented in a project's INSTRUCTIONS
  (audit + reuse, don't replace).

## Inputs

Required:

- `agent-group.md` — the staffed group with leads + supporters.
- `workflow-design.md` — phase deliverables + gates (acceptance
  criteria draft from gates).
- Each agent's `AGENT.md` — the "deliverable contract" section
  is the basis for acceptance criteria.

## The procedure

### Phase 1 — Enumerate transitions

A *transition* exists between any two adjacent phases where the
lead agent changes, OR between any two parallel phases that
converge at a sync point.

From the workflow + group, enumerate every transition. Typical
count: phase-count + sync-point-count − 1.

Order transitions by occurrence in the critical path.

### Phase 2 — For each transition, fill the six fields

For every transition:

| Field | What it captures |
|---|---|
| **Producing agent** | The agent (and phase) that hands off. |
| **Receiving agent** | The agent (and phase) that picks up. |
| **Artifact** | The exact file (or set of files) that passes. Named, path-specified. |
| **Acceptance criteria** | Testable; pre-agreed; usually 3–6 rows. |
| **Rejection procedure** | What happens if rejected. Names the gaps; sets a re-acceptance target. |
| **Escalation** | Who decides if producer and receiver disagree. Usually the conductor. |

Acceptance criteria sources:

- The workflow's per-phase gate (audit / review / metric /
  decision).
- The receiving agent's `AGENT.md` deliverable contract —
  whatever the receiver needs to do its job.
- Project-specific compliance / quality requirements.

### Phase 3 — Write per-handoff verification snippets

For each acceptance criterion, write a one-line verification step:

- For audit-shaped criteria: *"`requirement-audit` against rows
  X1, X2"*.
- For metric-shaped: *"check dashboard <URL>; metric ≥ X"*.
- For artifact-shaped: *"file <path> exists and has sections
  A, B, C"*.
- For decision-shaped: *"named authority signed off in
  <doc-path>"*.

These snippets are what the **conductor** runs at every transition
in the workflow. Without them, acceptance becomes a gut-feel
operation.

### Phase 4 — Rejection procedure discipline

Every transition has a rejection procedure that:

- **Names specific gaps**, not vague dissatisfaction. (*"Missing
  the rollback section + the test plan only covers happy path"*,
  not *"insufficient"*.)
- **Sets a re-acceptance target.** *"Resubmit with gaps closed
  within 3 business days; re-audit at <next sync>"*.
- **Logs the rejection.** Goes into `handoff-protocols.md`
  rejection log; counted in the conductor's re-plan-trigger
  watch (two rejections of the same handoff = phase mis-scoped).

### Phase 5 — Escalation discipline

Every transition names an escalation authority. Default rules:

| Transition shape | Default escalation |
|---|---|
| Within scenario-strategist-conducted group | `scenario-strategist` agent (conductor) |
| Within lifecycle-pilot-conducted group | `lifecycle-pilot` agent |
| Producer + receiver disagree on factual matter | the human decision authority named in the scenario brief |
| Producer + receiver disagree on quality | conductor; if conductor is one of them, kick to human authority |

If the escalation path is itself unclear, **stop** — the group
needs re-formation with a clearer conductor.

### Phase 6 — Emit the protocols

Write `handoff-protocols.md` using
[references/handoff-protocols-template.md](references/handoff-protocols-template.md).

The document has:

- One section per transition with the six fields filled.
- The verification snippets per transition.
- A rejection log (initially empty; conductor appends as
  rejections happen).
- Cross-references back to `workflow-design.md` phases and
  `agent-group.md` agents.

After writing:

1. Surface to the user; confirm the protocols.
2. Persist as `type: project` memory (`handoff_protocols_<slug>_v1`).
3. Hand off to the conductor (`scenario-strategist` or the named
   lead) to enforce at each transition.

### Phase 7 — Protocol updates

The protocols are versioned. Update when:

- A receiving agent's deliverable contract changes (new
  acceptance criterion needed).
- A handoff is rejected twice — gaps in the producing phase or
  the acceptance criteria; re-spec.
- A sync point's contributing phases produce mismatched artifacts —
  the convergence artifact's contract was wrong; re-spec.
- A transition reveals a missing escalation path mid-execution —
  document the resolution path.

Old protocols are not deleted; status becomes `superseded` with a
pointer to the new version.

## Anti-patterns

- **Vague acceptance criteria.** *"High quality output"* fails
  the testability test. Each row is testable.
- **No rejection procedure.** Without a defined rejection path,
  rejections become arguments. Define the path.
- **Self-escalation.** A conductor who escalates to themselves is
  a stuck dispute. The escalation path must exit the dispute.
- **Acceptance "by silence".** *"If nothing is said within 24h,
  consider accepted"* hides actual disagreement. Force an
  explicit yes / no / reject-with-gaps.
- **One mega-protocol.** Each transition has its own section.
  Bundling them into one big doc means each transition is
  underspecified.
- **Acceptance criteria not derived from the receiver's needs.**
  If the criteria don't match what the receiver actually needs
  to do its job, acceptance becomes ceremony. Pull criteria from
  the receiver's AGENT.md deliverable contract.

## Companion skills

- `agent-group-formation` — upstream input.
- `workflow-design` — phase gates seed acceptance criteria.
- `requirement-audit` — verification mechanism for criteria.
- Receiving agents' AGENT.md — deliverable contracts seed
  criteria.
- `memory-ontology` — persist protocols.

## Reference files

- [references/handoff-protocols-template.md](references/handoff-protocols-template.md) —
  canonical protocols document.
- `references/acceptance-criteria-patterns.md` — common shapes
  of acceptance criteria (audit, metric, artifact, decision)
  with worked examples.
- `references/rejection-vocabulary.md` — vocabulary for
  rejection notes so they're specific not vague.
