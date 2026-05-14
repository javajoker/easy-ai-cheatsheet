# DEPENDENCY_GRAPH.md Template

```markdown
# {Project Name} — Full Dependency Graph

> **Machine-readable dependency map for AI task orchestration.**
> A task cannot start until all `depends_on` tasks are `status: done`.

---

## Quick Reference Table

| ID | Title | Week | Priority | Status | Depends On | Blocks |
|----|-------|------|----------|--------|------------|--------|
| {ID} | {Title} | W{X}-W{Y} | P{1} | pending | — | {ID2, ID3} |
| {ID} | {Title} | W{X}-W{Y} | P{1} | pending | {ID1} | {ID4} |
{Add all tasks. Use — for empty depends_on or blocks.}

---

## Dependency Tree (ASCII)

\`\`\`
W{X}  {ID}: {Title}
      {ID}: {Title}
          |
W{Y}  +---+-------------------+
      {ID}: {Title}      {ID}: {Title}
          |                    |
W{Z}  +---+                +---+
      {ID}: {Title}        {ID}: {Title}
\`\`\`

---

## Parallel Work Opportunities

| Pair | Why they can run simultaneously |
|------|---------------------------------|
| {ID1} + {ID2} | {Reason: no shared dependencies} |
{Add all parallelisable pairs.}

---

## Critical Path

The minimum sequence that must not slip:

\`\`\`
{ID1} -> {ID2} -> {ID3} -> {ID4} -> Launch
\`\`\`

If any task on the critical path slips by 1 {week/sprint}, launch slips by the same.

---

## Hard External Deadlines

| Milestone | Timing | Action Required |
|-----------|--------|----------------|
{| {Milestone} | {Week N or date} | {What to do and when} |}
{Examples:
 | Book security auditor | W9 | Contact auditor firms — 4-8 week lead time |
 | App Store submission | W16 | Submit before review window |
 | Beta launch | W12 | Marketing and user recruitment |
}

---

## Interface Lock Dates

| Interface | Lock By | Consumed By |
|-----------|---------|-------------|
{| {Interface description} | End W{N} | {Component that imports it} |}
{Examples:
 | Auth service JWT public key | End W4 | All other backend services |
 | REST API schema v1 | End W6 | Frontend web and mobile apps |
 | Database schema migration baseline | End W2 | All backend services |
}
```

---

# CONVENTIONS.md Template

```markdown
# {Project Name} — Conventions and Repo Layout

## Repository Structure

\`\`\`
{project-root}/
{List the full directory tree using the actual structure for this project.}
{Group by: apps/, services/, packages/, infrastructure/, contracts/ as applicable.}
\`\`\`

---

## Naming Conventions

### Files and Directories
- **Directories**: {e.g. kebab-case}
- **TypeScript/JS files**: {e.g. camelCase.ts for modules, PascalCase.tsx for React}
- **Test files**: {e.g. *.test.ts alongside source, or __tests__/ subdirectory}
- **{Other file type}**: {naming rule}

### {Language/Layer — e.g. TypeScript}
- **Types/Interfaces**: {e.g. PascalCase}
- **Functions**: {e.g. camelCase}
- **Constants**: {e.g. SCREAMING_SNAKE_CASE}
- **React components**: {e.g. PascalCase}
- **Database tables**: {e.g. snake_case plural}
- **API routes**: {e.g. /kebab-case/{:id}/sub-resource}

### {Another layer — e.g. Solidity, Python, etc.}
{Same pattern}

---

## Code Quality Standards

### {Layer 1 — e.g. TypeScript/JavaScript}
- {Rule 1: e.g. strict mode always on}
- {Rule 2: e.g. no any — use unknown and narrow}
- {Rule 3: e.g. Zod for all external input validation}
- {Rule 4: e.g. no console.log in production — use structured logger}

### {Layer 2}
{Same pattern}

### Testing
- **{Layer}**: {Framework} + {assertion library}; {coverage target}
- **{Layer}**: {Framework}; {E2E tool}; {coverage target}

### Git
- Branch: {naming convention, e.g. feat/{ticket}-{slug}}
- Commits: {convention, e.g. conventional commits}
- PRs: {review requirements}
- Merge: {strategy, e.g. squash merge to main}

---

## Environment Variables

\`\`\`env
# Required — all services
{VAR_NAME}={description or example}

# Service-specific
{VAR_NAME}={description}
\`\`\`

---

## {Port Allocation / Service Endpoints}  [include if microservices]

| Service | Port/URL |
|---------|----------|
{| {Service name} | {port or URL pattern} |}
```
