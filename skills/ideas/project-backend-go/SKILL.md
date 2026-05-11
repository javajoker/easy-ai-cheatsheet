---
name: project-backend-go
description: >
  Generates a production-grade Go backend application from project docs (PRD + tech
  design) AND the task breakdown. Output is a Go project using Gin or Echo + GORM or
  sqlx + PostgreSQL + Redis + asynq with i18n (English + Traditional Chinese error
  messages), service organisation aligned with task-breakdown backend components (each
  task ID maps to a real package), every API endpoint from the tech design, database
  migrations via golang-migrate, JWT auth + RBAC middleware, background workers, and
  external integrations.

  USE THIS SKILL when the user wants a Go backend specifically. Trigger when:
  - the tech design specifies Go / Golang / Gin / Echo / Fiber / Chi as the backend stack
  - the user explicitly asks for "Go backend", "Golang API", "build it in Go"
  - the user mentions "performance-critical backend" or "low-latency API" and is open
    to language suggestions (Go is a strong default for those)
  Do NOT trigger this skill for Node.js or Python projects — use project-backend-node
  or project-backend-python instead.
---

# Project Backend Generator (Go)

Step 5b (parallel with project-frontend) of the project-quick-start workflow.
**Position: AFTER task-breakdown.**

Builds a production-grade Go backend from THREE sources of truth:
1. Project docs (PRD, tech design) — the *what*
2. Task breakdown (AGENT.md, DEPENDENCY_GRAPH.md, task files) — the *how-organised*
3. User overrides if provided — explicit decisions

The generated code's package organisation mirrors the task breakdown's backend
components, so each backend task ID (e.g. `BE-003 Auth Service`) maps to a real
Go package under `internal/`. When an AI agent picks up a task, the corresponding
package already exists.

This is **not** scaffolding — every endpoint specified in the tech design is fully
implemented with validation, error handling, auth checks, and database operations.

---

## Step 0 — Inputs

Required:
- [ ] PRD.md (for business rules and validation requirements)
- [ ] TECH_DESIGN.md (especially API spec + database schema sections)
- [ ] Task breakdown tar (or extracted contents) — specifically:
  - [ ] `AGENT.md`
  - [ ] `DEPENDENCY_GRAPH.md`
  - [ ] `tasks/` folder with all backend task files
  - [ ] `CONVENTIONS.md`

Optional:
- [ ] UIUX_SPEC.md (cross-reference for endpoint coverage)

If the user has not run task-breakdown yet, ASK FIRST whether to:
- (a) Run task-breakdown first (recommended) — produces aligned package organisation
- (b) Generate without task plan using flat default structure

Default to (a) unless the user explicitly says otherwise.

---

## Step 1 — Parse the Task Breakdown First

Before scaffolding any code:
1. **Open `DEPENDENCY_GRAPH.md`** — list every backend task ID and title
2. **Open each backend task file** in `tasks/` — extract:
   - Service / module name (becomes the Go package name)
   - File paths in "Expected Outputs" — drives the actual file structure
   - Endpoints owned by this task
   - Workers / jobs owned by this task
3. **Open `CONVENTIONS.md`** — apply project-specific naming conventions
4. **Open `AGENT.md`** — read section 4 for Go-specific stack preferences if any

The package structure of the generated backend MUST mirror the task component list.

---

## Step 2 — Tech Stack (defaults)

Unless AGENT.md / tech design specified otherwise:

- **Language**: Go 1.22+
- **Web framework**: Gin (fallback: Echo, Chi, Fiber)
- **ORM**: GORM v2 (fallback: sqlx with sqlc for type-safe queries)
- **Database**: PostgreSQL 15
- **Migrations**: golang-migrate (file-based SQL migrations)
- **Cache**: Redis 7 via go-redis/v9
- **Job queue**: asynq (Redis-backed, similar API to BullMQ)
- **Validation**: go-playground/validator/v10 + custom struct tags
- **Auth**: golang-jwt/jwt/v5 (RS256) + bcrypt
- **i18n**: nicksnyder/go-i18n/v2 with TOML message catalogues
- **Logger**: zerolog (structured, zero-allocation)
- **Config**: viper or envconfig
- **Testing**: standard library + testify + testcontainers-go
- **Email**: SendGrid Go SDK
- **File storage**: aws-sdk-go-v2/service/s3
- **Monitoring**: sentry-go
- **OpenAPI generation**: swaggo/swag (annotation-based) or chi/render
- **Container**: Docker + docker-compose

