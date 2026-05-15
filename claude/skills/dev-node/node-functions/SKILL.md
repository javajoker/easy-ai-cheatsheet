---
name: node-functions
description: Use when designing or reviewing function signatures in Node.js/TypeScript — choosing arrow vs function declaration, parameter shape (positional vs options object), default parameter values, rest parameters, return types, and overloads. Also use when refactoring long parameter lists or "boolean trap" call sites.
license: Apache-2.0
metadata:
  sources: "Google TypeScript Style Guide, Effective TypeScript, Clean Code"
---

# Node.js / TypeScript Functions

## Arrow vs `function` Declarations

| Use | Reach for |
|---|---|
| Top-level named functions | `function foo() { ... }` (hoisted, named in stack) |
| Methods | shorthand `foo() { ... }` |
| Callbacks, single-use lambdas | arrow `(x) => ...` |
| Need `this` binding from enclosing | arrow |
| Need own `this` (rare) | `function` |

```ts
// Good
export function buildClient(opts: Options): Client { ... }

const numbers = items.map((it) => it.count);

class UserService {
  async getById(id: string): Promise<User> { ... }
}
```

Don't redeclare `function foo() { ... }` as `const foo = () => { ... }` for no
reason — declarations hoist and produce cleaner stack traces.

---

## Annotate Public Return Types

For exported functions and module-public functions, annotate the return type
even if it could be inferred. This:

- Locks the contract — accidental change is a compile error.
- Speeds up the type-checker on large projects.
- Makes the API readable without IDE assistance.

```ts
// Good
export async function fetchUser(id: string): Promise<User> { ... }

// Fine for internal helpers
function double(x: number) {
  return x * 2;
}
```

Lint with `@typescript-eslint/explicit-module-boundary-types`.

---

## Parameter Shape: 0–3 Positional, Else Options Object

| Count | Shape |
|---|---|
| 0–3 simple, ordered, obvious | positional |
| ≥ 4, or any boolean / optional / config-like | options object |

```ts
// Bad — boolean trap
function createUser(name: string, email: string, isAdmin: boolean, active: boolean) { ... }
createUser('Ada', 'ada@example.com', false, true);  // which is which?

// Good
function createUser(opts: {
  name: string;
  email: string;
  isAdmin?: boolean;
  active?: boolean;
}) { ... }
createUser({ name: 'Ada', email: 'ada@example.com', active: true });
```

Options objects also extend forwards-compatibly: adding a new optional field is
non-breaking.

---

## Required Before Optional

For positional parameters, all required ones come first. Don't intersperse:

```ts
// Bad
function load(id: string, opts?: Opts, version: number) { ... }   // illegal anyway

// Good
function load(id: string, version: number, opts?: Opts) { ... }
```

For options objects, mark optional with `?`. Default values go inside:

```ts
function paginate({ limit = 20, offset = 0 }: { limit?: number; offset?: number }) { ... }
```

---

## Default Parameters Beat `||`

```ts
// Bad
function greet(name) {
  name = name || 'friend';
  return `Hello, ${name}`;
}

// Good
function greet(name = 'friend') {
  return `Hello, ${name}`;
}
```

Defaults run only when the argument is `undefined`. `null` is passed through —
the function gets `null`, not the default. That's usually what you want.

---

## Rest Parameters, Not `arguments`

`arguments` is array-like, not an array, and is illegal in arrow functions and
strict mode in many contexts. Use rest parameters:

```ts
function sum(...values: number[]): number {
  return values.reduce((a, b) => a + b, 0);
}
```

---

## Pure Functions Where Possible

A pure function:

- Returns the same output for the same input.
- Doesn't mutate its arguments.
- Has no side effects (I/O, time, randomness).

Pure helpers compose, are trivial to test, and don't surprise reviewers. Move
impure operations (DB, HTTP, `Date.now()`) to the edges.

```ts
// Bad — mutates input
function withTotal(cart: Cart) {
  cart.total = cart.items.reduce((a, b) => a + b.price, 0);
  return cart;
}

// Good — returns new
function withTotal(cart: Cart): Cart {
  const total = cart.items.reduce((a, b) => a + b.price, 0);
  return { ...cart, total };
}
```

---

## Function Length

Aim for under ~30 lines. If a function has 8 locals, 3 branches, and 2 loops,
extract pieces. Long functions hide bugs and resist testing.

A function should do one thing at one level of abstraction. If you find
yourself writing comments like `// Step 2:` inside a function, those steps want
to be named helpers.

---

## Return Early, Return Once Doesn't Apply

The old "single return point" rule comes from C. In TypeScript / Node, multiple
returns improve readability when each handles a different case:

```ts
function classify(score: number): Grade {
  if (score >= 90) return 'A';
  if (score >= 80) return 'B';
  if (score >= 70) return 'C';
  return 'F';
}
```

---

## Overloads vs Generics vs Unions

Reach for overloads only when the return type **truly** depends on the input
type and the relationship isn't a simple generic.

```ts
// Good — generic suffices
function identity<T>(x: T): T { return x; }

// Good — overloads, return depends on the literal input
function parse(input: string): string;
function parse(input: number): number;
function parse(input: string | number): string | number {
  return input;
}
```

If overloads grow beyond 3, the API is probably mis-designed. Consider splitting
into separate named functions.

---

## Async Functions Return Promises

An `async` function always returns a `Promise<T>`. Annotate as `Promise<T>`,
not `T`:

```ts
// Good
async function getUser(id: string): Promise<User> { ... }
```

Don't `await` a value just to wrap it — `async` already does. And don't write
`function foo(): Promise<T>` without `async` unless you have a reason (e.g.
returning an existing promise as-is).

---

## Quick Reference

| Question | Default |
|---|---|
| Arrow or `function`? | `function` for declarations, arrow for callbacks |
| How many positional args? | ≤ 3 |
| More args? | Options object |
| Annotate return type? | Yes for exported |
| Default value? | Parameter default, not `\|\|` |
| Pure or impure? | Pure unless I/O required |
| Length? | Under ~30 lines |

## Related Skills

- **Style core**: See [node-style-core](../node-style-core/SKILL.md) for the broader style baseline.
- **Types**: See [node-types](../node-types/SKILL.md) for generics, overload patterns, and `satisfies`.
- **Async**: See [node-async](../node-async/SKILL.md) for promise-returning function design.
- **Naming**: See [node-naming](../node-naming/SKILL.md) for function names (verbs, predicates).
- **Documentation**: See [node-documentation](../node-documentation/SKILL.md) for JSDoc/TSDoc on signatures.
