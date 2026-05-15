---
name: java-methods-lambdas
description: Use when designing Java method signatures, writing lambdas, using method references, choosing functional interfaces (`Function`, `Predicate`, `Consumer`, `Supplier`), or refactoring inner classes to lambdas. Also use when reviewing parameter shape ("boolean trap"), default arguments via overloading, or overload resolution.
license: Apache-2.0
metadata:
  sources: "Effective Java (Items 42-44), Google Java Style Guide, java.util.function docs"
---

# Java Methods, Lambdas, and Functional Interfaces

## Method Signatures: 0–3 Positional, Else Builder or Record

| Count | Shape |
|---|---|
| 0–3 simple, ordered, obvious | Positional |
| ≥ 4, or any boolean / optional flag | Builder, options record, or named overloads |

```java
// Bad — boolean trap
public User createUser(String name, String email, boolean isAdmin, boolean active) { ... }
createUser("Ada", "a@b", false, true);   // which is which?

// Good — options record
public record CreateUserOptions(
    String name,
    String email,
    boolean isAdmin,
    boolean active
) {}
public User createUser(CreateUserOptions opts) { ... }

// Good — builder for complex construction
public class CreateUser {
  private String name, email;
  private boolean isAdmin = false, active = true;
  public CreateUser name(String n) { this.name = n; return this; }
  // ...
  public User build() { ... }
}
```

Records work well when the parameter set is closed. Builders when it grows
over time.

---

## Overloading for "Default Argument"

Java doesn't have default parameters. Express them with overloads:

```java
public User createUser(String name, String email) {
  return createUser(name, email, false, true);
}

public User createUser(String name, String email, boolean isAdmin, boolean active) {
  // ...
}
```

For more than two or three combinations, the overload explosion gets ugly —
switch to options-record or builder.

---

## `varargs` for Genuinely Variadic

```java
public static <T> List<T> listOf(T... items) {
  return List.of(items);    // or Arrays.asList
}

listOf("a", "b", "c");
listOf();                    // valid — empty
```

Use `varargs` only when the method really takes a variable number of args
(`String.format`, `List.of`). Don't replace a normal `List<T>` parameter
with `T...` — the caller now has to pick.

Pitfall: passing a `T[]` to a `T...` method works; passing a `List<T>`
doesn't. Don't make both available.

---

## Method References

`ClassName::method` is shorthand for a lambda that calls that method:

```java
// Lambda
users.stream().map(u -> u.email()).toList();

// Method reference — same effect, less noise
users.stream().map(User::email).toList();
```

Forms:

| Form | Example | Equivalent lambda |
|---|---|---|
| Static | `Integer::parseInt` | `s -> Integer.parseInt(s)` |
| Bound | `user::email` | `() -> user.email()` |
| Unbound | `User::email` | `u -> u.email()` |
| Constructor | `User::new` | `(args) -> new User(args)` |

Use method references when they're clearer than the equivalent lambda. If
the lambda body adds anything (a check, a wrapper), use the lambda.

---

## Lambdas: Keep Them Short

```java
// Good
List<String> emails = users.stream()
    .filter(User::isActive)
    .map(User::email)
    .toList();

// Bad — too much in a lambda body
List<String> result = users.stream()
    .filter(u -> {
      var settings = configFor(u);
      if (settings.isBlocked()) return false;
      if (u.isActive() && u.getCreatedAt().isAfter(threshold)) return true;
      return u.isAdmin();
    })
    .map(User::email)
    .toList();
```

Extract long lambda bodies into named methods. The stream pipeline becomes
self-documenting.

---

## `java.util.function`

The standard functional interfaces cover most cases. Use them, don't roll
your own:

| Interface | Signature | Use |
|---|---|---|
| `Function<T, R>` | `R apply(T)` | Transform |
| `BiFunction<T, U, R>` | `R apply(T, U)` | Two-arg transform |
| `Predicate<T>` | `boolean test(T)` | Filter |
| `Consumer<T>` | `void accept(T)` | Side effect |
| `Supplier<T>` | `T get()` | Lazy / factory |
| `UnaryOperator<T>` | `T apply(T)` | Same-type transform |
| `BinaryOperator<T>` | `T apply(T, T)` | Reduce-like |

