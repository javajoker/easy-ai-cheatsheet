# Project Quick-Start Workflow Guide

A practical, conversation-by-conversation guide to using all eight skills together.

The full sequence:

```
[1] prototype  →  [2] docs  →  [3] mockup (optional)  →  [4] task-breakdown
                   (asks backend                                 │
                    language)                                    ▼
                                                       [5a] frontend         ║
                                                       [5b] backend-{node,   ║  parallel
                                                            go, or python}   ║  (both consume
                                                                                docs + tasks)
```

The backend language is chosen during Phase 2 (`project-docs`) and baked into
TECH_DESIGN.md. Phase 5b uses whichever backend skill matches that choice.

---

## Phase 1 — Ideation → Prototype

### Goal
Turn a fuzzy idea into a clickable prototype that exposes every user role and primary
flow. Validates that you can articulate the product clearly.

### Prompts that trigger `project-prototype`

```
"I want to build [your concept in plain language]."
```
```
"Design a web app for [domain] where users can [actions]."
```
```
"Show me a prototype of [your idea]."
```

### What you get
- Clickable React artifact rendered in the chat
- Demo controls panel for switching between user roles
- All major views: landing, auth, role-specific dashboards, lists, details, forms,
  admin views
- Realistic mock data
- View inventory checklist showing what was generated

### Iteration loop
After the first prototype:
- Click through every flow
- List what's missing or wrong
- Ask Claude to add/modify specific views: *"Add a dispute submission flow for buyers"*
- Iterate until the prototype matches your mental model

### Output to keep
- The React artifact code (copy it out, save as `prototype.tsx`)
- Your refined idea description (often gets sharper through prototyping)

---

## Phase 2 — Prototype → Specifications

### Goal
Convert the prototype + idea into formal docs that engineering can build from.

### Prompts that trigger `project-docs`

```
"Now create the formal docs from this prototype."
```
```
"Generate a PRD, UI/UX spec, and tech design from the prototype I just built."
```

### Inputs to provide
- The prototype (already in conversation, or paste the code)
- The original idea description (in case it got refined during Phase 1)
- Any constraints: tech stack preferences, scale targets, integrations

### Backend Language Decision
`project-docs` will ask which backend language you want before generating TECH_DESIGN.md:

> "Which backend language would you like?
> - **Node.js / TypeScript** (default, fastest dev velocity)
> - **Go** (best latency at minimal compute cost)
> - **Python** (FastAPI; best for ML/data integration)"

The choice is baked into TECH_DESIGN.md and determines which backend skill you'll
use in Phase 5b.

### What you get
Three markdown files in `/mnt/user-data/outputs/`:
- **PRD.md** — personas, user stories, features (P0/P1/P2), business rules, success metrics
- **UIUX_SPEC.md** — every view spec, components, flows, missing views identified
- **TECH_DESIGN.md** — DB schema, every API endpoint, auth, **stack-specific i18n
  approach**, security, deployment — language-specific library choices embedded

### Quality check
The skill enforces cross-doc consistency, but spot-check before moving on:
- Every persona in PRD has matching views in UIUX_SPEC
- Every feature in PRD has API endpoints in TECH_DESIGN
- Every entity in TECH_DESIGN appears as a view in UIUX_SPEC

### Iteration loop
Treat docs as code: ask Claude to update specific sections rather than regenerating
from scratch.

> "In TECH_DESIGN.md, add a webhook endpoint for Stripe events."
> "In UIUX_SPEC.md, add a wizard flow for first-time creator onboarding."

---

## Phase 3 — Quick Demo (optional but recommended)

### Goal
Build a runnable demo with mock data to validate the docs end-to-end before any
production code work begins. Catches spec gaps that would otherwise show up only
after weeks of code work.

### When to skip
- You have very high confidence the docs are complete (small project, well-known domain)
- You're rebuilding an existing system and don't need stakeholder validation
- You're under time pressure and willing to fix gaps in production code instead

### Prompts that trigger `project-mockup-app`
```
"Build a quick demo with mock data covering all the flows."
```
```
"Generate a runnable mock app from the docs to validate the workflow."
```
```
"Build a frontend with mock data first, no backend yet."
```

### Inputs to provide
- PRD.md, UIUX_SPEC.md, TECH_DESIGN.md

### What you get
Tar archive with a runnable Vite + React project:
- Every view from UIUX_SPEC
- Mock data following the eventual DB schema
- Role switcher (no real auth)
- All interactions working in-memory
- Simple, neutral styling

