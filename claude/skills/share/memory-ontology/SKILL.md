---
name: memory-ontology
description: Maintain Claude Code's MEMORY.md and the per-memory files under memory/ as a small ontology — a knowledge graph of who the user is, which projects they work on, what guidance they have given, and what external systems they reference. Use this skill whenever a new fact about the user or a project surfaces and would still be useful in a future session, whenever the user explicitly asks Claude to "remember" or "forget" something, whenever onboarding to an existing project, before producing any deliverable that depends on a remembered fact, and as part of the compact-ritual. Goes beyond the harness's default "save memories" behaviour by structuring the index into linked entities and relations so that future Claude instances can reconstruct the full picture, not just the latest entry. Triggers proactively after any "/compact" event, after any onboarding pass, and whenever the user says something that pattern-matches one of the four memory types (user / feedback / project / reference). Pairs with cognitive-alignment (conversation-scoped) and compact-ritual (survival mechanic).
---

# Memory Ontology

The Claude Code harness already exposes a memory directory at
`~/.claude/projects/<project-id>/memory/` with `MEMORY.md` as the loaded index.
The default behaviour is a flat list — one memory per file, one line per memory
in the index. This skill **lifts that flat list into an ontology graph**: each
memory is an entity, each entity has explicit relations to others, and
`MEMORY.md` is the entry point into the graph rather than just an alphabetical
inventory.

The result is what an analyst would call a *knowledge base*: a small but
disciplined model of who the user is, what work they do, and how their guidance
applies. A future Claude instance reading the ontology can pick up the
relationship between *"user dislikes mocked databases in tests"* and *"current
project is a payments service" and *"user is the on-call engineer"* without
piecing it together from three separate flat memories.

## Why this exists

The harness's built-in memory system answers *"what did the user tell me?"* well.
It answers *"what does this user need from me on this project, given everything
I know?"* poorly — because the flat structure hides the relations.

Three concrete failure modes that this skill prevents:

1. **Stale-by-accretion.** A new memory contradicts an older one, but both
   survive because the writer of the new one did not look for the contradiction.
   The flat index makes contradictions easy to miss.
2. **Orphaned guidance.** A feedback memory says "always use the staging cluster
   for X." A project memory says "we are migrating away from staging." Without
   an `applies-to` or `superseded-by` relation, neither memory knows about the
   other.
3. **Onboarding silence.** A new project starts. The user's general memories
   apply, the project memories from another repo do not. Without a `scope`
   field, the harness loads everything at once and Claude has to silently
   filter.

## The ontology shape

Every memory file is one of four types (`user`, `feedback`, `project`,
`reference`) per the harness's contract. This skill keeps those types but adds
structure inside each file and across the index.

### File frontmatter (extension of the harness format)

```markdown
---
name: <short title>
description: <one-line description used to decide relevance in future conversations>
type: user | feedback | project | reference
scope: global | project:<slug> | session
created: YYYY-MM-DD
updated: YYYY-MM-DD
status: active | superseded | tentative
supersedes: <filename>            # optional
superseded-by: <filename>          # optional
related: [<filename>, ...]         # optional, graph edges
applies-to: [<entity>, ...]        # optional, e.g. "project:foo", "domain:databases"
distinct-from: [<filename>, ...]   # optional, prevents future conflation
---

<memory body — same shape the harness already defines for that type>
```

The harness already requires `name`, `description`, `type`. This skill adds
`scope`, `status`, `supersedes` / `superseded-by`, `related`, `applies-to`,
`distinct-from`. None of the additions break the harness — `MEMORY.md` is still
just a list of links.

### MEMORY.md index, ontology-enriched

The default `MEMORY.md` is `- [Title](file.md) — one-line hook`. The
ontology-enriched form groups entries by scope and lists relations inline:

```markdown
# MEMORY

## Global — user
- [Role and stack](user_role.md) — senior platform engineer, Go + PostgreSQL primary
- [Linguistic style](user_style.md) — terse English, no emojis ≺ applies-to: every project

## Global — feedback
- [Mocking discipline](feedback_mocks.md) — integration tests hit real DB ≺ applies-to: testing
- [PR sizing](feedback_pr_size.md) — small focused PRs preferred ≺ supersedes: feedback_pr_size_old.md

## Global — reference
- [Linear projects](reference_linear.md) — INGEST = pipeline bugs, INFRA = platform tickets

## Project — coolshell
- [Compliance driver](project_coolshell_compliance.md) — auth rewrite from legal mandate
- [Release window](project_coolshell_freeze.md) — merge freeze begins 2026-03-05

## Project — stardust
- [Architecture mode](project_stardust_arch.md) — base library, no main package
```

Annotations like `≺ applies-to: testing` are graph edges expressed inline. They
are not free-text — they read the corresponding fields from the memory files.
If a relation appears in the index but not in the memory file, the file is the
truth and the index is repaired.

Per the harness contract: keep `MEMORY.md` under 200 lines (lines after 200 are
truncated). The ontology fits comfortably within that limit for 30–50
memories. If the ontology outgrows it, see "When the index outgrows 200 lines"
below.

## What gets saved here vs the cognitive library

