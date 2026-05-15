---
name: node-error-handling
description: Use when throwing, catching, or designing errors in Node.js/TypeScript — choosing between throw and Result, defining custom Error subclasses, using `cause`, mapping errors at HTTP boundaries, or matching errors with instanceof. Also use when reviewing error-handling code, even if the user didn't ask about error strategy. Does not cover process-level crash handling (see node-security and node-performance for uncaughtException and OOM).
license: Apache-2.0
compatibility: Uses `Error.cause` (Node 16.9+ / ES2022).
metadata:
  sources: "Node.js docs, Joyent error handling guide, MDN Error reference"
allowed-tools: Bash(bash:*)
---

# Node.js Error Handling

## Available Scripts

- **`scripts/check-errors.sh`** — Detects error-handling anti-patterns: throwing non-Errors (strings, plain objects, primitives), empty `catch` blocks, and log-and-throw / log-and-return violations. Run `bash scripts/check-errors.sh --help` for options.

## Choosing an Error Strategy

In Node, errors flow through three layers:

1. **Internal calls** — throw / await rejects; let the caller decide.
2. **Module boundary** — wrap with `new Error(msg, { cause })` to add context
   without losing the original.
3. **System boundary** (HTTP, queue consumer, CLI) — translate to the protocol's
   error shape (HTTP status + JSON body, exit code, dead-letter).

Result-style returns (`{ ok: true, value } | { ok: false, error }`) are a
legitimate alternative when an error is part of normal control flow (validation,
not-found, business-rule failure). Don't apply Result everywhere — it adds
boilerplate without benefit when the error is genuinely exceptional.

---

## Always Throw `Error`

Throwing a plain string, number, or POJO loses the stack trace and breaks
`instanceof` matching. Wrap unknown rejections in `Error` at the boundary.

```ts
// Bad
throw 'invalid input';
throw { code: 'BAD' };

// Good
throw new Error('invalid input');
throw new BadInputError('email', input);
```

When you catch an `unknown` (TypeScript 4.4+), narrow first:

```ts
try { ... } catch (err) {
  if (err instanceof MyError) handle(err);
  else if (err instanceof Error) log.error({ err }, 'unexpected');
  else throw new Error('non-Error thrown', { cause: err });
}
```

---

## Custom Error Subclasses

Subclass `Error` for distinct failure modes that callers may want to match on.
Set `name` so it shows up in stack traces and structured logs.

```ts
export class NotFoundError extends Error {
  override name = 'NotFoundError';
  constructor(public readonly resource: string, public readonly id: string) {
    super(`${resource} not found: ${id}`);
  }
}

export class ValidationError extends Error {
  override name = 'ValidationError';
  constructor(public readonly issues: ReadonlyArray<{ path: string; message: string }>) {
    super(`validation failed: ${issues.length} issues`);
  }
}

// Caller
try {
  await getUser(id);
} catch (err) {
  if (err instanceof NotFoundError) return reply.status(404).send({ id: err.id });
  throw err;
}
```

**Don't** create one error class per call site. Group by *who handles it
differently*. Five-to-ten domain error types per service is plenty.

---

## `Error.cause`: Preserve the Chain

When re-throwing, pass the original via `cause` so the stack trace and original
message are preserved.

```ts
async function loadUser(id: string) {
  try {
    return await db.users.findById(id);
  } catch (cause) {
    throw new Error(`loadUser(${id}) failed`, { cause });
  }
}
```

Node prints the full chain by default. Structured loggers (pino, winston with
the right serializer) flatten `cause` into the JSON output.

---

## Catch What You Can Handle

Catch only at the level that can do something useful with the error. A bare
`try { ... } catch (err) { throw err; }` adds noise.

