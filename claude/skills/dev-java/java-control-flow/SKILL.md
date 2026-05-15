---
name: java-control-flow
description: Use when writing or refactoring control flow in Java — early returns, switch expressions, pattern-matching switch (Java 21+), ternary, `for` vs `for-each`, conditional expressions, and replacing nested conditionals. Also use when reviewing code that's "too nested" or has long `if`/`else` ladders.
license: Apache-2.0
compatibility: Switch expressions (Java 14+). Pattern-matching `switch` (Java 21+).
metadata:
  sources: "Google Java Style Guide, JEP 361 (switch expressions), JEP 441 (pattern matching for switch)"
---

# Java Control Flow

## Early Return

Push special cases to the top. Keep the main path at the lowest indent.

```java
// Bad — deep nesting
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

// Good — flat
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

## Switch Expressions (Java 14+)

Switch is now an expression — it returns a value. Arrow form skips
fallthrough:

```java
// Old switch statement
String label;
switch (status) {
  case PENDING: label = "in progress"; break;
  case ACTIVE:  label = "active"; break;
  case ARCHIVED: label = "archived"; break;
  default: throw new IllegalArgumentException();
}

// Good — switch expression
String label = switch (status) {
  case PENDING -> "in progress";
  case ACTIVE -> "active";
  case ARCHIVED -> "archived";
};
```

If the switch is **exhaustive** over an enum or sealed type, the compiler
doesn't require a `default`.

Block-form arms with `yield`:

```java
int sum = switch (op) {
  case ADD -> a + b;
  case MUL -> a * b;
  case DIVIDE -> {
    if (b == 0) throw new ArithmeticException();
    yield a / b;
  }
};
```

---

## Pattern-Matching Switch (Java 21+)

Combine sealed types with pattern matching for exhaustive destructuring:

```java
sealed interface Shape permits Circle, Square, Triangle {}
record Circle(double radius) implements Shape {}
record Square(double side) implements Shape {}
record Triangle(double base, double height) implements Shape {}

double area(Shape s) {
  return switch (s) {
    case Circle c   -> Math.PI * c.radius() * c.radius();
    case Square sq  -> sq.side() * sq.side();
    case Triangle t -> 0.5 * t.base() * t.height();
  };
}
```

The compiler verifies the switch covers every permitted subtype. Add a new
subtype, get a compile error in every switch that needs to handle it —
that's the win.

Guards: `case Square sq when sq.side() == 0 -> 0;`

---

## `instanceof` Pattern (Java 16+)

```java
// Old
if (obj instanceof User) {
  User u = (User) obj;
  return u.getEmail();
}

// Good
if (obj instanceof User u) {
  return u.email();
}

// Chained
if (obj instanceof User u && u.isActive() && !u.email().isBlank()) {
  return u.email();
}
```

The pattern variable is in scope where the type holds. Pair with
`&&` chains to flatten what used to be nested guards.

---

## Loops: Pick the Right One

| Loop | When |
|---|---|
| `for-each` (`for (X x : xs)`) | Iterate items |
| `for (int i = 0; ...; i++)` | Need the index or mutate via index |
| `while (cond)` | Indefinite, condition-driven |
| Stream `.forEach` | When you're already in a stream pipeline |

```java
// Good — iterate items
for (var user : users) {
  process(user);
}

// Good — index needed
for (int i = 0; i < users.size(); i++) {
  process(i, users.get(i));
}
```

Don't index-loop when `for-each` works:

```java
// Bad
for (int i = 0; i < users.size(); i++) {
  process(users.get(i));
}
```

For paired iteration, use a stream:

```java
IntStream.range(0, names.size())
    .forEach(i -> log.info("name[{}]={}, age[{}]={}", i, names.get(i), i, ages.get(i)));
```

---

## `if` vs Ternary

| Need | Reach for |
|---|---|
| Single condition, short branches | Ternary |
| Branches with statements / side effects | `if`/`else` |
| Many discriminated cases | switch expression |

```java
// Good
String label = user.isAdmin() ? "admin" : "user";

// Bad — nested ternary is illegible
String grade = s >= 90 ? "A" : s >= 80 ? "B" : s >= 70 ? "C" : "F";

// Good — explicit
String grade =
    s >= 90 ? "A"
    : s >= 80 ? "B"
    : s >= 70 ? "C"
    : "F";

// Better — extract
String grade = gradeFor(s);
private static String gradeFor(int s) {
  if (s >= 90) return "A";
  if (s >= 80) return "B";
  if (s >= 70) return "C";
  return "F";
}
```

---

## `Optional` and Conditional Logic

`Optional` has fluent operations that often replace `if`/`else`:

```java
// Bad
User user = repo.findById(id);
if (user != null) {
  return user.getEmail();
}
return "anonymous";

// Good — Optional
return repo.findById(id)
    .map(User::email)
    .orElse("anonymous");
```

Don't overdo it. Three chained `.map().filter().flatMap()` start to read
worse than the equivalent `if` ladder.

---

## `break`, `continue`, Labels

`continue` to flatten a loop body:

```java
// Good — continue early
for (var item : items) {
  if (!item.isValid()) continue;
  if (item.isProcessed()) continue;
  process(item);
}
```

Labeled break / continue exist for nested loops but are rarely needed —
extract the inner loop to a method instead:

```java
// Avoid
outer:
for (var row : grid) {
  for (var cell : row) {
    if (cell == target) break outer;
  }
}

// Better — method with early return
return findIn(grid, target);
```

---

## Switch Fallthrough

In the classic `:` switch, missing `break` falls through. Arrow form
doesn't fall through. Always prefer arrow form.

When two `:` cases share logic, list both labels — don't intentionally
omit `break`:

```java
// Arrow form — preferred
String season(int month) {
  return switch (month) {
    case 12, 1, 2 -> "winter";
    case 3, 4, 5 -> "spring";
    case 6, 7, 8 -> "summer";
    case 9, 10, 11 -> "fall";
    default -> throw new IllegalArgumentException();
  };
}
```

---

## `do-while` vs `while`

`do-while` runs the body at least once. Useful for retry loops:

```java
// Retry up to 3 times
int attempt = 0;
Result result;
do {
  result = tryOnce();
  attempt++;
} while (result.isFailure() && attempt < 3);
```

In most cases, regular `while` reads better. Reach for `do-while` when "at
least one iteration" is the explicit requirement.

---

## Don't Mix Assignment and Branching

```java
// Bad — confusing
User user;
if ((user = findUser(id)) != null) { ... }

// Good
User user = findUser(id);
if (user != null) { ... }
```

Java doesn't have an "if-let" or "while-let"; declare, then test.

---

## Quick Reference

| Want | Default |
|---|---|
| Flatten nested ifs | Early return |
| Pick a value | Switch expression |
| Destructure sum type | Pattern-matching switch (21+) |
| Type test + cast | `instanceof X x` |
| Iterate items | `for-each` |
| Iterate indices | `for (int i...)` |
| Default for missing | `Optional.orElse` |
| Avoid | nested ternaries, fallthrough in `:` switch |

## Related Skills

- **Style core**: [java-style-core](../java-style-core/SKILL.md) for nesting principles.
- **Types**: [java-types](../java-types/SKILL.md) for sealed types and `instanceof` pattern.
- **Classes**: [java-classes](../java-classes/SKILL.md) for record-based sum types.
- **Functions**: [java-methods-lambdas](../java-methods-lambdas/SKILL.md) for `Optional.map`.
- **Error handling**: [java-error-handling](../java-error-handling/SKILL.md) for guard-clause throws.
