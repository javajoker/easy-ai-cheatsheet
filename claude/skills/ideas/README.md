# Project Skillset

A twelve-skill toolkit covering the entire project lifecycle — from fuzzy
idea to production-ready codebase to onboarded existing project to
incremental feature delivery.

**Eight skills** form the linear "idea → built code" quick-start workflow.
**Three skills** handle the orthogonal tasks of onboarding an existing
project, producing the per-project INSTRUCTIONS files, and building a
conceptual knowledge base.
**One skill** (`feature-spec`) produces a single-feature delta spec for an
already-onboarded project — the incremental counterpart to `project-docs`.

This skillset replaces ad-hoc prompting with structured, composable skills that:
1. Each have a clear job and a clear handoff to the next.
2. Can be triggered automatically by Claude based on what you've already done.
3. Produce consistent, well-structured outputs that feed directly into the next step.
4. Let you skip, repeat, or branch any step without breaking the chain.
5. Support three backend languages (Node.js, Go, Python) sharing the same project docs.

---

## The Eight Skills

| # | Skill | Phase | Input | Output |
|---|-------|-------|-------|--------|
| 1 | `project-prototype` | Ideation | Idea description | Clickable React UI prototype with all roles + flows |
| 2 | `project-docs` | Specification | Idea + prototype + backend language choice | PRD.md, UIUX_SPEC.md, TECH_DESIGN.md |
| 3 | `project-mockup-app` | Validation (optional) | Project docs | Quick demo frontend with mock data, all views, no backend |
| 4 | `task-breakdown` | Planning | Project docs (+ optional mockup) | Full task plan: AGENT.md, DEPENDENCY_GRAPH.md, per-component task files |
| 5 | `project-frontend` | Production | Project docs **+ task breakdown** | Production React app with i18n + backend wiring |
| 6a | `project-backend-node` | Production (Node.js) | Project docs **+ task breakdown** | Fastify + Prisma + BullMQ project, i18n via i18next |
| 6b | `project-backend-go` | Production (Go) | Project docs **+ task breakdown** | Gin + GORM + asynq project, i18n via go-i18n (TOML) |
| 6c | `project-backend-python` | Production (Python) | Project docs **+ task breakdown** | FastAPI + SQLAlchemy + Celery project, i18n via Babel (.po/.mo) |

**Pick exactly one backend variant** based on the language chosen during `project-docs`.

## Ancillary skills

| Skill | Use when |
|---|---|
| `project-onboarding` | Bringing an existing codebase into the framework for the first time, or refreshing a long-inactive project. Reads the codebase, gathers facts, delegates artifact-writing to `create-project-instruction`, seeds memory. |
| `create-project-instruction` | Producing the per-project INSTRUCTIONS files from any input — an existing codebase, a fresh-project conversation, a PRD + tech design, or a hybrid. Called by `project-onboarding` (Mode A), can be called after `project-docs` (Mode C), or run standalone. |
| `project-knowledge-base` | Building a conceptual knowledge graph of an existing project (features, modules, abstractions, decisions, terminology). Output is a navigable docs/knowledge-base/ tree. |
| `feature-spec` | Producing a single-feature delta spec for an already-onboarded project — the incremental counterpart to `project-docs`. Writes `docs/features/FEATURE_<slug>.md` covering 11 sections (why, out-of-scope, load-bearing terms, contract deltas, verification, rollout, risks). Consumed by the `feature-development` agent. |

These four are *orthogonal* to the eight-skill linear workflow. You can run
them at any time before, after, or independently of the linear chain.
`create-project-instruction` is also the producer that `project-onboarding`
calls during its Phase 4. `feature-spec` typically runs under the
`feature-development` agent against a project that has already been
onboarded.

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
                       │  project-backend-{node, │  ◄─┘   docs + tasks
                       │   go, or python}        │
                       │   (production)          │
                       └─────────────────────────┘
