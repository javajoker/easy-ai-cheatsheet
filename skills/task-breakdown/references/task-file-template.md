# Task File Template

Copy this structure for every task file. Replace all `{PLACEHOLDER}` values.
Sections marked [REQUIRED] must always be present. [OPTIONAL] can be omitted if not applicable.

---

```markdown
---
id: {PREFIX}-{NNN}
title: {Human-readable component title}
component: {Component category, e.g. "Smart Contracts", "Backend", "Frontend — Mobile"}
week: W{X}-W{Y}
status: pending
priority: P{1|2|3}
hours: {total estimated hours}
depends_on: [{ID1}, {ID2}]   # leave [] if none
blocks: [{ID3}, {ID4}]        # leave [] if none
interface_lock: "{Description of the interface that must be locked for downstream tasks}"  # omit if not applicable
---

# {PREFIX}-{NNN}: {Title}  [REQUIRED]

## Context  [REQUIRED]
{2–4 sentences covering:}
{1. What this component does and why it exists}
{2. The most important architectural decision(s) that must be made BEFORE starting}
{3. Any downstream contracts ("this locks an interface used by X")}
{4. Key risk or gotcha ("the highest-risk function is...")}

**Decide on Day 1:** {If there is a binary architectural decision, state it here with recommendation}

## Prerequisites  [REQUIRED]
- [ ] {Dependency 1 from depends_on tasks — what specifically must exist}
- [ ] {Dependency 2}
{...}

## Tasks  [REQUIRED]

### Group 01 — {Scaffold / Setup / Project Init} ({subtotal}h)
- [ ] **[P1]** {Task description} `{optional/file/path/hint}` ({X}h)
- [ ] **[P1]** {Task description} ({X}h)
- [ ] **[P2]** {Task description} ({X}h)

### Group 02 — {Core Data Model / Schema / Storage} ({subtotal}h)
- [ ] **[P1]** {Task description} ({X}h)
- [ ] **[P2]** {Task description} ({X}h)

### Group 03 — {Primary Feature A} ({subtotal}h)
- [ ] **[P1]** {Task description} ({X}h)
{...}

### Group {N-1} — Unit Tests ({subtotal}h)
- [ ] **[P1]** {Test suite 1}: {what it tests} `{test/path.test.ts}` ({X}h)
- [ ] **[P1]** {Test suite 2}: {what it tests} ({X}h)
- [ ] **[P1]** {Coverage target: 100% line + branch / 80%+ line + branch} ({X}h)

### Group {N} — Integration Tests ({subtotal}h)  [include if testable end-to-end]
- [ ] **[P1]** {Integration test scenario}: {happy path description} `{test/integration/path.test.ts}` ({X}h)
- [ ] **[P2]** {Edge case scenario} ({X}h)

### Group {N+1} — Deployment ({subtotal}h)  [include for deployable components]
- [ ] **[P1]** {Deploy script or build command} `{path/to/script}` ({X}h)
- [ ] **[P1]** {Verify or publish step} ({X}h)
- [ ] **[P1]** Export {ABI/types/schema} to `{packages/shared/path}` ({X}h)  ← INTERFACE LOCK OUTPUT

## AI Execution Prompt  [REQUIRED]

\`\`\`
You are a {role} working on the {Project Name} project.

TASK: {One-sentence task summary}

{CONTEXT BLOCK — 3-8 lines covering:}
{- What this component is for}
{- The most critical implementation constraint or risk}
{- Any decisions that must be made before starting}
{- Key integration points with other components}

STACK:
{- Language + runtime version}
{- Key framework(s) + versions}
{- Testing framework}
{- Deployment target}

CRITICAL RULES:
{- Rule 1: the thing that, if wrong, breaks everything}
{- Rule 2: the security or correctness constraint}
{- Rule 3: the interface contract that must be respected}

Complete Groups 01–{N} in order. After each group:
1. {Compile/run/build} — must pass
2. {Test command} — all tests must pass
3. Check off completed items in the task file
4. Report what you completed before moving to the next group
\`\`\`

## Expected Outputs  [REQUIRED]
- `{path/to/primary/output.ext}`
- `{path/to/secondary/output.ext}`
- `{packages/shared/interface.json}` ← INTERFACE LOCK  [if applicable]

## Verification Checklist  [REQUIRED]
- [ ] All task checkboxes checked
- [ ] {Specific test command} — all green
- [ ] {Coverage target} met
- [ ] {Deploy/verify step} confirmed
- [ ] {Interface exported} committed  [if interface lock]
- [ ] No P1/P2 lint or type errors

## Notes  [OPTIONAL]
{Any gotchas, links to external specs, or decisions recorded here.}
{Delete this section if empty.}
```

---

## Rules for Filling In This Template

### Context section
- **Do** name the single highest-risk function, the most important design decision, and the downstream dependency
- **Do** flag "Decide on Day 1" items explicitly
- **Don't** write a generic description ("this component handles authentication")
- **Don't** make it longer than 4 sentences + the Decide on Day 1 line

### Task items
- **Do** write tasks at a level where a competent developer can complete one item in 30min–4h
- **Do** include `file/path` hints when the output file location is deterministic
- **Do** include hour estimates on every item
- **Don't** write tasks vague enough to mean anything ("implement feature X")
- **Don't** write tasks so atomic they're just keystrokes ("add semicolon to line 42")

### Testing group
- Always the last group(s) before Deployment
- Unit tests come before Integration tests
- Every contract task file must have "100% branch coverage" as a P1 item
- Every backend/frontend task file should have "80%+ line coverage" or equivalent

### AI Execution Prompt
- Must work as a standalone prompt — no "see above" references
- If the task spans multiple domains (e.g. contract + backend), write multiple role sections
- The "Complete Groups in order, report between groups" instruction is non-negotiable — it's how the AI self-checks
- Flag the highest-risk function with "**HIGHEST RISK:**" prefix

### Interface Lock
- Use when this task produces an ABI, API schema, TypeScript types, or any contract that another task imports
- The exported file path goes in Expected Outputs marked ← INTERFACE LOCK
- The `interface_lock` frontmatter field explains which downstream tasks are gated
- In DEPENDENCY_GRAPH.md, add a row to the Interface Lock Dates table

---

## Multi-Service Task File Pattern

When multiple related services fit naturally in one file (e.g. several backend microservices
with identical structure), use a header + horizontal rule to separate them:

```markdown
---
id: BE-002
title: Auth Service
...
---

# BE-002: Auth Service

{Context for auth service...}

## Tasks

### Group 01 — {Auth service task}
...

---

## BE-003: User Service  ← starts new service section

{Context for user service...}

## Tasks (BE-003)

### Group 01 — {User service task}
...
```

Include both IDs in the DEPENDENCY_GRAPH.md as separate rows but point to the same file.
