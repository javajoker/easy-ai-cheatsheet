---
name: node-types
description: Use when working with TypeScript types in a Node.js project — designing interfaces vs type aliases, writing generics, narrowing unknown/any, using `satisfies`, modeling discriminated unions, or applying utility types (Pick, Omit, Partial, Readonly). Also use when reviewing type annotations or eliminating `any` from a codebase.
license: Apache-2.0
compatibility: TypeScript 5.0+ (uses `satisfies`, `const` type parameters).
metadata:
  sources: "Google TypeScript Style Guide, Microsoft TypeScript coding guidelines, type-challenges canon"
---

# TypeScript Types (Node.js Context)

## Strictness Baseline

Turn on `strict: true`. Treat the following extra flags as non-negotiable on
greenfield projects:

```jsonc
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "exactOptionalPropertyTypes": true,
    "noImplicitOverride": true,
    "noFallthroughCasesInSwitch": true,
    "verbatimModuleSyntax": true
  }
}
```

`noUncheckedIndexedAccess` is the single biggest correctness gain — `arr[0]`
becomes `T | undefined` and you must narrow before use.

---

## `interface` vs `type`

| Use | Reach for |
|---|---|
| Object shape that may be extended later | `interface` |
| Union, tuple, mapped, conditional | `type` |
| Public API of a library | `interface` (better error messages, declaration merging if needed) |

```ts
interface User {
  id: string;
  email: string;
}

type Status = 'pending' | 'active' | 'archived';
type WithTimestamp<T> = T & { createdAt: Date };
```

Pick one shape per concept. Don't randomly mix `type Foo = { ... }` and
`interface Foo { ... }` across the same domain.

---

## `any` and `unknown`

`any` is the type system's escape hatch — it disables checking. `unknown` is the
type system's "I don't know yet" — it forces you to narrow before use.

```ts
// Bad
function parse(input: any) {
  return input.toUpperCase();   // no check, runtime explosion possible
}

// Good
function parse(input: unknown): string {
  if (typeof input !== 'string') throw new TypeError('expected string');
  return input.toUpperCase();
}
```

When `any` is genuinely required (interop with an untyped lib), isolate it to a
single helper and convert immediately:

```ts
function toUser(raw: unknown): User {
  return userSchema.parse(raw);   // zod / valibot
}
```

---

## Discriminated Unions for State

Model state as a discriminated union, not as a struct with a string `kind` and
optional fields. The checker can then narrow exhaustively.

```ts
// Bad: many optional fields, fragile
interface Result {
  status: 'ok' | 'error' | 'pending';
  data?: User;
  error?: string;
}

// Good
type Result =
  | { status: 'pending' }
  | { status: 'ok'; data: User }
  | { status: 'error'; error: string };

function render(r: Result) {
  switch (r.status) {
    case 'pending': return null;
    case 'ok':      return r.data.email;   // narrowed
    case 'error':   return r.error;        // narrowed
  }
}
```

For exhaustiveness, end the switch with an `assertNever` helper:

```ts
function assertNever(x: never): never {
  throw new Error(`unhandled variant: ${JSON.stringify(x)}`);
}
```

---

## `satisfies` for Inferred Literal Types

Use `satisfies` when you want the value's inferred type to remain narrow but
also want to check that it conforms to a wider contract.

```ts
type RouteConfig = Record<string, { method: 'GET' | 'POST' }>;

// Annotated: methods widen to 'GET' | 'POST'
const routesA: RouteConfig = {
  users: { method: 'GET' },
};
const m: 'GET' = routesA.users.method;   // error: too wide

// satisfies: methods stay literal
const routesB = {
  users: { method: 'GET' },
} satisfies RouteConfig;
const m2: 'GET' = routesB.users.method;  // ok
```

---

## Generics: Constrain, Don't Open

A generic without a constraint is rarely what you want. Constrain to the shape
you actually depend on.

```ts
// Bad
function pick<T, K>(obj: T, keys: K[]): unknown {
  return Object.fromEntries(keys.map((k) => [k, (obj as any)[k]]));
}

// Good
function pick<T extends object, K extends keyof T>(obj: T, keys: K[]): Pick<T, K> {
  const out = {} as Pick<T, K>;
  for (const k of keys) out[k] = obj[k];
  return out;
}
```

Name parameters meaningfully when there's more than one (`TInput`, `TOutput`,
`TRow`). Single-parameter generics can stay `T`.

---

## Utility Types: Compose, Don't Duplicate

Reach for these before writing a parallel type by hand:

| Utility | Use |
|---|---|
| `Pick<T, K>` | Subset of fields |
| `Omit<T, K>` | All fields except some |
| `Partial<T>` | All optional (e.g. update DTO) |
| `Required<T>` | Inverse of `Partial` |
| `Readonly<T>` | Freeze at the type level |
| `Awaited<P>` | Unwrap a Promise |
| `ReturnType<F>` / `Parameters<F>` | Reflect a function type |
| `NonNullable<T>` | Strip `null` / `undefined` |

```ts
type User = { id: string; email: string; password: string };
type PublicUser = Omit<User, 'password'>;
type UserPatch = Partial<Pick<User, 'email'>>;
```

---

## Type Imports

Use `import type` for type-only imports — required when `verbatimModuleSyntax`
is on, and removes the import from the emitted JS.

```ts
import type { FastifyInstance } from 'fastify';
import { z } from 'zod';
```

If you import both runtime and type from the same module:

```ts
import { type Logger, createLogger } from './logging.js';
```

---

## Branding for Nominal Identity

TypeScript is structural by default. When two `string` types must not be
interchangeable (`UserId` vs `OrderId`), brand them:

```ts
declare const userIdBrand: unique symbol;
export type UserId = string & { readonly [userIdBrand]: never };

function asUserId(s: string): UserId {
  return s as UserId;
}
```

Reserve this for genuinely error-prone domains (IDs of different entities,
opaque tokens). Don't brand every primitive.

---

## Quick Reference

| Need | Reach for |
|---|---|
| Object shape | `interface` |
| Union / mapped | `type` |
| Unknown JSON input | `unknown` + zod / valibot |
| Multi-state value | discriminated union + `assertNever` |
| Keep inferred literal | `satisfies` |
| Subset of fields | `Pick` / `Omit` |
| Nominal ID | branded string |

## Related Skills

- **Style core**: See [node-style-core](../node-style-core/SKILL.md) for the strictness baseline.
- **Modules**: See [node-modules](../node-modules/SKILL.md) for `import type` and `verbatimModuleSyntax`.
- **Functions**: See [node-functions](../node-functions/SKILL.md) for parameter and return type design.
- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for typed errors.
- **Data structures**: See [node-data-structures](../node-data-structures/SKILL.md) for `ReadonlyArray` and `ReadonlyMap`.
- **Linting**: See [node-linting](../node-linting/SKILL.md) for `@typescript-eslint` type-aware rules.
