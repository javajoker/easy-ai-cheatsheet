---
name: py-code-review
description: Use when systematically reviewing a Python pull request — author or reviewer side. Walks through the canonical PR review pass with checks per area (types, async, errors, security, tests, perf, docs). Also use when asked to "look at this PR" or when a PR description is short and you need to derive the review yourself.
license: Apache-2.0
metadata:
  sources: "Google engineering practices code review guide, Python Security best practices, OWASP API Security Top 10"
allowed-tools: Bash(bash:*)
---

# Python Code Review

## Available Scripts and Assets

- **`scripts/pre-review.sh`** — Runs `ruff format --check`, `ruff check`, `mypy`, and `pip-audit` (or `safety`) against the current project; produces a per-stage pass/fail summary. Supports `--json`, `--no-audit`, `--skip-mypy`, `--src`. Run before manual review. `bash scripts/pre-review.sh --help`.
- **`assets/review-template.md`** — Canonical PR review structure with Verdict, Blockers / Suggestions / Questions tiers, and an automated-checks checklist. Copy into the PR comment.

## How to Use This Skill

For author or reviewer, walk the sections in order. Each ends with the
specific patterns to grep / inspect. Skip sections that don't apply (a
docs-only PR doesn't need the perf pass).

For larger PRs, use three feedback tiers:

| Tier | Phrase | Meaning |
|---|---|---|
| **Blocker** | "This must change before merge" | Bug, security issue, broken contract |
| **Suggestion** | "Consider …" | Style, design, optional improvement |
| **Question** | "Why this approach?" | Reviewer asking; not a request to change |

Mix tiers visibly so readers know what's required vs optional.

---

## 1. Functional Correctness

The first question: **does this do what the description says?**

- Read the PR description / linked ticket.
- Trace one happy-path scenario through the diff.
- Trace one edge case.
- Watch for off-by-one, wrong default, swapped arguments, missed branch.

Tests support this pass but don't replace it. A passing test with the wrong
assertion is still broken.

---

## 2. Types

- Type checker (Mypy / Pyright) run on the diff?
- Any new `Any` / `cast(Any, ...)` / `# type: ignore`? Each needs a comment.
- Generics constrained (not bare `T`)?
- `match` statements exhaustive (caught by checker if `_:` is missing)?
- Public functions have explicit return annotations?
- `Optional[X]` modernized to `X | None`?

```bash
mypy src/                                 # full project check
grep -rn 'Any\|type: ignore\|cast(' src/  # scan for escape hatches
```

See [py-typing](../py-typing/SKILL.md).

---

## 3. Async

- `asyncio.run` only at the entry point?
- `TaskGroup` (or `gather`) for concurrent ops?
- Timeouts at every hop?
- `CancelledError` re-raised (not silently swallowed)?
- No `time.sleep` / sync `requests.get` inside `async def`?
- `contextvars` instead of globals for request scope?

See [py-async](../py-async/SKILL.md).

---

## 4. Errors

- Custom exceptions inherit from `Exception` (or a more specific base)?
- `raise X from cause` preserves the chain?
- `except Exception` only at boundary layers?
- No `try/except: pass` without a reason?
- Errors mapped to HTTP status in one place?
- No "log and raise" duplication?

See [py-error-handling](../py-error-handling/SKILL.md).

---

## 5. Security

- New input validated with Pydantic / schema?
- SQL parameterized? Any `f"... {x} ..."` in SQL?
- `subprocess` uses list args, not `shell=True`?
- No `pickle.load` / `yaml.load` on untrusted data?
- New `requests.get(user_input)` — SSRF-guarded?
- Sensitive fields redacted in logs?
- New env vars added to `Settings`?
- New dependency: `pip-audit` clean? Maintained? Necessary?

```bash
grep -rn 'shell=True\|pickle\.load\|yaml\.load\|os\.system\|exec(' src/
ruff check --select S src/
pip-audit
```

See [py-security](../py-security/SKILL.md).

---

## 6. Tests

- Tests cover new behaviour, including one negative case?
- Test names describe behaviour, not the function?
- No test asserts on internal implementation (mock-call SQL strings)?
- Async tests properly marked?
- Time / randomness injected or frozen?
- Fixtures isolated (one test's state can't leak)?
- Module mocks justified (preferred: real or in-memory fake)?

