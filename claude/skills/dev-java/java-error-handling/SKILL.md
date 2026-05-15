---
name: java-error-handling
description: Use when throwing, catching, or designing exceptions in Java — choosing checked vs runtime exceptions, custom exception classes, `try-with-resources`, exception chaining with `getCause()`, mapping to HTTP responses, or reviewing `try/catch` blocks. Also use when refactoring `throws` cascades or replacing exception-as-control-flow.
license: Apache-2.0
metadata:
  sources: "Effective Java (Items 69-77), Joshua Bloch on exception design, OWASP error handling guidance"
allowed-tools: Bash(bash:*)
---

# Java Error Handling

## Available Scripts

- **`scripts/check-errors.sh`** — Detects error-handling anti-patterns: `catch (Throwable)`, empty catch blocks, catch-and-rethrow, String identity comparison with `== / !=`, and `InterruptedException` swallowed without re-interrupt. Run `bash scripts/check-errors.sh --help` for options. For deeper coverage, configure ErrorProne and SpotBugs (see [java-linting](../java-linting/SKILL.md)).

## Checked vs Runtime: Default to Runtime

Java's checked exceptions sound great in theory and hurt in practice:

- They infect every call site up the stack.
- Most callers can't do anything useful with them and rethrow.
- Functional interfaces (`Function`, `Supplier`) don't declare `throws`.

**Default to `RuntimeException` subclasses.** Use checked exceptions only
when:

- The error is recoverable by the immediate caller.
- The caller would naturally write recovery code.
- The stdlib forces it (`IOException` from `Files.readString`).

```java
// Good — runtime, lets callers ignore unless they care
public class NotFoundException extends RuntimeException {
  public NotFoundException(String resource, String id) {
    super("%s not found: %s".formatted(resource, id));
  }
}
```

If the project disagrees and prefers checked, follow that — but most modern
Java projects (Spring, most libraries) lean runtime.

---

## Subclass Meaningfully

Five-to-ten domain exceptions per service is plenty. Group by "who handles
it differently":

```java
public class AppException extends RuntimeException {
  public AppException(String message) { super(message); }
  public AppException(String message, Throwable cause) { super(message, cause); }
}

public class NotFoundException extends AppException {
  private final String resource;
  private final String id;

  public NotFoundException(String resource, String id) {
    super("%s not found: %s".formatted(resource, id));
    this.resource = resource;
    this.id = id;
  }
  public String resource() { return resource; }
  public String id() { return id; }
}

public class ValidationException extends AppException {
  private final List<Issue> issues;
  public ValidationException(List<Issue> issues) {
    super("validation failed: %d issues".formatted(issues.size()));
    this.issues = List.copyOf(issues);
  }
  public List<Issue> issues() { return issues; }
}
```

Suffix is `Exception` (not `Error` — `Error` is reserved for JVM-level
issues like `OutOfMemoryError`).

---

## Always Include the Cause

When re-throwing, pass the original via `getCause()`:

```java
try {
  return db.query(sql);
} catch (SQLException cause) {
  throw new AppException("query failed: " + redact(sql), cause);
}
```

The two-arg `Throwable(String, Throwable)` constructor sets the cause.
Stack traces show the full chain.

---

## Catch What You Handle

If you can't do something useful with the exception, don't catch it:

```java
// Bad — catch-and-rethrow with no change
try {
  return db.query(sql);
} catch (SQLException e) {
  throw e;   // do nothing
}

// Good — let it propagate
return db.query(sql);

// Good — add context
try {
  return db.query(sql);
} catch (SQLException cause) {
  throw new AppException("query failed", cause);
}
```

`catch (Exception)` is the broadest justifiable catch and only at boundary
layers. `catch (Throwable)` catches `Error` too — almost always wrong.

---

## `try-with-resources`

For any `AutoCloseable` (streams, JDBC, sockets, lock-wrapped resources),
use `try-with-resources`:

```java
// Bad
InputStream in = null;
try {
  in = Files.newInputStream(path);
  process(in);
} finally {
  if (in != null) in.close();
}

// Good
try (var in = Files.newInputStream(path)) {
  process(in);
}
```

Multiple resources, comma-separated, close in reverse order:

```java
try (var in = Files.newInputStream(input);
     var out = Files.newOutputStream(output)) {
  in.transferTo(out);
}
```

If the body throws and the close also throws, the close exception is
attached as a `Throwable.getSuppressed()`.

---

## HTTP Boundary: One Error Translator

