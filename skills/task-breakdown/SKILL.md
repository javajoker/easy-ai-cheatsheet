---
name: task-breakdown
description: >
  Generates a complete, AI-executable project task breakdown from any project input —
  PRD, tech spec, whitepaper, architecture doc, or even a plain description. Produces
  a structured set of markdown files: an AGENT.md orchestration framework, a
  DEPENDENCY_GRAPH.md with full topological task ordering, a CONVENTIONS.md, and
  individual task files per component — each with YAML frontmatter, context, grouped
  task checklists, an AI execution prompt, expected outputs, and a verification checklist.
  Output is packaged as a downloadable tar archive.
---

# Task Breakdown Generator Skill

Converts any project input into a complete, AI-executable task breakdown system — the
same structure used to manage 1,000+ tasks across a 20-week blockchain + mobile + web
project. The output gives any AI agent enough context to pick up a task, execute it,
update its status, and hand off cleanly to the next task.

---

## Step 0 — Gather Input

Before analysing anything, collect the following. Check if they're already present in
the conversation; only ask for what's missing.

**Required (must have at least one):**
- [ ] PRD, tech spec, architecture doc, whitepaper, or plain-text description
- [ ] Project name and one-sentence purpose

**Optional (improves output quality significantly):**
- [ ] Tech stack (languages, frameworks, infra)
- [ ] Team size and composition (1 dev vs 5-person team changes task granularity)
- [ ] Timeline (weeks or months; if unknown, Claude will estimate)
- [ ] Any known constraints (existing codebases, fixed external APIs, compliance needs)

If the user only provided a document, extract the project name and purpose from it —
don't ask unless ambiguous.

---

## Step 1 — Analyse the Input

Read `references/analysis-guide.md` before starting analysis.

Run this analysis over the input document(s):

### 1a. Identify Components
Extract all distinct buildable components. A component is a deployable unit, major
service, or standalone application. Examples:
- Smart contracts (one per contract if complex, grouped if simple)
- Backend microservices (group by domain: auth, core, analytics)
- Frontend applications (one per app: web portal, mobile app, admin dashboard)
- Infrastructure (IaC, CI/CD, monitoring)
- External integrations (third-party APIs, hardware, firmware)
- Documentation

### 1b. Assign IDs, Weeks, Priority
For each component:
- **ID**: Short prefix + zero-padded number (e.g. `BE-001`, `CTR-002`, `FE-003`)
- **Week**: Estimate based on complexity and dependencies
- **Priority**: P1 (launch-blocking), P2 (important but deferrable), P3 (nice-to-have)
- **Hours**: Rough total estimate

### 1c. Map Dependencies
For every component, answer:
- What must exist before this can start? → `depends_on`
- What becomes unblocked when this is done? → `blocks`
- Is there a public interface that must be locked before downstream work begins? → `interface_lock`

### 1d. Identify the Critical Path
The critical path is the minimum chain from first task to launch. Anything on this
chain that slips delays launch by the same amount.

### 1e. Find Parallelisation Opportunities
Which components have no shared dependencies and can be built simultaneously?

---

## Step 2 — Generate the File Set

Generate all files. Read the relevant reference files first:
- `references/agent-template.md` → for AGENT.md
- `references/dependency-template.md` → for DEPENDENCY_GRAPH.md
- `references/task-file-template.md` → for individual task files
- `references/conventions-template.md` → for CONVENTIONS.md

### File set to produce:

```
{project-slug}-tasks/
├── AGENT.md                    ← AI orchestration framework
├── DEPENDENCY_GRAPH.md         ← Full dependency map (machine-readable)
├── CONVENTIONS.md              ← Code style, naming, repo layout
└── tasks/
    ├── {01-component-name}/
    │   └── {01-task-name}.md
    ├── {02-component-name}/
    │   └── {01-task-name}.md
    └── ...
```

**Naming rules:**
- Directory: zero-padded number + kebab-case component name (`01-smart-contracts`)
- File: zero-padded number + kebab-case task name (`01-pmn-token.md`)
- Group related sub-tasks in one file (e.g. all backend services in one file with
  sections per service) unless a component exceeds ~300 lines — then split per sub-component

---

## Step 3 — File Generation Rules

