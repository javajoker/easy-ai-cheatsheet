---
name: node-data-structures
description: Use when working with arrays, objects, Maps, Sets, tuples, typed arrays, or immutable updates in Node.js/TypeScript. Also use when choosing between Map and plain object, applying ReadonlyArray, handling deep clones, or auditing accidental mutation. Does not cover streaming or buffer-pooling patterns (see node-streams and node-performance).
license: Apache-2.0
compatibility: `structuredClone` is Node 17+. `Array.prototype.findLast` and immutable copy methods are Node 20+.
metadata:
  sources: "MDN, V8 design docs, Google TypeScript Style Guide"
---

# Node.js / TypeScript Data Structures

## Object vs `Map`

| Need | Reach for |
|---|---|
| Fixed shape with known keys (a record type) | Object |
| Dynamic keys, frequent add/remove, iteration order matters | `Map` |
| Keys are not strings (number, object) | `Map` |
| JSON serialization | Object |

```ts
// Good — config / DTO
const user = { id: '1', email: 'a@b' };

// Good — dynamic map of unknown size
const sessions = new Map<string, Session>();
sessions.set(id, session);
```

`Object.create(null)` makes a prototype-less object, safer for user-controlled
keys (no `__proto__` exposure). Prefer `Map` over the bare-object dance.

---

## `Set` and Membership Checks

`Array.includes` is O(n). For repeated membership checks, use `Set`:

```ts
// Bad in a hot path
const allowed = ['admin', 'editor', 'viewer'];
for (const u of users) if (allowed.includes(u.role)) { ... }   // O(n*m)

// Good
const allowed = new Set(['admin', 'editor', 'viewer']);
for (const u of users) if (allowed.has(u.role)) { ... }        // O(n)
```

For tiny constant arrays (≤ 5 items), `includes` is fine and reads more
naturally.

---

## Array Methods: Pick the Right One

| Method | Returns | When |
|---|---|---|
| `map` | new array, same length | 1-to-1 transform |
| `filter` | new array, ≤ length | keep some |
| `flatMap` | new array, may grow/shrink | combine map + filter, or expand |
| `reduce` | single value | aggregate |
| `find` / `findLast` | one element or `undefined` | first/last match |
| `some` / `every` | boolean | predicate over all |
| `at(-1)` | last element | beats `arr[arr.length - 1]` |
| `includes` | boolean | membership in a small array |

Don't chain three transforms when one `for...of` reads more clearly. Don't
hand-write a `for` loop when `map` says the intent.

```ts
// Good
const emails = users.filter((u) => u.isActive).map((u) => u.email);

// Better for non-trivial bodies
const emails: string[] = [];
for (const u of users) {
  if (!u.isActive) continue;
  emails.push(u.email);
}
```

---

## `ReadonlyArray<T>` and `readonly T[]`

For parameters you don't mutate, declare `ReadonlyArray<T>` (or `readonly T[]`).
The checker then flags accidental mutation.

```ts
function sum(values: ReadonlyArray<number>): number {
  // values.push(0);   // compile error
  return values.reduce((a, b) => a + b, 0);
}
```

This is the cheapest way to communicate "I won't change your array". Apply it
to map / filter return values exposed as public API too.

---

## Immutable Update Idioms

Treat shared state as immutable. Build new instances rather than mutating.

```ts
// Bad
user.email = newEmail;

// Good
const updated = { ...user, email: newEmail };

// Bad
arr.push(item);

// Good
const next = [...arr, item];
```

For deeper nested updates, either:

1. Use spread layer by layer (fine up to two layers deep).
2. Reach for `immer` if the structure is genuinely deep.

`Array` got immutable copy methods in Node 20: `toSorted`, `toReversed`,
`toSpliced`, `with`. Prefer them over mutate-then-return.

```ts
// Bad — sorts the caller's array
function sortedByName(users: User[]) {
  return users.sort((a, b) => a.name.localeCompare(b.name));
}

// Good
function sortedByName(users: ReadonlyArray<User>) {
  return users.toSorted((a, b) => a.name.localeCompare(b.name));
}
```

---

## `structuredClone` for Deep Copy

Don't roll your own deep clone. `JSON.parse(JSON.stringify(x))` loses `Date`,
`Map`, `Set`, `undefined`, functions, and circular references. Use
`structuredClone`:

```ts
const copy = structuredClone(original);
```

It works on plain objects, arrays, Map, Set, Date, ArrayBuffer, typed arrays,
and handles cycles. It does **not** clone class instances back into their class
(you get a plain object with the same fields) and it does **not** clone
functions.

For copy-on-write at API boundaries, prefer `structuredClone` for nested
mutable inputs you accept and might retain.

---

## Tuples and Fixed-Shape Arrays

When you want a pair or triple with positional meaning, use a tuple type:

```ts
type Point = readonly [x: number, y: number];

function distance([ax, ay]: Point, [bx, by]: Point): number {
  return Math.hypot(ax - bx, ay - by);
}
```

For more than three positions, prefer a named object — positional code becomes
unreadable beyond a triple.

---

## `Object.keys` / `entries` / `fromEntries`

`Object.keys(o)` returns `string[]`, not `(keyof O)[]`. If you need the typed
keys, cast deliberately or use a helper:

```ts
function typedKeys<T extends object>(o: T): (keyof T)[] {
  return Object.keys(o) as (keyof T)[];
}

for (const k of typedKeys(user)) { ... }
```

`Object.fromEntries` rebuilds an object from `[key, value][]` — useful for the
final step of a transform chain:

```ts
const upper = Object.fromEntries(
  Object.entries(headers).map(([k, v]) => [k.toLowerCase(), v]),
);
```

---

## Buffers and Typed Arrays

Use `Buffer` for binary I/O in Node code paths and `Uint8Array` for
cross-platform code (browsers, workers). `Buffer` is a subclass of `Uint8Array`,
so a `Buffer` is also a `Uint8Array`, but not vice versa.

```ts
const buf = Buffer.from('hello', 'utf8');
const view = new Uint8Array(buf);   // shares memory, no copy
```

Avoid `Buffer.allocUnsafe` unless you'll fill the buffer immediately —
it returns uninitialized memory.

---

## Quick Reference

| Need | Reach for |
|---|---|
| Fixed shape | Object |
| Dynamic / non-string keys | `Map` |
| Membership in large set | `Set` |
| Last element | `arr.at(-1)` |
| Immutable sort/reverse | `toSorted`, `toReversed` |
| Deep copy | `structuredClone` |
| Read-only parameter | `ReadonlyArray<T>` |
| Pair/triple | Tuple `readonly [a, b]` |
| Binary buffer | `Buffer` (Node) / `Uint8Array` (portable) |

## Related Skills

- **Types**: See [node-types](../node-types/SKILL.md) for `ReadonlyArray`, tuples, and discriminated unions.
- **Functions**: See [node-functions](../node-functions/SKILL.md) for pure-function patterns over data structures.
- **Performance**: See [node-performance](../node-performance/SKILL.md) for hot-path data-structure choices.
- **Streams**: See [node-streams](../node-streams/SKILL.md) for buffer-pool and chunked binary patterns.
