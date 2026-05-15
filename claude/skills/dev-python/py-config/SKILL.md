---
name: py-config
description: Use when designing or loading configuration in Python — environment variables, `.env` files, `pydantic-settings`, `dynaconf`, multi-environment overrides, secrets handling, and validation at startup. Also use when reviewing code that reads `os.environ` ad hoc.
license: Apache-2.0
metadata:
  sources: "12-Factor App, pydantic-settings docs, python-dotenv docs"
---

# Python Configuration

## Single Source of Truth: Validated Settings

Read `os.environ` once, at startup, through a validator. Everything else
imports the typed result.

```python
# myapp/config.py
from pydantic import Field, HttpUrl, PostgresDsn
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    env: str = Field("development", pattern=r"^(development|test|production)$")
    port: int = Field(3000, gt=0, lt=65536)
    database_url: PostgresDsn
    log_level: str = Field("INFO", pattern=r"^(DEBUG|INFO|WARNING|ERROR|CRITICAL)$")
    redis_url: str | None = None

settings = Settings()       # raises on invalid env
```

Now `settings.port` is `int`, `settings.database_url` is a validated DSN, and
the type checker knows it.

---

## Fail Fast on Invalid Config

Pydantic raises `ValidationError` on missing-required or wrong-typed inputs.
Let it propagate — the process should die at startup, before it accepts
traffic.

A silent default (`port = int(os.environ.get("PORT", 3000))`) is a footgun:
in production, you wanted the deploy to fail loudly, not bind to the wrong
port.

For values with a meaningful default (log level, page size), put the default
in the model, not in a fallback at the call site.

---

## `.env` Discipline

| File | Tracked in git? |
|---|---|
| `.env` | No |
| `.env.local` | No |
| `.env.example` | Yes (with placeholder values) |
| `.env.test` | Yes only if it has no secrets |

```bash
# .env.example
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
REDIS_URL=redis://localhost:6379
LOG_LEVEL=DEBUG
```

`pydantic-settings` auto-reads `.env` when the path is in `model_config`. In
production, the platform injects env vars; don't ship a `.env`.

---

## Layered Override

Configuration loads in priority order:

1. **Command-line flags** (rare in services; common in CLIs).
2. **Environment variables** (production source of truth).
3. **`.env` file** (local dev only).
4. **Defaults** in the model.

Each layer overrides the one below. Don't add a YAML / TOML config format on
top unless the project genuinely needs structured config the model can't
express — and even then, validate the loaded file with the same model.

---

## Secrets Are Not Config

Anything sensitive (database password, API key, JWT secret) is a **secret**,
not config. The distinction matters because:

- Secrets rotate. Config doesn't.
- Secrets get redacted in logs. Config can be logged at startup.
- Secrets live in a vault (AWS Secrets Manager, GCP Secret Manager, Vault).

In small projects, secrets *are* env vars. In larger ones, the platform
injects them from the vault.

```python
# pydantic Secret type — repr is masked
from pydantic import SecretStr

class Settings(BaseSettings):
    jwt_secret: SecretStr
```

`SecretStr` masks the value in `repr()`, which protects against accidental
logging. Call `.get_secret_value()` to read.

---

## Don't Log the Whole Settings Object

```python
# Bad
log.info("starting", settings=settings.model_dump())

# Good
log.info(
    "starting",
    env=settings.env,
    port=settings.port,
    log_level=settings.log_level,
)
```

`SecretStr` helps but isn't a substitute for being deliberate about what
appears in logs.

---

## Multi-Environment

Don't write `if os.environ.get("ENV") == "production"` across modules.
Translate the environment once into a typed setting, then branch on the
setting:

```python
# Bad
if os.environ.get("ENV") == "production":
    log_pretty = False

# Good
if settings.env == "production":
    log_pretty = False
```

For features that vary by environment, prefer **feature flags** over `ENV`
checks. Flags are explicit, runtime-toggleable, and don't require a deploy.

---

## Feature Flags

For simple per-environment toggles, a bool in settings works:

```python
class Settings(BaseSettings):
    enable_new_checkout: bool = False

if settings.enable_new_checkout: ...
```

For per-user or per-tenant flags, use a service (LaunchDarkly, Unleash,
GrowthBook). Rolling your own from env vars doesn't scale.

---

## Don't Read `os.environ` Outside `config.py`

```python
# Bad — scattered reads
timeout = int(os.environ.get("HTTP_TIMEOUT", "5"))

# Good
from myapp.config import settings
timeout = settings.http_timeout
```

Benefits of central reads:

- The model documents every input.
- Adding a new env var is a single-file change.
- The validator catches typos before the call site does.

Ruff rule: `pylint-import-from-os-environ`-style custom rule, or grep for
`os.environ` in CI outside `config.py`.

---

## Test Config

In tests, override settings with environment variables at the test runner
level, not by re-mocking `Settings`:

```python
# pyproject.toml
[tool.pytest.ini_options]
env = [
    "ENV=test",
    "DATABASE_URL=postgresql://test:test@localhost/test",
    "LOG_LEVEL=ERROR",
]
```

(Requires `pytest-env`.) Same validator runs in tests — bad test env vars
fail like production would.

Or override per-test with `monkeypatch`:

```python
def test_with_custom_port(monkeypatch):
    monkeypatch.setenv("PORT", "4000")
    from myapp.config import Settings
    settings = Settings()
    assert settings.port == 4000
```

---

## Nested Settings

For organization, group related settings into sub-models:

```python
class DatabaseSettings(BaseModel):
    url: PostgresDsn
    pool_size: int = 10

class Settings(BaseSettings):
    database: DatabaseSettings

    model_config = SettingsConfigDict(env_nested_delimiter="__")
```

Then `DATABASE__URL` and `DATABASE__POOL_SIZE` in env vars populate the
nested model.

---

## CLI Configuration

For CLIs, `typer` or `click` bind options at the entry point and pass them
down:

```python
import typer

def main(
    port: int = typer.Option(3000, envvar="PORT"),
    log_level: str = typer.Option("INFO", envvar="LOG_LEVEL"),
):
    configure_logging(log_level)
    run_server(port)

typer.run(main)
```

The CLI options take precedence over env vars; env vars over defaults.

---

## Quick Reference

| Question | Default |
|---|---|
| Source of truth | `pydantic-settings` `BaseSettings` |
| Where read | One module (`config.py`) |
| `.env` in git | No |
| `.env.example` in git | Yes |
| Defaults | In the model |
| Secrets | `SecretStr`; vault for prod |
| Multi-env logic | Branch on typed `settings`, not `os.environ` |
| Feature flag | Bool for env-level; flag service for per-user |

## Related Skills

- **Security**: [py-security](../py-security/SKILL.md) for secret handling.
- **Logging**: [py-logging](../py-logging/SKILL.md) for redaction.
- **HTTP**: [py-http](../py-http/SKILL.md) for binding port / timeouts.
- **Typing**: [py-typing](../py-typing/SKILL.md) for pydantic-mypy plugin setup.
- **Testing**: [py-testing](../py-testing/SKILL.md) for test-environment configuration.
- **Modules**: [py-modules](../py-modules/SKILL.md) for `pyproject.toml` tool sections.
