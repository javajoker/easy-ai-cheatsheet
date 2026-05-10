# Project Quick-Start Skillset

A six-skill toolkit that takes you from a fuzzy idea to a production-ready codebase
following a repeatable, AI-driven workflow.

This skillset replaces ad-hoc prompting with structured, composable skills that:
1. Each have a clear job and a clear handoff to the next
2. Can be triggered automatically by Claude based on what you've already done
3. Produce consistent, well-structured outputs that feed directly into the next step
4. Let you skip, repeat, or branch any step without breaking the chain

---

## The Six Skills

| # | Skill | Phase | Input | Output |
|---|-------|-------|-------|--------|
| 1 | `project-prototype` | Ideation | Idea description | Clickable React UI prototype with all roles + flows |
| 2 | `project-docs` | Specification | Idea + prototype | PRD.md, UIUX_SPEC.md, TECH_DESIGN.md |
| 3 | `project-mockup-app` | Validation (optional) | Project docs | Quick demo frontend with mock data, all views, no backend |
| 4 | `task-breakdown` | Planning | Project docs (+ optional mockup) | Full task plan: AGENT.md, DEPENDENCY_GRAPH.md, per-component task files |
| 5 | `project-frontend` | Production | Project docs **+ task breakdown** | Production React app with i18n + backend wiring |
| 6 | `project-backend` | Production | Project docs **+ task breakdown** | Production Node.js backend with i18n + every endpoint |

---

## The Workflow

```
                       ┌─────────────────────────┐
                       │   project-mockup-app    │ ◄── optional
                       │   (quick demo, no BE)   │     validation
                       └────────────┬────────────┘
                                    │
   IDEA ─► [1] prototype ─► [2] docs ─► [3] task-breakdown
                                    │
                                    ▼
                       ┌─────────────────────────┐
                       │   project-frontend      │  ◄─┐
                       │   (production)          │    │
                       └─────────────────────────┘    │ run in
                                                      │ parallel
                       ┌─────────────────────────┐    │ — both consume
                       │   project-backend       │  ◄─┘   docs + tasks
                       │   (production)          │
                       └─────────────────────────┘
```

### Phase 1 — Ideation (Skill 1)
You: *"I want to build a marketplace where artists license their IP for secondary creations."*

Claude triggers `project-prototype` and produces a clickable React mockup with:
- Creator dashboard, IP registration, license management
- Buyer browse + checkout
- Admin moderation
- Verification page

You click through, identify gaps, ask for changes.

### Phase 2 — Specification (Skill 2)
You: *"Now create the formal docs."*

Claude triggers `project-docs` using the prototype + idea. Produces:
- **PRD.md** — personas, user stories, features (P0/P1/P2), business rules
- **UIUX_SPEC.md** — every view spec, components, flows, missing views called out
- **TECH_DESIGN.md** — full database schema, every API endpoint, auth, i18n strategy

### Phase 3 — Validation (Skill 3, optional)
You: *"Build a quick demo first to validate the workflow."*

Claude triggers `project-mockup-app`. Produces a runnable React project:
- Every view from the UI/UX spec
- Mock data following the eventual DB schema
- Role switcher (no real auth)
- All interactions working in-memory
- Deliberately simple styling

Use this for stakeholder demos and to validate the docs before serious code work.
**If you find spec gaps, fix the docs (Phase 2) before moving on — never patch the
mockup.**

### Phase 4 — Planning (Skill 4)
You: *"Break this into AI-executable tasks."*

Claude triggers `task-breakdown` from the project docs. Produces a tar archive:
- `AGENT.md` — AI orchestration framework with prompt templates per stack
- `DEPENDENCY_GRAPH.md` — full topological task ordering, critical path, parallel
  opportunities, interface lock dates
- `CONVENTIONS.md` — code style, naming, repo layout
- `tasks/` — one folder per component, one markdown file per task with:
  - YAML frontmatter (id, status, depends_on, blocks, week, hours, priority)
  - Context, prerequisites
  - Grouped task checklists
  - **Self-contained AI execution prompt**
  - Expected outputs and verification checklist

