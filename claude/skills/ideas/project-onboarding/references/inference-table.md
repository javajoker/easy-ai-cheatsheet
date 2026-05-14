# Inference Table

For each fact you would otherwise have to ask the user, where to look in the
repo to infer it. Reduces the question count in Phase 3 substantially.

| Fact | Look at |
|---|---|
| Language and version | `go.mod`, `package.json` "engines", `pyproject.toml` "requires-python", `.python-version`, `.nvmrc`, `Dockerfile` base image, `.tool-versions` |
| Primary framework | Top-level imports of `cmd/main.go`, `index.ts`, `app/main.py`; dependency manifest |
| ORM / data layer | Dependency manifest: `gorm`, `prisma`, `sqlalchemy`, `typeorm`, `sequelize`, `mongoose`, `mongo-driver` |
| Database type | `docker-compose.yml`, `migrations/` content, ORM dialect strings, connection-string env vars |
| Cache / KV | Dependency manifest: `redis`, `go-redis`, `ioredis`, `memcached` |
| Queue | Dependency manifest: `bullmq`, `celery`, `asynq`, `nats`, `kafka`, `rabbitmq` |
| Logger | Imports: `zap`, `logrus`, `pino`, `winston`, `logging` (Python stdlib), `slog` |
| Metrics | Imports: `prometheus`, `statsd`, `datadog` |
| Tracing | Imports: `opentelemetry`, `jaeger`, `zipkin`, `sentry` |
| Test framework | Test file extensions and imports: `*_test.go`, `*.test.ts`, `test_*.py`, `*Test.java` |
| Test integration gating | `testing.Short()` (Go), `@pytest.mark.integration`, `describe.skip` (Jest) |
| Build command | `Makefile` targets, `package.json` scripts, `pyproject.toml` `[tool.poetry.scripts]`, `Cargo.toml` `[[bin]]` |
| Lint config | `.golangci.yml`, `.eslintrc`, `pyproject.toml [tool.ruff]`, `tslint.json`, `.rubocop.yml` |
| CI pipeline | `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, `.circleci/` |
| Deploy target | `Dockerfile`, `docker-compose.yml`, `helm/`, `k8s/`, `serverless.yml`, `vercel.json`, `Procfile` |
| Branch convention | Recent `git log --oneline -20`, `CONTRIBUTING.md` |
| Commit convention | Recent commits — look for `feat:`, `fix:`, `chore:` prefixes vs free-form |
| Module / package structure | Top-level dirs: `cmd/`, `internal/`, `pkg/` (Go); `src/`, `app/`, `lib/` (others) |
| i18n / locales | `locales/`, `i18n/`, `messages/` directories; dependency manifest mentioning `i18next`, `go-i18n`, `gettext`, `babel` |
| Auth / session | Imports of `jwt`, `passport`, `flask-login`, `oauth2`, custom middleware in `auth/` |
| External SDKs | Imports of `stripe`, `aws-sdk`, `firebase-admin`, `sendgrid`, etc. |
| Documentation system | `mkdocs.yml`, `docusaurus.config.js`, `mdbook.toml`, `.obsidian/`, `_config.yml` (Jekyll) |
| Doc indexing system | `docs/docs-index.md`, `docs/SUMMARY.md`, `mkdocs.yml` `nav:` |

## What you cannot infer

These almost always need to be asked. Save the question count for them:

- Which features are in active development vs maintained vs frozen.
- Stakeholder structure (who decides what).
- Upcoming deadlines or release windows.
- Reasons behind unusual conventions (the *why*, when only the *what* is in
  the code).
- Primary language preference for output (the codebase may be polyglot).
- Sensitive areas where extra care is needed (compliance-driven code,
  legacy modules, etc.).

## Inference confidence

When you infer rather than ask, mark the inference in your output:

- **High confidence** — explicitly named in a manifest or config. State as
  fact.
- **Medium confidence** — present in code but interpretation could be wrong.
  Phrase as "appears to be …" and offer the user a quick correction
  opportunity.
- **Low confidence** — guessed from one or two ambiguous signals. Ask
  rather than infer.
