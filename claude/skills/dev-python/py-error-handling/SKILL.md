---
name: py-error-handling
description: Use when raising, catching, or designing exceptions in Python — choosing exception classes, using `raise from`, narrow vs broad `except`, `ExceptionGroup`/`except*`, returning Result-style values, mapping errors to HTTP responses, or reviewing `try/except` placement. Does not cover process-level signal handling.
license: Apache-2.0
compatibility: Examples use `ExceptionGroup` / `except*` (Python 3.11+).
metadata:
  sources: "Python docs (Exceptions), PEP 654 (ExceptionGroup), Google Python Style Guide"
allowed-tools: Bash(bash:*)
---

# Python Error Handling

## Available Scripts

- **`scripts/check-errors.sh`** — Detects error-handling anti-patterns: bare `except:`, `except: pass` (silent swallow), catch-and-rethrow, log-and-raise, and `raise "string"`. Run `bash scripts/check-errors.sh --help` for options. For deeper coverage, configure Ruff with `--select TRY,B` (see [py-linting](../py-linting/SKILL.md)).

## Use Exceptions for Errors

Python's error story is exceptions. Don't return error sentinels (`-1`,
`None`) where a raised exception would be clearer. Reserve sentinel returns
for genuinely expected absences (`dict.get(key)` returns `None`).

```python
# Bad — caller has to remember to check
def find_user(id) -> User | None:
    row = db.query(...)
    if not row:
        return None
    return User(row)

# Good — explicit, distinguishes "not found" from "lookup failed"
def find_user(id) -> User:
    row = db.query(...)
    if not row:
        raise NotFoundError("user", id)
    return User(row)

# Also good — Optional return when "missing" is normal control flow
def find_user_optional(id) -> User | None:
    row = db.query(...)
    return User(row) if row else None
```

Pick one based on the call site: if the absence is the unhappy path, raise;
if it's a normal case the caller branches on, return `None`.

---

## Subclass the Built-in Hierarchy

Don't catch `Exception` and don't raise bare `Exception`. Subclass the nearest
meaningful base:

| Base | Use for |
|---|---|
| `ValueError` | Invalid input that fails validation |
| `TypeError` | Wrong type provided |
| `KeyError` | Missing key in a mapping |
| `LookupError` | Generic "couldn't find it" |
| `RuntimeError` | Genuine runtime failure with no better fit |
| `OSError` | File/socket/system error (often raised by the stdlib) |

Your custom errors go below:

```python
class AppError(Exception):
    """Base for all app-specific errors."""

class NotFoundError(AppError):
    def __init__(self, resource: str, id: str) -> None:
        super().__init__(f"{resource} not found: {id}")
        self.resource = resource
        self.id = id

class ValidationError(AppError):
    def __init__(self, issues: list[dict]) -> None:
        super().__init__(f"validation failed: {len(issues)} issues")
        self.issues = issues
```

Five-to-ten domain error types per service is plenty. Don't make one per call
site; group by "who handles it differently".

---

## `raise ... from`: Preserve the Chain

When re-raising, chain to the original with `from`:

```python
def load_user(id: str) -> User:
    try:
        return db.users.find_by_id(id)
    except DatabaseError as cause:
        raise AppError(f"load_user({id}) failed") from cause
```

This sets `__cause__`. Tracebacks show both errors with "The above exception
was the direct cause of the following exception". For a non-causal chain
(suppressing the original from the report), use `from None`.

---

## Catch Narrow Exceptions

```python
# Bad — swallows everything including KeyboardInterrupt, SystemExit
try:
    do_thing()
except:
    pass

# Bad — too broad
try:
    do_thing()
except Exception:
    pass

# Good
try:
    do_thing()
except ValueError as err:
    handle(err)
```

Bare `except:` catches `BaseException`, including `KeyboardInterrupt` and
`SystemExit`. Never use it. `except Exception` is the broadest justifiable
catch, and even then only at boundary layers.

---

## Catch Where You Can Handle

If you can't do something useful with the exception, don't catch it. A
`try/except` that just re-raises adds noise.

```python
# Bad
try:
    return db.query(sql)
except DatabaseError:
    raise   # no-op

# Good — let it propagate
return db.query(sql)

# Good — add context
try:
    return db.query(sql)
except DatabaseError as cause:
    raise AppError(f"query failed: {redact(sql)}") from cause
```