Specialized primitives avoid boxing in hot paths: `IntFunction<R>`,
`ToIntFunction<T>`, `IntPredicate`, etc.

Define your own functional interface only when the method name carries
meaning the standard one doesn't:

```java
@FunctionalInterface
public interface RetryPolicy {
  boolean shouldRetry(int attempt, Throwable lastError);
}
```

`@FunctionalInterface` is documentation + a compile-time check (exactly one
abstract method).

---

## `Optional` Composition

`Optional` returns can chain with method references:

```java
return findById(id)
    .map(User::email)            // Optional<String>
    .filter(e -> !e.isBlank())
    .orElseThrow(() -> new NotFoundException("user", id));
```

Use `Optional.flatMap` when the next step returns `Optional<U>`:

```java
return findById(userId)
    .flatMap(this::findCart)     // returns Optional<Cart>
    .map(Cart::total)
    .orElse(BigDecimal.ZERO);
```

---

## Argument Order: Required Before Optional

```java
// Bad
public void send(String body, Recipient to) { ... }   // body first hides the destination

// Good
public void send(Recipient to, String body) { ... }
```

For methods with both required and optional logical parameters: required
first, then "less essential" parameters in order of decreasing importance.

---

## Method Length

Aim for under ~30 lines. A method with 8 locals, 3 branches, 2 loops, and
3 sections labeled with `// Step N:` wants to be several methods.

A method does one thing at one level of abstraction. The level matters —
"validate, enrich, save, and email the user" is a four-level method.

---

## Return Types

| Want | Reach for |
|---|---|
| One value | The value |
| Possibly absent | `Optional<T>` |
| Multiple, related | `record` |
| Collection | `List<T>`, never null |
| Stream | `Stream<T>` — when caller may want lazy consumption |
| Async | `CompletableFuture<T>` or virtual-thread Future |

A method that returns a `List<T>` should return an empty list, never
`null`:

```java
// Bad
public List<User> activeUsers() {
  if (db.isDown()) return null;   // surprise NPE in caller
  return ...;
}

// Good
public List<User> activeUsers() {
  if (db.isDown()) return List.of();
  return ...;
}
```

---

## `static` Methods

Use `static` for:

- Helpers that don't depend on instance state (factory methods, pure
  utilities).
- Constants and factory methods on enums and records.

Don't make every method `static` "because it's faster" — testability and
overridability suffer.

---

## `final` on Parameters

Optional. Some teams require it for documentation; modern tooling
(IntelliJ "reassigned parameter" warning) makes it less necessary. Effective
Java doesn't require it; Google Java Style allows it but doesn't mandate it.

Pick once for the project.

---

## Effectively Final

Lambdas can only capture locals that are **effectively final** —
unmodified after assignment. The compiler enforces this:

```java
// Bad
int counter = 0;
list.forEach(x -> counter++);    // compile error

// Good — atomic or list mutation
AtomicInteger counter = new AtomicInteger();
list.forEach(x -> counter.incrementAndGet());

// Or — collect, don't accumulate
long count = list.stream().count();
```

This is intentional: it preserves safety in concurrent execution and forces
state to be explicit.

---

## Quick Reference

| Question | Default |
|---|---|
| Many args? | Options record or builder |
| Default arg? | Overload, not Java default |
| Method reference vs lambda | Method reference if shorter; lambda if body adds |
| Custom functional interface? | Only when stdlib doesn't fit |
| Return null collection? | No — empty collection |
| `@FunctionalInterface` | Yes on your own functional interfaces |
| Method length | Under ~30 lines |

## Related Skills

- **Types**: [java-types](../java-types/SKILL.md) for `Optional`, records.
- **Generics**: [java-generics](../java-generics/SKILL.md) for `Function<T, R>` parameterization.
- **Streams**: [java-data-structures](../java-data-structures/SKILL.md) for stream-based pipelines.
- **Classes**: [java-classes](../java-classes/SKILL.md) for record / class method design.
- **Naming**: [java-naming](../java-naming/SKILL.md) for method verbs.
