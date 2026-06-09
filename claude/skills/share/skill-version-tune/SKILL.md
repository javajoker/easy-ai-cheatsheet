---
name: skill-version-tune
description: Retune an existing skill so it makes full benefit of a specific Claude model or Claude Code harness version — Opus 4.6, 4.7, 4.8, or the current CC harness. The skill-layer member of a three-sibling family (agent-version-tune for agents, instructions-version-tune for always-loaded INSTRUCTIONS). Reads the target skill, loads the chosen version's capability sheet (from the tune-for-opus-4-6 / tune-for-opus-4-7 / tune-for-opus-4-8 / tune-for-cc-harness worker skills), runs a gap analysis, and emits skill-evolution proposals that exploit the version's distinctive capabilities — never a silent rewrite. Use this skill when the user says "tune this skill for Opus 4.8", "make this skill take advantage of the new model", "upgrade my skill to the latest harness features", "this skill was written for an older model — modernise it", "what version capabilities is this skill missing", or "retune the framework for the current Claude". Picks the right per-version worker, then hands the resulting proposals to skill-merge. Pairs with skill-evolution (shares the proposal format), skill-merge (applies the proposals), requirement-audit (verifies the retune landed), and cognitive-alignment (locks any contested capability term). For agents use the agent-version-tune sibling, for always-loaded INSTRUCTIONS use instructions-version-tune, and to scaffold a new role a version makes viable use agent-create. Does not edit the target skill directly — the proposal + merge checkpoint is the safety guarantee.
---

# Skill Version Tune

The dispatcher for keeping skills *current with the model and harness they
run on*. Skills in this framework are static markdown authored against an
**implicit** baseline — whatever the model and Claude Code harness could do
the day the skill was written. The model (Opus 4.6 → 4.7 → 4.8) and the
harness both gain capabilities over time. Nothing automatically rewrites a
skill to exploit them. This skill closes that gap, deliberately and on
demand.

> **No silent rewrites.** This skill emits *proposals* under
> `docs/skill-evolution/` — the same format `skill-evolution` produces and
> `skill-merge` applies. The merge checkpoint (with its diff preview) is
> the safety guarantee against retuning a skill in a way the author never
> sees. If you catch yourself wanting to edit the target SKILL.md directly
> "because it's obvious," stop — route it through a proposal.

## Why this exists

A skill written for an older baseline shows tells:

- It asks the user one question at a time when the model can now batch and
  the harness runs tool calls in parallel.
- It hand-rolls a procedure the harness now does natively (subagents,
  background tasks, plan mode, context compaction, the memory store).
- It under-uses extended thinking / effort control on exactly the
  reasoning-heavy step that would benefit most.
- Its budget assumptions ("keep the doc short or context overflows") were
  written for a smaller effective context window.
- It never mentions a companion mechanic the harness added later (Skills,
  MCP tools, worktrees) that would make it sharper.

None of those are *bugs* — the skill works. They are **missed leverage**.
This skill finds the missed leverage for a *named* version and proposes the
specific edits to capture it.

## Versions covered

Each version is a worker skill that owns its capability sheet. This
dispatcher loads the right one.

| Target version | Worker skill | Capability sheet |
|---|---|---|
| Opus 4.6 | `tune-for-opus-4-6` | `tune-for-opus-4-6/references/capabilities.md` |
| Opus 4.7 | `tune-for-opus-4-7` | `tune-for-opus-4-7/references/capabilities.md` |
| Opus 4.8 | `tune-for-opus-4-8` | `tune-for-opus-4-8/references/capabilities.md` |
| Current CC harness | `tune-for-cc-harness` | `tune-for-cc-harness/references/capabilities.md` |

Model versions and harness versions are **orthogonal** — a skill can be
tuned for Opus 4.8 *and* the current harness at once. They are separate
workers because the capabilities (and the release-note sources) are
separate. Tune for both when both have moved.

## Procedure

### Phase 0 — Identify target skill and target version

