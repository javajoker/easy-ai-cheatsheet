---
name: py-logging
description: Use when configuring or using logging in Python — the stdlib `logging` module, structlog, structured/JSON log lines, levels, handlers, formatters, log injection prevention, or integrating OpenTelemetry. Also use when reviewing code that uses `print` for diagnostics, or when log noise is overwhelming useful signal.
license: Apache-2.0
metadata:
  sources: "Python logging docs, structlog docs, PEP 282, OpenTelemetry semantic conventions"
---

# Python Logging

## No `print` in Committed Code

`print` writes to stdout unconditionally, blocks the process, ignores levels,
and can't be redirected. It's fine in a one-off script. It is not fine in a
service.

Use `logging` or `structlog`:

```python
import logging
log = logging.getLogger(__name__)

log.info("user signed in", extra={"user_id": user.id})
```

```python
# structlog
import structlog
log = structlog.get_logger()

log.info("user signed in", user_id=user.id)
```

`structlog` is the recommended choice for new projects — keyword arguments
are first-class log fields, output is JSON by default, configuration is
explicit. The stdlib `logging` works but its API for structured fields
(`extra=`) is awkward.

---

## Configure Once at Startup

Configure logging exactly once, in the application entry point. Modules use
`logging.getLogger(__name__)` and *don't* configure anything themselves.

```python
# myapp/logging_config.py
import logging
import structlog

def configure(level: str = "INFO") -> None:
    logging.basicConfig(
        format="%(message)s",
        level=level,
    )
    structlog.configure(
        processors=[
            structlog.contextvars.merge_contextvars,
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.JSONRenderer(),
        ],
        wrapper_class=structlog.make_filtering_bound_logger(
            logging.getLevelNamesMapping()[level],
        ),
    )
```

```python
# myapp/__main__.py
configure(level=settings.log_level)
log = structlog.get_logger()
log.info("starting", port=settings.port)
```

---

## Log Lines Are Structured

A log line is JSON with named fields, not a sentence with embedded values.

```python
# Bad
log.info(f"user {user_id} logged in from {ip} after {latency_ms}ms")

# Good
log.info("user logged in", user_id=user_id, ip=ip, latency_ms=latency_ms)
```

Structured fields are queryable. A string `"user u_123 logged in from
1.2.3.4 after 47ms"` requires regex to extract.

---

## Levels

| Level | When | Audience |
|---|---|---|
| `CRITICAL` | Service can't continue; exiting | On-call |
| `ERROR` | Operation failed; user impact | On-call |
| `WARNING` | Suboptimal but the system continued | Review during business hours |
| `INFO` | Significant lifecycle event | Operations |
| `DEBUG` | Verbose diagnostics, off in production | Developer |

Default to `INFO` in production, `DEBUG` in development. Don't log at
`ERROR` unless someone should look.

---

## Bind Request Context

For request-scoped fields (request id, user id), bind once and let downstream
logs inherit:

```python
# structlog with contextvars
import structlog
from structlog.contextvars import bind_contextvars, clear_contextvars

async def handler(request):
    bind_contextvars(request_id=request.id, user_id=request.user.id)
    try:
        return await process(request)
    finally:
        clear_contextvars()
```

Now every `log.info(...)` inside `process` includes `request_id` and
`user_id` automatically.

For stdlib `logging`, use a `Filter` that injects from `contextvars`. The
plumbing is more involved; this is one reason `structlog` is recommended.

---

## Log the Exception

When catching, log with `exc_info=True` (stdlib) or pass the exception
directly (structlog) so the stack trace and chained causes appear.

```python
# stdlib
try:
    do_thing()
except Exception as err:
    log.error("operation failed", extra={"user_id": user_id}, exc_info=err)

# structlog
try:
    do_thing()
except Exception:
    log.exception("operation failed", user_id=user_id)
```

`log.exception(...)` is shorthand for `log.error(..., exc_info=True)`.

---

## Redaction

Never log secrets, API keys, credit cards, full Authorization headers, full
bodies that may contain PII. Configure redaction in the processor pipeline:

```python
SECRET_FIELDS = {"password", "token", "authorization", "credit_card"}

def redact_secrets(_, __, event_dict):
    for key in list(event_dict.keys()):
        if key.lower() in SECRET_FIELDS:
            event_dict[key] = "[REDACTED]"
    return event_dict

structlog.configure(
    processors=[
        redact_secrets,
        # ... other processors
        structlog.processors.JSONRenderer(),
    ],
)
```

Audit the redaction list when new fields enter the schema.

---

## Don't Log and Raise

If you both log and raise on the same condition, downstream code logs
*again* on catch.

```python
# Bad
if not user:
    log.error("user not found", id=id)
    raise NotFoundError("user", id)

# Good — raise; the boundary logs
if not user:
    raise NotFoundError("user", id)
```

Exception: at a boundary that swallows the error (HTTP handler that
converts to 4xx), log the detail before converting.

---

## Logger Per Module

```python
# myapp/user/service.py
import logging
log = logging.getLogger(__name__)
```

`__name__` produces a hierarchical logger name (`myapp.user.service`). The
hierarchy lets you adjust verbosity per package: silence `myapp.db` to
`WARNING` while keeping `myapp.user` at `DEBUG`.

```python
logging.getLogger("myapp.db").setLevel(logging.WARNING)
```

---

## Avoid `%`-Formatting Performance Trap

In stdlib logging, pass formatting arguments separately so they're not
evaluated when the level is filtered out:

```python
# Bad — string formatted even when debug is disabled
log.debug(f"processing item {expensive_repr(item)}")

# Good — only formatted if level passes
log.debug("processing item %s", item)
```

`structlog` evaluates eagerly because its processors need the values; the
performance trade-off is the price of typed fields.

---

## Log Injection

User-controlled strings in a log *message* are a vector for log injection (a
newline + crafted line that fakes a fresh log entry). Structured loggers
escape this in the JSON output, but never concatenate user input into the
message:

```python
# Bad
log.info(f"search: {req.query.q}")

# Good
log.info("search", query=req.query.q)
```

---

## Asynchronous Logging

In high-throughput services, sync logging on the hot path adds latency. Two
options:

1. **Async handler**: `logging.handlers.QueueHandler` writes to an in-process
   queue; a separate thread reads and writes to disk/stdout.
2. **stdout + log aggregator**: write to stdout, let the container runtime
   ship to the log system. No application-level async needed.

Option 2 is the cleanest in containerized environments. Don't reinvent log
shipping.

---

## OpenTelemetry Integration

When tracing is enabled, inject trace IDs so logs correlate with traces.
`opentelemetry-instrumentation-logging` does this automatically; or do it
explicitly with a structlog processor:

```python
from opentelemetry import trace

def add_trace_context(_, __, event_dict):
    span = trace.get_current_span()
    ctx = span.get_span_context() if span else None
    if ctx and ctx.is_valid:
        event_dict["trace_id"] = f"{ctx.trace_id:032x}"
        event_dict["span_id"] = f"{ctx.span_id:016x}"
    return event_dict
```

---

## Quick Reference

| Question | Default |
|---|---|
| Library | structlog (new) or `logging` (established) |
| Style | Structured JSON |
| Pattern | `log.info("event", field=value)` |
| Per-module | `getLogger(__name__)` |
| Request context | `contextvars` + `bind_contextvars` |
| Exception | `log.exception(...)` |
| Redact | Processor + path list |
| Config location | One module, called at startup |

## Related Skills

- **Error handling**: [py-error-handling](../py-error-handling/SKILL.md) for `exc_info` and one-log boundary discipline.
- **HTTP**: [py-http](../py-http/SKILL.md) for request-scoped logger binding.
- **Async**: [py-async](../py-async/SKILL.md) for `contextvars` across `await`.
- **Security**: [py-security](../py-security/SKILL.md) for what must never appear in logs.
- **Config**: [py-config](../py-config/SKILL.md) for `LOG_LEVEL` env wiring.
