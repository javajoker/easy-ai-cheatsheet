---
name: java-documentation
description: Use when writing or reviewing Javadoc — class, method, and field documentation, `@param` / `@return` / `@throws` tags, `package-info.java`, README sections, and `@deprecated` markers. Also use when deciding what to document and what to leave to the signature.
license: Apache-2.0
metadata:
  sources: "Oracle Javadoc Guide, Google Java Style Guide, Effective Java (Item 56)"
allowed-tools: Bash(bash:*)
---

# Java Documentation

## Available Scripts and Assets

- **`scripts/check-docs.sh`** — Scans `.java` files for public methods and public classes that lack a Javadoc comment immediately above. Skips test files. Run `bash scripts/check-docs.sh --help`. For richer enforcement, use Checkstyle's `MissingJavadocType` / `MissingJavadocMethod`.
- **`assets/DocTemplate.java`** — Canonical Javadoc shapes for class, method, constructor, record, and `@Deprecated`. Copy when scaffolding documentation for a new class.

## What to Document

The type signature already documents *what types*. Javadoc contributes:

- **Why** the method exists.
- **When** to use it vs another method.
- **Constraints** the type doesn't express (units, ranges, ordering, thread
  safety).
- **Examples** for non-obvious call sites.

Don't restate the signature.

```java
// Bad — repeats the name and types
/**
 * Get the user by id.
 *
 * @param id the user id
 * @return the user
 */
public User getUserById(String id) { ... }

// Good — adds why and constraints
/**
 * Loads the user from the primary database, bypassing the read-replica
 * cache.
 *
 * <p>Use {@link #findById} when stale data is acceptable.
 *
 * @param id user id; must be non-null
 * @return the user
 * @throws NotFoundException if no user matches the id
 */
public User getUserById(String id) { ... }
```

---

## Javadoc Tags Reference

| Tag | Purpose |
|---|---|
| `@param name desc` | Parameter description |
| `@return desc` | Return value description |
| `@throws Type desc` | Exceptions that can be thrown |
| `@see` | Reference another symbol or URL |
| `@since` | Version introduced |
| `@deprecated reason` | Mark as deprecated; mention replacement |
| `{@link Symbol}` | Inline cross-reference |
| `{@code text}` | Inline code formatting (preserves whitespace) |
| `{@inheritDoc}` | Inherit from overridden method |

```java
/**
 * Charges the customer for the given amount.
 *
 * @param customerId Stripe customer ID; must not be null
 * @param amountCents amount in cents; must be ≥ 50 (Stripe minimum)
 * @return the Stripe charge ID on success
 * @throws InsufficientFundsException when the card is declined
 * @see #refund(String)
 * @since 1.4.0
 */
public String charge(String customerId, int amountCents) { ... }
```

---

## Summary Line First

The first sentence is the summary — used by IDE hover and Javadoc index
pages. Keep it under ~80 characters.

```java
// Bad
/**
 * This method takes a user id and a tenant id and looks up
 * the user in the database, returning the user object.
 */

// Good
/** Loads a user by id within a tenant scope. */
```

Subsequent paragraphs go below; separate with `<p>` (HTML, but Javadoc uses
it).

```java
/**
 * Validates and normalizes a user-supplied configuration.
 *
 * <p>Normalization includes lowercasing keys, expanding shorthand
 * paths, and computing derived defaults.
 *
 * @throws ConfigException on schema violations
 */
public Config normalize(Map<String, Object> input) { ... }
```

---

## Document Public API

Document **exported** classes and methods (public, and protected on
extension-friendly classes). Private helpers usually don't need Javadoc —
the name and surrounding usage say enough.

Exception: a private helper with non-obvious logic (algorithm, workaround)
deserves a short comment explaining why.

```java
// private helper — short comment is fine
// Walks the class graph to detect deserialization gadgets.
private boolean isDangerousGraph(Object root) { ... }

// public API — full Javadoc
/**
 * Validates and normalizes a user-supplied configuration.
 *
 * @throws ConfigException on schema violations
 */
public Config normalize(Map<String, Object> input) { ... }
```

---

## Class-Level Javadoc

```java
/**
 * JDBC-backed implementation of {@link UserRepository}.
 *
 * <p>This class is thread-safe; the underlying {@code DataSource} is
 * assumed to be thread-safe (HikariCP and similar pools are).
 *
 * <p>Designed for use as a Spring bean; constructor injection only.
 *
 * @since 1.0
 */
public class JdbcUserRepository implements UserRepository { ... }
```

Mention:

- Thread-safety (or its absence).
- Invariants the class maintains.
- Lifecycle expectations (singleton, request-scoped).
- Performance properties if non-obvious.

