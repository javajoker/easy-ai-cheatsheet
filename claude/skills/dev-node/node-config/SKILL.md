---
name: node-config
description: Use when designing, loading, or validating configuration in Node.js — environment variables, .env files, runtime config objects, secrets management, multi-environment overrides, feature flags. Also use when reviewing code that reads `process.env` ad hoc, or when a misconfigured value caused a production incident.
license: Apache-2.0
metadata:
  sources: "12-Factor App, Node.js dotenv ecosystem, zod / valibot schema design"
---

# Node.js Configuration

## Single Source of Truth: A Validated Schema

Read `process.env` exactly once, at startup, through a validator. Everything
else imports the typed result.

```ts
// src/config.ts
import { z } from 'zod';

const schema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().url(),
  LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),
  REDIS_URL: z.string().url().optional(),
});

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error('invalid config:', parsed.error.flatten().fieldErrors);
  process.exit(1);
}

export const config = parsed.data;
export type Config = z.infer<typeof schema>;
```

Now `config.PORT` is `number`, `config.DATABASE_URL` is a validated URL string,
and TypeScript knows it.

---

## Fail Fast on Invalid Config

A bad config should kill the process at startup, before it accepts traffic.
A silent default ("PORT was missing so I'll use 3000") is a footgun: in
production, you wanted the deploy to fail loudly, not bind to the wrong port.

For values that *do* have a meaningful default (log level, page size), declare
the default in the schema, not in a fallback at the call site.

---

## `.env` Discipline

`.env` files belong in the developer's machine and in CI's secret store. They
do **not** belong in the repository.

| File | Tracked in git? |
|---|---|
| `.env` | No |
| `.env.local` | No |
| `.env.example` | Yes (with placeholder values) |
| `.env.test` | Yes only if it has no secrets |

```bash
# .env.example
DATABASE_URL=postgres://user:pass@localhost:5432/dbname
REDIS_URL=redis://localhost:6379
LOG_LEVEL=debug
```

Use `dotenv` (or Node 20+'s built-in `--env-file`) for local development. In
production, the platform injects environment variables — don't ship a `.env`
file.

```bash
node --env-file=.env src/main.js
```

---

## Layered Override

Configuration loads in priority order:

1. **Command-line flags** (rare in services; common in CLIs).
2. **Environment variables** (the production source of truth).
3. **`.env` file** (local dev only).
4. **Defaults** in the schema.

Each layer overrides the one below. Don't add a config file format on top
(JSON, YAML, TOML) unless the project genuinely needs structured config the
schema can't express — and even then, validate the loaded file with the same
schema.

---

## Secrets Are Not Config

Anything sensitive (database password, API key, JWT secret) is a **secret**,
not config. The distinction matters because:

- Secrets rotate. Config doesn't.
- Secrets get redacted in logs. Config gets logged at startup.
- Secrets live in a vault (AWS Secrets Manager, GCP Secret Manager,
  HashiCorp Vault). Config lives in env vars.

In small projects, secrets *are* env vars. In larger ones, the platform
injects them from the vault.

```ts
const dbPassword = await secretManager.getSecretValue('db-password');
```

Treat the result as ephemeral; don't store it in a long-lived global.

---

## Don't Log the Whole Config Object

```ts
// Bad
log.info({ config }, 'starting');

// Good — log only what's safe
log.info({
  nodeEnv: config.NODE_ENV,
  port: config.PORT,
  logLevel: config.LOG_LEVEL,
}, 'starting');
```

If you must log "the config", first strip secrets explicitly:

```ts
const { DATABASE_URL, REDIS_URL, ...safeConfig } = config;
log.info({ config: safeConfig }, 'starting');
```

See [node-logging](../node-logging/SKILL.md) for redaction patterns.

---

## Multi-Environment

Don't write code like `if (process.env.NODE_ENV === 'production') { ... }`
sprinkled across modules. Translate the environment into a typed config value
once, then branch on the config:

```ts
// Bad
if (process.env.NODE_ENV === 'production') log.flush();

// Good
if (config.NODE_ENV === 'production') log.flush();
```

For features that genuinely vary by environment, prefer **feature flags** over
`NODE_ENV` checks. Flags are explicit, runtime-toggleable, and don't require
a deploy.

---

## Feature Flags

For simple per-environment toggles, a config bool is fine:

```ts
const schema = z.object({
  ENABLE_NEW_CHECKOUT: z.coerce.boolean().default(false),
});

if (config.ENABLE_NEW_CHECKOUT) { ... }
```

For per-user or per-tenant flags, use a service (LaunchDarkly, Unleash,
GrowthBook). Don't roll your own from environment variables.

---

## Don't Read `process.env` Outside `config.ts`

```ts
// Bad — scattered reads
const timeout = parseInt(process.env.HTTP_TIMEOUT_MS ?? '5000', 10);

// Good
const timeout = config.HTTP_TIMEOUT_MS;
```

Centralizing reads means:

- The schema documents every input.
- Adding a new env var is a single-file change.
- The validator catches typos before the call site does.

ESLint rule: ban `process.env` outside `src/config.ts`.

---

## Test Config

In tests, override config with environment variables in the test runner config,
not by re-mocking `config.ts`:

```ts
// vitest.config.ts
export default defineConfig({
  test: {
    env: {
      NODE_ENV: 'test',
      DATABASE_URL: 'postgres://test/test',
      LOG_LEVEL: 'fatal',
    },
  },
});
```

This keeps the same validator running in tests — bad test env vars fail like
production would.

---

## Quick Reference

| Question | Default |
|---|---|
| Source of truth | Validated schema (zod / valibot) |
| Where read | One module (`config.ts`) |
| `.env` in git | No |
| `.env.example` in git | Yes |
| Defaults | In the schema |
| Secrets | Vault, redacted in logs |
| Multi-env logic | Branch on typed `config`, not `process.env` |
| Feature flag | Boolean for env-level; flag service for per-user |

## Related Skills

- **Security**: See [node-security](../node-security/SKILL.md) for secret handling.
- **Logging**: See [node-logging](../node-logging/SKILL.md) for redaction of config-derived fields.
- **HTTP**: See [node-http](../node-http/SKILL.md) for binding port and timeouts.
- **Types**: See [node-types](../node-types/SKILL.md) for inferring the `Config` type from the schema.
- **Testing**: See [node-testing](../node-testing/SKILL.md) for test-environment configuration.