```ts
// Bad — catch-and-rethrow with no change
try {
  return await db.query(sql);
} catch (err) {
  throw err;
}

// Good — let it propagate
return await db.query(sql);

// Good — catch to add context
try {
  return await db.query(sql);
} catch (cause) {
  throw new Error(`query failed: ${redactSql(sql)}`, { cause });
}

// Good — catch to translate at the boundary
try {
  return await loadUser(id);
} catch (err) {
  if (err instanceof NotFoundError) return reply.status(404).send();
  log.error({ err }, 'unexpected');
  return reply.status(500).send();
}
```

---

## HTTP Boundary: One Error Translator

Centralize HTTP error translation in **one** place per service (Fastify error
handler, Express middleware). Don't sprinkle `res.status(500)` calls.

```ts
// fastify-error-handler.ts
app.setErrorHandler((err, req, reply) => {
  if (err instanceof NotFoundError) {
    return reply.status(404).send({ error: 'not_found', resource: err.resource });
  }
  if (err instanceof ValidationError) {
    return reply.status(400).send({ error: 'validation', issues: err.issues });
  }
  req.log.error({ err }, 'unhandled');
  return reply.status(500).send({ error: 'internal' });
});
```

Don't leak internal messages or stack traces in production responses. Log the
detail; return a stable, machine-friendly shape.

---

## Process-Level Handlers

Install handlers at startup. Their job is to **log and exit cleanly**, not to
keep the process limping along.

```ts
process.on('uncaughtException', (err, origin) => {
  log.fatal({ err, origin }, 'uncaught');
  // flush logs, then exit
  setTimeout(() => process.exit(1), 100).unref();
});

process.on('unhandledRejection', (reason) => {
  log.fatal({ err: reason }, 'unhandled rejection');
  setTimeout(() => process.exit(1), 100).unref();
});
```

These should be *rare*. If you see `unhandledRejection` in production logs, fix
the missing `await` rather than expand the handler's tolerance.

---

## Don't Use `try` to Detect — Use a Predicate

```ts
// Bad — try/catch as control flow
let json;
try { json = JSON.parse(input); } catch { json = null; }

// Good — schema parser with explicit result
const parsed = schema.safeParse(input);
if (!parsed.success) { ... }
```

Exception: `JSON.parse` has no try-free alternative in the std lib. When you
must, wrap it in a single helper.

---

## Don't Catch `Promise.all` Silently

`Promise.all` rejects on the first failure and aborts no other in-flight work.
If you need all attempts to complete, use `Promise.allSettled`. If you swallow
the rejection with `.catch(() => null)`, mark it clearly:

```ts
// Bad — silent
const results = await Promise.all(items.map((x) => process(x).catch(() => null)));

// Good — explicit collection
const settled = await Promise.allSettled(items.map((x) => process(x)));
const failures = settled.filter((s) => s.status === 'rejected');
if (failures.length > 0) log.warn({ count: failures.length }, 'partial failure');
```

---

## Quick Reference

| Question | Default |
|---|---|
| What do I throw? | A subclass of `Error` |
| How do I preserve the original? | `new Error(msg, { cause })` |
| How do I match? | `instanceof` on a known subclass |
| Where do I translate to HTTP? | One central error handler |
| Should I retry? | Only at the boundary; with backoff; bounded |
| What if a string is thrown by a dep? | Wrap in `Error` at the catch site |

> **Validation**: After implementing error handling, run `bash scripts/check-errors.sh` to detect common anti-patterns. Then run `npx eslint .` to catch additional issues like missing `await`.

## Related Skills

- **Async**: See [node-async](../node-async/SKILL.md) for promise rejection semantics and `Promise.allSettled`.
- **HTTP**: See [node-http](../node-http/SKILL.md) for status-code mapping and request-scoped errors.
- **Logging**: See [node-logging](../node-logging/SKILL.md) for serializing `Error` and `cause`.
- **Testing**: See [node-testing](../node-testing/SKILL.md) for asserting thrown errors and rejected promises.
- **Naming**: See [node-naming](../node-naming/SKILL.md) for `*Error` class naming conventions.
- **Code review**: See [node-code-review](../node-code-review/SKILL.md) for error-handling review checklist.