You can now hand any single task file to a fresh AI session and it executes
independently.

### Phase 5 — Production Code (Skills 5 + 6, parallel)
You: *"Now build the real frontend and backend."*

Both skills consume **the project docs + the task breakdown** and run in parallel:

**`project-frontend`** generates:
- Vite + React + TypeScript with strict mode
- TanStack Query + Zustand + react-hook-form + Zod
- shadcn/ui components
- i18n with English + Traditional Chinese
- Every view from UI/UX spec
- API client wired to tech design endpoints
- Mock fallback mode (`VITE_USE_MOCK=true`)
- File organisation aligned with task-breakdown components

**`project-backend`** generates:
- Node.js + Fastify + TypeScript
- Prisma + PostgreSQL with full schema and migrations
- Redis + BullMQ for queues
- Every endpoint from tech design with Zod validation
- JWT auth (RS256) + RBAC
- i18n error messages
- Background workers
- Auto-generated Swagger UI at /docs
- Service organisation aligned with task-breakdown components

Both deliver as tar archives with full README and `pnpm install && pnpm dev` setup.

---

## How to Use

### Installation
1. Each skill folder under `skills/` is a standalone skill
2. Install all six in your Claude environment (Claude Code, Claude.ai with skill
   support, or Cowork)
3. Each skill becomes available based on its description matching your prompt

### Triggering — let Claude pick the right skill
Simply describe what you want and Claude will route to the correct skill:

| What you say | Skill triggered |
|--------------|----------------|
| "I have an idea for a platform that..." | project-prototype |
| "Show me a prototype of..." | project-prototype |
| "Create a PRD from this prototype" | project-docs |
| "Now formalise this into specs" | project-docs |
| "Build me a quick demo with mock data" | project-mockup-app |
| "Validate the docs with a runnable mock" | project-mockup-app |
| "Break this into AI-executable tasks" | task-breakdown |
| "Build the production frontend" | project-frontend |
| "Build the backend API" | project-backend |

### Triggering — explicit invocation
You can also invoke a skill explicitly by name:
> "Use the project-docs skill to generate the PRD, UI/UX, and tech design from the
> prototype I just made and the original concept I described above."

### Resuming mid-workflow
The skills are designed to pick up wherever you have. Bring in your existing assets:

> "Here's our existing PRD, tech design, and task breakdown [attaches files].
> Generate the backend now."

→ `project-backend` uses what you provide and skips the earlier phases.

### Skipping or repeating phases
- **Skip prototype**: provide an idea + your own wireframes; jump to project-docs
- **Skip mockup**: go from project-docs directly to task-breakdown
- **Skip task-breakdown**: pass docs straight to project-frontend / project-backend
  (the skills can still infer ordering from the docs alone)
- **Repeat docs**: re-run project-docs after modifying the prototype to keep specs in sync
- **Repeat tasks**: re-run task-breakdown after major spec changes

### Delivering outputs
All skills deliver via `present_files` to `/mnt/user-data/outputs/`:
- `project-prototype` → React artifact (rendered inline) or tar
- `project-docs` → PRD.md + UIUX_SPEC.md + TECH_DESIGN.md
- `project-mockup-app` → `mockup-app.tar.gz`
- `task-breakdown` → `{project}-tasks.tar.gz`
- `project-frontend` → `{project}-frontend.tar.gz`
- `project-backend` → `{project}-backend.tar.gz`

---

## End-to-End Example

### Starting prompt
> "I want to build an open-IP-licensing marketplace where creators can register their
> IP, set licensing terms with revenue shares, secondary creators apply for licenses
> and produce derivative works that get sold on the platform with automatic provenance
> tracking. Verification happens via a chain showing original creator → secondary
> creator → final product. Anyone violating terms loses their authentic-product status."

### Phase 1 — Prototype
Claude triggers `project-prototype`:
- Identifies 3 personas (Creator, Secondary Creator, Buyer) + Admin
- Generates ~18 views: dashboards, IP registration, license application, browse,
  product detail, verify-by-code, admin moderation
