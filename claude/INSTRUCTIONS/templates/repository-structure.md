---
id: "repository-structure-{project-slug}-001"
title: "Repository Structure — {Project Name}"
type: reference
status: draft
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags: ["repo-structure", "{project-slug}"]
---

# Repository Structure — {Project Name}

> A map of the codebase. The goal is that a new contributor (human or AI)
> can find anything within sixty seconds.

## Top-level layout

```
{project-slug}/
├── .claude/                     # Claude Code configuration
│   ├── CLAUDE.md                # primary AI configuration (always loaded)
│   ├── INSTRUCTIONS/            # AI instructions for this project (may link to the framework)
│   └── skills/                  # project-specific skills (if any)
├── docs/                        # project documentation
│   ├── docs-index.md            # global doc index (update on every doc change)
│   ├── prd/                     # product requirements
│   ├── design/                  # tech design
│   ├── api/                     # API reference
│   └── progress.md              # execution journal
├── src/                         # source code (or `internal/` for Go, `app/` for Python, etc.)
└── tests/                       # tests (if not co-located with source)
```

Adapt the structure to the language's idiom. Examples:

- Go monorepo library: `cmd/`, `internal/`, `pkg/`, `example/`.
- Go service: `cmd/`, `internal/`, `migrations/`.
- Python FastAPI service: `app/`, `tests/`, `alembic/`.
- Node.js service: `src/`, `prisma/`, `tests/`.
- React frontend: `src/`, `public/`, `e2e/`.

## Source code organization

> Describe the top-level directories under your source root and what lives
> where. One line per directory; link to deeper notes if the directory has
> internal structure worth describing.

```
src/  (or internal/, app/, …)
├── module/                      # business modules, vertically sliced
│   ├── user/
│   ├── …/
├── model/                       # shared data models
├── middleware/                  # cross-cutting middleware
└── pkg/                         # external SDK wrappers
```

Per-module layout — if the project uses a consistent shape, describe it
once here:

```
module/<name>/
├── service.go      # business logic
├── handler.go      # HTTP / RPC handlers
├── repo.go         # data access
└── module.go       # wiring
```

## Documentation layout

```
docs/
├── docs-index.md                # required: every doc has an entry
├── prd/                         # product requirements
├── design/                      # architectural designs
├── api/                         # API reference (often generated)
├── runbook/                     # operational procedures
└── progress.md                  # execution journal
```

## Where things go — quick reference

| Type of content | Location |
|---|---|
| Product requirements | `docs/prd/` |
| Architecture and design | `docs/design/` |
| API reference | `docs/api/` |
| Runbooks (incidents, releases) | `docs/runbook/` |
| Source code | `src/` (or language-idiomatic equivalent) |
| Tests | co-located with source, or `tests/` |
| Migration scripts | `migrations/` |
| Sample / seed data | `scripts/seed/` or `migrations/seed/` |

## Document ID conventions

> Adapt to your indexing system. Default kebab-case `{type}-{topic}-{seq}`.

| Document | ID | Path |
|---|---|---|
| {example: Architecture overview} | `design-architecture-001` | `docs/design/architecture.md` |

## Cross-references

This project uses {plain markdown links | Obsidian WikiLinks | both}. See
the project's `markdown-conventions.md` if it overrides the framework default.

## Related framework files

- Universal: `INSTRUCTIONS/README.md`, `INSTRUCTIONS/development-principles.md`.
- This project's: `INSTRUCTIONS/projects/{project-slug}/project-context.md`.

---

**How to use this template:**

1. Copy this file to `INSTRUCTIONS/projects/<your-slug>/repository-structure.md`.
2. Replace every `{placeholder}` and remove this footer.
3. Tailor the layout sections to your project's actual structure.
4. Reference it from the project's `CLAUDE.md`.
