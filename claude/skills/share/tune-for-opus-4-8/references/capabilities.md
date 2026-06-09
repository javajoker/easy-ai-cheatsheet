# Capability Sheet — Opus 4.8

The Opus 4.8 model capabilities `skill-version-tune` checks a skill against.
Each row: the capability, a **provenance tag**, what it enables, and the
**skill-shape change** it implies.

Provenance:
- `(confirmed)` — verifiable from the runtime environment / framework facts.
- `(inferred)` — a plausible per-version delta vs 4.7 / 4.6 that **must** be
  confirmed against the model release notes before a proposal relies on it.

> Token for `tuned-for`: `opus-4-8`. Authoritative source for deltas:
> the Opus 4.8 model card / release notes on `docs.claude.com`.

---

## Anchored facts `(confirmed)`

- **Model id `claude-opus-4-8`.** The exact id, for any skill that names a
  model in code or config.
- **Most capable model in the current Claude 4.x family.** When a skill
  builds an AI application, the default should be the latest, most capable
  Claude model — 4.8 unless there's a reason to pick Sonnet/Haiku for
  cost/latency.
- **Fast mode available** (`/fast`, Opus at faster output, not a downgrade).
  Shared with 4.7 and 4.6.
- **Knowledge cutoff: January 2026.** Use this to retire stale "the model
  won't know about X" caveats keyed to an older date.

These anchor the proposals that don't depend on a per-version delta — e.g.
"update the model id in this skill's example code to `claude-opus-4-8`,"
or "this skill's cutoff caveat is stale."

## Reasoning-shape capabilities

### Stronger instruction-following `(inferred, directional)`
The 4.x family follows dense multi-part instructions well; 4.8 is the
strongest member.
- **Enables:** giving the model a whole structured task at once instead of
  drip-feeding.
- **Skill-shape change:** consolidate multi-turn question/instruction
  sequences into one dense block (the pattern `skill-orchestrator` already
  uses). Confirm the degree from release notes before claiming it as a
  *4.8-specific* win rather than a family trait.

### Deeper single-pass reasoning `(inferred, directional)`
More can be reasoned through in one pass without external scaffolding.
- **Enables:** removing tiny intermediate steps a skill added to compensate
  for a shallower model.
- **Skill-shape change:** collapse over-scaffolded procedures where the
  scaffolding no longer earns its keep — conservatively, one step at a time,
  each justified.

### Extended / interleaved thinking + effort control `(inferred)`
The family supports extended thinking; the exact 4.8 effort-control surface
(how you request more/less reasoning, verbosity controls) is version- and
API-dependent.
- **Enables:** spending more reasoning on the hard step, less on the rote
  ones.
- **Skill-shape change:** mark the *single* hardest reasoning step in a
  skill for higher effort / extended thinking. **Confirm the control
  surface** before writing the proposal — this is the most `(inferred)` row
  on the sheet; a proposal here must name its release-note dependency in
  Risks.

### Long-context coherence `(inferred, directional)`
Holding the thread over long inputs improves across the family.
- **Enables:** less defensive chunking/summarising of long inputs.
- **Skill-shape change:** revisit "summarise before processing" steps — but
  coordinate with `tune-for-cc-harness`, since *window size* is a harness
  property and *coherence over the window* is a model one. A real finding
  usually needs both.

---

## How to use this sheet

1. The dispatcher walks the target skill against the **checklist** in this
   worker's SKILL.md.
2. Anchored `(confirmed)` rows ship proposals with confidence (model id,
   cutoff).
3. `(inferred)` reasoning-shape rows ship proposals **only** with a
   release-note dependency named in Risks — and the most uncertain (effort
   control) may be deferred until confirmed, exactly as the dispatcher's
   tuning-playbook shows.

**Verify against release notes:** the Opus 4.8 model card / release notes on
`docs.claude.com`. The honest baseline is that 4.6 / 4.7 / 4.8 share a large
common capability surface; this sheet anchors what is verifiable and flags
the rest for confirmation rather than inventing a per-version changelog.