```

### Phase 1 — Ideation (Skill 1)
You: *"I want to build a marketplace where artists license their IP for secondary creations."*

Claude triggers `project-prototype` and produces a clickable React mockup with all
roles and primary flows.

### Phase 2 — Specification (Skill 2)
You: *"Now create the formal docs."*

Claude triggers `project-docs`. **Critical: this skill asks which backend language
you want** (Node.js / Go / Python) before generating TECH_DESIGN.md. The chosen
language is baked into the tech design's stack table, library choices, and the
recommended downstream skill.

Outputs:
- **PRD.md** — personas, user stories, features, business rules
- **UIUX_SPEC.md** — every view, components, flows
- **TECH_DESIGN.md** — DB schema, every API endpoint, auth, **stack-specific i18n**,
  language-specific library choices

### Phase 3 — Validation (Skill 3, optional)
You: *"Build a quick demo first to validate the workflow."*

Claude triggers `project-mockup-app` — frontend-only, uses mock data. Language-agnostic
because there's no backend. Validates the docs before serious code work.

### Phase 4 — Planning (Skill 4)
You: *"Break this into AI-executable tasks."*

Claude triggers `task-breakdown` from the project docs. The task plan inherits the
backend language choice from TECH_DESIGN.md and produces tasks with
language-appropriate component IDs and AI execution prompts.

### Phase 5 — Production Code (Skills 5 + 6a/6b/6c, parallel)
You: *"Now build the real frontend and backend."*

Both skills consume **the project docs + the task breakdown**:

**`project-frontend`** — language-agnostic (always React + Vite + TS) — generates the
production frontend.

**`project-backend-node`** OR **`project-backend-go`** OR **`project-backend-python`**
— pick the one matching the tech design — generates the production backend with
matching folder organisation per task ID:
- Node.js → `src/modules/{task-id-slug}/` (kebab-case)
- Go → `internal/modules/{task_id_slug}/` (lowercase, no separators)
- Python → `app/modules/{task_id_slug}/` (snake_case)

Each module folder contains a README.md linking back to the source task file.

---

## How to Use

### Installation
Each skill folder under `skills/` is a standalone skill. Install all eight in your
Claude environment. Each skill becomes available based on its description matching
your prompt.

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
| "Build the Node.js backend" / "Build the TypeScript API" | project-backend-node |
| "Build the Go backend" / "Build the Golang API" | project-backend-go |
| "Build the Python backend" / "Build the FastAPI app" | project-backend-python |
| "Build the backend" (unspecified) | matches whichever language is in TECH_DESIGN.md |

### Triggering — explicit invocation
You can also invoke a skill explicitly by name:
> "Use the project-backend-go skill to generate the backend from these docs and
> task breakdown."

### Backend language: when to choose what

| Choose Node.js if… | Choose Go if… | Choose Python if… |
|--------------------|---------------|-------------------|
| You want fastest dev velocity | You need lowest p95 latency at minimal compute cost | You need ML / data-science integration |
| Your team is TS-heavy | You expect high concurrency | Your team is Python-heavy |
| You want full TS type sharing between FE and BE | You're building infrastructure-level services | You need scientific computing libraries |
| The project is a typical SaaS / CRUD app | You prioritise small binary deploys | The project is a typical web API with light compute |

All three meet the standard performance targets (p95 < 500ms) with appropriate
horizontal scaling. The choice is mostly about team familiarity and ecosystem fit.

### Resuming mid-workflow
The skills are designed to pick up wherever you are. Bring in your existing assets:

> "Here's our existing PRD, tech design, and task breakdown [attaches files].
> Generate the Python backend now."

→ `project-backend-python` uses what you provide and skips earlier phases.

### Skipping or repeating phases
- **Skip prototype**: provide an idea + wireframes; jump to project-docs
- **Skip mockup**: go from project-docs to task-breakdown
- **Switch backend language mid-project**: re-run project-docs with the new
  language choice (the API contract stays the same — only the implementation
  language changes), then re-run the matching backend skill
- **Repeat tasks**: re-run task-breakdown after major spec changes

### Delivering outputs
All skills deliver via `present_files` to `/mnt/user-data/outputs/`:
- `project-prototype` → React artifact (rendered inline) or tar
- `project-docs` → PRD.md + UIUX_SPEC.md + TECH_DESIGN.md
- `project-mockup-app` → `mockup-app.tar.gz`
- `task-breakdown` → `{project}-tasks.tar.gz`
- `project-frontend` → `{project}-frontend.tar.gz`
- `project-backend-node` → `{project}-backend-node.tar.gz`
- `project-backend-go` → `{project}-backend-go.tar.gz`
- `project-backend-python` → `{project}-backend-py.tar.gz`

---

## End-to-End Example

### Starting prompt
> "I want to build an open-IP-licensing marketplace where creators can register their
> IP, set licensing terms with revenue shares..."

### Phase 1 — Prototype
Claude triggers `project-prototype`. Identifies 3 personas + Admin. Generates ~18
views as a React artifact.

### Phase 2 — Docs (asks about backend language!)
> "Now create the docs."

Claude triggers `project-docs` and asks:
> "Which backend language? Node.js (default), Go, or Python?"

You: *"Go please — we need low latency for the verification endpoint."*

Claude generates:
- PRD.md: 4 personas, 32 user stories, 45 features
- UIUX_SPEC.md: 22 views, component library, 8 user flows
- TECH_DESIGN.md with **Backend stack: Go**, including:
  - Gin + GORM + asynq stack table
  - JWT via golang-jwt
  - i18n via go-i18n with TOML catalogues
  - All 67 endpoints documented with owning task IDs
  - All workers using asynq

### Phase 3 — Quick Demo (optional)
> "Build a quick demo first."

`project-mockup-app` runs — frontend only, mock data, language-agnostic. You demo
to stakeholders.

### Phase 4 — Task Breakdown
> "Break it down into tasks."

`task-breakdown` produces 8 components, 12-week timeline, ~150 tasks. Backend tasks
reference Go-specific structure (e.g. `BE-003: Auth Service` will become
`internal/modules/be003auth/` package).

### Phase 5 — Production Code
> "Now the real frontend and Go backend."

`project-frontend` produces the React app with i18n.
`project-backend-go` produces the Go backend with `internal/modules/{task_id}/`
packages aligned with the task plan.

Both share the API contract (TECH_DESIGN.md) and the task plan organisation.

---

## Why This Skillset Works

1. **Each skill has one job** — focused, small, won't drift
2. **Outputs feed directly into next inputs** — no manual translation between phases
3. **Validation step is dedicated** — the mockup app catches spec gaps before code work
4. **Task breakdown drives code organisation** — generated code mirrors the task plan
5. **Backend language is a first-class choice** — same docs + tasks, three production
   backend variants, share the API contract exactly
6. **AI-executable end state** — task-breakdown output is structured so individual
   tasks can be handed to AI agents and completed independently

---

## Skill Dependencies

```
project-prototype       (no dependencies)
       ↓
