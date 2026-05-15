---
name: java-logging
description: Use when configuring or using logging in Java — SLF4J as the facade, Logback or Log4j2 as the implementation, structured/JSON log lines, levels, MDC for request context, log injection prevention, and OpenTelemetry integration. Also use when reviewing code that uses `System.out.println` for diagnostics.
license: Apache-2.0
metadata:
  sources: "SLF4J docs, Logback docs, Log4j2 docs, OpenTelemetry semantic conventions"
---

# Java Logging

## No `System.out.println` in Committed Code

`System.out.println` is unconditional, ignores levels, blocks the I/O
thread, and can't be redirected. It's fine in a one-off main; not in a
service.

Use **SLF4J** as the API:

```java
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

private static final Logger log = LoggerFactory.getLogger(MyClass.class);

log.info("user signed in: userId={}", userId);
```

SLF4J is the facade; the binding determines the implementation:

- **Logback** — default in Spring Boot, mature, fast.
- **Log4j2** — feature-rich, async appenders, good for high throughput.

Pick one binding per project. Don't ship both.

---

## Structured Logging via SLF4J Placeholders

SLF4J placeholders (`{}`) defer formatting until the level passes — fast
and safe:

```java
// Bad — string concat happens even if DEBUG is disabled
log.debug("processing user: " + user);   // user.toString() always called

// Bad — string format always called
log.debug("processing user: %s".formatted(user));

// Good — placeholder; formatted only when logged
log.debug("processing user: {}", user);
```

For real structured JSON output, configure Logback with a JSON encoder
(`logstash-logback-encoder`):

```xml
<encoder class="net.logstash.logback.encoder.LogstashEncoder"/>
```

Then add structured fields via `StructuredArguments`:

```java
import static net.logstash.logback.argument.StructuredArguments.kv;

log.info("user signed in {} {}", kv("userId", userId), kv("ip", ip));
```

The output is JSON with `userId` and `ip` as first-class fields,
queryable in Elasticsearch / Loki / etc.

---

## Levels

| Level | When | Audience |
|---|---|---|
| `ERROR` | Operation failed; user impact | On-call |
| `WARN` | Suboptimal but the system continued | Review during business hours |
| `INFO` | Significant lifecycle event (startup, shutdown, request done) | Operations |
| `DEBUG` | Verbose diagnostics, off in production | Developer |
| `TRACE` | Finest-grain | Developer with tracing enabled |

Default to `INFO` in production, `DEBUG` in development. Don't log at
`ERROR` unless someone should look at it.

Configure per-package levels in `logback-spring.xml`:

```xml
<logger name="com.acme.myapp.db" level="WARN"/>
<logger name="com.acme.myapp.user" level="DEBUG"/>
```

---

## MDC for Request Context

`MDC` (Mapped Diagnostic Context) is a thread-local map that the logger
includes in every log line. Use it for request-scoped fields:

```java
import org.slf4j.MDC;

@Override
public Response handle(Request req) {
  MDC.put("requestId", req.id());
  MDC.put("userId", req.user().id());
  try {
    return process(req);
  } finally {
    MDC.clear();
  }
}
```

Every `log.info(...)` inside `process(req)` automatically includes
`requestId` and `userId` in the output.

In Spring, a filter / `OncePerRequestFilter` populates MDC for every
request. Don't reinvent it.

---

## Pass the Exception as the Last Argument

SLF4J recognizes a `Throwable` as the last argument and logs the full
stack trace:

```java
try {
  service.charge(amount);
} catch (Exception ex) {
  log.error("charge failed for user {}", userId, ex);   // logs stack
}
```

```java
// Bad — message string only; stack lost
log.error("charge failed: " + ex.getMessage());

// Bad — uses placeholder for the exception (won't render the stack)
log.error("charge failed: {}", ex);
```

The placeholder for the exception is implicit; just pass it as the last
arg.

---

## Don't Log and Throw

If you both log and throw, downstream code logs again on catch. Pick one:

