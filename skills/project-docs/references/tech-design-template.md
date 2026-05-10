# Tech Design Template Reference

Use this exact structure when generating TECH_DESIGN.md.

---

```markdown
# {Project Name} — Technical Design Specification

**Version**: 1.0
**Date**: {today}
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
    Queue[BullMQ workers]
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
SSR vs SPA, REST vs GraphQL, sync vs async patterns. Justify the choices.}

---

## 2. Tech Stack

| Layer | Technology | Version | Why |
|-------|-----------|---------|-----|
| Frontend | React + TypeScript | 18.x | {rationale} |
| Frontend bundler | Vite | 5.x | {rationale} |
| Styling | Tailwind CSS | 3.x | {rationale} |
| State | TanStack Query + Zustand | latest | {rationale} |
| i18n | react-i18next | latest | {rationale} |
| Backend | Node.js + TypeScript | 20 LTS | {rationale} |
| Web framework | Fastify | 4.x | {rationale} |
| ORM | Prisma | 5.x | {rationale} |
| Database | PostgreSQL | 15.x | {rationale} |
| Cache / Queue | Redis | 7.x | {rationale} |
| Job queue | BullMQ | latest | {rationale} |
| Object storage | AWS S3 | — | {rationale} |
| Email | SendGrid | — | {rationale} |
| Auth | JWT (RS256) | — | {rationale} |

---

## 3. Database Schema

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

### 4.2 Auth Endpoints

#### POST /api/v1/auth/register
- **Auth**: none
- **Body**: `{ email, password, display_name }`
- **Response**: `201 { user, access_token, refresh_token }`
- **Validation**: email format, password ≥ 8 chars, display_name 2-100 chars

#### POST /api/v1/auth/login
- **Body**: `{ email, password }`
- **Response**: `200 { user, access_token, refresh_token }`

#### POST /api/v1/auth/refresh
- **Body**: `{ refresh_token }`
- **Response**: `200 { access_token, refresh_token }`

#### POST /api/v1/auth/logout
- **Auth**: required
- **Response**: `204`

#### POST /api/v1/auth/forgot-password
- **Body**: `{ email }`
- **Response**: `204` (always — don't leak existence)

#### POST /api/v1/auth/reset-password
- **Body**: `{ token, new_password }`
- **Response**: `204`

### 4.3 {Resource} Endpoints

{Repeat the pattern above for every resource. EVERY action visible in the
prototype must have a corresponding endpoint. Every endpoint must include
auth requirements, request body schema, response schema, and key validation rules.}

Coverage checklist (every prototype action → endpoint):
- [ ] List (GET /resource)
- [ ] Detail (GET /resource/:id)
- [ ] Create (POST /resource)
- [ ] Update (PUT or PATCH /resource/:id)
- [ ] Delete (DELETE /resource/:id)
- [ ] Custom actions (POST /resource/:id/action)

---

## 5. Authentication and Authorisation

### 5.1 Auth Strategy
- **Token format**: JWT with RS256 signing
- **Access token TTL**: 15 minutes
- **Refresh token TTL**: 30 days, stored in httpOnly cookie
- **Rotation**: refresh token rotates on every refresh call
- **Public key**: distributed to all services for stateless verification

### 5.2 Authorisation
- **Approach**: Role-based access control (RBAC) — roles stored in user.roles array
- **Roles**: {list from PRD personas}
- **Resource ownership**: enforced at the route handler level
  (e.g. only owner can update their own IP asset)
- **Admin override**: users with `admin` role can override ownership checks

### 5.3 Protected Resources
| Resource | Public read | Auth read | Owner write | Admin write |
|----------|------------|-----------|-------------|-------------|
| {resource} | {y/n} | {y/n} | {y/n} | {y/n} |

---

## 6. External Integrations

### 6.1 {Integration name, e.g. "Stripe"}
- **Purpose**: payment processing
- **Auth**: `STRIPE_SECRET_KEY` env var
- **Endpoints used**: `POST /v1/payment_intents`, etc.
- **Webhooks received**: `payment_intent.succeeded`, `charge.refunded`
- **Failure mode**: queue retry with exponential backoff
- **Test mode**: separate test keys in non-prod env

{Repeat for every external integration: email provider, file storage, payment,
analytics, push notifications, blockchain RPC, etc.}

---

## 7. Background Jobs and Workers

ONE SECTION PER JOB.

### 7.1 {Job name}
- **Trigger**: {event / schedule}
- **Queue**: BullMQ queue name
- **Concurrency**: N
- **Retry policy**: exponential backoff, max N attempts
- **Failure handling**: alert via Sentry, push to dead-letter queue

Common jobs:
- Send email (transactional)
- Process file upload (resize images, scan for malware)
- Generate thumbnails / previews
- Send push notifications
- Periodic cleanup (expired sessions, soft-deleted records)
- Webhook delivery to external systems

---

## 8. Security Considerations

- **Input validation**: Zod schemas on every request body
- **SQL injection**: prevented by Prisma parameterised queries
- **XSS**: React auto-escapes; CSP header set on all responses
- **CSRF**: SameSite=Lax on cookies; CSRF token for state-changing GET requests
- **Rate limiting**: per-IP global (60 req/min), per-user authenticated (1000 req/hr)
- **Secrets management**: env vars in dev, AWS SSM Parameter Store in prod
- **Encryption at rest**: PostgreSQL TDE, S3 SSE-KMS
- **Encryption in transit**: TLS 1.3 minimum
- **Password storage**: bcrypt with cost factor 12
- **PII handling**: GDPR — data export and deletion endpoints required

---

## 9. Deployment Architecture

- **Containerisation**: Docker
- **Orchestration**: Kubernetes / ECS / Cloud Run
- **Environments**: dev, staging, production — each with own DB
- **CI/CD**: GitHub Actions — test → build → deploy
- **Database migrations**: Prisma migrate, run automatically on deploy
- **Zero-downtime deploys**: rolling update strategy
- **Rollback procedure**: image tag rollback, DB migration rollback if reversible

---

## 10. Performance Targets

| Metric | Target |
|--------|--------|
| API p50 latency | < 100ms |
| API p95 latency | < 500ms |
| API p99 latency | < 1s |
| Frontend LCP | < 2.5s |
| Frontend CLS | < 0.1 |
| Uptime SLA | 99.9% |
| Concurrent users supported (initial) | 1,000 |

---

## 11. Internationalisation Strategy

- **Library (frontend)**: react-i18next with i18next-http-backend
- **Library (backend)**: i18next with i18next-fs-backend
- **Default locale**: `en`
- **Supported locales**: `en`, `zh-TW`
- **Fallback chain**: `zh-TW` → `en`
- **Storage**: JSON files per locale, namespaced by feature
  ```
  locales/
  ├── en/
  │   ├── common.json
  │   ├── auth.json
  │   └── {feature}.json
  └── zh-TW/
      ├── common.json
      └── ...
  ```
- **Detection**: Accept-Language header → user preference → default
- **API responses**: error messages localised based on Accept-Language header
- **Currency / dates**: formatted client-side via Intl API

---

## 12. Open Technical Questions

Decisions needed before implementation:
- [ ] {Q1: e.g. "Custodial or non-custodial wallet for crypto payments?"}
- [ ] {Q2: e.g. "SQL or NoSQL for the analytics events table?"}
```
