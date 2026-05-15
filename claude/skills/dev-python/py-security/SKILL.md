---
name: py-security
description: Use when reviewing or writing security-sensitive Python code — input validation, SQL injection, command injection, XSS, SSRF, deserialization (pickle/yaml), JWT handling, secrets, dependency audit, rate limiting, or hardening at the process level. Also use during a security review of a PR, even if the user didn't ask for one.
license: Apache-2.0
metadata:
  sources: "OWASP Top 10, OWASP API Security Top 10, Bandit findings, Python Security docs"
---

# Python Security

## Input Validation Is Layer One

Every external input — request bodies, query strings, headers, env vars,
files on disk — is **untrusted**. Validate with a schema at the boundary;
trust the inside.

```python
from pydantic import BaseModel, EmailStr, Field

class Body(BaseModel):
    email: EmailStr
    age: int = Field(ge=0, le=150)

body = Body.model_validate(raw)   # raises on invalid
```

Bare casts are not validation:

```python
# Bad
body = raw   # type: dict   — assumes shape
email = body["email"]

# Good
body = Body.model_validate(raw)
email = body.email
```

---

## SQL Injection

Use parameterized queries. The driver handles escaping. Never build SQL by
string concatenation or f-strings with user input:

```python
# Bad
cursor.execute(f"SELECT * FROM users WHERE email = '{email}'")

# Good — psycopg
cursor.execute("SELECT * FROM users WHERE email = %s", (email,))

# Good — SQLAlchemy
stmt = select(User).where(User.email == email)
session.execute(stmt)
```

If you need dynamic column or table names, use an **allow-list**:

```python
ALLOWED_COLUMNS = {"id", "email", "created_at"}
if col not in ALLOWED_COLUMNS:
    raise ValueError(f"unknown column: {col}")
stmt = text(f"SELECT {col} FROM users WHERE id = :id")
```

Never interpolate user-controlled identifiers.

---

## Command Injection

Never pass user input to `os.system`, `subprocess.call(..., shell=True)`, or
similar.

```python
# Bad
os.system(f"convert {user_file} out.png")   # user_file = "x.png; rm -rf /"

# Good — list form, no shell
subprocess.run(["convert", user_file, "out.png"], check=True, timeout=30)
```

The list form skips the shell entirely. If you genuinely need shell features,
build the command carefully with `shlex.quote`.

---

## Pickle and YAML

`pickle.load` on untrusted input executes arbitrary code. Treat as critical.

```python
# Bad
data = pickle.load(open("data.pkl", "rb"))   # if "data.pkl" came from outside

# Good — use JSON for cross-trust-boundary data
data = json.load(open("data.json"))
```

YAML's default `yaml.load` is similarly dangerous; use `yaml.safe_load`:

```python
# Bad
config = yaml.load(open("config.yml"))

# Good
config = yaml.safe_load(open("config.yml"))
```

For complex serialization, use Pydantic + JSON, or `msgpack`/`protobuf` with
schema validation.

---

## SSRF

Server-Side Request Forgery: the server fetches a URL the user controls, and
the user points it at internal services or cloud metadata
(`http://169.254.169.254/...`).

Defenses (apply all that fit):

