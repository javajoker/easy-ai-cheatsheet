---
name: node-performance
description: Use when profiling or optimizing Node.js performance — event loop lag, CPU hot paths, memory growth, GC pressure, async overhead, buffer pooling, JSON parsing, or worker threads. Also use when reviewing code claimed to be a hot path, or when investigating a slow endpoint, OOM, or latency regression. Does not cover load test design itself.
license: Apache-2.0
metadata:
  sources: "V8 design docs, Node.js perf-hooks, clinic.js, 0x flamegraph"
---

# Node.js Performance

## Measure First

Don't optimize until you've measured. Tools that pay for themselves:

| Tool | When |
|---|---|
| `--prof` + `--prof-process` | CPU profile of a process run |
| `clinic doctor` | High-level diagnosis: event loop, I/O, GC |
| `clinic flame` / `0x` | CPU flamegraph |
| `clinic bubbleprof` | Async-flow visualization |
| `node:perf_hooks` | In-process timing |
| Chrome DevTools (`--inspect`) | Live heap and CPU |

```bash
node --prof src/main.js
node --prof-process isolate-*.log > profile.txt
```

For services, instrument the event-loop lag and emit it as a metric:

```ts
import { monitorEventLoopDelay } from 'node:perf_hooks';
const h = monitorEventLoopDelay({ resolution: 20 });
h.enable();
setInterval(() => {
  metrics.gauge('event_loop_lag_p99_ms', h.percentile(99) / 1e6);
  h.reset();
}, 10_000);
```

---

## The Event Loop Is Single-Threaded

Every synchronous CPU cycle delays *every* other request. Find and fix:

- Big JSON parses / serializes on the hot path.
- Synchronous crypto / hashing.
- Regex with catastrophic backtracking.
- Deep object cloning.

Move CPU-bound work to **worker threads** or break it into chunks that yield
with `await setImmediate()`:

```ts
import { Worker } from 'node:worker_threads';

const worker = new Worker('./pdf-render-worker.js');
worker.postMessage({ doc });
worker.once('message', (out) => reply.send(out));
```

For one-off CPU bursts in the main thread, chunk:

```ts
import { setImmediate as yieldLoop } from 'node:timers/promises';
for (let i = 0; i < n; i++) {
  doStep(i);
  if (i % 1000 === 0) await yieldLoop();
}
```

---

## JSON: The Usual Bottleneck

`JSON.parse` and `JSON.stringify` are fast in V8 but are still synchronous and
allocate. For very large payloads:

- **Stream parse** with `stream-json` (or similar) — process records as they
  arrive, never materialize the whole thing.
- **Skip parsing** when you don't need the data — pass through as a Buffer.
- **Schema-aware serialize** with `fast-json-stringify` (Fastify uses it).
  Compiles the response shape into a tight function; 2-5× faster than the
  default `JSON.stringify`.

```ts
import fastJson from 'fast-json-stringify';
const stringify = fastJson({
  type: 'object',
  properties: {
    id: { type: 'string' },
    email: { type: 'string' },
  },
});
const body = stringify(user);
```

---

## Allocation and GC

Every `{...}`, `[...]`, `new ClassName()`, template literal, and `.map()`
allocates. Hot-path allocations pile up and trigger GC pauses.

Patterns that help:

- **Reuse buffers** — `Buffer.allocUnsafe` once, fill in place, copy out only
  what you ship.
- **Avoid `String.split` in hot loops** — use indexOf scans.
- **Avoid `Array.from(iterable)`** when a `for...of` is enough.
- **Cache compiled regex** at module scope, not inside the function body.

Cold-path code: don't bother. Readability wins.

Look at GC in clinic doctor; if the GC line is a sawtooth, allocations are
the suspect.

---

## Connection and Buffer Pooling

For repeated HTTP calls to the same host, share a `keepAlive` agent:

```ts
import { Agent } from 'node:https';
const agent = new Agent({ keepAlive: true, maxSockets: 50 });

await fetch(url, { agent } as any);   // node-fetch / undici options
```

`undici` is Node's modern HTTP client; for high-throughput outbound, use it
directly:

```ts
import { Pool } from 'undici';
const pool = new Pool('https://api.example.com', { connections: 50 });
const { body } = await pool.request({ method: 'GET', path: '/users/1' });
```

For DBs, use the driver's pool config — `max`, `idleTimeout`,
`connectionTimeout`. A pool of 10 is usually a fine starting point.

---

## Don't Block on Logging in the Hot Path

Pino in async mode batches writes via `pino.destination({ sync: false })` or
`pino.transport`. Sync logging blocks the event loop on every line.

For very high log volume, sample (see [node-logging](../node-logging/SKILL.md))
and emit a metric for the unsampled count.

---

## Caching

The cheapest call is the one you don't make. Cache:

- **Computed results** when the inputs repeat (LRU in-process).
- **Upstream responses** with `Cache-Control` (CDN).
- **DB reads** that are rare-write, frequent-read (Redis).

```ts
import { LRUCache } from 'lru-cache';
const cache = new LRUCache<string, User>({ max: 1000, ttl: 60_000 });

async function getUser(id: string) {
  const hit = cache.get(id);
  if (hit) return hit;
  const user = await db.users.findById(id);
  cache.set(id, user);
  return user;
}
```

Watch for stampedes: many requests miss at once and all hit the upstream.
Use `dataloader` or a single-flight pattern (deduplicate concurrent fetches
for the same key).

---

## Regex Pitfalls

A regex with nested quantifiers (`(a+)+`) on adversarial input can run for
seconds (ReDoS). Linters and `safe-regex` flag the common ones.

In hot paths, prefer string methods (`startsWith`, `indexOf`) when the match
shape allows.

```ts
// Bad: catastrophic backtracking on long inputs
const slow = /^(a+)+$/;

// Good: linear
const fast = /^a+$/;
```

---

## Memory Leaks

Common patterns:

- **Event listener accumulation**: same listener added every request without
  removal. Use `once` or remove on cleanup.
- **Global maps that only grow** — switch to LRU or weak references.
- **Closures that capture a big object** — release with `obj = null` after use
  if the closure outlives the call.

Tools: `--heap-prof`, Chrome DevTools heap snapshot, `clinic heapprofiler`.
Look for retained size, not shallow size.

---

## Worker Threads vs Cluster vs Process Manager

| Need | Reach for |
|---|---|
| CPU-bound task while serving requests | Worker thread |
| Multiple cores for an HTTP server | `cluster` module or PM (pm2, container replicas) |
| Heavy memory isolation (untrusted code) | Child process |
| Background queue work | Separate worker process consuming BullMQ / SQS |

Cluster is fine; a container per worker (orchestrated by Kubernetes) is
usually simpler in production than the cluster module.

---

## Benchmarking

Use `node:test`'s built-in bench (Node 22+) or `tinybench`. Run for enough
iterations to dwarf JIT warmup; report median, not mean.

```ts
import { Bench } from 'tinybench';
const bench = new Bench({ time: 1000 });
bench
  .add('Set has', () => set.has('key'))
  .add('Array includes', () => arr.includes('key'));
await bench.run();
console.table(bench.table());
```

Compare relative numbers, not absolute. Microbenchmarks lie at the absolute
level (V8 inlines, branch predicts, GC pauses); they're useful for
**comparing two implementations on the same machine**.

---

## Quick Reference

| Symptom | Look at |
|---|---|
| High latency, low CPU | I/O — DB, upstream, sync FS |
| High CPU, low latency | Computation in the hot path |
| Sawtooth GC | Allocation pattern |
| Slow first request | Cold cache, JIT warmup |
| Memory grows over time | Listener leaks, growing maps |
| Event loop lag spikes | Sync work; check JSON parses |
| Many small fetches slow | Missing keep-alive agent |

## Related Skills

- **Async**: See [node-async](../node-async/SKILL.md) for event-loop-friendly async patterns.
- **Streams**: See [node-streams](../node-streams/SKILL.md) for avoiding full-payload materialization.
- **HTTP**: See [node-http](../node-http/SKILL.md) for fast-json-stringify and connection reuse.
- **Logging**: See [node-logging](../node-logging/SKILL.md) for async vs sync logging.
- **Data structures**: See [node-data-structures](../node-data-structures/SKILL.md) for Map/Set choices in hot paths.
