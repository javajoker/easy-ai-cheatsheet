---
name: eval-design
description: Design the evaluation for one task class — 5–10 golden tasks drawn from the project's real work, expected outputs, a PASS/PARTIAL/FAIL rubric per task, and at least one trap task that punishes plausible-but-wrong output. Output is docs/squad/evals/<task-class>/eval-spec.md, approved by the user (Gate 1) before any eval spend. The spec is member-agnostic: one spec per task class, reused for every member and every re-eval, so scores stay comparable. Use this skill when the user says "design an eval for <task class>", "how do we test whether <member> can do X", "build the test set for translation/test-gen/code-review", or when eval-run is invoked for a task class that has no spec yet. Criteria are written before any member output is seen — that ordering is the whole discipline. Pairs with eval-run (executes the spec), squad-verify (shares the PASS/PARTIAL/FAIL row format from requirement-audit), and cognitive-alignment (locks what the task class even means before designing).
---

# Eval Design

Produces the measuring stick. A rating is only as good as the eval behind
it, and an eval is only as good as its resemblance to *your actual work*
— so golden tasks come from the project's history, not from generic
benchmark imagination, and the rubric is committed before anyone sees a
member's output.

## Procedure

### Phase 0 — Lock the task class

Confirm which roster task class this spec measures (`bulk-transform`,
`code-gen`, `code-review`, `test-gen`, `doc-writing`, `translation`,
`summarize-extract`, `research`) and what it concretely means *in this
project* — run `cognitive-alignment` if the boundary is contested (is
"fix the failing tests" test-gen or code-gen?). One spec per task class;
if a spec already exists under `docs/squad/evals/<task-class>/`, this is
a revision, not a new design — keep score comparability in mind and bump
a version note in the spec.

### Phase 1 — Harvest golden tasks

5–10 tasks, sourced in priority order:

1. **Real past tasks** from this project (git history, closed issues,
   docs) — anonymized to `public`-class content if the member pool isn't
   data-cleared yet.
2. **Imminent real tasks** — things the user actually wants routed soon.
3. Synthetic tasks only to fill coverage gaps (e.g. the long-input probe).

Coverage requirements:

- At least one **trap task**: a task where the plausible-looking wrong
  answer is the common failure (translating inside code blocks; tests
  that assert buggy current behaviour; a summary that inverts a negation).
  Trap results dominate how much verification a member's output will
  need, which dominates its true cost.
- At least one **scale probe**: input near the size the real work runs at.
- Inputs must be self-contained — members start cold; a golden task that
  needs session context is measuring the wrong thing.

### Phase 2 — Write the rubric

Per task: the expected output (or properties of it) and what PASS,
PARTIAL, and FAIL mean — in the `requirement-audit` row format that
`squad-verify` and `eval-run` both speak. Rubric lines must be checkable
by a cold reader: "translation is good" fails the bar; "all `{0}`
placeholders preserved; glossary terms per `INSTRUCTIONS/projects/<slug>/`
used" clears it. Prefer mechanically checkable criteria (diffs, greps,
test runs) — they make scoring cheap and repeatable.

### Phase 3 — Estimate and gate (Gate 1)

Write `docs/squad/evals/<task-class>/eval-spec.md`: the tasks, rubric,
data-class of the fixtures, and an estimated dispatch cost per member.
Surface it for approval. **Nothing is spent until the user approves the
spec.**

## Anti-patterns

- **Benchmark cosplay.** Generic LeetCode-style tasks measure the
  leaderboard, not your work. Golden tasks come from your repo's reality.
- **Rubric-after-the-fact.** Criteria written (or "clarified") after
  seeing an output are not criteria. The spec freezes first.
- **No traps.** An eval a member can pass while being confidently wrong
  produces ratings that fail exactly when stakes are high.
- **Sensitive fixtures.** Eval fixtures go to *uncleared* members by
  definition (that's why you're evaluating). Keep them `public`-class
  unless clearance already exists.
- **Per-member specs.** One spec per task class, or scores can't be
  compared across members and across time.

## Companion skills

| When… | Use |
|---|---|
| Executing the spec against members | `eval-run` |
| The task-class boundary is contested | `cognitive-alignment` |
| Borrowing the audit row format | `requirement-audit` |
