---
name: agent-version-tune
description: Retune an existing agent (an AGENT.md role definition under claude/agents/<name>/) so its workflow, skill set, and deliverable contract make full benefit of a specific Claude model or Claude Code harness version — Opus 4.6, 4.7, 4.8, or the current CC harness. The agent-layer sibling of skill-version-tune; it loads the same per-version capability sheets (tune-for-opus-4-6 / -4-7 / -4-8 / tune-for-cc-harness) but applies an agent-shaped lens (parallel phases, subagent delegation, plan-mode gates, skills_used freshness, contract assumptions). Emits skill-evolution proposals targeting AGENT.md — never a silent rewrite — and, when a version makes an entirely new role viable, recommends creating one via agent-create. Use this skill when the user says "tune this agent for Opus 4.8", "modernise the devops-engineer agent for the new harness", "this agent predates subagents — update its workflow", "should any agent's phases run in parallel now", or "does the new model warrant a new agent". Pairs with agent-create (downstream — scaffold a recommended new role), skill-evolution / skill-merge (the proposal + apply loop), skill-version-tune (skill-layer sibling), and the four tune-for-* workers (the shared version lens).
---

# Agent Version Tune

The **agent-layer** member of the version-tuning family. `skill-version-tune`
keeps *skills* current with the model/harness; this keeps *agents* current.
An agent is a role: a phase workflow, a `skills_used` set, an inputs-upfront
list, and a deliverable contract. Each of those can be written against an
older baseline and miss leverage the current version offers.

> **No silent rewrites.** Like its siblings, this skill emits proposals
> under `docs/skill-evolution/` (target: `agents/<name>/AGENT.md`) and
> applies them through the same diff-preview discipline `skill-merge` uses.
> The capability sheets are layer-agnostic (a version is a version); the
> *lens* — how a capability changes an **agent's** shape — is this skill's
> contribution.

## How agents fall behind

The tells differ from a skill's:

- **Serial phases that could overlap.** An agent runs phase 2 then phase 3
  when, with harness parallelism, independent phase work could run together.
- **Inline fan-out a subagent should own.** A phase that "scans the whole
  repo / reviews every service" by hand is a subagent delegation now.
- **No checkpoint before an irreversible phase.** A migration/rollout phase
  with no plan-mode gate.
- **A stale `skills_used` set.** The agent doesn't compose newer skills that
  now exist — including version-aware ones. (An agent's skills can themselves
  be tuned: that's `skill-version-tune`, run per skill.)
- **Contract / inputs assumptions from a smaller window.** "Cap at 3
  questions because context is tight," or defensive truncation of phase
  outputs, written before compaction + a larger window.
- **A role the version newly makes viable.** Sometimes the right output is
  not a tune but a *new agent* — see Phase 3b.

## Procedure

The shape mirrors `skill-version-tune`; the differences are flagged.

### Phase 0 — Identify target agent and target version

- **Target agent:** the `agents/<name>/AGENT.md` to retune.
- **Target version:** which baseline to tune toward. Detect the running
  model from the environment if the user said "the latest"; confirm
  reachability. Model and harness are separate axes — run both workers in
  sequence if both moved (one proposal set each, attributable).

> Never tune an agent toward a version its actual runtime doesn't have.

### Phase 1 — Load the capability sheet

Read the chosen worker's `references/capabilities.md` (the same sheets
`skill-version-tune` uses). Honour the `(confirmed)` / `(inferred)`
provenance — an `(inferred)` capability ships a proposal only with its
release-note dependency named in Risks.

### Phase 2 — Agent-shaped gap analysis

Walk the agent against the **agent lens** in
`references/agent-tuning-lens.md` (the agent analogue of the dispatcher's
capability → skill-shape map). For each capability ask: *does this agent's
workflow / skills_used / contract leave it on the table, and would
exploiting it materially improve the role?*

Classify each finding as a `skill-evolution` kind, agent-flavored:

| Finding | Kind |
|---|---|
| `fires_on` / `role` should reflect a version affordance | `description` |
| A phase should change shape (parallelise, delegate to a subagent, add a plan-mode gate, relax a budget caveat) | `procedure` |
| A new failure mode the capability introduces, or a workaround it retires | `anti-pattern` |
| A reference / deliverable-contract clause should document the technique | `reference` |
| `skills_used` should gain a now-existing skill, or `companion_agents` should change | `wiring` |

