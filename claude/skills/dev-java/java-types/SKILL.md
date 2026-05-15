---
name: java-types
description: Use when working with Java types — primitives vs wrappers, `var`, records, sealed types, enums, `Optional`, nullability annotations, type inference, or `instanceof` pattern matching. Also use when modeling state, replacing boolean flags with enums, or eliminating null from a public API.
license: Apache-2.0
compatibility: Java 17+ baseline. Pattern-matching `switch` is 21+.
metadata:
  sources: "Effective Java, JEP 286 (var), JEP 395 (records), JEP 409 (sealed), JEP 441 (pattern-matching)"
---

# Java Types

## Primitives vs Wrappers

| Use | Reach for |
|---|---|
| Performance, no null possible | primitive (`int`, `long`, `boolean`) |
| Collection element / generic parameter | wrapper (`Integer`, `Long`, `Boolean`) |
| Field that may be absent | wrapper (or `OptionalInt` etc.) |

Autoboxing is fine in the application layer; in hot loops, it allocates.

```java
// In a hot loop, avoid boxing in/out
long sum = 0;
for (long x : values) {       // primitive iteration
  sum += x;
}

// Avoid in a hot loop
Long sum = 0L;
for (Long x : values) { sum += x; }   // box, unbox each iter
```

Reach for primitives in fields, locals, and parameters where null isn't a
valid value. Reach for wrappers when null *is* a valid value or generics
force them.

---

## `var` for Local Variables (Java 10+)

Use `var` when the type is obvious. Don't use it when it adds friction:

```java
// Good
var users = new ArrayList<User>();
var path = Path.of("/tmp/log");
var stream = Files.lines(path);

// Acceptable
var user = repo.findById(id);

// Bad
var result = compute(input);    // reader doesn't know the type
var x = service.call();          // ditto
```

`var` is illegal for fields, method parameters, and return types — and that's
right: public surfaces benefit from explicit types.

---

## Records for Value Objects (Java 14+)

A record is the right tool for a fixed-shape immutable value:

```java
public record User(String id, String email, boolean isAdmin) {}

User user = new User("u1", "a@b", false);
user.email();                   // accessor — same name as field
user.equals(new User("u1", "a@b", false));   // true, by value
user.toString();                 // User[id=u1, email=a@b, isAdmin=false]
```

Records get for free: equals, hashCode, toString, accessors, canonical
constructor.

Add validation in a compact constructor:

```java
public record EmailAddress(String value) {
  public EmailAddress {
    Objects.requireNonNull(value);
    if (!value.contains("@")) throw new IllegalArgumentException();
  }
}
```

Use records for DTOs, value objects, multi-return tuples. Reach for a class
when the entity has identity (entity, service) — see
[java-classes](../java-classes/SKILL.md).

---

## Sealed Types (Java 17+)

Sealed types enumerate their permitted subtypes. The compiler can then
enforce exhaustive matching:

```java
public sealed interface Result permits Success, Failure, Pending {}

public record Success(User user) implements Result {}
public record Failure(String reason) implements Result {}
public record Pending() implements Result {}

// Exhaustive switch (Java 21+)
String render(Result r) {
  return switch (r) {
    case Success s -> s.user().email();
    case Failure f -> "error: " + f.reason();
    case Pending p -> "...";
    // no default needed — compiler verifies exhaustiveness
  };
}
```

Sealed + records + pattern-matching switch is Java's answer to discriminated
unions. The compiler catches missing cases at compile time.

---

## Enums

```java
public enum Status { PENDING, ACTIVE, ARCHIVED }
```

Enums in Java are full classes — they can have fields, methods, and
abstract method per-constant overrides:

```java
public enum LogLevel {
  ERROR(0), WARN(1), INFO(2), DEBUG(3);

  private final int severity;
  LogLevel(int s) { this.severity = s; }
  public int severity() { return severity; }
}
```

Use enums for finite, well-known sets of values. Don't roll your own
"constants class" — enums give you switch exhaustiveness, valueOf, and
`EnumSet`/`EnumMap` (fast O(1) backed by bit fields).

---

## `Optional<T>` for Possibly-Absent Returns

`Optional<T>` was introduced for **return values** that might be absent.
Don't use it for fields or parameters.

