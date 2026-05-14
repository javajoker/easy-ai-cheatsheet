---
name: create-project-instruction
description: >
  Generate the per-project INSTRUCTIONS files (project-context.md, repository-structure.md,
  and optional conventions.md) under INSTRUCTIONS/projects/<slug>/ from any of four input
  modes — an existing codebase, a fresh-project conversation, a PRD + tech design, or a
  hybrid. Output is always a filled set of files following the framework's templates plus
  a one-paragraph "what was produced and what was guessed" report. This skill is the focused
  INSTRUCTIONS producer; project-onboarding wraps it for the existing-codebase case (adding
  the scan + memory-seed phases), project-docs wraps it for the new-project case, and it
  can also run standalone when the user already has the inputs in front of them.

  USE THIS SKILL when the user:
  - explicitly asks to "generate the project instructions", "create the project-context file",
    "fill in the project template", "set up INSTRUCTIONS/projects/<x>/"
  - has just completed project-docs / project-onboarding and wants the per-project
    INSTRUCTIONS written
  - is migrating a project to this framework manually and wants the INSTRUCTIONS files
    populated without the full onboarding ceremony
  - has the project's PRD or tech design in hand and wants the INSTRUCTIONS derived directly
  Do NOT trigger this skill for:
  - non-project-instruction documents (those are docs, not INSTRUCTIONS — use the
    appropriate doc skill)
  - re-generating an already-populated INSTRUCTIONS/projects/<slug>/ unless the user says
    "refresh" or "regenerate"
---

# Create Project Instructions

A focused skill that writes the per-project INSTRUCTIONS files. It does *one*
thing — populate `INSTRUCTIONS/projects/<slug>/` — and accepts that input in
several shapes so the same producer serves several scenarios.

## Why this exists

Two related skills already touch INSTRUCTIONS generation:

- **`project-onboarding`** is the end-to-end onboarding pass for an existing
  codebase. Its Phase 4 *generates the instruction artifacts*.
- **`project-docs`** is the doc generator for a new project (PRD, UI/UX, tech
  design). After it finishes, the INSTRUCTIONS files should follow naturally.

If each skill writes its own version of the files, they drift. The cleanest
shape is one focused producer that both skills delegate to, and that the user
can also invoke directly when they have the inputs but don't want the full
ceremony around either of those skills.

## The four input modes

This skill accepts inputs in any of four modes. Identify which one applies
before reading further.

### Mode A — existing codebase

**Inputs.** Path to a repository root. Optionally: a partial conversation
where the user has answered some questions.

**Source of truth.** The code, the manifests (`go.mod`, `package.json`,
`pyproject.toml`, etc.), the CI config, the README, any existing docs.

**Use this mode when.** `project-onboarding` is calling, or the user said
*"create the INSTRUCTIONS files from this codebase"* with a path in hand.

### Mode B — fresh-project conversation

**Inputs.** A plain-language description of the project being planned.
Optionally: a clickable prototype, an idea note.

**Source of truth.** The conversation itself. Many fields will be unknown;
mark them clearly.

**Use this mode when.** The user is at the very start of a project, has not
written specs yet, and wants the INSTRUCTIONS files seeded so that downstream
skills (project-docs, task-breakdown) have a stable target.

### Mode C — PRD + tech design

**Inputs.** A PRD document, a UI/UX spec, a tech design document. Typically
produced by `project-docs`.

**Source of truth.** The documents. Pull stack, languages, integrations,
verification commands directly from the tech design.

**Use this mode when.** `project-docs` has just produced the tri-doc set and
the next step is to consolidate the project's identity into the INSTRUCTIONS
layer.

### Mode D — hybrid

**Inputs.** Some of A, B, and C — for example, an existing codebase *plus* a
new PRD describing where it's headed.

**Source of truth.** Each input governs the fields it covers. Conflicts are
surfaced for user resolution, not silently merged.

**Use this mode when.** Migration, rewrite, or significant pivot.

## The procedure

Four phases. They are the same regardless of input mode; only the data sources
differ.

### Phase 1 — Confirm scope

Ask three questions, max:

- **Slug.** *"What slug should I use under `INSTRUCTIONS/projects/`?"* —
  short, kebab-case, no surprises. Default: lowercase project name, hyphens.
- **Existing instance.** Check whether `INSTRUCTIONS/projects/<slug>/`
  already exists. If yes: confirm overwrite or pick a new slug. Never silently
  overwrite.
