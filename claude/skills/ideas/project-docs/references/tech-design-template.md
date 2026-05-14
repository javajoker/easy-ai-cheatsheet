# Tech Design Template Reference

Use this exact structure when generating TECH_DESIGN.md.

---

## Backend Language Choice (decide first)

Before generating the doc, the user must choose a backend language. This drives the
stack table, code examples, ORM choice, queue choice, and i18n approach throughout
the rest of the document. If the user hasn't specified, ASK before generating.

| Choice | Trigger | Downstream skill |
|--------|---------|------------------|
| **Node.js / TypeScript** (default) | "Node", "TypeScript", general SaaS work | `project-backend-node` |
| **Go / Golang** | "Go", "performance", "low-latency", "concurrent" | `project-backend-go` |
| **Python** | "Python", "FastAPI", "Django", "ML / data" | `project-backend-python` |

Once chosen, use only the matching stack rows below — do NOT include all three in
the generated tech design.

---

```markdown
# {Project Name} — Technical Design Specification

**Version**: 1.0
**Date**: {today}
**Backend stack**: {Node.js / Go / Python}    ← FILL THIS IN AT THE TOP
**Companion docs**: PRD.md, UIUX_SPEC.md

---

## 1. Architecture Overview

### 1.1 System Diagram

\`\`\`mermaid
graph TB
    Client[Frontend Web App]
    Mobile[Mobile App]
    API[Backend API]
    DB[(PostgreSQL)]
    Cache[(Redis)]
    Storage[(S3 / object storage)]
    Queue[Background workers]
    Email[SendGrid]

    Client --> API
    Mobile --> API
    API --> DB
    API --> Cache
    API --> Storage
    API --> Queue
    Queue --> Email
\`\`\`

### 1.2 High-Level Approach
{2–3 paragraphs describing the architecture style — monolith vs microservices,
SSR vs SPA, REST vs GraphQL, sync vs async patterns. Justify the choices,
including the backend language choice.}

---

## 2. Tech Stack

### 2.1 Frontend (all stacks share these)

| Layer | Technology | Version | Why |
|-------|-----------|---------|-----|
| Frontend | React + TypeScript | 18.x | {rationale} |
| Frontend bundler | Vite | 5.x | {rationale} |
| Styling | Tailwind CSS | 3.x | {rationale} |
| State | TanStack Query + Zustand | latest | {rationale} |
| i18n | react-i18next | latest | {rationale} |

### 2.2 Backend — choose ONE block below based on the stack decision

#### Option A: Node.js / TypeScript stack
| Layer | Technology | Version | Why |
|-------|-----------|---------|-----|
| Backend | Node.js + TypeScript | 20 LTS | {rationale} |
| Web framework | Fastify | 4.x | {rationale} |
| ORM | Prisma | 5.x | {rationale} |
| Job queue | BullMQ | latest | {rationale} |
| Validation | Zod | latest | {rationale} |
| i18n | i18next + i18next-fs-backend | latest | {rationale} |
| Testing | Vitest + Testcontainers | latest | {rationale} |

#### Option B: Go stack
| Layer | Technology | Version | Why |
|-------|-----------|---------|-----|
| Backend | Go | 1.22+ | {rationale} |
| Web framework | Gin (or Echo, Chi, Fiber) | latest | {rationale} |
| ORM | GORM v2 (or sqlx + sqlc) | latest | {rationale} |
| Migrations | golang-migrate | latest | {rationale} |
| Job queue | asynq | latest | {rationale} |
| Validation | go-playground/validator | v10 | {rationale} |
| i18n | nicksnyder/go-i18n | v2 (TOML catalogues) | {rationale} |
| Testing | testify + testcontainers-go | latest | {rationale} |

#### Option C: Python stack
| Layer | Technology | Version | Why |
|-------|-----------|---------|-----|
| Backend | Python | 3.12+ | {rationale} |
| Web framework | FastAPI (or Django REST, Flask) | 0.110+ | {rationale} |
| ASGI server | uvicorn (prod: gunicorn + uvicorn workers) | latest | {rationale} |
| ORM | SQLAlchemy 2.0 async | latest | {rationale} |
| Migrations | Alembic | latest | {rationale} |
| Job queue | Celery (or arq) | latest | {rationale} |
| Validation | Pydantic v2 | latest | {rationale} |
| i18n | Babel (.po/.mo files) | latest | {rationale} |
| Testing | pytest + pytest-asyncio + httpx | latest | {rationale} |

### 2.3 Shared infrastructure (all stacks)

| Layer | Technology | Version | Why |
|-------|-----------|---------|-----|
| Database | PostgreSQL | 15.x | {rationale} |
| Cache | Redis | 7.x | {rationale} |
| Object storage | AWS S3 | — | {rationale} |
| Email | SendGrid | — | {rationale} |
| Auth tokens | JWT (RS256) | — | {rationale} |
| Monitoring | Sentry | — | {rationale} |
| Container | Docker + docker-compose | — | {rationale} |

---

## 3. Database Schema

The schema is language-agnostic — it's plain PostgreSQL DDL. The ORM-specific
representation (Prisma schema / GORM struct / SQLAlchemy model) lives in the
generated backend code.

ONE SECTION PER TABLE. Derived from prototype mock data + business rules in PRD.

### 3.1 users
| Column | Type | Constraints | Description |
|--------|------|-------------|-------------|
| id | UUID | PK | |
| email | VARCHAR(255) | UNIQUE, NOT NULL | |
| password_hash | VARCHAR(255) | NOT NULL | bcrypt |
| display_name | VARCHAR(100) | NOT NULL | |
| avatar_url | VARCHAR(500) | NULL | S3 CDN URL |
| roles | TEXT[] | NOT NULL DEFAULT '{}' | e.g. ['creator', 'buyer'] |
| created_at | TIMESTAMPTZ | NOT NULL DEFAULT now() | |
| updated_at | TIMESTAMPTZ | NOT NULL DEFAULT now() | |

**Indexes**:
- `idx_users_email` (email)

### 3.2 {next table}
{Repeat for every table}

### Common patterns to include
- `id` UUID primary key on every table
- `created_at`, `updated_at` timestamps on every table
- Soft-delete column `deleted_at` where appropriate
- Foreign keys named `{referenced_table_singular}_id`
- Indexes on every foreign key
- Indexes on every column used in WHERE / ORDER BY in the API spec

---

## 4. API Specification

The API spec is language-agnostic — it describes HTTP contracts. The
language-specific implementation (Fastify routes / Gin handlers / FastAPI routes)
lives in the generated backend code.

### 4.1 Conventions

- **Base URL**: `/api/v1`
- **Auth**: `Authorization: Bearer {jwt}` header on all protected routes
- **Content-Type**: `application/json` (multipart for file uploads)
- **Pagination**: `?page=1&limit=20` query params; response includes `{data, total, page, limit}`
- **Filtering**: `?status=active&category=foo`
- **Sorting**: `?sort=created_at&order=desc`
- **Errors**: `{ error: { code: 'CODE', message: 'human readable', details: {...} } }`
- **Status codes**: 200 ok, 201 created, 204 no-content, 400 bad-request,
  401 unauthorised, 403 forbidden, 404 not-found, 409 conflict, 422 validation-error,
  500 server-error
- **Accept-Language header**: API honours this to localise error messages
  (en, zh-TW by default; fallback to en)

### 4.2 Auth Endpoints

#### POST /api/v1/auth/register
- **Auth**: none
- **Body**: `{ email, password, display_name }`
- **Response**: `201 { user, access_token, refresh_token }`
- **Validation**: email format, password ≥ 8 chars, display_name 2-100 chars
- **Owning task**: BE-003 Auth Service

#### POST /api/v1/auth/login
- **Body**: `{ email, password }`
- **Response**: `200 { user, access_token, refresh_token }`
- **Owning task**: BE-003 Auth Service

#### POST /api/v1/auth/refresh
- **Body**: `{ refresh_token }`
- **Response**: `200 { access_token, refresh_token }`
- **Owning task**: BE-003 Auth Service

#### POST /api/v1/auth/logout
- **Auth**: required
- **Response**: `204`
- **Owning task**: BE-003 Auth Service

#### POST /api/v1/auth/forgot-password
- **Body**: `{ email }`
- **Response**: `204` (always — don't leak existence)
- **Owning task**: BE-003 Auth Service

#### POST /api/v1/auth/reset-password
- **Body**: `{ token, new_password }`
- **Response**: `204`
- **Owning task**: BE-003 Auth Service

### 4.3 {Resource} Endpoints

{Repeat the pattern above for every resource. EVERY action visible in the
prototype must have a corresponding endpoint. Every endpoint must include
auth requirements, request body schema, response schema, key validation rules,
and **the owning task ID** from the task-breakdown — this drives module folder
organisation in the generated backend regardless of language.}

Coverage checklist (every prototype action → endpoint):
- [ ] List (GET /resource)
- [ ] Detail (GET /resource/:id)
- [ ] Create (POST /resource)
- [ ] Update (PUT or PATCH /resource/:id)
- [ ] Delete (DELETE /resource/:id)
- [ ] Custom actions (POST /resource/:id/action)

---

## 5. Authentication and Authorisation

### 5.1 Auth Strategy (language-agnostic)
- **Token format**: JWT with RS256 signing
- **Access token TTL**: 15 minutes
- **Refresh token TTL**: 30 days, stored in httpOnly cookie
- **Rotation**: refresh token rotates on every refresh call
- **Public key**: distributed to all services for stateless verification
- **Library per stack**:
  - Node.js → `jsonwebtoken`
  - Go → `golang-jwt/jwt/v5`
  - Python → `python-jose`

### 5.2 Authorisation
- **Approach**: Role-based access control (RBAC) — roles stored in user.roles array
- **Roles**: {list from PRD personas}
- **Resource ownership**: enforced at the route handler level
- **Admin override**: users with `admin` role can override ownership checks
- **Pattern per stack**:
  - Node.js / Fastify → middleware: `requireAuth`, `requireRole(...allowed)`
  - Go / Gin → middleware: `RequireAuth()`, `RequireRole(...allowed)`
  - Python / FastAPI → dependencies: `Depends(require_auth)`, `Depends(require_role(...))`

### 5.3 Protected Resources
| Resource | Public read | Auth read | Owner write | Admin write |
|----------|------------|-----------|-------------|-------------|
| {resource} | {y/n} | {y/n} | {y/n} | {y/n} |

---

## 6. External Integrations

Each integration has language-specific SDK choice but the same wrapper pattern.

### 6.1 {Integration name, e.g. "Stripe"}
- **Purpose**: payment processing
- **Auth**: `STRIPE_SECRET_KEY` env var
- **Endpoints used**: `POST /v1/payment_intents`, etc.
- **Webhooks received**: `payment_intent.succeeded`, `charge.refunded`
- **Failure mode**: queue retry with exponential backoff
- **Test mode**: separate test keys in non-prod env
- **SDK per stack**:
  - Node.js → `stripe` (official)
  - Go → `stripe/stripe-go/v76`
  - Python → `stripe` (official)
- **Owning task**: BE-XXX (per task breakdown)

{Repeat for every external integration: email provider, file storage, payment,
analytics, push notifications, blockchain RPC, etc.}

---

## 7. Background Jobs and Workers

The queue technology depends on the backend stack but jobs are language-agnostic
in scope.

### Stack-specific queue choice
- Node.js → **BullMQ** (Redis-backed, full-featured, mature in TS ecosystem)
- Go → **asynq** (Redis-backed, BullMQ-equivalent semantics)
- Python → **Celery** (default — full-featured) OR **arq** (async-native, lighter)

### Per-job spec

#### 7.1 {Job name}
- **Trigger**: {event / schedule}
- **Concurrency**: N workers
- **Retry policy**: exponential backoff, max N attempts
- **Failure handling**: alert via Sentry, push to dead-letter queue
- **Owning task**: BE-XXX

Common jobs:
- Send email (transactional)
- Process file upload (resize images, scan for malware)
- Generate thumbnails / previews
- Send push notifications
- Periodic cleanup (expired sessions, soft-deleted records)
- Webhook delivery to external systems

---

## 8. Security Considerations

Same posture across all stacks:

- **Input validation**: stack-specific
  - Node.js → Zod schemas on every request body
  - Go → struct tags via go-playground/validator
  - Python → Pydantic v2 models
- **SQL injection**: prevented by parameterised queries / ORM
- **XSS**: React auto-escapes; CSP header set on all responses
- **CSRF**: SameSite=Lax on cookies; CSRF token for state-changing GET requests
- **Rate limiting**: per-IP global (60 req/min), per-user authenticated (1000 req/hr)
  - Node.js → `@fastify/rate-limit`
  - Go → custom middleware backed by Redis
  - Python → `slowapi`
- **Secrets management**: env vars in dev, AWS SSM Parameter Store in prod
- **Encryption at rest**: PostgreSQL TDE, S3 SSE-KMS
- **Encryption in transit**: TLS 1.3 minimum
- **Password storage**: bcrypt with cost factor 12
- **PII handling**: GDPR — data export and deletion endpoints required

---

## 9. Deployment Architecture

- **Containerisation**: Docker (multi-stage build per stack)
  - Node.js → node:20-alpine builder → distroless/nodejs20-debian12 runtime
  - Go → golang:1.22-alpine builder → distroless/static-debian12 runtime
  - Python → python:3.12-slim builder → python:3.12-slim runtime (cannot use distroless)
- **Orchestration**: Kubernetes / ECS / Cloud Run / Fly.io
- **Environments**: dev, staging, production — each with own DB
- **CI/CD**: GitHub Actions — test → build → deploy
- **Database migrations**:
  - Node.js → `prisma migrate deploy`
  - Go → `golang-migrate` CLI in init container
  - Python → `alembic upgrade head`
- **Zero-downtime deploys**: rolling update strategy
- **Rollback procedure**: image tag rollback, DB migration rollback if reversible

---

## 10. Performance Targets

Same SLOs across all stacks. Stack choice may influence cost-per-RPS but the
targets are constant:

| Metric | Target |
|--------|--------|
| API p50 latency | < 100ms |
| API p95 latency | < 500ms |
| API p99 latency | < 1s |
| Frontend LCP | < 2.5s |
| Frontend CLS | < 0.1 |
| Uptime SLA | 99.9% |
| Concurrent users supported (initial) | 1,000 |

Stack-specific notes:
- Go and Node typically deliver lower p95 than Python at equivalent compute cost
- If targets must be met on minimal compute, prefer Go; otherwise all three meet
  the targets with appropriate horizontal scaling

---

## 11. Internationalisation Strategy

i18n is supported by ALL three backend stacks, but the library and message file
format differ:

### Frontend (all stacks share)
- **Library**: react-i18next with i18next-http-backend
- **Default locale**: `en`
- **Supported locales**: `en`, `zh-TW`
- **Fallback chain**: `zh-TW` → `en`
- **Storage**: JSON files per locale, namespaced by feature
  ```
  public/locales/
  ├── en/
  │   ├── common.json
  │   ├── auth.json
  │   └── {feature}.json
  └── zh-TW/
      └── ...
  ```

### Backend — choose ONE based on stack

#### Node.js
- **Library**: i18next with i18next-fs-backend
- **Storage**: JSON files per locale, mirroring frontend structure
  ```
  locales/
  ├── en/
  │   ├── errors.json
  │   ├── emails.json
  │   └── {feature}.json
  └── zh-TW/
      └── ...
  ```

#### Go
- **Library**: nicksnyder/go-i18n/v2
- **Storage**: TOML message catalogues (one file per locale)
  ```
  locales/
  ├── active.en.toml
  └── active.zh-TW.toml
  ```
- Module-specific keys prefixed (`auth.*`, `ipassets.*`, etc.)

#### Python
- **Library**: Babel (GNU gettext format)
- **Storage**: `.po` source files compiled to `.mo` binaries
  ```
  locales/
  ├── en/LC_MESSAGES/
  │   ├── messages.po
  │   └── messages.mo
  └── zh_TW/LC_MESSAGES/
      ├── messages.po
      └── messages.mo
  ```
- Compile step: `pybabel compile -d locales` (added to Makefile)

### Shared behaviour (all stacks)
- **Detection**: Accept-Language header → user preference → default
- **API responses**: error messages localised based on Accept-Language header
- **Currency / dates**: formatted client-side via Intl API
- **Error response shape**: `{ error: { code, message } }` where `message` is
  pre-localised by the backend

---

## 12. Open Technical Questions

Decisions needed before implementation:
- [ ] {Q1: e.g. "Custodial or non-custodial wallet for crypto payments?"}
- [ ] {Q2: e.g. "SQL or NoSQL for the analytics events table?"}
- [ ] **Backend language confirmed**: {Node.js / Go / Python}
- [ ] **Job queue confirmed**: {BullMQ / asynq / Celery / arq}
- [ ] **ORM confirmed**: {Prisma / GORM / SQLAlchemy}
```
