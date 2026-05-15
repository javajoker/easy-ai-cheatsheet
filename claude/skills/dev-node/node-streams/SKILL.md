---
name: node-streams
description: Use when working with Node streams — Readable, Writable, Transform, Duplex, web streams, async iteration over streams, backpressure, pipeline composition, or large-file/network I/O. Also use when reviewing code that loads big payloads into memory and should be streaming. Does not cover HTTP request/response body handling at the framework level (see node-http).
license: Apache-2.0
compatibility: Examples use `node:stream/promises` (Node 15+) and Web Streams (`ReadableStream`/`WritableStream`, Node 16.5+).
metadata:
  sources: "Node.js stream docs, WHATWG Streams spec, Substack's stream-handbook (historical)"
---

# Node.js Streams

## When to Stream

Use streams when the data is:

- Larger than you want sitting in memory at once (files, query results, network payloads).
- Arriving over time (sockets, child-process output, sensor data).
- Transformed in stages where each stage shouldn't materialize the full intermediate.

If the payload is a few hundred KB and you'll process it as a single value,
streams are overkill. Just `await fs.readFile`.

---

## Prefer `pipeline` over `pipe`

`stream.pipeline` from `node:stream/promises` propagates errors, cleans up
properly on failure, and gives you a promise to await. The classic `.pipe()`
chain leaks resources and silently swallows errors.

```ts
import { pipeline } from 'node:stream/promises';
import { createReadStream, createWriteStream } from 'node:fs';
import { createGzip } from 'node:zlib';

await pipeline(
  createReadStream('input.txt'),
  createGzip(),
  createWriteStream('input.txt.gz'),
);
```

For a single transform you'd otherwise inline with `.pipe()`, `pipeline` is
still the right tool — it makes the lifecycle explicit.

---

## Async Iteration

A `Readable` is an async iterable. For consumer-side code, `for await ... of`
is usually clearer than registering `'data'`/`'end'` handlers:

```ts
import { createReadStream } from 'node:fs';
import { createInterface } from 'node:readline';

const rl = createInterface({ input: createReadStream('big.csv') });
for await (const line of rl) {
  process(line);
}
```

Throwing inside the loop body propagates as a stream destruction — the iterator
cleans up the underlying read.

---

## Backpressure: Don't Defeat It

Streams have backpressure built in. `pipeline` and `for await` respect it
automatically. The places where it's easy to defeat:

1. **Buffering everything yourself**:
   ```ts
   // Bad
   const chunks: Buffer[] = [];
   for await (const c of stream) chunks.push(c);
   const all = Buffer.concat(chunks);
   ```
   You've just materialized the whole stream. Only do this when the data is
   genuinely small.

2. **Ignoring the return value of `write`**:
   ```ts
   // Bad
   for (const item of items) writable.write(item);

   // Good — respect the drain
   for (const item of items) {
     if (!writable.write(item)) {
       await new Promise((res) => writable.once('drain', res));
     }
   }
   ```
   Or, better, use a pipeline that feeds the writable.

3. **Calling `read()` in a tight loop without a pause**.

---

## Transform Streams

A `Transform` stream consumes and emits. For most transforms, prefer an async
generator and convert with `Readable.from` rather than subclassing.

```ts
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';

async function* upperCase(source: AsyncIterable<Buffer>) {
  for await (const chunk of source) {
    yield Buffer.from(chunk.toString('utf8').toUpperCase());
  }
}

await pipeline(
  inputStream,
  upperCase,
  outputStream,
);
```

`pipeline` accepts an async generator as a stage — far less ceremony than
`new Transform({ transform(chunk, _, cb) { ... } })`.

---

## Web Streams Interop

`ReadableStream` (WHATWG, fetch API) and Node streams are bridgeable:

```ts
import { Readable } from 'node:stream';

// fetch().body is a WHATWG ReadableStream
const res = await fetch(url);
const nodeStream = Readable.fromWeb(res.body!);
await pipeline(nodeStream, writeStream);
```

`Readable.toWeb` goes the other direction. Choose based on the boundary you
expose: third-party API or browser-bound code? Use Web Streams. Pure Node
internals? Node streams.

---

## Object Mode

Object-mode streams pass arbitrary JS values, not bytes. Useful for streaming
query results, JSON lines, or message frames:

```ts
const transform = new Transform({
  objectMode: true,
  transform(record, _, cb) {
    cb(null, { ...record, processed: true });
  },
});
```

Note: in object mode, `highWaterMark` counts *objects*, not bytes. Tune
accordingly (default 16 is often too low for tiny objects, too high for big
ones).

---

## Don't Mix Modes

A stream is either binary or object mode for its lifetime. Don't try to
straddle. If you have a binary input and want object output, put a parsing
transform in the middle that emits structured records.

```ts
await pipeline(
  createReadStream('events.ndjson'),
  parseNDJSON(),          // objectMode transform
  filterRelevant(),       // objectMode transform
  writeJsonLines(out),    // objectMode → binary at the edge
);
```

---

## Error Handling

`pipeline` rejects on the first stream that errors and destroys the rest. The
rejection carries the original error.

```ts
try {
  await pipeline(src, transform, dst);
} catch (cause) {
  throw new Error('encode pipeline failed', { cause });
}
```

When implementing a transform with async iteration, throw normally — the
runtime destroys upstream/downstream and propagates.

For `'error'` events on standalone streams, always attach a listener — an
unhandled `'error'` event crashes the process.

---

## Stream Lifecycle

Streams transition: `open → flowing/paused → ending → closed`. Common pitfalls:

| Symptom | Cause |
|---|---|
| Stream hangs forever | Consumer attached `'data'` listener but never reads to end |
| Memory grows | Backpressure ignored; or you're caching chunks |
| Error not caught | `'error'` event handler missing on a raw `.pipe()` chain |
| `EPIPE` on stdout | Downstream closed; handle with `process.stdout.on('error', ...)` |

Use `stream.finished` if you want to be notified when a single stream is done,
without managing your own listeners:

```ts
import { finished } from 'node:stream/promises';
await finished(readable);
```

---

## Quick Reference

| Need | Reach for |
|---|---|
| Chain streams safely | `pipeline` (node:stream/promises) |
| Iterate a Readable | `for await ... of` |
| Build a transform | async generator + `pipeline` |
| WHATWG ↔ Node | `Readable.fromWeb` / `toWeb` |
| Wait for one stream | `finished` |
| Stream objects | `{ objectMode: true }` |
| Avoid | `.pipe()` without error handling, buffering whole stream |

## Related Skills

- **Async**: See [node-async](../node-async/SKILL.md) for `for await ... of` and AbortSignal.
- **HTTP**: See [node-http](../node-http/SKILL.md) for request/response body streaming.
- **Performance**: See [node-performance](../node-performance/SKILL.md) for buffer pooling and chunk sizing.
- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for wrapping pipeline errors.
- **Data structures**: See [node-data-structures](../node-data-structures/SKILL.md) for Buffer vs Uint8Array.
