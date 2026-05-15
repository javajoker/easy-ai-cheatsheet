---
name: java-style-core
description: Use when working with Java formatting, line length, braces, indentation, blank lines, or core style principles. Also use when a style question isn't covered by a more specific skill, even if the user doesn't reference a specific style rule. Does not cover domain-specific patterns like error handling, naming, or testing (see specialized skills). Acts as fallback when no more specific style skill applies.
license: Apache-2.0
metadata:
  sources: "Google Java Style Guide, Oracle Code Conventions, JEP guidelines"
---

# Java Style Core Principles

## Style Principles (Priority Order)

When writing readable Java code, apply these in order of importance:

1. **Clarity** — Can a reader understand without extra context?
2. **Simplicity** — Is this the simplest way?
3. **Concision** — Does every line earn its place?
4. **Maintainability** — Will this be easy to modify later?
5. **Consistency** — Does it match surrounding code and project conventions?

> Read [references/PRINCIPLES.md](references/PRINCIPLES.md) when resolving conflicts between clarity, simplicity, and concision, or when you need concrete examples of how each principle applies in real Java code.

---

## Formatting

Use a formatter. The canonical choices:

- **google-java-format** — the de facto modern standard. Available as a
  Maven/Gradle plugin via **Spotless**.
- **IDE default** with the team's checked-in `.editorconfig` — acceptable
  when google-java-format doesn't fit (e.g. AOSP style with 4-space indent).

```xml
<!-- pom.xml — Spotless plugin -->
<plugin>
  <groupId>com.diffplug.spotless</groupId>
  <artifactId>spotless-maven-plugin</artifactId>
  <configuration>
    <java>
      <googleJavaFormat/>
    </java>
  </configuration>
</plugin>
```

Run `mvn spotless:apply` or `./gradlew spotlessApply` on save / in pre-commit.
PRs that touch formatting + logic in the same commit are a friction tax — keep
formatting commits separate.

> Read [references/FORMATTING.md](references/FORMATTING.md) when configuring Spotless, google-java-format, import order, modifier order, or wiring formatting into pre-commit and CI.

---

## Indentation and Braces

| Element | Convention (Google style) |
|---|---|
| Indent | 2 spaces (or 4 — pick once) |
| Continuation indent | +4 spaces |
| Tab | Never |
| Opening brace | Same line ("K&R" style) |
| `else` / `catch` | Same line as `}` |
| Empty block | `{}` on one line |

```java
// Good
if (user.isActive()) {
  doSomething();
} else {
  doSomethingElse();
}

// Bad — opening brace on new line ("Allman" style — non-standard for Java)
if (user.isActive())
{
  doSomething();
}
```

Always use braces, even for one-line statements:

```java
// Bad
if (condition) doSomething();
if (condition)
  doSomething();

// Good
if (condition) {
  doSomething();
}
```

The dangling-else hazard of brace-less `if` doesn't pay for the lines saved.

---

## Line Length

Google style: 100 columns. Some teams use 120. Pick once and enforce in the
formatter.

When a line wants to be longer, refactor — extract a local with a meaningful
name, break the method chain — don't just wrap.

```java
// Bad — long chain
List<String> result = users.stream().filter(u -> u.isActive() && u.getAge() > 18 && u.getCountry().equals("US")).map(User::getEmail).toList();

// Good
Predicate<User> eligible = u -> u.isActive() && u.getAge() > 18 && "US".equals(u.getCountry());
List<String> result = users.stream()
    .filter(eligible)
    .map(User::getEmail)
    .toList();
```

---

## Reduce Nesting

Push error cases to the top. Keep the main path at the lowest indent.

```java
// Bad
public Result process(Request req) {
  if (req.user() != null) {
    if (req.user().isActive()) {
      if (req.body() != null) {
        return doWork(req.user(), req.body());
      } else {
        throw new IllegalArgumentException("no body");
      }
    } else {
      throw new IllegalStateException("inactive");
    }
  } else {
    throw new IllegalArgumentException("no user");
  }
}

// Good
public Result process(Request req) {
  if (req.user() == null) {
    throw new IllegalArgumentException("no user");
  }
  if (!req.user().isActive()) {
    throw new IllegalStateException("inactive");
  }
  if (req.body() == null) {
    throw new IllegalArgumentException("no body");
  }
  return doWork(req.user(), req.body());
}
```

