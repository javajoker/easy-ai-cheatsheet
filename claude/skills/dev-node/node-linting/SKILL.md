---
name: node-linting
description: Use when setting up, tuning, or troubleshooting ESLint and Prettier in a Node.js / TypeScript project — the flat config format, type-aware rules, the @typescript-eslint plugin, import ordering, integration with editors and CI, or migrating from the legacy `.eslintrc` to `eslint.config.js`. Also use when reviewing lint suppressions.
license: Apache-2.0
compatibility: ESLint 9+ flat config. typescript-eslint v8.
metadata:
  sources: "ESLint docs, typescript-eslint docs, Prettier docs"
allowed-tools: Bash(bash:*)
---

# Node.js Linting

## Available Scripts and Assets

- **`assets/eslint.config.mjs`** — Canonical ESLint 9 flat-config baseline with `typescript-eslint` strict-type-checked, import ordering, `consistent-type-imports`, `no-floating-promises`, naming-convention, and looser overrides for tests and config files.
- **`assets/prettierrc.json`** — Matching Prettier defaults (100 width, single quote, trailing comma, semicolons).
- **`scripts/setup-lint.sh`** — Installs the canonical lint stack (eslint, typescript-eslint, eslint-plugin-import, prettier, eslint-config-prettier) and copies the two configs into the project root. Supports `--pnpm`, `--yarn`, `--force`. Run `bash scripts/setup-lint.sh --help`.

## ESLint + Prettier, Each Doing Its Job

**Prettier** owns formatting (whitespace, line breaks, quote style). **ESLint**
owns semantics (unused vars, no-implicit-any, no-floating-promises). Don't
let them fight: install `eslint-config-prettier` to disable the ESLint rules
that conflict with Prettier.

```bash
npm i -D eslint @eslint/js typescript-eslint prettier eslint-config-prettier
```

---

## Flat Config (`eslint.config.js`)

ESLint 9's flat config replaces `.eslintrc.*` and `.eslintignore`. New projects
should use it; established `.eslintrc` repos are fine until a major upgrade
forces the change.

```js
// eslint.config.js
import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import importPlugin from 'eslint-plugin-import';
import prettierConfig from 'eslint-config-prettier';

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.strictTypeChecked,
  ...tseslint.configs.stylisticTypeChecked,
  importPlugin.flatConfigs.recommended,
  importPlugin.flatConfigs.typescript,
  {
    languageOptions: {
      parserOptions: {
        projectService: true,        // type-aware
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      '@typescript-eslint/no-floating-promises': 'error',
      '@typescript-eslint/consistent-type-imports': 'error',
      '@typescript-eslint/no-misused-promises': 'error',
      'import/order': ['error', {
        groups: ['builtin', 'external', 'internal', 'parent', 'sibling'],
        'newlines-between': 'always',
        alphabetize: { order: 'asc' },
      }],
    },
  },
  {
    files: ['**/*.test.ts', '**/*.spec.ts'],
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
    },
  },
  prettierConfig,                    // last — disables conflicting rules
);
```

`strictTypeChecked` is the safe default. Drop to `recommendedTypeChecked` if
the project is large and `strict` would create too much churn at once.

---

## Type-Aware Rules

Rules like `no-floating-promises` and `no-misused-promises` require
type-checker information. Configure the parser to read your `tsconfig.json`:

```js
languageOptions: {
  parserOptions: {
    projectService: true,                  // ESLint 9 / TS-ESLint 8 preferred
    tsconfigRootDir: import.meta.dirname,
  },
},
```

For monorepos with multiple tsconfigs, the projectService form discovers them
automatically. The older `project: ['./tsconfig.json']` array still works but
loads slower.

---

## High-Value Rules

Pick from this list. Each has saved a real bug.

