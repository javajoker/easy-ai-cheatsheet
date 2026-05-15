---
name: node-classes
description: Use when designing or reviewing classes in Node.js/TypeScript — choosing class vs factory function, declaring private fields, applying readonly, defining accessors, using abstract classes, or implementing interfaces. Also use when refactoring inheritance into composition or replacing class inheritance with discriminated unions.
license: Apache-2.0
compatibility: ECMAScript private fields (`#field`) supported in Node 14+ / TS 4.3+.
metadata:
  sources: "TC39 class fields, Google TypeScript Style Guide, Composition over Inheritance principles"
---

# Node.js / TypeScript Classes

## Class or Factory Function?

A class makes sense when:

- The object has **identity** that callers depend on (a connection pool, a
  logger, a service).
- You'll want `instanceof` for narrowing (custom Errors).
- A framework expects it (NestJS, TypeORM, Mongoose, decorators).

A plain function or factory makes sense when:

- The value is pure data — give it a `type` or `interface`, not a class.
- The "class" has only static methods — use a module of exported functions.
- Composition is more natural than inheritance.

```ts
// Bad — static-only class
class StringUtils {
  static toKebab(s: string): string { ... }
  static toCamel(s: string): string { ... }
}

// Good — module of functions
export function toKebab(s: string): string { ... }
export function toCamel(s: string): string { ... }
```

---

## Constructor Parameter Properties (TypeScript)

When the constructor only assigns to fields, use parameter properties for less
boilerplate:

```ts
// Bad
class UserService {
  private readonly db: Database;
  private readonly logger: Logger;
  constructor(db: Database, logger: Logger) {
    this.db = db;
    this.logger = logger;
  }
}

// Good
class UserService {
  constructor(
    private readonly db: Database,
    private readonly logger: Logger,
  ) {}
}
```

Mark dependencies `readonly` — they shouldn't be reassigned at runtime.

---

## Private Fields: `#field` vs `private`

| Option | Truly private | Compile error on access | Reflectable |
|---|---|---|---|
| `private field` | No (compile-time only) | Yes | Yes — JS can still access |
| `#field` | Yes (runtime) | Yes | No |

Prefer ECMAScript `#fields` for new code. They're invisible to JS callers,
defeat accidental reflection, and survive transpilation. Use `private` when:

- The codebase is mixed and your team has standardized on it.
- A framework needs reflection (`reflect-metadata` decorators).

```ts
class Counter {
  #value = 0;
  increment() { this.#value++; }
  get value() { return this.#value; }
}
```

---

## Composition over Inheritance

A two-level `class A extends B` is sometimes useful. A three-level chain almost
never is — pull common behavior into helpers and inject it.

```ts
// Bad
class Animal { ... }
class Mammal extends Animal { ... }
class Dog extends Mammal { ... }

// Good — composition + interface
interface Walker { walk(): void; }
class Dog implements Walker {
  constructor(private readonly logger: Logger) {}
  walk() { ... }
}
```

Prefer `implements` (contract) over `extends` (mechanism) when the shared
behavior is just an API surface.

---

## `abstract class` is a Last Resort

An abstract class is useful when you genuinely want a partial implementation
that subclasses fill in. Most of the time, the same intent is cleaner with an
interface + composition, or a higher-order function.

```ts
// Acceptable
abstract class BaseHandler {
  protected abstract handle(req: Request): Promise<Response>;

  async run(req: Request) {
    const res = await this.handle(req);
    this.metrics.record(res.status);
    return res;
  }
}
```

If subclasses only differ in a single method, replace the class with a function
that takes that method as a parameter.

---

## Accessors: `get` / `set`

Use accessors when:

- You want a property that's actually computed (lazy total).
- You need to validate or transform on assignment.

Don't use accessors as no-op wrappers around a private field — exposing the
field directly is fine and clearer.

```ts
// Good — computed
class Cart {
  constructor(private readonly items: ReadonlyArray<Item>) {}
  get total() { return this.items.reduce((a, b) => a + b.price, 0); }
}

// Bad — no-op getter/setter pair
class User {
  #name: string;
  get name() { return this.#name; }
  set name(v) { this.#name = v; }
}
```

Accessors on the public API should be the same complexity as a field access —
no I/O, no throw. Anything heavier should be a method (`getX()`, `loadX()`).

---

## `static` Members

Use `static` for:

- Factory methods (`User.fromRow`, `User.empty`).
- Constants that conceptually belong to the type.

Don't use `static` for a hidden namespace ("StringUtils.toKebab") — that's a
module.

```ts
class User {
  static empty(): User { return new User('', ''); }
  static fromRow(row: Row): User { return new User(row.id, row.email); }
  constructor(public readonly id: string, public readonly email: string) {}
}
```

---

## Method Binding: Arrows on Methods?

Class methods bind `this` lexically only when written as arrow-function
properties. There's a trade-off:

- Arrow property: `this` is correct when you pass the method around, but the
  method is on the **instance**, not the prototype. Each instance allocates.
- Regular method: prototype-stored, cheap, but `this` is lost when passed
  unbound.

Best practice: regular methods, with explicit `.bind(this)` or arrow wrapper
at the call site:

```ts
class Server {
  constructor() {
    process.on('SIGTERM', () => this.shutdown());   // arrow at call site
  }
  shutdown() { ... }
}
```

Use arrow-property methods only when the method is a callback target many times
and `.bind(this)` would be noisy.

---

## Equality and Identity

JS classes use reference equality by default. If you need value equality, write
an explicit method:

```ts
class Money {
  constructor(public readonly amount: number, public readonly currency: string) {}
  equals(other: Money): boolean {
    return this.amount === other.amount && this.currency === other.currency;
  }
}
```

For value-shaped data that needs equality, often a plain type with a deepEqual
helper is simpler than a class.

---

## `instanceof` and Custom Errors

`instanceof` is the canonical way to match error subclasses (see
[node-error-handling](../node-error-handling/SKILL.md)). It works across module
boundaries only when both sides import the same class definition — beware
duplicated copies when bundlers de-dupe imperfectly.

---

## Quick Reference

| Question | Default |
|---|---|
| Class or factory? | Factory for pure data; class for identity |
| Private? | `#field` for new code |
| Inheritance depth? | ≤ 2 levels |
| Abstract class? | Last resort; usually replaceable |
| Accessors? | Only for computed / validated properties |
| Static methods? | Factories and constants |
| Method binding? | Regular method + bind at call site |

## Related Skills

- **Style core**: See [node-style-core](../node-style-core/SKILL.md) for class file layout.
- **Types**: See [node-types](../node-types/SKILL.md) for `interface` vs `class implements`.
- **Functions**: See [node-functions](../node-functions/SKILL.md) for factories vs classes.
- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for custom Error subclasses.
- **Documentation**: See [node-documentation](../node-documentation/SKILL.md) for JSDoc on class members.
