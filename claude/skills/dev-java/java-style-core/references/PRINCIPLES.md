# Style Principles Reference

The five priority principles for Java style, in the order they apply when
they conflict.

## 1. Clarity

The code's purpose and rationale must be clear to a reader who is not the
author.

- Descriptive names over short names.
- Comment *why*, not *what*.
- View clarity through the reader's lens, not the author's.
- Code is read many more times than it is written.

```java
// Good — clear purpose
public String chargeCustomer(String customerId, int amountCents) { ... }

// Bad — unclear, repeats noun, mixes intent
public String chargeChargeForCustomer(String custId, int amt) { ... }
```

## 2. Simplicity

Code should accomplish goals in the simplest way possible.

Simple code:

- Reads top to bottom.
- Doesn't assume prior knowledge of clever idioms.
- Has no unnecessary abstraction.
- May be mutually exclusive with "clever" code.

### Least Mechanism

When several mechanisms can express the same idea, prefer the most standard:

1. Core language constructs (`for-each`, `switch` expression, records).
2. Standard library (`java.util`, `java.time`, `java.nio.file`).
3. Well-known third-party (Spring, Jackson, AssertJ).
4. Rolling your own — only when 1, 2, and 3 don't suffice.

```java
// Good — stdlib
String text = Files.readString(Path.of("README.md"));

// Bad — reaching for Apache Commons / Guava when stdlib does the job
String text = FileUtils.readFileToString(new File("README.md"), StandardCharsets.UTF_8);
```

## 3. Concision

High signal-to-noise ratio.

- Avoid repetition.
- Avoid extraneous syntax.
- Avoid unnecessary abstraction layers.

```java
// Good — flat, signal-only
if (!user.isActive()) {
    throw new InactiveUserException(user.id());
}

// Bad — same content, more noise
if (user.isActive() == false) {
    InactiveUserException ex = new InactiveUserException(user.id());
    throw ex;
}
```

Concision is about the *useful* bytes. A confusing one-liner is not
concise.

## 4. Maintainability

Code is modified many more times than it is written.

Maintainable code:

- Has APIs that grow gracefully.
- Uses predictable names (same concept = same name everywhere).
- Minimizes coupling and hidden dependencies.
- Has tests with clear diagnostics.

```java
// Bad — leaks internal state, locks the implementation
public ArrayList<User> activeUsers() { ... }

// Good — interface return type, defensive copy if mutable
public List<User> activeUsers() { ... }
```

## 5. Consistency

Code should look and behave like similar code in the codebase.

- Package-level consistency is most important.
- When two principles tie, break in favor of consistency.
- Never override documented style principles for consistency.

If the project uses Google Java Style and your new file uses Allman braces,
the new file is the odd one out — and readers pay the cost.

## Resolving Conflicts

When two principles disagree:

| Conflict | Wins |
|---|---|
| Clarity vs Simplicity | Clarity |
| Clarity vs Concision | Clarity |
| Simplicity vs Concision | Simplicity |
| Any principle vs Consistency | The principle |
| Concision vs Maintainability | Maintainability |
| Consistency within file vs across project | Project |

When in doubt, ask: "If I came back to this code in six months without
context, would I understand it?"