| Question | Goes in cognitive library | Goes in memory ontology |
|---|---|---|
| Does it survive `/compact`? | Yes, for this conversation | Yes, across all sessions |
| Does it carry across projects? | No | Yes if `scope: global` |
| Is it about *the user as a person*? | Profile, not library | `type: user` |
| Is it correction or validated approach? | Possibly, conversation-scoped | `type: feedback` if it should outlive this session |
| Is it about a specific project? | Yes, conversation-scoped | `type: project` |
| Is it a pointer to an external system? | Probably not | `type: reference` |

If unsure, ask one quick question: *"is this for now, or should I keep it for
the next session?"* If for the next session, write it to the memory ontology.

## The five operations

The skill exposes five operations, all incremental — no big rebuilds.

### 1. Save

Write a new memory file under `memory/`. Add its line to `MEMORY.md` in the
correct scope group. If the new memory has any `supersedes`, `related`,
`applies-to`, or `distinct-from` relations, also update the index annotations
on the affected entries.

Before saving, **scan for contradictions**: read the descriptions of memories
in the same scope and type. If a contradiction exists, the new memory is a
`supersede` (mark the old one `status: superseded`, set `superseded-by` /
`supersedes`), not a duplicate.

### 2. Update

When the same fact gets refined — not contradicted, just sharper — update the
existing file. Bump `updated:`. Do not change `created:`. Do not add a
`superseded` chain for refinements.

### 3. Supersede

When new information *replaces* an old memory: the old file keeps existing,
marked `status: superseded`, with `superseded-by:` pointing forward; the new
file is created with `supersedes:` pointing back. Both files survive — the
supersession chain is part of the record.

In the index, the superseded entry moves to an "Archive" sub-section at the
bottom of its scope group. It stays linkable but does not clutter the active
list.

### 4. Forget

Only when the user explicitly asks. Delete the file, remove the line from
`MEMORY.md`, and **also remove any `related:` or `supersedes:` references in
*other* memory files that pointed at it.** A dangling relation is worse than no
relation.

### 5. Audit

Run during the compact-ritual or onboarding pass. Walk every memory file:

- Does the description in `MEMORY.md` still match the description in the file?
- Are any relations dangling (point at a file that no longer exists)?
- Is any `applies-to` scope wrong now (project archived, system retired)?
- Are there obvious contradictions between entries of the same scope?

Report the issues; do not silently rewrite them.

## When the index outgrows 200 lines

The harness truncates `MEMORY.md` past line 200. Three options when the
ontology exceeds that:

1. **Cull the global feedback section.** Old feedback that has not fired in
   months is the first candidate. Mark superseded by a brief consolidation memo.
2. **Move per-project memories into project-scoped `CLAUDE.md`.** If `coolshell`
   has 12 memories, drop them into the project's own `.claude/CLAUDE.md` and
   delete them from global memory.
3. **Split into volumes.** `MEMORY.md` keeps the global entries and a one-line
   pointer per active project; `memory/INDEX_<project>.md` holds that project's
   detail. Claude reads the project index only when working in that project.

Option 2 is preferred — locality of reference. Option 3 is heavier.

## Triggers

Save proactively when:

- The user volunteers a fact about themselves, their team, or their project
  that is not in the current memory files.
- The user gives a correction (write a `feedback` memory).
- The user confirms a non-obvious approach worked (write a `feedback` memory).
- A reference URL or external system is named (write a `reference` memory).

Audit proactively when:

- During the compact-ritual (see compact-ritual skill).
- At the start of a session after a gap of more than a few days.
- After onboarding to a new project (run `project-onboarding`; it triggers this
  skill at the end).
- The user says "do you remember X?" and the answer is unclear.

## Anti-patterns

- **Saving ephemera.** In-progress task state, current todo lists, "we just
  decided to do X today" — that belongs in a plan, not in memory. The test:
  *"will this still be true in three weeks?"* If no, do not save.
- **Saving duplicates.** Before save, scan the same type and scope for an
  existing entry. Update or supersede the existing one rather than creating a
  parallel.
- **Treating `MEMORY.md` as a free-text scratchpad.** It is an index. Body
  content goes in the per-memory file.
- **Pre-emptive supersession.** Marking entries `superseded` because they
  *might* be wrong, before the user confirms. A `status: tentative` is fine;
  `superseded` is final.
- **Silent rebuild after `/compact`.** If `MEMORY.md` looks empty after
  compaction, the harness still has the files on disk. Re-read them, do not
  rewrite from your memory of the conversation.

## Interaction with the cognitive library and profile

The cognitive library is conversation-scoped. The memory ontology is
session-spanning. The relationship is one of *promotion*:

- A library entry `[T1] 简化品牌故事` that has held across three sessions on the
  same project is a candidate for promotion to a `type: project` memory.
- A profile observation *"prefers principle-first explanations"* that holds
  across multiple projects is a candidate for promotion to a `type: user`
  memory.

Promotion is opt-in. Ask the user: *"This has held across our last few
sessions — want me to remember it for next time too?"* On yes, write the memory
and reference the library entry ID in the body.

## Reference files

- `references/ontology-schema.md` — the full frontmatter fields, valid values,
  and relation semantics.
- `references/operations.md` — worked examples of save, update, supersede,
  forget, audit.
- `references/promotion-from-library.md` — when and how to promote a cognitive
  library entry or a profile observation into a durable memory.
