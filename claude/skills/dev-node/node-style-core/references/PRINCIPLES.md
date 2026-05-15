# Style Principles Reference

The five priority principles for Node.js / TypeScript style, in the order
they apply when they conflict.

## 1. Clarity

The code's purpose and rationale must be clear to a reader who is not the
author.

- Descriptive names over short names.
- Comment *why*, not *what*.
- View clarity through the reader's lens, not the author's.
- Code is read many more times than it is written.

```ts
// Good — clear purpose, sensible name
async function chargeCustomer(customerId: string, amountCents: number): Promise<ChargeId> { ... }

// Bad — unclear, repeats noun, mixes intent
async function chargeChargeForCustomer(custId: string, amt: number): Promise<string> { ... }
```

## 2. Simplicity

Code should accomplish goals in the simplest way possible.

Simple code:

- Reads top to bottom without surprise.
- Doesn't assume prior knowledge of clever idioms.
- Has no unnecessary abstraction.
- May be mutually exclusive with "clever" code.

### Least Mechanism

When several mechanisms can express the same idea, prefer the most standard:

1. Native JS / TS constructs (`for...of`, `Array.map`, `Map`, `Set`).
2. Standard library (`node:fs`, `node:url`, `node:crypto`).
3. Well-known third-party (`zod`, `fastify`).
4. Rolling your own — only when 1, 2, and 3 don't suffice.

```ts
// Good — native, idiomatic
const ids = users.map((u) => u.id);

// Bad — reach for lodash for something native does
import _ from 'lodash';
const ids = _.map(users, 'id');
```

## 3. Concision

High signal-to-noise ratio.

- Avoid repetition.
- Avoid extraneous syntax.
- Avoid unnecessary abstraction layers.

```ts
// Good — flat, signal-only
if (!user.isActive) throw new InactiveUserError(user.id);

// Bad — same content, more noise
if (user.isActive === false) {
  throw new InactiveUserError({ id: user.id });
}
```

Concision is about the *useful* bytes. A confusing one-liner is not
concise.

## 4. Maintainability

Code is modified many more times than it is written.

Maintainable code:

- Has APIs that grow gracefully.
- Uses predictable names — the same concept gets the same name everywhere.
- Minimizes coupling and hidden dependencies.
- Has tests with clear diagnostics.

```ts
// Bad — critical detail (return type) hidden
const result = await fetchUser(id);

// Good — explicit return type on the function declaration documents the API
async function fetchUser(id: string): Promise<User> { ... }
const result = await fetchUser(id);   // result is User by IDE / checker
```

## 5. Consistency

Code should look and behave like similar code in the codebase.

- Package-level consistency is most important.
- When two principles tie, break in favor of consistency.
- Never override documented style principles for consistency.

If the project uses `function` declarations and your new file uses arrow
constants, the new file is the odd one out — and the reader pays the cost.

## Resolving Conflicts

When two principles disagree:

| Conflict | Wins |
|---|---|
| Clarity vs Simplicity | Clarity |
| Clarity vs Concision | Clarity |
| Simplicity vs Concision | Simplicity |
| Any principle vs Consistency | The principle |
| Concision vs Maintainability | Maintainability |
| Consistency within file vs across project | Project |

When in doubt, ask: "If I came back to this code in six months without
context, would I understand it?"
