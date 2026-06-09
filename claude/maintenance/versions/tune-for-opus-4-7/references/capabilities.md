# Capability Sheet — Opus 4.7

The Opus 4.7 model capabilities `skill-version-tune` checks a skill against,
for deployments **pinned to 4.7**. Each row: capability, provenance tag,
what it enables, and the skill-shape change it implies.

Provenance:
- `(confirmed)` — verifiable from the runtime environment / framework facts.
- `(inferred)` — a plausible per-version delta that **must** be confirmed
  against the model release notes before a proposal relies on it.

> Token for `tuned-for`: `opus-4-7`. Authoritative source: the Opus 4.7
> model card / release notes on `docs.claude.com`.

---

## Anchored facts `(confirmed)`

- **Member of the current Claude 4.x family.** Shares the family's strong
  instruction-following and tool-use baseline.
- **Fast mode available** (`/fast`, Opus at faster output, not a downgrade)
  — shared with 4.6 and 4.8.

## Family-baseline reasoning capabilities `(inferred, directional)`

These are present across 4.x; the *degree* at 4.7 specifically is what
needs confirmation.

### Strong instruction-following
- **Enables:** one dense, structured instruction instead of multi-turn
  drip-feed.
- **Skill-shape change:** consolidate question/instruction sequences into
  one block.

### Single-pass reasoning
- **Enables:** removing scaffolding micro-steps.
- **Skill-shape change:** collapse over-scaffolded procedures conservatively,
  one justified step at a time.

### Extended thinking
- **Enables:** more reasoning on the hard step.
- **Skill-shape change:** mark the single hardest step for deeper thinking.
  The effort-control surface is `(inferred)` — confirm before depending on
  it; name the dependency in the proposal's Risks.

## The 4.8-only boundary `(inferred)`

The reason a 4.7 tune is distinct from a 4.8 tune: some gains belong to 4.8
and must **not** be assumed on a 4.7 runtime. Treat the following as
**out of scope for a 4.7 tune unless release notes confirm 4.7 has them**:

- Any reasoning-depth or long-context improvement the 4.8 sheet attributes
  to 4.8 specifically.
- Any effort-control surface that shipped with 4.8.

This is **negative guidance** — its value is preventing a proposal that
would make the skill worse on the pinned 4.7 deployment. When in doubt,
leave it out and note it for a future tune-up if the deployment moves to 4.8.

---

## How to use this sheet

1. The dispatcher walks the target skill against this worker's checklist.
2. `(confirmed)` rows (family membership, fast mode) ship grounded proposals.
3. `(inferred)` family-baseline rows ship proposals with a release-note
   dependency in Risks.
4. Anything in the **4.8-only boundary** does not ship for a 4.7 tune unless
   confirmed.

**Verify against release notes:** the Opus 4.7 model card / release notes on
`docs.claude.com`. This sheet anchors the verifiable facts and refuses to
invent the per-version deltas.