---

## `var` for Local Variables (Java 10+)

Use `var` when the type is obvious from the right-hand side. Don't use it when
the inferred type adds friction for readers.

```java
// Good — obvious
var users = new ArrayList<User>();
var stream = Files.lines(path);

// Acceptable
var user = repo.findById(id);

// Bad — what is this?
var result = compute(input);   // reader has to look up compute()
```

Never use `var` for fields (illegal anyway) or method return types. The
public surface uses concrete types.

---

## Blank Lines

| Place | Lines |
|---|---|
| Between methods | 1 |
| Between fields and methods | 1 |
| Between class declarations | 1 |
| Inside a method, between logical sections | 1, sparingly |
| Inside a method between every line | 0 |

A method with a blank line after every statement is harder to read than one
with no blank lines.

---

## Member Order

Standard order in a class:

1. Static fields (constants, then mutable — though mutable static is a smell).
2. Instance fields.
3. Constructors.
4. Static methods.
5. Instance methods (group by purpose; public before private).
6. Nested types.

Tools like google-java-format don't reorder; either follow convention or use
a checkstyle rule.

---

## Equality and Comparison

Use `.equals()` for object equality, `==` for primitives or reference
identity. `String` interning means `"a" == "a"` *sometimes* works, but it's
brittle.

```java
// Bad
if (name == "alice") { ... }

// Good
if ("alice".equals(name)) { ... }    // null-safe on the left
if (Objects.equals(name, other)) { ... }
```

`Objects.equals(a, b)` is null-safe. Use it for fields where one side may
be `null`.

---

## Strings

Prefer text blocks (Java 15+) for multi-line:

```java
// Good
String json = """
    {
      "name": "alice",
      "age": 30
    }
    """;
```

Use `String.format` or `formatted()` for interpolation:

```java
// Good
log.info("user {} signed in at {}", name, ts);                     // SLF4J placeholders
String msg = "user %s signed in at %s".formatted(name, ts);
```

Avoid `String` concatenation in hot loops — use `StringBuilder`:

```java
// Bad
String result = "";
for (String s : parts) {
  result += s;
}

// Good
StringBuilder sb = new StringBuilder();
for (String s : parts) {
  sb.append(s);
}
return sb.toString();

// Or
return String.join("", parts);
```

---

## Imports

| Convention | Detail |
|---|---|
| Order | `java.*`, `javax.*`, third-party, project — blank line between groups |
| Wildcards | Never (`import java.util.*;`) |
| Static imports | Sparingly; only when they reduce noise (e.g. `Assertions.*` in tests) |

The formatter handles order. ESLint-equivalent: Checkstyle's `ImportOrder`.

---

## Quick Reference

| Principle | Key Question |
|-----------|--------------|
| Clarity | Can a reader understand what and why? |
| Simplicity | Is this the simplest approach? |
| Concision | Is the signal-to-noise ratio high? |
| Maintainability | Can this be safely modified later? |
| Consistency | Does this match surrounding code? |

## Related Skills

- **Naming**: See [java-naming](../java-naming/SKILL.md) for identifier conventions.
- **Packages**: See [java-packages](../java-packages/SKILL.md) for package layout and imports.
- **Types**: See [java-types](../java-types/SKILL.md) for `var`, records, sealed types.
- **Error handling**: See [java-error-handling](../java-error-handling/SKILL.md) for early-return guards.
- **Documentation**: See [java-documentation](../java-documentation/SKILL.md) for Javadoc.
- **Linting**: See [java-linting](../java-linting/SKILL.md) for Spotless, Checkstyle, ErrorProne.
- **Code review**: See [java-code-review](../java-code-review/SKILL.md) for applying style during PR review.
