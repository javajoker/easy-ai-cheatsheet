---
name: scenario-checklist
description: Produce a per-scenario skills (and agents) checklist for any workflow — list the skills/agents that will participate, their role, their availability status (shipped / project-specific / missing), and any gaps before the workflow can run. Output mirrors the "Skills involved — checklist" tables in SCENARIOS.md. Two formats: 3-column (skill-only scenarios) and 4-column with an Agent column (agent-aware scenarios). Use this skill when authoring a new scenario for SCENARIOS.md, when a user asks "what skills will this use?", when planning a workflow that has not been done before, or when reviewing whether the framework can handle a proposed workflow. Reads both the skill catalog AND agents/CHECKLIST.md at runtime — does not hardcode skill or agent lists. Pairs with skill-orchestrator (which uses the checklist to plan execution and to route to named agents), with requirement-audit (which uses scenario-checklist output as one form of evidence), and with agent-group-formation (which uses the same row format at agent granularity).
---

# Scenario Checklist

A skill for producing the "which skills participate in this workflow?"
checklist. The output is the same shape used in `SCENARIOS.md` — a table
with skill, status, and role columns — and is the canonical way to add a
new scenario or to surface the plan to the user before execution.

## Why this exists

Two related needs share an answer:

1. When adding a new scenario to `SCENARIOS.md`, the per-scenario "Skills
   involved" table is what makes the scenario actionable. Authoring it by
   hand is tedious and error-prone — easy to forget a meta-skill, easy to
   miss a gap.
2. When the user asks "what would it take to do X?", the most honest
   answer is the same kind of checklist: here is the chain, here is what
   exists, here is what's missing.

Both reduce to one operation: read the catalog, classify which skills
apply, mark gaps. This skill encodes that operation.

## Output format

The deliverable is a markdown table plus a short summary, matching the
format used throughout `SCENARIOS.md`.

### Default 3-column format (skill-only scenarios)

```markdown
### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `<name>` | shipped / project-specific / missing | <one-line role description> |
| `<name>` | … | … |

Gaps: <count of missing skills>. Recommended next step: <one concrete action>.
```

### 4-column format (agent-aware scenarios)

When **one or more agents** participate in the scenario, add an `Agent`
column that names the owning agent for each row (or `–` if the row is
not owned by a specific agent). Use this format for any scenario
involving the agents from `agents/CHECKLIST.md`.

```markdown
### Skills involved — checklist

| Skill / Agent | Status | Agent | Role |
|---|---|---|---|
| `lifecycle-pilot` (agent) | shipped | – | Conductor across phases. |
| `project-prototype` | shipped | `lifecycle-pilot` | Phase 1 — clickable React mock. |
| `gtm-launch-readiness` | shipped | `lifecycle-pilot` | Phase 6 — pre-launch audit. |
| `requirement-audit` | shipped | – | Gates Phase 6. |
| `cognitive-alignment` | shipped | – | Cross-phase meta-skill. |

Agents: <list>. Gaps: <count of missing skills/agents>.
Recommended next step: <one concrete action>.
```

**Rules for the Agent column:**

- An agent's *own* row has `–` in the Agent column (the agent is the
  owner; it doesn't own itself).
- A skill row's Agent column names the agent in whose AGENT.md it
  appears under `skills_used` (typically one agent; if a skill is
  shared across agents, name the *primary* owner — usually the one
  whose `fires_on` triggers most directly invoke the skill).
- Meta-skills (`cognitive-alignment`, `memory-ontology`,
  `compact-ritual`, `skill-orchestrator`, `requirement-audit`) get
  `–` since they're cross-cutting.
- If a row is `missing`, the Agent column names the agent that
  *would* own the missing skill if it existed.

### When to use which format

| Format | Use when |
|---|---|
| 3-column | Scenario uses only skills from `skills/share/`, `dev-*/`, `ideas/`, `knowledge-graph/`, etc. without invoking a named agent. |
| 4-column | Scenario involves any of the 5 agents (`lifecycle-pilot`, `architecture-shepherd`, `scenario-strategist`, `devops-engineer`, `knowledge-curator`). |

When in doubt, prefer 4-column — the extra column is cheap and the
agent visibility is valuable.

## Status vocabulary

Fixed; do not invent new statuses:

- **shipped** — exists in the framework and applies generically.
- **project-specific** — exists but only applies to one project (lives
  under `skills/projects/`).
- **opt-in** — exists but requires explicit project adoption (e.g.
  Obsidian-flavoured `doc-markdown-standards`).
- **missing** — does not exist. The checklist names the gap; another
  skill (project-onboarding, the user) fills it.

## Procedure

### Phase 1 — Anchor the scenario