```java
// Bad
if (!user.isActive()) {
  log.error("inactive user: {}", id);
  throw new InactiveUserException(id);
}

// Good — throw; the boundary logs once
if (!user.isActive()) {
  throw new InactiveUserException(id);
}
```

Exception: at a boundary that swallows the error (HTTP handler converting
to a 4xx), log the detail before converting. See
[java-error-handling](../java-error-handling/SKILL.md).

---

## Redaction

Never log secrets, full tokens, passwords, or PII bodies. The right place
for redaction is a Logback layout filter or, for structured logging, a
processor that scrubs known fields.

```xml
<encoder class="net.logstash.logback.encoder.LogstashEncoder">
  <fieldNames>
    <message>msg</message>
  </fieldNames>
  <maskedFields>password, token, credit_card</maskedFields>
</encoder>
```

Audit the redaction list when new fields enter the schema. Don't try to
regex-mask the entire message — keys are explicit and reviewable.

---

## Sampling for High-Cardinality Logs

Logging every hot-path event at `INFO` is a fast way to blow up your log
bill. Sample:

```java
if (requestId.hashCode() % 10 == 0) {       // 10 % sample
  log.info("hot path event");
}
```

Better: emit a metric for the count and a sampled log line for detail.

---

## Asynchronous Appenders

For high-throughput services, sync logging on the hot path adds latency.
Wrap a file appender in `AsyncAppender`:

```xml
<appender name="ASYNC" class="ch.qos.logback.classic.AsyncAppender">
  <appender-ref ref="FILE"/>
  <queueSize>1024</queueSize>
  <discardingThreshold>0</discardingThreshold>
</appender>
```

In containers, prefer writing to stdout and letting the runtime ship logs.
Asynchronous handling at the application layer is then unnecessary.

---

## OpenTelemetry Integration

When tracing is enabled, inject trace IDs so logs correlate with traces.
`opentelemetry-instrumentation-logback-mdc` populates `traceId` and
`spanId` into MDC automatically.

```xml
<pattern>%X{traceId} %X{spanId} %msg%n</pattern>
```

With JSON output, the fields appear as proper keys.

---

## Don't Log User Input Verbatim in the Message

User-controlled strings in a log message are a vector for log injection
(newline + crafted line that fakes a fresh log entry):

```java
// Bad
log.info("search: " + request.getQuery());     // newline injection

// Good
log.info("search performed", kv("query", request.getQuery()));
```

Structured JSON output escapes this automatically. Plain text appenders
need an explicit `%replace(%msg){'\n','\\n'}` filter.

---

## Logger per Class

```java
public class UserService {
  private static final Logger log = LoggerFactory.getLogger(UserService.class);
}

// Or with Lombok @Slf4j
@Slf4j
public class UserService {
  // log is auto-generated
}
```

`LoggerFactory.getLogger(getClass())` works inside non-static contexts and
picks up subclass identity — useful in base classes. Otherwise prefer the
class literal.

---

## Quick Reference

| Question | Default |
|---|---|
| API | SLF4J |
| Implementation | Logback (default) or Log4j2 |
| Output | JSON (logstash-logback-encoder) |
| Style | `log.info("event {}", kv("field", value))` |
| Per-class | `LoggerFactory.getLogger(...)` |
| Request context | MDC |
| Exception | Last arg of the call |
| Redact | Layout-level masked fields |
| Sample | Hot paths, with metric |
| Avoid | `System.out.println`, log + throw |

## Related Skills

- **Error handling**: [java-error-handling](../java-error-handling/SKILL.md) for logging exceptions correctly.
- **HTTP**: [java-http](../java-http/SKILL.md) for request-filter MDC population.
- **Concurrency**: [java-concurrency](../java-concurrency/SKILL.md) for MDC across thread pools.
- **Security**: [java-security](../java-security/SKILL.md) for what must never appear in logs.
- **Config**: [java-config](../java-config/SKILL.md) for log-level config.
