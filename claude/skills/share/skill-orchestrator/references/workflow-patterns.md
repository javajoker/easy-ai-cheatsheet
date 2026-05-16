# Workflow Patterns

Concrete examples of multi-skill chains, organized by the four shapes from SKILL.md. Use these as reference when planning a workflow — adapt rather than copy.

These patterns assume a typical claude.ai or Claude Code environment with the standard public skills loaded (docx, pdf, pptx, xlsx, pdf-reading, file-reading, frontend-design, project-*, task-breakdown, skill-creator). Substitute equivalents when the available skill set differs.

---

## Shape 1 — Extract → Transform → Produce

The most common shape. A file or content source comes in, gets restructured or summarized, and a new file or artifact comes out.

### PDF → editable Word document

**User signal:** "Convert this PDF to Word", "I need to edit this contract"
**Chain:** `pdf-reading` → analyze structure → `docx`
**Inputs needed upfront:**
- Preserve images? (yes / drop / replace with descriptions)
- Match original formatting or clean to plain prose?

### PDF / docx → slide deck

**User signal:** "Make a presentation from this report", "Pitch deck from this whitepaper"
**Chain:** `pdf-reading` or `file-reading` → outline key points → `pptx`
**Inputs needed upfront:**
- Audience (technical / executive / general)
- Slide count target (5–10 / 10–20 / 20+)
- Speaker notes? (yes / no)

### xlsx → narrative report