If tech design or AGENT.md specifies different choices, follow them.

---

## Step 3 — Project Structure (aligned with task breakdown)

Standard Go project layout (`golang-standards/project-layout`) extended for our
task-aligned modules:

```
{project-name}-backend-go/
├── go.mod
├── go.sum
├── Makefile
├── Dockerfile
├── docker-compose.yml          # postgres + redis
├── .env.example
├── .golangci.yml               # linting config
├── README.md
├── cmd/
│   ├── api/
│   │   └── main.go             # HTTP server entrypoint
│   ├── worker/
│   │   └── main.go             # asynq worker entrypoint
│   └── migrate/
│       └── main.go             # migration runner
├── internal/                   # private packages (Go convention)
│   ├── modules/                # ONE PACKAGE PER BACKEND TASK ID
│   │   ├── {task_id_slug}/     # e.g. be003auth/  (Go package names: lowercase, no hyphens)
│   │   │   ├── README.md       # links back to tasks/.../BE-003-auth.md
│   │   │   ├── handler.go      # HTTP handlers (routes)
│   │   │   ├── service.go      # business logic
│   │   │   ├── dto.go          # request/response types + validation tags
│   │   │   ├── repository.go   # database access
│   │   │   ├── worker.go       # background jobs (if any)
│   │   │   ├── module.go       # module registration (Register(r *gin.Engine))
│   │   │   └── handler_test.go # integration tests
│   │   └── ...
│   ├── platform/               # shared cross-cutting concerns
│   │   ├── config/
│   │   ├── database/           # GORM/sqlx setup
│   │   ├── redis/
│   │   ├── jwt/
│   │   ├── i18n/
│   │   ├── logger/
│   │   ├── middleware/         # auth, rbac, audit, ratelimit, cors, recovery
│   │   ├── errors/             # ApiError type + i18n key resolution
│   │   ├── queue/              # asynq client
│   │   └── server/             # Gin app factory
│   └── integrations/           # external services
│       ├── email/              # SendGrid wrapper
│       ├── storage/            # S3 wrapper
│       ├── payments/           # Stripe wrapper
│       └── monitoring/         # Sentry wrapper
├── migrations/                 # golang-migrate SQL files
│   ├── 000001_init.up.sql
│   └── 000001_init.down.sql
├── locales/                    # go-i18n message files
│   ├── active.en.toml
│   └── active.zh-TW.toml
├── api/
│   └── openapi.yaml            # generated by swaggo
├── pkg/                        # public packages (only if exported)
└── test/
    ├── integration/
    └── e2e/
```

### Key alignment rule
For every backend task in the task breakdown:
1. Create a package in `internal/modules/` — name is task ID with hyphens removed
   and lowercased (e.g. `BE-003 Auth Service` → `be003auth`)
2. Add a `README.md` linking back to the source task file
3. Place all module-scoped code (handler, service, repository, worker, dto, tests) inside
4. The module exports a `Register(r *gin.Engine, deps *platform.Deps)` function
   called from `cmd/api/main.go`

This gives a 1-to-1 mapping: when an AI agent picks up `BE-003 Auth Service`, it
knows exactly where to work.

---

## Step 4 — Database Schema

### Migrations (golang-migrate)

Every table from TECH_DESIGN.md section 3 becomes a numbered SQL migration:

```sql
-- migrations/000001_create_users.up.sql
CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  display_name  VARCHAR(100) NOT NULL,
  avatar_url    VARCHAR(500),
  roles         TEXT[] NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_email ON users(email);
```

