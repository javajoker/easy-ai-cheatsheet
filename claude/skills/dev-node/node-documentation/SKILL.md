---
name: node-documentation
description: Use when writing or reviewing in-code documentation in Node.js / TypeScript — JSDoc / TSDoc comments, README sections, public API docs, examples, or `@deprecated` markers. Also use when deciding what to document and what to leave to the type signature.
license: Apache-2.0
metadata:
  sources: "TSDoc spec, JSDoc reference, Microsoft API Extractor conventions"
allowed-tools: Bash(bash:*)
---

# Node.js / TypeScript Documentation

## Available Scripts and Assets

- **`scripts/check-docs.sh`** — Scans `.ts`/`.tsx` files for exported declarations (function, class, interface, type, const, enum) that lack a TSDoc comment immediately above. Run `bash scripts/check-docs.sh --help` for options.
- **`assets/doc-template.ts`** — Canonical TSDoc shapes for module, function, interface, options object, and `@deprecated`. Copy when scaffolding the documentation for a new module.

## What to Document

The compiler already documents *what* and *what types*. Documentation
contributes:

- **Why** the function exists (when the name + signature don't say it).
- **When** to use it vs another function (trade-offs).
- **Constraints** that the type system can't express (units, ranges, ordering
  guarantees, side effects).
- **Examples** for non-obvious call sites.

Don't document:

- A getter named `email` that returns the email.
- A constructor whose parameters are already named.
- A type alias that's a transparent re-export.

```ts
// Bad — repeats the name
/** Get the user by id. */
function getUserById(id: string): Promise<User> { ... }

// Good — adds why and constraints
/**
 * Loads the user from the primary database.
 *
 * @throws {NotFoundError} If no user matches the id.
 * @remarks Bypasses the read-replica cache; use `getUserById` from
 *   `cached-repo.ts` when stale data is acceptable.
 */
function getUserByIdFromPrimary(id: string): Promise<User> { ... }
```

---

## TSDoc Tag Reference

Standard tags worth knowing:

| Tag | Purpose |
|---|---|
| `@param name - desc` | Parameter description |
| `@returns desc` | Return value description |
| `@throws {Type} desc` | Errors that can be thrown |
| `@example` | Followed by a fenced code block |
| `@remarks` | Additional notes that don't fit the summary |
| `@see` | Reference another symbol or URL |
| `@deprecated reason` | Mark as deprecated; mention the replacement |
| `@internal` | Excluded from public API (API Extractor) |
| `@beta` / `@alpha` | Stability marker |
| `@defaultValue` | Default for an option |

```ts
/**
 * Charges the customer for the given amount.
 *
 * @param customerId - Stripe customer ID.
 * @param amountCents - Amount in cents; must be ≥ 50 (Stripe minimum).
 * @returns The Stripe charge ID on success.
 * @throws {InsufficientFundsError} When the card was declined.
 * @example
 * ```ts
 * const id = await charge('cus_123', 1500);
 * ```
 */
export async function charge(customerId: string, amountCents: number): Promise<string> { ... }
```

---

## Summary Line First

The first sentence is the summary — keep it under ~80 characters. Tools (IDE
hover, generated docs) display it standalone.

```ts
// Bad
/**
 * This function takes a user id and a tenant id and looks up
 * the user in the database, returning the user object.
 */

// Good
/** Loads a user by id within a tenant scope. */
```

Subsequent paragraphs go below; separate with a blank `*`.

---

## Document the Edge of Your Module

For an internal module, document the **exported** symbols. Private helpers
inside the same file usually don't need a doc comment — the name and the
surrounding usage say enough.

Exception: a private helper whose body is non-obvious (algorithm, workaround,
constraint) deserves a short comment explaining why.

```ts
// internal helper — short prose comment is fine
// Walks the prototype chain to detect __proto__ before structured clone runs.
function isPollutedShape(o: object): boolean { ... }

// Exported API — full TSDoc
/**
 * Validates and normalizes a user-supplied configuration object.
 *
 * @throws {ConfigError} On schema violations.
 */
export function normalizeConfig(input: unknown): Config { ... }
```

---

## `@deprecated` Mentions the Replacement

```ts
/**
 * @deprecated Use {@link getUserById} instead. Will be removed in v3.
 */
export function fetchUser(id: string): Promise<User> { ... }
```

Without a replacement pointer, callers have nowhere to go. IDEs render
`@deprecated` with strikethrough, which makes the migration discoverable.

---

## Examples Run in IDE Hover

A short `@example` block is the most useful TSDoc tag you can add. IDEs
display it on hover; readers don't have to navigate to a docs site.

```ts
/**
 * Builds a URL with query parameters.
 *
 * @example
 * ```ts
 * buildUrl('/users', { page: 2 });
 * // → '/users?page=2'
 * ```
 */
function buildUrl(path: string, params: Record<string, string | number>): string { ... }
```

Keep examples to under ~5 lines. Anything longer belongs in a README or a
dedicated docs page.

---

## Don't Restate the Type

```ts
// Bad — duplicates the type
/** @param id - The string id of the user. @returns The user. */
function getUser(id: string): User { ... }

// Good — explains the meaning
/** @param id - Looks up the user by their public-facing slug, not the internal numeric id. */
function getUser(id: string): User { ... }
```

If the type alone is informative (most cases), skip the doc.

---

## Doc Comments and Inline Comments

| Comment | Where | What |
|---|---|---|
| `/** ... */` TSDoc | Above a declaration | Public-facing API documentation |
| `// inline` | Above a line | Non-obvious *why* of the code below |
| `// TODO(name): ...` | Above a line | Tracked deferred work |
| `// FIXME: ...` | Above a line | Known broken; replace ASAP |

Default to no inline comment. Add one only when removing it would confuse a
reader.

---

## README Sections

A package or service README answers, in order:

1. **What it is** — one sentence.
2. **Why it exists** — the problem it solves.
3. **Install / quick start** — minimal copy-pasteable example.
4. **Configuration** — env vars, config files.
5. **API surface** — main exports / endpoints; link to detailed docs.
6. **Development** — `npm install`, `npm test`, `npm run dev`.
7. **License**.

A README that opens with the install command is failing the reader. Lead with
"this is a library that ___".

---

## Public API Docs Generation

For libraries, a generated docs site (TypeDoc, API Extractor) gives consumers a
browseable surface.

```bash
npx typedoc --out docs src/index.ts
```

For services, generated OpenAPI from route schemas (Fastify swagger plugin) is
usually more valuable than narrative API docs.

---

## Quick Reference

| Question | Default |
|---|---|
| Document private helpers? | Only the non-obvious ones |
| Document exported API? | Yes, TSDoc with summary + tags |
| First line | Summary, under ~80 chars |
| `@example`? | Yes, when call shape isn't obvious |
| `@deprecated`? | Always with a replacement pointer |
| Restate the type? | No |
| Inline comments | Only for non-obvious *why* |

## Related Skills

- **Style core**: See [node-style-core](../node-style-core/SKILL.md) for comment defaults.
- **Naming**: See [node-naming](../node-naming/SKILL.md) — good names reduce the need for comments.
- **Types**: See [node-types](../node-types/SKILL.md) for types that document themselves.
- **Functions**: See [node-functions](../node-functions/SKILL.md) for signature shape.
- **Linting**: See [node-linting](../node-linting/SKILL.md) for TSDoc lint rules.
