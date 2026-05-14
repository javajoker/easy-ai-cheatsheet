# Checklist Format

The strict format for scenario-checklist output, with two layout variants
(SCENARIOS.md vs inline-during-workflow) and worked examples.

## Layout — for SCENARIOS.md

The checklist lives inside a scenario subsection titled
`### Skills involved — checklist`. Every scenario in `SCENARIOS.md`
follows this shape:

```markdown
## Scenario <letter> — <one-line goal>

**Goal.** <one-paragraph goal>.

### When this fits

- <bullet>

### Procedure

1. <numbered step>

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `<name>` | shipped | <one-line role description> |
| `<name>` | missing | <name suggestion + one-line role> |

### Manual fallback (if a skill is missing or unavailable)

<one paragraph>

---
```

The `### Skills involved — checklist` heading is exact — do not vary it
(other scenarios scan for it, and tooling may grep on it).

## Layout — inline during a workflow

When surfacing the checklist mid-conversation (not for inclusion in a
doc), drop the `###` heading and prepend a one-line context:

```markdown
For this workflow, the participating skills are:

| Skill | Status | Role |
|---|---|---|
| `skill-orchestrator` | shipped | Picks and chains the producer skills. |
| `cognitive-alignment` | shipped | Surfaces ambiguous terms early. |
| `<producer-skill>` | shipped | <role>. |
| `<missing-skill>` | missing | <name + role>. |

Gaps: 1. Recommended next step: <action>.
```

The table is identical to the SCENARIOS.md form; only the heading and the
surrounding context differ.

## Mandatory rows

Every checklist includes (in this order, when applicable):

1. `skill-orchestrator` — except for single-skill scenarios that need no
   orchestration.
2. The work-doing producer skills — one row each.
3. `cognitive-alignment` — always.
4. `memory-ontology` — always (even if the scenario doesn't write
   memory, surface the option).
5. `compact-ritual` — always for long workflows; mention as optional for
   short ones.

If a scenario genuinely does not need a meta-skill (e.g. a one-off
question that doesn't even involve a workflow), say so explicitly in the
prose rather than omitting the row. Silent omission looks like an
oversight; explicit "not applicable here" looks like a decision.

## Row format

Each row has exactly three columns:

```
| `skill-name` | <status> | <role description> |
```

- **Skill name** is in backticks. Always.
- **Status** is one of the four vocabulary words: `shipped`,
  `project-specific`, `opt-in`, `missing`.
- **Role description** is one line, sentence-case, ending with a period.

Multi-line role descriptions or unusual statuses are signs the checklist
is trying to do too much. Split the requirement, or move detail to the
scenario's procedure section.

## Summary line

After the table, always include:

```
Gaps: N. Recommended next step: <one concrete action>.
```

Even when N=0, the recommended next step is useful — it tells the user
how to actually execute the workflow.

## Worked example

A request: *"What's the checklist for migrating a project's i18n locale
list?"*

```markdown
For this workflow, the participating skills are:

| Skill | Status | Role |
|---|---|---|
| `skill-orchestrator` | shipped | Plans the migration steps in order. |
| `cognitive-alignment` | shipped | Confirms the meaning of "migrate" (extend? replace? archive?). |
| `project-onboarding` | shipped | Refreshes `INSTRUCTIONS/projects/<slug>/` if the locale list is documented there. |
| `create-project-instruction` | shipped | Re-emits project-context.md with the updated locale set. |
| `memory-ontology` | shipped | Records the migration decision and rationale as a `type: project` memory. |
| `compact-ritual` | shipped | Available if the migration spans a long session. |
| `i18n-migration` | missing | Suggested name for a dedicated skill that handles locale-file conversion, fallback rules, and translation diffing. |

Gaps: 1. Recommended next step: run `project-onboarding --refresh` to update
the project notes; until `i18n-migration` exists, follow `INSTRUCTIONS/
standards/code-standards.md` and the project's existing i18n conventions
manually.
```
