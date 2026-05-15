---
name: node-testing
description: Use when writing, reviewing, or improving tests for Node.js / TypeScript code — using Vitest, Jest, or node:test, designing table-driven cases with test.each, mocking modules, testing async code, and structuring fixtures. Also use when a user asks to write a test for a function or module, even if they don't mention a framework. Does not cover load testing or benchmarks in depth (see node-performance).
license: Apache-2.0
compatibility: Examples target Vitest. `node:test` syntax noted where it differs.
metadata:
  sources: "Vitest docs, Jest docs, node:test docs, Kent C. Dodds testing principles"
allowed-tools: Bash(bash:*)
---

# Node.js Testing

## Available Scripts and Assets

- **`assets/table-test-template.ts`** — Canonical Vitest table-driven test (with `it.each`, fake timers, and async-rejection sample). Copy as the starting scaffold for a new test file.
- **`scripts/gen-test.sh`** — Generates a minimal Vitest scaffold for a given function and source file. Supports `--async` and `--output`. Run `bash scripts/gen-test.sh --help`.

## Quick Reference

| Need | Reach for |
|---|---|
| Table-driven | `test.each` / `it.each` |
| Async assertion | `await expect(p).resolves...` / `.rejects...` |
| Module-level mock | `vi.mock()` / `jest.mock()` |
| Time control | `vi.useFakeTimers()` |
| Fixture / setup | `beforeEach` + helper function |
| HTTP handler | `app.inject()` (Fastify) or supertest |
| Snapshot for stable JSON | last resort; prefer explicit assert |

---

## Pick One Framework, Stick With It

**Vitest** for new TypeScript projects (Vite-aligned, ESM-native, fast watch
mode). **Jest** when the project is established on it. **`node:test`** when
zero-deps matters (CLIs, libs, environments without npm). Don't mix runners in
the same package.

```ts
import { describe, it, expect } from 'vitest';

describe('add', () => {
  it('returns the sum', () => {
    expect(add(2, 3)).toBe(5);
  });
});
```

---

## Useful Test Names

Test names describe **behaviour**, not the function. They form a sentence with
the `it` / `test`:

```ts
// Bad
it('add', () => { ... });
it('test 1', () => { ... });

// Good
it('returns the sum of two positive numbers', () => { ... });
it('throws when the input is not finite', () => { ... });
```

`describe` groups by subject (function, class, module); `it` describes a
single behaviour. One assertion concept per `it` — multiple assertions are
fine if they together cover one behaviour.

---

## Table-Driven Tests

Use `it.each` / `test.each` when cases share the same code path with only
input/output differences:

```ts
it.each([
  { input: 'foo',  expected: 'FOO' },
  { input: '',     expected: '' },
  { input: 'háy',  expected: 'HÁY' },
])('upperCase($input) → $expected', ({ input, expected }) => {
  expect(upperCase(input)).toBe(expected);
});
```

**Don't** use table-driven tests when:

- Cases need different setup or teardown.
- Cases have different assertion shapes.
- Adding a row would require an `if` inside the body.

Then prefer separate `it` blocks.

---

## Async Tests

Always `await` the work under test, and use `.resolves` / `.rejects` for
promises:

```ts
it('loads a user', async () => {
  const user = await loadUser('1');
  expect(user.id).toBe('1');
});

it('rejects when missing', async () => {
  await expect(loadUser('nope')).rejects.toThrow(NotFoundError);
});
```

Don't return a promise *and* call `done` — that's an older Jest pattern that
hides race conditions.

---

## Fakes, Stubs, Mocks: Use Sparingly

Module-level mocking with `vi.mock('./db.js')` is powerful and easy to abuse.
Order of preference:

1. **Real implementation** in a test container (Postgres in Docker, in-memory
   sqlite, real HTTP server with `app.inject()`).
2. **In-memory fake** that satisfies the same interface (an `InMemoryUserRepo`
   class that implements `UserRepo`).
3. **Stub** of a single function on a real module.
4. **Module mock** as a last resort.

Module mocks lock the test to the implementation and break the moment the
production code refactors imports. They're the most expensive maintenance
debt.

```ts
// Preferred — inject a fake
class InMemoryUserRepo implements UserRepo {
  private users = new Map<string, User>();
  async findById(id: string) { return this.users.get(id) ?? null; }
}

const service = new UserService(new InMemoryUserRepo());
```