```java
// Good
public Optional<User> findByEmail(String email) {
  User u = repo.findByEmail(email);
  return Optional.ofNullable(u);
}

// Caller
findByEmail(email)
    .map(User::id)
    .ifPresent(this::trackLogin);

// Bad — Optional as a field
record User(String id, Optional<String> phone) {}    // serializes badly, allocates

// Bad — Optional as a parameter
public User load(Optional<String> id) { ... }        // just use overloads or null check
```

`Optional.get()` without checking is a smell — equivalent to throwing
`NoSuchElementException`. Use `orElse`, `orElseThrow`, `ifPresent`, `map`,
`flatMap`.

---

## `null` and Nullability

Java has null. You cannot eliminate it — but you can document it and let
tools check it.

Use JSpecify (`@NullMarked`, `@Nullable`) or the older JSR-305 set:

```java
@NullMarked     // package-info.java — everything non-null by default
package com.acme.myapp.user;

public interface UserRepository {
  User findById(String id);                 // non-null
  @Nullable User findByEmail(String email); // may be null
}
```

Tools (NullAway, Checker Framework, IntelliJ inspection) enforce. Without
them, null annotations are documentation only.

---

## `instanceof` Pattern Matching (Java 16+)

```java
// Old
if (shape instanceof Circle) {
  Circle c = (Circle) shape;
  return Math.PI * c.radius() * c.radius();
}

// New — bind in the test
if (shape instanceof Circle c) {
  return Math.PI * c.radius() * c.radius();
}
```

The pattern variable is in scope where the type holds. Especially useful
inside `&&` chains:

```java
if (obj instanceof User u && u.isActive() && !u.email().isBlank()) { ... }
```

Pair with sealed types and switch for exhaustive matching.

---

## Generic Types

| Want | Reach for |
|---|---|
| One type parameter | `<T>` |
| Multiple parameters | `<K, V>`, `<UserT, OrderT>` (descriptive when needed) |
| Subtype constraint | `<T extends Comparable<T>>` |
| Wildcard "any read" | `List<? extends User>` |
| Wildcard "any write" | `List<? super User>` |
| Erased | (avoid raw types) |

See [java-generics](../java-generics/SKILL.md) for PECS, bounded wildcards,
and the diamond operator.

---

## Don't Use Raw Types

```java
// Bad — raw
List list = new ArrayList();
list.add("oops");   // checker can't help

// Good
List<String> list = new ArrayList<>();
list.add("ok");
```

Raw types compile but disable generics. They're a legacy bridge; don't
introduce them in new code.

---

## `final` for Locals and Parameters

Declaring locals `final` documents "this won't be reassigned" and lets the
checker enforce it. Some teams require it; others find it noisy.

Google Java Style doesn't require `final` on locals; modern tooling
(refactor, IDE warnings) makes it less necessary. The rule:

- `final` on **fields** — yes, unless mutable is required.
- `final` on **method parameters** — optional; team style.
- `final` on **local variables** — optional; consider `var` instead.

Records' fields are implicitly final.

---

## `BigDecimal` for Money

Don't use `double` or `float` for currency. Use `BigDecimal`:

```java
// Bad — floating point in currency
double total = 0.1 + 0.2;   // 0.30000000000000004

// Good
BigDecimal total = new BigDecimal("0.1").add(new BigDecimal("0.2"));
// 0.3
```

Always construct `BigDecimal` from a `String` (or int / long), not from a
`double`. `new BigDecimal(0.1)` carries the floating-point error.

---

## Quick Reference

| Need | Reach for |
|---|---|
| Immutable value | `record` |
| Sum type | `sealed` interface + `record` permits |
| Finite set | `enum` |
| Possibly-absent return | `Optional<T>` |
| Nullable field/param | `@Nullable` annotation |
| Local with obvious type | `var` |
| Type test + cast | `instanceof X x` |
| Money | `BigDecimal` |
| Hot loop | primitive |

## Related Skills

- **Style core**: [java-style-core](../java-style-core/SKILL.md) for the broader baseline.
- **Naming**: [java-naming](../java-naming/SKILL.md) for type parameter and enum naming.
- **Classes**: [java-classes](../java-classes/SKILL.md) for class vs record.
- **Generics**: [java-generics](../java-generics/SKILL.md) for wildcard variance.
- **Control flow**: [java-control-flow](../java-control-flow/SKILL.md) for switch expression and pattern matching.
- **Error handling**: [java-error-handling](../java-error-handling/SKILL.md) for `Optional.orElseThrow`.
