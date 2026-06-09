# Scenario U — Tuning skills/agents/instructions to a model or harness update/upgrade

The full playbook for the maintenance layer. Self-contained — you do not need
to read the top-level `SCENARIOS.md` to run this. For the everyday mechanics
(running a tune, the disciplines, evolution vs. version-tune), see
[HOWTO.md](HOWTO.md); for the layer rationale and family map, see
[README.md](README.md).

**Goal.** When a new Claude model lands (Opus 4.6 → 4.7 → 4.8) or the Claude
Code harness gains capabilities, bring the framework's *own* artifacts —
skills, agents, and always-loaded INSTRUCTIONS — current with what the new
version can do. Capability-driven, not failure-driven; human-checkpointed;
no silent rewrites. This is the version-tuning sibling of Scenario L
(which is failure-driven evolution — see `../skills/share/skill-evolution/`).

## When this fits

- A model upgrade shipped and you want existing skills to exploit deeper
  reasoning / stronger instruction-following / extended thinking.
- The harness added a capability (subagents, plan mode, background tasks,
  context compaction, the Skill/MCP systems, worktrees) and your skills or
  agents still hand-roll what's now native.
- An agent's phases could run in parallel, or delegate fan-out to a subagent,
  now that the harness supports it.
- An always-loaded INSTRUCTIONS file (especially
  `claude-code-best-practices.md`) predates a harness feature.
- A version makes a *new role* practical that wasn't before — the tune
  becomes "create a new agent."

## Procedure — pick the layer, then tune

1. **Pick the layer dispatcher** for the artifact you're tuning:
   - skill → [`skill-version-tune`](skill-version-tune/)
   - agent (`AGENT.md`) → [`agent-version-tune`](agent-version-tune/)
   - INSTRUCTIONS file → [`instructions-version-tune`](instructions-version-tune/)
2. Name the target and the version: *"Tune `task-breakdown` for the current
   harness"* / *"Modernise the `devops-engineer` agent for Opus 4.8."* If you
   say "the latest," the dispatcher detects the running model and **confirms
   it's reachable** before proposing anything.
3. The dispatcher loads the matching worker sheet under
   [`versions/`](versions/) (`tune-for-opus-4-6` / `-4-7` / `-4-8` /
   `tune-for-cc-harness`) and runs a **gap analysis** with its layer lens.
   Capabilities are tagged `(confirmed)` or `(inferred)`.
4. It emits **one atomic `skill-evolution` proposal per real finding**, each
   tagged `tuned-for: <version>`. Non-findings (capabilities the artifact
   doesn't need) are rejected — no cargo-culting.

## Procedure — merge, and the new-role branch

1. Run `skill-merge` on the proposals — same diff-preview discipline as
   Scenario L. On approval it applies, bumps version, and stamps an additive
   `tuned-for:` field so the next tune only proposes deltas (idempotent).
2. **If a finding is "this should be a new role"**, `agent-version-tune`
   routes to [`agent-create`](agent-create/), which qualifies the role
   against the "job, not a task" bar, drafts the AGENT.md, and registers it
   in CHECKLIST + README (also the destination for `agent-group-formation`'s
   "create new agent" recommendation).
3. Apply the **layer-specific downstream**: agents also touch
   `../agents/CHECKLIST.md`, the README table, and `companion_agents`
   mirrors; INSTRUCTIONS changes state their cross-project blast radius.

## Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `skill-version-tune` | shipped | Dispatcher — retunes a **skill** for a named version. |
| `agent-version-tune` | shipped | Dispatcher — retunes an **agent**; branches to `agent-create` for new roles. |
| `instructions-version-tune` | shipped | Dispatcher — retunes an always-loaded **INSTRUCTIONS** file (higher bar; portable). |
| `agent-create` | shipped | Scaffolds + registers a brand-new agent when a version makes a role viable. |
| `versions/tune-for-opus-4-6` / `-4-7` / `-4-8` | shipped | Per-version model capability sheets (provenance-tagged). |
| `versions/tune-for-cc-harness` | shipped | Current harness capability sheet (mostly `(confirmed)`). |
| `skill-evolution` | shipped | Shared proposal format + `docs/skill-evolution/` home (in `../skills/share/`). |
| `skill-merge` | shipped | Shared apply step — diff preview, version bump, downstream checks (in `../skills/share/`). |
| `requirement-audit` | shipped | Verifies the retune landed across the file(s) it claimed. |
| `cognitive-alignment` | shipped | Locks any contested capability term before proposing. |
| `memory-ontology` | shipped | Records a framework-wide tuning pass so it resumes across sessions. |

Gaps: 0. Recommended next step: tune one skill for `tune-for-cc-harness`
first — the harness sheet is mostly `(confirmed)`, so the proposals are the
most concrete and the loop is easy to feel end-to-end.

## Manual fallback

Without the family: read the relevant model/harness release notes, then for
each artifact write a `docs/skill-evolution/` proposal by hand (template at
[`../skills/share/skill-evolution/references/proposal-template.md`](../skills/share/skill-evolution/references/proposal-template.md))
adding a `tuned-for:` field, and apply via a reviewed PR. The skills mainly
automate the *capability → shape-change* gap analysis and the provenance
discipline; the underlying mechanism is disciplined proposal-then-merge.

## What this scenario does NOT cover

- **Tuning toward a version you can't run.** Proposing 4.8-only affordances
  for a 4.6-pinned deployment makes the artifact worse. The dispatcher
  confirms reachability first.
- **Fabricated changelogs.** Per-version deltas the sheets mark `(inferred)`
  ship only with a release-note dependency named in the proposal's Risks.
- **Failure-driven refinement.** A skill that misfired or had a procedure
  gap is Scenario L (evolution), not a version tune.
- **Bug fixes.** Wrong output is a bug — normal commit, not a tune.
