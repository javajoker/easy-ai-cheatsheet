# Tuning Playbook — a worked retune

One end-to-end run of `skill-version-tune`, so the procedure is concrete.
We retune **`task-breakdown`** (a real skill in this framework, under
`skills/ideas/task-breakdown/`) for **Opus 4.8 + the current CC harness**.

This is illustrative. The exact findings depend on the skill's current
text and the capability sheets at the time you run it — do not copy the
proposals below verbatim; reproduce the *method*.

---

## Phase 0 — Identify

- **Target skill:** `skills/ideas/task-breakdown/SKILL.md`.
- **Target version:** user said "modernise this for the latest Claude and
  Claude Code." Two axes → run `tune-for-opus-4-8` and `tune-for-cc-harness`
  in sequence. Confirmed the running model is `claude-opus-4-8` from the
  session context, so 4.8 is reachable. The harness in use exposes the
  Skill tool, the Agent (subagent) tool, background tasks, plan mode, and
  parallel tool calls — all reachable.

## Phase 1 — Load sheets

Read `tune-for-opus-4-8/references/capabilities.md` and
`tune-for-cc-harness/references/capabilities.md`. Note which lines are
`(confirmed)` vs `(inferred)` — they change how the Risks sections read.

## Phase 2 — Gap analysis

Walking `task-breakdown` against the capability → skill-shape map:

| Observation about the skill today | Capability | Finding? |
|---|---|---|
| The procedure decomposes a doc, then (conceptually) processes components one after another | Parallel tool calls (harness, `confirmed`) | **Yes** — independent component analyses can be batched |
| It produces many task files; large breakdowns push context | Context compaction + larger window (harness `confirmed` / model `inferred`) | **Yes** — the "keep it terse or context overflows" caveat can relax |
| It does the whole breakdown inline, even for large repos | Subagents (harness, `confirmed`) | **Yes** — the per-component first-pass scan can fan out to `Explore` |
| It already asks for inputs up front | Batched questioning (model) | **No finding** — already batched |
| It has a generic anti-patterns list | Effort control on the decomposition step (model, `inferred`) | **Maybe** — defer; depends on confirming 4.8's effort surface |

Three solid findings, one deferred (because it leans on an `(inferred)`
capability). Note we did **not** invent a finding for every capability — the
already-batched questioning yields nothing.

## Phase 3 — Emit proposals

Three atomic proposals. Shown abbreviated; real ones use the full
`skill-evolution` template.

### Proposal 1 — `procedure`, harness, confirmed

```markdown
---
id: evolution-task-breakdown-parallel-components-001
target: skills/ideas/task-breakdown/SKILL.md
kind: procedure
tuned-for: cc-harness-2026-06
status: proposed
created: 2026-06-09
session: branch claude/eager-swirles-42c1f1
---

# Batch independent component analyses into parallel tool calls

## Observed

Capability sheet: tune-for-cc-harness/references/capabilities.md —
"Parallel tool calls (confirmed): independent tool calls in one assistant
turn execute concurrently." task-breakdown's procedure analyses components
in sequence; component analyses that don't depend on each other are
independent and can be issued in one batched step.

## Current

<exact current procedure step text>

## Proposed

<revised step: "issue the independent component read/analysis calls in a
single batched step; only serialise where DEPENDENCY_GRAPH ordering forces
it">

## Rationale

Independent work that ran serially now runs concurrently with no change to
output quality — a latency win the skill simply wasn't written to take.

## Risks

Components with hidden ordering dependencies must still serialise — the
proposed text keeps the DEPENDENCY_GRAPH carve-out so this doesn't
flatten genuinely ordered work. No model-version dependency (harness
capability, confirmed).

## Suggested action

merge-now
```

### Proposal 2 — `procedure` + `wiring`, harness, confirmed

Relax the context-budget caveat and cross-link `compact-ritual`:
the skill can produce a fuller breakdown and rely on compaction +
`compact-ritual` to survive a long generation, rather than truncating
defensively. Risks: don't *remove* the discipline of terse task files —
relax the caveat, don't delete it.

### Proposal 3 — `procedure` + `wiring`, harness, confirmed

Delegate the per-component first-pass scan to an `Explore` subagent for
large repos. Risks: subagents start cold and re-derive context; only worth
it above a size threshold — the proposal names the threshold so the skill
doesn't fan out a 5-file repo.

### Deferred — effort control

Not written. It depends on an `(inferred)` 4.8 capability (the exact
effort-control surface). The gap-analysis table records it as "Maybe —
defer"; when the 4.8 capability sheet's `(inferred)` line is confirmed
against release notes, write it then.

## Phase 4 — Hand off + stamp

```
Wrote 3 version-tune proposal(s) for task-breakdown:
  docs/skill-evolution/2026-06-09-task-breakdown-parallel-components.md
  docs/skill-evolution/2026-06-09-task-breakdown-relax-context-budget.md
  docs/skill-evolution/2026-06-09-task-breakdown-subagent-scan.md
1 finding deferred (effort control — depends on an inferred 4.8 capability).
Run skill-merge when ready to apply.
```

On merge, `skill-merge` stamps `task-breakdown`'s front matter:
`tuned-for: [cc-harness-2026-06]`. (Opus 4.8 produced no *applied* findings
here — the one 4.8 finding was deferred — so `opus-4-8` is **not** added
yet. `tuned-for` records what landed, not what was attempted.)

## Phase 5 — Memory hook

Because this is the first of a planned "modernise the ideas/ skills" pass,
write a `type: feedback` memory: "Tuning ideas/ skills for cc-harness-2026-06;
done: task-breakdown; next: project-docs, project-frontend." The next
session resumes from there.

---

## What this worked example demonstrates

1. **Two axes, run separately.** Model and harness are different workers;
   their proposals are attributable to different `tuned-for` tokens.
2. **Findings are a subset of capabilities.** Five capabilities considered,
   three findings, one no-finding, one deferred. The sieve worked.
3. **`(inferred)` capabilities don't ship proposals** until confirmed —
   they get deferred, not fabricated.
4. **`tuned-for` records reality.** Only the harness token landed because
   only harness findings were applied.