---

## `@deprecated` with a Replacement

```java
/**
 * Loads a user by id.
 *
 * @deprecated Use {@link #getUserById(String)} instead. Will be removed
 *     in 2.0.
 */
@Deprecated(since = "1.5.0", forRemoval = true)
public User fetchUser(String id) {
  return getUserById(id);
}
```

Without a replacement pointer, callers don't know where to migrate.
`@Deprecated(forRemoval = true)` triggers a stronger compiler warning.

---

## Records and Documentation

Records can have Javadoc on the type declaration and on individual
components:

```java
/**
 * A user account.
 *
 * @param id     unique user id; format {@code u_<hex>}
 * @param email  email address; lowercased
 * @param isAdmin whether the user has admin privileges
 */
public record User(String id, String email, boolean isAdmin) {}
```

The component-level `@param` tags propagate to the auto-generated
accessors.

---

## `package-info.java`

A package can document itself in `package-info.java`:

```java
/**
 * User domain — entities, repository, and service for the {@code users}
 * table.
 *
 * <p>External callers should depend only on {@link UserService}. The
 * repository interface and implementations are internal.
 *
 * @since 1.0
 */
@NullMarked
package com.acme.myapp.user;

import org.jspecify.annotations.NullMarked;
```

Javadoc tools render this as the package's overview page. Useful for
explaining the package's responsibility and pointing at the primary entry
point.

---

## Examples in Javadoc

Use `<pre>{@code ... }</pre>` for inline examples:

```java
/**
 * Builds a URL with query parameters.
 *
 * <pre>{@code
 * String url = UrlBuilder.build("/users", Map.of("page", 2));
 * // → "/users?page=2"
 * }</pre>
 */
public static String build(String path, Map<String, ?> params) { ... }
```

`{@code ...}` inside the `<pre>` block preserves whitespace and skips
HTML escaping — clean code blocks in the rendered docs.

---

## Don't Restate Types

```java
// Bad — duplicates the type info
/**
 * @param userId the string user id
 * @return the user object
 */
public User getUser(String userId) { ... }

// Good — explains meaning beyond the type
/**
 * @param userId looks up by public-facing slug, not the internal numeric id
 * @return the user; never null
 */
public User getUser(String userId) { ... }
```

If the type alone is informative, skip the tag.

---

## Inline Comments

| Comment | Where | What |
|---|---|---|
| `/** ... */` Javadoc | Above a declaration | Public-facing API documentation |
| `// inline` | Above a line | Non-obvious *why* of the code below |
| `// TODO(name): ...` | Above a line | Tracked deferred work |
| `// FIXME: ...` | Above a line | Known broken; replace ASAP |

Default to no inline comment. Add only when removing it would confuse a
reader.

---

## README Sections

A library or service README answers, in order:

1. **What it is** — one sentence.
2. **Why it exists** — the problem it solves.
3. **Quick start** — minimal Maven/Gradle dependency snippet + one example.
4. **Configuration** — application.yml properties, env vars.
5. **API surface** — main classes / endpoints; link to detailed docs.
6. **Development** — `mvn test`, `mvn spring-boot:run`.
7. **License**.

A README that opens with the install command is failing the reader. Lead
with "this is a library that ___".

---

## Generated Docs

For libraries, publish Javadoc:

```bash
mvn javadoc:jar
./gradlew javadoc
```

Tools render the result well; readers expect it. Provide an
`api-docs/index.html` link in the README.

For services, generated OpenAPI from controller annotations is usually
more valuable than narrative API docs.

---

## Quick Reference

| Question | Default |
|---|---|
| Document private helpers? | Only the non-obvious ones |
| Document public API? | Yes |
| First line | Summary, under ~80 chars |
| Restate types? | No |
| `{@link}` for symbols | Yes |
| Code example | `<pre>{@code ...}</pre>` |
| `@deprecated`? | With replacement and `forRemoval=true` |
| Inline comments | Only for non-obvious *why* |

## Related Skills

- **Style core**: [java-style-core](../java-style-core/SKILL.md) for comment style.
- **Naming**: [java-naming](../java-naming/SKILL.md) — good names reduce comments.
- **Types**: [java-types](../java-types/SKILL.md) for records that document themselves.
- **Methods/lambdas**: [java-methods-lambdas](../java-methods-lambdas/SKILL.md) for signature shape.
- **Packages**: [java-packages](../java-packages/SKILL.md) for `package-info.java`.
- **Linting**: [java-linting](../java-linting/SKILL.md) for Checkstyle Javadoc rules.
