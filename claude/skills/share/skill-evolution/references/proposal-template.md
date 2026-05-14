# Proposal Template

Copy this when writing a new evolution proposal. Save under
`docs/skill-evolution/<YYYY-MM-DD>-<skill-slug>-<topic>.md`.

## Template

```markdown
---
id: evolution-<skill-slug>-<topic>-001
target: skills/<group>/<skill-name>/SKILL.md
kind: description | procedure | anti-pattern | reference | wiring
status: proposed
created: YYYY-MM-DD
session: <session id / commit sha / branch>
related: [<other proposal IDs if any>]
---

# <one-line summary>

## Observed

<Specific, quoted, evidence-based. Include turn references where useful.>

## Current

<Exact current text. Copy-paste from the target file.>

## Proposed

<Exact new text, or a diff.>

## Rationale

<Why this is an improvement. One paragraph.>

## Risks

<Honest failure modes. Even "minor" risks belong here.>

## Suggested action

<merge-now / discuss / batch-with-related / superseded-by-<id>>
```

## Worked example — description kind

```markdown
---
id: evolution-project-onboarding-register-synonym-001
target: skills/ideas/project-onboarding/SKILL.md
kind: description
status: proposed
created: 2026-05-13
session: branch claude/blissful-hopper-a8cad7
---

# Add "register" synonym to project-onboarding description

## Observed

During session on 2026-05-13, user said *"register this project with the
framework"*. `project-onboarding` did not fire because the description
includes "onboard"/"set up"/"scan" but not "register". User had to
explicitly invoke the skill by name on the second try.

## Current

description: >
  Onboard an existing codebase to the Claude Code framework. […]
  USE THIS SKILL when:
  - the user opens a Claude Code session in a project for the first time
  - the user asks "onboard this project", "set up Claude Code here",
    "scan the repo and learn it", "what is this project?"

## Proposed

description: >
  Onboard an existing codebase to the Claude Code framework. […]
  USE THIS SKILL when:
  - the user opens a Claude Code session in a project for the first time
  - the user asks "onboard this project", "register this project",
    "set up Claude Code here", "scan the repo and learn it",
    "what is this project?"

## Rationale

Adding "register" expands automated triggering for users who think of
the action as registration with a framework rather than onboarding to it.
Both framings are common; both should match.

## Risks

Marginal — adding a synonym does not narrow the skill's scope, and
"register" is unambiguous in this context. Watch for false-fires from
unrelated registration intents (e.g. "register a route") but the
surrounding context ("project") should keep this disambiguated.

## Suggested action

merge-now
```

## Worked example — anti-pattern kind

```markdown
---
id: evolution-task-breakdown-granularity-001
target: skills/ideas/task-breakdown/SKILL.md
kind: anti-pattern
status: proposed
created: 2026-05-13
---

# Add "over-decomposition for small projects" anti-pattern

## Observed

Ran task-breakdown on a 5-screen prototype; output contained 87 tasks
across 12 components. User had to manually consolidate to 14 tasks. The
skill produced what it produces for a real project — but the project
was a prototype-scale effort.

## Current

(Anti-patterns section currently lists three patterns. No granularity
warning.)

## Proposed

Append to the Anti-patterns list:

- **Over-decomposition for small projects.** A 5-screen prototype does
  not need 80 tasks. Before generating, ask the user for an estimated
  project size; if "prototype" or "MVP" or fewer than ~10 screens,
  default to coarser-grained tasks (one task per screen plus shared
  infra) instead of decomposing each screen further.

## Rationale

The current procedure scales with screen count without scaling with
project lifecycle stage. Adding the size question up front lets the
skill produce useful output for both prototypes and real production
work, instead of defaulting to production-scale granularity.

## Risks

The size estimate is subjective; users may underestimate. Mitigation:
mark inferred sizes with `← inferred` in the output so the user can
upgrade.

## Suggested action

discuss — interacts with project-prototype's lifecycle stage, want to
check whether the question should live there instead.
```
