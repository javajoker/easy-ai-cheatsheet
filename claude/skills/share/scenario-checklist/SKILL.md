---
name: scenario-checklist
description: Produce a per-scenario skills checklist for any workflow — list the skills that will (or should) participate, their role in that scenario, their availability status (shipped / project-specific / missing), and any gaps that need filling before the workflow can run. Output mirrors the "Skills involved — checklist" tables in SCENARIOS.md and is the canonical format for adding a new scenario or for surfacing the plan before execution. Use this skill when authoring a new scenario for SCENARIOS.md, when a user asks "what skills will this use?", when planning a workflow that has not been done before, or when reviewing whether the framework can handle a proposed workflow. Reads the skill catalog at runtime — does not hardcode skill lists. Pairs with skill-orchestrator (which uses the checklist to plan execution) and with requirement-audit (which uses scenario-checklist output as one form of evidence).
---

# Scenario Checklist

A skill for producing the "which skills participate in this workflow?"
checklist. The output is the same shape used in `SCENARIOS.md` — a table
with skill, status, and role columns — and is the canonical way to add a
new scenario or to surface the plan to the user before execution.

## Why this exists

Two related needs share an answer:

1. When adding a new scenario to `SCENARIOS.md`, the per-scenario "Skills
   involved" table is what makes the scenario actionable. Authoring it by
   hand is tedious and error-prone — easy to forget a meta-skill, easy to
   miss a gap.
2. When the user asks "what would it take to do X?", the most honest
   answer is the same kind of checklist: here is the chain, here is what
   exists, here is what's missing.

Both reduce to one operation: read the catalog, classify which skills
apply, mark gaps. This skill encodes that operation.

## Output format

The deliverable is a markdown table plus a short summary, matching the
format used throughout `SCENARIOS.md`.

```markdown
### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `<name>` | shipped / project-specific / missing | <one-line role description> |
| `<name>` | … | … |

Gaps: <count of missing skills>. Recommended next step: <one concrete action>.
```

Status vocabulary (fixed; do not invent new statuses):

- **shipped** — exists in the framework and applies generically.
- **project-specific** — exists but only applies to one project (lives
  under `skills/projects/`).
- **opt-in** — exists but requires explicit project adoption (e.g.
  Obsidian-flavoured `doc-markdown-standards`).
- **missing** — does not exist. The checklist names the gap; another
  skill (project-onboarding, the user) fills it.

## Procedure

### Phase 1 — Anchor the scenario

Get a one-paragraph statement of the workflow being checklisted:

- What is the user trying to accomplish?
- What inputs does the workflow start with?
- What outputs does it produce?
- What is in scope, what is out?

If anchoring is unclear, run a **cognitive-alignment** check before
proceeding. A vague scenario produces a vague checklist.

### Phase 2 — Read the catalog

The skill catalog is enumerated in the system prompt under
`<available_skills>` (or equivalent harness mechanism). Read every entry's
description, not just the names — see `skill-orchestrator/SKILL.md` Phase 1
for the same discipline.

Identify every skill whose description plausibly applies to the scenario.
Borderline skills get included with a note rather than excluded silently.

### Phase 3 — Decompose into roles

Split the scenario into discrete sub-tasks. Each sub-task maps to one or
more skills:

- **Producer skills** — produce a deliverable (project-frontend,
  task-breakdown, create-project-instruction).
- **Coordinator skills** — pick or chain producers (skill-orchestrator,
  project-onboarding).
- **Meta-skills** — run alongside (cognitive-alignment, memory-ontology,
  compact-ritual) and are nearly always present.

The meta-skills row is mandatory in every scenario checklist — they are
not optional, even when the scenario doesn't explicitly mention them.

### Phase 4 — Classify status

For each skill identified, classify:

- Present in the catalog and applies generically → `shipped`.
- Present but under `skills/projects/<slug>/` → `project-specific`.
- Present but requires the project to opt in (declared in its `SKILL.md`
  frontmatter or noted in this file's status vocabulary) → `opt-in`.
- Absent from the catalog → `missing`. Suggest a name for the missing
  skill in the role column.

### Phase 5 — Emit the checklist

Write the table in the format above. Below the table:

- One-line summary of total skills and gap count.
- One concrete recommended next step (the most valuable single action).
- (Optional) "Manual fallback" subsection if any rows are `missing`.

### Phase 6 — Cross-reference

If the checklist is for inclusion in `SCENARIOS.md`, update:

- The scenario's own "Skills involved" table.
- The appendix's per-group counts.
- The "Known gaps" subsection if any rows are `missing`.

If the checklist is for inline use during a workflow, no document updates
are needed — the table itself is the deliverable.

## Examples of when to use

- *"Add a scenario for migrating a project's database — what skills will
  be involved?"* — scenario-checklist produces the table.
- *"Plan an audit pass over our docs."* — scenario-checklist surfaces the
  chain (project-knowledge-base + requirement-audit + cognitive-alignment).
- *"Can the framework do X?"* — scenario-checklist's output answers
  honestly with `missing` rows where the framework falls short.

## Companion skills

| When… | Use |
|---|---|
| Locking the meaning of an ambiguous scenario term before checklisting | `cognitive-alignment` |
| After checklisting, to plan and execute the workflow | `skill-orchestrator` |
| To verify the workflow's deliverables once executed | `requirement-audit` |
| To capture the checklist as the next session's starting point | `memory-ontology` |
| For long workflows where the checklist survives `/compact` | `compact-ritual` |

## Anti-patterns

- **Listing every skill in the catalog.** A checklist that names 30
  skills tells the user nothing. Pick the skills that actually
  participate; cap mandatory rows at the meta-skills plus the work-doing
  skills (typically 5–10 total).
- **Omitting meta-skills.** `cognitive-alignment`, `memory-ontology`,
  `compact-ritual` are present in every scenario checklist. Always.
- **Marking `missing` without a name.** When a row is `missing`, suggest
  a name (kebab-case, role-appropriate). Anonymous gaps don't get filled.
- **Inventing new statuses.** Four statuses, full stop: shipped,
  project-specific, opt-in, missing.
- **Bloating the role column.** One line per role. Detail goes in the
  scenario's procedure section, not the checklist row.

## Reference files

- `references/checklist-format.md` — strict format spec for the output
  table, including how to lay it out in `SCENARIOS.md` vs inline.
- `references/role-vocabulary.md` — controlled vocabulary for role
  descriptions, so different scenarios use the same language for the
  same kind of work.
