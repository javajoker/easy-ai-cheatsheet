---
name: skill-merge
description: Apply one or more accepted evolution proposals (from skill-evolution) into the canonical skill or INSTRUCTIONS files they target. Handles three modes — solo merge (one proposal, one target), multi-merge (batch of proposals, possibly multiple targets, detect conflicts), and override-promotion (lift a project-specific override into the canonical skill). Always human-checkpointed: surfaces conflicts and the final diff before writing, then bumps version metadata, updates the changelog, and runs downstream cross-reference checks (orchestrator references, SCENARIOS appendix, companion-skill lists). Use this skill whenever a proposal under docs/skill-evolution/ is ready to land, when consolidating accumulated overrides across projects, or when a refactor needs to apply several related proposals together. Pairs with skill-evolution (the upstream producer), with requirement-audit (verify the merge actually landed everywhere it should), and with cognitive-alignment (lock the meaning of any contested term in a proposal before merging).
---

# Skill Merge

The partner skill to `skill-evolution`. Evolution captures proposals;
merge applies them. This is where the framework actually changes —
which is precisely why this is a human-checkpointed step, not a silent
update.

> **No silent merges.** Every merge surfaces the full diff, every
> conflict surfaces the conflict, every downstream cross-reference
> check is reported. If you find yourself wanting to skip a step "to
> move faster," resist — the cost of a silent skill-drift bug is much
> higher than the cost of a thirty-second confirmation.

## Why this exists

Evolution proposals would pile up and lose value without an explicit
apply step. Merging them requires:

- **Conflict detection** — multiple proposals touching the same lines
  must be resolved deliberately.
- **Version metadata** — each merge bumps the skill's version so the
  history is traceable.
- **Downstream consistency** — when a SKILL.md changes, several other
  artifacts may need updates: `skill-orchestrator/SKILL.md`,
  `SCENARIOS.md` appendix, `README.md` counts (if a skill is
  added/removed), cross-references in companion skills.

Doing all of that by hand is error-prone. This skill does it
methodically.

## Three merge modes

### Mode 1 — Solo merge

**Inputs:** one proposal file, one target file.

**Use when:** a single evolution proposal is ready to land and does
not interact with any pending sibling proposals.

**Procedure:** straightforward apply (Phases 1–4 below, skipping Phase 2's
conflict detection).

### Mode 2 — Multi-merge

**Inputs:** N proposal files, possibly targeting M files.

**Use when:** several proposals have accumulated and you want to land
them in one pass, OR several proposals interact with each other and
need to be merged together to be coherent.

**Procedure:** all phases. Phase 2 (conflict detection) is the load-
bearing step.

### Mode 3 — Override promotion

**Inputs:** one or more project-specific override files (under
`INSTRUCTIONS/projects/<slug>/skill-overrides/`), the canonical skill
they refine.

**Use when:** the same override pattern has emerged across multiple
projects and the canonical skill should absorb it.

**Procedure:** treat each override as an implicit proposal, then run
Phases 1–5 as for Mode 2. After successful merge, the override files
become redundant — supersede them rather than deleting (a footnote
pointing at the canonical change preserves the audit trail).

## Procedure

### Phase 1 — Gather and classify

Read every proposal file in scope:

- Parse the front matter to get `target`, `kind`, `status`.
- Reject proposals with `status: rejected` or `status: merged` (the
  latter is already applied; the former should not be).
- Group proposals by target file. A target with multiple proposals
  becomes a conflict candidate in Phase 2.

Output of this phase: a grouped list, one entry per target file,
listing the proposals that touch it.

### Phase 2 — Detect conflicts

For each target file with multiple proposals:

- **No overlap** — proposals touch different sections. Merge order
  doesn't matter; apply them all.
- **Adjacent overlap** — proposals touch nearby lines but not the same
  text. Apply in order, re-render context between applies.
- **Direct overlap** — proposals touch the same text. **Conflict.**
  Surface to the user:

  ```
  Conflict on skills/<group>/<skill>/SKILL.md lines L1–L2:
    Proposal A (id: evolution-…-001) proposes: <excerpt>
    Proposal B (id: evolution-…-002) proposes: <different excerpt>

  Resolution options:
    1. Pick one (mark the other rejected).
    2. Merge by hand (write a third proposal that combines both,
       mark A and B as superseded).
    3. Sequence (apply A first, then derive a new proposal from B's
       intent against A's text).
  ```

  Do not pick silently.

