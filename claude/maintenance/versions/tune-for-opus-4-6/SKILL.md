---
name: tune-for-opus-4-6
description: The Opus 4.6 capability lens for skill-version-tune. Loads when a skill is being retuned for a deployment pinned to Claude Opus 4.6 — the floor of the current Claude 4.x family covered here. Covers the model-reasoning axis at the 4.6 baseline (the family's instruction-following and reasoning baseline, fast-mode support) while being explicit that 4.7-only and 4.8-only gains must NOT be assumed when the runtime is pinned to 4.6. Use this worker when the user says "tune this skill for Opus 4.6", "our deployment is on 4.6 — make the skill exploit it safely", "tune to the oldest supported Opus", or when skill-version-tune routes a model-axis retune to 4.6. Provides the 4.6 capability checklist and the full capability sheet (references/capabilities.md); the gap analysis and proposal emission stay in the skill-version-tune dispatcher.
---

# Tune for Opus 4.6

A **worker skill** for `skill-version-tune`. The dispatcher owns the retune;
this skill provides the **Opus 4.6 model lens** — the family floor covered
by this skill series.

> Token for `tuned-for`: `opus-4-6`. Tuning *toward* 4.6 is the right move
> when the target deployment is pinned to 4.6 (cost, availability, an
> environment that hasn't upgraded). The job is to exploit the family
> baseline that 4.6 already has, while assuming **neither** 4.7 nor 4.8
> deltas — so the skill stays correct on the pinned runtime.

## What's distinctive about the 4.6 axis

4.6 is a member of the current Claude 4.x family `(confirmed)` and supports
fast mode `(confirmed)`. As the floor of the three covered versions, the
4.6 lens is the **most conservative**: it exploits what the family baseline
provides and is the strictest about not assuming newer-version gains.

The reason to have a distinct 4.6 lens is the same as 4.7's, more so: a 4.6
tune is mostly **negative guidance** — keep the skill from depending on
capabilities that only landed in 4.7 or 4.8.

## The Opus 4.6 capability checklist

Apply in the dispatcher's Phase 2:

1. **Family-baseline instruction-following.** Consolidate drip-fed,
   multi-turn instruction sequences into one structured block — the family
   handles this at 4.6.
2. **Single-pass reasoning (baseline).** Collapse the most egregious
   over-scaffolding, conservatively. Be more cautious than for 4.8 — keep
   scaffolding whose payoff you're unsure of.
3. **Extended thinking.** Mark the single hardest step for deeper thinking
   where the family supports it; confirm the 4.6 control surface from
   release notes before depending on it.
4. **Fast mode (`confirmed`).** Note only where a skill reasons about
   latency.
5. **Do NOT assume 4.7 or 4.8 gains.** Any candidate change that relies on a
   capability the sheets attribute to 4.7 or 4.8 is **out of scope** for a
   4.6 tune unless release notes confirm 4.6 has it.

## Companion skills

| When… | Use |
|---|---|
| Running the retune (Phases 0–5) | `skill-version-tune` (dispatcher) |
| Same version lens, but the target is an agent / INSTRUCTIONS file | `agent-version-tune` / `instructions-version-tune` |
| Tuning the harness half at the same time | `tune-for-cc-harness` |
| The deployment moves up a version | `tune-for-opus-4-7` |
| The deployment is on the newest model | `tune-for-opus-4-8` |
| Writing / applying the proposals | `skill-evolution` / `skill-merge` |

## Anti-patterns

- **Assuming 4.7/4.8 deltas on a 4.6 runtime.** This is the failure the 4.6
  lens exists to prevent. When unsure, leave it out.
- **Over-collapsing scaffolding.** 4.6 is the floor; be the most
  conservative here about removing steps whose payoff is uncertain.
- **Fabricating a 4.6 capability.** `(inferred)` stays `(inferred)`; the
  proposal's Risks must name the release-note dependency.

## Reference files

- `references/capabilities.md` — the full Opus 4.6 capability sheet: the
  family-baseline rows and an explicit "treat as 4.7/4.8-only until
  confirmed" boundary.
