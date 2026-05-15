---
name: node-security
description: Use when reviewing or writing security-sensitive Node.js code — input validation, SQL injection, XSS, SSRF, command injection, prototype pollution, JWT handling, secrets, dependency audit, security headers, CSRF, rate limiting, or process-level hardening. Also use during a security review of a PR, even if the user didn't ask specifically about security.
license: Apache-2.0
metadata:
  sources: "OWASP Top 10, OWASP API Security Top 10, Node.js Security Best Practices, Snyk advisories"
---

# Node.js Security

## Input Validation Is Layer One

Every external input — request bodies, query strings, headers, environment
variables, files on disk — is **untrusted**. Validate at the boundary with a
schema; trust the inside.

```ts
const Body = z.object({
  email: z.string().email(),
  age: z.number().int().min(0).max(150),
});

const body = Body.parse(req.body);   // throws on invalid; caught by error handler
```

Bare `as` casts are not validation:

```ts
// Bad
const body = req.body as { email: string };   // pretends, doesn't check

// Good
const body = Body.parse(req.body);
```

---

## SQL Injection

Use parameterized queries. Always. The argument list goes through the driver,
never through string concatenation.

```ts
// Bad
db.query(`SELECT * FROM users WHERE email = '${email}'`);

// Good — pg, parameterized
db.query('SELECT * FROM users WHERE email = $1', [email]);

// Good — Prisma
prisma.user.findFirst({ where: { email } });

// Good — Knex
knex('users').where({ email });
```

If you're building dynamic SQL (column names, table names), use an
allow-list — `if (!allowedColumns.has(col)) throw new Error(...)`. **Never**
interpolate user-controlled identifiers.

---

## XSS in Server-Rendered Output

If you render HTML on the server (templates, email, PDF), escape user content.
Most template engines escape by default; the danger is the "raw" / "unsafe"
helper:

```ts
// Bad
res.send(`<p>Welcome ${name}</p>`);   // name contains <script>

// Good — template engine with auto-escape
res.send(template('welcome', { name }));

// Good — manual escape only when generating HTML directly
import { escapeHTML } from './escape.js';
res.send(`<p>Welcome ${escapeHTML(name)}</p>`);
```

In JSON APIs, XSS isn't a server concern — but make sure the client doesn't
`innerHTML` the response.

---

## SSRF

Server-Side Request Forgery: the server fetches a URL the user controls, and
the user points it at `http://169.254.169.254/...` (cloud metadata) or an
internal service.

```ts
// Bad — accepts any URL
async function fetchImage(req) {
  const res = await fetch(req.body.url);
  ...
}
```

Defenses (apply all that fit):

1. **Allow-list domains** — whitelist exactly the destinations you'll fetch
   from.
2. **Block private IPs** — resolve the hostname and reject `127.0.0.0/8`,
   `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, IPv6
   equivalents.
3. **Disable redirects** or follow them through the same checks.
4. **No `file://`, `gopher://`, `ftp://`** — restrict to `https://`.

Libraries like `ssrf-req-filter` automate this.

---

## Command Injection

Never pass user input to `child_process.exec` or `execSync` without sanitizing.

```ts
// Bad
exec(`convert ${userFile} out.png`);   // userFile = "x.png; rm -rf /"

// Good — args array, not shell string
import { execFile } from 'node:child_process';
execFile('convert', [userFile, 'out.png'], (err, stdout, stderr) => { ... });
```

`execFile` and `spawn` with an args array skip the shell entirely. If you must
use the shell, sanitize aggressively or use `shell-quote`.

---

## Prototype Pollution

Merging user-supplied objects into application objects with a deep merger that
respects `__proto__` is the canonical pollution vector.

```ts
// Bad — recursive merge that walks every key
function deepMerge(a, b) {
  for (const k in b) {
    if (typeof b[k] === 'object') a[k] = deepMerge(a[k] ?? {}, b[k]);
    else a[k] = b[k];
  }
  return a;
}

// Bad caller
const merged = deepMerge({}, JSON.parse(req.body));
```

Mitigations:

- Use schema-validated objects only — `zod.parse` strips unknown keys.
- Use `Object.create(null)` for maps of user-controlled keys.
- Use established merge libraries (`lodash.merge` with the pollution patch, or
  `defu`) that block `__proto__`, `constructor`, `prototype`.