**User signal:** "Write a report on this sales data", "Explain what this spreadsheet shows"
**Chain:** `xlsx` (read) → data analysis → `docx` or markdown
**Inputs needed upfront:**
- Audience (analyst / exec summary / general)
- Include charts? (embed in doc / separate / no)
- Key dimensions to focus on (let user pick from the sheet's columns)

### Meeting notes → action plan + calendar

**User signal:** "Turn these notes into a follow-up plan"
**Chain:** `file-reading` → extract action items → `docx` (plan) → optionally calendar tool for events
**Inputs needed upfront:**
- Owner names visible in the notes, or assume you'll list "TBD"?
- Email follow-up needed, or just the document?

### Scanned PDF → searchable PDF

**User signal:** "I have a scanned contract, make it searchable"
**Chain:** `pdf-reading` (with OCR) → `pdf` (rebuild with text layer)
**Inputs needed upfront:**
- Language(s) in the document
- Just OCR, or also redact/annotate?

---

## Shape 2 — Idea → Spec → Build

Used when the user wants to go from a project concept to working code. The chain is longer (4–6 steps) and the input-hint phase matters most here, because asking 5 questions later is far worse than asking 3 upfront.

### Full project scaffold (frontend + backend)

**User signal:** "Build me an app for X", "I want to make a SaaS for Y"
**Chain:**
1. `project-prototype` → clickable HTML/React prototype with mock data
2. `project-docs` → PRD + UI/UX spec + tech design from the prototype
3. `task-breakdown` → AGENT.md, dependency graph, per-component task files
4. `project-frontend` → production React app wired to the task breakdown
5. `project-backend-python` OR `project-backend-node` OR `project-backend-go` → matching backend

**Inputs needed upfront (cap at 3):**
- Backend stack (Python / Node / Go) — affects step 5
- Scope (prototype only / through specs / through task breakdown / full build)
- i18n target (English only / English + Traditional Chinese / other)

**Notes:**
- For scope = "prototype only", stop after step 1. The user can come back later for the rest.
- For scope = "through specs", stop after step 2.
- Always check whether the user already has a prototype attached — if so, skip step 1.

### Spec-only deliverable

**User signal:** "Write a PRD for my idea", "Just give me the spec"
**Chain:** `project-prototype` (if no prototype given) → `project-docs`
**Inputs needed upfront:**
- Have a prototype/mockup already, or generate one first?
- Target audience for the docs (engineers / mixed team / investors)

### Demo / mockup for stakeholder review

**User signal:** "Make a demo to show stakeholders", "Click-through for user testing"
**Chain:** `project-docs` (if no docs given) → `project-mockup-app`
**Inputs needed upfront:**
- Have docs already, or build them first from a description?
- Specific user flows to emphasize?

---

## Shape 3 — Single deliverable with prep

One artifact at the end, but it needs structured preparation. The chain is short (1–2 skills + reasoning) but the input-hint phase is still worth running because the prep decisions shape the output significantly.

### Professional report (no source data)

**User signal:** "Write a Word doc on topic X for client Y"
**Chain:** research/reasoning → `docx`
**Inputs needed upfront:**
- Length (one-pager / 5 pages / long-form)
- Tone (formal / consultative / casual)
- Sections required, or let the structure emerge?

### Financial model from a brief

**User signal:** "Build a 3-year financial model for this startup idea"
**Chain:** clarify assumptions → `xlsx`
**Inputs needed upfront:**
- Revenue model (subscription / transaction / hybrid)
- Time horizon (3yr / 5yr)
- Currency and base year

### Pitch deck from a brief (no source doc)

**User signal:** "Make me a pitch deck for [idea]"
**Chain:** outline reasoning → `pptx`
**Inputs needed upfront:**
- Audience (seed VCs / customers / internal)
- Slide count (10 / 15 / 20)
- Existing brand colors/style guide attached?

### Filled PDF form

**User signal:** "Fill out this form for me"
**Chain:** `pdf-reading` (to see fields) → `pdf` (to fill)
**Inputs needed upfront:**
- Field values (collect via consolidated intake — never field-by-field)
- Signature handling (skip / placeholder / leave for user)

---

## Shape 4 — Skill about a skill

When the user is building, improving, or testing a skill itself.

### Create a new skill

**User signal:** "Make me a skill for X", "Turn this workflow into a skill"
**Chain:** `skill-creator` (handles the whole loop — draft, eval, iterate, package)
**Inputs needed upfront:**
- What should the skill do, in one sentence?
- When should it trigger (example user phrases)?
- Test cases to verify it works, or skip evals?

This is usually a single-skill task — `skill-creator` is the entire workflow. No orchestration needed unless the new skill being created is itself an orchestrator (in which case, this very file might be a useful reference).

### Improve an existing skill

**User signal:** "Make my X skill better", "Optimize this skill's triggering"
**Chain:** `skill-creator` (with the existing skill as input)
**Inputs needed upfront:**
- Path to the existing skill, or upload?
- What's wrong (specific failure mode) or just general polish?

---

## Shape 5 — Agent group

When the request matches a named **agent**'s `fires_on` triggers, the agent's own workflow *is* the chain — don't re-plan it at the skill level. When the request matches *multiple* agents, engage `scenario-strategist` to form the group.

These patterns assume the agents from `agents/CHECKLIST.md`. Read it fresh; the catalog evolves.

### Single-agent — lifecycle-pilot

**User signal:** "Take this idea all the way to launch", "I want to build X and launch it", "we need GTM for the MVP"
**Routing:** `lifecycle-pilot` agent (single match)
**Chain:** the agent's 7-phase arc (prototype → docs → task-breakdown → frontend+backend → launch-readiness → GTM → public launch)
**Inputs needed upfront (cap at 3 across the whole arc):**
- Backend language (Node / Go / Python)
- Launch posture (closed beta / open beta / public)
- Compliance regime (none / GDPR / HIPAA / SOC2)

See [Scenario M](../../../../SCENARIOS.md#scenario-m--taking-an-idea-all-the-way-to-launch-lifecycle-pilot) for the playbook.

### Single-agent — architecture-shepherd

**User signal:** "Plan our re-architecture", "should we split the monolith", "upgrade Postgres major", "deprecate v1 of the API"
**Routing:** `architecture-shepherd` agent
**Chain:** assessment → decision → migration plan (or dependency-upgrade variant) → rollout strategy → breaking-change comms
**Inputs needed upfront:**
- Triggering concern (perf / cost / team / compliance / roadmap)
- Decision authority
- Time available for assessment

See [Scenario P](../../../../SCENARIOS.md#scenario-p--architecture-upgrade-architecture-shepherd).

### Single-agent — devops-engineer

**User signal:** "Set up CI/CD", "add observability", "write runbooks", "harden for prod", "rotate secrets"
**Routing:** `devops-engineer` agent (engaged workstreams only — not all 7 at once)
**Chain:** the requested workstream(s) from {ci-cd / iac / observability / incident-runbook / release-management / security-hardening / secrets}
**Inputs needed upfront:**
- Which workstream(s)
- Platform / cloud / vault choices
- Approval chain for prod

See [Scenario O](../../../../SCENARIOS.md#scenario-o--operational-baseline--ongoing-ops-devops-engineer).

### Single-agent — knowledge-curator

**User signal:** "Build the enterprise KB", "merge the project KBs", "set up RAG over our docs", "set up access control on the KB"
**Routing:** `knowledge-curator` agent
**Chain:** architecture → merge → refresh-policy → search-index → access-control
**Inputs needed upfront:**
- Compliance regime (drives `regulated` classification rules)
- Vector DB + embedding model preferences
- Source inventory (which project KBs / books / memory)

See [Scenario Q](../../../../SCENARIOS.md#scenario-q--enterprise-knowledge-base-knowledge-curator).

### Multi-agent — re-architecture + relaunch

**User signal:** "Re-architect and relaunch as v2", "migrate to k8s during the v2 launch window"
**Routing:** **multiple agents match → engage `scenario-strategist`** (do NOT route to one of the candidate agents alone)
**Chain:**
1. `scenario-strategist`'s four-phase arc (analysis → workflow → group → handoffs) forms the group.
2. Group typically: `architecture-shepherd` (lead, architecture phases) → `lifecycle-pilot` (lead, relaunch phases) → `devops-engineer` (supports both throughout).
3. Strategist remains conductor across phase boundaries.

**Inputs needed upfront (cap at 3, gathered by strategist's Phase 1):**
- Time horizon for the combined work
- Reversibility tolerance
- Customer impact tolerance during the transition

See [Scenario R](../../../../SCENARIOS.md#scenario-r--re-architecture--relaunch-multi-agent).

### Multi-agent — enterprise KB + AI feature launch

**User signal:** "Build the enterprise KB and ship the AI features that depend on it", "we need RAG for the new feature, but also the KB underneath doesn't exist yet"
**Routing:** **multiple agents match → engage `scenario-strategist`**
**Chain:**
1. `scenario-strategist` forms the group.
2. Group: `knowledge-curator` (KB lead) + `lifecycle-pilot` (AI feature lead) + `devops-engineer` (vector DB hosting + AI feature CI/CD).
3. The KB ↔ AI feature handoff is a contracted artifact (retrieval client API) under `agent-handoff-protocol`.

See [Scenario S](../../../../SCENARIOS.md#scenario-s--enterprise-kb--ai-feature-launch-multi-agent).

### Agent routing — decision rules summary

| Match | Routing |
|---|---|
| 0 agents | Fall back to Shapes 1–4 (skill-level chains) |
| 1 agent | Invoke that agent by name; its AGENT.md is the workflow |
| ≥2 agents | Engage `scenario-strategist`; it forms the group |
| Ambiguous | Read the candidate agents' `fires_on` triggers; pick the one whose triggers most specifically match; if tied, engage strategist |

**Hardcoding is forbidden.** Always read `agents/CHECKLIST.md` fresh — the catalog evolves; what's stub today may be shipped tomorrow.

---

## Composing shapes

Shapes can nest. A user request like "Build me an app to manage book reviews, then write a blog post announcing it" combines Shape 2 (Idea → Spec → Build) with Shape 3 (single deliverable with prep). The orchestrator's job is to surface this combination in the plan so the user sees the full arc and approves before execution.

Shape 5 (Agent group) commonly composes *upward* of the others — the agent's workflow itself uses Shapes 1–4 internally. For example, `lifecycle-pilot`'s Phase 2 (specification) is a Shape 2 chain run inside Phase 2 of the agent's larger arc. Don't double-report shapes in the plan; report at the *outermost* shape and let the agent's AGENT.md describe its internals.

When composing, keep the consolidated intake tight — combine questions across shapes where they share a decision (e.g., the language and tone for both the app's UI and the blog post can be one question if they should match).

---

## Anti-patterns

- **Stretching one shape across the whole chain.** Real workflows often mix shapes. Don't force everything into "Extract → Transform → Produce" if there's a clear design step that belongs in Shape 2.
- **Adding cosmetic steps.** "Then we'll review the output" is not a step. Steps must use a tool or skill.
- **Treating a single skill's internal stages as separate steps.** `project-docs` produces three documents internally — that's one step, not three. Report it as one step in the plan.
