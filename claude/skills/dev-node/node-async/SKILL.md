---
name: node-async
description: Use when writing or reviewing async/await, Promises, parallel vs sequential async, cancellation with AbortController/AbortSignal, timeouts, or async iteration in Node.js. Also use when debugging unhandled promise rejections, missed `await`s, or task races. Does not cover Node streams in depth (see node-streams).
license: Apache-2.0
compatibility: Node 18+ (uses AbortSignal.timeout, Promise.withResolvers in 22+).
metadata:
  sources: "Node.js docs, V8 microtask model, Bluebird → native promises transition guidance"
---

# Node.js Async

## Core Rule: Await Every Promise

Every promise must be **awaited**, **returned**, or explicitly converted to
fire-and-forget with a logged catch. An unawaited promise is the dominant source
of unhandled rejections.

```ts
// Bad — promise is fire-and-forget, errors lost
fetchUser(id);

// Good — awaited inline
const user = await fetchUser(id);

// Good — returned for caller to await
function getUser(id: string) {
  return fetchUser(id);
}

// Acceptable — intentionally fire-and-forget, with error reporting
void fetchUser(id).catch((err) => log.error({ err }, 'background fetch failed'));
```

Enable ESLint `@typescript-eslint/no-floating-promises` so this is caught at
review time.

---

## `async`/`await` Beats `.then()` Chains

For sequential logic, `async`/`await` reads top-to-bottom; `.then()` chains
flatten into callback ladders for non-trivial control flow.

```ts
// Bad
function loadUser(id: string) {
  return fetchUser(id)
    .then((user) => fetchOrders(user.id).then((orders) => ({ user, orders })))
    .catch((err) => { throw new Error('load failed', { cause: err }); });
}

// Good
async function loadUser(id: string) {
  try {
    const user = await fetchUser(id);
    const orders = await fetchOrders(user.id);
    return { user, orders };
  } catch (cause) {
    throw new Error('load failed', { cause });
  }
}
```

Reserve `.then` / `.catch` for fire-and-forget at the boundary
(`void p.catch(...)`) and for cases where you genuinely want to chain
transformations on a stored Promise.

---

## Parallel vs Sequential

`await` in a loop forces serial execution. If the operations are independent,
launch them in parallel.

```ts
// Bad — N requests serialized for no reason
const results = [];
for (const id of userIds) {
  results.push(await fetchUser(id));
}

// Good — parallel, all-or-nothing
const results = await Promise.all(userIds.map((id) => fetchUser(id)));

// Good — parallel, collect successes and failures
const settled = await Promise.allSettled(userIds.map((id) => fetchUser(id)));
const ok = settled.filter((s) => s.status === 'fulfilled');
```

**Watch the fan-out**: 10,000 concurrent requests is rarely what you want. Cap
concurrency with a small pool:

```ts
import pLimit from 'p-limit';
const limit = pLimit(8);
const results = await Promise.all(userIds.map((id) => limit(() => fetchUser(id))));
```

Pick the right combinator:

| Need | Combinator |
|---|---|
| Wait for all, fail-fast on first error | `Promise.all` |
| Wait for all, collect failures separately | `Promise.allSettled` |
| First to resolve (or reject) | `Promise.race` |
| First to successfully resolve | `Promise.any` |

---

## Cancellation: `AbortSignal`

Long-running async operations should accept an `AbortSignal` so the caller can
cancel them. Pass it through to every layer; don't synthesize a new one.

```ts
async function search(query: string, signal?: AbortSignal): Promise<Hit[]> {
  const res = await fetch(`/search?q=${query}`, { signal });
  if (!res.ok) throw new Error(`search failed: ${res.status}`);
  return res.json();
}

const ctrl = new AbortController();
setTimeout(() => ctrl.abort(), 5000);
const hits = await search('rust', ctrl.signal);
```

For a simple timeout, use `AbortSignal.timeout(ms)` (Node 18+):

```ts
await fetch(url, { signal: AbortSignal.timeout(5000) });
```

Compose multiple cancellation sources with `AbortSignal.any([...])`.

---

## Error Handling

Inside an `async` function, throw normally. Outside, catch with `try`/`catch`
or `.catch`. Use `cause` to preserve the original error:

```ts
try {
  await loadUser(id);
} catch (cause) {
  throw new Error(`loadUser(${id}) failed`, { cause });
}
```

Top-level entry points must catch — an uncaught rejection kills the Node
process under default settings. Wrap your `main`:

```ts
async function main() { ... }

main().catch((err) => {
  log.fatal({ err }, 'fatal');
  process.exit(1);
});
```

See [node-error-handling](../node-error-handling/SKILL.md) for typed errors and
the `cause` chain.

---

## Async Iteration

Use `for await ... of` for streams, async generators, and paginated APIs. The
loop body runs sequentially; each `await` pauses iteration.

```ts
async function* pages(url: string) {
  let next: string | null = url;
  while (next) {
    const res = await fetch(next);
    const { items, nextUrl } = await res.json();
    yield items;
    next = nextUrl;
  }
}

for await (const batch of pages('/api/items')) {
  for (const item of batch) process(item);
}
```

---

## Common Anti-Patterns

| Anti-pattern | Fix |
|---|---|
| `new Promise((res) => res(value))` | `Promise.resolve(value)` |
| `async function f() { return Promise.resolve(x); }` | `async function f() { return x; }` (`async` already wraps) |
| `await await p` | `await p` |
| `return await p` at function tail (outside try) | just `return p` — but **inside `try`**, `return await p` is correct so the catch can see the rejection |
| `forEach` with async callback | `for...of` with `await`, or `Promise.all(arr.map(...))` |
| `setTimeout(() => resolve(), ms)` as your own delay | `await setTimeout(ms)` from `node:timers/promises` |

---

## Event Loop Awareness

`await` yields to the microtask queue, not the macrotask queue. CPU-bound work
inside an async function still blocks the loop. Move heavy CPU work to a worker
thread or to `setImmediate` chunks.

```ts
import { setImmediate as yieldLoop } from 'node:timers/promises';

for (let i = 0; i < items.length; i++) {
  process(items[i]);
  if (i % 1000 === 0) await yieldLoop();
}
```

---

## Quick Reference

| Need | Reach for |
|---|---|
| Sequential | `await` in a `for...of` |
| Parallel, fail-fast | `Promise.all` |
| Parallel, collect failures | `Promise.allSettled` |
| Bounded concurrency | `p-limit` |
| Timeout | `AbortSignal.timeout(ms)` |
| Composed cancellation | `AbortSignal.any([...])` |
| Preserve original error | `new Error(msg, { cause })` |
| Loop yield | `setImmediate` (timers/promises) |

## Related Skills

- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for typed errors and `cause`.
- **Streams**: See [node-streams](../node-streams/SKILL.md) for pipeline backpressure and async iterators on streams.
- **HTTP**: See [node-http](../node-http/SKILL.md) for request-scoped AbortSignal.
- **Testing**: See [node-testing](../node-testing/SKILL.md) for testing async code, timers, and cancellation.
- **Performance**: See [node-performance](../node-performance/SKILL.md) for event-loop diagnostics.
