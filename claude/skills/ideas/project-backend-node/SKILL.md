---
name: project-backend-node
description: >
  Generates a production-grade Node.js/TypeScript backend application from project docs
  (PRD + tech design) AND the task breakdown. Output is a Fastify + Prisma + PostgreSQL
  + Redis + BullMQ project with i18n (English + Traditional Chinese error messages),
  service organisation aligned with task-breakdown backend components (each task ID
  maps to a real module folder), every API endpoint from the tech design, database
  migrations, JWT auth + RBAC, background workers, and external integrations.

  USE THIS SKILL when the user wants a Node.js backend specifically. Trigger when:
  - the tech design specifies Node.js / TypeScript / Fastify / Express / NestJS as the
    backend stack
  - the user explicitly asks for "Node backend", "TypeScript API", "JavaScript backend"
  - the user says "build the backend" without specifying a language AND the tech design
    is silent on stack choice (Node.js is the default)
  Do NOT trigger this skill if the tech design specifies Go or Python — use
  project-backend-go or project-backend-python respectively.
---

# Project Backend Generator

Step 5b (parallel with project-frontend) of the project-quick-start workflow.
**Position: AFTER task-breakdown.**

Builds a production-grade Node.js/TypeScript backend from THREE sources of truth:
1. Project docs (PRD, tech design) — the *what*
2. Task breakdown (AGENT.md, DEPENDENCY_GRAPH.md, task files) — the *how-organised*
3. User overrides if provided — explicit decisions

The generated code's service organisation mirrors the task breakdown's backend
components, so each backend task ID (e.g. `BE-003 Auth Service`) maps to a real
service folder. When an AI agent picks up a task, the corresponding code folder
already exists.

This is **not** scaffolding — every endpoint specified in the tech design is fully
implemented with validation, error handling, auth checks, and database operations.

---

## Step 0 — Inputs

Required:
- [ ] PRD.md (for business rules and validation requirements)
- [ ] TECH_DESIGN.md (especially API spec + database schema sections)
- [ ] Task breakdown tar (or its extracted contents) — specifically:
  - [ ] `AGENT.md` (for project conventions and prompt templates)
  - [ ] `DEPENDENCY_GRAPH.md` (for backend component list and ordering)
  - [ ] `tasks/` folder with all backend task files
  - [ ] `CONVENTIONS.md` (for naming and style)

