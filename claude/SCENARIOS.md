# SCENARIOS — workflow playbooks

Step-by-step playbooks for common situations, each with a checklist of the
skills involved. If a skill is **marked missing**, the framework does not yet
ship one and you'll want to fall back to a manual procedure.

For the everyday mechanics, see [HOWTO.md](HOWTO.md). For the underlying
audit and design rationale, see the [appendix at the end](#appendix-checklists).

---

## Scenario A — Onboarding an existing project

**Goal.** Bring an existing codebase under the framework so future sessions
load relevant context automatically.

### When this fits

- First time opening Claude Code in a project repository.
- Project hasn't been touched in months and you want a refresh.
- Project was developed without this framework and you're adopting it now.

### Procedure

1. Open Claude Code in the project's root directory.
2. Say: *"Onboard this project."*
3. Answer the 3–7 targeted questions Claude asks.
4. Review the generated `INSTRUCTIONS/projects/<slug>/` files; correct
   anything you spot wrong.
5. (Optional) Run `project-knowledge-base` next for a deeper conceptual
   graph.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `skill-orchestrator` | shipped | Picks the chain, asks consolidated questions. |
| `project-onboarding` | shipped | Reads the codebase, gathers facts, seeds memory. |
| `create-project-instruction` | shipped | Producer for `INSTRUCTIONS/projects/<slug>/` (invoked by `project-onboarding`'s Phase 4). |
| `cognitive-alignment` | shipped | Runs alongside to capture load-bearing terms. |
| `memory-ontology` | shipped | Seeds durable memory entries at the end. |
| `compact-ritual` | shipped | Available if context fills during the onboarding pass. |
| `project-knowledge-base` | shipped | Optional follow-on for conceptual depth. |

### Manual fallback (if the skill isn't available)

1. Copy `INSTRUCTIONS/templates/project-context.md` and
   `INSTRUCTIONS/templates/repository-structure.md` into
   `INSTRUCTIONS/projects/<slug>/`.
2. Fill in `{placeholders}` by reading the codebase.
3. Reference both files from the project's `CLAUDE.md`.

If you have the facts gathered but want help just writing the files, invoke
`create-project-instruction` standalone in Mode A — it will read the inputs
you provide and produce the same artifacts as the onboarding pass without
the surrounding scan + memory-seed phases.

---

## Scenario B — Starting a new project from an idea

**Goal.** Go from "I'm thinking about building X" to a runnable production
codebase using a structured, repeatable workflow.

### When this fits

- You have a concept but no spec, no prototype, no docs yet.
- You want consistent docs + tasks + code across frontend and backend.
- The project is greenfield.

### Procedure

The full linear chain. See `skills/ideas/WORKFLOW.md` for the canonical
walkthrough.

1. *"I want to build [your idea in plain language]."* → `project-prototype`
   produces a clickable React mockup.
2. *"Now create the formal docs."* → `project-docs` asks for the backend
   language choice and generates PRD + UI/UX spec + tech design.
3. *"Set up the project INSTRUCTIONS from these docs."* →
   `create-project-instruction` (Mode C — PRD + tech design) writes
   `INSTRUCTIONS/projects/<slug>/project-context.md` and
   `repository-structure.md` so downstream skills + future sessions have a
   stable identity to reference.
4. (Optional) *"Build a quick demo first."* → `project-mockup-app` produces
   a runnable mock-data demo.
5. *"Break this into AI-executable tasks."* → `task-breakdown` produces
   the task plan.
6. In parallel:
   - *"Build the production frontend."* → `project-frontend`.
   - *"Build the production backend."* → `project-backend-{node|go|python}`
     based on what `project-docs` chose.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `skill-orchestrator` | shipped | Plans the chain, asks intake questions upfront. |
| `project-prototype` | shipped | Idea → clickable UI prototype. |
| `project-docs` | shipped | Prototype + idea → PRD, UI/UX, tech design. Asks backend language. |
| `create-project-instruction` | shipped | Mode C: tech design → INSTRUCTIONS/projects/<slug>/. |
| `project-mockup-app` | shipped | (Optional) Docs → runnable mock app for validation. |
| `task-breakdown` | shipped | Docs → AI-executable task plan. |
| `project-frontend` | shipped | Docs + tasks → production React app. |
| `project-backend-node` | shipped | Docs + tasks → Fastify + Prisma + BullMQ. |
| `project-backend-go` | shipped | Docs + tasks → Gin + GORM + asynq. |
| `project-backend-python` | shipped | Docs + tasks → FastAPI + SQLAlchemy + Celery. |
| `cognitive-alignment` | shipped | Captures domain terms throughout. |
| `memory-ontology` | shipped | Records the project's identity and decisions. |
| `compact-ritual` | shipped | Likely to fire mid-chain on large projects. |

### Manual fallback

You can run any single skill in isolation by naming it. Skipping a phase
means you'll need to provide that phase's expected output as input to the
next.

---

## Scenario C — Generating a project knowledge base

**Goal.** Build a conceptual knowledge graph of an existing project so
that future work has a stable map of features, modules, abstractions, and
domain terminology.

### When this fits

- The project has been onboarded but lacks a conceptual model.
- New engineers (or AI agents) are losing time learning the codebase
  shape.
- You want a navigable knowledge base in `docs/knowledge-base/` plus a
  machine-readable relation manifest.

### Procedure

1. Make sure `project-onboarding` has already run for this project.
2. Say: *"Build a knowledge base for this project."*
3. Confirm the proposed entity list (typically 20–80 entities).
4. Review the generated `docs/knowledge-base/` tree.
5. Iterate on entities that are mis-scoped or missing.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `project-knowledge-base` | shipped | Generates the entity files, relation manifest, terminology, index. |
| `cognitive-alignment` | shipped | Seeds the terminology section from prior library entries. |
| `memory-ontology` | shipped | Hydrates from `type: project` memories; promotes new `type: decision` findings back. |
| `project-onboarding` | shipped | Should be run first; provides the shape-level context. |
| `book-to-knowledge-graph` | shipped | Sibling — use this one for long-form prose, not code. |

### Output

- `docs/knowledge-base/INDEX.md`
- `docs/knowledge-base/entities/*.md` (one per entity)
- `docs/knowledge-base/relations.md`
- `docs/knowledge-base/terminology.md`
- New `type: project` memory entries for any decisions surfaced.

---

## Scenario D — Building a knowledge graph from a long book

**Goal.** Process a very long text (>200K tokens, often millions) into a
queryable ontology and answer questions against it.

### When this fits

- You have a book, multi-volume work, dense academic text, scripture, or
  long transcript.
- You want to query character relationships, plot events, themes, etc.
- The text is too big to fit in context.

### Procedure

1. Place the book at a known path on disk.
2. Say: *"Build a knowledge graph from this book."*
3. The `book-to-knowledge-graph` skill orchestrates the rest:
   - `book-chunking` produces semantically coherent chunks.
   - `ontology-extraction` runs per chunk (LLM-heavy stage).
   - `ontology-merging` consolidates into a canonical book-level ontology.
   - `ontology-storage` exports to JSON / Turtle / GraphML / Markdown.
   - `ontology-qa` answers your questions, citing entities.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `book-to-knowledge-graph` | shipped | Pipeline orchestrator. |
| `book-chunking` | shipped | Splits the input. |
| `ontology-extraction` | shipped | Per-chunk entity/relation/event extraction. |
| `ontology-merging` | shipped | Deduplicates and unifies. |
| `ontology-storage` | shipped | Exports to multiple formats. |
| `ontology-qa` | shipped | Grounded question answering. |

### Manual fallback

Each stage's `scripts/` directory has runnable Python. You can chain them
manually via the commands in `skills/knowledge-graph/README.md`.

---

## Scenario E — Multi-step task that needs orchestration

**Goal.** A user request implicitly needs more than one skill chained
together — extract content from a file, transform it, produce a new
artifact.

### When this fits

- "Convert this PDF to a Word doc."
- "Turn this whitepaper into a pitch deck."
- "Read the meeting notes and make me a project plan."
- "Take this spreadsheet and write a narrative report."

### Procedure

1. Make the request in plain language.
2. The `skill-orchestrator` skill fires and:
   - Reads the available skill catalog.
   - Plans the workflow (2–5 steps typically).
   - Surfaces the plan and asks for any inputs upfront (cap at 3
     questions).
3. After you confirm, the orchestrator executes the chain.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `skill-orchestrator` | shipped | Picks the chain, consolidates the intake. |
| Source-reading skill | varies | E.g. `pdf-reading`, `xlsx`, `file-reading` — depends on input. |
| Transformation logic | inline | Often just reasoning between steps, not a skill. |
| Output skill | varies | E.g. `docx`, `pptx`, `xlsx` — depends on requested artifact. |
| `cognitive-alignment` | shipped | Surfaces any ambiguous terms in the request. |

Skills like `pdf-reading`, `docx`, `pptx`, `xlsx` are typically provided
by your Claude Code environment as built-in skills; this framework does
not duplicate them.

---

## Scenario F — Cross-session continuity / handing off to future Claude

**Goal.** End a long session so that the next session (or a different team
member's session) can pick up cleanly without re-explaining everything.

### When this fits

- Long session winding down.
- Project paused for days or weeks.
- Handing the project to a new contributor.

### Procedure

1. Run the `compact-ritual` pre-procedure even if you're not running
   `/compact`. It's a save point.
2. Promote any conversation-scoped library/profile entries that should
   outlive this session to MEMORY via `memory-ontology`.
3. Write a session-notes file (see
   `INSTRUCTIONS/workflows/task-management.md`):
   `docs/memory/<YYYY-MM-DD>-<short-slug>.md` describing what shipped,
   what's in flight, and what's blocked.
4. Update `task_plan.md`, `progress.md`, `findings.md` if the project
   maintains them.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `compact-ritual` | shipped | Surfaces the three durable artifacts as a snapshot. |
| `memory-ontology` | shipped | Promotes library entries to memory; runs an audit. |
| `cognitive-alignment` | shipped | Confirms any uncertain library entries before snapshot. |

---

## Scenario G — Migrating a project's language stack

**Goal.** Switch a project's backend language (e.g. Node.js to Go) while
keeping the same docs and task plan.

### When this fits

- Performance requirements changed and the original language can't meet them.
- Team capability shifted (new engineers, different expertise).
- Strategic alignment with an organization-wide stack choice.

### Procedure

1. Re-run `project-docs` and choose the new language during the language-
   selection question. Only `TECH_DESIGN.md` and the recommended backend
   skill change; `PRD.md` and `UIUX_SPEC.md` are reused.
2. Optionally re-run `task-breakdown` (most tasks stay; backend task IDs
   may shift slightly).
3. Run the new backend skill (`project-backend-go` etc.) against the
   updated docs.
4. Update `INSTRUCTIONS/projects/<slug>/project-context.md` to reflect the
   new stack.
5. Update memory entries: supersede the old `project_<slug>_stack.md`
   memory with the new one.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `project-docs` | shipped | Re-generate the tech design with the new language. |
| `task-breakdown` | shipped | (Optional) refresh the task plan. |
| `project-backend-{node\|go\|python}` | shipped | Generate the new backend. |
| `memory-ontology` | shipped | Supersede the old stack memory. |
| `cognitive-alignment` | shipped | Surface any term meanings that shifted. |

---

## Scenario H — Refactoring with the framework

**Goal.** Plan and execute a non-trivial refactor with the framework's
support, not against it.

### When this fits

- Cross-cutting refactor (rename a concept, restructure a module, change a
  pattern across many files).
- Architectural change that affects the knowledge base.

### Procedure

1. Run `project-knowledge-base` first if it hasn't been run, or
   refresh the relevant entities if it has.
2. Make sure cognitive-library entries cover the load-bearing terms in
   the refactor; if not, surface and confirm them.
3. Plan the refactor in Plan Mode. List files to touch, signature changes,
   tests to update.
4. Execute incrementally; verify each step.
5. After the refactor lands, update affected knowledge-base entities and
   bump their `updated:` date.
6. If the refactor introduced an architectural decision worth recording,
   add a `decision` entity and a `type: project` memory.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `cognitive-alignment` | shipped | Lock down load-bearing terms before changing them. |
| `project-knowledge-base` | shipped | Update the conceptual model. |
| `memory-ontology` | shipped | Record the architectural decision. |
| Language-specific dev skills (`dev-go/*`, `dev-node/*`, `dev-python/*`, `dev-java/*`) | shipped | Per-language quality guidance during the refactor. |
| `compact-ritual` | shipped | Available if the refactor session runs long. |

---

## Scenario I — Day-to-day feature work in an onboarded project

**Goal.** Implement a new feature or fix a bug in a project that's already
been onboarded.

### When this fits

- Routine work in a project with existing INSTRUCTIONS, knowledge base,
  and task plan.

### Procedure

1. Open Claude Code in the project root. `INSTRUCTIONS/projects/<slug>/`
   loads automatically via the project's `CLAUDE.md`.
2. State the feature or bug. Include a verifiable success criterion.
3. Plan in Plan Mode for anything non-trivial.
4. Implement against the plan; verify each step with the project's
   test/lint/build commands (declared in
   `INSTRUCTIONS/projects/<slug>/project-context.md`).
5. If the feature is large enough to be a knowledge-base entity, add or
   update the relevant entity.
6. Commit following the project's conventions
   (`INSTRUCTIONS/workflows/git-workflow.md`).

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `skill-orchestrator` | shipped | Picks the chain; for most day-to-day work, single-skill workflows skip it. |
| `cognitive-alignment` | shipped | Always running in the background. |
| Language-specific dev skills | shipped | E.g. for Go: `go-style-core`, `go-naming`, `go-testing`, `go-error-handling`. Node.js: `node-*`. Python: `py-*`. Java: `java-*`. |
| `doc-markdown-standards` | shipped | If the project uses Obsidian-style docs and you're updating them. |
| `memory-ontology` | shipped | If any decision worth remembering surfaces. |

---

## Scenario J — Reviewing a pull request

**Goal.** Review a PR systematically.

### When this fits

- You're the PR author wanting an independent review.
- You're the PR reviewer using Claude to surface issues.

### Procedure

1. In a clean session (`/clear` first if needed), say: *"Review this PR:
   <PR URL or branch name>."*
2. Claude pulls the diff and runs through:
   - Functional correctness — does it do what the description says?
   - Style alignment — matches project conventions?
   - Test coverage — new behaviour covered?
   - Security — any new attack surface?
   - Operational concerns — observability, migrations, backwards
     compatibility?
3. Claude produces a structured review with specific line references.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `go-code-review` / `node-code-review` / `py-code-review` / `java-code-review` (or language equivalent) | shipped for Go, Node.js, Python, Java | Language-specific review checks. |
| `cognitive-alignment` | shipped | If review surfaces ambiguous terms with the author. |
| Project knowledge base | data, not skill | Entities referenced by the changed code. |

The framework currently ships `go-code-review` for Go projects,
`node-code-review` for Node.js / TypeScript projects, `py-code-review`
for Python projects, and `java-code-review` for Java projects.
**Other-language equivalents are not yet skill-packaged** — for Rust /
Ruby / Kotlin reviews, fall back to running the project's own lint/test
commands and using `cognitive-alignment` + general principles from
`INSTRUCTIONS/`.

---

## Scenario K — Auditing requirements and producing scenario checklists

**Goal.** Two related needs share the same mechanic: (1) verify that a
numbered list of user requirements has actually been satisfied, and (2)
produce the "Skills involved" checklist for a new workflow. Both run
against the catalog and the current state of the repository; both emit
structured tables.

### When this fits

- The user issued a numbered or bulleted multi-point request and you need
  to surface what was delivered vs what was missed before declaring done.
- A long workflow is reaching its natural end and you want an auditable
  record of completion.
- You're authoring a new scenario in `SCENARIOS.md` and need the
  participating-skills table.
- The user asks "what would this take?" or "is this complete?" and the
  most honest answer is a per-row status with evidence.
- A handoff to another agent or future session needs an evidence trail.

### Procedure — for requirement auditing

1. *"Audit my requirements list against what was actually delivered."* →
   `requirement-audit` reads the verbatim requirements and the current
   repo state.
2. For each requirement, the skill emits a row with status
   (`✅ PASS` / `⚠ PARTIAL` / `❌ FAIL` / `➖ N/A`) and pointer-style
   evidence (file paths with line ranges, command outputs, cross-refs).
3. Optional: save the audit as `docs/audits/<YYYY-MM-DD>-<topic>-audit.md`
   and write a `type: project` memory entry so the next session knows
   the audit exists.

### Procedure — for scenario checklisting

1. *"What's the checklist for [new workflow]?"* → `scenario-checklist`
   anchors the workflow, reads the catalog, classifies which skills
   participate.
2. The skill emits the `### Skills involved — checklist` table in the
   canonical format (Skill / Status / Role columns; status from the
   fixed vocabulary).
3. If the table includes any `missing` rows, the recommended next step
   surfaces the most valuable gap to fill.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `skill-orchestrator` | shipped | Plans the audit / checklist pass; consolidates intake. |
| `cognitive-alignment` | shipped | Locks the meaning of ambiguous requirement terms before audit. |
| `requirement-audit` | shipped | Verifies a numbered requirements list; emits PASS/PARTIAL/FAIL per row. |
| `scenario-checklist` | shipped | Produces the "Skills involved" checklist for a workflow. |
| `memory-ontology` | shipped | Persists audit findings worth carrying forward. |
| `compact-ritual` | shipped | Available if the audit happens at the end of a long session. |

Gaps: 0. Recommended next step: invoke `requirement-audit` on your most
recent multi-point request; if the audit surfaces FAIL rows, either fill
the gaps or revise the requirements before declaring done.

### Manual fallback

Without the two new skills:

1. Copy `skills/share/requirement-audit/references/audit-template.md`
   into a working file.
2. Number the requirements verbatim; do not paraphrase.
3. Fill in status and evidence per row, preferring pointer-style evidence
   (file path + line range) over prose.
4. End with a summary line: `N PASS · M PARTIAL · K FAIL · L N/A`.

The format itself is the deliverable — the skill mostly automates the
discipline of *not skipping rows*.

---

## Scenario L — Evolving a skill through live project use

**Goal.** Let the framework sharpen itself based on what actually
happens during real project work — without silent file rewrites. The
mechanic is observe → propose → merge, with a human checkpoint at the
merge step.

### When this fits

- You (or Claude) noticed during a workflow that a skill's description
  didn't match how you phrased an intent.
- A skill's procedure had a gap that became obvious in practice.
- An anti-pattern just played out that wasn't called out in the skill.
- A user question hit references that didn't cover it.
- Two skills clearly need to know about each other and don't.
- Several project-specific overrides for the same skill have
  accumulated across projects and the pattern is worth promoting to the
  canonical.

### Procedure — capture during live work

1. When you notice an evolution candidate (or Claude proactively does
   in its orchestrator Phase 4 evolution-watch), say:
   *"Capture that as an evolution proposal."*
2. `skill-evolution` writes a structured proposal under
   `docs/skill-evolution/<YYYY-MM-DD>-<skill>-<topic>.md` with
   observed / current / proposed / rationale / risks.
3. The proposal sits as `status: proposed` until reviewed.
4. (Optional) A `type: feedback` memory entry points at the proposal so
   future sessions see it before any merge.

### Procedure — merge when ready

1. *"Run skill-merge on the pending proposals."*
2. `skill-merge` gathers proposals, classifies by target, detects
   conflicts.
3. Conflicts stop the merge and surface resolution options (pick one,
   synthesize, or sequence).
4. The skill previews the full unified diff for every target file.
5. On approval, applies the change, bumps the target's version, updates
   `updated:`, marks proposals `merged`.
6. Cross-checks downstream artifacts: `skill-orchestrator`,
   `references/workflow-patterns.md`, this `SCENARIOS.md`,
   `README.md` counts, companion sections in sibling skills, any
   redundant overrides.
7. Writes a feedback memory so the next session knows the catalog
   shifted.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `skill-orchestrator` | shipped | Watches for evolution candidates during Phase 4 execution; surfaces them in the handoff. |
| `cognitive-alignment` | shipped | Locks the meaning of the observation before the proposal is written. |
| `skill-evolution` | shipped | Captures the candidate as a structured proposal; never modifies the target. |
| `skill-merge` | shipped | Applies proposals after explicit diff approval; runs downstream consistency checks. |
| `memory-ontology` | shipped | Persists the proposal and the merge as session-spanning feedback entries. |
| `requirement-audit` | shipped | Verifies post-merge that the change actually landed everywhere the proposal claimed. |
| `compact-ritual` | shipped | Available if the evolution session is long enough to risk `/compact`. |

Gaps: 0. Recommended next step: capture two or three evolution candidates
during your next real project workflow, then run `skill-merge` to feel
the loop end-to-end before relying on it for substantive changes.

### Manual fallback

Without the two skills:

1. Write a markdown file under `docs/skill-evolution/` with the same
   template (see `skills/share/skill-evolution/references/proposal-template.md`).
2. Open a small PR that applies the change to the target skill, bumps
   its version, and updates downstream references that mention the
   target.
3. Reference the proposal file in the PR description so the rationale
   is preserved.

The skills mostly automate the discipline of *capturing-without-applying*
and *applying-with-conflict-detection*; the underlying mechanism is
just disciplined markdown editing.

### What this scenario does NOT cover

- **Bug fixes.** A skill that produces wrong output is a bug; fix it
  with a normal commit, not the evolution loop.
- **Wholesale rewrites.** A new skill is not an evolution. Use
  `skill-creator` (when present) or write a fresh SKILL.md.
- **Auto-application.** The diff preview is non-negotiable. If you want
  faster turnaround, batch many small proposals and review them
  together rather than skipping the review.

---

## Scenario M — Taking an idea all the way to launch (lifecycle-pilot)

**Goal.** Drive a product from concept through production code to
public launch as one coordinated arc. The full eight-skill linear
chain plus the GTM tail (launch readiness, positioning, pricing,
marketing site, beta program, analytics).

### When this fits

- *"I want to build X and launch it."* (not just "build me a
  prototype").
- You have an MVP codebase and now need launch readiness + GTM
  before going public.
- The product needs the seam between *"code is done"* and *"product
  is launched"* held by a single owner.

### Procedure

The full seven-phase arc owned by [`lifecycle-pilot`](agents/lifecycle-pilot/AGENT.md):

1. **Ideation** → `project-prototype` produces clickable React mock.
2. **Specification** → `project-docs` (asks backend language) +
   `create-project-instruction` Mode C.
3. **Validation** (optional) → `project-mockup-app`.
4. **Planning** → `task-breakdown`.
5. **Production code** (parallel) → `project-frontend` +
   `project-backend-{node|go|python}`.
6. **Launch readiness** → `gtm-launch-readiness` audit (FAIL rows
   block launch).
7. **Go-to-market** (parallel) → `gtm-positioning` →
   `gtm-pricing-model` → `gtm-marketing-site`; `gtm-beta-program`;
   `gtm-analytics-instrumentation`.

Hand-off agents engage as needed: `devops-engineer` from Phase 5 on;
`architecture-shepherd` if Phase 2 surfaces a non-trivial
architectural decision; `knowledge-curator` if Phase 8 publishes a
public KB.

### Skills involved — checklist

| Skill / Agent | Status | Role |
|---|---|---|
| `lifecycle-pilot` (agent) | shipped | Conductor across all phases. |
| `project-prototype`, `project-docs`, `project-mockup-app`, `task-breakdown`, `project-frontend`, `project-backend-{node,go,python}`, `create-project-instruction` | shipped | Phases 1–5 producers. |
| `gtm-launch-readiness` | shipped | Phase 6 — opinionated pre-launch audit. |
| `gtm-positioning`, `gtm-pricing-model`, `gtm-marketing-site`, `gtm-beta-program`, `gtm-analytics-instrumentation` | shipped | Phase 7 — GTM artifacts. |
| `requirement-audit` | shipped | Gates Phases 6 + 8. |
| `cognitive-alignment`, `memory-ontology`, `compact-ritual` | shipped | Cross-phase. |
| `devops-engineer`, `architecture-shepherd`, `knowledge-curator` (agents) | shipped | Hand-offs per phase. |

Gaps: 0. Recommended next step: invoke the agent by name —
*"Use the lifecycle-pilot agent to take this idea through to
launch."*

---

## Scenario N — Multi-agent coordination (scenario-strategist)

**Goal.** A complex situation needs more than one agent — analyse
the scenario, design the workflow, form the right agent group,
contract the handoffs.

### When this fits

- *"We're going to re-architect the platform and re-launch."*
- *"Migrate to Kubernetes while we ship v2."*
- *"Build the enterprise KB and use it to power the AI features
  we promised customers."*
- A scenario that needs ≥2 agents in coordinated motion.

### Procedure

The four-phase strategist arc owned by [`scenario-strategist`](agents/scenario-strategist/AGENT.md):

1. **Analysis** → `scenario-analysis` locks the brief (goal /
   scope / constraints / success criteria) and produces an
   options analysis (2–4 weighted options + recommendation).
2. **Workflow design** → `workflow-design` produces 3–7 phases
   with deliverables, gates, critical path, parallelism, sync
   points.
3. **Group formation** → `agent-group-formation` reads
   `agents/CHECKLIST.md` fresh; one lead per phase; named
   conductor; missing-role gaps surfaced.
4. **Handoff protocols** → `agent-handoff-protocol` fills the
   six-field contract per transition (producer / receiver /
   artifact / acceptance / rejection / escalation).

The conductor (often the strategist itself) tracks the workflow
across phases and enforces the handoff contracts.

### Skills involved — checklist

| Skill / Agent | Status | Role |
|---|---|---|
| `scenario-strategist` (agent) | shipped | Conductor for the four-phase strategist arc. |
| `scenario-analysis` | shipped | Phase 1 — brief + options + recommendation. |
| `workflow-design` | shipped | Phase 2 — agent-level phases + gates. |
| `agent-group-formation` | shipped | Phase 3 — staffing. |
| `agent-handoff-protocol` | shipped | Phase 4 — handoff contracts. |
| `cognitive-alignment` | shipped | Non-negotiable in Phase 1. |
| `memory-ontology` | shipped | Persists brief + decision + group. |
| `requirement-audit` | shipped | Verifies workflow deliverables at end. |
| `skill-orchestrator` | shipped | Used inside phases for skill-level chains. |

Gaps: 0. Recommended next step: *"Use the scenario-strategist
agent to design how we'll handle <complex situation>."*

---

## Scenario O — Operational baseline + ongoing ops (devops-engineer)

**Goal.** Establish or extend the operational stack — CI/CD, IaC,
observability, runbooks, releases, security, secrets — for a
project. Seven concurrent workstreams, engaged à la carte; not all
seven at once.

### When this fits

- New project preparing for prod — needs the full kit.
- Existing project missing one or more workstreams (no
  observability; ad-hoc deploys; no runbooks).
- Post-incident — extend an existing workstream (e.g. tighten
  alerts or add a new runbook class).

### Procedure

Engage the workstreams the project needs from [`devops-engineer`](agents/devops-engineer/AGENT.md):

1. **CI/CD** → `devops-ci-cd` — on-PR + on-merge + on-approval
   pipeline; per-platform template; cache discipline; required
   checks; vault integration.
2. **IaC** → `devops-iac` — Terraform-default; per-cloud baseline;
   plan-not-apply gate; tag discipline.
3. **Observability** → `devops-observability` — OpenTelemetry +
   RED/USE metrics + SLO burn-rate alerts; golden-signals
   dashboards per service.
4. **Incident runbooks** → `devops-incident-runbook` — fixed-shape
   runbooks (Detect → Diagnose → Mitigate → Recover → Postmortem);
   quarterly game-day rehearsals.
5. **Release management** → `devops-release-management` — cadence
   + freezes + approvals + versioning + rollback procedures +
   communication.
6. **Security hardening** → `devops-security-hardening` — 8-
   category pre-prod audit (SBOM / scans / auth / TLS / OWASP)
   with PASS/PARTIAL/FAIL and waiver discipline.
7. **Secrets** → `devops-secrets` — vault choice; per-class
   rotation; ACLs; audit + anomaly alerts; emergency rotation
   runbook.

### Skills involved — checklist

| Skill / Agent | Status | Role |
|---|---|---|
| `devops-engineer` (agent) | shipped | Conductor for engaged workstreams. |
| `devops-ci-cd`, `devops-iac`, `devops-observability`, `devops-incident-runbook`, `devops-release-management`, `devops-security-hardening`, `devops-secrets` | shipped | Per-workstream producers. |
| Language `*-testing` / `*-linting` skills | shipped | Supply CI commands. |
| `requirement-audit` | shipped | Per-workstream deliverable verification. |
| `memory-ontology` | shipped | Persists operational decisions. |
| `lifecycle-pilot`, `architecture-shepherd` (agents) | shipped | Hand-offs (launch readiness; rollout gates). |

Gaps: 0. Recommended next step: *"Use the devops-engineer agent
to set up <workstream(s)> for this project."*

---

## Scenario P — Architecture upgrade (architecture-shepherd)

**Goal.** Steward an architectural upgrade end-to-end — assess
honestly, decide deliberately, plan in reversible phases, roll
out with metric gates, communicate to downstream consumers.

### When this fits

- *"Should we split this monolith?"*
- *"Move from REST to gRPC."*
- *"Upgrade Postgres major version."*
- *"Plan the rollout for the new auth service."*
- *"We're deprecating v1 of the public API."*

### Procedure

The five-phase shepherd arc from [`architecture-shepherd`](agents/architecture-shepherd/AGENT.md):

1. **Assessment** → `arch-assessment` — current-state diagram +
   pain points + risk register + 3+ options matrix (always with
   Option 0); inferred-vs-confirmed discipline mandatory.
2. **Decision** — human decision authority picks; rationale
   recorded via `memory-ontology`.
3. **Migration plan** → `arch-migration-plan` (general) OR
   `arch-dependency-upgrade` (specialised variant for major dep
   bumps) — 3–8 phases with reversible checkpoints, named
   owners, interface locks, per-phase test plans.
4. **Rollout** → `arch-rollout-strategy` — pick among 5 strategies
   (big-bang / blue-green / canary / dark-launch / feature-
   flagged); metric gates tied to SLOs; automatic abort
   conditions; scripted per-stage rollback.
5. **Comms + record** → `arch-breaking-change-comms` — audience-
   specific drafts (internal / customers / API consumers); sunset
   escalation pattern; update INSTRUCTIONS/projects/<slug>/ to
   reflect new stack.

Hand off to `devops-engineer` for CI/CD + observability + runbook
work during rollout. Hand off to `knowledge-curator` for public
KB / docs updates.

### Skills involved — checklist

| Skill / Agent | Status | Role |
|---|---|---|
| `architecture-shepherd` (agent) | shipped | Conductor across the 5-phase arc. |
| `arch-assessment`, `arch-migration-plan`, `arch-dependency-upgrade`, `arch-rollout-strategy`, `arch-breaking-change-comms` | shipped | Per-phase producers. |
| `project-knowledge-base` | shipped | Pulls current architecture map for assessment. |
| `cognitive-alignment` | shipped | Lock service / tenant / queue / region terms. |
| `memory-ontology` | shipped | Records architectural decisions. |
| `requirement-audit` | shipped | Gates every phase transition. |
| `devops-engineer`, `knowledge-curator` (agents) | shipped | Hand-offs (rollout infra; public docs). |

Gaps: 0. Recommended next step: *"Use the architecture-shepherd
agent to assess and plan <architectural change>."*

---

## Scenario Q — Enterprise knowledge base (knowledge-curator)

**Goal.** Build, merge, refresh, and govern a multi-project
enterprise knowledge base with search and access control —
turning isolated per-project KBs into a governed enterprise
knowledge graph.

### When this fits

- *"Build the enterprise KB."*
- *"Merge the project KBs into one canonical layer."*
- *"Set up RAG over our docs for the new AI features."*
- *"How do we keep the KB fresh?"*
- *"We need access control on the KB."*

### Procedure

The five-workstream curator arc from [`knowledge-curator`](agents/knowledge-curator/AGENT.md):

1. **Architecture** → `enterprise-kb-architecture` — 7-domain
   default taxonomy; entity contract; promotion + sunset
   criteria. **Foundational — must be locked before merging.**
2. **Merge** → `enterprise-kb-merge` — per-entity decision tree;
   explicit conflict surfacing; cross-reference rewriting; alias
   capture; versioned merge reports.
3. **Refresh policy** → `enterprise-kb-refresh-policy` — per-
   entity-type staleness rules; mandatory ownership; automatic
   + manual triggers; soft/hard sunset; unowned-entity governance.
4. **Search index** → `enterprise-kb-search-index` — shared
   retrieval client; context-preserving chunking; hybrid
   dense+BM25 + reranking; ACL enforcement at retrieval.
5. **Access control** → `enterprise-kb-access-control` — 5-level
   classification; internal default; per-classification
   redaction; audit log + anomaly alerts; quarterly access
   audits.

Hand off to `devops-engineer` for vector DB hosting + audit log
infrastructure. Hand off to `lifecycle-pilot` for AI features
consuming the index.

### Skills involved — checklist

| Skill / Agent | Status | Role |
|---|---|---|
| `knowledge-curator` (agent) | shipped | Conductor across the 5 workstreams. |
| `enterprise-kb-architecture`, `enterprise-kb-merge`, `enterprise-kb-refresh-policy`, `enterprise-kb-search-index`, `enterprise-kb-access-control` | shipped | Per-workstream producers. |
| `project-knowledge-base` | shipped | Per-project KB source. |
| `book-to-knowledge-graph`, `ontology-extraction`, `ontology-merging`, `ontology-storage`, `ontology-qa` | shipped | Long-text source pipeline. |
| `cognitive-alignment` | shipped | Cross-project terminology alignment. |
| `memory-ontology` | shipped | Promotes durable facts to canonical entities. |
| `devops-engineer`, `lifecycle-pilot` (agents) | shipped | Hand-offs (infra; AI features). |

Gaps: 0. Recommended next step: *"Use the knowledge-curator
agent to design the enterprise KB architecture."*

---

## Scenario R — Re-architecture + relaunch (multi-agent)

**Goal.** A change that spans architecture, ops, and product/GTM
simultaneously — for example, re-platforming an existing product
and relaunching it as v2.

### When this fits

- *"Re-architect to event-driven and relaunch as v2."*
- *"Migrate to Kubernetes during the v2 launch window."*
- Any scenario that needs the architecture + lifecycle + devops
  agents working in concert.

### Procedure

`scenario-strategist` forms the group; the four-phase strategist
arc (Scenario N) precedes the work:

1. **Brief + options + decision** via `scenario-analysis`.
2. **Workflow design** via `workflow-design` — typically
   sequential overall (architecture → relaunch) with parallel
   tracks within each phase.
3. **Group formation** via `agent-group-formation`:
   - Architecture phases: `architecture-shepherd` lead;
     `devops-engineer` supports.
   - Launch phases: `lifecycle-pilot` lead; `devops-engineer`
     + `architecture-shepherd` (steady-state) support.
   - Conductor: `scenario-strategist`.
4. **Handoffs** via `agent-handoff-protocol` — between
   architecture and lifecycle (typically the cutover phase →
   "ready for launch readiness audit").

Then execute Scenario P → Scenario O (ops touch-points) →
Scenario M for the relaunch portion.

### Skills involved — checklist

| Skill / Agent | Status | Role |
|---|---|---|
| `scenario-strategist` (agent) | shipped | Conductor across the multi-agent group. |
| `scenario-analysis`, `workflow-design`, `agent-group-formation`, `agent-handoff-protocol` | shipped | Group-formation arc. |
| `architecture-shepherd` (agent) | shipped | Lead — architecture phases. |
| `lifecycle-pilot` (agent) | shipped | Lead — relaunch phases. |
| `devops-engineer` (agent) | shipped | Supports both (ops gates + observability). |
| `cognitive-alignment`, `memory-ontology`, `compact-ritual` | shipped | Cross-arc (long-lived workflow). |
| `requirement-audit` | shipped | Per-handoff acceptance verification. |

Gaps: 0. Recommended next step: *"Use the scenario-strategist
agent to form the group for our re-architecture + relaunch."*

---

## Scenario S — Enterprise KB + AI feature launch (multi-agent)

**Goal.** Build the enterprise knowledge base and ship the AI
features that consume it in coordinated motion — common pattern
where the AI feature is the *reason* the enterprise KB is being
built.

### When this fits

- *"Build the enterprise KB and use it to power the AI features
  we promised customers."*
- New AI product whose value depends on retrieval over the
  enterprise knowledge graph.

### Procedure

`scenario-strategist` forms the group (Scenario N precedes).

Then in coordinated phases:

1. **KB architecture** (`knowledge-curator` lead) — establish
   taxonomy + entity contract before anything else.
2. **Merge + access control + initial index** (`knowledge-curator`
   lead; `devops-engineer` supports for index hosting) — produces
   the queryable canonical layer.
3. **AI feature design + build** (`lifecycle-pilot` lead;
   `knowledge-curator` supports for retrieval-client API) — the
   feature consumes the shared retrieval client.
4. **Launch readiness + GTM** (`lifecycle-pilot` lead;
   `knowledge-curator` supports for public-docs slice;
   `devops-engineer` supports for ops baseline).
5. **Refresh policy + ongoing ownership** (`knowledge-curator`
   lead; persists past launch).

### Skills involved — checklist

| Skill / Agent | Status | Role |
|---|---|---|
| `scenario-strategist` (agent) | shipped | Group conductor. |
| `knowledge-curator` (agent) | shipped | KB lead; AI-feature retrieval-client partner. |
| `lifecycle-pilot` (agent) | shipped | AI feature lead. |
| `devops-engineer` (agent) | shipped | Vector DB hosting; AI-feature CI/CD; ops baseline. |
| `enterprise-kb-architecture`, `enterprise-kb-merge`, `enterprise-kb-search-index`, `enterprise-kb-access-control`, `enterprise-kb-refresh-policy` | shipped | Per-workstream KB producers. |
| `agent-group-formation`, `agent-handoff-protocol` | shipped | Define the KB ↔ AI-feature handoff contract. |
| `requirement-audit` | shipped | Per-handoff acceptance. |
| `memory-ontology` | shipped | Persists KB + AI feature decisions. |

Gaps: 0. Recommended next step: *"Use the scenario-strategist
agent to form a group for our enterprise KB + AI feature launch."*

---

## Appendix — Checklists

Aggregated quick-reference of which skills exist (✓), which are project-specific
(◐), and which are gaps to fill (✗).

### `share/` — meta-skills

| Skill | Status |
|---|---|
| `skill-orchestrator` | ✓ |
| `cognitive-alignment` | ✓ |
| `memory-ontology` | ✓ |
| `compact-ritual` | ✓ |
| `requirement-audit` | ✓ |
| `scenario-checklist` | ✓ |
| `skill-evolution` | ✓ |
| `skill-merge` | ✓ |

### `ideas/` — project lifecycle

| Skill | Status |
|---|---|
| `project-prototype` | ✓ |
| `project-docs` | ✓ |
| `project-mockup-app` | ✓ |
| `task-breakdown` | ✓ |
| `project-frontend` | ✓ |
| `project-backend-node` | ✓ |
| `project-backend-go` | ✓ |
| `project-backend-python` | ✓ |
| `project-onboarding` | ✓ |
| `project-knowledge-base` | ✓ |
| `create-project-instruction` | ✓ |

### `knowledge-graph/` — long-text pipeline

| Skill | Status |
|---|---|
| `book-to-knowledge-graph` | ✓ |
| `book-chunking` | ✓ |
| `ontology-extraction` | ✓ |
| `ontology-merging` | ✓ |
| `ontology-storage` | ✓ |
| `ontology-qa` | ✓ |

### `dev-go/` — Go quality skills

20 portable skills covering style, naming, errors, concurrency, testing,
etc. All shipped (✓).

The previous `go-stardust-rtl` was moved out of this group into
`skills/projects/stardust-rtl/` because it is project-specific rather than
generic Go guidance.

### `dev-node/` — Node.js / TypeScript quality skills

20 portable skills covering style, naming, types, modules, async,
error-handling, control-flow, functions, data-structures, classes, streams,
testing, logging, config, HTTP, security, performance, documentation,
linting, and code-review. All shipped (✓).

### `dev-python/` — Python quality skills

20 portable skills covering style, naming, typing, modules, async,
error-handling, control-flow, functions, data-structures, classes,
iterators/generators, testing, logging, config, HTTP, security,
performance, documentation, linting, and code-review. All shipped (✓).

### `dev-java/` — Java quality skills

20 portable skills covering style, naming, packages, types, generics,
concurrency, error-handling, control-flow, methods/lambdas,
data-structures, classes, testing, logging, config, HTTP, security,
performance, documentation, linting, and code-review. All shipped (✓).

### `projects/` — project-specific skills

| Skill | Status |
|---|---|
| `stardust-rtl` | ✓ (◐ project-specific: stardust; example of skill produced via project-onboarding) |

Add additional entries here when a project earns one (see
`skills/projects/README.md` for when to create one).

### `dev-tools/`

| Skill | Status |
|---|---|
| `ccc` | ✓ (requires CocoIndex Code CLI installed) |
| `doc-markdown-standards` | ✓ (opt-in: Obsidian convention only) |
| `omc-reference` | ✓ (requires oh-my-claudecode plugin) |

### `design/`

| Skill | Status |
|---|---|
| `ui-ux-pro-max` | ✓ |

### Known gaps

| Need | Status | Workaround |
|---|---|---|
| Language-specific review skills beyond Go, Node, Python, and Java (`rust-code-review`, `kotlin-code-review`, etc.) | ✗ | Use general principles + project lint/test commands. |
| Per-language skill suites beyond Go, Node, Python, and Java (`dev-rust/*`, `dev-kotlin/*`, etc.) | ✗ | Use universal `INSTRUCTIONS/standards/code-standards.md` plus project-specific conventions. |
| Security-review skill (cross-language) | ✗ | Use `INSTRUCTIONS/development-principles.md` defensive sections plus project's security guidelines. |
| API-contract diff skill | ✗ | Manual diff review against OpenAPI / proto files. |

These gaps are candidates for future skills. When you write one, follow the
shape of `skills/dev-go/go-code-review/`, `skills/dev-node/node-code-review/`,
`skills/dev-python/py-code-review/`, or `skills/dev-java/java-code-review/`
as the template and update the relevant scenarios above.

---

## Agents — quick reference

The framework ships **five agents** under `agents/`. Each agent is a
named role bundling a workflow + skills + deliverables for a specific
job. The scenarios above (M–S) document the characteristic arc per
agent and the common multi-agent compositions.

| Agent | Focus | Single-agent scenario | Multi-agent appearances |
|---|---|---|---|
| [`lifecycle-pilot`](agents/lifecycle-pilot/AGENT.md) | Prototype → Prod → Go-to-Market | [M](#scenario-m--taking-an-idea-all-the-way-to-launch-lifecycle-pilot) | R, S |
| [`scenario-strategist`](agents/scenario-strategist/AGENT.md) | Scenario analysis + workflow + group formation | [N](#scenario-n--multi-agent-coordination-scenario-strategist) | R, S |
| [`devops-engineer`](agents/devops-engineer/AGENT.md) | CI/CD, IaC, observability, runbooks, releases, security, secrets | [O](#scenario-o--operational-baseline--ongoing-ops-devops-engineer) | M, P, R, S |
| [`architecture-shepherd`](agents/architecture-shepherd/AGENT.md) | Architecture upgrade support | [P](#scenario-p--architecture-upgrade-architecture-shepherd) | R |
| [`knowledge-curator`](agents/knowledge-curator/AGENT.md) | Enterprise knowledge base upgrade | [Q](#scenario-q--enterprise-knowledge-base-knowledge-curator) | S |

See [agents/README.md](agents/README.md) for the agents layer rationale
and [agents/CHECKLIST.md](agents/CHECKLIST.md) for build status of every
agent + its dependent skills.

---

## See also

- [README.md](README.md) — framework overview.
- [HOWTO.md](HOWTO.md) — everyday mechanics.
- [agents/README.md](agents/README.md) — agents layer overview.
- [agents/CHECKLIST.md](agents/CHECKLIST.md) — agents + new-skills progress.
- `INSTRUCTIONS/README.md` — universal instructions overview.
- `skills/ideas/WORKFLOW.md` — the project quick-start narrative.
- `skills/share/skill-orchestrator/SKILL.md` — orchestration logic.
