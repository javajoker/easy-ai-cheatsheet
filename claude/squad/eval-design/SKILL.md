---
name: eval-design
description: Design the evaluation for one task class — 5–10 golden tasks drawn from the project's real work, a PASS/PARTIAL/FAIL rubric per task (golden-output mode for tasks with one right answer; rubric-band mode for creative/subjective classes where no single output is correct), at least one trap task that punishes plausible-but-wrong output, and an evaluator-bias guard (blind scoring + cross-vendor/human spot-check, so the in-house scorer doesn't reward Claude-shaped output). Output is docs/squad/evals/<task-class>/eval-spec.md, approved by the user (Gate 1) before any eval spend. Can run as a calibration run (dispatch the golden set to members AND in-house, report cost/quality/latency/success — the squad-vs-baseline benchmark). The spec is member-agnostic: one spec per task class, reused for every member and every re-eval, so scores stay comparable. Use this skill when the user says "design an eval for <task class>", "how do we test whether <member> can do X", "build the test set for translation/test-gen/code-review", "is routing this even worth it vs in-house", or when eval-run is invoked for a task class that has no spec yet. Criteria are written before any member output is seen — that ordering is the whole discipline. Pairs with eval-run (executes the spec), squad-verify (shares the PASS/PARTIAL/FAIL row format from requirement-audit), and cognitive-alignment (locks what the task class even means before designing).
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

#### Two rubric modes — pick by task shape

- **Golden-output mode** (default) — for tasks with a single correct
  result (extraction, conversion, code that must compile, translation
  with a glossary). Score by match-to-expected, the mode above.
- **Rubric-band mode** — for **creative / open-ended / subjective** task
  classes (`research` synthesis, `doc-writing` prose, naming, design
  rationale) where no single output is "the" answer. Here a golden output
  is a category error. Instead, define **criteria-referenced bands**:
  3–5 named dimensions (e.g. *coverage, correctness of claims, structure,
  voice*) each with explicit PASS/PARTIAL/FAIL descriptors a cold reader
  can apply, plus a hard floor of must-not-fail dimensions (a beautifully
  written research summary with a fabricated citation is FAIL regardless
  of voice). The trap-task discipline still holds — the trap is the
  *confidently-wrong claim*, not the *imperfect phrasing*. Bands keep
  even subjective scoring repeatable across members and across re-evals.

Even in band mode, anchor every dimension on a verifiable sub-claim where
one exists (a citation either resolves or it doesn't) — push as much of
the score onto checkable ground as the task allows, and reserve the bands
for what genuinely needs judgment.

### Phase 3 — Guard against evaluator bias

The scorer is in-house Claude — which can quietly reward output that
*looks like Claude's own* (its phrasing, its structure) over output
that's equally correct in another voice. In band mode especially, that
bias corrupts the very ratings the layer routes on. Build the guard into
the spec:

- **Blind where you can.** Score against the rubric without knowing which
  member produced a return; strip member identity from the scoring view.
- **Anchor on the verifiable.** Bias hides in subjective dimensions —
  the more of the score rests on checkable sub-claims, the less room it
  has.
- **Spot-check the scorer.** For a creative class, have a *cross-vendor
  member or a human* re-score a small sample; a systematic gap between
  their scores and the in-house ones is a bias finding, recorded on the
  spec. Style ≠ quality — a member writing in a different but valid voice
  is not thereby worse (that's the C2 consistency concern, which the kit
  normalizes at author time — don't double-penalize it at eval time).

### Phase 4 — Estimate and gate (Gate 1)

Write `docs/squad/evals/<task-class>/eval-spec.md`: the tasks, rubric
(mode noted), the bias guard, data-class of the fixtures, and an
estimated dispatch cost per member. Surface it for approval. **Nothing is
spent until the user approves the spec.**

### Cold-start: shadow evidence (the cheap bootstrap)

A brand-new member is U everywhere, so it can take only `throwaway` work
— a chicken-and-egg that makes the first evidence expensive. The cheap
escape is **shadow evidence**: route real *low-stakes* tasks to the U
member *in parallel with* the in-house run that's happening anyway, and
score its returns against the in-house result as a free oracle. No extra
in-house spend (that work was being done regardless), and a few shadow
passes seed the `(measured)` record that a formal eval then confirms.
Shadow results are evidence toward a rating, never a rating by
themselves — Gate 4 still applies.

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