```bash
tar -xzf mockup-app.tar.gz
cd mockup-app
pnpm install && pnpm dev
```

### What to do with the mockup
1. Click through every flow as every role
2. Demo to stakeholders
3. List any spec gaps or missing flows
4. **Fix the docs (Phase 2), not the mockup.** The mockup is disposable.
5. Optionally re-run `project-mockup-app` after doc updates to confirm

### Output to keep (or discard)
- The mockup tar — useful as a reference but **not a code base you keep**
- Notes on spec changes needed — feed these back into Phase 2

---

## Phase 4 — Task Breakdown

### Goal
Turn the (now validated) specs into a structured task plan that AI agents can execute
one task at a time. This becomes the source of truth for the production code phase.

### Prompts that trigger `task-breakdown`

```
"Break this into AI-executable tasks."
```
```
"Generate a task plan from these docs."
```
```
"Create a project task breakdown I can hand to AI agents."
```

### Inputs to provide
- PRD.md, UIUX_SPEC.md, TECH_DESIGN.md (attach all three)
- Optional: team size, timeline preferences, existing infrastructure
- Optional: feedback from mockup phase (if you ran it)

### What you get
A tar archive `/mnt/user-data/outputs/{project}-tasks.tar.gz` containing:
- `AGENT.md` — entry-point file for any AI agent working on the project
- `DEPENDENCY_GRAPH.md` — full topological task ordering, critical path, parallel
  opportunities, interface lock dates
- `CONVENTIONS.md` — code style, naming, repo layout
- `tasks/` — one folder per component, one markdown file per task with:
  - YAML frontmatter (id, status, depends_on, blocks, week, hours, priority)
  - Context, prerequisites
  - Grouped task checklists
  - Self-contained AI execution prompt (copy-paste ready)
  - Expected outputs and verification checklist

### Why this comes before production code
- **Code organisation matches task organisation.** When `project-frontend` and
  `project-backend` see the task breakdown, they generate folders and files aligned
  with task IDs, so future work on a single task is a self-contained edit.
- **Component boundaries are explicit.** No ambiguity about where a feature lives.
- **Dependency order is documented.** When you start coding, the order is already known.

### Output to keep
- The full tasks tar — this is your project plan; reference it throughout development

---

## Phase 5 — Production Code

Run frontend and backend in parallel (separate conversations if you want).
**Both consume the project docs + the task breakdown.**

### Phase 5a — Frontend (`project-frontend`)

#### Prompts
```
"Build the production frontend, organised around the task breakdown."
```
```
"Generate the production React app using the docs and task plan."
```

#### Inputs to provide
- PRD.md, UIUX_SPEC.md, TECH_DESIGN.md
- The task-breakdown tar (or its extracted contents)
- Optional: existing mockup tar (mock data and components can be reused)

#### What you get
- Vite + React 18 + TypeScript strict mode
- Routing, state management, forms, validation
- shadcn/ui components
- i18n (en + zh-TW) with all user-facing text using `t('key')`
- API client wired to backend endpoints
- Mock fallback mode (`VITE_USE_MOCK=true`) for dev before backend is ready
- **Folder structure aligned with task-breakdown components**
  (e.g. one feature module per task component → easy to map task IDs to code)

```bash
tar -xzf {project}-frontend.tar.gz
cd {project}-frontend
pnpm install
pnpm dev    # uses real backend if available, mock if VITE_USE_MOCK=true
```

### Phase 5b — Backend (`project-backend-node` / `-go` / `-python`)

Pick the skill matching the language chosen in TECH_DESIGN.md:

| Language | Skill | Output structure |
|----------|-------|------------------|
| Node.js | `project-backend-node` | `src/modules/{task-id-slug}/` (kebab) |
| Go | `project-backend-go` | `internal/modules/{task_id_slug}/` (lowercase) |
| Python | `project-backend-python` | `app/modules/{task_id_slug}/` (snake_case) |

#### Prompts
```
"Build the production Node.js backend, organised around the task breakdown."
```
```
"Generate the Go backend using the docs and task plan."
```
```
"Build the Python FastAPI backend from the docs and task breakdown."
```
```
"Build the backend"     # → routes to the language in TECH_DESIGN.md
```

#### Inputs to provide
- PRD.md, TECH_DESIGN.md (UIUX_SPEC optional but useful)
- The task-breakdown tar (or its extracted contents)