---

## HTTP Boundary: One Translator

Centralize HTTP error translation in one exception handler. Don't
sprinkle `return JSONResponse(status_code=400, ...)` across handlers.

```python
# fastapi: register a single handler per error type or one for the base
@app.exception_handler(NotFoundError)
async def not_found_handler(request, err):
    return JSONResponse(status_code=404, content={"resource": err.resource})

@app.exception_handler(ValidationError)
async def validation_handler(request, err):
    return JSONResponse(status_code=400, content={"issues": err.issues})

@app.exception_handler(AppError)
async def app_error_handler(request, err):
    log.error({"err": str(err)}, "app error")
    return JSONResponse(status_code=500, content={"error": "internal"})
```

In production, never leak stack traces or internal messages in responses — log
the detail, return a stable shape. See
[py-http](../py-http/SKILL.md).

---

## `ExceptionGroup` / `except*`

When concurrent tasks fail, you may get multiple exceptions at once. Python
3.11 introduced `ExceptionGroup` (raised by `asyncio.TaskGroup`) and `except*`
syntax for matching across the group.

```python
try:
    async with asyncio.TaskGroup() as tg:
        tg.create_task(fetch_a())
        tg.create_task(fetch_b())
        tg.create_task(fetch_c())
except* ValueError as eg:
    log.warn(f"validation failures: {len(eg.exceptions)}")
except* DatabaseError as eg:
    log.error(f"db failures: {len(eg.exceptions)}")
```

`except*` matches and *splits* the group: each handler sees only the matching
sub-exceptions; the remainder is re-raised.

---

## `else` and `finally`

`else` runs only if no exception was raised:

```python
try:
    user = load(id)
except NotFoundError:
    handle_missing()
else:
    # only reached if load() succeeded
    enrich(user)
```

`finally` always runs:

```python
try:
    f = open(path)
except OSError:
    handle()
finally:
    f.close()
```

Better: use a `with` block for resource cleanup. `finally` is mostly for
edge cases where `with` doesn't fit.

---

## Don't Use Exceptions for Flow Control

```python
# Bad — exception for an expected case
try:
    return cache[key]
except KeyError:
    value = compute(key)
    cache[key] = value
    return value

# Good
if key in cache:
    return cache[key]
value = compute(key)
cache[key] = value
return value

# Also good — uses dict.get with a sentinel
if (value := cache.get(key, MISSING)) is MISSING:
    value = compute(key)
    cache[key] = value
return value
```

`EAFP` ("easier to ask forgiveness than permission") is Pythonic, but throw it
overboard when the exception is hot or the look-before-you-leap is just as
clear. Don't use exceptions where a boolean check is cheaper and obvious.

---

## Result Types?

Some teams adopt a `Result[T, E]` pattern (libraries: `returns`, `result`).
It can read well, especially for chains of validation. The trade-offs:

- Pro: errors become values, easy to compose.
- Con: every layer must unwrap; doesn't compose with the standard library
  (which raises).
- Con: type checkers help, but the boilerplate is real.

In practice, exceptions are idiomatic Python; `Result` is fine in projects
that have committed to it but isn't a default.

---

## Quick Reference

| Question | Default |
|---|---|
| What do I raise? | A subclass of an appropriate built-in / `AppError` |
| Preserve the chain? | `raise X from cause` |
| How wide a catch? | The narrowest you can handle |
| Multiple concurrent errors? | `ExceptionGroup` + `except*` |
| Where to translate to HTTP? | One central handler |
| Use exceptions for control flow? | No |
| Use Result types? | Optional; team choice |

## Related Skills

- **Async**: [py-async](../py-async/SKILL.md) for `TaskGroup` and `ExceptionGroup`.
- **HTTP**: [py-http](../py-http/SKILL.md) for status-code mapping.
- **Logging**: [py-logging](../py-logging/SKILL.md) for `exc_info=True` and structured exception logging.
- **Naming**: [py-naming](../py-naming/SKILL.md) for `*Error` class naming.
- **Testing**: [py-testing](../py-testing/SKILL.md) for `pytest.raises`.
- **Code review**: [py-code-review](../py-code-review/SKILL.md) for the error section of a PR review.
