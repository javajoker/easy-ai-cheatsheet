---
name: node-code-review
description: Use when systematically reviewing a Node.js / TypeScript pull request — author or reviewer side. Walks through the canonical PR review pass with checks per area (types, async, errors, security, tests, perf). Also use when asked to "look at this PR" or when a PR description is short and you need to derive the review yourself.
license: Apache-2.0
metadata:
  sources: "Google engineering practices code review guide, Node.js Best Practices, OWASP API Security Top 10"
allowed-tools: Bash(bash:*)
---

# Node.js / TypeScript Code Review

## Available Scripts and Assets

- **`scripts/pre-review.sh`** — Runs Prettier, ESLint, TypeScript `--noEmit`, and `npm audit` against the current project; produces a per-stage pass/fail summary. Supports `--json`, `--no-audit`, `--pnpm`, `--yarn`. Run before manual review to catch mechanical issues. `bash scripts/pre-review.sh --help`.
- **`assets/review-template.md`** — Canonical PR review structure with Verdict, Blockers / Suggestions / Questions tiers, and an automated-checks checklist. Copy into the PR comment.

## How to Use This Skill

For author or reviewer, walk the sections below in order. Each section ends
with the **specific patterns** to grep / inspect. Skip sections that don't
apply to the diff at hand (a docs-only change doesn't need the perf pass).

For larger PRs, prefer feedback in three tiers:

| Tier | Phrase | Meaning |
|---|---|---|
| **Blocker** | "This must change before merge" | Bug, security issue, broken contract |
| **Suggestion** | "Consider …" | Style, design, optional improvement |
| **Question** | "Why this approach?" | Reviewer asking; not a request to change |

Mix the tiers visibly — readers do the right thing more often when the
expectation is explicit.

---

## 1. Functional Correctness

The first question is always: **does this do what the description says?**

- Read the PR description / linked ticket.
- Pick one happy-path scenario and trace it through the diff.
- Pick one edge case and trace it.
- Look for off-by-one, wrong default, swapped arguments, missed branch.

Tests support this pass but don't replace it. A passing test with the wrong
assertion is still broken.

---

## 2. Types

- `strict` mode on? (`tsconfig.json`)
- Any new `any` / `as any` / `@ts-ignore` / `!`? Each needs a comment.
- Any `as Foo` cast without a runtime check?
- Generics constrained? (`<T>` alone is suspect.)
- Discriminated unions exhaustive? (`assertNever` at the switch tail)
- Public exports have explicit return types?

```bash
# Quick checks
grep -rn ': any\|as any\|@ts-ignore' <files>
```

See [node-types](../node-types/SKILL.md).

---

## 3. Async

- Every promise awaited or returned? `no-floating-promises` clean?
- Sequential `await` in a `for` loop where parallel would do?
- `Promise.all` where one failure should *not* abort the rest? Use
  `allSettled`.
- `AbortSignal` threaded through long operations?
- Top-level entry has a `.catch`?
- Fire-and-forget marked with `void p.catch(...)` and a logged error?

See [node-async](../node-async/SKILL.md).

---

## 4. Errors

- Throws are `Error` subclasses, not strings/POJOs?
- Custom errors used for cases callers want to match on?
- Re-throw preserves the original via `{ cause }`?
- HTTP boundary translates errors in one place, not per-handler?
- `try`/`catch` blocks add value (context, translation), not just rethrow?
- Errors logged at the right level; not logged-then-thrown?

See [node-error-handling](../node-error-handling/SKILL.md).

---

## 5. Security

- New input validated with a schema?
- SQL parameterized? Any `db.query(`${...}`)` template literals?
- New `exec` / `execSync` calls? Args-array form?
- Third-party fetch URL user-controllable? Allow-list?
- Sensitive fields redacted in logs?
- New env vars added to the validated config?
- New dependency: audit clean? Maintained? Necessary?

```bash
grep -rn 'exec\|execSync\|JSON.parse\|require(\|process.env' <files>
npm audit --omit=dev
```

See [node-security](../node-security/SKILL.md).

---

## 6. Tests

- Tests cover the new behaviour, including one negative case?
- Test names describe behaviour, not the function?
- No test asserts on the internal implementation (mock-call SQL strings)?
- Async tests use `await expect(...).resolves/.rejects`, not `.then(done)`?
- Time / randomness faked?
- Module mocks justified (preferred: real or in-memory fake)?
- Test setup isolated; one test's state can't leak to the next?

See [node-testing](../node-testing/SKILL.md).

---

## 7. Performance

For a regular PR, a quick scan suffices. Investigate when the diff touches a
hot path (request handler, tight loop, large-payload code).

- New synchronous work in the hot path?
- `JSON.parse` of a large body without streaming?
- `Array.includes` against a large array — should be `Set`?
- Outbound `fetch` without a shared keep-alive agent?
- New cache: TTL set? Eviction bound?
- Event listener added without removal?

See [node-performance](../node-performance/SKILL.md).

---

## 8. HTTP Layer

For API changes:

- Status codes from the standard set; HTTP layer carries success/failure?
- New endpoint validates body / query / params with a schema?
- Pagination implemented (or explicitly N/A)?
- Idempotency considered (POST vs PUT semantics)?
- Backward compatibility — adds a field, doesn't rename/remove without versioning?
- OpenAPI / docs updated?

See [node-http](../node-http/SKILL.md).

---

## 9. Operational Concerns

- Observability: new log fields? new metrics?
- Migration: schema change has a migration file? Reversible?
- Feature flag: behind a flag if user-visible? Default off?
- Rollback plan: can this be reverted cleanly?
- Config: new env vars documented in `.env.example`?

---

## 10. Style and Naming

This pass is fast; defer to the linter where it overlaps.

- Names follow project convention (see [node-naming](../node-naming/SKILL.md))?
- Files in the right directory?
- Imports ordered; `import type` for types?
- Public functions have TSDoc?
- No dead code, no commented-out blocks?

---

## Common Smells, Quick Greps

```bash
# Type escape hatches
grep -rn ': any\|as any\|@ts-ignore\|!\.' src/

# Console logging
grep -rn 'console\.\(log\|error\|warn\)' src/

# Direct env reads outside config
grep -rn 'process\.env' src/ | grep -v 'src/config'

# Floating promises (the linter catches more)
grep -rn '\.then(' src/

# Hand-rolled shell exec
grep -rn 'execSync\|child_process\.exec(' src/

# Dynamic SQL
grep -rn 'query(`\|query(\(.*\${' src/

# TODO without owner
grep -rn 'TODO\|FIXME' src/ | grep -v 'TODO('
```

---

## Wrap-Up

End the review with a one-line verdict and the next action:

- **Approved — ship it.**
- **Approved with suggestions — these can land in a follow-up.**
- **Changes requested — list of blockers above.**
- **Needs more context — questions to answer before I can review.**

If the diff is too large to review meaningfully (over ~500 lines of real
code, or touching many unrelated areas), ask for a split before reviewing.
Trying to review a sprawling diff fairly almost never works — issues are
missed and reviewer fatigue compounds.

---

## Related Skills

- **Style core**: [node-style-core](../node-style-core/SKILL.md)
- **Naming**: [node-naming](../node-naming/SKILL.md)
- **Types**: [node-types](../node-types/SKILL.md)
- **Async**: [node-async](../node-async/SKILL.md)
- **Error handling**: [node-error-handling](../node-error-handling/SKILL.md)
- **Security**: [node-security](../node-security/SKILL.md)
- **Testing**: [node-testing](../node-testing/SKILL.md)
- **Performance**: [node-performance](../node-performance/SKILL.md)
- **HTTP**: [node-http](../node-http/SKILL.md)
- **Logging**: [node-logging](../node-logging/SKILL.md)
- **Linting**: [node-linting](../node-linting/SKILL.md)
- **Documentation**: [node-documentation](../node-documentation/SKILL.md)
