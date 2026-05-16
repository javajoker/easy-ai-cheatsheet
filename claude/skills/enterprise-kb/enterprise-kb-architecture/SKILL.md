---
name: enterprise-kb-architecture
description: Designs the top-level layout for an enterprise knowledge base — the domain taxonomy (products, teams, decisions, terminology, runbooks, customers, partners), the entity contract (required fields per entity type — id, name, owner, status, updated, sources, classification), the source manifest (which per-project KBs, books, memory scopes, external systems feed it), the promotion criteria (when does a per-project entity become canonical), and the sunset criteria (when does it retire). The taxonomy + entity contract are the load-bearing decisions of the whole enterprise KB — get them wrong and every later merge fights them. Output is enterprise-kb/ARCHITECTURE.md plus the empty directory tree ready for ingestion. Use this skill when the user is starting an enterprise KB project before any merging has happened; or when they say "design the KB taxonomy", "what's the entity model", "we need an enterprise KB structure", "set up the knowledge graph". Pairs with cognitive-alignment (taxonomy terms are load-bearing across the org — lock them first), with project-knowledge-base (per-project KBs are sources), with book-to-knowledge-graph (long-text sources), with memory-ontology (durable facts promote into canonical entities), and with enterprise-kb-access-control (the entity contract includes classification — both skills need consistent definitions).
status: shipped
owner_agent: knowledge-curator
---

# Enterprise KB Architecture

Phase 1 of the `knowledge-curator` agent. The load-bearing
decisions of the entire enterprise KB — taxonomy, entity
contract, source manifest — must be made *before* merging
starts.

> **A wrong taxonomy is a re-merge.** Once entities have been
> merged under one taxonomy, switching taxonomies means
> re-walking every entity. Spend the time up front.

## Why this exists

Enterprise KB failures are predictable:

1. **Taxonomy drift.** Each project's KB invents its own
   terminology; *user* in one means *customer* in another;
   merging discovers the disagreement only after it's
   expensive.
2. **No promotion rule.** Project entities sometimes promote
   to canonical, sometimes don't — no clear criterion;
   canonical layer becomes inconsistent.
3. **Entity contract sprawl.** Each entity type collects ad-hoc
   fields; downstream consumers can't rely on what's there.
4. **No source manifest.** Six months in, nobody knows which
   project KBs the canonical layer was built from; refresh is
   archaeology.
5. **Never sunset anything.** Entities accumulate; deprecated
   products still surface in retrieval; KB loses signal-to-
   noise.

This skill enforces the four foundational decisions: taxonomy,
entity contract, source manifest, promotion + sunset criteria.

## When to fire

Fire when:

- Starting an enterprise KB project from scratch.
- An organisation has 3+ per-project KBs and wants to unify
  them.
- The user says *"design the KB taxonomy"*, *"what's the
  entity model"*, *"we need an enterprise KB structure"*.
- An existing enterprise KB needs architectural refresh (rare;
  high cost).

Do **not** fire when:

- The project is a single-project KB — use `project-
  knowledge-base` instead (per-project scope).
- The project is a book/long-text ontology — use
  `book-to-knowledge-graph` instead.
- The architecture already exists and the team wants to add
  entities — that's `enterprise-kb-merge`, not this skill.

## Inputs

Required:

- Inventory of sources: which per-project KBs exist; which
  books / whitepapers / long texts; which memory scopes;
  which external systems (Notion, Confluence, Linear, etc.).

Asked once (cap at 4):

1. **Organisation shape.** Single product / multi-product
   suite / agency-style (multiple unrelated client projects).
   Drives whether the taxonomy is product-centric or
   project-centric.
2. **Primary consumers.** AI features / human navigation /
   compliance / all. Drives entity contract priorities.
3. **Compliance regime.** None / GDPR / HIPAA / SOC2 / multi.
   Drives access-control classification at the entity-contract
   level.
4. **Top-level domains.** Default 7 (products, teams,
   decisions, terminology, runbooks, customers, partners).
   Add / remove based on org shape.

## The opinionated architecture

### Top-level taxonomy

Default 7-domain layout:

