---
name: java-code-review
description: Use when systematically reviewing a Java pull request — author or reviewer side. Walks through the canonical PR review pass with checks per area (types, concurrency, errors, security, tests, performance, docs). Also use when asked to "look at this PR" or when a PR description is short and you need to derive the review yourself.
license: Apache-2.0
metadata:
  sources: "Google engineering practices code review guide, Effective Java, OWASP API Security Top 10"
allowed-tools: Bash(bash:*)
---

# Java Code Review

## Available Scripts and Assets

- **`scripts/pre-review.sh`** — Runs Spotless check, compile (with ErrorProne if configured), Checkstyle (if configured), and tests against the current project. Auto-detects Maven vs Gradle. Supports `--json`, `--skip-test`. Run `bash scripts/pre-review.sh --help`.
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

Tests support this pass but don't replace it. A passing test with the
wrong assertion is still broken.

---

## 2. Types

- New `@SuppressWarnings("unchecked")`? Each needs a comment.
- New raw type (`List`, `Map`)? Replace with parameterized.
- `Optional` used for fields or parameters (anti-pattern)?
- Sealed-type switch missing a case (compile error if exhaustive)?
- Records used where appropriate (DTOs, value objects)?
- Public methods have explicit return types (not just `var`)?

```bash
grep -rn '@SuppressWarnings\|raw types' src/main/java
```

See [java-types](../java-types/SKILL.md), [java-generics](../java-generics/SKILL.md).

---

## 3. Concurrency

- New `new Thread(...)`? Replace with `ExecutorService`.
- Shared mutable state without synchronization or `ConcurrentHashMap`?
- `synchronized` on `this` exposing the lock to callers?
- `InterruptedException` swallowed? Should re-set the interrupt flag.
- `volatile` used for compound operations (smell)?
- Long-running task doesn't honor cancellation?
- Virtual threads used where appropriate (Java 21+)?

See [java-concurrency](../java-concurrency/SKILL.md).

---

## 4. Errors

- Checked exception cascade where runtime would do?
- `catch (Throwable)` or `catch (Exception)` at non-boundary layers?
- Bare rethrow `catch (E e) { throw e; }` — remove?
- `raise from cause` preserved (Java: constructor with `Throwable cause`)?
- Resource cleanup uses `try-with-resources`?
- HTTP errors mapped in one `@RestControllerAdvice`?
- `Optional.get()` without check (anti-pattern)?

```bash
grep -rn 'catch (Throwable\|catch (Exception .*) {\s*throw\|\.get()' src/main/java
```

See [java-error-handling](../java-error-handling/SKILL.md).

---

## 5. Security

- New input validated with Bean Validation?
- SQL injection: no string-built queries; `PreparedStatement` / JPA params?
- Command injection: `ProcessBuilder` with args array, not shell?
- New `ObjectInputStream`, `pickle.load`-equivalent (`Yaml.load` without
  safe constructor)?
- SSRF: outbound URL allow-listed if user-controlled?
- Sensitive fields redacted in logs?
- New env vars added to `@ConfigurationProperties`?
- New dependency: OWASP Dependency Check clean? Maintained?

```bash
grep -rn 'Runtime\.\|exec(\|ObjectInputStream\|Yaml\.load(' src/main/java
mvn org.owasp:dependency-check-maven:check
```

See [java-security](../java-security/SKILL.md).

---

## 6. Tests

- Tests cover new behavior, including one negative case?
- Test names describe behavior (not the method)?
- No test asserts on internal interactions (mock-call SQL strings)?
- Async tests use proper synchronization (not `Thread.sleep`)?
- Time / randomness injected or controlled?
- Module mocks justified (preferred: real or in-memory fake)?
- New `@DirtiesContext` (slow, often avoidable)?

See [java-testing](../java-testing/SKILL.md).

---

## 7. Performance

For ordinary PRs, a quick scan suffices. Investigate when the diff
touches a hot path.