```sql
-- migrations/000001_create_users.down.sql
DROP TABLE users;
```

### GORM models (alongside migrations)

```go
// internal/modules/be001users/model.go
package be001users

import (
    "time"
    "github.com/google/uuid"
    "github.com/lib/pq"
)

type User struct {
    ID           uuid.UUID      `gorm:"type:uuid;primaryKey;default:gen_random_uuid()" json:"id"`
    Email        string         `gorm:"uniqueIndex;not null" json:"email"`
    PasswordHash string         `gorm:"not null" json:"-"`
    DisplayName  string         `gorm:"not null" json:"display_name"`
    AvatarURL    *string        `json:"avatar_url,omitempty"`
    Roles        pq.StringArray `gorm:"type:text[];default:'{}'" json:"roles"`
    CreatedAt    time.Time      `json:"created_at"`
    UpdatedAt    time.Time      `json:"updated_at"`
}

func (User) TableName() string { return "users" }
```

### Seed data
`cmd/seed/main.go` populates dev DB with 5 users (one per role), 10 records per
primary entity, foreign keys correctly cross-referenced.

---

## Step 5 — i18n Setup

### Configuration

```go
// internal/platform/i18n/i18n.go
package i18n

import (
    "embed"
    "github.com/BurntSushi/toml"
    "github.com/nicksnyder/go-i18n/v2/i18n"
    "golang.org/x/text/language"
)

//go:embed all:locales
var localesFS embed.FS

var Bundle *i18n.Bundle

func Init() error {
    Bundle = i18n.NewBundle(language.English)
    Bundle.RegisterUnmarshalFunc("toml", toml.Unmarshal)

    for _, lang := range []string{"en", "zh-TW"} {
        path := fmt.Sprintf("locales/active.%s.toml", lang)
        if _, err := Bundle.LoadMessageFileFS(localesFS, path); err != nil {
            return err
        }
    }
    return nil
}

// Localizer returns a localizer for the request's accept-language
func Localizer(acceptLang string) *i18n.Localizer {
    return i18n.NewLocalizer(Bundle, acceptLang, "en")
}
```

### Per-request localiser
Gin middleware reads `Accept-Language`, attaches `*i18n.Localizer` to context:

```go
// internal/platform/middleware/i18n.go
func I18n() gin.HandlerFunc {
    return func(c *gin.Context) {
        lang := c.GetHeader("Accept-Language")
        c.Set("localizer", i18n.Localizer(lang))
        c.Next()
    }
}
```

### Localised error responses
Errors carry an i18n key:

```go
// internal/platform/errors/api_error.go
type APIError struct {
    Code    string
    Status  int
    MsgID   string  // i18n message ID
    Details map[string]any
}

// In handlers:
return errors.New(errors.ErrAuthInvalidCredentials, 401, "auth.invalidCredentials")
```

The error middleware resolves the `MsgID` against the request's localiser:

```go
loc := c.MustGet("localizer").(*i18n.Localizer)
msg, _ := loc.Localize(&i18n.LocalizeConfig{MessageID: apiErr.MsgID})
c.JSON(apiErr.Status, gin.H{"error": gin.H{"code": apiErr.Code, "message": msg}})
```

### Message file format (TOML)
```toml
# locales/active.en.toml
[auth.invalidCredentials]
description = "Returned when login credentials don't match"
other = "Invalid email or password"

[auth.userNotFound]
other = "User not found"

# locales/active.zh-TW.toml
[auth.invalidCredentials]
other = "電子郵件或密碼無效"
```

One TOML section per error key. Module-specific keys are prefixed
(`auth.*`, `ipassets.*`, etc.).

---

## Step 6 — Auth Implementation

### JWT with RS256