```
enterprise-kb/
├── ARCHITECTURE.md              # this skill's output; canonical
├── INDEX.md                     # nav index across all domains
├── entities/
│   ├── products/                # product entities (one per shipped product)
│   ├── teams/                   # team entities (org chart at entity-level)
│   ├── decisions/               # architectural / strategic decisions
│   ├── terminology/             # canonical glossary
│   ├── runbooks/                # promoted from per-project devops-incident-runbook
│   ├── customers/               # customer entities (B2B / enterprise focus)
│   └── partners/                # partner / integration / vendor entities
├── relations.md                 # cross-entity links
├── source-manifest.md           # what feeds the KB
├── refresh-policy.md            # output of enterprise-kb-refresh-policy
├── access-control.md            # output of enterprise-kb-access-control
├── search-index/                # output of enterprise-kb-search-index
└── governance.md                # ownership, escalation, audit cadence
```

Each domain is a folder; each canonical entity is one file
(markdown) under its domain. The folder structure is the
taxonomy.

### Adapting the domains

| Org shape | Adjustments |
|---|---|
| Single product | Products domain has one entry — consider replacing with "subsystems" |
| Multi-product suite | Default works well |
| Agency-style | Replace "products" with "projects"; add "engagements" |
| Open-source heavy | Add "contributors" alongside "teams" |
| Regulated industry | Add "compliance" alongside "decisions" |

Adapt before locking; never after.

### Entity contract (required fields per entity)

Every canonical entity has these fields (frontmatter):

```yaml
---
id: <kebab-case-stable-id>          # canonical ID; never changes
name: <human-readable name>
domain: products | teams | decisions | terminology | runbooks | customers | partners
type: <sub-type within domain>      # see per-domain type catalogues
owner: <named individual or team>   # mandatory; unowned entities don't promote
status: active | deprecated | sunset
classification: public | internal | restricted | confidential | regulated
updated: YYYY-MM-DD
created: YYYY-MM-DD
sources:                            # what fed this canonical entity
  - per-project-kb: <project slug> / <entity path>
  - book: <book id> / <entity path>
  - memory: <scope> / <memory id>
  - external: <system> / <reference>
aliases:                            # other names this entity is known by
  - <name>
related:                            # links to other canonical entities by ID
  - <id>
---

# <Name>

## Definition

<one paragraph; canonical definition>

## Context

<background; why this entity exists in the KB>

## Where it appears

<per-source list — which project KBs, which docs, which
features reference this entity>

## See also

<links — within KB and to external authoritative sources>
```

The contract is **enforced** at promotion time — an entity
missing a required field cannot promote.

### Promotion criteria

When does a per-project entity become a canonical enterprise
entity? Default rules (configurable):

| Criterion | Threshold |
|---|---|
| Appears in N project KBs | ≥2 |
| Named in a strategic / architectural decision memory | always |
| Referenced in a public artifact (docs site, marketing) | always |
| Referenced by an external partner / customer | always |
| Specifically requested for promotion | always (with rationale) |

Entities that don't meet criteria stay in per-project KBs
(still useful; just not canonical).

### Sunset criteria

When does a canonical entity retire?

| Criterion | Threshold |
|---|---|
| Owner unassignable (e.g. team dissolved, no new owner) | 90 days after last owner |
| No references in active artifacts | 12 months |
| Underlying subject decommissioned (product killed, partner ended) | At decommission |
| Explicit retirement request | Always |

**Sunset != delete.** Retired entities become read-only with
a pointer to successor (if any). Audit trail preserved.

### Source manifest

`source-manifest.md` enumerates every source:

```markdown
# Source Manifest

## Per-project knowledge bases

| Project | Path | Owner | Last sync |
|---|---|---|---|
| coolshell | github.com/x/coolshell/docs/knowledge-base/ | @alice | 2026-05-10 |
| stardust | github.com/x/stardust/docs/knowledge-base/ | @bob | 2026-05-12 |

## Books / long-text ontologies

| Source | Path | Format | Last sync |
|---|---|---|---|
| Acme Engineering Handbook | books/acme-eng-handbook.pdf | ontology-extraction | 2026-04-01 |

## Memory scopes

| Scope | Type | Purpose |
|---|---|---|
| global | user / feedback | User preferences across projects |
| project:* | project | Per-project facts |

## External systems

| System | Sync mechanism | Purpose |
|---|---|---|
| Linear | API → entity import | Engineering decisions |
| Notion | API → entity import | Product docs |
| Confluence | API → entity import | Internal wikis |
```

