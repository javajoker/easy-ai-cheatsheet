---
name: py-performance
description: Use when profiling or optimizing Python — CPU hot paths, GIL impact, asyncio vs threads vs processes, memory growth, JSON parsing, container hot loops, vectorization with numpy/numba. Also use when investigating slow endpoints, OOM, or latency regressions. Does not cover load test design itself.
license: Apache-2.0
metadata:
  sources: "CPython internals docs, cProfile/py-spy/Scalene docs, asyncio docs"
---

# Python Performance

## Measure First

Don't optimize until you've measured.

| Tool | When |
|---|---|
| `cProfile` | Function-level wall time per call (CPU-bound) |
| `py-spy` | Production-safe sampling profiler; flamegraphs |
| `scalene` | CPU + memory + GPU combined; identifies allocations |
| `tracemalloc` | Memory allocation tracking by line |
| `pytest-benchmark` | Microbenchmarks for unit-level comparisons |
| `timeit` | Stopwatch for small snippets |

```bash
py-spy record -o profile.svg -- python -m myapp
```

For services, expose event-loop and request-latency metrics and trend them.
Latency regressions stand out on time-series charts before they appear in
profiles.

---

## The GIL

CPython's Global Interpreter Lock serializes Python bytecode execution.
Threads do not give you parallel CPU — they give parallel I/O.

For CPU-bound work:

- **Process pool** (`concurrent.futures.ProcessPoolExecutor`,
  `multiprocessing.Pool`) — true parallelism, with pickling overhead per call.
- **C extensions that release the GIL** — numpy, pandas, pillow, hashlib.
  Threads do help when the work is inside the extension.
- **Native code** — Cython, Rust via PyO3, C via cffi.
- **Python 3.13 free-threaded build** (experimental, no-GIL) — promising;
  not production for most teams yet.

For I/O-bound work: asyncio is the default. Threads work too (especially for
sync libraries) but asyncio scales further on the same machine.

---

## asyncio vs Threads vs Processes

| Work | Reach for |
|---|---|
| Many concurrent network calls | asyncio |
| Blocking sync I/O library you can't replace | `asyncio.to_thread` (one or two helpers; not "everywhere") |
| Heavy CPU | Process pool or native code |
| Mix of CPU + I/O | asyncio for I/O; offload CPU to `run_in_executor(process_pool, ...)` |

See [py-async](../py-async/SKILL.md) for the asyncio patterns.

---

## Hot-Loop Patterns

In a hot loop:

```python
# Bad — attribute lookup and global lookup each iteration
import math
for i in items:
    result.append(math.sqrt(i))

# Good — bind to local
sqrt = math.sqrt
for i in items:
    result.append(sqrt(i))

# Better — comprehension; smaller bytecode
result = [math.sqrt(i) for i in items]

# Best — vectorize when applicable
import numpy as np
result = np.sqrt(np.asarray(items))
```

For numerical loops over large arrays, numpy is 10-1000× faster than the
equivalent Python loop because the inner loop runs in C with the GIL
released.

---

## Container Choices in Hot Paths

| Need | Reach for |
|---|---|
| Membership test on big collection | `set` (O(1)) over `list` (O(n)) |
| FIFO queue | `collections.deque` (O(1) popleft) |
| Auto-defaults | `defaultdict` |
| Many small records | `@dataclass(slots=True)` (less memory, faster attribute access) |
| Strings concatenated in a loop | `"".join(parts)` |

```python
# Bad — O(n²) string concat
result = ""
for s in parts:
    result += s

# Good — O(n)
result = "".join(parts)
```

---

## JSON Performance

`json` (stdlib) is fine for small/medium payloads. For very large payloads or
high throughput:

- `orjson` — fastest JSON library; 5–10× faster than stdlib.
- `ujson` — older, still fast.
- `msgspec` — schema-aware JSON; combines validation and parsing.

```python
import orjson
data = orjson.loads(raw)
out = orjson.dumps(obj)         # returns bytes
```

For streaming JSON over the network, `ijson` parses incrementally without
holding the whole document in memory.

---

## Allocation Pressure and GC

Every `{...}`, `[...]`, `MyClass(...)` allocates. Hot-loop allocations
trigger GC pauses.

Tactics:

- **`__slots__`** on classes you'll create many of — less memory, no dict.
- **Object pooling** for short-lived objects in hot paths (rare; usually
  premature).
