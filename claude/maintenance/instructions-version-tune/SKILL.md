---
name: instructions-version-tune
description: Retune an always-loaded INSTRUCTIONS file (under claude/INSTRUCTIONS/) so its portable engineering guidance makes full benefit of a specific Claude model or Claude Code harness version — Opus 4.6, 4.7, 4.8, or the current CC harness. The INSTRUCTIONS-layer sibling of skill-version-tune; it loads the same per-version capability sheets (tune-for-opus-4-6 / -4-7 / -4-8 / tune-for-cc-harness) and applies an instructions-shaped lens (does claude-code-best-practices.md predate subagents/plan mode/compaction; do development-principles or the workflow/standards files carry stale model-capability assumptions). Emits skill-evolution proposals targeting INSTRUCTIONS/<path>.md — never a silent rewrite — reusing the loop that already supports INSTRUCTIONS targets. Use this skill when the user says "update the best-practices instructions for the current harness", "our development principles assume an older model — modernise them", "do the INSTRUCTIONS mention subagents/plan mode yet", or "tune the always-loaded guidance for Opus 4.8". Pairs with skill-evolution / skill-merge (the proposal + apply loop, which already targets INSTRUCTIONS), skill-version-tune (skill-layer sibling), agent-version-tune (agent-layer sibling), and the four tune-for-* workers (the shared version lens).
---

# Instructions Version Tune

The **INSTRUCTIONS-layer** member of the version-tuning family. Skills are
loaded on demand; INSTRUCTIONS are loaded **always** and are **portable**
across every project. That changes the stakes: an instructions tune touches
guidance that shapes every session in every project, so the bar for a
finding is higher and the blast radius is wider.

> **No silent rewrites, and a higher bar.** This skill emits proposals under
> `docs/skill-evolution/` (target: `INSTRUCTIONS/<path>.md`) — a target the
> existing `skill-evolution` / `skill-merge` loop **already supports**, so no
> new mechanism is introduced. Because INSTRUCTIONS are always-loaded and
> portable, every proposal here states its cross-project blast radius in
> Risks. A change that helps one stack but hurts another does not belong in
> portable INSTRUCTIONS — it belongs in a project override.

## Which INSTRUCTIONS files are version-sensitive

Not all are. The lens (`references/instructions-tuning-lens.md`) ranks them;
the short version:

- **`claude-code-best-practices.md`** — the most version-sensitive file in
  the framework. It is literally guidance on using the harness; if it
  predates subagents, plan mode, background tasks, context compaction, the
  Skill/MCP systems, or worktrees, it is stale by definition. Primary target.
- **`development-principles.md`**, **`workflows/task-management.md`** —
  may carry assumptions shaped by older model limits (defensive context
  budgeting, manual step-chaining the model now does in one pass).
- **`standards/*`**, **`markdown-conventions.md`**, **`git-workflow.md`** —
  mostly version-neutral (a coding standard is a coding standard). Tune only
  where a standard explicitly reasons about model/harness behaviour.

## How INSTRUCTIONS fall behind

- **Best-practices that don't mention native mechanics.** The harness gained
  subagents / plan mode / compaction; the always-loaded best-practices file
  never tells the model to use them.
- **Defensive budgeting baked into a principle.** "Keep working context
  minimal" written for a smaller window, now contradicting the compaction +
  larger-window reality (and `compact-ritual`).
- **Manual scaffolding elevated to a principle.** A step-by-step ritual the
  model can now do in one reasoned pass, frozen as a "always do X then Y"
  instruction.
- **A stale capability claim.** "The model cannot reliably do Z" that a
  newer version made false.

## Procedure

Mirrors `skill-version-tune`; INSTRUCTIONS-specific notes flagged.

### Phase 0 — Identify target file and version

- **Target:** the `INSTRUCTIONS/<path>.md` to retune. Default to
  `claude-code-best-practices.md` if the user said "the instructions" and
  meant harness guidance.
