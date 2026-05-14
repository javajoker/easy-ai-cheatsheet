# Development Principles

> Universal engineering principles for any project Claude Code works on.
> Project-specific stack and convention details live in `projects/<name>/`.

## 1. Think before coding

**Do not assume. Do not hide confusion. Surface trade-offs proactively.**

Before implementing:

- State your assumptions explicitly. If anything is uncertain, ask directly.
- If multiple interpretations exist, list them — do not pick silently.
- If a simpler approach is possible, say so. Push back when needed.
- If something is unclear, stop. Name what is unclear, then ask.

## 2. Simple first

**Solve the problem with the smallest amount of code that works. No speculation.**

- Do not add features that were not asked for.
- Do not create abstractions for one-shot code.
- Do not add "flexibility" or "configurability" that was not requested.
- Do not write error handling for scenarios that cannot happen.
- If you wrote 200 lines where 50 would do, rewrite it.

Ask yourself: *"would a senior engineer say this is too complex?"* If yes,
simplify.

## 3. Surgical edits

**Change only what must change. Clean up only the mess you made.**

When editing existing code:

- Do not "while I'm here" optimize adjacent code, comments, or formatting.
- Do not refactor code that has no problem.
- Preserve the existing style even if you would have written it differently.
- If you spot unrelated dead code, mention it — do not delete it.

When your edit produces orphan code:

- Delete imports, variables, and functions that *your edit* made unused.
- Do not delete pre-existing dead code unless explicitly asked.

The test: every line of change should be directly traceable to the user's
request.

## 4. Goal-driven execution

**Define success criteria. Loop verify until done.**

Turn the task into a verifiable goal:

- *"Add validation"* → *"write a test for invalid input, then make it pass"*
- *"Fix the bug"* → *"write a test that reproduces the bug, then make it pass"*
- *"Refactor X"* → *"ensure all tests pass before and after the refactor"*

For multi-step tasks, sketch a brief plan first:

```
1. [step] → verify: [check]
2. [step] → verify: [check]
3. [step] → verify: [check]
```

Clear success criteria let you loop independently. Vague criteria
(*"make it work"*) require constant confirmation.

## 5. No silent mocking

- **Do not mock data inside application code.** If a code path needs sample
  data for development, the data goes in a seed script that writes to the
  development database, not in the production code path.
- **Do not swallow errors with default fallback values.** If an operation
  fails, return the error. The caller decides whether to substitute a
  default — and the caller is the one that has the context to do so safely.
- **Do not invent values for missing inputs.** If a required parameter is
  missing, return a clear error. Do not infer it.

## Development triad

1. **Explore first** — understand requirements and existing code.
2. **Plan next** — design the approach and break down the tasks.
3. **Then code** — implement and verify.

## Minimal-change principle

- Default to the smallest necessary edit.
- Avoid unrelated refactors.
- Preserve existing directory structure and naming conventions.
- Do not silently change public APIs.

## Reuse first

- Prefer existing utilities in the project before introducing new ones.
- Do not duplicate third-party libraries with overlapping scope.
- Do not introduce new infrastructure dependencies unless necessary.

## Code quality baseline

- New code should include necessary error handling and logging.
- New features should include unit tests covering core logic and edge cases.
- Public APIs should have language-appropriate documentation comments
  (godoc, JSDoc, docstrings, KDoc, etc.).
- Avoid `panic` / equivalent abrupt termination in library code (initialization
  paths may be an exception).

## Testing baseline

- Run tests related to the change first.
- Do not unrelated-fix broken tests as part of a feature — flag the risk instead.
- Integration tests need real external dependencies; gate them with whatever
  the language idiom is (`testing.Short()` in Go, `@pytest.mark.integration`
  in Python, etc.).

### Verification checklist

The exact commands depend on the language, but every project should have an
equivalent of:

- Build passes (`go build ./...`, `tsc --noEmit`, `cargo build`, etc.).
- Static checks pass (`go vet`, `eslint`, `mypy`, etc.).
- Unit tests pass with race detection where applicable (`go test -race`).

Per-project commands are documented in `projects/<name>/`.

## Important reminders

- **Never develop directly on `main`** unless the project's branching model
  explicitly allows it. Default model: `main` is release, work happens on
  feature branches, PR to merge.
- `main` should be deployable.

---

**Version**: 2.0.0
**Updated**: 2026-05-13