Updates to the manifest are versioned; the manifest is the
audit trail for "where did this entity come from".

## The procedure

### Phase 1 — Inventory sources

Catalogue every source (per-project KBs, books, memory
scopes, external systems). The user provides; the skill
asks targeted follow-up if anything obvious seems missing.

### Phase 2 — Cognitive alignment

Run `cognitive-alignment` on the load-bearing taxonomy terms:

- *product* vs *project* vs *engagement*.
- *user* vs *customer* vs *account*.
- *team* vs *squad* vs *unit*.
- *decision* vs *policy* vs *standard*.

These terms recur across every entity; cross-project alignment
is non-negotiable.

### Phase 3 — Decide the taxonomy

Default 7 domains adapted per org shape. Document the choice
+ rationale.

### Phase 4 — Decide the entity contract per type

For each domain, list the entity sub-types (e.g. in
`decisions`: architectural / strategic / compliance / tactical).

For each sub-type, list any *extra* required fields beyond
the base contract (e.g. `decisions/architectural` may require
`affected_components`).

Document in `ARCHITECTURE.md` as a contract table.

### Phase 5 — Decide promotion + sunset criteria

Per defaults; override with reasoning per org context.

The criteria become enforcement rules in `enterprise-kb-merge`
and `enterprise-kb-refresh-policy`.

### Phase 6 — Scaffold the directory tree

Create the empty `enterprise-kb/` tree:

- Empty domain folders.
- README in each domain explaining what belongs there.
- Top-level `ARCHITECTURE.md` (this skill's output).
- Placeholder `INDEX.md`, `relations.md`, `source-manifest.md`.
- README pointing at the next skills (`enterprise-kb-merge`,
  `enterprise-kb-refresh-policy`, etc.).

### Phase 7 — Emit ARCHITECTURE.md

Write `enterprise-kb/ARCHITECTURE.md` using
[references/architecture-template.md](references/architecture-template.md).

After writing:

1. Surface to the user; **the user must explicitly lock** the
   architecture before merging starts.
2. Persist as `type: project` memory (`kb_architecture_v1`).
3. Hand off to `enterprise-kb-merge` for the first merge pass.

### Phase 8 — Watch for re-architecture triggers

The architecture is locked but not immutable. Re-architect when:

- Org shape fundamentally changes (M&A; major restructure;
  pivot from single-product to multi-product).
- Compliance regime expands materially (new regulated entity
  type needed).
- The merge skill is failing repeatedly because the taxonomy
  doesn't fit the actual entities.

Re-architecture is expensive — typically requires re-walking
every entity. Treat it as a project, not a quick edit.

## Anti-patterns

- **Skipping cognitive alignment.** Org-wide taxonomy disagree-
  ments surface as merge conflicts later; cheaper to surface
  them now.
- **Optional owner field.** Unowned canonical entities decay.
  Owner is mandatory at promotion.
- **No promotion criteria.** Without criteria, the canonical
  layer is opinion-driven — inconsistent.
- **Domain explosion.** 15 top-level domains → nobody can
  navigate. Cap at 7 ± 2.
- **Fields no consumer uses.** Each required field has a
  consumer. If you can't name the consumer, the field is
  noise.
- **Permanent merge with no re-architecture trigger list.**
  Architecture should be revisitable; document when.
- **Public-default classification.** Default to *internal* in
  the entity contract; promoting to public is a deliberate
  action.

## Companion skills

- `cognitive-alignment` — non-negotiable upfront.
- `project-knowledge-base` — source of per-project entities.
- `book-to-knowledge-graph` — source of book ontologies.
- `memory-ontology` — promotes durable facts.
- `enterprise-kb-merge` — downstream consumer (merges per the
  architecture).
- `enterprise-kb-refresh-policy` — uses sunset criteria.
- `enterprise-kb-access-control` — uses classification field
  from entity contract.
- `enterprise-kb-search-index` — uses entity structure for
  chunking.

## Reference files

- [references/architecture-template.md](references/architecture-template.md) —
  canonical output document.
- `references/domain-catalogues.md` — sub-type catalogues per
  domain (products, teams, decisions, etc.).
- `references/entity-contract-examples.md` — worked examples of
  filled entity contracts per domain.
- `references/taxonomy-adaptation-examples.md` — how default
  taxonomy adapts to different org shapes.