- New blocking call in an async/reactive flow?
- `String` concatenation in a loop where `StringBuilder` would do?
- `List.contains` against a large list (should be `Set`)?
- Outbound HTTP without a shared client?
- New cache: bounded? TTL?
- N+1 query (multiple DB calls in a loop)?

See [java-performance](../java-performance/SKILL.md).

---

## 8. HTTP Layer

For API changes:

- Standard status codes; HTTP layer carries success/failure?
- New endpoint validates body / query / params with `@Valid`?
- Pagination implemented (or explicitly N/A)?
- Idempotency: POST vs PUT semantics correct?
- Backward compatibility — adds field, doesn't rename/remove without
  versioning?
- DTO at the boundary (not the JPA entity)?
- OpenAPI updated?

See [java-http](../java-http/SKILL.md).

---

## 9. Operational Concerns

- Observability: new log fields? new metrics?
- Migration: Liquibase / Flyway file added? Reversible?
- Feature flag: behind a flag if user-visible? Default off?
- Rollback plan: can this be reverted cleanly?
- Config: new properties documented in `application.yml`?

---

## 10. Style and Naming

This pass is fast; defer to Spotless / Checkstyle where they overlap.

- Names follow project / Google style?
- Files in the right package?
- Imports clean; no wildcards?
- Public classes / methods have Javadoc?
- No dead code, no commented-out blocks?
- No `System.out.println` — uses SLF4J?

```bash
grep -rn 'System.out.println\|System.err.println' src/main/java
```

---

## Common Smells, Quick Greps

```bash
# Type escape hatches
grep -rn '@SuppressWarnings\|raw types' src/main/java

# Print calls
grep -rn 'System.out.println\|System.err.println' src/main/java | grep -v test

# Direct env reads outside config
grep -rn 'System.getenv\|System.getProperty(' src/main/java | grep -v 'AppProperties\|Config'

# Shell exec
grep -rn 'Runtime.getRuntime().exec\|new ProcessBuilder' src/main/java

# Unsafe deserialization
grep -rn 'ObjectInputStream\|new Yaml()' src/main/java

# Empty catch
grep -rn 'catch.*) {\s*}\|catch.*) {\s*//' src/main/java

# Dynamic SQL
grep -rn 'createNativeQuery.*+\|createQuery.*+' src/main/java

# Old-style equals on String
grep -rn '== "\|" ==' src/main/java

# TODO without owner
grep -rn 'TODO\|FIXME' src/main/java | grep -v 'TODO('
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
almost never works.

---

## Related Skills

- **Style core**: [java-style-core](../java-style-core/SKILL.md)
- **Naming**: [java-naming](../java-naming/SKILL.md)
- **Packages**: [java-packages](../java-packages/SKILL.md)
- **Types**: [java-types](../java-types/SKILL.md)
- **Generics**: [java-generics](../java-generics/SKILL.md)
- **Concurrency**: [java-concurrency](../java-concurrency/SKILL.md)
- **Error handling**: [java-error-handling](../java-error-handling/SKILL.md)
- **Control flow**: [java-control-flow](../java-control-flow/SKILL.md)
- **Methods/lambdas**: [java-methods-lambdas](../java-methods-lambdas/SKILL.md)
- **Data structures**: [java-data-structures](../java-data-structures/SKILL.md)
- **Classes**: [java-classes](../java-classes/SKILL.md)
- **Testing**: [java-testing](../java-testing/SKILL.md)
- **Logging**: [java-logging](../java-logging/SKILL.md)
- **Config**: [java-config](../java-config/SKILL.md)
- **HTTP**: [java-http](../java-http/SKILL.md)
- **Security**: [java-security](../java-security/SKILL.md)
- **Performance**: [java-performance](../java-performance/SKILL.md)
- **Documentation**: [java-documentation](../java-documentation/SKILL.md)
- **Linting**: [java-linting](../java-linting/SKILL.md)
