# Testing Standards

> Universal testing principles. Language-specific patterns (table-driven tests
> in Go, parameterized tests in Pytest, etc.) live in `skills/dev-<language>/`
> or per-project test-style notes.

## Strategy

- **Run change-scoped tests first.** Re-running the full suite on every iteration
  wastes time when most of it is irrelevant.
- **New behaviour ships with new tests.** Cover the core logic and at least one
  boundary or failure case.
- **Integration tests need real external dependencies.** Gate them with the
  language's idiomatic skip mechanism (`testing.Short()` in Go,
  `@pytest.mark.integration` in Python, `describe.skipIf` in Jest).
- **Do not opportunistically fix unrelated failing tests.** Surface them as a
  risk; let the user decide whether to bundle the fix or split it.

## Unit tests

The pattern depends on the language but every test obeys these rules:

- One observable behaviour per test case. If the test name has "and" in it,
  split it.
- Test the public API. White-box tests against internals are appropriate when
  the internal behaviour is genuinely the subject; otherwise they harden the
  test against legitimate refactors.
- Use the language's table-driven / parameterized pattern when several cases
  share the same shape:
  - Go: `tests := []struct{ name, input, want, wantErr ... }`
  - Python: `@pytest.mark.parametrize("input,want,error", [...])`
  - TypeScript: `describe.each([...])` or `it.each([...])`
- Assertion messages should say *what was expected*, not just *that something
  failed*.

## Integration tests

- Mark them with the language's "slow" or "integration" tag.
- Provide a way to skip them when external systems are unreachable. CI should
  exercise them; local rapid iteration may skip them.
- Idempotent setup and teardown — each test leaves the system in the state it
  found it.
- Real database, not mocked. See `development-principles.md` section 5 ("no
  silent mocking").

## Concurrency tests

For code that promises thread-safety or goroutine-safety:

- Exercise it from multiple workers in parallel.
- Run the test under the language's race detector (`go test -race`, Java's
  ThreadSanitizer, etc.).
- Vary the worker count; bugs often surface only above some threshold.

## Verification commands

Each language uses its own verification commands. The universal expectation is
three things pass cleanly before declaring a task done:

1. **Build** — the project compiles or type-checks.
2. **Static analysis** — vet/lint passes.
3. **Tests** — unit tests pass; integration tests pass when applicable.

Per-language and per-project commands live in `projects/<name>/`.

## Anti-patterns

- **Tests that only assert "does not crash."** No real coverage.
- **Tests that mock everything.** What is left under test is the test
  scaffolding, not the code.
- **Tests that depend on test order.** Reorder them; they should still pass.
- **Tests with hard-coded "now" values.** Use the language's clock-injection
  idiom (`Clock` interface in Go, `freezegun` in Python, etc.) so the test
  works in five years.

---

**Version**: 2.0.0
**Updated**: 2026-05-13
