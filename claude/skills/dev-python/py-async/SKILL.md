---
name: py-async
description: Use when writing or reviewing Python asyncio code — async/await, asyncio.gather/TaskGroup, cancellation, timeouts, contextvars, structured concurrency, async iterators, or interop with sync code. Also use when diagnosing pending-task warnings, deadlocks in event loops, or choosing between asyncio, threads, and processes. Does not cover async web frameworks in depth (see py-http).
license: Apache-2.0
compatibility: Python 3.11+ (`asyncio.TaskGroup`, `asyncio.timeout`). Notes for 3.10 fallbacks.
metadata:
  sources: "asyncio docs, PEP 654 (ExceptionGroup), Trio design influences"
---

# Python asyncio

## Async Is Cooperative, Single-Threaded

asyncio runs one coroutine at a time on a single thread, yielding at every
`await`. CPU-bound work in an async function blocks every other task. Network
and other I/O is where asyncio pays off.

The mental model:

- `def` → ordinary function.
- `async def` → coroutine; calling it returns a coroutine object, you need to
  `await` it or schedule it.
- `await` → yield to the event loop.

```python
import asyncio

async def fetch(url):
    return await http_get(url)

asyncio.run(fetch("https://example.com"))
```

`asyncio.run` is the canonical entry point. Avoid `loop = asyncio.get_event_loop()`
in new code — it's deprecated for top-level usage.

---

## Run Concurrent Tasks with `TaskGroup`

Python 3.11+ has structured concurrency built in. Use `asyncio.TaskGroup`:

```python
async def load_dashboard(user_id: str):
    async with asyncio.TaskGroup() as tg:
        user_task = tg.create_task(fetch_user(user_id))
        orders_task = tg.create_task(fetch_orders(user_id))
        prefs_task = tg.create_task(fetch_prefs(user_id))

    return Dashboard(
        user=user_task.result(),
        orders=orders_task.result(),
        prefs=prefs_task.result(),
    )
```

If any task fails, the group cancels the rest and raises an `ExceptionGroup`
containing the original exceptions. This is dramatically safer than the older
`asyncio.gather` pattern (which leaked pending tasks on exception).

For Python 3.10, fall back to `asyncio.gather(..., return_exceptions=False)`
and remember to cancel pending tasks manually on failure — `TaskGroup` exists
because that was painful.

---

## `asyncio.gather` vs `TaskGroup`

| Need | Reach for |
|---|---|
| All-or-nothing parallel, error-propagating | `TaskGroup` (3.11+) |
| All-or-nothing parallel (3.10) | `asyncio.gather` |
| Collect failures rather than fail fast | `asyncio.gather(..., return_exceptions=True)` |
| Limit concurrency | `asyncio.Semaphore` |
| First to complete | `asyncio.wait(..., return_when=FIRST_COMPLETED)` |

```python
# Bounded concurrency
async def fetch_all(urls):
    sem = asyncio.Semaphore(10)

    async def fetch_one(u):
        async with sem:
            return await fetch(u)

    async with asyncio.TaskGroup() as tg:
        tasks = [tg.create_task(fetch_one(u)) for u in urls]

    return [t.result() for t in tasks]
```

---

## Cancellation

Cancellation propagates as `asyncio.CancelledError`. Don't swallow it without
re-raising — that breaks structured concurrency.

```python
# Bad — swallows cancellation
try:
    await long_running()
except Exception:
    log.error("failed")

# Good — let cancellation propagate
try:
    await long_running()
except asyncio.CancelledError:
    cleanup()
    raise
except Exception:
    log.error("failed")
```

For deliberate cleanup on cancel, use `try/finally`:

```python
async def with_resource():
    resource = await acquire()
    try:
        return await use(resource)
    finally:
        await resource.close()
```

---

## Timeouts

`asyncio.timeout()` (3.11+) is the modern context manager:

```python
async def fetch_with_timeout(url):
    async with asyncio.timeout(5):
        return await fetch(url)
```

If the timer expires, the inner coroutine is cancelled. The `CancelledError`
becomes a `TimeoutError` at the `async with` boundary.

For 3.10 and below, use `asyncio.wait_for(coro, timeout=5)`.

---

## Don't Block the Loop

Anything synchronous and slow blocks the event loop:

