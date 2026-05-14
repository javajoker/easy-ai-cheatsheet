---
id: "project-context-{project-slug}-001"
title: "Project Context — {Project Name}"
type: reference
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: ["project-context", "{project-slug}"]
---

# Project Context — {Project Name}

> One-paragraph elevator pitch: what this project is, who it serves, and
> what makes it different.

## Identity

- **Name**: {Project Name}
- **Slug**: {project-slug}  ← used in scope:`project:{project-slug}` memory entries
- **Module path / package name**: {e.g. `github.com/example/foo` or `@example/foo`}
- **Project type**: {library | service | application | platform | data pipeline | …}
- **Lifecycle stage**: {planning | prototype | MVP | production | maintenance | sunset}

## Stack

| Layer | Choice | Notes |
|---|---|---|
| Language | {e.g. Go 1.22+} | |
| Framework | {e.g. Gin, FastAPI, Fastify, Next.js} | |
| Persistence | {e.g. PostgreSQL 15, Redis 7} | |
| Queue / events | {e.g. NATS, BullMQ, Kafka} | |
| Observability | {e.g. OpenTelemetry + Prometheus} | |
| Build / test | {e.g. `make`, `pnpm`, `cargo`} | |
| Deploy target | {e.g. Kubernetes, Vercel, AWS Lambda} | |

## Languages

- **Primary language for code / comments**: {English | other}
- **Primary language for user-facing copy**: {English | other}
- **i18n locales supported**: {e.g. en, zh-TW}

## Key conventions and constraints

> Anything Claude needs to know that is *not* obvious from the code or from
> the universal INSTRUCTIONS.

- {convention 1}
- {convention 2}
- {project-specific constraint, e.g. "no panic in library code"}

## Initialization / startup order

> If the project follows a non-obvious startup sequence, document it here.

```
1. Load config
2. Initialize logger
3. Initialize database
4. Initialize cache
5. Start HTTP server
```

## External integrations

| Integration | Purpose | Where in code |
|---|---|---|
| {e.g. Stripe} | Payments | `internal/payment/` |
| {e.g. SendGrid} | Email | `internal/notification/` |

## Verification commands

```bash
# Build
{e.g. go build ./...}

# Static analysis
{e.g. go vet ./...}

# Unit tests
{e.g. go test -short ./...}

# Integration tests
{e.g. go test ./...  (requires Docker compose up)}
```

## Stakeholders

- **Product owner**: {name or role}
- **Tech lead**: {name or role}
- **Operations / on-call**: {name or role}

## Related documents

- {link to PRD, design doc, etc.}
- {link to the project's repository-structure.md}

---

**How to use this template:**

1. Copy this file to `INSTRUCTIONS/projects/<your-slug>/project-context.md`.
2. Replace every `{placeholder}` and remove this footer.
3. Reference it from the project's `CLAUDE.md`.
