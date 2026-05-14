---
name: skill-evolution
description: Capture an evolution candidate — a concrete observation that a skill (or an INSTRUCTIONS file) could be improved — during live project work, and write it up as a reviewable proposal under docs/skill-evolution/. Use this skill whenever you notice in real-time that a skill's description does not match how the user actually phrased an intent, a skill's procedure had a gap in practice, a skill's anti-patterns missed a failure mode that just occurred, a skill's references did not cover a question that came up, or two skills should be cross-referenced but are not. Pairs with memory-ontology (saves a feedback memory pointing at the proposal), with skill-merge (the partner skill that applies the proposal once accepted), and with cognitive-alignment (locks the meaning of the observation before writing it up). Does not modify any existing skill file — only writes new proposal documents. The merge step is explicit and human-checkpointed.
---

# Skill Evolution

A skill for keeping the framework *alive*: as you use skills in real
project work, observations accumulate that would make them better. This
skill is the mechanic for capturing those observations as proposals so
they can be reviewed and merged rather than lost in conversation history.

> **Claude does not silently rewrite skill files.** This skill writes
> *proposals* under `docs/skill-evolution/` that a human (or a follow-up
> session) reviews. The `skill-merge` partner skill is what actually
> applies the proposal once accepted. The checkpoint is the safety
> guarantee against silent drift.

## Why this exists

The framework's skills are static markdown today. They evolve only when
someone deliberately edits them. In practice, evolution opportunities
surface constantly during live work:

- A trigger phrase didn't fire when it should have.
- A skill's procedure had a step that turned out to be too rigid (or
  too vague) for a specific project type.
- An anti-pattern just happened that wasn't in the anti-patterns list.
- A user question went to references but the references didn't have the
  answer.
- Two skills clearly need to know about each other and don't.

Without a capture mechanic, those observations disappear when the
session ends. With one, they become reviewable proposals that compound
into a sharper framework over time.

## Five evolution kinds

Classify every candidate as one of:

| Kind | Trigger | Example |
|---|---|---|
| **description** | The skill's `description:` field didn't match the user's phrasing | User said *"register this project"*; `project-onboarding` is described with *"onboard"* but not *"register"* — add the synonym. |
| **procedure** | A step in the skill's procedure was wrong for this case | `project-onboarding` Phase 3 asks 5–7 questions; for tiny projects 5 is too many — cap at 3 for projects with <5 files. |
| **anti-pattern** | A failure mode just occurred that wasn't called out | `task-breakdown` produced a 200-task plan when 30 was right; add "watch granularity" anti-pattern. |
| **reference** | References missed a question the user asked | User asked how to handle multi-tenancy in `project-backend-go`; not in references — add a section. |
| **wiring** | Two skills should reference each other and don't | `project-knowledge-base` should call out `cognitive-alignment` as a partner; the SKILL.md doesn't yet. |

If a candidate spans multiple kinds, split it into multiple proposals.
One proposal = one atomic change.

## When to fire

Proactively when:

- A user reformulates the same request three different ways before the
  right skill fires — the description needs the phrasing they tried.
- You catch yourself thinking *"the skill says X but in this case Y is
  better"* — that's a procedure refinement.
- A failure or wasted step just happened during a workflow — that's an
  anti-pattern candidate.
- The user asks something a reference *should* answer but doesn't —
  that's a reference enrichment.
- You name a partner skill in your own output that isn't in the SKILL.md's
  "Companion skills" section — that's a wiring candidate.

Reactively when:

- The user says *"this skill should mention X"* or *"add Y to skill Z"*.
- A retrospective on a finished workflow surfaces a pattern.

Do not fire for:

- One-off frustrations that won't generalize.
- "I wish this skill did something completely different" — that's a new
  skill, not an evolution. Use `create-skill` (when it exists) or write
  a fresh SKILL.md.

## Procedure

### Phase 1 — Anchor the observation

Run a quick **cognitive-alignment** check on the observation:

- What specifically did you observe?
- Which skill is it about?
- Which kind of evolution is it (one of the five above)?

If the observation is vague, refine it before writing. Vague proposals
get rejected at merge time.

### Phase 2 — Write the proposal

Save to `docs/skill-evolution/<YYYY-MM-DD>-<skill-slug>-<topic>.md`:

```markdown
---
id: evolution-<skill-slug>-<topic>-001
target: skills/<group>/<skill-name>/SKILL.md
       (or skills/<group>/<skill>/references/<file>.md)
       (or INSTRUCTIONS/<path>.md)
kind: description | procedure | anti-pattern | reference | wiring
status: proposed
created: YYYY-MM-DD
session: <session id / commit sha / branch>
---

# <one-line summary, e.g. "Add 'register' synonym to project-onboarding description">

## Observed

<What happened in live use that surfaced this. Be specific — turn quotes
help. Avoid hand-waving.>

## Current

<The exact current text from the target file. Copy-paste, do not
paraphrase.>

## Proposed

<The exact new text, or a diff. If a diff, format as ```diff with -/+ lines.>

## Rationale

<Why this is an improvement. One paragraph, max.>

## Risks

<What could go wrong, what to watch for, what cases the change might
weaken even as it improves the original target. Be honest. "No known
risks" is a valid entry if true, but think harder before writing it.>

## Suggested action

<merge-now / discuss / supersede an existing proposal / batch with related>
```

### Phase 3 — Surface the memory hook (optional)

If the observation should outlive the session even before the proposal
is merged, write a `feedback` memory via `memory-ontology`:

```markdown
---
name: Evolution candidate — <summary>
description: <one line>
type: feedback
scope: global
created: YYYY-MM-DD
status: tentative
related: [<path/to/proposal.md>]
---

<body — short, pointing at the proposal>
```

This lets a future session re-discover the proposal even if no review
has happened yet.

### Phase 4 — Cross-reference

If the proposal touches a skill that other skills' SKILL.md cite as a
companion, list those cross-references in the proposal so the merge
phase knows what else to update. The merge skill (`skill-merge`) reads
this list to keep wiring consistent.

### Phase 5 — Notify

Surface the proposal to the user in one line:

```
Evolution proposal written: docs/skill-evolution/2026-05-13-project-onboarding-register-synonym.md
Run skill-merge when ready to apply.
```

Do not lobby for the change. The proposal stands on its own; the user
decides.

## What this skill does NOT do

- **Modify the target skill or instruction file.** The proposal is the
  output. Applying it is `skill-merge`'s job.
- **Make multiple changes at once.** One proposal per atomic change. A
  refactor of a whole skill is multiple proposals, batched.
- **Score quality of skills.** Evolution is about specific
  improvements with evidence, not about ranking the catalog.
- **Apply project-specific overrides directly.** Project-specific
  refinements go under `INSTRUCTIONS/projects/<slug>/skill-overrides/`
  (see `references/override-vs-evolution.md`); promotion to the
  canonical skill is a separate, more deliberate move.

## Companion skills

| When… | Use |
|---|---|
| Locking the meaning of an observation before writing it up | `cognitive-alignment` |
| Persisting an evolution candidate so it survives sessions | `memory-ontology` (as `type: feedback`) |
| Applying the proposal to the canonical artifact | `skill-merge` |
| At workflow end, batch-capturing multiple candidates noticed during execution | `skill-orchestrator`'s Phase 4 narration |
| Auditing whether merged proposals actually delivered the promised improvement | `requirement-audit` |

## Anti-patterns

- **Capturing the same observation twice.** Search
  `docs/skill-evolution/` for related slugs before writing a new
  proposal. If one exists, link or supersede.
- **"Mega-proposals" that rewrite a skill from scratch.** That's a new
  skill, not an evolution. Split or rename.
- **Lobbying.** A proposal makes its case once and stops. If the user
  rejects it, the proposal status becomes `rejected` (do not delete —
  the record of "we considered this and chose not to" is valuable).
- **Forgetting risks.** Every change has a risk surface. "No known
  risks" is suspicious; write at least one possible failure mode.
- **Writing proposals without evidence.** "I think this would be
  better" is not enough. The "Observed" section is non-optional.

## Reference files

- `references/proposal-template.md` — copy-paste template + a worked
  example.
- `references/override-vs-evolution.md` — when to write a
  project-specific override (lives under the project, never promotes
  unless requested) versus an evolution proposal (lives in
  `docs/skill-evolution/`, candidate for promotion to canonical).
