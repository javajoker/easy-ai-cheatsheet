# Code Standards

> Language-agnostic code principles. Per-language detail lives in the
> `skills/dev-<language>/` family of skills (`skills/dev-go/*` covers the
> Go-specific rules); the project's `projects/<name>/` directory can extend
> these for a project's particular conventions.

## Universal principles

These apply regardless of language.

### Imports / module boundaries

- Group imports by origin in this order: standard library, third-party,
  internal modules.
- Within each group, sort alphabetically unless your language's tooling
  enforces a different order.
- Inside an internal module, depend in one direction. No cycles.

### Naming

- Use the language's idiomatic case: `PascalCase` for exported types in Go,
  Java, C#; `snake_case` for Python; `camelCase` for JavaScript variables;
  etc. Apply consistently.
- Verbs for actions, nouns for things. `Init`, `Connect`, `Authenticate` are
  actions; `Manager`, `Client`, `Session` are things.
- Pick one term and stick to it. If "session" is the noun, do not interchange
  it with "instance" or "handle" depending on the file.

### Error handling

- Wrap errors with context as they cross a boundary. Preserve the original
  error so callers can match on it.
- Define a few well-named sentinel errors at the package level. Do not return
  raw strings or magic numbers as errors.
- Library code should not crash the process. Initialization can be an
  exception when the program cannot proceed.
- Match on errors using the language's idiom (`errors.Is/As` in Go,
  `isinstance` in Python, `instanceof` in TypeScript), not on error string
  contents.

### Logging

- Use a structured logger throughout the project. No ad-hoc `print` /
  `console.log` calls in committed code.
- Include the request or trace ID in every log line where applicable.
- Levels:
  - `error` — something failed, action needed.
  - `warn` — something is suboptimal but the system continued.
  - `info` — significant lifecycle event.
  - `debug` — verbose diagnostics, off in production.
- Do not log secrets, credentials, or full request bodies that may contain
  user data.

### Constructors and initialization

- Prefer dependency injection over global mutable state. Where a singleton is
  unavoidable (database connection pool, log sink), keep it tightly scoped
  and document its initialization order.
- A common project-wide pattern: explicit `Init(config) error` once at
  startup; subsequent code accesses the initialized resource by name.

### Concurrency

- Document who owns each shared resource. If two goroutines / threads /
  workers can touch the same memory, the access discipline (channel,
  mutex, copy-on-write) is named in code or comments.
- Cancellation propagates from the request boundary inward. Long-running
  operations accept a cancellation signal (`context.Context` in Go,
  `AbortSignal` in JS, `asyncio.Task.cancel` in Python).

### Defensive boundaries

- Copy slices, maps, and other mutable containers at API boundaries when the
  caller might mutate them later.
- Validate inputs at the system edge (HTTP handler, message consumer, CLI
  argument parser). Trust internal calls; do not re-validate at every layer.
- Use the language's null-safety mechanism (Go's zero values, Rust's `Option`,
  TypeScript's `strict null checks`). Do not silently coerce nulls into
  defaults.

## Documentation in code

- **Public API**: every exported symbol has a doc comment in the language's
  idiom (godoc, JSDoc, docstring, KDoc).
- **Private symbols**: comments are reserved for non-obvious *why*. Default
  to no comment.
- **No noise**: do not narrate what well-named code already says.

## Per-language detail

| Language | Skills to consult |
|---|---|
| Go | `skills/dev-go/*` — 20 skills covering style, naming, errors, concurrency, generics, testing, etc. |
| Other | Project-specific. Reference the project's `projects/<name>/code-standards.md` if present. |

When a project introduces a new language not yet covered, add the per-language
skill set (see `skills/dev-go/` as the template) before substantial work in
that language. Style consistency depends on having something to consult.

## Verification

Project-specific build, lint, and test commands live in
`projects/<name>/`. The universal expectation:

- Build passes.
- Lint passes with the project's chosen tool.
- Unit tests pass; integration tests pass when the relevant external systems
  are available.
- Race / concurrency detector passes if the language supports one (Go's
  `-race`, ThreadSanitizer, etc.).

---

**Version**: 2.0.0
**Updated**: 2026-05-13