| Rule | Catches |
|---|---|
| `@typescript-eslint/no-floating-promises` | Missed `await` |
| `@typescript-eslint/no-misused-promises` | `async` callbacks in `forEach`, sync-expecting positions |
| `@typescript-eslint/no-explicit-any` | `any` in committed code |
| `@typescript-eslint/consistent-type-imports` | `import type` for type-only imports |
| `@typescript-eslint/no-unused-vars` | Dead locals and imports |
| `@typescript-eslint/explicit-module-boundary-types` | Missing return types on exports |
| `@typescript-eslint/switch-exhaustiveness-check` | Missing case in discriminated-union switch |
| `@typescript-eslint/strict-boolean-expressions` | `if (x)` where `x` is nullable / number |
| `no-fallthrough` | Switch fallthrough without comment |
| `eqeqeq` | `==` instead of `===` |
| `prefer-const` | `let` that's never reassigned |
| `import/no-cycle` | Circular imports |
| `import/order` | Import order |
| `import/no-default-export` | Force named exports |
| `no-restricted-syntax` | Project-specific patterns (e.g. ban `process.env` outside `config.ts`) |

---

## Naming Convention Rule

`@typescript-eslint/naming-convention` enforces the cases from
[node-naming](../node-naming/SKILL.md). It's verbose; copy from a known good
config:

```js
'@typescript-eslint/naming-convention': [
  'error',
  { selector: 'default', format: ['camelCase'] },
  { selector: 'variable', format: ['camelCase', 'UPPER_CASE'] },
  { selector: 'parameter', format: ['camelCase'], leadingUnderscore: 'allow' },
  { selector: 'typeLike', format: ['PascalCase'] },
  { selector: 'enumMember', format: ['PascalCase'] },
  { selector: 'objectLiteralProperty', format: null },  // allow API field names
],
```

Don't tune this rule incrementally — get the team to agree once, then commit
the config.

---

## Prettier Config

Keep it minimal. Prettier's defaults are good; the team's bike-shed
preferences should fit on three lines.

```jsonc
// .prettierrc
{
  "printWidth": 100,
  "singleQuote": true,
  "trailingComma": "all"
}
```

```bash
# .prettierignore
dist
coverage
*.lock
```

---

## CI Integration

In CI, run lint and type-check separately:

```yaml
- run: npm ci
- run: npm run lint        # eslint .
- run: npm run typecheck   # tsc --noEmit
- run: npm run format:check # prettier --check .
- run: npm test
```

`tsc --noEmit` is the type-check; ESLint's type-aware rules use the same data
but don't fully replace it.

---

## Pre-commit Hooks

`lint-staged` runs the linters only on changed files — fast enough to run on
every commit.

```jsonc
// package.json
{
  "scripts": { "prepare": "husky" },
  "lint-staged": {
    "*.{ts,tsx,js}": ["eslint --fix", "prettier --write"],
    "*.{json,md,yml}": ["prettier --write"]
  }
}
```

```bash
# .husky/pre-commit
npx lint-staged
```

Don't block commits on full project lint — slow hooks get skipped with
`--no-verify`.

---

## Suppressing a Rule

Every `eslint-disable` comment should have a reason:

```ts
// Good
// eslint-disable-next-line @typescript-eslint/no-explicit-any -- third-party lib has no types
const sdk = require('weird-sdk') as any;

// Bad
// eslint-disable-next-line
const x: any = doThing();
```

Open suppressions accumulate technical debt. Run periodically:

```bash
grep -rn 'eslint-disable' src/ | wc -l
```

Trend it down.

---

## Migrating Legacy `.eslintrc`

`@eslint/migrate-config` converts most configs. The places you'll touch by
hand:

- `extends` arrays become spread imports.
- `parserOptions.project` becomes `projectService: true`.
- `overrides` becomes a separate config object in the array.
- Plugin shorthand strings become imported plugin objects.

---

## Quick Reference

| Tool | Role |
|---|---|
| Prettier | Formatting |
| ESLint | Semantics |
| `eslint-config-prettier` | Disable conflicting style rules |
| `typescript-eslint` | TS-aware rules |
| `eslint-plugin-import` | Import order + cycle detection |
| `lint-staged` + Husky | Pre-commit |
| `tsc --noEmit` | Type check (CI separate from ESLint) |

## Related Skills

- **Style core**: See [node-style-core](../node-style-core/SKILL.md) for the formatting principles Prettier enforces.
- **Naming**: See [node-naming](../node-naming/SKILL.md) for what `naming-convention` enforces.
- **Modules**: See [node-modules](../node-modules/SKILL.md) for `import/order`.
- **Types**: See [node-types](../node-types/SKILL.md) for `strictTypeChecked` rules.
- **Code review**: See [node-code-review](../node-code-review/SKILL.md) for when to push back on suppressions.