Optional:
- [ ] UIUX_SPEC.md (cross-reference for endpoint coverage from the user's view)

If the user has not run task-breakdown yet, ASK FIRST whether to:
- (a) Run task-breakdown first (recommended) — produces aligned service organisation
- (b) Generate without task plan using flat default structure (faster but less organised)

Default to (a) unless the user explicitly says otherwise.

---

## Step 1 — Parse the Task Breakdown First

Before scaffolding any code, read the task breakdown:

1. **Open `DEPENDENCY_GRAPH.md`** — list every backend-related task ID and title
2. **Open each backend task file** in `tasks/` — extract:
   - Service / module name (the folder this becomes)
   - Listed file paths in "Expected Outputs" — these become the actual file structure
   - Endpoints owned by this task
   - Workers / jobs owned by this task
3. **Open `CONVENTIONS.md`** — apply the project's naming, port allocation, etc.
4. **Open `AGENT.md`** — read section 4 (Standard Prompt Templates) for the project's
   preferred backend stack if it differs from defaults

The structure of the generated backend MUST mirror the backend task component list.
Do not improvise organisation when the task breakdown specifies it.

---

## Step 2 — Tech Stack (defaults)

Unless AGENT.md / tech design specified otherwise:

- **Runtime**: Node.js 20 LTS + TypeScript strict mode
- **Web framework**: Fastify 4 + @fastify/swagger (auto-generated OpenAPI)
- **ORM**: Prisma 5
- **Database**: PostgreSQL 15
- **Cache**: Redis 7
- **Queue**: BullMQ
- **Validation**: Zod (request/response schemas)
- **Auth**: JWT (RS256) + bcrypt
- **i18n**: i18next + i18next-fs-backend
- **Logger**: Pino
- **Testing**: Vitest + Testcontainers
- **Email**: SendGrid (via @sendgrid/mail)
- **File storage**: AWS S3 (via @aws-sdk/client-s3)
- **Monitoring**: Sentry SDK
- **Container**: Docker + docker-compose for local dev

If tech design or AGENT.md specifies different choices, follow them.

---

## Step 3 — Project Structure (aligned with task breakdown)

The structure is derived from the task breakdown's backend task list. The general
shape:

```
{project-name}-backend/
├── package.json
├── tsconfig.json
├── .env.example
├── .eslintrc.cjs
├── docker-compose.yml          # local: postgres + redis
├── Dockerfile
├── README.md
├── prisma/
│   ├── schema.prisma           # full DB schema from TECH_DESIGN
│   ├── migrations/
│   └── seed.ts                 # dev seed data
├── locales/
│   ├── en/
│   │   ├── errors.json
│   │   ├── emails.json
│   │   └── {feature}.json      # one file per feature task
│   └── zh-TW/
│       └── ... (mirror)
└── src/
    ├── server.ts               # Fastify app entrypoint
    ├── config/
    │   ├── env.ts              # zod-validated env vars
    │   └── i18n.ts
    ├── plugins/                # Fastify plugins
    │   ├── auth.ts
    │   ├── i18n.ts
    │   ├── error-handler.ts
    │   ├── rate-limit.ts
    │   └── swagger.ts
    ├── modules/                # ONE FOLDER PER BACKEND TASK ID
    │   ├── {task-id-slug}/     # e.g. be-003-auth/
    │   │   ├── README.md       # links back to tasks/.../BE-003-auth.md
    │   │   ├── routes.ts       # endpoints owned by this task
    │   │   ├── service.ts      # business logic
    │   │   ├── schemas.ts      # Zod schemas for req/res
    │   │   ├── workers.ts      # background jobs (if any)
    │   │   ├── tests/          # integration tests for this module
    │   │   └── index.ts        # exports for plugin registration
    │   └── ...
    ├── lib/
    │   ├── prisma.ts           # singleton Prisma client
    │   ├── redis.ts
    │   ├── s3.ts
    │   ├── sendgrid.ts
    │   ├── crypto.ts
    │   └── jwt.ts
    ├── middleware/
    │   ├── auth.ts
    │   ├── rbac.ts
    │   └── audit-log.ts
    ├── types/
    └── utils/
```

### Key alignment rule
For every backend task in the task breakdown:
1. Create a folder in `src/modules/` named `{task-id-slug}/`
2. Add a `README.md` linking back to the source task file
3. Place all module-scoped code (routes, service, schemas, workers, tests) inside
4. The Fastify app registers each module's `routes.ts` plugin from `src/server.ts`

This gives a 1-to-1 mapping: when an AI agent picks up `BE-003 Auth Service`, it
knows exactly where to work. Workers also live in their owning module.

---

## Step 4 — Database Schema

Translate every table from TECH_DESIGN.md section 3 directly into `prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id           String   @id @default(uuid())
  email        String   @unique
  passwordHash String   @map("password_hash")
  displayName  String   @map("display_name")
  avatarUrl    String?  @map("avatar_url")
  roles        String[]
  createdAt    DateTime @default(now()) @map("created_at")
  updatedAt    DateTime @updatedAt @map("updated_at")

  ipAssets     IpAsset[]

  @@map("users")
}

// ... one model per table from TECH_DESIGN
```

### Migration baseline + seed
- Run `npx prisma migrate dev --name init` → commit `prisma/migrations/0001_init/`
- Seed data in `prisma/seed.ts` — 5 users (one per role), 10 records per primary
  entity, all foreign keys cross-referenced, mix of statuses

---

## Step 5 — i18n Setup

### Configuration

```ts
// src/config/i18n.ts
import i18next from 'i18next';
import Backend from 'i18next-fs-backend';
import path from 'path';

await i18next.use(Backend).init({
  fallbackLng: 'en',
  preload: ['en', 'zh-TW'],
  ns: ['errors', 'emails', /* one per backend task module */],
  defaultNS: 'errors',
  backend: {
    loadPath: path.join(__dirname, '../../locales/{{lng}}/{{ns}}.json'),
  },
});

export default i18next;
```

### Per-request localisation
Fastify plugin reads `Accept-Language`, picks supported locale, attaches to request:

```ts
// src/plugins/i18n.ts
fastify.decorateRequest('t', null);
fastify.addHook('onRequest', async (req) => {
  const lang = pickLanguage(req.headers['accept-language']);
  req.t = i18next.getFixedT(lang);
});
```

### Localised error responses
All errors thrown by route handlers include a translation key:
```ts
throw new ApiError('errors:auth.invalidCredentials', 401);
```

Error handler resolves the key against the request's locale:
```ts
return reply.status(error.status).send({
  error: { code: error.code, message: req.t(error.code) }
});
```

Translation file location follows module organisation:
- `locales/en/errors.json` — global error keys
- `locales/en/auth.json` — owned by `src/modules/be-003-auth/`
- `locales/zh-TW/auth.json` — translations

---

## Step 6 — Auth Implementation

### JWT with RS256
```ts
// src/lib/jwt.ts
import jwt from 'jsonwebtoken';
import { env } from '@/config/env';

export const signAccessToken = (userId: string, roles: string[]) =>
  jwt.sign({ sub: userId, roles }, env.JWT_PRIVATE_KEY, {
    algorithm: 'RS256',
    expiresIn: '15m',
  });

export const signRefreshToken = (userId: string) =>
  jwt.sign({ sub: userId, type: 'refresh' }, env.JWT_PRIVATE_KEY, {
    algorithm: 'RS256',
    expiresIn: '30d',
  });

export const verifyToken = (token: string) =>
  jwt.verify(token, env.JWT_PUBLIC_KEY, { algorithms: ['RS256'] });
```

### Auth middleware
```ts
// src/middleware/auth.ts
export const requireAuth = async (req, reply) => {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) throw new ApiError('errors:auth.missingToken', 401);
  try {
    const payload = verifyToken(token);
    req.user = await prisma.user.findUnique({ where: { id: payload.sub } });
    if (!req.user) throw new ApiError('errors:auth.userNotFound', 401);
  } catch {
    throw new ApiError('errors:auth.invalidToken', 401);
  }
};
```

### RBAC
```ts
// src/middleware/rbac.ts
export const requireRole = (...allowed: string[]) => async (req, reply) => {
  if (!req.user.roles.some(r => allowed.includes(r))) {
    throw new ApiError('errors:auth.forbidden', 403);
  }
};
```

### Refresh token rotation
- Refresh tokens stored in Redis with TTL = 30 days
- On refresh: validate, issue new pair, blocklist old refresh token
- On logout: blocklist refresh token

---

## Step 7 — Endpoint Implementation

For EVERY endpoint in TECH_DESIGN.md section 4:

1. **Find which task module owns this endpoint** by reading the task files
2. **Place the route + handler inside that module** (not in a global routes file)
3. **Zod schema** for request body, query params, response (in module's `schemas.ts`)
4. **Route handler** in module's `routes.ts`:
   - `requireAuth` if protected
   - `requireRole` if role-restricted
   - Validate input via Zod
   - Call service layer
   - Return response with appropriate status code
5. **Service function** in module's `service.ts`:
   - Business logic
   - Database operations via Prisma
   - Authorisation checks (ownership, etc.)
   - Trigger background jobs if needed
6. **Tests** in module's `tests/`:
   - Happy path
   - Auth failure
   - Authorisation failure
   - Validation failure
   - Not found

### Endpoint coverage checklist
Cross-reference TECH_DESIGN.md section 4 — every endpoint must:
- [ ] Belong to a specific task module (per the task breakdown)
- [ ] Have a route handler in that module's `routes.ts`
- [ ] Have a Zod schema in that module's `schemas.ts`
- [ ] Have a service function (no business logic in route handlers)
- [ ] Have an integration test in that module's `tests/`
- [ ] Be registered via the module's plugin export
- [ ] Appear in the auto-generated Swagger / OpenAPI spec

NEVER skip an endpoint. NEVER stub one with `TODO`. If unsure how to implement,
ask the user before proceeding.

---

## Step 8 — Background Workers

For each job listed in TECH_DESIGN.md section 7:

1. Identify which task module owns the job (per task breakdown)
2. Place the worker in that module's `workers.ts`
3. The producer (service that enqueues the job) is in the same module
4. BullMQ queue defined in `src/lib/queues.ts` with key registered to the module

Workers run as separate processes in production. Locally, all workers can run in
one process via `pnpm dev:workers`.

---

## Step 9 — External Integrations

For each external service in TECH_DESIGN.md section 6:

1. Wrapper in `src/lib/{service}.ts` (project-wide)
2. Modules use the wrapper, never the raw SDK
3. Mock implementation in `tests/mocks/{service}.ts` for testing
4. Env vars in `.env.example`
5. Webhook endpoint (if applicable) in the owning task module's `routes.ts` with
   signature verification

Common integrations:
- SendGrid (email)
- AWS S3 (file storage)
- Stripe (payments)
- Sentry (error monitoring)
- Domain-specific: blockchain RPC, Twilio, OAuth providers, etc.

---

## Step 10 — Quality Standards

### Required
- TypeScript strict mode — zero `any`
- All routes validated via Zod schemas
- All errors localised via i18next
- All sensitive operations audited (write to `audit_log` table)
- Rate limiting via @fastify/rate-limit (60 req/min per IP, 1000 req/hr per user)
- CORS configured for known frontend origins only
- Helmet security headers
- Pino structured logging (JSON in prod, pretty in dev)
- Sentry error capture
- Health check endpoint (`GET /health`)
- OpenAPI spec auto-generated and served at `/docs`

### Required toolchain
- ESLint + Prettier — `pnpm lint && pnpm format` clean
- TypeScript — `pnpm typecheck` passes
- Vitest — `pnpm test` passes (unit + integration)
- Test coverage ≥ 80% for service layer, ≥ 60% overall

### Code quality reference
Apply the `dev-node/*` skill pack as the canonical style and quality reference
during generation. The most directly relevant skills:
- `node-style-core`, `node-naming`, `node-types` — foundational style and type discipline
- `node-modules`, `node-async`, `node-error-handling`, `node-control-flow`, `node-functions`, `node-data-structures`, `node-classes`, `node-streams`
- `node-testing`, `node-logging`, `node-config`, `node-http`, `node-security`, `node-performance`
- `node-documentation`, `node-linting`, `node-code-review` (for the final review pass)

### .env.example (full)
```
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/myapp
REDIS_URL=redis://localhost:6379
JWT_PRIVATE_KEY=                     # PEM, multiline
JWT_PUBLIC_KEY=                      # PEM, multiline
SENDGRID_API_KEY=
SENDGRID_FROM_EMAIL=noreply@example.com
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
AWS_REGION=us-east-1
S3_BUCKET=
SENTRY_DSN=
CORS_ORIGINS=http://localhost:5173
```

---

## Step 11 — Cross-reference task files

For every module folder created, the README.md inside it MUST link back to the
source task file:

```markdown
# Module: Auth (BE-003)

This module implements the auth service described in:
**[../../tasks/03-backend/BE-003-auth.md](../../tasks/03-backend/BE-003-auth.md)**

## Endpoints owned
- POST /api/v1/auth/register
- POST /api/v1/auth/login
- POST /api/v1/auth/refresh
- POST /api/v1/auth/logout
- POST /api/v1/auth/forgot-password
- POST /api/v1/auth/reset-password

## Workers owned
- send-verification-email
- send-password-reset-email

## Status
- [x] Group 01 — Scaffold
- [x] Group 02 — Endpoints
- [ ] Group 03 — Workers
- [ ] Group 04 — Tests

When working on this module, update both this README and the task file.
```

---

## Step 12 — Generation Strategy for Large Backends

If the tech design has > 30 endpoints, generate in batches aligned with task IDs:

**Batch 1 (foundation)**: project scaffold, prisma schema, config, plugins, i18n,
  global lib (NOT module-specific code)
**Batch 2 (auth + user modules)**: BE tasks listed in dependency graph as
  no-dependency or auth-only
**Batch 3 (core domain modules)**: BE tasks that depend on auth
**Batch 4 (integrations + admin modules)**: BE tasks depending on multiple core modules
**Batch 5 (analytics + reporting)**: tail tasks per dependency graph

After each batch:
- Verify with the user that the batch is complete and correct
- Confirm before proceeding to the next batch

This avoids hitting context length limits and gives the user checkpoints aligned
with the task plan.

---

## Step 13 — Deliver

```bash
cd /home/claude
tar -czf {project-name}-backend.tar.gz {project-name}-backend/
cp {project-name}-backend.tar.gz /mnt/user-data/outputs/
```

Include comprehensive README.md:
- Local setup: `docker-compose up -d && pnpm install && pnpm prisma migrate dev && pnpm dev`
- Env vars to configure
- Architecture overview — call out the `src/modules/` ↔ task-breakdown alignment
- API docs URL: http://localhost:3000/docs (Swagger)
- How i18n works
- How to add a new module (recipe — create new task in task plan first)
- How to add a new background worker (recipe)
- Link to the task breakdown tar — this is the source of truth for organisation
- Deployment notes

Use `present_files` to deliver.

---

## Workflow Position

```
prototype → docs → mockup → task-breakdown → project-frontend  +  [YOU ARE HERE]
                                                                   project-backend
```

Final summary:
> "Production backend generated. N modules aligned with N backend task IDs.
> N tables, N endpoints, N workers, N translation keys.
> Setup: `docker-compose up && pnpm install && pnpm prisma migrate dev && pnpm dev`.
> Swagger UI at http://localhost:3000/docs.
> Each `src/modules/{task-id-slug}/` folder links back to its source task file —
> when you work on a task, the corresponding code module is already in place.
> Pair with the **project-frontend** generated frontend — they share both the API
> contract (TECH_DESIGN.md) and the task plan organisation."