project-docs            (needs prototype + idea + backend language choice)
       │
       ├─→ project-mockup-app    (optional — needs docs)
       │
       └─→ task-breakdown        (needs docs)
                ↓
                ├─→ project-frontend         (needs docs + task breakdown)
                └─→ project-backend-{node|go|python}
                                              (needs docs + task breakdown;
                                               choice driven by tech design)
```

---

## Customising the Defaults

Each skill has sensible defaults but accepts user overrides:

- **Backend language**: choose Node.js (default), Go, or Python during project-docs
- **Frontend framework**: defaults to React + Vite + TS; specify others
  ("Use Vue instead of React")
- **i18n locales**: default is en + zh-TW; specify others
- **ORM / queue / framework within a language**: specify in tech design
  - Node.js: Fastify + Prisma + BullMQ (default) / Express + Drizzle / NestJS
  - Go: Gin + GORM + asynq (default) / Echo + sqlx / Fiber + ent
  - Python: FastAPI + SQLAlchemy + Celery (default) / Django REST / Flask + arq

---

## File Reference

- `skills/project-prototype/SKILL.md` — prototype skill
- `skills/project-docs/SKILL.md` + `references/` — docs skill (asks language choice)
- `skills/project-mockup-app/SKILL.md` — quick demo skill
- `skills/task-breakdown/SKILL.md` + `references/` — task breakdown skill
- `skills/project-frontend/SKILL.md` — production frontend skill (language-agnostic)
- `skills/project-backend-node/SKILL.md` — Node.js backend
- `skills/project-backend-go/SKILL.md` — Go backend
- `skills/project-backend-python/SKILL.md` — Python backend
- `skills/feature-spec/SKILL.md` + `references/` — single-feature delta spec for onboarded projects
- `WORKFLOW.md` — detailed phase-by-phase walkthrough
