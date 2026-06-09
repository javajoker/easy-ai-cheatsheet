---
name: tune-for-opus-4-7
description: The Opus 4.7 capability lens for skill-version-tune. Loads when a skill is being retuned for a deployment that runs Claude Opus 4.7 — the middle member of the current Claude 4.x family. Covers the model-reasoning axis at the 4.7 baseline (strong instruction-following, single-pass reasoning, extended thinking, fast-mode support) while being explicit about which capabilities are 4.8-only and must NOT be assumed when the target runtime is pinned to 4.7. Use this worker when the user says "tune this skill for Opus 4.7", "we run 4.7 in production — make the skill exploit it without assuming 4.8", or when skill-version-tune routes a model-axis retune to 4.7. Provides the 4.7 capability checklist and the full capability sheet (references/capabilities.md); the gap analysis and proposal emission stay in the skill-version-tune dispatcher.
---

# Tune for Opus 4.7

A **worker skill** for `skill-version-tune`. The dispatcher owns the retune;
this skill provides the **Opus 4.7 model lens**.

> Token for `tuned-for`: `opus-4-7`. Tuning *toward* 4.7 (rather than 4.8)
> is the right move when the target deployment is pinned to 4.7 — for cost,
> availability, or stability reasons. The job is to exploit what 4.7 has
> **without** baking in 4.8-only assumptions that would degrade on the
> pinned runtime.

## What's distinctive about the 4.7 axis

4.7 is a member of the current Claude 4.x family `(confirmed)` and supports
fast mode `(confirmed)`. Its reasoning capability sits between 4.6 and 4.8.
The honest position: the **precise deltas** that separate 4.7 from its
neighbours are `(inferred)` and must be read from the model release notes —
this worker does not invent them.

The reason to have a distinct 4.7 lens (rather than just using 4.8's) is
**negative guidance**: when a skill must run on a 4.7-pinned deployment, the
tune has to *avoid* relying on anything that only landed in 4.8. The 4.7
checklist is the family baseline minus the unconfirmed 4.8 deltas.

## The Opus 4.7 capability checklist

Apply in the dispatcher's Phase 2:

1. **Strong instruction-following (family baseline).** Consolidate
   drip-fed, multi-turn instruction sequences into one structured block.
2. **Single-pass reasoning (family baseline).** Collapse over-scaffolded
   micro-steps where 4.7 can reason through them directly — conservatively.
3. **Extended thinking.** Mark the single hardest step for deeper thinking.
   The exact effort-control surface is `(inferred)` — confirm before
   depending on it.
4. **Fast mode (`confirmed`).** Note only where a skill explicitly reasons
   about latency.
5. **Do NOT assume 4.8-only gains.** If a candidate change relies on a
   capability the sheet attributes to 4.8 (or marks `(inferred, 4.8)`), it
   is **out of scope** for a 4.7 tune. Either confirm 4.7 has it from
   release notes, or leave it out.

## Companion skills

| When… | Use |
|---|---|
| Running the retune (Phases 0–5) | `skill-version-tune` (dispatcher) |
| Same version lens, but the target is an agent / INSTRUCTIONS file | `agent-version-tune` / `instructions-version-tune` |
| Tuning the harness half at the same time | `tune-for-cc-harness` |
| The deployment is actually on the newest model | `tune-for-opus-4-8` |
| The deployment is on the family floor | `tune-for-opus-4-6` |
| Writing / applying the proposals | `skill-evolution` / `skill-merge` |

## Anti-patterns

- **Assuming 4.8 deltas on a 4.7 runtime.** The whole point of a 4.7 tune is
  to not do this. Negative guidance is the value here.
- **Fabricating a 4.7-vs-4.6 delta.** `(inferred)` stays `(inferred)` until
  the release notes confirm it; the proposal's Risks must say so.
- **Cargo-culting "think harder."** Extended thinking is for the one hard
  step, not a global default.

## Reference files

- `references/capabilities.md` — the full Opus 4.7 capability sheet, with
  the family-baseline rows and an explicit "treat as 4.8-only until
  confirmed" boundary.