### Phase 3 — Preview the diff

For every target file (after conflicts are resolved):

- Render the would-be new content.
- Generate a unified diff against the current content.
- Surface the diff to the user. If the user signals approval, proceed;
  if not, abort cleanly (no partial writes).

The diff is the audit moment. The user sees exactly what's going to
change. Do not skip on grounds of "it's a small change."

### Phase 4 — Apply

For each target:

1. Write the new content.
2. Update the front matter:
   - Bump `version:` (semver: patch for description / anti-pattern /
     reference; minor for procedure / wiring; major for breaking
     procedure changes).
   - Update `updated:` to today's date.
   - Optionally add `last-evolved:` and a pointer to the merged
     proposal IDs.

### Phase 5 — Update proposal status

For every applied proposal:

- Change `status: proposed` → `status: merged`.
- Append a `merged-at:` field with today's date.
- Append a `merged-into:` field with the version of the target after
  the merge.

Do not delete the proposal files. They are the changelog.

### Phase 6 — Downstream cross-reference check

The merged change may have implications elsewhere. Walk:

- **`skill-orchestrator/SKILL.md`** — does it reference the changed
  skill by name in a workflow pattern? Update if so.
- **`references/workflow-patterns.md`** — same check, for the chain
  examples.
- **`SCENARIOS.md`** — does any scenario's "Skills involved" checklist
  describe the changed skill? Update role/description if the change is
  user-visible.
- **`README.md`** — only relevant if the merge changed counts
  (added/removed skills).
- **Companion sections in sibling SKILL.md files** — if the change
  added/removed a partnership, the partners must mirror it.
- **`INSTRUCTIONS/projects/*/skill-overrides/`** — for Mode 3
  promotions, any overrides that became redundant should be
  superseded.

Generate a short report of what was checked, what was found, and what
was updated.

### Phase 7 — Memory hook

Write a `type: feedback` memory via `memory-ontology` so future
sessions know the merge happened:

```markdown
---
name: Skill evolution merged — <summary>
description: <one line summary of the change>
type: feedback
scope: global
created: YYYY-MM-DD
related: [docs/skill-evolution/<proposal>.md]
---

Merged <count> proposal(s) into <target(s)>. New version: <version>.
```

This makes the change discoverable by `requirement-audit` later and
by orchestration runs that need to know the skill catalog has shifted.

## What this skill does NOT do

- **Auto-apply without confirmation.** Phase 3's diff preview is
  non-negotiable.
- **Apply rejected or superseded proposals.** They are documentation,
  not pending work.
- **Fix bugs in skills.** Bug fixes are normal commits; they don't
  route through proposal/merge. Use this skill for *refinements* with
  proposals as evidence.
- **Resolve conflicts on its own.** Phase 2 surfaces, the user
  decides.

## Companion skills

| When… | Use |
|---|---|
| Before merge, to lock the meaning of a contested term in the proposal | `cognitive-alignment` |
| After merge, to verify the change landed everywhere downstream | `requirement-audit` against the proposals' "Proposed" sections |
| To capture *new* proposals from live use | `skill-evolution` |
| To record the merge as a durable session-spanning fact | `memory-ontology` |
| To plan the merge pass as a multi-step workflow | `skill-orchestrator` |
| To produce a fresh "Skills involved" checklist for SCENARIOS.md if the merge touched scenario-relevant skills | `scenario-checklist` |

## Anti-patterns

- **Batch-applying without conflict detection.** "I'll just rebase
  them in order" is how silent regressions land.
- **Skipping the diff preview.** The diff IS the merge. Surface it.
- **Auto-bumping major version on procedure changes.** Reserve major
  for genuine breaking changes — a procedure tweak that doesn't break
  callers is minor.
- **Forgetting Phase 6.** A merged change with stale downstream
  references is worse than no change — it lies to the next session.
- **Deleting proposal files after merge.** They are the historical
  record. Move them to an `archive/` subdirectory if `docs/skill-
  evolution/` gets crowded.

## Reference files

- `references/merge-checklist.md` — the explicit phase-by-phase
  checklist for a merge run.
- `references/conflict-resolution.md` — patterns for the three
  conflict modes (no overlap / adjacent / direct), with worked
  examples.