- **Version:** detect the running model if "the latest"; confirm
  reachability. Model and harness are separate axes — for INSTRUCTIONS, the
  harness axis (`tune-for-cc-harness`) is usually the high-value one.

### Phase 1 — Load the capability sheet

Read the chosen worker's `references/capabilities.md`. Honour `(confirmed)`
/ `(inferred)` provenance.

### Phase 2 — Instructions-shaped gap analysis

Walk the target file against the **instructions lens** in
`references/instructions-tuning-lens.md`. For each capability ask: *does
this always-loaded guidance leave the capability on the table, or actively
contradict it, in a way that's true across projects?*

Classify findings as `skill-evolution` kinds:

| Finding | Kind |
|---|---|
| A heading/intro should name a version affordance | `description` (rare for INSTRUCTIONS) |
| A principle/step should change to reflect the capability | `procedure` |
| A stale "the model can't do X" caveat | `anti-pattern` (retire the workaround) |
| A new section documenting the native mechanic (subagents, plan mode) | `reference` |
| A pointer to a companion skill the capability makes relevant (`compact-ritual`, `memory-ontology`) | `wiring` |

**Reject project-specific findings.** If the change only helps one stack,
it is a project override (`INSTRUCTIONS/projects/<slug>/skill-overrides/` or
project context), **not** a portable-INSTRUCTIONS tune. This is the most
important rejection rule at this layer.

### Phase 3 — Emit proposals

One atomic proposal per finding, `skill-evolution` template, saved under
`docs/skill-evolution/<YYYY-MM-DD>-instructions-<topic>.md`, with:

- `target: INSTRUCTIONS/<path>.md`
- `tuned-for: cc-harness-<YYYY-MM>` (or `opus-4-8`) — additive provenance.
- **Observed** cites the capability-sheet line (with provenance tag).
- **Risks** states the **cross-project blast radius** — non-negotiable here.

### Phase 4 — Hand off to skill-merge

`skill-merge` applies INSTRUCTIONS proposals natively (its Phase 6 downstream
list already includes `INSTRUCTIONS/projects/*/skill-overrides/`). On apply,
the target file gains an additive `tuned-for:` note where the file carries
front matter; for plain instruction files without front matter, record the
tune in the proposal's `merged-into` and in a memory hook instead.

### Phase 5 — Memory hook (optional)

For a deliberate pass across the INSTRUCTIONS set, write a `type: feedback`
memory listing which files were tuned for which version.

## Companion skills

| When… | Use |
|---|---|
| Writing / applying the proposals | `skill-evolution` / `skill-merge` (already INSTRUCTIONS-aware) |
| The change is really project-specific, not portable | a project override under `INSTRUCTIONS/projects/<slug>/` (see `skill-evolution/references/override-vs-evolution.md`) |
| A compaction-relaxation needs the survival procedure | `compact-ritual` |
| A memory-persistence pointer is the finding | `memory-ontology` |
| Tuning a skill / agent that rests on these instructions | `skill-version-tune` / `agent-version-tune` |
| Loading the version lens | `tune-for-opus-4-6` / `-4-7` / `-4-8` / `tune-for-cc-harness` |

## Anti-patterns

- **Portable-izing a project-specific change.** The highest-stakes mistake
  at this layer. If it doesn't generalise across stacks, it's an override.
- **Tuning version-neutral standards.** A naming convention or git workflow
  rarely depends on the model version. Don't manufacture findings there.
- **Omitting blast radius from Risks.** Every always-loaded change states
  what it could break across projects. "No known risks" on a portable
  instruction is suspicious.
- **Fabricating version deltas.** `(inferred)` stays `(inferred)`; cite the
  release note.

## Reference files

- `references/instructions-tuning-lens.md` — the per-file version-sensitivity
  ranking and the capability → instruction-change mapping, including the
  portable-vs-project-override decision.
