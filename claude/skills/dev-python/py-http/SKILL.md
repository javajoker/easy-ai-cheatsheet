---
name: py-http
description: Use when building HTTP services in Python — designing routes, validating request bodies, mapping errors to status codes, applying timeouts and cancellation, streaming responses, organizing dependencies/middleware. Examples target FastAPI (preferred); notes for Flask, Starlette, Django REST. Does not cover REST/OpenAPI contract design.
license: Apache-2.0
compatibility: FastAPI 0.110+ / Python 3.11+ for the async examples.
metadata:
  sources: "FastAPI docs, Starlette docs, OWASP API Security Top 10"
---

# Python HTTP Services

## Pick One Framework

| Framework | When |
|---|---|
| FastAPI | Default for new services. Pydantic-native, async-first, generates OpenAPI. |
| Starlette | When you want FastAPI's foundations without the magic. |
| Flask | Established sync services. Don't rewrite to async just for fun. |
| Django REST Framework | When the project is already a Django app. |
| Litestar | Newer FastAPI alternative; pick if the team prefers it. |

This skill uses FastAPI in examples.

---

## Validate at the Edge

Every request body, query, and path param is untrusted. Validate with a
Pydantic model at the boundary; the inside of the service trusts its inputs.

```python
from fastapi import FastAPI, status
from pydantic import BaseModel, EmailStr

app = FastAPI()

class CreateUser(BaseModel):
    email: EmailStr
    name: str = Field(min_length=1, max_length=100)

@app.post("/users", status_code=status.HTTP_201_CREATED)
async def create_user(payload: CreateUser) -> UserOut:
    user = await user_service.create(payload)
    return UserOut.model_validate(user)
```

Pydantic raises `ValidationError`; FastAPI translates it to a 422 response
shape. Schemas appear in the generated OpenAPI for free.

---

## Status Codes

Use the standard set; don't invent.

| Code | When |
|---|---|
| 200 OK | Successful GET / PUT / PATCH with body |
| 201 Created | Successful POST returning new resource |
| 202 Accepted | Queued for async processing |
| 204 No Content | Successful DELETE or update with no body |
| 400 Bad Request | Validation failure |
| 401 Unauthorized | No / invalid credentials |
| 403 Forbidden | Authenticated but not allowed |
| 404 Not Found | Resource doesn't exist |
| 409 Conflict | Duplicate-key, optimistic-lock |
| 422 Unprocessable Entity | Semantically invalid input (FastAPI default for validation) |
| 429 Too Many Requests | Rate-limited |
| 500 Internal Server Error | Unexpected failure |
| 502 / 503 / 504 | Upstream / overload / timeout |

Don't return 200 with `{"ok": false, "error": "..."}`. Use the HTTP layer.

---

## One Error Translator

Don't sprinkle `JSONResponse(status_code=500, ...)` across handlers. Use
FastAPI exception handlers:

```python
@app.exception_handler(NotFoundError)
async def not_found(request, err):
    return JSONResponse(404, {"resource": err.resource, "id": err.id})

@app.exception_handler(ValidationError)
async def validation(request, err):
    return JSONResponse(400, {"issues": err.issues})

@app.exception_handler(Exception)
async def unhandled(request, err):
    log.exception("unhandled")
    return JSONResponse(500, {"error": "internal"})
```

In production, never return stack traces or internal messages. Log the
detail; return a stable shape.

---

## Response Bodies Have Stable Shape

Define canonical error and resource shapes; stick to them.

```python
# Error
{"error": "validation", "issues": [{"loc": ["body", "email"], "msg": "invalid"}]}

# Resource
{"id": "u_1", "email": "a@b", "created_at": "2024-01-01T00:00:00Z"}
```

Avoid:

- Bare string body (clients have to parse).
- Wrapping every successful response in `{"data": ..., "success": true}` —
  the HTTP status carries success.
- Inconsistent date formats — ISO 8601 strings everywhere.

---

## Dependencies for Cross-Cutting

FastAPI's `Depends` is the dependency-injection mechanism. Use it for auth,
DB sessions, logging context — anything that wraps the handler.

