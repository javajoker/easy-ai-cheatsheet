# CONVENTIONS.md Template Reference

## Full Template

Paste this into the generated CONVENTIONS.md and fill in the blanks.
Delete sections that don't apply (e.g. no Solidity section for a pure SaaS app).

---

```markdown
# {Project Name} — Conventions and Repo Layout

## Repository Structure

\`\`\`
{project-root}/
├── apps/
│   ├── {web-app}/              # Next.js / Vite web frontend
│   ├── {mobile-app}/           # React Native / Expo mobile app
│   └── {admin}/                # Admin dashboard (if separate)
├── services/
│   ├── {auth}/                 # Auth service
│   ├── {core-api}/             # Primary API service
│   └── {other-services}/
├── packages/
│   ├── types/                  # Shared TypeScript types
│   ├── config/                 # Shared ESLint, TSConfig, Prettier
│   ├── {ui-primitives}/        # Shared React/RN components (if applicable)
│   └── {abis}/                 # Contract ABIs (if blockchain)
├── {contracts}/                # Smart contracts (if blockchain)
├── {infrastructure}/           # Terraform, k8s, Docker
├── prisma/ OR {schema-dir}/    # Database schema + migrations
└── {docs}/                     # Documentation site
\`\`\`

---

## Naming Conventions

### Files and Directories
- **Directories**: `kebab-case`
- **TypeScript modules**: `camelCase.ts`
- **React components**: `PascalCase.tsx`
- **Test files**: `ComponentName.test.ts` (alongside source) or `__tests__/`
- **Database migrations**: `0001_description.sql` (zero-padded sequential)

### TypeScript / JavaScript
- **Types + Interfaces**: `PascalCase` (e.g. `UserProfile`, `TaskStatus`)
- **Enums**: `PascalCase` enum, `PascalCase` members (e.g. `TaskStatus.InProgress`)
- **Functions**: `camelCase` (e.g. `getUserById`)
- **Constants**: `SCREAMING_SNAKE_CASE` (e.g. `MAX_RETRY_COUNT`)
- **React components**: `PascalCase`
- **React hooks**: `use` + `PascalCase` (e.g. `useDeviceStatus`)
- **Zod schemas**: `camelCaseSchema` (e.g. `createTaskSchema`)
- **API route handlers**: `kebab-case` files (`auth-wallet.ts`), function `handleWalletAuth`

### Database (PostgreSQL / Prisma)
- **Tables**: `snake_case` plural (e.g. `user_profiles`, `task_records`)
- **Columns**: `snake_case` (e.g. `created_at`, `wallet_address`)
- **Indexes**: `idx_{table}_{column(s)}` (e.g. `idx_tasks_status_created_at`)
- **Foreign keys**: `{referenced_table_singular}_id` (e.g. `user_id`, `machine_id`)

### API Routes (REST)
- Versioned: `/api/v1/`
- Resource nouns, plural: `/api/v1/users`, `/api/v1/tasks`
- Sub-resources: `/api/v1/tasks/:id/bids`
- Actions as verbs (only when truly not a resource): `/api/v1/tasks/:id/accept`

{--- Solidity section — delete if not a blockchain project ---}
### Solidity
- **Contracts**: `PascalCase`
- **Functions**: `camelCase`
- **Events**: `PascalCase`
- **Custom errors**: `PascalCase` (e.g. `error InsufficientStake()`)
- **Constants**: `SCREAMING_SNAKE_CASE`
- **Roles**: `SCREAMING_SNAKE_CASE` + `_ROLE` suffix (e.g. `MINTER_ROLE`)
{---}

---

## Code Quality Standards

### TypeScript / JavaScript
- `"strict": true` in all tsconfig.json — no exceptions
- No `any` — use `unknown` and narrow with type guards
- All function params and return types explicitly typed
- Zod for all external input validation (API request bodies, env vars, config files)
- No `console.log` in production code — use Pino / Winston structured logger
- `eslint` + `prettier` enforced in CI (fail the build on violations)

{--- Solidity section ---}
### Solidity
- `^0.8.20` — implicit overflow checking
- OpenZeppelin Contracts v5 as base library
- Custom errors throughout — no `require("string message")`
- `nonReentrant` on every function that transfers tokens or calls external contracts
- `/// @notice`, `/// @param`, `/// @return` NatSpec on all `public`/`external` functions
- Explicit visibility on every state variable
{---}

### Testing
- **Unit tests**: {Vitest / Jest} — run in-process, mock all I/O
- **Integration tests**: {Testcontainers / real test DB} — real DB + Redis
- **E2E tests**: {Playwright / Detox / Hardhat scripts}
- **Coverage targets**: {contracts: 100% branch; backend: 80%+ line; frontend: unit for logic only}

### Git Workflow
- **Branch naming**: `feat/{ticket-id}-short-description`, `fix/{ticket-id}-description`
- **Commits**: Conventional Commits (`feat:`, `fix:`, `chore:`, `test:`, `docs:`, `refactor:`)
- **PRs require**: CI green + no lint errors + 1 approving reviewer
- **Merge strategy**: Squash merge to main

---

## Environment Variables

All services share this approach:
- `.env.example` committed; actual `.env` gitignored
- Validate all required vars at startup via Zod (throw on missing required vars)
- Secrets injected via {AWS SSM / Doppler / GitHub Actions secrets} in CI/CD

\`\`\`env
# ── Shared across all services ──────────────────
DATABASE_URL=postgresql://user:pass@localhost:5432/dbname
REDIS_URL=redis://localhost:6379
NODE_ENV=development|staging|production
LOG_LEVEL=info
SENTRY_DSN=https://...

# ── Auth service ─────────────────────────────────
JWT_PRIVATE_KEY=-----BEGIN RSA PRIVATE KEY-----...
JWT_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----...

# ── All services (verify JWT) ────────────────────
JWT_PUBLIC_KEY=-----BEGIN PUBLIC KEY-----...

# ── Blockchain (if applicable) ───────────────────
ALCHEMY_API_KEY=...
CHAIN_ID=137         # Polygon mainnet; 80001 = Mumbai testnet
CONTRACT_{NAME}_ADDRESS=0x...

# ── External services ────────────────────────────
SENDGRID_API_KEY=SG....
FIREBASE_ADMIN_SDK='{...}'    # JSON string
STRIPE_SECRET_KEY=sk_...
AWS_ACCESS_KEY_ID=...
AWS_SECRET_ACCESS_KEY=...
S3_BUCKET_NAME=...
\`\`\`

---

## Port Allocation

| Service | Local Port |
|---------|-----------|
| {Service 1} | {3001} |
| {Service 2} | {3002} |
| PostgreSQL | 5432 |
| Redis | 6379 |
| {Local blockchain node} | 8545 |
```

---

## Conventions Filling Guide

### Adapt naming rules to the actual stack
- If using Python: snake_case for everything (functions, variables, files)
- If using Go: exported = PascalCase, unexported = camelCase
- If using Rust: snake_case for functions/variables, PascalCase for types
- If the project has a linter config: defer to the linter, note it in Code Quality

### Repository structure rules
- Show the ACTUAL directory structure, not a generic one
- Include only directories that will be created in this project
- Mark generated directories with a `# auto-generated` comment

### Port allocation
- Only needed for microservices projects
- Reserve ports to avoid conflicts during local development
- Include infrastructure services (Postgres, Redis, etc.) in the table