---

## JWT

- Use a vetted library (`jose` for new code, `jsonwebtoken` for established).
- **Verify the signature**, don't just decode.
- Set `algorithms: ['RS256']` (or your chosen alg) explicitly — never rely on
  the token's `alg` header.
- Set `expiresIn` to a short value (15 min for access tokens; refresh tokens
  separately).
- Don't put secrets in the payload — JWT bodies are base64, not encrypted.

```ts
import * as jose from 'jose';

const { payload } = await jose.jwtVerify(token, key, {
  algorithms: ['RS256'],
  issuer: 'https://issuer.example',
  audience: 'my-api',
});
```

---

## CSRF

CSRF matters for cookie-based browser sessions. For Bearer-token APIs (JWT in
Authorization header), CSRF is not the threat.

If you use cookies:

- Set `SameSite=Lax` (or `Strict`) on session cookies.
- Issue a CSRF token (`@fastify/csrf-protection`).
- Use double-submit pattern or synchronizer token.

```ts
app.register(import('@fastify/csrf-protection'));
```

---

## Security Headers

```ts
import helmet from '@fastify/helmet';
app.register(helmet, {
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'"],
    },
  },
});
```

Helmet sets: `Content-Security-Policy`, `X-Frame-Options: DENY`,
`Strict-Transport-Security`, `X-Content-Type-Options: nosniff`,
`Referrer-Policy: no-referrer`, and a few more. Customize CSP for your app.

---

## Rate Limiting

A single client exhausting your service is a DoS — accidental or otherwise.
Rate-limit at the edge (CDN, API gateway) **and** in the app.

```ts
import rateLimit from '@fastify/rate-limit';
app.register(rateLimit, {
  max: 100,
  timeWindow: '1 minute',
});
```

Key the limit on the right axis: per-IP for anonymous endpoints, per-user for
authenticated.

---

## Dependency Audit

```bash
npm audit
npm audit fix
```

Run it in CI. Treat known-high vulnerabilities as a build break. Use
`npm-audit-resolver` or override via `overrides` in `package.json` when a
transitive dep has no fixed version.

For supply-chain hardening:

- Pin via `package-lock.json` (committed).
- Use `npm ci` (or `pnpm install --frozen-lockfile`) in CI.
- Consider `npm install --ignore-scripts` to neutralize install-time
  malicious scripts in dev. Audit specifically when you allow them.

---

## Secrets in Code

Never commit secrets. Use a pre-commit hook (`gitleaks`, `trufflehog`) and
the platform's secret scanner.

If a secret leaked: rotate it first, then remove from history. Removing from
history without rotation is theater.

---

## Process Hardening

- Run as a non-root user (`USER node` in Dockerfile).
- Drop capabilities (`--cap-drop=ALL` in container runtime).
- `NODE_ENV=production` — disables stack traces in some libraries' default
  output.
- `--disable-proto=delete` (Node 18+) blocks `__proto__` access patterns.

---

## Quick Reference

| Threat | Defense |
|---|---|
| Bad input | Schema validation at the edge |
| SQL injection | Parameterized queries |
| XSS | Template auto-escape; never `innerHTML` user input |
| SSRF | Allow-list domains, block private IPs |
| Command injection | `execFile` with args array |
| Prototype pollution | Strip / validate before merge |
| JWT confusion | Pin algorithm in verifier |
| CSRF | `SameSite` + token for cookie sessions |
| DoS | Rate limit at edge and app |
| Vulnerable deps | `npm audit` in CI |
| Secret leak | Pre-commit scanner; rotate on leak |

## Related Skills

- **HTTP**: See [node-http](../node-http/SKILL.md) for headers, CORS, rate-limit plugins.
- **Error handling**: See [node-error-handling](../node-error-handling/SKILL.md) for not leaking stack traces in responses.
- **Logging**: See [node-logging](../node-logging/SKILL.md) for redaction of secrets in logs.
- **Config**: See [node-config](../node-config/SKILL.md) for secret management.
- **Code review**: See [node-code-review](../node-code-review/SKILL.md) for the security section of a PR review.
