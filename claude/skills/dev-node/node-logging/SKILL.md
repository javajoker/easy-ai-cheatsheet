---
name: node-logging
description: Use when adding, reviewing, or configuring logging in Node.js — choosing pino vs winston vs console, designing structured log lines, attaching request context, picking levels, redacting secrets, or integrating with OpenTelemetry. Also use when a code review surfaces `console.log` in committed code.
license: Apache-2.0
metadata:
  sources: "Pino docs, Winston docs, OpenTelemetry semantic conventions"
---

# Node.js Logging

## No `console.log` in Committed Code

`console.log` writes to stdout synchronously, blocks the event loop on flush,
ignores log levels, can't be redirected, and lacks structure. It's fine in a
one-off script. It is not fine in a service.

Use a **structured logger** — `pino` is the default for performance and JSON
output; `winston` is fine if the project already uses it.

```ts
import pino from 'pino';

export const log = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  redact: ['req.headers.authorization', 'password', '*.token'],
});
```

---

## Log Lines Are Structured

A log line is a JSON object, not a string. The message field describes the
event; structured fields carry the data.

```ts
// Bad
log.info(`user ${userId} logged in from ${ip} after ${latencyMs}ms`);

// Good
log.info({ userId, ip, latencyMs }, 'user logged in');
```

Why: structured fields are indexable, queryable, and survive truncation. A
string `"user u_123 logged in from 1.2.3.4 after 47ms"` requires a regex to
extract.

---

## Levels

Use the standard hierarchy. Each level answers a different question.

| Level | When | Audience |
|---|---|---|
| `fatal` | Service can't continue; exiting | On-call |
| `error` | Operation failed; user impact | On-call |
| `warn` | Suboptimal but the system continued | Review during business hours |
| `info` | Significant lifecycle event (startup, shutdown, request done) | Operations |
| `debug` | Verbose diagnostics, off in production | Developer |
| `trace` | Finest-grain, hot-path detail | Developer with tracing on |

Default to `info` in production, `debug` in development. Don't log at `error`
unless someone should look.

---

## Child Loggers for Context

Attach durable context with a child logger, not by repeating fields on every
call site.

```ts
const requestLog = log.child({ requestId: req.id, route: req.url });
requestLog.info('handling');
// ... downstream code uses requestLog
requestLog.info({ statusCode: 200, latencyMs }, 'handled');
```

In Fastify, `req.log` is a child logger bound to that request. In other
frameworks, AsyncLocalStorage is the standard way to thread the logger through
async boundaries without passing it explicitly.

---

## Errors: Pass the Error Object

Loggers know how to serialize `Error` (and `cause` chain). Pass the error
itself, not just its message:

```ts
// Bad
log.error('login failed: ' + err.message);

// Good
log.error({ err, userId }, 'login failed');
```

Pino's default error serializer captures `name`, `message`, `stack`, and walks
the `cause` chain. For Winston, configure `format.errors({ stack: true })`.

---

## Redaction

Never log secrets, credentials, full Authorization headers, or full bodies that
may contain PII. Configure redaction once, declaratively:

```ts
const log = pino({
  redact: {
    paths: [
      'req.headers.authorization',
      'req.headers.cookie',
      'password',
      'token',
      '*.creditCard',
    ],
    censor: '[REDACTED]',
  },
});
```

Audit the redaction list when new fields enter the schema. A regex-based
redactor is a tripwire — paths are explicit and reviewable.

---

## Don't Log Then Throw

If you both log and throw on the same condition, downstream code logs *again*
when it catches. Either log (and handle), or throw (and let the boundary log
once).

```ts
// Bad
if (!user) {
  log.error({ id }, 'user not found');
  throw new NotFoundError('user', id);
}

// Good — throw; the boundary logs
if (!user) throw new NotFoundError('user', id);
```

The exception is when the error will be swallowed (e.g. middleware catches
and converts to a 4xx). Then log the detail before converting.

---

## Sampling for High-Cardinality Logs

Logging every hot-path event at `info` is a fast way to blow up your log bill
and slow the service. Sample:

```ts
if (req.id.endsWith('0')) requestLog.info('handled');   // 10 % sample
```

Better: emit a metric for the count and a sampled log line for the detail.

---

## Asynchronous Flushing on Exit

Pino in async mode buffers writes. Before exiting, flush:

```ts
const log = pino({ /* ... */ }, pino.destination({ sync: false }));

process.on('SIGTERM', async () => {
  await new Promise<void>((res) => log.flush(res));
  process.exit(0);
});
```

For `process.exit(1)` from an uncaught exception handler, give the destination
a tick to drain (`setTimeout(... 100).unref()`).

---

## OpenTelemetry Integration

When the project has tracing, inject `trace_id` and `span_id` into every log
line so logs correlate with traces. The OpenTelemetry log API and pino's
`pino-opentelemetry-transport` do this automatically.

```ts
import { context, trace } from '@opentelemetry/api';

const span = trace.getSpan(context.active());
log.info({ traceId: span?.spanContext().traceId }, 'event');
```

---

## Don't Log User Input Verbatim

Logging user-controlled strings is a vector for log injection (e.g. a
newline-laden query that fakes a fresh log line). Most structured loggers
escape this automatically, but never concatenate user input into the *message
string*:

```ts
// Bad — log injection
log.info('search: ' + req.query.q);

// Good
log.info({ query: req.query.q }, 'search');
```

---

## Quick Reference

| Question | Default |
|---|---|
| Library | pino (perf) or winston (established) |
| Style | Structured JSON |
| Pattern | `log.info({ fields }, 'message')` |
| Request context | Child logger / AsyncLocalStorage |
| Error | Pass the Error object |
| Redact | Declarative path list |
| Sample | Hot paths, with metric for count |
| Exit | Flush before exit |

## Related Skills

- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for `Error.cause` and one-log boundary discipline.
- **HTTP**: See [node-http](../node-http/SKILL.md) for request-scoped child loggers.
- **Security**: See [node-security](../node-security/SKILL.md) for what must never appear in logs.
- **Config**: See [node-config](../node-config/SKILL.md) for `LOG_LEVEL` env wiring.
- **Performance**: See [node-performance](../node-performance/SKILL.md) for async-logging trade-offs.
