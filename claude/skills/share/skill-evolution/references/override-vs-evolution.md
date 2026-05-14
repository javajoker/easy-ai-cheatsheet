# Override vs. Evolution

Two different mechanisms for refining how a skill behaves in practice.
Pick the right one or you will fight the framework instead of bending
it.

## Project-specific override

A **project-specific override** lives under
`INSTRUCTIONS/projects/<slug>/skill-overrides/<skill-name>.md` and
applies *only* when Claude is working inside that project. It does not
modify the canonical skill.

Use when:

- The refinement applies to *one* project's quirks (compliance,
  legacy code, specific naming convention).
- The refinement contradicts the canonical skill's default but the
  contradiction is correct for this project.
- Different projects need different versions of the same behaviour.

Shape:

```markdown
---
target-skill: <name>
applies-to: project:<slug>
created: YYYY-MM-DD
---

# Override for <skill> in <slug>

## What changes

<Specific behaviours the canonical skill does that this project does
differently. State the canonical behaviour, then state the override.>

## Why

<Why the canonical default is wrong for this project specifically. The
"why" is what prevents the override from accidentally becoming a
general improvement that should have been an evolution proposal.>
```

The orchestrator reads `INSTRUCTIONS/projects/<slug>/skill-overrides/`
when a project is active and treats those files as additive guidance.

## Evolution proposal

An **evolution proposal** (this skill's output) lives under
`docs/skill-evolution/` and proposes a change to the *canonical* skill.
Once merged, every project sees the change.

Use when:

- The refinement would be useful across most projects, not just this
  one.
- The current canonical behaviour is genuinely wrong (not just wrong
  for this case).
- Multiple projects have applied the same override; the pattern is
  worth promoting.

## The promotion path

The two mechanisms compose:

1. A project hits a case where the canonical skill misfires. Write an
   override (fast — fixes today's work).
2. Time passes. The same override pattern appears on a second project.
   Worth promoting.
3. Write an evolution proposal that lifts the override into the
   canonical skill. The proposal cites both overrides as evidence.
4. Run `skill-merge`. Once merged, the overrides become redundant —
   the canonical skill now does what they enforced.
5. Remove the redundant overrides (or supersede them with a note
   pointing at the new canonical behaviour).

This is the same shape as cognitive-library entries promoting into
memory-ontology — *local* learning that earns its way to *global*
status through repeated confirmation.

## Decision flowchart

```
Did the refinement apply to one project only?
├─ yes → Override under INSTRUCTIONS/projects/<slug>/skill-overrides/
│
└─ no → Does it apply to most projects?
        ├─ yes → Evolution proposal under docs/skill-evolution/
        │
        └─ I'm not sure → Start with an override. Promote later if it
                          turns out to be general.
```

When in doubt, override first. Promotion is cheap once a pattern is
clear; un-merging a too-eager evolution is expensive.

## What does NOT belong in either

- One-off frustrations ("the skill annoyed me today"). Sit with it.
- Wholesale rewrites ("this skill should do something different").
  Write a new skill, don't override or evolve.
- Bug reports ("this skill produces wrong output"). Those are bugs —
  file them as such, fix the skill directly with a regular commit, do
  not route through the override / evolution path.

The override and evolution paths are for *refinement*, not for repair
or replacement.