---

## Time and Randomness

Fake them. Otherwise tests flake.

```ts
import { vi } from 'vitest';

beforeEach(() => vi.useFakeTimers());
afterEach(() => vi.useRealTimers());

it('expires after 60s', async () => {
  const session = new Session(60_000);
  vi.advanceTimersByTime(60_001);
  expect(session.isValid()).toBe(false);
});
```

For randomness, inject the random source (`() => number`) into the unit under
test. Don't spy on `Math.random`.

---

## Test Helpers

Helpers live alongside tests in a `test-helpers.ts` or `fixtures.ts`. Common
helpers:

```ts
export function makeUser(overrides: Partial<User> = {}): User {
  return { id: 'u1', email: 'a@b', active: true, ...overrides };
}

export async function withTransaction(db: Database, fn: () => Promise<void>) {
  await db.begin();
  try { await fn(); } finally { await db.rollback(); }
}
```

Use object-spread overrides so a test can change only what it cares about,
not restate the whole shape.

---

## Test the Public API

Test through the unit's exported surface. Reaching into private state with
`(service as any).privateField` couples the test to the implementation.

When a private behaviour is genuinely hard to test through the public API,
that's a hint to extract a separate pure helper and test *it* directly.

---

## Don't Test Implementation Details

```ts
// Bad — couples to the implementation
expect(dbMock.query).toHaveBeenCalledWith('SELECT * FROM users WHERE id = $1', ['1']);

// Good — assert the observable behaviour
const user = await service.getById('1');
expect(user.id).toBe('1');
```

Mock-call-count assertions are fine for testing genuine side effects (an event
was published, a metric was emitted). They're brittle when used to verify the
internal SQL the service emitted.

---

## Snapshot Tests: Reserved for Stable Output

Snapshots are tempting because they're easy to write. They're hard to maintain
because every refactor that touches output prompts a "just update the snapshot"
moment that erases the test's signal.

Use snapshots only when:

- The output is large and stable (a generated config, a normalized AST).
- The test fails informatively when the snapshot changes.

For anything else, write explicit `expect().toEqual({ ... })` assertions.

---

## HTTP Handler Tests

For Fastify, use `app.inject()` — it bypasses the network and runs the request
pipeline in-process:

```ts
it('returns 404 for unknown user', async () => {
  const res = await app.inject({ method: 'GET', url: '/users/nope' });
  expect(res.statusCode).toBe(404);
  expect(res.json()).toEqual({ error: 'not_found', resource: 'user' });
});
```

For Express, `supertest(app)` is the equivalent.

---

## Coverage: a Floor, Not a Target

A 90 % coverage number means little if the tests don't assert behaviour.
Prefer a smaller suite of strong tests over a large suite of "imports exercise
the line counter" tests.

Set a coverage *floor* (e.g. 70 %) to prevent regressions, but don't celebrate
crossing it.

---

## Parallel and Isolated

Each test file should be runnable in isolation and in parallel with others.
Shared state (a running DB schema, global mocks) is the leading cause of flake.
Reset state in `beforeEach`, not `afterEach` — `beforeEach` guarantees the
clean state regardless of the previous test's success.

---

## Quick Reference

| Question | Default |
|---|---|
| Runner | Vitest (or Jest if established) |
| Mock style | Real > fake > stub > module mock |
| Table-driven | `it.each` when same code path |
| Async | `await` + `.resolves` / `.rejects` |
| Time | `vi.useFakeTimers()` |
| HTTP | `app.inject()` / `supertest` |
| Snapshot | Last resort, stable outputs only |

## Related Skills

- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for asserting thrown errors and matching by class.
- **Async**: See [node-async](../node-async/SKILL.md) for cancellation and timeout testing.
- **HTTP**: See [node-http](../node-http/SKILL.md) for request/response shape and validation.
- **Naming**: See [node-naming](../node-naming/SKILL.md) for test file naming.
- **Linting**: See [node-linting](../node-linting/SKILL.md) for `eslint-plugin-vitest` / `eslint-plugin-jest` rules.
- **Code review**: See [node-code-review](../node-code-review/SKILL.md) for the test section of a PR review.