1. **Allow-list domains**.
2. **Resolve hostname; block private IPs** (`127.0.0.0/8`, `10.0.0.0/8`,
   `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, IPv6 equivalents).
3. **Disable redirects** or follow them through the same checks.
4. **Restrict to `https://`** — no `file://`, `gopher://`, `ftp://`.

```python
import ipaddress, socket
from urllib.parse import urlparse

def safe_url(url: str) -> str:
    parsed = urlparse(url)
    if parsed.scheme not in {"http", "https"}:
        raise ValueError("bad scheme")
    host = parsed.hostname
    if host is None:
        raise ValueError("no host")
    for info in socket.getaddrinfo(host, None):
        ip = ipaddress.ip_address(info[4][0])
        if ip.is_private or ip.is_loopback or ip.is_link_local:
            raise ValueError("private IP")
    return url
```

---

## XSS in Server-Rendered Templates

Jinja2 auto-escapes by default in most loaders. Don't disable autoescape;
don't use `{{ user_input | safe }}` on user content. For email/PDF rendering,
the same rules apply.

In JSON APIs, XSS isn't a server concern, but ensure the client doesn't
`innerHTML` the response.

---

## JWT

Use a vetted library (`PyJWT`, `authlib`, `jose`).

- **Verify the signature**, don't just decode.
- Pin algorithms explicitly — don't trust the token's `alg` header.
- Set short `exp` for access tokens (15 min); use refresh tokens separately.
- Don't put secrets in the payload — JWT bodies are base64, not encrypted.

```python
import jwt

payload = jwt.decode(
    token,
    key=public_key,
    algorithms=["RS256"],          # pin
    audience="my-api",
    issuer="https://issuer.example",
)
```

---

## CSRF

CSRF matters for cookie-based browser sessions. For Bearer-token APIs (JWT
in `Authorization`), CSRF isn't the threat.

If you use cookies, set `SameSite=Lax` (or `Strict`) and issue a CSRF token.
FastAPI doesn't have first-party CSRF middleware; use `starlette-csrf` or
similar.

---

## Hashing and Crypto

- Passwords: `argon2` (preferred) or `bcrypt`. Never plain hashes
  (`sha256`, `md5`) for passwords.
- Random tokens: `secrets.token_urlsafe(32)`, never `random.choice`.
- Hashing for non-security uses (cache keys, dedupe): `hashlib.sha256` is
  fine.

```python
import secrets
from argon2 import PasswordHasher

ph = PasswordHasher()
hashed = ph.hash(password)
ph.verify(hashed, candidate)        # raises on mismatch

api_token = secrets.token_urlsafe(32)
```

`random` is a PRNG — predictable. Never use it for tokens, passwords,
session IDs, or cryptographic keys.

---

## Constant-Time Comparison

When comparing secrets (signatures, tokens), use `hmac.compare_digest` —
not `==`. `==` can leak timing information byte-by-byte.

```python
import hmac
if not hmac.compare_digest(expected, provided):
    raise ValueError("invalid signature")
```

---

## Dependency Audit

```bash
pip-audit
safety check
```

Run in CI. Treat known-high vulnerabilities as a build break. For
supply-chain hardening:

- Pin via `requirements.txt` (or `uv.lock` / `poetry.lock`), committed.
- Use `--require-hashes` for high-trust deployments.
- Avoid `--user` and global installs in CI; use venvs.

---

## Rate Limiting

A single client exhausting your service is DoS — accidental or otherwise.
Rate-limit at the edge (CDN, API gateway) **and** in the app.

See [py-http](../py-http/SKILL.md) for `slowapi`. Key on per-IP for
anonymous endpoints, per-user for authenticated.

---

## Secrets in Code

Never commit secrets. Use a pre-commit hook (`gitleaks`, `trufflehog`) and
the platform's secret scanner.

If a secret leaked: rotate first, then remove from git history. Removing
without rotation is theater.

---

## Process Hardening

- Run as a non-root user (`USER python` in Dockerfile).
- Drop capabilities (`--cap-drop=ALL`).
- Pin Python and dependency versions in production images.
- Don't run debug mode in production — it can expose `/debug` endpoints,
  enable `pdb` on errors, etc.

---

## Bandit / Ruff Security Rules

Run a security linter in CI:

```bash
bandit -r src/
# or, via Ruff:
ruff check --select S src/    # bandit-equivalent rules
```

Ruff's `S` rule set covers `assert` in production code, hardcoded passwords,
unsafe deserialization, weak crypto, command injection via subprocess, and
more.

---

## Quick Reference

| Threat | Defense |
|---|---|
| Bad input | Pydantic validation at the edge |
| SQL injection | Parameterized queries / ORM |
| Command injection | `subprocess` with list args |
| Pickle/YAML deserialization | JSON; `yaml.safe_load` |
| SSRF | Allow-list domains, block private IPs |
| XSS (server templates) | Auto-escape; never mark user input safe |
| JWT confusion | Pin algorithm in verifier |
| CSRF | `SameSite` + token for cookie sessions |
| Password hashing | argon2 / bcrypt |
| Random tokens | `secrets`, never `random` |
| Timing attacks | `hmac.compare_digest` |
| Vulnerable deps | `pip-audit` in CI |

## Related Skills

- **HTTP**: [py-http](../py-http/SKILL.md) for headers, CORS, rate-limit middleware.
- **Error handling**: [py-error-handling](../py-error-handling/SKILL.md) for not leaking traces.
- **Logging**: [py-logging](../py-logging/SKILL.md) for secret redaction.
- **Config**: [py-config](../py-config/SKILL.md) for `SecretStr` and vault integration.
- **Linting**: [py-linting](../py-linting/SKILL.md) for Bandit / Ruff `S` rules in CI.
- **Code review**: [py-code-review](../py-code-review/SKILL.md) for the security section of a PR review.