Get a one-paragraph statement of the workflow being checklisted:

- What is the user trying to accomplish?
- What inputs does the workflow start with?
- What outputs does it produce?
- What is in scope, what is out?

If anchoring is unclear, run a **cognitive-alignment** check before
proceeding. A vague scenario produces a vague checklist.

### Phase 2 — Read the catalog (skills AND agents)

Two catalogs:

1. **Skills** — enumerated in the system prompt under `<available_skills>`
   (or equivalent harness mechanism). Read every entry's description, not
   just the names — see `skill-orchestrator/SKILL.md` Phase 1 for the
   same discipline.
2. **Agents** — enumerated in `agents/CHECKLIST.md`. Read the per-agent
   `fires_on` triggers (from each AGENT.md frontmatter) and `skills_used`
   lists to know which agents participate and which skills they own.

Identify every skill **and every agent** whose description / triggers
plausibly apply to the scenario. Borderline candidates get included with
a note rather than excluded silently.

If **any** agent participates, switch to the 4-column output format.

### Phase 3 — Decompose into roles

Split the scenario into discrete sub-tasks. Each sub-task maps to one or
more skills (and possibly an owning agent):

- **Agents** — named roles that conduct multi-phase work (the 5 agents
  under `agents/`). When an agent participates, list its own row first
  with `Agent: –` (the agent owns; it doesn't own itself).
- **Producer skills** — produce a deliverable (project-frontend,
  task-breakdown, create-project-instruction). When owned by an agent,
  populate the Agent column.
- **Coordinator skills** — pick or chain producers (skill-orchestrator,
  project-onboarding).
- **Meta-skills** — run alongside (cognitive-alignment, memory-ontology,
  compact-ritual) and are nearly always present. Always `Agent: –`
  (cross-cutting).

The meta-skills row is mandatory in every scenario checklist — they are
not optional, even when the scenario doesn't explicitly mention them.

### Phase 4 — Classify status

For each skill identified, classify:

- Present in the catalog and applies generically → `shipped`.
- Present but under `skills/projects/<slug>/` → `project-specific`.
- Present but requires the project to opt in (declared in its `SKILL.md`
  frontmatter or noted in this file's status vocabulary) → `opt-in`.
- Absent from the catalog → `missing`. Suggest a name for the missing
  skill in the role column.

### Phase 5 — Emit the checklist

Write the table in the format above. Below the table:

- One-line summary of total skills and gap count.
- One concrete recommended next step (the most valuable single action).
- (Optional) "Manual fallback" subsection if any rows are `missing`.

### Phase 6 — Cross-reference

If the checklist is for inclusion in `SCENARIOS.md`, update:

- The scenario's own "Skills involved" table.
- The appendix's per-group counts.
- The "Known gaps" subsection if any rows are `missing`.

If the checklist is for inline use during a workflow, no document updates
are needed — the table itself is the deliverable.

## Examples of when to use

- *"Add a scenario for migrating a project's database — what skills will
  be involved?"* — scenario-checklist produces the table.
- *"Plan an audit pass over our docs."* — scenario-checklist surfaces the
  chain (project-knowledge-base + requirement-audit + cognitive-alignment).
- *"Can the framework do X?"* — scenario-checklist's output answers
  honestly with `missing` rows where the framework falls short.

## Companion skills

| When… | Use |
|---|---|
| Locking the meaning of an ambiguous scenario term before checklisting | `cognitive-alignment` |
| After checklisting, to plan and execute the workflow | `skill-orchestrator` |
| To verify the workflow's deliverables once executed | `requirement-audit` |
| To capture the checklist as the next session's starting point | `memory-ontology` |
| For long workflows where the checklist survives `/compact` | `compact-ritual` |

## Anti-patterns

- **Listing every skill in the catalog.** A checklist that names 30
  skills tells the user nothing. Pick the skills that actually
  participate; cap mandatory rows at the meta-skills plus the work-doing
  skills (typically 5–10 total).
- **Omitting meta-skills.** `cognitive-alignment`, `memory-ontology`,
  `compact-ritual` are present in every scenario checklist. Always.
- **Marking `missing` without a name.** When a row is `missing`, suggest
  a name (kebab-case, role-appropriate). Anonymous gaps don't get filled.
- **Inventing new statuses.** Four statuses, full stop: shipped,
  project-specific, opt-in, missing.
- **Bloating the role column.** One line per role. Detail goes in the
  scenario's procedure section, not the checklist row.

## Reference files

- `references/checklist-format.md` — strict format spec for the output
  table, including how to lay it out in `SCENARIOS.md` vs inline.
- `references/role-vocabulary.md` — controlled vocabulary for role
  descriptions, so different scenarios use the same language for the
  same kind of work.
