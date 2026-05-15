---
name: node-style-core
description: Use when working with Node.js or TypeScript formatting, line length, nesting, early returns, semicolons, trailing commas, or core style principles. Also use when a style question isn't covered by a more specific skill, even if the user doesn't reference a specific style rule. Does not cover domain-specific patterns like error handling, naming, or testing (see specialized skills). Acts as fallback when no more specific style skill applies.
license: Apache-2.0
metadata:
  sources: "Airbnb JavaScript Style Guide, Google TypeScript Style Guide, Standard.js, Prettier defaults"
---

# Node.js Style Core Principles

## Style Principles (Priority Order)

When writing readable Node.js / TypeScript code, apply these principles in order of importance:

1. **Clarity** — Can a reader understand the code without extra context?
2. **Simplicity** — Is this the simplest way to accomplish the goal?
3. **Concision** — Does every line earn its place?
4. **Maintainability** — Will this be easy to modify later?
5. **Consistency** — Does it match surrounding code and project conventions?

> Read [references/PRINCIPLES.md](references/PRINCIPLES.md) when resolving conflicts between clarity, simplicity, and concision, or when you need concrete examples of how each principle applies in real TS code.

---

## Formatting

Run **Prettier** — no exceptions. The team disagreement about quote style, trailing
commas, and semicolons is solved by adopting Prettier defaults and committing the
config. Prettier handles line wrapping; ESLint enforces semantic style. Configure
print width to **100** unless the team has a documented reason to differ.

```jsonc
// .prettierrc
{
  "printWidth": 100,
  "singleQuote": true,
  "trailingComma": "all",
  "semi": true,
  "arrowParens": "always"
}
```

Do not wrap a long line just to satisfy a column limit — refactor it. A line that
needs to be 140 chars to express its intent is usually a sign that the expression
should be extracted into a named local.

> Read [references/FORMATTING.md](references/FORMATTING.md) when configuring Prettier and ESLint together, choosing print width, applying trailing commas, or deciding between single/double quote style.

---

## Reduce Nesting

Handle error cases and special conditions first. Return early or continue the loop
to keep the "happy path" unindented.

```ts
// Bad: Deeply nested
for (const v of data) {
  if (v.f1 === 1) {
    const processed = process(v);
    try {
      processed.call();
      processed.send();
    } catch (err) {
      throw err;
    }
  } else {
    log.warn({ v }, 'invalid v');
  }
}

// Good: Flat with early continue
for (const v of data) {
  if (v.f1 !== 1) {
    log.warn({ v }, 'invalid v');
    continue;
  }
  const processed = process(v);
  await processed.call();
  processed.send();
}
```

### Unnecessary Else

If a variable is set in both branches, use default + override.

```ts
// Bad
let a: number;
if (b) a = 100;
else a = 10;

// Good
let a = 10;
if (b) a = 100;
```

Prefer `const` over `let`. Reach for `let` only when reassignment is genuinely
needed; `let` in the body of a function is a signal worth a second look.

---

## Semicolons and ASI

Always write semicolons. Prettier inserts them by default and the Standard.js
"no semicolons" position depends on understanding the small set of statements
that need a leading `;` (lines starting with `(`, `[`, `/`, `+`, `-`, `` ` ``).
The cost of remembering that is higher than the cost of typing `;`.

---

## Equality and Type Coercion

Use `===` / `!==`. The only sanctioned `==` is `x == null` to match both `null`
and `undefined`, and even that is better written as
`x === null || x === undefined` in TypeScript where the narrowing helps the
checker.

```ts
// Bad
if (count == 0) { ... }
if (value != null) { ... }

// Good
if (count === 0) { ... }
if (value !== null && value !== undefined) { ... }
```

---

## Strings, Templates, and Multiline

Prefer template literals over string concatenation. Use single quotes for plain
strings (Prettier default) and template literals when interpolating or spanning
lines. Don't escape unnecessarily.

```ts
// Bad
const msg = 'user ' + name + ' failed login at ' + ts;

// Good
const msg = `user ${name} failed login at ${ts}`;
```

---

## File Layout

One module = one file. Each file:

1. Imports (grouped: node built-ins, third-party, internal).
2. Type definitions used only in this file.
3. Constants.
4. Implementation.
5. Default export (if any) at the bottom — but prefer named exports.

Keep files under ~300 lines as a rough heuristic. A 1000-line file is almost
always two or three files in disguise.

---

## TypeScript Strictness

Turn on `strict: true` in `tsconfig.json` and keep it on. Add
`noUncheckedIndexedAccess`, `noImplicitOverride`, and `exactOptionalPropertyTypes`
on greenfield code. Suppressing the checker with `as any`, `@ts-ignore`, or
non-null `!` should be rare and commented.

```ts
// Bad
const user = data as any;

// Good — refine the type
const user = userSchema.parse(data); // zod
```

---

## Quick Reference

| Principle | Key Question |
|-----------|--------------|
| Clarity | Can a reader understand what and why? |
| Simplicity | Is this the simplest approach? |
| Concision | Is the signal-to-noise ratio high? |
| Maintainability | Can this be safely modified later? |
| Consistency | Does this match surrounding code? |

## Related Skills

- **Naming conventions**: See [node-naming](../node-naming/SKILL.md) when picking identifier names or file names.
- **Modules and imports**: See [node-modules](../node-modules/SKILL.md) when ordering imports or choosing ESM vs CJS.
- **Type usage**: See [node-types](../node-types/SKILL.md) when designing types, interfaces, or generics.
- **Error flow**: See [node-error-handling](../node-error-handling/SKILL.md) when structuring guard clauses.
- **Documentation**: See [node-documentation](../node-documentation/SKILL.md) when writing JSDoc/TSDoc.
- **Linting**: See [node-linting](../node-linting/SKILL.md) when configuring ESLint and Prettier together.
- **Code review**: See [node-code-review](../node-code-review/SKILL.md) when applying style principles during a systematic PR review.