See [py-testing](../py-testing/SKILL.md).

---

## 7. Performance

For an ordinary PR, a quick scan suffices. Investigate when the diff
touches a hot path.

- New sync work in an async handler?
- `Array.append` in a tight loop where `extend` or comprehension would do?
- `in list` on a big collection — should be `set`?
- Outbound HTTP without a shared client?
- New cache: bounded? TTL?
- `json` vs `orjson` for large payloads?

See [py-performance](../py-performance/SKILL.md).

---

## 8. HTTP Layer

For API changes:

- Standard status codes (HTTP layer carries success/failure)?
- New endpoint validates input with Pydantic?
- Pagination implemented (or explicitly N/A)?
- Idempotency: POST vs PUT semantics correct?
- Backward compatibility — adds a field, doesn't rename without versioning?
- OpenAPI / docs updated?

See [py-http](../py-http/SKILL.md).

---

## 9. Operational Concerns

- Observability: new log fields? new metrics?
- Migration: schema change has an Alembic / Django migration? Reversible?
- Feature flag: behind a flag if user-visible? Default off?
- Rollback plan: can this be reverted cleanly?
- Config: new env vars documented in `.env.example`?

---

## 10. Style and Naming

This pass is fast; defer to Ruff where it overlaps.

- Names follow PEP 8 / project convention?
- Files in the right directory?
- Imports ordered; type-only imports under `TYPE_CHECKING` where needed?
- Public functions and classes have docstrings?
- No dead code, no commented-out blocks?
- No `print` calls — uses logging?

---

## Common Smells, Quick Greps

```bash
# Type escape hatches
grep -rn 'Any\|type: ignore\|cast(' src/

# Print calls
grep -rn 'print(' src/ | grep -v test

# Direct env reads outside config
grep -rn 'os\.environ\|os\.getenv' src/ | grep -v 'src/.*config'

# Shell exec
grep -rn 'shell=True\|os\.system\|subprocess\.call(' src/

# Mutable default
ruff check --select B006 src/

# Unsafe deserialization
grep -rn 'pickle\.load\|yaml\.load\b' src/

# Dynamic SQL
grep -rn 'execute(f\|execute(.*\.format\|execute(.*+\s*\w*\)' src/

# Empty except
grep -rn 'except.*:\s*pass\|except.*:\s*$' src/

# TODO without owner
grep -rn 'TODO\|FIXME' src/ | grep -v 'TODO('
```

---

## Wrap-Up

End the review with a one-line verdict:

- **Approved — ship it.**
- **Approved with suggestions — these can land in a follow-up.**
- **Changes requested — list of blockers above.**
- **Needs more context — questions to answer before I can review.**

If the diff exceeds ~500 lines of real code or touches many unrelated
areas, ask for a split before reviewing. Reviewing a sprawling diff fairly
almost never works — issues are missed and reviewer fatigue compounds.

---

## Related Skills

- **Style core**: [py-style-core](../py-style-core/SKILL.md)
- **Naming**: [py-naming](../py-naming/SKILL.md)
- **Typing**: [py-typing](../py-typing/SKILL.md)
- **Async**: [py-async](../py-async/SKILL.md)
- **Error handling**: [py-error-handling](../py-error-handling/SKILL.md)
- **Security**: [py-security](../py-security/SKILL.md)
- **Testing**: [py-testing](../py-testing/SKILL.md)
- **Performance**: [py-performance](../py-performance/SKILL.md)
- **HTTP**: [py-http](../py-http/SKILL.md)
- **Logging**: [py-logging](../py-logging/SKILL.md)
- **Linting**: [py-linting](../py-linting/SKILL.md)
- **Documentation**: [py-documentation](../py-documentation/SKILL.md)
- **Data structures**: [py-data-structures](../py-data-structures/SKILL.md)
- **Classes**: [py-classes](../py-classes/SKILL.md)
- **Iterators**: [py-iterators-generators](../py-iterators-generators/SKILL.md)
- **Functions**: [py-functions](../py-functions/SKILL.md)
- **Control flow**: [py-control-flow](../py-control-flow/SKILL.md)
- **Modules**: [py-modules](../py-modules/SKILL.md)
- **Config**: [py-config](../py-config/SKILL.md)