```go
// internal/platform/jwt/jwt.go
package jwt

import (
    "time"
    "github.com/golang-jwt/jwt/v5"
    "github.com/google/uuid"
)

type Claims struct {
    UserID uuid.UUID `json:"sub"`
    Roles  []string  `json:"roles"`
    Type   string    `json:"type,omitempty"` // "refresh" for refresh tokens
    jwt.RegisteredClaims
}

func SignAccessToken(userID uuid.UUID, roles []string) (string, error) {
    claims := Claims{
        UserID: userID,
        Roles:  roles,
        RegisteredClaims: jwt.RegisteredClaims{
            ExpiresAt: jwt.NewNumericDate(time.Now().Add(15 * time.Minute)),
        },
    }
    token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
    return token.SignedString(privateKey)
}

func Verify(tokenString string) (*Claims, error) {
    token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(t *jwt.Token) (any, error) {
        if _, ok := t.Method.(*jwt.SigningMethodRSA); !ok {
            return nil, errors.New("unexpected signing method")
        }
        return publicKey, nil
    })
    if err != nil || !token.Valid {
        return nil, err
    }
    return token.Claims.(*Claims), nil
}
```

### Auth middleware

```go
// internal/platform/middleware/auth.go
func RequireAuth() gin.HandlerFunc {
    return func(c *gin.Context) {
        token := strings.TrimPrefix(c.GetHeader("Authorization"), "Bearer ")
        if token == "" {
            c.AbortWithStatusJSON(401, errors.New("AUTH_MISSING_TOKEN", 401, "auth.missingToken"))
            return
        }
        claims, err := jwt.Verify(token)
        if err != nil {
            c.AbortWithStatusJSON(401, errors.New("AUTH_INVALID_TOKEN", 401, "auth.invalidToken"))
            return
        }
        c.Set("user_id", claims.UserID)
        c.Set("user_roles", claims.Roles)
        c.Next()
    }
}
```

### RBAC

```go
func RequireRole(allowed ...string) gin.HandlerFunc {
    return func(c *gin.Context) {
        roles := c.MustGet("user_roles").([]string)
        for _, r := range roles {
            for _, a := range allowed {
                if r == a {
                    c.Next()
                    return
                }
            }
        }
        c.AbortWithStatusJSON(403, errors.New("AUTH_FORBIDDEN", 403, "auth.forbidden"))
    }
}
```

### Refresh token rotation
- Refresh tokens stored in Redis with TTL = 30 days
- On refresh: validate, issue new pair, blocklist old refresh token in Redis
- On logout: blocklist refresh token

---

## Step 7 — Endpoint Implementation

For EVERY endpoint in TECH_DESIGN.md section 4:

1. **Find which task module owns this endpoint** (from task files)
2. **Place handler + route inside that module's package**
3. **DTO with validator tags** in module's `dto.go`:
   ```go
   type CreateIPAssetRequest struct {
       Title       string  `json:"title" binding:"required,min=1,max=200"`
       Description string  `json:"description" binding:"max=2000"`
       Category    string  `json:"category" binding:"required,oneof=art music video"`
   }
   ```
4. **Handler** in module's `handler.go`:
   ```go
   func (h *Handler) Create(c *gin.Context) {
       var req CreateIPAssetRequest
       if err := c.ShouldBindJSON(&req); err != nil {
           c.AbortWithStatusJSON(422, errors.Validation(err))
           return
       }
       userID := c.MustGet("user_id").(uuid.UUID)
       asset, err := h.svc.Create(c.Request.Context(), userID, req)
       if err != nil { c.AbortWithStatusJSON(err.Status, err); return }
       c.JSON(201, asset)
   }
   ```
5. **Service function** in module's `service.go`:
   - Business logic
   - Calls repository for DB operations
   - Authorisation checks (ownership, etc.)
   - Enqueues background jobs via asynq client
6. **Repository** in module's `repository.go`:
   - GORM/sqlx queries only
   - No business logic
7. **Tests** in module's `handler_test.go`:
   - Happy path
   - Auth failure
   - Authorisation failure
   - Validation failure
   - Not found