- Delivers as a single React artifact with role switcher

You click through, ask Claude to add a "Dispute" flow that was missed.

### Phase 2 — Docs
> "Now create the docs."

Claude triggers `project-docs`:
- PRD.md: 4 personas, 32 user stories, 45 features (24 P0, 14 P1, 7 P2), revenue-share
  business rules, dispute resolution policy
- UIUX_SPEC.md: 22 views (18 from prototype + 4 missing: forgot-password, order-detail,
  email-verification, account-deletion), full component library, 8 user flows
- TECH_DESIGN.md: 14 database tables, 67 API endpoints, JWT auth, role mapping,
  Stripe integration for payments, S3 for file storage, BullMQ for revenue cascade

### Phase 3 — Quick Demo (optional)
> "Build a quick demo first."

Claude triggers `project-mockup-app`:
- Runnable Vite + React project, 22 views, all 14 entities mocked
- All interactions working in-memory: search, filter, create, edit, license
  application, approval, purchase, verification

You demo it to stakeholders, get sign-off. Spot 2 missing edge cases. Update the
PRD/UIUX_SPEC and re-run mockup.

### Phase 4 — Task Breakdown
> "Break it down into tasks."

Claude triggers `task-breakdown`:
- 8 components: contracts (smart contracts for provenance), backend, portal-web,
  creator-app, buyer-app, admin-dashboard, verifier-extension, docs
- 12-week timeline with critical path
- ~150 tasks across all task files
- AGENT.md with 7 operating rules and 5 prompt templates per stack

### Phase 5 — Production Code
> "Now the real frontend and backend, organised around the task breakdown."

`project-frontend` + `project-backend` run in parallel, each consuming the docs
**plus the task plan**. The output structure mirrors the task-breakdown components,
so when you sit down to work on `BE-003 Auth Service`, the corresponding folder
already exists in the generated backend.

Total elapsed: a handful of conversations vs. weeks of solo planning.

---

## Why This Skillset Works

1. **Each skill has one job** — they're focused, small, and won't drift
2. **Outputs feed directly into next inputs** — no manual translation between phases
3. **Validation step is dedicated** — the mockup app catches spec gaps before code work
4. **Task breakdown drives code organisation** — generated code mirrors the task plan
5. **Branch points are explicit** — frontend vs backend parallelisable; mockup is optional
6. **AI-executable end state** — task-breakdown output is structured so individual
   tasks can be handed to AI agents and completed independently

---

## Skill Dependencies

```
project-prototype       (no dependencies)
       ↓
project-docs            (needs prototype + idea)
       │
       ├─→ project-mockup-app    (optional — needs docs)
       │
       └─→ task-breakdown        (needs docs; mockup feedback may have refined them)
                ↓
                ├─→ project-frontend      (needs docs + task breakdown)
                └─→ project-backend       (needs docs + task breakdown)
```

---

## Customising the Defaults

Each skill has sensible defaults but accepts user overrides:

- **Tech stack**: state your preference up front and the skill adapts
  ("Use Vue instead of React", "Use Drizzle instead of Prisma", "Use Go for backend")
- **i18n locales**: default is en + zh-TW; specify others
  ("English and Spanish only please")
- **Styling system**: default is Tailwind + shadcn/ui; specify others
  ("Use Mantine instead of shadcn")
- **Project structure**: defaults documented in each skill; ask for changes

---

## File Reference

- `skills/project-prototype/SKILL.md` — full prototype skill
- `skills/project-docs/SKILL.md` + `references/` — docs skill with templates
- `skills/project-mockup-app/SKILL.md` — quick demo skill
- `skills/task-breakdown/SKILL.md` + `references/` — task breakdown skill
- `skills/project-frontend/SKILL.md` — production frontend skill
- `skills/project-backend/SKILL.md` — production backend skill
- `WORKFLOW.md` — detailed phase-by-phase how-to