- **Avoid intermediate lists** — use generators when the data is consumed
  once.

Check `gc.get_stats()` to see GC frequency. For long-running services with
big working sets, tuning `gc.set_threshold` rarely helps; latency is
usually dominated by I/O.

---

## Connection and Resource Pooling

For repeated outbound HTTP calls to the same host, reuse a client:

```python
import httpx

# Bad — new client per call
async def fetch(url):
    async with httpx.AsyncClient() as c:
        return await c.get(url)

# Good — module-level client, app lifecycle
client = httpx.AsyncClient(timeout=5.0, http2=True)

async def fetch(url):
    return await client.get(url)
```

For DBs, use the driver's pool. Default settings are rarely optimal — tune
`pool_size`, `max_overflow`, `pool_recycle` against your load profile.

---

## Caching

The cheapest call is the one you don't make. Cache:

- Pure-function results: `functools.cache` (or `lru_cache`).
- Expensive recurring lookups: in-process LRU (`cachetools`) or Redis.
- Upstream responses: HTTP `Cache-Control`.

```python
from functools import cache

@cache
def parse_template(s: str) -> Template:
    return compile_template(s)
```

`functools.cache` is unbounded (use carefully). `functools.lru_cache(maxsize=N)`
bounds it. Don't cache mutable objects unless you understand the
consequences — caches are shared.

---

## Memory Growth

Common patterns:

- Module-level dict that only grows.
- Caching with no eviction.
- Event listener accumulation (rare in Python, but possible with custom
  signal hubs).
- Closures that capture a big object.

Tools:

```python
import tracemalloc
tracemalloc.start()

# ... run workload ...

snapshot = tracemalloc.take_snapshot()
for stat in snapshot.statistics("lineno")[:10]:
    print(stat)
```

`py-spy dump --pid <PID>` shows the live stack of every thread without
restarting the process — useful for diagnosing a stuck or growing service.

---

## Avoid Sync I/O in async Code

Calling `time.sleep(1)`, `requests.get(...)`, or `open(...).read()` inside
an async handler blocks the event loop and freezes every other task.

```python
# Bad
async def handler():
    response = requests.get(url)       # sync, blocks loop

# Good
async def handler():
    async with httpx.AsyncClient() as c:
        response = await c.get(url)
```

Or push to a thread:

```python
async def handler():
    data = await asyncio.to_thread(blocking_lib.fetch, url)
```

---

## Benchmarking

```python
import timeit
timeit.timeit("x in s", setup="s = set(range(1000)); x = 500", number=1_000_000)
```

Compare *relative* numbers on the *same* machine. Microbenchmarks lie at
the absolute level — GC, JIT (in PyPy), branch prediction. Run for enough
iterations to dwarf measurement noise.

For larger comparisons, `pytest-benchmark`:

```python
def test_set_lookup(benchmark):
    s = set(range(1000))
    benchmark(lambda: 500 in s)
```

---

## PyPy and Alternative Interpreters

PyPy can be a drop-in 2-10× speedup for CPU-bound pure-Python code. It's
worth a try when the workload doesn't depend on C extensions that PyPy
hasn't optimized. Test thoroughly — some libraries break.

Python 3.13 free-threaded build (no-GIL) is promising but experimental.
Stay on CPython 3.12 for production; revisit as the ecosystem matures.

---

## Quick Reference

| Symptom | Look at |
|---|---|
| High latency, low CPU | I/O — DB, upstream, sync FS |
| High CPU, low latency | Hot loops; vectorize or push to native code |
| Memory grows over time | Unbounded caches, module-level dicts |
| Sawtooth GC | Allocation pattern; use slots |
| Async handler slow | Sync call in the path; offload to thread or replace |
| Outbound calls slow | Missing client reuse |

## Related Skills

- **Async**: [py-async](../py-async/SKILL.md) for event-loop-friendly async.
- **Data structures**: [py-data-structures](../py-data-structures/SKILL.md) for hot-path container choice.
- **Iterators**: [py-iterators-generators](../py-iterators-generators/SKILL.md) for streaming.
- **HTTP**: [py-http](../py-http/SKILL.md) for client reuse.
- **Logging**: [py-logging](../py-logging/SKILL.md) for async-friendly logging.