### Module registration
Each module exposes `Register`:

```go
// internal/modules/be003auth/module.go
func Register(r *gin.RouterGroup, deps *platform.Deps) {
    h := NewHandler(NewService(NewRepository(deps.DB)))
    g := r.Group("/auth")
    g.POST("/register", h.Register)
    g.POST("/login", h.Login)
    g.POST("/refresh", h.Refresh)
    auth := g.Use(middleware.RequireAuth())
    auth.POST("/logout", h.Logout)
}
```

`cmd/api/main.go` calls each module's Register in dependency order from the task graph.

### Endpoint coverage checklist
Every endpoint in TECH_DESIGN must:
- [ ] Belong to a task module (per task breakdown)
- [ ] Have a handler in module's `handler.go`
- [ ] Have a request DTO with validator tags in `dto.go`
- [ ] Have a service function (no business logic in handlers)
- [ ] Have an integration test in `handler_test.go`
- [ ] Be registered in module's `module.go`
- [ ] Have swaggo annotations for OpenAPI generation

NEVER skip an endpoint. NEVER stub one with `TODO`.

---

## Step 8 — Background Workers (asynq)

For each job listed in TECH_DESIGN.md section 7:

1. Identify which task module owns the job
2. Place worker in that module's `worker.go`
3. Producer (service that enqueues) is in the same module's `service.go`
4. Job type constants live in module's `dto.go`

```go
// internal/modules/be008email/worker.go
package be008email

const TaskTypeSendEmail = "email:send"

type SendEmailPayload struct {
    To       string `json:"to"`
    Template string `json:"template"`
    Data     map[string]any `json:"data"`
}

func HandleSendEmail(ctx context.Context, t *asynq.Task) error {
    var p SendEmailPayload
    if err := json.Unmarshal(t.Payload(), &p); err != nil {
        return fmt.Errorf("unmarshal: %w", err)
    }
    return emailClient.Send(p)
}

// In cmd/worker/main.go:
mux := asynq.NewServeMux()
mux.HandleFunc(be008email.TaskTypeSendEmail, be008email.HandleSendEmail)
```

Workers run as separate `cmd/worker` process in production. For local dev, run
both `cmd/api` and `cmd/worker` via `make dev`.

---

## Step 9 — External Integrations

For each external service in TECH_DESIGN section 6:

1. Wrapper in `internal/integrations/{service}/`
2. Modules use the wrapper, never the raw SDK
3. Mock implementation in `test/mocks/{service}.go` for testing
4. Env vars in `.env.example`
5. Webhook endpoint (if applicable) in the owning task module's `handler.go` with
   signature verification

Example wrapper:

```go
// internal/integrations/email/sendgrid.go
package email

type Client interface {
    Send(ctx context.Context, payload SendPayload) error
}

type sendgridClient struct {
    apiKey string
    from   string
}

func NewSendGridClient(apiKey, from string) Client {
    return &sendgridClient{apiKey, from}
}

func (c *sendgridClient) Send(ctx context.Context, p SendPayload) error {
    // implementation
}
```

---

## Step 10 — Quality Standards

### Required
- Go 1.22+
- All requests validated via go-playground/validator struct tags
- All errors carry i18n message IDs and resolve at the error middleware
- All sensitive operations write to `audit_log` table
- Rate limiting via custom middleware backed by Redis (60 req/min per IP, 1000/hr per user)
- CORS configured for known frontend origins only
- Security headers via custom middleware (or unrolled.com/secure)
- zerolog structured logging (JSON in prod)
- Sentry error capture
- Health check endpoint (`GET /health`)
- OpenAPI spec auto-generated via swaggo, served at `/swagger/index.html`

### Required toolchain
- `golangci-lint run` clean
- `gofmt -s` formats consistently
- `go vet ./...` passes
- `go test ./...` passes (unit + integration)
- Test coverage ≥ 80% for service layer, ≥ 60% overall
- `make ci` runs everything