- **Target skill:** the SKILL.md to retune. If the user named it, use it.
  If they said "this skill" mid-workflow, use the one in play. If ambiguous,
  ask — do not guess. (If the target is an **agent** AGENT.md, hand to
  `agent-version-tune`; if an always-loaded **INSTRUCTIONS** file, hand to
  `instructions-version-tune` — same workers, different layer lens.)
- **Target version:** which baseline to tune *toward*. If the user named a
  version, use it. If they said "the new model" / "the latest," detect the
  running model from the environment (the exact model ID is in the session
  context — e.g. `claude-opus-4-8`) and confirm. If they said "the harness"
  / "Claude Code features," use `tune-for-cc-harness`. If they want both a
  model and the harness, run the relevant workers in sequence (one proposal
  set each — keep them attributable).

> Never tune toward a version that is not actually available to the user.
> Tuning a skill to exploit a capability the running model/harness does not
> have produces a skill that degrades for everyone on the current setup.
> Confirm the target version is reachable before proposing anything.

### Phase 1 — Load the capability sheet

Read the chosen worker skill's `references/capabilities.md`. It is a
provenance-tagged list — every capability is marked `(confirmed)` (anchored
on a fact verifiable from the runtime environment) or `(inferred)` (a
plausible per-version delta that must be checked against release notes).

**Treat `(inferred)` capabilities as hypotheses, not facts.** If a proposal
hinges on an `(inferred)` capability, say so in the proposal's Risks
section and point at the release-note source. Do not fabricate a capability
that is not on the sheet.

### Phase 2 — Gap analysis

Walk the target skill against the capability checklist in the worker's
SKILL.md. For each capability, ask: *does this skill currently leave this
capability on the table, and would exploiting it make the skill
materially better?*

Classify each finding as one of `skill-evolution`'s existing kinds:

| Finding | Kind |
|---|---|
| The trigger/description should mention a version-specific affordance | `description` |
| A step should change shape to use the capability (batch instead of serial, delegate to a subagent, use plan mode, lean on compaction) | `procedure` |
| A new failure mode the capability introduces, or an old workaround the capability retires | `anti-pattern` |
| A reference should document the version-specific technique | `reference` |
| A companion mechanic the version added should be cross-linked | `wiring` |

**Reject non-findings.** A capability the skill genuinely does not need is
*not* a gap. The output of this phase is only the findings where exploiting
the capability has a concrete payoff for *this* skill. Cargo-culting every
capability into every skill is the primary failure mode (see Anti-patterns).

### Phase 3 — Emit proposals

One atomic proposal per finding, written with the **existing**
`skill-evolution` proposal template
(`skills/share/skill-evolution/references/proposal-template.md`), saved
under `docs/skill-evolution/<YYYY-MM-DD>-<skill-slug>-<topic>.md`.

Two additions on top of the standard template:

1. Add a `tuned-for:` front-matter field naming the version, e.g.
   `tuned-for: opus-4-8` or `tuned-for: cc-harness-2026-06`. This is purely
   additive metadata — `skill-merge` ignores fields it does not consume, so
   no change to `skill-evolution` or `skill-merge` is required.
2. In the **Observed** section, cite the capability sheet line (with its
   `(confirmed)`/`(inferred)` tag) instead of a live-session turn quote —
   the "evidence" for a version-tune proposal is the capability, not a
   user utterance.

Everything else (Current / Proposed / Rationale / Risks / Suggested action)
is unchanged. The Risks section is non-negotiable, and for `(inferred)`
capabilities it must name the release-note dependency.

### Phase 4 — Hand off to skill-merge and stamp the skill

The proposals are the deliverable of *this* skill. Applying them is
`skill-merge`'s job (Mode 1 solo, or Mode 2 multi if you emitted several).
Surface them to the user:

```
Wrote N version-tune proposal(s) for <skill> targeting <version>:
  docs/skill-evolution/2026-06-09-task-breakdown-parallel-batch.md
  docs/skill-evolution/2026-06-09-task-breakdown-subagent-delegation.md
Run skill-merge when ready to apply.
```

