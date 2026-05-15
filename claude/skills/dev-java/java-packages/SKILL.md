---
name: java-packages
description: Use when designing Java package layout, organizing modules (JPMS), choosing between package-private and public, applying the principle of least exposure, structuring `src/main/java` and `src/test/java`, or migrating from a flat structure to a layered one.
license: Apache-2.0
metadata:
  sources: "Effective Java Item 15 (minimize accessibility), JPMS docs, Spring project structure guide"
---

# Java Packages and Module Boundaries

## Maven / Gradle Layout

The conventional layout:

```
my-project/
├── pom.xml (or build.gradle.kts)
├── src/
│   ├── main/
│   │   ├── java/
│   │   │   └── com/acme/myapp/
│   │   │       ├── MyApp.java
│   │   │       ├── user/
│   │   │       │   ├── User.java
│   │   │       │   ├── UserRepository.java
│   │   │       │   └── UserService.java
│   │   │       └── config/
│   │   │           └── Settings.java
│   │   └── resources/
│   │       └── application.yml
│   └── test/
│       ├── java/
│       │   └── com/acme/myapp/
│       │       └── user/
│       │           └── UserRepositoryTest.java
│       └── resources/
└── target/   (or build/)
```

Stay on this layout unless you have a concrete reason. Build tools, IDEs,
test runners, and packaging plugins assume it.

---

## Package by Feature, Not by Layer

Two organizing principles:

| Layer-based (bad) | Feature-based (good) |
|---|---|
| `com.acme.controller.*` | `com.acme.user.*` |
| `com.acme.service.*` | `com.acme.order.*` |
| `com.acme.repository.*` | `com.acme.invoice.*` |
| `com.acme.dto.*` | (each feature has its own controller, service, repo) |

A feature package owns its full vertical slice. Cross-package dependencies
flow in one direction (e.g. `invoice` may depend on `user`, but `user` knows
nothing about `invoice`).

```
com.acme.myapp/
├── user/
│   ├── User.java                  // entity / record
│   ├── UserRepository.java        // interface
│   ├── JdbcUserRepository.java    // implementation
│   ├── UserService.java
│   └── UserController.java
├── order/
│   └── ...
└── shared/
    └── ...                        // genuinely shared utilities
```

This is the "Hexagonal" or "Vertical Slice" approach. Easier to navigate,
easier to delete a feature, easier to extract into a separate service.

---

## Minimize Accessibility

The narrowest scope that compiles is the right one. Java has four levels:

| Modifier | Scope |
|---|---|
| `private` | Inside the class only |
| (default — no modifier) | Same package |
| `protected` | Same package + subclasses |
| `public` | Anywhere |

Default to `private`. Promote to package-private when another class in the
same package needs access. Promote to `public` only when you've decided
this is the package's external contract.

```java
// In com.acme.user
public class UserService {
  private final UserRepository repo;   // private — internal state
  public UserService(UserRepository repo) { this.repo = repo; }
  public User getById(String id) { return repo.findById(id); }
  User normalize(User u) { ... }      // package-private — only UserService and tests use it
}
```

`protected` is rare. It's an "I expect this to be extended" signal — use it
only in classes designed for inheritance.

---

## One Public Type Per File

The file name must match the public type. Other types in the file are
package-private (or `private static` nested):

```java
// User.java
public record User(String id, String email) {}

// UserRepository.java
public interface UserRepository {
  User findById(String id);
}

class UserRepositoryHelper {  // package-private — only used in this file's package
  ...
}
```

For helpers used by exactly one class, prefer a private static nested class
inside that class.

---

## Imports

```java
// Good — explicit
import java.util.List;
import java.util.Map;

// Bad — wildcard
import java.util.*;
```

Wildcard imports hide what you depend on, break under refactors, and create
ambiguity when two packages have classes with the same name. The formatter
expands wildcards.

Static imports are useful when they reduce noise (`assertEquals`, `Mockito.mock`)
but become noise themselves when overused:

```java
// Good in test code
import static org.junit.jupiter.api.Assertions.*;
import static org.assertj.core.api.Assertions.assertThat;

// Bad in production code — readers hunt for where `now()` comes from
import static java.time.LocalDateTime.now;
```

Limit static imports to test assertion APIs and a handful of well-known
factory methods (`Map.of`, `List.of`).

---

## Package Cycles Are Bugs

If package `a` imports from `b` and `b` imports from `a`, the design has a
problem. Fix by:

1. **Extracting the shared types** into a third package (often `shared` or
   `domain`).
2. **Inverting the dependency** — define an interface in the lower-level
   package, implement it in the higher-level one (the "ports and adapters"
   pattern).

Tools: ArchUnit can assert architectural rules in tests:

```java
@Test
void userPackageDoesNotDependOnOrder() {
  noClasses()
      .that().resideInAPackage("..user..")
      .should().dependOnClassesThat().resideInAPackage("..order..")
      .check(importedClasses);
}
```

---

## Java Modules (JPMS)

For libraries published to a Java 9+ runtime, declare a `module-info.java`:

```java
module com.acme.myapp {
  requires java.sql;
  requires org.slf4j;
  exports com.acme.myapp.api;          // public API
  exports com.acme.myapp.internal      // exposed only to one consumer
      to com.acme.myapp.consumer;
}
```

For application code, JPMS is optional. Most teams skip it; the cost of
maintaining `module-info` doesn't pay back unless you're publishing a
library.

---

## `package-info.java` for Package Docs

A package can have a `package-info.java` file with a Javadoc comment and
package-level annotations:

```java
/**
 * User domain — entities, repository, and service for the ``users`` table.
 *
 * <p>External callers should depend only on {@link UserService}. The
 * repository interface and implementations are internal.
 */
@NullMarked
package com.acme.myapp.user;

import org.jspecify.annotations.NullMarked;
```

`@NullMarked` (JSpecify) marks the package as null-aware — annotations like
`@Nullable` apply to the package's API surface.

---

## Don't Expose Internal Types in Public APIs

If a public method returns `InternalMessage`, you can't change
`InternalMessage` without breaking callers. Define a separate `Message`
public DTO and convert:

```java
public class UserService {
  public PublicUserDto getById(String id) {
    User user = repo.findById(id);
    return PublicUserDto.from(user);    // conversion in service
  }
}
```

Effective Java Item 64: refer to objects by their interfaces. A public method
returning `ArrayList<String>` instead of `List<String>` locks you in.

---

## Avoid `model.shared`, `util.common` Packages

A package called `common`, `util`, `shared`, `helpers` is a magnet for
everything that doesn't fit elsewhere — and that's the problem. The longer
it lives, the more cross-cutting it becomes, until removing anything from it
breaks unrelated features.

Better: a small `domain` or `shared` package with explicit, narrow content
(`Money`, `EmailAddress`, `Identifier`). When a "shared" type grows specific
to one feature, move it there.

---

## Quick Reference

| Question | Default |
|---|---|
| Layout | Maven/Gradle standard |
| Organization | By feature, not by layer |
| Visibility default | `private` |
| Wildcard imports | No |
| Static imports | Tests only, mostly |
| Cycles | Refactor immediately |
| Public DTOs | Separate from internal entities |

## Related Skills

- **Style core**: [java-style-core](../java-style-core/SKILL.md) for import ordering.
- **Naming**: [java-naming](../java-naming/SKILL.md) for package names.
- **Classes**: [java-classes](../java-classes/SKILL.md) for `record` and visibility.
- **Documentation**: [java-documentation](../java-documentation/SKILL.md) for `package-info.java`.
- **Linting**: [java-linting](../java-linting/SKILL.md) for ArchUnit and Checkstyle import rules.
