---
name: node-control-flow
description: Use when writing or refactoring control flow in Node.js/TypeScript — early returns, guard clauses, switch with exhaustiveness, ternaries, nullish vs OR coalescing, optional chaining, or replacing nested conditionals. Also use when reviewing code that feels "too nested" or that mixes assignment and branching.
license: Apache-2.0
metadata:
  sources: "Google TypeScript Style Guide, Airbnb JavaScript Style Guide"
---

# Node.js Control Flow

## Early Return for Clarity

Push error cases and edge conditions to the top. Leave the main logic at the
lowest indentation.

```ts
// Bad
function process(req: Request) {
  if (req.user) {
    if (req.user.isActive) {
      if (req.body) {
        return doWork(req.user, req.body);
      } else {
        throw new Error('no body');
      }
    } else {
      throw new Error('inactive');
    }
  } else {
    throw new Error('no user');
  }
}

// Good
function process(req: Request) {
  if (!req.user) throw new Error('no user');
  if (!req.user.isActive) throw new Error('inactive');
  if (!req.body) throw new Error('no body');

  return doWork(req.user, req.body);
}
```

If you find more than three guard clauses at the top of a function, consider
whether the function is doing too much, or whether the guards belong on a
schema/validator.

---

## `if` vs Ternary vs `??`

| Need | Reach for |
|---|---|
| Single boolean check, two branches with simple values | ternary |
| Pick between two longer expressions | `if`/`else` |
| Default for `null`/`undefined` only | `??` (nullish coalescing) |
| Default for any falsy (`0`, `''`, `false`) | `\|\|` (rarely correct — be deliberate) |
| Optional member access | `?.` |

```ts
// Good
const label = user.isAdmin ? 'admin' : 'user';
const port = config.port ?? 3000;          // 0 stays 0
const name = user.profile?.fullName ?? 'anonymous';

// Bad — uses || for default; if count is 0 the fallback fires
const count = input.count || 10;

// Good — use ?? when you mean "missing"
const count = input.count ?? 10;
```

`||` is correct when you want **any falsy** to fall through (rare but legitimate
for empty-string defaults).

---

## Switch with Discriminated Unions

`switch` is fine for **finite, discriminated** branches. Use it on a string
literal or discriminant field, never on an object identity or computed value.

```ts
type Event =
  | { kind: 'created'; userId: string }
  | { kind: 'updated'; userId: string; diff: Diff }
  | { kind: 'deleted'; userId: string };

function handle(e: Event) {
  switch (e.kind) {
    case 'created': return onCreated(e.userId);
    case 'updated': return onUpdated(e.userId, e.diff);
    case 'deleted': return onDeleted(e.userId);
    default: return assertNever(e);
  }
}

function assertNever(x: never): never {
  throw new Error(`unhandled: ${JSON.stringify(x)}`);
}
```

`assertNever` makes a missing case a **compile-time error**, not a runtime
surprise. Always end an exhaustive switch with it.

### Switch Fallthrough

Don't intentionally fall through. The lint rule `no-fallthrough` should be on.
If two cases share logic, factor it into a helper or list both labels:

```ts
case 'a':
case 'b':
  return doAOrB();
```

---

## Object Lookup vs Switch

For a flat mapping `key → value`, an object lookup is shorter and cheaper than
a switch:

```ts
// Good
const labels = {
  pending: 'In Progress',
  active: 'Active',
  archived: 'Archived',
} as const satisfies Record<Status, string>;

const label = labels[status];
```

Use `switch` when each branch contains real logic (not just a constant).

---

## Loops: Pick the Right One

| Loop | When |
|---|---|
| `for...of` | Iterating an array / Set / Map / iterable |
| `for (let i = 0; ...; i++)` | Need the index and want to mutate / break |
| `for (const k of Object.keys(o))` | Iterating object keys; never `for...in` |
| `for await ... of` | Async iterable (streams, generators) |
| `.map` / `.filter` / `.reduce` | Pure transformation; don't await inside |
| `.forEach` | Avoid — no early break, awkward with async |

Never use `for...in` on arrays — it picks up inherited and added properties and
visits keys as strings. Use `for...of` or numeric `for`.

```ts
// Bad
for (const i in arr) { console.log(arr[i]); }  // i is string

// Good
for (const v of arr) { console.log(v); }
for (let i = 0; i < arr.length; i++) { console.log(i, arr[i]); }
```

---

## Optional Chaining and Nullish Coalescing

These compose tightly. Don't over-chain — if you find `a?.b?.c?.d?.e`, your
type model is probably too loose. Either narrow earlier or model the absence as
a discriminated union.

```ts
// Acceptable
const city = user.address?.city ?? 'unknown';

// Code smell
const x = root?.a?.b?.c?.d?.e ?? null;   // model the shape better
```

---

## Don't Mix Assignment and Branching

```ts
// Bad — confusing
if ((user = findUser(id))) { ... }

// Good — separate
const user = findUser(id);
if (user) { ... }
```

Modern `if (const user = findUser(id)) { ... }` is **not** valid JS. Declare,
then test.

---

## Ternary Chains: Stop at Two

```ts
// Bad — read like a maze
const label = a ? 'A' : b ? 'B' : c ? 'C' : 'D';

// Good — use a function or switch
function labelFor(x: X): string {
  if (x.isA) return 'A';
  if (x.isB) return 'B';
  if (x.isC) return 'C';
  return 'D';
}
```

A nested ternary across more than two conditions is almost always more readable
as an `if`/`else` ladder or a small map.

---

## Loops vs Recursion

Prefer loops. V8 does not guarantee tail-call optimization, and deep recursion
can hit the stack limit (~10k–30k frames). Use recursion only for genuinely
tree-shaped data where the call depth is bounded.

---

## Quick Reference

| Want | Default |
|---|---|
| Flatten nested ifs | Early return |
| Default for missing | `??` |
| Default for any falsy | `\|\|` (rare) |
| Exhaustive multi-branch | `switch` + `assertNever` |
| Iterate iterable | `for...of` |
| Async iterate | `for await ... of` |
| Map keys → labels | object lookup |
| Avoid | `for...in` on arrays, ternary chains, `forEach` with async |

## Related Skills

- **Style core**: See [node-style-core](../node-style-core/SKILL.md) for nesting and early-return defaults.
- **Async**: See [node-async](../node-async/SKILL.md) for async iteration and Promise loop pitfalls.
- **Types**: See [node-types](../node-types/SKILL.md) for discriminated unions and `assertNever`.
- **Functions**: See [node-functions](../node-functions/SKILL.md) for parameter defaults vs guard clauses.
- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for guard clauses that throw.