### Makefile targets
```makefile
.PHONY: dev test lint migrate seed build docker

dev:           ## Run API + worker locally with hot reload
	docker-compose up -d postgres redis
	air -c .air.toml

test:          ## Run unit + integration tests
	go test ./... -race -cover

lint:          ## Run golangci-lint
	golangci-lint run --timeout=5m

migrate:       ## Run database migrations
	go run cmd/migrate/main.go up

seed:          ## Seed dev database
	go run cmd/seed/main.go

build:         ## Build production binary
	CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/api cmd/api/main.go
	CGO_ENABLED=0 go build -ldflags="-s -w" -o bin/worker cmd/worker/main.go

docker:        ## Build Docker images
	docker build -f Dockerfile -t {project}-backend:latest .
```

### .env.example
```
GO_ENV=development
PORT=3000
LOG_LEVEL=debug
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/myapp?sslmode=disable
REDIS_URL=redis://localhost:6379
JWT_PRIVATE_KEY_PATH=./keys/private.pem
JWT_PUBLIC_KEY_PATH=./keys/public.pem
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

Every module's README.md links back to the source task file:

```markdown
# Module: be003auth

This module implements **BE-003: Auth Service** described in:
**[../../../tasks/03-backend/BE-003-auth.md](../../../tasks/03-backend/BE-003-auth.md)**

## Endpoints owned
- POST /api/v1/auth/register
- POST /api/v1/auth/login
- POST /api/v1/auth/refresh
- POST /api/v1/auth/logout
- POST /api/v1/auth/forgot-password
- POST /api/v1/auth/reset-password

## Workers owned
- email:send-verification (handled in coordination with be008email)

## Status
- [x] Group 01 — Scaffold
- [x] Group 02 — Endpoints
- [ ] Group 03 — Tests
```

---

## Step 12 — Generation Strategy for Large Backends

If the tech design has > 30 endpoints, generate in batches aligned with task IDs:

**Batch 1 (foundation)**: project layout, go.mod, platform package (config, db,
  redis, jwt, i18n, logger, middleware, errors, queue), Makefile, Dockerfile
**Batch 2 (auth + user modules)**: tasks with no dependencies or auth-only
**Batch 3 (core domain modules)**: tasks depending on auth
**Batch 4 (integrations + admin modules)**: tasks depending on multiple core modules
**Batch 5 (analytics + reporting)**: tail tasks per dependency graph

After each batch:
- Run `go build ./...` to verify compilation
- Run `go test ./...` to verify tests pass
- Confirm with the user before proceeding

This avoids hitting context length limits and gives the user checkpoints aligned
with the task plan.

---

## Step 13 — Deliver

```bash
cd /home/claude
tar -czf {project-name}-backend-go.tar.gz {project-name}-backend-go/
cp {project-name}-backend-go.tar.gz /mnt/user-data/outputs/
```

README.md must include:
- Local setup: `make migrate && make seed && make dev`
- Env vars to configure
- Architecture overview — call out the `internal/modules/` ↔ task-breakdown alignment
- Swagger UI URL: http://localhost:3000/swagger/index.html
- How i18n works (TOML message files)
- How to add a new module (recipe — create new task in task plan first)
- How to add a new asynq worker (recipe)
- Link to the task breakdown tar
- Deployment notes (multi-stage Docker, distroless base image)

Use `present_files` to deliver.

---

## Workflow Position

```
prototype → docs → mockup → task-breakdown → project-frontend  +  [YOU ARE HERE]
                                                                   project-backend-go
```

Final summary:
> "Production Go backend generated. N modules aligned with N backend task IDs.
> N tables, N endpoints, N workers, N i18n message keys.
> Setup: `docker-compose up -d && make migrate && make seed && make dev`.
> Swagger UI at http://localhost:3000/swagger/index.html.
> Each `internal/modules/{task_id_slug}/` package links back to its source task file.
> Pair with **project-frontend** — they share both the API contract (TECH_DESIGN.md)
> and the task plan organisation."