Reject non-findings. An agent whose phases are genuinely sequential by
data-dependency has no parallelism finding. The lens is a sieve.

### Phase 3 — Emit proposals

One atomic proposal per finding, `skill-evolution` template, saved under
`docs/skill-evolution/<YYYY-MM-DD>-<agent-slug>-<topic>.md`, with:

- `target: agents/<name>/AGENT.md`
- `tuned-for: opus-4-8` (or `cc-harness-<YYYY-MM>`) — additive provenance.
- **Observed** cites the capability-sheet line (with its provenance tag),
  not a user turn.

### Phase 3b — Recommend a new agent (the branch)

If the gap analysis surfaces that the version enables a **whole new role**
rather than an improvement to this one — e.g. a capability makes a
previously-impractical job practical, or splits an overloaded agent into
two — **do not** force it into an AGENT.md edit. Instead, write a proposal
of kind `wiring` whose Suggested action is *"create new agent"*, and route
to **`agent-create`** with the role qualified (its Phase 1 will re-check the
"job, not a task" bar). This mirrors `agent-group-formation`'s
"create new agent" recommendation — same destination skill.

### Phase 4 — Hand off and stamp

Proposals are the deliverable; applying them is the `skill-merge`
diff-preview step (or a direct checkpointed apply for the AGENT.md). On
apply, stamp the agent's frontmatter with an additive
`tuned-for: [opus-4-8, cc-harness-2026-06]` field.

**Agent-specific downstream** (the analogue of `skill-merge` Phase 6 — apply
these when the proposal lands, because agents have wiring skills don't):

- `agents/CHECKLIST.md` — if `skills_used` changed, update the dependent-skill
  list; if status changed, update it.
- `agents/README.md` — update the table row if `role`/`focus_area` changed.
- `companion_agents` — mirror any added/removed partnership in the partner's
  AGENT.md.
- `SCENARIOS.md` — update the agent's scenario if the workflow shape changed
  visibly.

### Phase 5 — Memory hook (optional)

For a framework-wide pass ("modernise all agents for the current harness"),
write a `type: feedback` memory recording which agents were tuned for which
version, so a later session resumes the pass.

## Companion skills

| When… | Use |
|---|---|
| The finding is "this should be a NEW role" | `agent-create` (Phase 3b destination) |
| Writing / applying the proposals | `skill-evolution` / `skill-merge` |
| Tuning the agent's individual skills (not the role) | `skill-version-tune`, per skill in `skills_used` |
| Tuning the always-loaded INSTRUCTIONS the agent rests on | `instructions-version-tune` |
| Loading the version lens | `tune-for-opus-4-6` / `-4-7` / `-4-8` / `tune-for-cc-harness` |
| Re-formalising a workflow a tune reshaped substantially | `scenario-strategist` (`workflow-design`) |
| Verifying the retune landed across AGENT.md + CHECKLIST + README | `requirement-audit` |

## Anti-patterns

- **Tuning the agent when you should tune its skills.** If the gap is in a
  skill the agent composes, the fix is `skill-version-tune` on that skill —
  not a change to the agent. Tune the right layer.
- **Cargo-culting parallelism / subagents into sequential phases.** A phase
  ordered by a real data dependency must stay ordered. The lens is a sieve.
- **Forcing a new role into an AGENT.md edit.** If it's a new job, it's
  `agent-create` (Phase 3b), not a bloated tune.
- **Fabricating version deltas.** `(inferred)` stays `(inferred)`; name the
  release-note dependency in Risks.
- **Skipping the agent-specific downstream.** A tuned AGENT.md with a stale
  CHECKLIST or unmirrored `companion_agents` lies to the next group
  formation. Phase 4's downstream list is the point.

## Reference files

- `references/agent-tuning-lens.md` — the agent analogue of the
  capability → shape-change map: how each version/harness capability
  changes an agent's phases, `skills_used`, inputs, or contract — and when
  it instead means "create a new agent."
