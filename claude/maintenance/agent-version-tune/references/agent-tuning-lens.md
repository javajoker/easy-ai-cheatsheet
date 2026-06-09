# Agent Tuning Lens

The agent analogue of `skill-version-tune/references/version-matrix.md`'s
"capability → skill-shape change" table. The **workers** (`tune-for-*`) say
what a version can do and tag provenance; this lens says what that means for
an **agent's** shape — its phases, `skills_used`, inputs-upfront, and
deliverable contract.

> Every row is conditional: "if the agent does X and the version offers Y,
> propose Z." Not every row applies to every agent. A row is a *finding*
> only when the "if" genuinely matches **and** the payoff is concrete. The
> lens is a sieve, not a stamp.

## Capability → agent-shape change

| If the agent currently… | …and the version offers… | …propose (kind) |
|---|---|---|
| Runs phase N then phase N+1 when the two share no data dependency | Parallel tool calls / concurrent work (harness, `confirmed`) | Mark the phases as parallelisable; note the sync point where they rejoin (`procedure`) |
| Has a phase that scans the whole repo / reviews every service inline | Subagents via the Agent tool (harness, `confirmed`) | Delegate the fan-out phase-step to an `Explore`/`general-purpose` subagent above a size threshold (`procedure`) |
| Has an irreversible phase (migration cutover, prod rollout) with no checkpoint | Plan mode (harness, `confirmed`) | Add a plan-mode gate before the irreversible phase (`procedure`) |
| Blocks a phase on a long build / test / deploy watch | Background tasks (harness, `confirmed`) | Run it in the background; the phase reacts on completion (`procedure`) |
| Caps inputs-upfront defensively ("max 3 questions, context is tight") or truncates phase outputs | Larger window + context compaction (harness `confirmed` / model `inferred`) | Relax the caveat; lean on compaction; cross-link `compact-ritual` (`procedure`) |
| `skills_used.shipped` omits a skill that now exists for one of its phases | Skill system (harness, `confirmed`) | Add the skill to `skills_used`; reference it by role (`wiring`) |
| Composes skills that are themselves behind on the model/harness | Any version capability | Don't edit the agent — run `skill-version-tune` on those skills (note as a follow-up, not an agent proposal) |
| Re-derives durable project facts each run | Memory store + `memory-ontology` (harness, `confirmed`) | Persist them; cross-link `memory-ontology` in the workflow (`wiring`) |
| Has a phase doing heavy single-pass reasoning at default depth | Extended thinking / effort control (model, `inferred`) | Call for deeper thinking on that phase only; name the release-note dependency (`procedure`) |
| Carries a stale "the model won't know about X after <date>" assumption in a phase | Newer knowledge cutoff (`confirmed` for the running model) | Update the stale caveat (`description`/`reference`) |
| Is overloaded — its workflow spans two genuinely different jobs, and a capability now makes the second job a practical standalone role | New capability lowers the cost of the second job | **Create a new agent** (Phase 3b → `agent-create`), not a tune |

## The "tune the layer that's actually behind" rule

The single most important agent-tuning discipline: **an agent is mostly a
composition of skills.** Before proposing changes to the AGENT.md, ask
whether the gap is really in the *role* (phase order, contract, inputs) or
in a *skill the role composes*. If it's the skill, the fix is
`skill-version-tune` on that skill, and the agent needs no change. Only the
genuinely role-level gaps — phase parallelism, plan-mode gates,
`skills_used` membership, contract/inputs assumptions, new-role splits —
belong to `agent-version-tune`.

This prevents the most common waste: rewriting an AGENT.md to describe
capabilities that its skills should own.

## When a finding means "new agent" instead

Route to `agent-create` (Phase 3b) rather than emitting an AGENT.md edit
when:

- The version makes a **previously-impractical job practical** and that job
  is a coherent role with its own deliverable contract — not just a new step
  in an existing phase.
- An existing agent is **overloaded** and a capability now lets the second
  half stand alone (split, don't bloat).
- `agent-group-formation` already flagged a **missing role** that a new
  capability now makes worth staffing.

In all three, the proposal's Suggested action is *"create new agent"* and
the role is handed to `agent-create`, whose Phase 1 re-checks the
"job, not a task" bar before scaffolding. Do not let "tune" quietly become
"build a new agent" without that gate.

## Provenance carries through

Agent proposals inherit the capability sheet's provenance. A proposal that
parallelises a phase rests on a `(confirmed)` harness capability — ship it.
A proposal that leans on an `(inferred)` model delta (effort control,
specific long-context numbers) names the release-note dependency in its
Risks section, exactly as the skill-layer dispatcher requires.
