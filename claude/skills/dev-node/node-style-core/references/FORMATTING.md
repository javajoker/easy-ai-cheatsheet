# Formatting Reference

## Tooling Decision

Run **Prettier**. Configure once; commit the config. Don't argue about
quote style or comma trailing in code review — the formatter decides.

```jsonc
// .prettierrc
{
  "printWidth": 100,
  "singleQuote": true,
  "trailingComma": "all",
  "semi": true,
  "arrowParens": "always",
  "endOfLine": "lf"
}
```

```
# .prettierignore
dist
coverage
*.lock
build
```

Install in CI:

```bash
npx prettier --check .
```

Make Prettier run on save in editors. The first time the team adopts it,
make a separate "Apply prettier" commit so logic diffs stay clean.

## Print Width

| Choice | When |
|---|---|
| 80 | Conservative; works on side-by-side diffs |
| 100 | Recommended default for new projects |
| 120 | Wide monitors, modern teams |
| > 120 | Rare; horizontal scrolling territory |

Pick once. Refactor for readability when a line wants to be longer — don't
just disable the rule.

## Quote Style

Prettier defaults to double quotes; the JS community has converged on
single. Pick one:

```ts
// Single — JS-community default
const greeting = 'hello';
const quoted = `she said "hello"`;

// Double — older JS, Prettier default
const greeting = "hello";
const quoted = 'she said "hello"';
```

Set `singleQuote: true` if you prefer single. Either is fine; consistency
matters.

## Semicolons

Always write them. Standard.js's "no semicolons" position requires the
team to remember the small set of lines that need a leading `;`. The cost
is higher than the cost of typing `;`.

```ts
// Good
const x = 1;
function foo() {
  return 1;
}

// Bad — requires leading ; on some lines
const x = 1
;(function () { ... }())
```

## Line Breaks in Long Expressions

Break by semantics, not by column:

```ts
// Bad — break to fit width
const result = compute(arg1, arg2,
    arg3,
    arg4, arg5);

// Good — Prettier wraps cleanly
const result = compute(
  arg1,
  arg2,
  arg3,
  arg4,
  arg5,
);
```

For method chains:

```ts
const emails = users
  .filter((u) => u.isActive)
  .map((u) => u.email)
  .filter((e) => !e.includes('@example.com'));
```

Prettier handles all of this. Don't fight the formatter.

## Trailing Commas

`trailingComma: "all"` — including function parameters. The reasons:

- Cleaner diffs when adding a new last element.
- Compatible with modern Node and all browsers since 2017.

```ts
// Good
const config = {
  port: 3000,
  host: 'localhost',
  timeout: 5000,
};

function fetch(
  url: string,
  options: FetchOptions,
  signal: AbortSignal,
) { ... }
```

## ESLint Style Rules Overlap

ESLint has style rules (`semi`, `quotes`, `indent`) that overlap with
Prettier. Disable them with `eslint-config-prettier`:

```js
// eslint.config.js — last in the chain
import prettierConfig from 'eslint-config-prettier';

export default [
  // ... other configs
  prettierConfig,
];
```

Now ESLint owns *semantics* (unused vars, type errors, bug patterns) and
Prettier owns *style*.

## Editor Config

Add `.editorconfig` for editor-level settings the formatter doesn't cover
(line endings, charset):

```
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.{js,ts,tsx,jsx,json,yml,yaml,md}]
indent_style = space
indent_size = 2

[Makefile]
indent_style = tab
```

Most editors auto-apply `.editorconfig`. No extra plugin needed in modern
VS Code / IntelliJ / Neovim.

## CI Check

```yaml
- name: Format check
  run: npx prettier --check .
```

If Prettier finds unformatted files, the build fails. Local hook
(`lint-staged` + Husky) prevents the bad commit in the first place.

```jsonc
// package.json
{
  "lint-staged": {
    "*.{ts,tsx,js,jsx,json,md}": "prettier --write"
  }
}
```