#### What you get (all three variants share this structure)
- Production-grade backend in your chosen language
- PostgreSQL schema migrations (Prisma / golang-migrate / Alembic)
- Redis-backed job queue (BullMQ / asynq / Celery)
- Every endpoint from TECH_DESIGN with validation, RBAC, i18n errors, tests
- JWT auth (RS256) with refresh token rotation
- Background workers (email, file processing, notifications)
- External integrations (Stripe, SendGrid, S3, etc.)
- Auto-generated OpenAPI / Swagger
- Docker + docker-compose for local dev
- **Module organisation aligned with task-breakdown backend components**
  (e.g. each backend task ID like `BE-003 Auth Service` maps to its own module folder)

Setup commands:

```bash
# Node.js variant
tar -xzf {project}-backend-node.tar.gz && cd {project}-backend-node
docker-compose up -d && pnpm install && pnpm prisma migrate dev && pnpm dev

# Go variant
tar -xzf {project}-backend-go.tar.gz && cd {project}-backend-go
docker-compose up -d && make migrate && make seed && make dev

# Python variant
tar -xzf {project}-backend-py.tar.gz && cd {project}-backend-py
docker-compose up -d && poetry install && make migrate && make seed && make dev
```

### Phase 5c — Connect frontend to backend
Set `VITE_API_BASE_URL=http://localhost:3000/api/v1` in the frontend's `.env`.
Set `CORS_ORIGINS=http://localhost:5173` in the backend's `.env`.
Toggle off `VITE_USE_MOCK` in the frontend.

Both sides should now wire up cleanly because they share the API contract from
TECH_DESIGN.md.

---

## Resuming, Skipping, Branching

### Bringing in your own existing assets
> "Here's my existing PRD, tech design, and task plan (attached). Generate the
> backend from these."

→ `project-backend` works directly from the attached files. Skips Phases 1–4.

### Iterating on a single phase without restarting
> "In the PRD, add a 'creator earnings export' feature. Update only that section,
> then update the task breakdown to add the corresponding task."

→ Claude updates the relevant docs without regenerating everything.

### Branching for experimentation
> "Build a second version of the mock app with a wizard-style onboarding instead of
> the form-based one we have."

→ Generate variant in a side directory; A/B compare; keep the winner.

### Generating only one piece
- Need just a frontend? Skip backend, run only `project-frontend`
- Need just docs? Run only `project-docs` from your existing description
- Need just the task plan? Run only `task-breakdown` from your existing docs
- Need to skip the mockup? Go straight from docs to task-breakdown

---

## Tips for Best Results

1. **Be specific in Phase 1.** The more detail in your initial prompt, the less back-
   and-forth in Phase 2.

2. **Iterate on the prototype before doing docs.** Visual feedback is faster than
   reading a PRD.

3. **Don't skip the mockup app for non-trivial projects.** It catches spec gaps that
   would otherwise show up only after weeks of code work.

4. **Run task-breakdown after the mockup, not before.** Mockup feedback often refines
   the docs; you want the task plan to reflect the latest version.

5. **Choose backend language before generating docs.** Once TECH_DESIGN.md is generated
   with a specific stack, switching language means regenerating the doc. The mockup app
   and frontend are unaffected by backend language — only the backend skill changes.

5. **Run frontend and backend generation in parallel conversations.** They share the
   tech design + task plan as the contract; no need to serialize.

6. **Use the task-breakdown output for ongoing work.** Every time a task is done, the
   AGENT.md tells the next AI session exactly where to pick up.

7. **Keep a `project-state/` folder.** Save the artifacts from each phase
   (prototype.tsx, PRD.md, UIUX_SPEC.md, TECH_DESIGN.md, mockup tar, tasks tar,
   frontend tar, backend tar) so you can resume mid-workflow at any time.

---

## What's Different vs Ad-Hoc Prompting

| Ad-hoc prompting | This skillset |
|------------------|--------------|
| Re-explain context every conversation | Skills load context from prior outputs |
| Inconsistent doc structure | Templates enforce same structure every time |
| Gaps between phases (PRD says X, code does Y) | Cross-doc consistency checks built in |
| Hard to resume after a break | Each skill picks up from documented inputs |
| Hand-rolled prompts of varying quality | Each skill has tested, structured prompts |
| Manual coordination of frontend + backend | Both generated from the same docs + tasks |
| No task tracking after planning | task-breakdown produces AI-executable tasks |
| Spec gaps discovered in production | Mockup phase catches them before code work |
