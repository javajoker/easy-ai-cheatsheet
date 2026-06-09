# Capability Sheet — Opus 4.6

The Opus 4.6 model capabilities `skill-version-tune` checks a skill against,
for deployments **pinned to 4.6** (the family floor covered by this series).
Each row: capability, provenance tag, what it enables, and the skill-shape
change it implies.

Provenance:
- `(confirmed)` — verifiable from the runtime environment / framework facts.
- `(inferred)` — a plausible per-version delta that **must** be confirmed
  against the model release notes before a proposal relies on it.

> Token for `tuned-for`: `opus-4-6`. Authoritative source: the Opus 4.6
> model card / release notes on `docs.claude.com`.

---

## Anchored facts `(confirmed)`

- **Member of the current Claude 4.x family.** Carries the family's
  instruction-following and tool-use baseline.
- **Fast mode available** (`/fast`, Opus at faster output, not a downgrade)
  — shared with 4.7 and 4.8.

## Family-baseline reasoning capabilities `(inferred, directional)`

Present across 4.x; the *degree* at 4.6 specifically needs confirmation. As
the floor, treat these conservatively.

### Instruction-following
- **Enables:** one structured instruction instead of multi-turn drip-feed.
- **Skill-shape change:** consolidate question/instruction sequences — the
  family handles this at 4.6.

### Single-pass reasoning
- **Enables:** removing the most obvious scaffolding micro-steps.
- **Skill-shape change:** collapse only over-scaffolding whose payoff is
  clearly gone. Be the most conservative of the three model lenses here.

### Extended thinking
- **Enables:** more reasoning on the hard step.
- **Skill-shape change:** mark the single hardest step for deeper thinking,
  where 4.6 supports it. Confirm the control surface from release notes;
  name the dependency in the proposal's Risks.

## The 4.7 / 4.8-only boundary `(inferred)`

A 4.6 tune must **not** assume gains that landed later. Treat as **out of
scope for a 4.6 tune unless release notes confirm 4.6 has them**:

- Reasoning-depth, long-context, or tool-use improvements the 4.7 / 4.8
  sheets attribute to those versions.
- Any effort-control surface introduced after 4.6.

This is **negative guidance**, and it is strongest at the floor: the value
of the 4.6 lens is keeping a skill correct on the oldest supported runtime.
When in doubt, leave it out; record it for a future tune if the deployment
upgrades.

---

## How to use this sheet

1. The dispatcher walks the target skill against this worker's checklist.
2. `(confirmed)` rows (family membership, fast mode) ship grounded proposals.
3. `(inferred)` family-baseline rows ship proposals with a release-note
   dependency in Risks — held to the most conservative reading.
4. Anything in the **4.7 / 4.8-only boundary** does not ship for a 4.6 tune
   unless confirmed.

**Verify against release notes:** the Opus 4.6 model card / release notes on
`docs.claude.com`. This sheet anchors the verifiable facts and refuses to
invent the per-version deltas.
