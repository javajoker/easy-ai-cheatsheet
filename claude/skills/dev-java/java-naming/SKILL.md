---
name: java-naming
description: Use when naming classes, interfaces, methods, fields, constants, packages, generic type parameters, or test classes in Java. Also use when reviewing identifier names, choosing exception class names, or settling debates over interface I-prefix and getter naming.
license: Apache-2.0
metadata:
  sources: "Google Java Style Guide, Oracle Code Conventions, Effective Java"
allowed-tools: Bash(bash:*)
---

# Java Naming

## Available Scripts

- **`scripts/check-naming.sh`** — Scans Java files for naming-convention violations: `I`-prefixed interfaces, types in lowercase/snake_case, exception classes not ending in `Exception`, and Hungarian-style prefixes. Run `bash scripts/check-naming.sh --help`. For stronger enforcement, use Checkstyle's `google_checks.xml` (see [java-linting](../java-linting/SKILL.md)).

## Identifier Cases (Canonical Table)

| Kind | Case | Example |
|---|---|---|
| Classes, interfaces, enums, records, annotations | `PascalCase` | `UserRepository`, `Status` |
| Type parameters | Single capital or short `PascalCase` | `T`, `K`, `Value` |
| Methods, fields, parameters, local variables | `camelCase` | `getUser`, `lastLogin` |
| Constants (`static final`) | `UPPER_SNAKE_CASE` | `MAX_RETRIES`, `DEFAULT_TIMEOUT` |
| Packages | `lowercase` (no underscores) | `com.example.user`, `myapp.config` |
| Test classes | `<NameUnderTest>Test` | `UserRepositoryTest` |
| Boolean methods | `is`/`has`/`can`/`should` prefix | `isActive()`, `hasAccess()` |

Java's naming is well-defined. Match the conventions exactly — auto-imports
and IDE actions assume they hold.

---

## No `I` Prefix on Interfaces

Modern Java does **not** prefix interfaces with `I`. The user of a type
shouldn't have to know whether it's an interface or a concrete class.

```java
// Bad
interface IUserRepository { ... }
class UserRepositoryImpl implements IUserRepository { ... }

// Good
interface UserRepository { ... }
class JdbcUserRepository implements UserRepository { ... }
class InMemoryUserRepository implements UserRepository { ... }
```

When there's exactly one implementation, prefer naming it after what it does
(`JdbcUserRepository`) rather than `UserRepositoryImpl`. `Impl` suffix is a
last-resort name; it conveys nothing.

---

## No Hungarian, No Type Encoding

```java
// Bad
String strName;
List<User> listUsers;
int iCount;

// Good
String name;
List<User> users;
int count;
```

The type is on the declaration; the name carries the meaning.

---

## Getters and Setters

For traditional beans (JPA entities, Jackson DTOs, Spring forms), use
`getX()` / `setX()`:

```java
public class User {
  private String email;

  public String getEmail() { return email; }
  public void setEmail(String email) { this.email = email; }
}
```

For boolean fields: `isActive()` (preferred) or `getActive()` — Jackson and
JPA understand both. Pick one project-wide.

For records and immutable values (Java 14+), accessors are auto-generated
with the field name — no `get` prefix:

```java
public record User(String id, String email) {}

User u = new User("u1", "a@b");
u.email();   // not u.getEmail()
```

Modern code prefers records and accessor-as-field naming over the bean
ceremony.

---

## No Redundant Repetition

Don't repeat the class or package in member names:

```java
// Bad
class UserRepository {
  public User findUserById(UserId userId) { ... }
}

// Good
class UserRepository {
  public User findById(UserId id) { ... }
}
```

`userRepo.findUserById(userId)` is noisier than `userRepo.findById(id)`. The
context already says "user".

---

## Functions: Verbs

| Verb stem | When |
|---|---|
| `get` / `find` | Read (`find` may return Optional) |
| `set` / `update` | Mutate |
| `create` / `new` / `make` | Construct |
| `delete` / `remove` | Destroy |
| `is` / `has` / `can` | Boolean predicate |
| `to` | Convert (`toJson`, `toString`) |
| `from` | Construct from other type (`User.fromRow`) |

