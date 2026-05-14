# Role Vocabulary

Controlled phrasing for the "Role" column of a scenario checklist. Using
the same language for the same kind of work across scenarios makes the
checklists comparable and scannable.

## For meta-skills

These four appear in nearly every checklist. Use these exact phrasings
unless the scenario adds genuine specificity.

| Skill | Default role phrasing |
|---|---|
| `skill-orchestrator` | Plans the chain, consolidates upfront questions, narrates execution. |
| `cognitive-alignment` | Surfaces ambiguous terms; maintains the conversation's shared vocabulary. |
| `memory-ontology` | Persists durable facts so the next session does not relearn them. |
| `compact-ritual` | Protects session state through `/compact` events. |

You may shorten these for very simple scenarios (one-clause role
descriptions), but do not invent unrelated phrasings — sameness is the
point.

## For project-lifecycle skills

| Skill | Default role phrasing |
|---|---|
| `project-prototype` | Idea → clickable UI prototype. |
| `project-docs` | Prototype + idea → PRD, UI/UX spec, tech design. Picks backend language. |
| `project-mockup-app` | Docs → runnable mock-data demo for validation. |
| `task-breakdown` | Docs → AI-executable task plan with dependency graph. |
| `project-frontend` | Docs + tasks → production React app. |
| `project-backend-node` | Docs + tasks → Fastify + Prisma + BullMQ project. |
| `project-backend-go` | Docs + tasks → Gin + GORM + asynq project. |
| `project-backend-python` | Docs + tasks → FastAPI + SQLAlchemy + Celery project. |
| `project-onboarding` | Reads an existing codebase; gathers facts; seeds memory. |
| `create-project-instruction` | Producer: writes `INSTRUCTIONS/projects/<slug>/`. |
| `project-knowledge-base` | Existing project → entities + relations + terminology graph. |

## For audit / checklist skills

| Skill | Default role phrasing |
|---|---|
| `requirement-audit` | Verifies a numbered requirements list against artifacts; emits PASS / PARTIAL / FAIL per row. |
| `scenario-checklist` | Produces the "Skills involved" checklist for a workflow. |

## For knowledge-graph skills

| Skill | Default role phrasing |
|---|---|
| `book-to-knowledge-graph` | Orchestrator for the long-text → ontology pipeline. |
| `book-chunking` | Long text → semantically coherent chunks. |
| `ontology-extraction` | Chunk → structured entity / relation JSON. |
| `ontology-merging` | Per-chunk ontologies → canonical book-level ontology. |
| `ontology-storage` | Merged ontology → portable exports (JSON, JSON-LD, Turtle, GraphML, Markdown). |
| `ontology-qa` | Question → grounded answer with citations from the ontology. |

## For dev / tools / design skills

When a scenario involves these, prefer the description from the SKILL.md
itself (condensed to one line) rather than inventing new phrasing.

## Phrasing rules

- **Sentence case**, ending with a period.
- **Active voice**: "Plans the chain" not "The chain is planned."
- **No hedging**: "Reads the codebase" not "Can read the codebase if
  available."
- **No lists in a row**: roles are one sentence. If a skill does several
  things in this scenario, pick the most load-bearing.

## When to deviate

The default phrasings are starting points, not laws. Deviate when:

- The scenario uses the skill in a specifically narrowed way (e.g.
  *"project-frontend — generates only the auth pages"*).
- The default phrasing would be technically correct but misleading in
  context.
- A new scenario surfaces a use case the default phrasing did not
  anticipate; update this file when the deviation is generally useful.