```python
async def get_current_user(token: str = Depends(oauth2_scheme)) -> User:
    user = await auth.verify(token)
    if not user:
        raise HTTPException(401)
    return user

@app.get("/me")
async def me(user: User = Depends(get_current_user)) -> UserOut:
    return UserOut.model_validate(user)
```

A dependency that yields acts as setup/teardown:

```python
async def get_db():
    async with database.session() as session:
        yield session

@app.get("/users/{id}")
async def get_user(id: str, db = Depends(get_db)) -> UserOut:
    ...
```

---

## Async Where It Helps

FastAPI runs sync handlers in a threadpool and async handlers on the event
loop. Use `async def` when the handler awaits I/O. Use `def` for handlers
that are CPU-bound or call sync libraries — they get a thread.

Mixing both is fine. Don't `await` a sync call; either make the call async
or push it to a thread:

```python
@app.post("/render")
async def render_pdf(payload: RenderRequest):
    pdf_bytes = await asyncio.to_thread(generate_pdf_sync, payload)
    return Response(content=pdf_bytes, media_type="application/pdf")
```

---

## Cancellation: Hook to the Request

FastAPI exposes `request.is_disconnected()`; check it in long-running
handlers. Or pass an `asyncio.timeout` for hard limits:

```python
@app.get("/search")
async def search(q: str, request: Request):
    async with asyncio.timeout(5):
        results = await search_service.run(q)
    return results
```

For very long operations, prefer background processing (Celery, arq) and
return a job id immediately.

---

## Timeouts at Every Hop

| Place | Default |
|---|---|
| Server-side request | 30 s (set in the server/proxy) |
| Outbound `httpx` | 5 s |
| DB query | 5 s (pool config) |
| External SDK | Set explicitly; SDKs often have no default |

Without timeouts, a stuck upstream can hang the loop.

```python
async with httpx.AsyncClient(timeout=5.0) as client:
    response = await client.get(url)
```

---

## Streaming Responses

For big payloads (downloads, NDJSON exports, server-sent events), stream
rather than buffer:

```python
from fastapi.responses import StreamingResponse

async def stream_events():
    async for row in db.stream("SELECT * FROM events"):
        yield (json.dumps(row) + "\n").encode()

@app.get("/export.ndjson")
async def export():
    return StreamingResponse(stream_events(), media_type="application/x-ndjson")
```

For SSE, set `media_type="text/event-stream"` and format the lines
appropriately.

---

## CORS, Compression, Security Headers

Use battle-tested middleware:

```python
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_methods=["GET", "POST"],
)
app.add_middleware(GZipMiddleware)
```

Security headers (HSTS, CSP, X-Frame-Options) are usually set at the reverse
proxy (nginx, Caddy, Envoy). If running directly, use `secure` or
`fastapi-secure-headers`.

---

## Rate Limiting

```python
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter

@app.get("/")
@limiter.limit("60/minute")
async def root(request: Request): ...
```

Apply per-IP for anonymous endpoints, per-user for authenticated. See
[py-security](../py-security/SKILL.md).

---

## Health and Readiness

```python
@app.get("/healthz")
async def healthz():
    return {"status": "ok"}

@app.get("/readyz")
async def readyz():
    if not await db.ping(): raise HTTPException(503)
    return {"status": "ready"}
```

Kubernetes / load balancers use the distinction. A passing `/healthz` on a
service whose DB is down should still fail `/readyz`.

---

## Quick Reference

| Question | Default |
|---|---|
| Framework | FastAPI |
| Validate where | At the handler, with Pydantic |
| Status codes | Standard set |
| Error handling | One central translator |
| Async or sync handler | `async def` for awaited I/O; `def` for sync libs |
| Timeouts | Explicit at every hop |
| Big payloads | `StreamingResponse` |
| Health | `/healthz` + `/readyz` separate |

## Related Skills

- **Error handling**: [py-error-handling](../py-error-handling/SKILL.md) for status-code mapping.
- **Logging**: [py-logging](../py-logging/SKILL.md) for request-scoped context.
- **Async**: [py-async](../py-async/SKILL.md) for cancellation and concurrency.
- **Typing**: [py-typing](../py-typing/SKILL.md) for Pydantic models.
- **Security**: [py-security](../py-security/SKILL.md) for input validation, headers, rate limit.
- **Config**: [py-config](../py-config/SKILL.md) for port, timeouts, CORS origins.