Stick to one verb per concept. If "find" returns `Optional<User>` and "get"
throws on missing, maintain that distinction throughout.

---

## Constants

Module-level constants are `UPPER_SNAKE_CASE`, declared `static final`:

```java
private static final int MAX_RETRIES = 3;
private static final Duration DEFAULT_TIMEOUT = Duration.ofSeconds(5);
```

Group related constants in a final class with a private constructor — or, in
modern Java, an enum:

```java
public enum LogLevel { FATAL, ERROR, WARN, INFO, DEBUG, TRACE }
```

Don't use a constants `interface` (deprecated antipattern: implementations
inherit the constants into their public API).

---

## Type Parameters

Single capitals or short names. Use descriptive names when there are
multiple:

```java
public <T> T identity(T value) { return value; }
public <K, V> Map<K, V> asMap(K key, V value) { ... }

public <UserT extends User> UserT loadFresh(UserT stale) { ... }   // more descriptive when needed
```

Don't write `T_co`, `T_in` unless you genuinely need variance markers (rare
in Java).

---

## Exceptions

Subclass an appropriate parent (`RuntimeException`, `Exception`, or an
ancestor); name `XxxException`:

```java
public class NotFoundException extends RuntimeException { ... }
public class ValidationException extends RuntimeException { ... }
public class InvalidConfigException extends RuntimeException { ... }
```

Don't end with `Error` in Java — that's reserved for JVM-level problems
(`OutOfMemoryError`, `StackOverflowError`). The convention is `Exception`.

---

## Packages

Lowercase, no underscores, reverse-domain prefix for libraries:

```
com.acme.app.user
com.acme.app.config
io.example.myapp.http
```

For application code, you can drop the reverse-domain (`myapp.user.repository`)
if the project is internal. Once published, use the reverse-domain to avoid
collisions.

Avoid version numbers in package names (`com.acme.appv2`). Version the
artifact (Maven coordinates), not the package.

---

## Test Classes and Methods

```java
class UserRepositoryTest {

  @Test
  void returnsUserWhenIdExists() { ... }

  @Test
  void throwsNotFoundWhenIdMissing() { ... }
}
```

Test method names are sentences in `camelCase`. They start with the behavior
("returns", "throws", "saves"), not the method name being tested.

For tests with grouped scenarios, use `@Nested` inner classes:

```java
class UserServiceTest {
  @Nested class WhenCreating { ... }
  @Nested class WhenUpdating { ... }
}
```

---

## Acronyms

Treat acronyms as words in the chosen case:

```java
// Good
class HttpClient { ... }
class JsonParser { ... }
String userId;
String httpUrl;

// Bad
class HTTPClient { ... }
class JSONParser { ... }
String userID;
```

Google style is strict: `Url` not `URL`, `Id` not `ID`, `Http` not `HTTP`. A
two-letter acronym at the start can stay capital (`IO`), but consistency
matters more than the edge case.

---

## File Names

A file is `ClassName.java` for the top-level class (must match). One public
type per file; nested types belong inside.

```
src/main/java/com/acme/user/
  User.java
  UserRepository.java
  UserService.java
src/test/java/com/acme/user/
  UserRepositoryTest.java
  UserServiceTest.java
```

---

## Quick Reference

| Question | Default |
|---|---|
| Classes, types | `PascalCase` |
| Methods, fields | `camelCase` |
| Constants | `UPPER_SNAKE_CASE` |
| Packages | `lowercase.dots` |
| Boolean prefix | `is` / `has` / `can` |
| Interface prefix | None (no `I`) |
| Exception suffix | `Exception` (not `Error`) |
| Test class | `<Subject>Test` |

## Related Skills

- **Style core**: [java-style-core](../java-style-core/SKILL.md) for the broader baseline.
- **Packages**: [java-packages](../java-packages/SKILL.md) for package design.
- **Classes**: [java-classes](../java-classes/SKILL.md) for record vs class naming.
- **Generics**: [java-generics](../java-generics/SKILL.md) for type parameter conventions.
- **Testing**: [java-testing](../java-testing/SKILL.md) for test naming.
- **Linting**: [java-linting](../java-linting/SKILL.md) for Checkstyle's naming rules.
