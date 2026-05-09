# AGENT.md Template

The AGENT.md is the entry point for any AI agent working on the project.
It must be completely self-contained — an AI reading only this file should understand
the project, find the right task, and know exactly what rules to follow.

Fill in all {PLACEHOLDERS}. The 7 Operating Rules below are fixed — do not change them.

---

```markdown
# {Project Name} — AI Agent Framework

> **This file is the entry point for any AI agent working on this project.**
> Read this entire file before touching any task file.

---

## 1. What Is This Project?

**{Project Name}** is {one sentence description}.

{2-3 sentences expanding on the core components, users, and purpose.}

The full stack is a **{N-week}, ~{total hours} hour** build across {N} components.

---

## 2. How to Use These Files

### File Structure
\`\`\`
{project-slug}-tasks/
├── AGENT.md                    ← YOU ARE HERE — read first
├── DEPENDENCY_GRAPH.md         ← Full dependency map (read before picking tasks)
├── CONVENTIONS.md              ← Code style, naming, repo layout
└── tasks/
{    LIST EVERY TASK FILE WITH FULL PATH}
\`\`\`

### Task File Anatomy

Every task file has these sections:
- **YAML frontmatter**: id, status, depends_on, blocks, week, hours, priority
- **Context**: Why this task exists, key decisions, downstream contracts
- **Prerequisites**: What must exist before starting
- **Tasks**: Grouped checklists with priority badges and hour estimates
- **AI Execution Prompt**: Self-contained prompt to execute the task
- **Expected Outputs**: Files and artefacts to produce
- **Verification**: How to confirm completion

---

## 3. AI Agent Operating Rules

When acting as an agent on this project, follow these rules **without exception**:

### Rule 1 — Always Check Dependencies First
Before starting any task, verify all `depends_on` tasks in DEPENDENCY_GRAPH.md are
`status: done`. If any dependency is not done, **do not start** — report which dependency
is blocking and ask the human which task to work on next.

### Rule 2 — One Task Group at a Time
Complete one group fully before moving to the next. After each group, update the task
file's checkboxes and `status` field, then report before continuing.

### Rule 3 — Update Status in Real Time
After completing a task item, mark its checkbox:
\`\`\`markdown
- [x] **[P1]** Task that is done
- [ ] **[P1]** Task still pending
\`\`\`
Update frontmatter `status`: pending → in-progress → done.

### Rule 4 — Always Write Tests
No task is `done` without tests passing. Every Tasks section ends with a Testing group.
Do not mark a task done until tests pass and coverage target is met.

### Rule 5 — Lock Interfaces Before Downstream Work
When a task has `interface_lock` set, export the public interface (ABI, API schema,
TypeScript types) to the `packages/` directory and commit it before any blocked task starts.

### Rule 6 — Never Invent Specifications
If a task requires a decision not covered in the task file, **stop and ask**.
Do not invent: {list the most sensitive specs for this project — e.g. "token economics,
contract parameters, API schemas, UI designs, pricing"}.

### Rule 7 — {Project-specific rule}
{Add one rule that is unique to this project's risk profile. Examples:
- "Smart contracts: never skip the security audit checklist before marking done"
- "Never store PII unencrypted; always encrypt before persisting to any database"
- "All user-facing copy must be approved by the product team before shipping"
- "Payment-related code must have a second pair of eyes before merging"}

---

## 4. Standard Prompt Templates

### Template A — {Primary domain, e.g. "Smart Contract Task"}

\`\`\`
You are a {role} working on the {Project Name} project.

## Project Context
{2-3 sentences about the project and this domain's role in it}

## Your Current Task
[PASTE TASK TITLE AND CONTEXT SECTION FROM TASK FILE]

## Stack
{- Language + version}
{- Framework + version}
{- Testing framework}

## Critical Constraints
{- Constraint 1 (e.g. 100% branch coverage)}
{- Constraint 2 (e.g. custom errors only)}
{- Constraint 3 (e.g. all roles use AccessControl)}

## Task Checklist
[PASTE THE ## Tasks SECTION FROM THE TASK FILE]

## Required Outputs
[PASTE THE ## Expected Outputs SECTION FROM THE TASK FILE]

Complete each group in order. After each group, run tests, report what you completed,
and ask before proceeding.
\`\`\`

### Template B — {Secondary domain, e.g. "Backend Service Task"}

\`\`\`
{Same structure, different domain/stack/constraints}
\`\`\`

### Template C — {Third domain, e.g. "Frontend Task"}

\`\`\`
{Same structure}
\`\`\`

---

## 5. Execution Order

Follow this order strictly — later items depend on earlier ones:

\`\`\`
Phase 1 — Foundation ({WX}–{WY}):
  [1] {COMPONENT-ID}: {Title}      ← Start here
  [2] {COMPONENT-ID}: {Title}      ← Parallel with [1]
  [3] {COMPONENT-ID}: {Title}      ← After [1]

Phase 2 — Core Build ({WX}–{WY}):
  [4] {COMPONENT-ID}: {Title}      ← After [1][2]
  [5] {COMPONENT-ID}: {Title}      ← Parallel with [4]

Phase 3 — {Phase name} ({WX}–{WY}):
  [6] {COMPONENT-ID}: {Title}
  [7] {COMPONENT-ID}: {Title}

Phase 4 — Launch Prep ({WX}–{WY}):
  [8] {COMPONENT-ID}: {Title}
  {External deadline: book {X} at week {N}}
  {Hard gate: {Y} must complete before {Z}}
\`\`\`

---

## 6. How to Ask AI to Start Working

### Option A — Start a specific task
\`\`\`
Read {project-slug}-tasks/AGENT.md and {project-slug}-tasks/DEPENDENCY_GRAPH.md.
Open {project-slug}-tasks/tasks/{path/to/task.md} and execute all tasks in it.
Follow the AI Execution Prompt in that file exactly.
Update checkboxes and status as you go.
\`\`\`

### Option B — Continue where left off
\`\`\`
Read {project-slug}-tasks/AGENT.md.
Scan all task files for status: in-progress or the most recently completed done task.
Identify the next unblocked task (all depends_on are done).
Open that task file and execute it.
\`\`\`

### Option C — Find next task automatically
\`\`\`
Read {project-slug}-tasks/DEPENDENCY_GRAPH.md.
List all tasks where status is pending and all depends_on are status: done.
Sort by week (earliest first), then priority (P1 first).
Tell me the top 3 unblocked tasks to work on next.
\`\`\`

---

## 7. Definition of Done

A task is `status: done` when ALL of the following are true:
- [ ] All checkboxes in the task file are checked
- [ ] Tests written and passing (coverage target met)
- [ ] No P1/P2 lint or type errors
- [ ] If `interface_lock` set: public interface exported to `packages/` and committed
{Add project-specific done criteria below:}
- [ ] {e.g. "Deployed to staging/testnet and address recorded"}
- [ ] {e.g. "Swagger/OpenAPI spec updated"}
- [ ] {e.g. "Lighthouse score ≥ 85 Performance, ≥ 90 Accessibility"}
- [ ] {e.g. "Sentry SDK integrated — no silent try/catch"}

---

## 8. Key Architectural Constants

These values are fixed — **never change without explicit team decision**:

| Constant | Value |
|----------|-------|
{| {Constant name} | {Value} |}
{| {Constant name} | {Value} |}
{Add all domain-specific constants: fee percentages, token amounts, timeouts,
 rate limits, SLA targets, max file sizes, API versions, etc.}
```

---

## Notes on Filling In AGENT.md

### Project Description (Section 1)
- Include the total number of components and weeks prominently
- Name each major component category (not individual services)
- One sentence per component type is enough

### Prompt Templates (Section 4)
- Create one template per major domain in the project
- Common domains: Smart Contracts, Backend/API, Frontend Web, Mobile, Infrastructure, Data/ML
- If the project only has one domain, one template is fine
- Each template must be self-contained — someone should be able to copy-paste it into Claude with no additional context

### Execution Order (Section 5)
- Derive directly from the topological sort in DEPENDENCY_GRAPH.md
- Group into phases by dependency boundaries (Phase = "all tasks in this phase can start after Phase N-1")
- Call out the critical path task in each phase
- Note any external dependencies (booking auditors, app store submissions) at their required week

### Key Architectural Constants (Section 8)
- Extract all numeric/boolean constants from the PRD/spec
- Include: timeouts, rate limits, sizes, percentages, version numbers, flag values
- These prevent AI from inventing parameters during implementation