- `time.sleep(1)` — use `await asyncio.sleep(1)`.
- File I/O via `open()` and reads — use `aiofiles` or push to a thread.
- CPU-bound work — push to `asyncio.to_thread` (for I/O-bound but blocking
  libraries) or a process pool (for true CPU work).

```python
# Bad
def heavy_compute(data): ...
async def handler():
    result = heavy_compute(data)   # blocks every other coroutine

# Good — push to a thread
async def handler():
    result = await asyncio.to_thread(heavy_compute, data)

# Good — push to a process for real CPU work
from concurrent.futures import ProcessPoolExecutor
loop = asyncio.get_running_loop()
async def handler():
    result = await loop.run_in_executor(pool, heavy_compute, data)
```

Threads are still subject to the GIL. They help only when the blocking work
releases the GIL (most C extensions, networking, file I/O).

---

## Async Iteration

`async for` and async generators consume / produce asynchronously:

```python
async def stream_users():
    offset = 0
    while True:
        batch = await db.fetch_users(offset, limit=100)
        if not batch:
            return
        for user in batch:
            yield user
        offset += len(batch)

async for user in stream_users():
    await process(user)
```

`async for` respects the loop's cancellation; `break` inside it properly
closes the async generator (via `aclose()`).

---

## Async Context Managers

Resources that need async setup/teardown use `async with`:

```python
async with httpx.AsyncClient() as client:
    response = await client.get(url)
```

Define one with `@contextlib.asynccontextmanager` or by implementing
`__aenter__` and `__aexit__`:

```python
from contextlib import asynccontextmanager

@asynccontextmanager
async def db_transaction(db):
    async with db.begin() as tx:
        yield tx
```

---

## Don't Mix Sync and Async Naively

Calling `asyncio.run()` from within an already-running event loop raises
`RuntimeError`. Don't do it — and don't paper over with `nest_asyncio` outside
of notebooks.

For libraries that need to expose both sync and async APIs, write the async
version and provide a thin sync wrapper:

```python
def sync_get(url):
    return asyncio.run(async_get(url))
```

Don't write parallel sync and async implementations — they diverge.

---

## `contextvars` for Request-Scoped State

`contextvars.ContextVar` survives `await` boundaries within a task, but each
task sees its own value. Use it to thread request-scoped data (trace id,
authenticated user) without passing it through every function:

```python
import contextvars

request_id: contextvars.ContextVar[str] = contextvars.ContextVar("request_id")

async def handler(request):
    request_id.set(request.headers["x-request-id"])
    await process()

async def process():
    log.info({"request_id": request_id.get()}, "processing")
```

---

## Fire-and-Forget Tasks

A task that nobody awaits can be garbage-collected mid-flight or have its
exceptions silently lost. Keep a reference and attach a callback:

```python
background_tasks: set[asyncio.Task] = set()

def fire(coro):
    t = asyncio.create_task(coro)
    background_tasks.add(t)
    t.add_done_callback(background_tasks.discard)
    t.add_done_callback(lambda t: t.exception() and log.error(...))
```

Better yet: don't fire-and-forget. Use a queue + a long-lived consumer task,
or push to a real job system (Celery, Dramatiq, arq).

---

## Quick Reference

| Need | Reach for |
|---|---|
| Concurrent calls, fail-fast | `TaskGroup` |
| Concurrent, collect failures | `gather(return_exceptions=True)` |
| Bounded concurrency | `Semaphore` |
| Timeout | `async with asyncio.timeout(s):` |
| Sleep | `await asyncio.sleep(s)` |
| Blocking call | `await asyncio.to_thread(fn, ...)` |
| Heavy CPU | `loop.run_in_executor(process_pool, ...)` |
| Cancel cleanly | Re-raise `CancelledError` |
| Per-task state | `contextvars.ContextVar` |

## Related Skills

- **Error handling**: [py-error-handling](../py-error-handling/SKILL.md) for `ExceptionGroup` and `except*`.
- **HTTP**: [py-http](../py-http/SKILL.md) for FastAPI/async clients.
- **Performance**: [py-performance](../py-performance/SKILL.md) for GIL/threads/processes trade-offs.
- **Logging**: [py-logging](../py-logging/SKILL.md) for contextvars-based context.
- **Testing**: [py-testing](../py-testing/SKILL.md) for pytest-asyncio.
