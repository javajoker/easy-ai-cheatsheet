---
name: node-modules
description: Use when working with Node.js module systems — choosing between ESM and CommonJS, ordering imports, designing package.json `exports`, deciding between named and default exports, organizing barrel files, or resolving subpath imports. Also use when migrating a package from CJS to ESM. Does not cover TypeScript type imports specifically (see node-types).
license: Apache-2.0
compatibility: ESM examples target Node 20+. CJS interop notes apply to Node 16+.
metadata:
  sources: "Node.js docs, TC39 modules spec, Google TypeScript Style Guide"
---

# Node.js Modules and Imports

## ESM vs CommonJS

**Default to ESM** for new code. CommonJS remains for legacy and a few tools that
require it. Set `"type": "module"` in `package.json` and use `.js` (or `.ts`)
extensions in import paths — ESM resolution requires them.

```jsonc
// package.json
{
  "type": "module",
  "exports": {
    ".": "./dist/index.js",
    "./client": "./dist/client.js"
  }
}
```

```ts
// ESM
import { readFile } from 'node:fs/promises';
import { UserService } from './user-service.js';

// CJS — only when ESM is not an option
const { readFile } = require('node:fs/promises');
```

When importing a Node built-in, prefer the `node:` prefix
(`node:fs`, `node:path`, `node:crypto`). It disambiguates from user packages and
is the documented Node convention.

---

## Import Ordering

Group imports in three blocks, separated by a blank line:

1. Node built-ins (`node:fs`, `node:path`).
2. Third-party packages (`react`, `zod`, `fastify`).
3. Internal modules (relative paths, or absolute via path aliases).

Within each group, sort alphabetically. Let ESLint enforce this
(`eslint-plugin-import` rule `import/order`) rather than relying on memory.

```ts
import { readFile } from 'node:fs/promises';
import { join } from 'node:path';

import { z } from 'zod';
import Fastify from 'fastify';

import { UserService } from './user-service.js';
import { config } from '../config.js';
```

Type-only imports go in the same groups but use `import type` so they're erased
at runtime:

```ts
import type { FastifyInstance } from 'fastify';
import type { User } from './user.js';
```

---

## Named vs Default Exports

**Prefer named exports.** They:

- Match the import name to the export name (refactor-safe).
- Allow auto-import to suggest the canonical name.
- Compose cleanly with tree-shaking.

```ts
// Good
export class UserRepository { ... }
export function makeUser(...) { ... }

// Import side reads naturally
import { UserRepository, makeUser } from './user-repository.js';
```

Use `export default` only when:

- The module's single purpose is one value (React component, route handler).
- A framework expects it (e.g. some bundlers and Next.js conventions).

Never mix `export default` and named exports in the same file — pick one shape.

---

## Barrel Files (`index.ts`)

A `directory/index.ts` re-exports the directory's public API. Use them sparingly:

```ts
// src/user/index.ts
export { UserRepository } from './user-repository.js';
export { UserService } from './user-service.js';
export type { User, UserId } from './user.js';
```

**Watch out:**

- Barrel files can defeat tree-shaking in some bundlers if they pull in
  side-effect-heavy submodules.
- Circular imports become easy to introduce — `a` imports `b/index.ts`, which
  re-exports `a`'s type.

If a barrel re-exports everything from a directory, prefer explicit re-exports
over `export * from './foo.js';` so removing a symbol is a visible change.

---

## Path Aliases vs Relative Imports

Inside `src/`:

- Short hops (one or two `..`): use relative imports.
- Cross-feature reach (three+ `..`, or jumping into a sibling tree): use a
  path alias.

```jsonc
// tsconfig.json
{
  "compilerOptions": {
    "paths": {
      "@app/*": ["src/*"]
    }
  }
}
```

```ts
// Good
import { config } from '../config.js';                // close
import { UserService } from '@app/user/index.js';     // far

// Bad
import { UserService } from '../../../../user/index.js';
```

Ensure the runtime resolves aliases too (e.g. `tsx`, `vitest`, the bundler) —
not just the type-checker.

---

## Subpath Exports

In a publishable package, use `exports` instead of `main` to control which paths
are public:

```jsonc
{
  "exports": {
    ".": "./dist/index.js",
    "./types": "./dist/types.js",
    "./package.json": "./package.json"
  }
}
```

This prevents consumers from reaching into `dist/internal/...` and forming
implicit contracts on private files. Add `"./package.json"` so tools that need
it can still resolve it.

---

## Side-Effectful Imports

Modules that mutate global state on import (polyfills, monkey-patches,
`reflect-metadata`) should be imported once, at the top of the entry point, and
marked clearly:

```ts
// src/main.ts — top of file
import 'reflect-metadata';        // side-effect import
import './otel-init.js';          // OpenTelemetry bootstrap

import { startServer } from './server.js';
```

Mark side-effect imports in `package.json` with `"sideEffects": ["./dist/otel-init.js"]`
so bundlers don't drop them.

---

## `require` Inside ESM (and vice versa)

In ESM, you can use `createRequire` to load a CJS package that has no ESM build:

```ts
import { createRequire } from 'node:module';
const require = createRequire(import.meta.url);
const legacy = require('legacy-cjs-only-pkg');
```

In CJS, dynamically import an ESM package with `await import('...')` inside an
async function — top-level await is ESM-only.

---

## Quick Reference

| Question | Default |
|---|---|
| ESM or CJS? | ESM for new code |
| Built-in import path | `node:fs` over `fs` |
| Default or named? | Named |
| File extension in imports | `.js` (yes, even from `.ts`) |
| Import order tooling | `eslint-plugin-import` `import/order` |
| Barrel file pattern | Explicit re-exports, not `*` |

## Related Skills

- **Naming**: See [node-naming](../node-naming/SKILL.md) for filename conventions that interact with module paths.
- **Types**: See [node-types](../node-types/SKILL.md) for `import type` and `verbatimModuleSyntax`.
- **Linting**: See [node-linting](../node-linting/SKILL.md) for `import/order` and `@typescript-eslint/consistent-type-imports`.
- **Code review**: See [node-code-review](../node-code-review/SKILL.md) when reviewing module boundary changes in a PR.
