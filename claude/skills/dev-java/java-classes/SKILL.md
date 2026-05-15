---
name: java-classes
description: Use when designing Java classes — choosing between records, regular classes, sealed types, abstract classes, and interfaces, applying inheritance vs composition, visibility, `final` classes, and inner/nested types. Also use when refactoring class hierarchies or replacing inheritance with delegation.
license: Apache-2.0
metadata:
  sources: "Effective Java (Items 15-25), JEP 395 (records), JEP 409 (sealed classes)"
---

# Java Classes

## Record First

For value-like data, use a record:

```java
public record User(String id, String email, boolean isAdmin) {}
```

Records get for free: `equals`, `hashCode`, `toString`, accessors, canonical
constructor. Fields are final; the record itself is implicitly `final`
(can't be extended).

Add validation in a compact constructor:

```java
public record EmailAddress(String value) {
  public EmailAddress {
    Objects.requireNonNull(value, "value");
    if (!value.contains("@")) throw new IllegalArgumentException("invalid email");
  }
}
```

Static factories and instance methods are fine:

```java
public record Money(BigDecimal amount, Currency currency) {
  public static Money zero(Currency c) { return new Money(BigDecimal.ZERO, c); }
  public Money add(Money other) {
    if (!currency.equals(other.currency)) throw new IllegalArgumentException();
    return new Money(amount.add(other.amount), currency);
  }
}
```

Use records for DTOs, value objects, message types. Use a class when the
entity has identity (a service, a stateful actor).

---

## Class for Identity

A regular class is the right tool when:

- The object has identity (a database session, a logger, an HTTP client).
- State and behavior are tightly coupled and used together.
- You need polymorphism (multiple implementations of one interface).
- A framework requires it (Spring beans, JPA entities).

```java
public class UserService {
  private final UserRepository repo;
  private final Logger log = LoggerFactory.getLogger(getClass());

  public UserService(UserRepository repo) {
    this.repo = Objects.requireNonNull(repo);
  }

  public User getById(String id) {
    return repo.findById(id)
        .orElseThrow(() -> new NotFoundException("user", id));
  }
}
```

Constructor injection (one constructor, all dependencies) is the cleanest
DI pattern. Avoid field injection (`@Autowired` on fields) — it makes
classes hard to test and hides dependencies.

---

## Composition over Inheritance

A two-level `class A extends B` is sometimes useful. A three-level chain
rarely is — extract shared behavior and inject it.

```java
// Bad — chained inheritance
class Animal { ... }
class Mammal extends Animal { ... }
class Dog extends Mammal { ... }

// Good — composition + interface
public interface Walker { void walk(); }

public class Dog implements Walker {
  private final Logger log;
  public Dog(Logger log) { this.log = log; }
  @Override public void walk() { log.info("walking"); }
}
```

Prefer `implements` (contract) over `extends` (mechanism) when the shared
behavior is just an API surface.

---

## Sealed Types for Closed Hierarchies

Sealed types enumerate their permitted subtypes:

```java
public sealed interface Shape permits Circle, Square, Triangle {}

public record Circle(double radius) implements Shape {}
public record Square(double side) implements Shape {}
public record Triangle(double base, double height) implements Shape {}
```

The compiler enforces exhaustive matching in switch (see
[java-control-flow](../java-control-flow/SKILL.md)). Adding a permitted
subtype triggers a compile error in every switch that doesn't handle it —
that's the win.

---

## Abstract Classes: Last Resort

An abstract class makes sense when you genuinely want a partial
implementation that subclasses fill in:

```java
public abstract class BaseHandler {
  protected final Logger log = LoggerFactory.getLogger(getClass());

  public final Response run(Request req) {
    var validated = validate(req);
    var response = handle(validated);
    log.info("request processed");
    return response;
  }

  protected Request validate(Request req) {
    Objects.requireNonNull(req);
    return req;
  }

  protected abstract Response handle(Request req);
}
```

If the base has no concrete code, switch to `interface` with `default`
methods or drop inheritance entirely.

Mark `final` what you don't want overridden. Without `final`, a subclass
can change `run`'s semantics and silently break invariants.

---

## Interfaces with `default` Methods

Java 8+ interfaces can have implementations:

```java
public interface UserRepository {
  Optional<User> findById(String id);

  default User getById(String id) {
    return findById(id).orElseThrow();
  }
}
```

Use `default` when:

- Adding a method to an existing interface without breaking implementers.
- Providing a convenient overload around the abstract methods.

Don't use `default` for the *primary* behavior — that's what classes are
for.

---

## Visibility: Default Private

The narrowest scope that compiles is the right one. See
[java-packages](../java-packages/SKILL.md).

```java
public class UserService {
  private final UserRepository repo;     // private field
  UserService(UserRepository repo) { ... }   // package-private constructor (testing)
  public User getById(String id) { ... }   // public API
  User normalize(User u) { ... }            // package-private helper
}
```

`protected` is rare. Use it only in classes designed for inheritance.

---

## `final` Classes

Mark classes `final` unless you've intentionally designed for extension.
Effective Java Item 19: "design and document for inheritance, or prohibit
it."

```java
public final class UserService { ... }
```

Records and enums are implicitly `final`. Most application classes should
be too — opening them to inheritance commits you to maintaining the
inheritance contract.

---

## Nested Classes

Java has four kinds:

| Kind | Has reference to outer? | When |
|---|---|---|
| `static class` (nested) | No | Helper class scoped to outer |
| Inner class (no `static`) | Yes | Captures outer state (e.g. iterator) |
| Local class | Yes (within method) | Rare; usually replaced by lambda |
| Anonymous class | Yes | Rare; usually replaced by lambda |

Prefer `static` nested classes — they don't carry a hidden reference to the
outer instance (which can hold it alive in memory).

```java
public class OuterCache {
  // Good — static
  static class Entry<V> {
    final long ts;
    final V value;
    Entry(long ts, V value) { this.ts = ts; this.value = value; }
  }
}
```

---

## Constructors

Validate inputs in the constructor. Throw on invalid:

```java
public class UserService {
  private final UserRepository repo;
  private final Duration timeout;

  public UserService(UserRepository repo, Duration timeout) {
    this.repo = Objects.requireNonNull(repo, "repo");
    if (timeout.isNegative() || timeout.isZero()) {
      throw new IllegalArgumentException("timeout must be positive");
    }
    this.timeout = timeout;
  }
}
```

For records, the compact constructor is the place for validation:

```java
public record User(String id, String email) {
  public User {
    Objects.requireNonNull(id);
    Objects.requireNonNull(email);
  }
}
```

---

## `equals` and `hashCode`

For records, both are generated. For regular classes, override either both
or neither.

Contract: `a.equals(b)` implies `a.hashCode() == b.hashCode()`. Breaking
this breaks hash-based collections silently.

```java
@Override
public boolean equals(Object o) {
  if (this == o) return true;
  if (!(o instanceof User other)) return false;
  return id.equals(other.id);   // identity by id
}

@Override
public int hashCode() {
  return Objects.hash(id);
}
```

Entities (DB rows) typically compare by id. Value objects compare by
all fields — that's what `record` gives for free.

---

## `toString`

Override `toString` on classes that aren't records. Records generate a
useful default. For classes, include the identifying fields:

```java
@Override
public String toString() {
  return "User[id=%s, email=%s]".formatted(id, email);
}
```

Don't include sensitive fields (passwords, tokens) — `toString` ends up
in logs.

---

## `this::method` and Inheritance

If a constructor calls a method that subclasses override, the subclass's
version runs before the subclass's fields are initialized. Don't call
overridable methods from a constructor.

```java
// Bad
public class Base {
  public Base() {
    init();   // calls subclass version with subclass uninitialized
  }
  protected void init() { ... }
}
```

Make initialization methods `final` or `private`.

---

## Quick Reference

| Question | Default |
|---|---|
| Value object | `record` |
| Sum type | `sealed` interface + record permits |
| Service / stateful | regular class |
| Public class default | `final` unless inheritance intended |
| Nested class default | `static` |
| Visibility default | `private` |
| Inheritance depth | ≤ 2 levels |
| Abstract class | Last resort |
| Constructor | Validate inputs; throw on invalid |
| Identity (entity) | `equals` by id |

## Related Skills

- **Types**: [java-types](../java-types/SKILL.md) for `record` vs class.
- **Generics**: [java-generics](../java-generics/SKILL.md) for generic class design.
- **Methods/lambdas**: [java-methods-lambdas](../java-methods-lambdas/SKILL.md) for method signatures.
- **Naming**: [java-naming](../java-naming/SKILL.md) for class member naming.
- **Packages**: [java-packages](../java-packages/SKILL.md) for visibility.
- **Error handling**: [java-error-handling](../java-error-handling/SKILL.md) for `Objects.requireNonNull`.
