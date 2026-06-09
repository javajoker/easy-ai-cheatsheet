---
name: tune-for-opus-4-8
description: The Opus 4.8 capability lens for skill-version-tune. Loads when a skill is being retuned to make full benefit of Claude Opus 4.8 (model id claude-opus-4-8) — the most capable model in the current Claude 4.x family. Covers the model-reasoning axis: deeper single-pass reasoning, stronger instruction-following (so multi-part asks can be consolidated), long-context use, tool-use reliability, extended/interleaved thinking and effort control, and a January 2026 knowledge cutoff. Use this worker when the user says "tune this skill for Opus 4.8", "make this skill exploit the newest model", "this skill was written for an older Opus — modernise the reasoning", or when skill-version-tune routes a model-axis retune to 4.8. Provides the 4.8 capability checklist and the full capability sheet (references/capabilities.md); the gap analysis and proposal emission stay in the skill-version-tune dispatcher.
---

# Tune for Opus 4.8

A **worker skill** for `skill-version-tune`. The dispatcher owns the retune
(Phases 0–5); this skill provides the **Opus 4.8 model lens** — what the
model can do, and where an existing skill written for an older Opus baseline
leaves reasoning capability on the table.

> Token for `tuned-for`: `opus-4-8`. Opus 4.8 is the most capable member of
> the current Claude 4.x family `(confirmed)`; its id is `claude-opus-4-8`
> `(confirmed)`. The precise reasoning/tool-use **deltas versus 4.7 and
> 4.6** are `(inferred)` here — confirm against the model release notes
> before a proposal leans on a specific delta.

## What's distinctive about the 4.8 axis

This is the **model** half of a tune, not the harness half (that is
`tune-for-cc-harness`). The 4.8 lens is about *reasoning shape*: how deep a
single pass goes, how reliably the model follows a dense multi-part
instruction, how well it holds a long context, and when to spend extended
thinking / effort. A skill can sit on the newest harness and still
prompt the model as if it were an older, shallower one.

Honesty note: most of what differentiates 4.8 from 4.7/4.6 in *degree* is
`(inferred)` — the family shares a large baseline. The capability sheet is
explicit about which lines are anchored and which need a release-note check.

## The Opus 4.8 capability checklist

Apply in the dispatcher's Phase 2:

1. **Stronger instruction-following.** Does the skill drip-feed instructions
   or split a multi-part ask across turns because it didn't trust the model
   to hold it all? Consolidate into one dense, well-structured instruction.
2. **Deeper single-pass reasoning.** Does the skill scaffold a chain of
   tiny steps the model can now do in one reasoned pass? Collapse the
   scaffolding where it no longer earns its keep.
3. **Extended / interleaved thinking + effort control.** Does the skill have
   one genuinely hard reasoning step done at default depth? Call for deeper
   thinking / higher effort *on that step only*. (The exact effort-control
   surface is `(inferred)` — confirm before depending on it.)
4. **Long-context use.** Does the skill chunk or summarise input defensively
   because an older model lost the thread over long inputs? Revisit — but
   pair this with the harness window (`tune-for-cc-harness`), since context
   size is a harness property and coherence-over-context is a model one.
5. **Knowledge cutoff (January 2026, `confirmed`).** Does the skill carry a
   stale "the model won't know about X after <older date>" caveat? Update or
   remove it.

Reject items the skill doesn't need. A mechanical formatting skill rarely
has a reasoning-depth finding.

## Companion skills

| When… | Use |
|---|---|
| Running the retune (Phases 0–5) | `skill-version-tune` (dispatcher) |
| Same version lens, but the target is an agent / INSTRUCTIONS file | `agent-version-tune` / `instructions-version-tune` |
| Tuning the harness half at the same time | `tune-for-cc-harness` |
| Comparing against the previous model baseline | `tune-for-opus-4-7` |
| Writing / applying the proposals | `skill-evolution` / `skill-merge` |

## Anti-patterns

- **Fabricating a 4.8-vs-4.7 delta.** If the sheet says `(inferred)`, the
  proposal inherits the uncertainty — name the release-note dependency in
  Risks. Do not assert a confident improvement number.
- **Collapsing scaffolding the skill still needs.** Deeper reasoning is not
  infinite. Remove a step only when its payoff is gone, not on faith.
- **Adding "think harder" everywhere.** Extended thinking is a finding for
  the *one* hard step, not a global default.
- **Tuning to 4.8 for a user on 4.6.** Confirm the running model first
  (dispatcher Phase 0).

## Reference files

- `references/capabilities.md` — the full Opus 4.8 capability sheet:
  per-capability rows, provenance tags, what each enables, and the
  skill-shape change it implies.