### AGENT.md must include:
1. Project description (what it is, who it's for, why it matters)
2. File structure map (directory tree of all generated files)
3. Task file anatomy (explain every section so AI knows how to read it)
4. AI Agent Operating Rules (7 non-negotiable rules — see template)
5. Standard Prompt Templates (one per domain: backend, frontend, contracts, mobile, etc.)
6. Recommended execution order (Phase 1, 2, 3… with task IDs)
7. How to ask AI to start / continue / find next task (3 copy-paste prompts)
8. Definition of Done (universal checklist)
9. Key Architectural Constants (immutable values the AI must never invent)

### DEPENDENCY_GRAPH.md must include:
1. Quick reference table (ID, Title, Week, Priority, Status, Depends On, Blocks)
2. ASCII dependency tree (visual, not just the table)
3. Parallel work opportunities
4. Critical path call-out
5. Hard external deadlines (app store submissions, audits, etc.)
6. Interface lock dates (when a public API/ABI must be frozen for downstream)

### CONVENTIONS.md must include:
1. Monorepo or repo structure (directory tree)
2. Naming conventions (files, functions, DB tables, API routes, etc.)
3. Code quality standards per layer (contracts, backend, frontend, mobile)
4. Environment variables (grouped by concern)
5. Port allocation (if microservices)

### Each task file must include all sections in this exact order:

```markdown
---
id: COMPONENT-NNN
title: Human-readable title
component: Component name
week: WX-WY
status: pending
priority: P1|P2|P3
hours: NNN
depends_on: [ID1, ID2]
blocks: [ID3, ID4]
interface_lock: "Description if this task has a downstream interface contract"
testnet_address: ""    ← only for blockchain tasks
---

# {ID}: {Title}

## Context
[2-4 sentences: why this task exists, what it produces, key architectural decisions
 that must be resolved BEFORE starting. Flag any "decide on Day 1" items explicitly.]

## Prerequisites
- [ ] Prerequisite 1 (from depends_on tasks)
- [ ] Prerequisite 2

## Tasks

### Group NN — {Group Name} ({total hours}h)
- [ ] **[P1]** Task description `file/path/hint` (Xh)
- [ ] **[P2]** Task description (Xh)
...

[Repeat for each group. Always end with a Testing group.]

## AI Execution Prompt

\`\`\`
[Self-contained prompt that an AI can copy-paste to execute this task.
Must include: role, task summary, stack constraints, critical rules,
 and the instruction to complete groups in order with reporting between groups.]
\`\`\`

## Expected Outputs
- `path/to/output/file.ext`
- `path/to/output/file2.ext` ← INTERFACE LOCK (if applicable)

## Verification
- [ ] Specific, measurable verification item
- [ ] All tests green
- [ ] Coverage target met
- [ ] Interface exported (if applicable)

## Notes
[Optional: gotchas, decisions made, links to specs. Leave blank if none.]
```

---

## Step 4 — Task Group Design Rules

When writing task groups inside a task file:

**Group naming pattern:**
- Group 01 — Scaffold / Setup
- Group 02 — Core Logic / Data Model
- Group 03 — [Primary feature A]
- Group 04 — [Primary feature B]
- ...
- Group N-1 — Integration Tests
- Group N — Deployment / Release (if applicable)
- **Always end with a Testing group**

**Task item rules:**
- Each item starts with `- [ ] **[P1|P2|P3]**`
- Include a `file/path/hint` in backticks when the output file path is known
- Include an hour estimate in parentheses: `(2h)`
- Items are atomic: one person can complete one item in one sitting
- P1 = required for the component to work; P2 = important; P3 = nice-to-have
- Aim for 4–10 items per group; split groups if they grow beyond 12 items
- The Testing group always includes a 100% coverage target item for contracts,
  80%+ for backend/frontend

**AI Execution Prompt rules:**
- Must be self-contained — copy-paste into a fresh AI session with no other context
- Format: role statement → task summary → stack/constraints → critical rules → instruction
- Include "Complete Groups 01-N in order. Report after each group before proceeding."
- Flag any "this is the highest-risk function" or "this must be locked by date X" items
- Keep under 40 lines

---

## Step 5 — Quality Checks Before Packaging

Before creating the tar, verify:

- [ ] Every `depends_on` ID in a task file exists as a real task ID elsewhere
- [ ] Every `blocks` ID is bidirectionally consistent (if A blocks B, B depends_on A)
- [ ] No task has `status: done` — all start as `pending`
- [ ] The critical path is explicitly called out in DEPENDENCY_GRAPH.md
- [ ] Every task file ends with a Testing group
- [ ] Every task file has an AI Execution Prompt
- [ ] AGENT.md execution order matches the dependency graph topological sort
- [ ] `interface_lock` is set on any task whose public API/ABI is imported by another task
- [ ] Total hours across all tasks is summed and reported to the user

---

## Step 6 — Package and Deliver

```bash
# Create the archive
cd /home/claude
tar -czf {project-slug}-tasks.tar.gz {project-slug}-tasks/

# Copy to outputs
cp {project-slug}-tasks.tar.gz /mnt/user-data/outputs/
```

Then use `present_files` to deliver the tar to the user.

Report to the user:
- Total files generated
- Total tasks across all files
- Total estimated hours
- Recommended first task to start
- Any ambiguities or assumptions made during analysis (ask for corrections)

---

## Calibration by Project Type

Read `references/project-type-patterns.md` for pre-defined patterns for common project
types. This saves analysis time and improves accuracy for well-known architectures.

Supported patterns:
- **Blockchain / DeFi / DePIN**: contracts first, then backend indexer, then frontends
- **SaaS web app**: auth + DB + API first, then frontend, then integrations
- **Mobile app**: API layer + auth first, then mobile screens, then native features
- **Data pipeline**: ingestion → transform → storage → serving → dashboard
- **API / SDK**: core library → docs → examples → SDKs → testing harness
- **Hardware + software**: firmware/spec → SDK → cloud backend → app
- **Marketplace**: auth + listings + search → transactions → reviews → analytics

For unknown project types, derive the pattern from the dependency analysis in Step 1.

---

## Scope Sizing Guide

Adjust task granularity based on team size and timeline:

| Team | Timeline | Task granularity |
|------|----------|-----------------|
| Solo dev | < 4 weeks | One file per phase, groups = days |
| Solo dev | 4–12 weeks | One file per component, groups = 2–4h blocks |
| 2–5 devs | 8–20 weeks | One file per component, groups = assignable units |
| 5+ devs | 20+ weeks | One file per sub-component, groups = 1-day sprints |

When in doubt: **more granular is better for AI execution** (easier to verify and check off).

---

## Reference Files

| File | When to read |
|------|-------------|
| `references/analysis-guide.md` | Step 1 — before analysing input |
| `references/agent-template.md` | Step 2 — when writing AGENT.md |
| `references/dependency-template.md` | Step 2 — when writing DEPENDENCY_GRAPH.md |
| `references/task-file-template.md` | Step 2 — when writing task files |
| `references/conventions-template.md` | Step 2 — when writing CONVENTIONS.md |
| `references/project-type-patterns.md` | Step 1 — for known project architectures |
| `references/ai-prompt-library.md` | Step 3 — copy-paste prompt templates by domain |
