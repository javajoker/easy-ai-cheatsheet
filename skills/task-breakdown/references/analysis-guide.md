# Analysis Guide — How to Extract Tasks from Project Documents

Read this before analysing any input document in Step 1 of the skill.

---

## Document Types and What to Extract

### PRD (Product Requirements Document)
Extract from:
- **Features list / user stories** → individual tasks per feature
- **Non-functional requirements** (performance, security, compliance) → infrastructure tasks, testing tasks
- **User personas** → separate frontend apps or role-based flows per persona
- **Success metrics** → analytics service tasks, tracking tasks
- **Out of scope** → mark as P3 or explicitly exclude
- **Milestones / phasing** → use as phase boundaries in AGENT.md execution order

Red flags in PRDs:
- "TBD" or "to be decided" sections → flag as "Decision required before starting" in Context
- Features with external dependencies (third-party APIs, hardware) → add as explicit prerequisites
- Performance SLAs → add as Verification items in relevant task files

### Technical Design / Architecture Doc
Extract from:
- **System diagram** → one component per box in the diagram
- **Data model / schema** → DB schema task inside the relevant service
- **API contracts** → backend service tasks; mark with `interface_lock`
- **Security model** → security hardening group inside each component
- **Deployment architecture** → Infrastructure component
- **Technology decisions** → populate CONVENTIONS.md

### Whitepaper / Concept Doc
Extract from:
- **Protocol mechanics** (token economics, reward formulas, governance rules) → smart contract tasks
- **Actor roles** (creator, consumer, operator, validator) → separate frontend apps per role
- **Flow diagrams** → task groups within a component (each step in the flow = a task)
- **Constants / parameters** → populate "Key Architectural Constants" in AGENT.md
- **Phase roadmap** → use as phase groupings in execution order

### Plain Description / User Message
When the user provides just text (no uploaded doc):
- Ask 2–3 clarifying questions maximum (stack preference, timeline, team size)
- Infer the rest from common patterns for the project type
- Make assumptions explicit in the report at the end

---

## Component Identification Heuristics

A component = something that can be deployed or shipped independently.

**Definitely separate components:**
- Separate tech stacks (e.g. Python service vs Node.js service)
- Separate deployment units (mobile app vs web app vs API vs contract)
- Separate data stores (each DB, each cache cluster)
- Hardware vs software split

**Can be one component (grouped in one task file):**
- Multiple smart contracts that form a suite (same repo, same deploy pipeline)
- Multiple microservices with identical tech stacks and tight coupling
- Frontend + BFF (Backend for Frontend) when the BFF is trivial
- Documentation + developer portal (same tech, similar content)

**Signals to split into sub-tasks within one file vs separate files:**
- If one component has > 8 groups → consider splitting into multiple files
- If two components can be assigned to different devs simultaneously → separate files
- If one component gates 3+ other components → always its own file (highest visibility)

---

## Dependency Extraction

For each pair of components A and B, ask:

1. **Does B need any output from A to start?**
   - If yes: B depends_on A
   - Outputs include: ABIs, shared types, environment variables, running services, database schemas

2. **Does B's public interface need to be frozen before A can be finalised?**
   - If yes: A has `interface_lock` pointing to B's dependency on it

3. **Can A and B start on the same day with mocked versions of each other's outputs?**
   - If yes: they're parallel, just note the mock requirement

**Common dependency patterns:**

```
DB schema → ALL backend services
Auth service → ALL other services (JWT public key needed)
Shared types package → ALL apps
Blockchain indexer → ANY frontend reading on-chain state
Smart contract ABI → backend services calling those contracts
Smart contract ABI → frontend apps calling those contracts
Design system → ALL frontend components
```

---

## Hour Estimation Heuristics

Use these as starting points, adjust for team experience:

| Task type | Typical range |
|-----------|--------------|
| Smart contract (simple, <200 lines) | 8–16h incl. tests |
| Smart contract (complex, escrow/governance) | 40–120h incl. tests |
| Backend CRUD service (5 endpoints) | 8–16h incl. tests |
| Backend complex service (payments, WS) | 24–48h |
| Frontend page (simple, static) | 2–4h |
| Frontend complex screen (real-time, forms) | 4–12h |
| Mobile screen (simple) | 3–6h |
| Mobile screen (complex, native APIs) | 8–20h |
| Infrastructure / DevOps setup | 8–24h |
| Documentation page | 1–3h |
| Test suite (unit, integration) | 20–30% of implementation time |
| Deployment + verification | 2–8h per component |

**Rules:**
- Always include testing time in the total (not as a separate line item unless it's a whole testing phase)
- Add 20% buffer for integration and debugging across services
- P3 tasks: estimate but note "can defer"

---

## Priority Assignment Rules

**P1 — Launch blocking. Must be done before any dependent can ship.**
- Any task on the critical path
- Security, auth, payment handling
- Core data models / schema (everything reads from them)
- Any task that 3+ other tasks depend on

**P2 — Important but can launch without it if needed.**
- Features needed by early adopters but not all users
- Admin tooling, analytics, monitoring
- Secondary flows (edge cases, error handling details)
- Performance optimisations (unless there's a hard SLA)

**P3 — Nice-to-have.**
- Convenience features
- Advanced customisation options
- Tooling improvements
- Future-proofing that isn't needed at V1

**Rule of thumb**: If removing a task would cause a launch-critical user flow to break → P1.

---

## Spotting Architectural Decisions

Some tasks require a design decision to be made *before* writing code. These must be
flagged in the **Context** section of the task file with the phrase "**Decide on Day 1**:"

Common examples:
- Authentication strategy (JWT vs sessions vs OAuth)
- Database choice (PostgreSQL vs MongoDB, etc.)
- Monorepo vs polyrepo
- Mobile: Expo managed vs bare workflow
- State management approach
- Upgrade/proxy strategy for smart contracts
- On-chain vs off-chain computation for expensive operations
- Custodial vs non-custodial wallet interactions
- Real-time strategy (WebSocket vs polling vs SSE)

For each decision, include:
1. The question: "Should X be done as A or B?"
2. The recommendation: "Recommended: A because..."
3. The consequence of delay: "If not decided by [date], [downstream task] will need to be reworked"
