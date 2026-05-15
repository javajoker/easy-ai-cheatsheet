---
name: node-http
description: Use when building HTTP services in Node.js — designing routes, validating request bodies, mapping errors to status codes, streaming responses, applying timeouts and AbortSignal, handling content negotiation, or organizing middleware. Examples target Fastify (preferred) with Express noted. Does not cover REST/OpenAPI contract design itself (that's a project-docs concern).
license: Apache-2.0
compatibility: Fastify 4+ / Node 18+.
metadata:
  sources: "Fastify docs, Express best practices, OWASP API Security Top 10"
---

# Node.js HTTP Services

## Pick One Framework

| Framework | When |
|---|---|
| Fastify | Default for new services. Schema-first, fast, plugin ecosystem. |
| Express | Established codebases. Don't rewrite to Fastify just for fun. |
| Hono | Cross-runtime (workers, Bun) or edge target. |
| Native `node:http` | Vendoring concerns, tiny embedded servers. |

This skill uses Fastify in examples.

---

## Validate at the Edge

Every request body, query, and route param is **untrusted input**. Validate
with a schema at the handler boundary; the inside of the service trusts its
inputs.

```ts
import { FastifyInstance } from 'fastify';
import { z } from 'zod';

const CreateUser = z.object({
  email: z.string().email(),
  name: z.string().min(1).max(100),
});

export async function userRoutes(app: FastifyInstance) {
  app.post('/users', async (req, reply) => {
    const body = CreateUser.parse(req.body);   // throws on invalid
    const user = await userService.create(body);
    return reply.status(201).send(user);
  });
}
```

Fastify natively understands JSON Schema and TypeBox; the validator throws a
shape that the framework turns into a 400.

---

## Status Codes

Pick from the small standard set; don't invent.

| Code | When |
|---|---|
| `200 OK` | Successful GET / PUT / PATCH returning a body |
| `201 Created` | Successful POST returning the new resource |
| `202 Accepted` | Queued for async processing |
| `204 No Content` | Successful DELETE or update with no body |
| `400 Bad Request` | Validation failure |
| `401 Unauthorized` | No / invalid credentials |
| `403 Forbidden` | Authenticated but not allowed |
| `404 Not Found` | Resource doesn't exist |
| `409 Conflict` | Optimistic-lock or duplicate-key |
| `422 Unprocessable Entity` | Semantically invalid input (use 400 if you don't want this distinction) |
| `429 Too Many Requests` | Rate-limited |
| `500 Internal Server Error` | Unexpected failure |
| `502 / 503 / 504` | Upstream / overload / timeout |

Don't return `200` with `{ ok: false, error: '...' }`. Use the HTTP layer.

---

## One Error Translator

Don't sprinkle `reply.status(500)` calls across handlers. Use the framework's
central error handler (see
[node-error-handling](../node-error-handling/SKILL.md)):

```ts
app.setErrorHandler((err, req, reply) => {
  if (err instanceof ValidationError) return reply.status(400).send({ issues: err.issues });
  if (err instanceof NotFoundError)   return reply.status(404).send({ resource: err.resource });
  if (err instanceof ConflictError)   return reply.status(409).send({ message: err.message });

  req.log.error({ err }, 'unhandled');
  return reply.status(500).send({ error: 'internal' });
});
```

---

## Response Bodies Have Stable Shape

Define a canonical error body and a canonical resource body. Stick to them.

```ts
// Error
{ "error": "validation", "issues": [{ "path": "email", "message": "invalid" }] }

// Resource
{ "id": "u_1", "email": "a@b", "createdAt": "2024-01-01T00:00:00Z" }
```

Avoid:

- Returning a bare string body (clients have to parse it).
- Wrapping everything in `{ data: ..., success: true }` if the HTTP status
  already conveys success/failure.
- Inconsistent date formats — pick ISO-8601 strings, return them everywhere.

---

## Request Logging

Use the framework's request logger. Fastify gives you `req.log`, a child of
the root logger bound to the request id. Don't `console.log` requests.

```ts
app.get('/users/:id', async (req, reply) => {
  req.log.info({ userId: req.params.id }, 'getting user');
  const user = await userService.getById(req.params.id);
  return user;
});
```

Tune the framework's default access log to include `userId` (from auth) and
the trace id from OpenTelemetry. See
[node-logging](../node-logging/SKILL.md).

---

## Cancellation: Hook to AbortSignal

Long-running handlers should observe the request's cancellation signal so
they don't keep doing work after the client disconnected.

```ts
app.get('/search', async (req, reply) => {
  const ctrl = new AbortController();
  req.raw.on('close', () => ctrl.abort());

  const results = await search(req.query.q, { signal: ctrl.signal });
  return results;
});
```

Some frameworks expose `req.signal` directly — check the docs. Pass the signal
all the way down to outbound `fetch`, DB queries, and slow CPU loops (see
[node-async](../node-async/SKILL.md)).

---

## Timeouts at Every Hop

| Place | Default |
|---|---|
| Server-side request timeout | 30 s (`server.requestTimeout`) |
| Body read timeout | 10 s |
| Keep-alive idle | 5 s |
| Outbound fetch | 5 s (per call), set explicitly |
| DB query | 5 s (set in pool config) |

Without timeouts, slow upstreams or a stuck client can hang the event loop.

```ts
const app = Fastify({
  requestTimeout: 30_000,
  bodyLimit: 1_048_576,   // 1 MB
});

// Outbound
await fetch(url, { signal: AbortSignal.timeout(5000) });
```

---

## Streaming Responses

For big payloads (file download, server-sent events, NDJSON export), stream
rather than buffer.

```ts
app.get('/export.ndjson', async (req, reply) => {
  reply.header('content-type', 'application/x-ndjson');
  reply.raw.writeHead(200);

  for await (const row of db.query('SELECT * FROM events')) {
    if (!reply.raw.write(JSON.stringify(row) + '\n')) {
      await once(reply.raw, 'drain');
    }
  }
  reply.raw.end();
});
```

See [node-streams](../node-streams/SKILL.md) for backpressure.

---

## CORS, Compression, Helmet

Use battle-tested plugins; don't roll your own.

- **CORS**: `@fastify/cors` / `cors` (Express). Allow-list origins; never echo
  the request `Origin` blindly.
- **Compression**: `@fastify/compress` / `compression`. Negotiate gzip/brotli.
- **Security headers**: `@fastify/helmet` / `helmet`. CSP, X-Frame-Options,
  Referrer-Policy.

See [node-security](../node-security/SKILL.md) for what each header does and
why.

---

## Avoid Synchronous Work in Handlers

CPU-heavy work in a handler blocks the event loop and stalls every other
request. Move it to a worker thread (`worker_threads`) or a queue
(BullMQ / arq). If the work must remain in-process, chunk it with
`await setImmediate(...)` from `node:timers/promises`.

---

## Health and Readiness

Expose two endpoints:

- `/healthz` — process is alive. Returns 200 if Node is responding.
- `/readyz` — service is ready to take traffic. Returns 200 only when DB,
  cache, and any required upstream are reachable.

Kubernetes and most load balancers use the distinction. A passing `/healthz`
on a service whose DB is down should still fail `/readyz`.

---

## Quick Reference

| Question | Default |
|---|---|
| Framework | Fastify |
| Validate where | At the handler, with a schema |
| Status codes | Standard set; HTTP layer carries success/failure |
| Error handling | One central translator |
| Timeouts | Set explicitly at every hop |
| Logging | `req.log`, child of root |
| Big payloads | Stream |
| Health | `/healthz` + `/readyz` separate |

## Related Skills

- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for status-code mapping.
- **Logging**: See [node-logging](../node-logging/SKILL.md) for request-scoped child loggers.
- **Async**: See [node-async](../node-async/SKILL.md) for AbortSignal threading.
- **Streams**: See [node-streams](../node-streams/SKILL.md) for response streaming.
- **Security**: See [node-security](../node-security/SKILL.md) for input validation and headers.
- **Config**: See [node-config](../node-config/SKILL.md) for port, body-limit, and timeout config.
