# Task Management

> How to plan, track, and record progress on multi-step work. Per-project
> task organization (file paths, granularity, agile rituals) lives in
> `projects/<name>/`.

## Tools, in priority order

1. **The harness's TodoWrite tool** — for tracking the *current session's*
   actionable items. Always preferred for multi-step work happening now.
2. **The `task-breakdown` skill output** — when planning a project from a
   PRD or spec. Produces structured task files that future sessions can
   pick up.
3. **The `memory-ontology` skill** — when a decision or finding from this
   session should outlive it.

Markdown task files are for *persisting* plans across sessions. The
TodoWrite tool is for *executing* against them in the current session. Use
both; do not duplicate.

## The minimum a project should maintain

Most projects benefit from three artifacts. Adapt names to taste.

- **`docs/task_plan.md`** — the master list of in-flight and upcoming work
  items, with status and owner where known.
- **`docs/findings.md`** — significant decisions, surprises, and
  trade-offs as they happen. Append-only.
- **`docs/progress.md`** — short journal of what shipped, by date. Useful
  for stand-ups and for reconstructing context after a long gap.

These three together let any new contributor (human or AI) catch up in
fifteen minutes.

## When to write a per-session note

If a working session has produced anything worth handing off to the next
session — partial progress on a long task, an investigation that surfaced
unexpected complexity, a decision waiting on stakeholder input — write a
short note before closing out.

Suggested location: `docs/memory/<YYYY-MM-DD>-<short-slug>.md`. Suggested
content:

```markdown
# 2026-05-13 — session notes

## Done
- Implemented X
- Added unit tests for Y

## In progress
- Z (60%) — next step is converting the Foo helper to the new interface

## Blocked
- Q needs product input on the validation rules

## Decisions
- Chose Bar over Baz for caching because of the multi-tenant requirements;
  recorded in findings.md

## Next session pickup
- Resume on Z step 5; reference task_plan.md item T-042
```

## Sync rules

When the project hits a milestone:

- Update `task_plan.md` with the new state of each item.
- Append a `findings.md` entry if the milestone produced any non-trivial
  decisions.
- Append a `progress.md` entry summarizing what shipped.
- Update `projects/<name>/` if the milestone changes anything about the
  project's structure, conventions, or stack.

Drift between these files is the most common failure mode. A skill audit
pass (see `memory-ontology`) catches drift before it accumulates.

## Granularity

A task is the right size when:

- It has a single, verifiable success criterion.
- It fits in one session (or one chunk of a session).
- Its dependencies are explicit.
- It is at most ~1 day of work.

If a task is "build the auth subsystem", that is an epic, not a task. Break
it down before starting.

## Working with `task-breakdown` output

When a project was set up via the `task-breakdown` skill, the per-task
markdown files under `tasks/` are the authoritative source. The three
top-level documents above are derivative views. Update the task file first,
let the derivative views catch up.

---

**Version**: 2.0.0
**Updated**: 2026-05-13
