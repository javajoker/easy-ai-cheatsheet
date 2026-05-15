---
name: node-naming
description: Use when naming variables, functions, classes, types, interfaces, files, or directories in Node.js or TypeScript code. Also use when reviewing identifier names for clarity, when resolving naming debates (interface I-prefix, file kebab-case vs camelCase), or when a name in a PR feels off. Does not cover module or import ordering (see node-modules).
license: Apache-2.0
metadata:
  sources: "Airbnb JavaScript Style Guide, Google TypeScript Style Guide, Microsoft TypeScript coding guidelines"
allowed-tools: Bash(bash:*)
---

# Node.js / TypeScript Naming

## Available Scripts

- **`scripts/check-naming.sh`** — Scans TS/JS files for naming-convention violations: interfaces with `I` prefix, types in lowercase or snake_case, Hungarian-style prefixes (`strFoo`, `arrFoo`). Run `bash scripts/check-naming.sh --help` for options. For stronger enforcement, configure `@typescript-eslint/naming-convention` (see [node-linting](../node-linting/SKILL.md)).

## Identifier Cases (Canonical Table)

| Kind | Case | Example |
|---|---|---|
| Variables, parameters, properties | `camelCase` | `userCount`, `lastLogin` |
| Functions, methods | `camelCase` | `getUser`, `serializePayload` |
| Classes, types, interfaces, enums | `PascalCase` | `UserRepository`, `Order`, `Status` |
| Type parameters (generics) | Single capital or `PascalCase` | `T`, `K`, `Value` |
| Module-level constants exposing config | `UPPER_SNAKE_CASE` | `DEFAULT_TIMEOUT_MS` |
| Files, directories | `kebab-case.ts` | `user-repository.ts` |
| Test files | `*.test.ts` or `*.spec.ts` | `user-repository.test.ts` |
| React components / Vue SFCs | `PascalCase.tsx` / `.vue` | `UserCard.tsx` |
| Booleans (vars, props) | `is`/`has`/`can`/`should` prefix | `isActive`, `hasAccess` |

Project consistency wins over personal preference. If the codebase uses
`camelCase.ts` filenames, match it. The naming rules below apply *within* whatever
file-case convention the project chose.

---

## No Hungarian, No Type-Encoding

Names describe **meaning**, not **type**. The compiler knows the type.

```ts
// Bad
const sName: string = 'alice';
const arrUsers: User[] = [];
const oConfig = { ... };

// Good
const name = 'alice';
const users: User[] = [];
const config = { ... };
```

### No `I` Prefix on Interfaces

This is settled in the modern TypeScript community: do **not** prefix interfaces
with `I`. The user of a type should not have to know whether it is implemented as
an `interface` or a `type` alias.

```ts
// Bad
interface IUserRepository { ... }

// Good
interface UserRepository { ... }
```

---

## No Redundant Repetition

Don't repeat the package, file, class, or property in identifier names within
that same scope.

```ts
// Bad — inside user-repository.ts
class UserRepository {
  userRepositoryFind(userRepositoryId: string) { ... }
}

// Good
class UserRepository {
  find(id: string) { ... }
}
```

When the surrounding scope already says "user", saying it again is noise:
`user.userName` should be `user.name`.

---

## Booleans Read Like Predicates

A boolean's name should let the calling code read as English.

```ts
if (user.isActive) { ... }
if (cart.hasItems()) { ... }
if (request.canRetry) { ... }
```

Avoid negative-form booleans (`isNotReady`, `hasNoUsers`) — they invert at the
call site (`if (!user.isNotReady)`) and become confusing. Flip the name.

---

## Functions Read Like Verbs

| Verb stem | When |
|---|---|
| `get` / `fetch` | Read a value (sync vs async) |
| `set` / `update` | Mutate a value |
| `create` / `make` / `build` | Construct |
| `delete` / `remove` | Destroy |
| `is` / `has` / `can` | Boolean predicate |
| `to` | Convert (`toJSON`, `toString`) |
| `from` | Construct from other type (`User.fromRow`) |
| `on` | Event handler (`onSubmit`) |

Pick one verb per concept and stick to it. If "fetch" means "go to the network"
and "get" means "read in-memory", maintain that across the project.

---

## Acronyms

For acronyms inside identifiers, treat the acronym as a normal word in the
chosen case.

```ts
// Good
function parseHttpResponse() { ... }
class JsonParser { ... }
const userId = '...';   // not userID
const httpClient: HttpClient;

// Bad
function parseHTTPResponse() { ... }  // breaks reading flow
class JSONParser { ... }
```

`Id` not `ID`, `Url` not `URL`, `Api` not `API` — except in **type names** where
all-caps is sometimes tolerated; project consistency decides.

---

## File and Directory Names

- Filenames are `kebab-case.ts` for plain modules. For React/JSX components and
  classes that are the file's main export, `PascalCase.tsx` is common.
- Test files are `<source>.test.ts` (Vitest/Jest) or `<source>.spec.ts`.
- Index files (`index.ts`) act as a directory's public API. Don't put logic in
  them — only re-exports.

```
src/
  user/
    user.ts                    # entity / type
    user-repository.ts         # data access
    user-repository.test.ts    # test
    user-service.ts            # business logic
    index.ts                   # public re-exports
```

---

## Avoid Stutter at the Package Boundary

When consumers will write `user.User`, name the type `User`, not `UserUser`:

```ts
// In user/index.ts
export { UserRepository } from './user-repository.js';
export type { User } from './user.js';

// Consumer code
import { User, UserRepository } from './user/index.js';
```

If the imported names already include the domain, don't repeat it in the import:
prefer `import { User }` over `import { UserUser }`.

---

## Related Skills

- **Style core**: See [node-style-core](../node-style-core/SKILL.md) for the underlying clarity/simplicity priority order.
- **Modules**: See [node-modules](../node-modules/SKILL.md) for import ordering and barrel files.
- **Types**: See [node-types](../node-types/SKILL.md) for type vs interface and generic naming.
- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for naming custom Error subclasses.
- **Testing**: See [node-testing](../node-testing/SKILL.md) for naming test cases and fixtures.
- **Linting**: See [node-linting](../node-linting/SKILL.md) for `@typescript-eslint/naming-convention` config that enforces these rules.
