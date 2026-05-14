# Conflict Resolution

Three overlap modes, with worked examples and resolution recipes for
each.

## Mode A — No overlap

**Detection:** two proposals target the same file but touch different
sections.

**Example:** Proposal 1 adds an anti-pattern; Proposal 2 enriches a
reference file.

**Resolution:** apply both, order doesn't matter. Render context
between applies in case one shifts line numbers.

```diff
File: skills/ideas/task-breakdown/SKILL.md

(Proposal 1 — new anti-pattern, appended to Anti-patterns section)
+ - **Over-decomposition for small projects.** [...]

File: skills/ideas/task-breakdown/references/ai-prompt-library.md

(Proposal 2 — new reference content, no overlap with Proposal 1)
+ ## Prompt template for prototype-scale tasks
+ [...]
```

No friction — just apply.

## Mode B — Adjacent overlap

**Detection:** two proposals modify nearby lines but not the same
text. Edits compose if applied in order.

**Example:** Proposal 1 adds "register" to a trigger phrase list;
Proposal 2 adds an entirely new trigger phrase right after.

**Resolution:** apply in a stable order (by `id:` ascending or by
`created:` ascending). After each apply, re-locate the next proposal's
target text via search rather than absolute line numbers.

```diff
Before:
  - the user asks "onboard this project", "set up Claude Code here",
    "scan the repo and learn it"

After Proposal 1 (add "register"):
  - the user asks "onboard this project", "register this project",
    "set up Claude Code here", "scan the repo and learn it"

After Proposal 2 (add a new bullet about refresh):
  - the user asks "onboard this project", "register this project",
    "set up Claude Code here", "scan the repo and learn it"
  - the user wants to refresh an existing project's INSTRUCTIONS after
    a long inactive period
```

Both land.

## Mode C — Direct overlap (conflict)

**Detection:** two or more proposals replace the same text with
different replacements.

**Example:** Proposal 1 says cap the "5–7 questions" to 3 for small
projects; Proposal 2 says cap it to 4 for any project that doesn't
have a tech design yet.

**Resolution:** stop. Surface the conflict explicitly:

```
Conflict on skills/ideas/project-onboarding/SKILL.md, Phase 3:

Proposal A (evolution-project-onboarding-question-cap-001):
  Replace "Cap at 5–7 questions" with:
    "Cap at 5–7 questions for typical projects; cap at 3 for projects
     with fewer than 5 files."

Proposal B (evolution-project-onboarding-question-cap-002):
  Replace "Cap at 5–7 questions" with:
    "Cap at 5–7 questions for projects with a tech design; cap at 4
     when no tech design exists."

Resolution options:
  1. Pick one (mark the other `rejected`).
  2. Synthesize: write a third proposal that combines both intents
     and mark A and B as `superseded`.
  3. Sequence: apply A first; then derive a new proposal from B's
     intent that builds on A's new text.

Which would you like?
```

Wait for the user's choice. Do not pick.

### After synthesis

If the user picks option 2, the synthesized proposal might look like:

```
Replace "Cap at 5–7 questions" with:
  "Cap at 5–7 questions for typical projects.
   Cap at 3 for tiny projects (fewer than ~5 files).
   Cap at 4 for projects without a tech design,
   regardless of size."
```

Mark Proposals A and B as `superseded` (point at the synthesized one
in their front matter); apply the synthesized one.

### After sequencing

If the user picks option 3, apply Proposal A. Then re-read Proposal
B's "Current" section against the now-modified file:

```
Proposal B says "Current: Cap at 5–7 questions"
File now reads: "Cap at 5–7 questions for typical projects; cap at 3 for projects
                 with fewer than 5 files."

Proposal B's text no longer matches. Either:
  a) Reject B (the new text already addresses the spirit of B), or
  b) Derive a new proposal B' that targets the new text.
```

Surface this back to the user.

## Mode D — Cross-file conflict (rare but possible)

**Detection:** two proposals each consistent within their own target
file, but together they would create an inconsistency across files
(e.g. Proposal 1 removes a trigger phrase from skill A; Proposal 2
adds skill B to companion section of skill A that now references the
removed phrase).

**Resolution:** treat as a Mode C conflict scoped to "the joint
intent." Synthesize or sequence; do not apply independently.

This is rare in practice — most evolution proposals are scoped to one
section of one file. But it's worth checking during Phase 2.

## Resolution audit

After resolving conflicts, the resolution itself is part of the
record:

- Updated proposal statuses (rejected / superseded / synthesized-into)
  appear in their front matter.
- The merge's success summary in Phase 6 names which conflicts were
  resolved and how.

A future audit reading `docs/skill-evolution/` should be able to
reconstruct *what was considered, what was chosen, and why* without
needing the live conversation.