When `skill-merge` applies them, the **target skill** should gain an
additive `tuned-for:` front-matter field recording the baseline it was
tuned to — e.g. `tuned-for: [opus-4-8, cc-harness-2026-06]`. This is the
durable record that the skill has been brought current; the next tune run
reads it to avoid re-proposing the same changes. The metadata spec is in
`references/version-matrix.md`.

### Phase 5 — Memory hook (optional)

If the retune is part of a deliberate framework-wide pass ("modernise all
the dev-go skills for Opus 4.8"), write a `type: feedback` memory via
`memory-ontology` recording which skills were tuned for which version, so a
later session can pick up where this one stopped.

## The `tuned-for` convention

`tuned-for` is the one new piece of metadata this family introduces. It is
additive and optional — existing skills carry only `name` + `description`,
and nothing breaks if `tuned-for` is absent. Its job is to make tuning
*idempotent*: a skill already `tuned-for: opus-4-8` should not collect a
second round of identical 4.8 proposals. Full spec, including how it
interacts with `skill-merge`'s version bump, is in
`references/version-matrix.md`.

## Companion skills

| When… | Use |
|---|---|
| Writing the actual proposal documents | `skill-evolution` (shared template + the `docs/skill-evolution/` home) |
| Applying the proposals to the target skill | `skill-merge` (diff preview, version bump, downstream cross-ref) |
| Locking the meaning of a contested capability term before proposing | `cognitive-alignment` |
| Verifying the retune actually landed everywhere it promised | `requirement-audit` against the proposals' Proposed sections |
| Loading the Opus 4.6 capability lens | `tune-for-opus-4-6` |
| Loading the Opus 4.7 capability lens | `tune-for-opus-4-7` |
| Loading the Opus 4.8 capability lens | `tune-for-opus-4-8` |
| Loading the current CC harness capability lens | `tune-for-cc-harness` |
| The target is an **agent** (AGENT.md) rather than a skill | `agent-version-tune` (sibling dispatcher) |
| The target is an always-loaded **INSTRUCTIONS** file | `instructions-version-tune` (sibling dispatcher) |
| A version makes a whole **new role** viable | `agent-create` (scaffold it) |
| Recording a framework-wide tuning pass so it survives the session | `memory-ontology` (`type: feedback`) |

## Anti-patterns

- **Cargo-culting capabilities.** Adding "use a subagent here" to a skill
  whose step takes two seconds, or "use extended thinking" on a lookup, is
  net-negative. A capability is only a finding when exploiting it has a
  concrete payoff for *this* skill. Most capabilities are not findings for
  most skills.
- **Tuning toward an unavailable version.** Proposing 4.8-only affordances
  for a user running 4.6 makes the skill worse for them. Confirm
  reachability in Phase 0.
- **Fabricating version deltas.** If the capability sheet marks something
  `(inferred)`, the proposal inherits that uncertainty — say so in Risks
  and cite the release note. Never upgrade an `(inferred)` capability to a
  confident claim to make a proposal sound stronger.
- **Mega-proposals.** "Modernise this whole skill for 4.8" is not one
  proposal; it is several atomic ones. One capability exploited = one
  proposal, so `skill-merge` can accept or reject each independently.
- **Silent edits.** Editing the target SKILL.md directly skips the diff
  checkpoint. The proposal is the output; the merge is the apply.
- **Re-proposing what `tuned-for` already records.** Check the target
  skill's `tuned-for` field first; only propose deltas not already applied
  for that version.

## Reference files

- `references/version-matrix.md` — the cross-version capability comparison
  at a glance, the `tuned-for` metadata spec, and the
  "capability → skill-shape change" mapping that drives Phase 2.
- `references/tuning-playbook.md` — a full worked retune: `task-breakdown`
  tuned for Opus 4.8 + the current harness, from gap analysis through the
  emitted proposals.