Centralize HTTP error translation in one place. In Spring, use
`@ControllerAdvice`:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

  @ExceptionHandler(NotFoundException.class)
  public ResponseEntity<ErrorBody> notFound(NotFoundException ex) {
    return ResponseEntity.status(404).body(new ErrorBody(
        "not_found", ex.resource(), ex.id()));
  }

  @ExceptionHandler(ValidationException.class)
  public ResponseEntity<ErrorBody> validation(ValidationException ex) {
    return ResponseEntity.badRequest().body(new ErrorBody(
        "validation", null, ex.issues()));
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorBody> unhandled(Exception ex) {
    log.error("unhandled", ex);
    return ResponseEntity.status(500).body(new ErrorBody("internal"));
  }
}
```

In production, never leak stack traces or internal messages in responses.
Log the detail; return a stable shape.

---

## Don't Use Exceptions for Control Flow

```java
// Bad — expected case modeled as exception
try {
  return cache.get(key);
} catch (KeyNotFoundException e) {
  V value = compute(key);
  cache.put(key, value);
  return value;
}

// Good — check
V cached = cache.get(key);
if (cached != null) return cached;
V value = compute(key);
cache.put(key, value);
return value;

// Good — return Optional
return cache.find(key).orElseGet(() -> {
  V value = compute(key);
  cache.put(key, value);
  return value;
});
```

Exceptions are slow (stack trace capture) and surprising (callers don't
expect them for normal cases).

---

## `finally` Pitfalls

`return` or `throw` inside `finally` overrides the original return /
exception — almost never what you want:

```java
// Bad — returning from finally swallows any exception
try {
  return compute();
} finally {
  return -1;   // overrides compute()'s return AND any exception
}
```

Use `finally` for cleanup only. For the cleanup case, `try-with-resources`
is almost always cleaner.

---

## Don't Catch `NullPointerException`

`NullPointerException` indicates a bug, not a runtime condition. Catching
it papers over the underlying problem.

```java
// Bad
try {
  return user.getEmail().toLowerCase();
} catch (NullPointerException e) {
  return "";
}

// Good
if (user == null || user.getEmail() == null) return "";
return user.getEmail().toLowerCase();

// Better — Optional
return Optional.ofNullable(user)
    .map(User::getEmail)
    .map(String::toLowerCase)
    .orElse("");
```

Use `@Nullable` annotations and `Objects.requireNonNull(x, "x")` to fail
fast on illegal nulls at the boundary.

---

## `Optional` for Possibly-Absent

For methods where missing is a *normal* result, return `Optional<T>`:

```java
public Optional<User> findByEmail(String email) {
  User u = repo.findByEmail(email);
  return Optional.ofNullable(u);
}

// Caller chooses
findByEmail(email).orElseThrow(() -> new NotFoundException("user", email));
```

Don't combine: `Optional<X>` *and* throwing on missing in the same method.
Pick one.

---

## Logging Exceptions

```java
// Bad — string concat loses the stack trace
log.error("failed: " + ex.getMessage());

// Good — pass the exception as the last argument (SLF4J)
log.error("operation failed for user {}", userId, ex);
```

The SLF4J `logger.error(String, Object...)` overload treats the last arg as
the exception if it's a `Throwable`, logging the full stack.

See [java-logging](../java-logging/SKILL.md).

---

## Don't Swallow `InterruptedException`

`InterruptedException` is the JVM asking the thread to stop. Don't catch
and ignore:

```java
// Bad
try {
  Thread.sleep(1000);
} catch (InterruptedException e) {
  // ignored
}

// Good — restore the interrupt flag
try {
  Thread.sleep(1000);
} catch (InterruptedException e) {
  Thread.currentThread().interrupt();
  return;   // or propagate
}
```

See [java-concurrency](../java-concurrency/SKILL.md).

---

## Quick Reference

| Question | Default |
|---|---|
| Checked or runtime? | Runtime |
| Throw what? | Subclass of `RuntimeException` |
| Preserve original? | Constructor with `Throwable cause` |
| Catch width | Narrowest you can handle |
| Resource cleanup | `try-with-resources` |
| HTTP translate | One `@ControllerAdvice` |
| Use for control flow? | No |
| Catch NPE? | No — fix the bug |
| Catch Interrupted? | Catch + `Thread.interrupt()` |

## Related Skills

- **Types**: [java-types](../java-types/SKILL.md) for `Optional`.
- **HTTP**: [java-http](../java-http/SKILL.md) for status-code mapping.
- **Logging**: [java-logging](../java-logging/SKILL.md) for logging exceptions.
- **Concurrency**: [java-concurrency](../java-concurrency/SKILL.md) for `InterruptedException`.
- **Testing**: [java-testing](../java-testing/SKILL.md) for asserting thrown exceptions.
- **Naming**: [java-naming](../java-naming/SKILL.md) for `*Exception` naming.