- **Primary language for project artifacts.** *"What language should the
  generated files be in? English, or the project's primary language?"* —
  default English; user can pick.

### Phase 2 — Gather

Read or interview, depending on mode:

- **Mode A** — open the manifest files, CI configs, READMEs; use the
  `project-onboarding` skill's `inference-table.md` reference for "what to
  look at for which fact."
- **Mode B** — ask 3–5 targeted questions (project type, stack
  preference, primary language, lifecycle stage, key constraints).
- **Mode C** — extract the relevant sections from each document.
- **Mode D** — combine; flag conflicts.

For every fact, classify confidence as **high** (explicitly stated in source),
**medium** (clear inference), or **low** (guess). Low-confidence facts get
marked in the output so the user can correct without surgery.

### Phase 3 — Fill the templates

Open `INSTRUCTIONS/templates/project-context.md` and
`INSTRUCTIONS/templates/repository-structure.md`. Replace every `{placeholder}`
with the gathered value, or mark `{TBD — <one-line description of what's missing>}`
when no value is known.

For low-confidence fields, append ` ← inferred` so the user can scan and
confirm.

Save the files at:

- `INSTRUCTIONS/projects/<slug>/project-context.md`
- `INSTRUCTIONS/projects/<slug>/repository-structure.md`

If the project has notable conventions beyond what the templates capture,
write a third file:

- `INSTRUCTIONS/projects/<slug>/conventions.md` — a short list of project-
  specific rules. Title pattern: *"What new contributors keep getting wrong."*
  Skip the file entirely if the project has no notable conventions.

### Phase 4 — Report and wire up

Output a short report:

```
Generated INSTRUCTIONS for <project-name>

Files written:
- INSTRUCTIONS/projects/<slug>/project-context.md
- INSTRUCTIONS/projects/<slug>/repository-structure.md
- INSTRUCTIONS/projects/<slug>/conventions.md  (or "(skipped — no project-specific conventions)")

High-confidence facts: <N>
Inferred facts to confirm: <N>
TBD fields: <N>

Next step:
- Reference these files from <project>/.claude/CLAUDE.md so they auto-load.
- Run project-onboarding's memory-seed pass if it has not run.
- Confirm the inferred facts before relying on them.
```

Update `INSTRUCTIONS/projects/README.md`'s "Existing instances" table with a
one-row entry.

## What this skill does NOT do

The boundaries that keep it focused:

- **No codebase scan.** Mode A *reads* what is provided; it does not crawl
  the entire repository. That is `project-onboarding`'s job. (When invoked
  by `project-onboarding`, the scan has already happened.)
- **No memory seeding.** Memories about the project go through
  `memory-ontology`, not through here.
- **No doc generation.** PRD / UI/UX / tech design are produced by
  `project-docs`. This skill consumes those, it does not produce them.
- **No CLAUDE.md edit.** Pointing the project's `CLAUDE.md` at the new files
  is the user's call (sometimes the project has its own `CLAUDE.md`
  conventions). Surface the suggestion in the report; do not edit silently.

## Companion skills

| When… | Use |
|---|---|
| Onboarding an existing codebase end-to-end | `project-onboarding` (which calls this skill in its Phase 4) |
| Writing specs for a new project | `project-docs` (which can call this skill to consolidate identity afterwards) |
| Building the conceptual knowledge base on top of the instructions | `project-knowledge-base` |
| Promoting durable facts surfaced during instruction generation | `memory-ontology` |
| Locking down ambiguous project-specific terms before they ossify | `cognitive-alignment` |

## Anti-patterns

- **Silent overwrites.** Always check for an existing instance; ask before
  overwriting.
- **Hidden inference.** Do not write a high-confidence fact in the output
  without high-confidence evidence. Better to mark `← inferred` and let the
  user correct.
- **Skipping conventions.md when it would help.** If the user mentioned even
  one project-specific rule, capture it. The threshold for `conventions.md`
  is one rule, not five.
- **Filling in fictional values to avoid TBDs.** A `{TBD}` is helpful; a
  fabricated value is dangerous. The downstream readers will trust what is
  written.

## Reference files

- `references/mode-playbooks.md` — phase-by-phase playbook for each of the
  four input modes, with worked examples.
- `references/inferred-vs-tbd.md` — guidance on when to infer (with marker)
  versus when to leave `{TBD}`.
