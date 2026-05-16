---
name: enterprise-kb-merge
description: Merges per-project knowledge bases (plus book-derived ontologies) into the canonical enterprise KB, with explicit conflict detection. For each candidate entity, decides canonical (promote) / per-project only (leave in source) / conflict (same name, different meaning) and surfaces conflicts for human resolution. Rewrites cross-references so per-project KBs link up to canonical entities and canonical entities link down to source instances. Captures aliases for renamed entities so historical references resolve. Operates one layer above ontology-merging (which handles single-source merges within one book/ontology); this skill handles multi-source enterprise-level merges. Output is updated enterprise-kb/entities/ + relations.md + a merge-report.md documenting decisions + conflicts. Use this skill after enterprise-kb-architecture is locked, when the user says "merge the KBs", "consolidate the project ontologies", "build the canonical entities", "do the enterprise KB merge", or when scheduled refresh from enterprise-kb-refresh-policy triggers. Pairs with enterprise-kb-architecture (upstream — taxonomy + promotion criteria must exist first), with ontology-merging (sub-skill for single-source merges), with cognitive-alignment (conflicts often turn out to be alignment failures), with enterprise-kb-refresh-policy (refresh re-runs merge), and with memory-ontology (promotes durable facts to canonical entities).
status: shipped
owner_agent: knowledge-curator
---

# Enterprise KB Merge

Phase 2 of the `knowledge-curator` agent. Operates one layer
above `ontology-merging` — that skill handles single-source
merges within one book / ontology; this one handles *multi-
source* enterprise-level merges across project KBs, books, and
memory.

> **Conflicts surface, never silently resolve.** When two
> sources disagree on what an entity means, the skill stops
> and surfaces the conflict. Silent resolution corrupts the
> canonical layer; the cost of asking is much less than the
> cost of getting it wrong.

## Why this exists

Multi-source merge failures are predictable:

1. **Silent disagreement.** Project A says *user = paid customer*;
   Project B says *user = anyone with an account*. Merge picks
   one; downstream consumers of the canonical layer get
   surprising behaviour.
2. **Lost cross-references.** Project A's KB linked to its
   local *Auth Service* entity; after promotion to canonical,
   the link is broken because nothing rewrote it.
3. **Duplicate canonical entities.** Project A's *Stripe
   Integration* and Project B's *Stripe Connector* merge as
   two canonical entities; downstream sees redundancy.
4. **No audit trail.** Three months later, "where did this
   canonical entity come from" is unanswerable; refresh becomes
   archaeology.
5. **Re-merge churn.** Every refresh re-decides decisions made
   in the prior merge; the canonical layer thrashes.

This skill enforces explicit promote/per-project/conflict
classification, mandatory cross-reference rewriting, alias
capture, and a versioned merge-report audit trail.

## When to fire

Fire when:

- `enterprise-kb-architecture` is locked + scaffolded.
- The user says *"merge the KBs"*, *"consolidate the project
  ontologies"*, *"build the canonical entities"*, *"do the KB
  merge"*.
- A scheduled refresh from `enterprise-kb-refresh-policy`
  triggers a re-merge.
- A new source (new project KB, new book) is being incorporated.

Do **not** fire when:

- No architecture exists yet (run `enterprise-kb-architecture`
  first).
- The merge is within a single source (use `ontology-merging`,
  not this skill).
- The user wants to query the KB, not extend it (use
  `ontology-qa`).

## Inputs

Required:

- `enterprise-kb/ARCHITECTURE.md` (locked).
- `enterprise-kb/source-manifest.md` (or the source list the
  user provides).
- Read access to every source (per-project KBs, books, memory
  store, external systems).

Asked once (cap at 3):

1. **Scope.** Full re-merge / incremental (only new entities
   since last sync) / single-source refresh.
2. **Conflict resolution policy.** Stop-on-conflict (default —
   surface every conflict; user decides) vs. auto-prefer-source
   (only for low-stakes refreshes; documented per source).
3. **Dry-run first?** Default yes — produce the merge report
   without writing canonical entities; user reviews before
   commit.

## The opinionated merge procedure

### Per-entity decision tree

For each candidate entity from any source:

```
Does an entity with the same id / name exist in canonical?
├── NO  → Does it meet promotion criteria from ARCHITECTURE.md?
│        ├── YES → Promote: create canonical entity
│        └── NO  → Per-project only: leave in source
└── YES → Compare candidate vs. existing canonical
         ├── Same meaning (e.g. minor wording difference) →
         │   Update canonical (append source; bump updated)
         ├── Same meaning, different name → Add alias to canonical
         ├── Different meaning → CONFLICT — surface to user
         └── Newer source has additional info → Merge fields
```

### Conflict types

| Type | Example | Resolution |
|---|---|---|
| **Definition** | Project A: *user = paid customer*; Project B: *user = any account* | User picks canonical definition; other source's usage gets aliased to a new entity |
| **Field value** | Owner = team X in one; owner = team Y in another | User decides current owner; old owner moved to history |
| **Relation** | One source links to entity Z; other doesn't | Merge relations (additive); flag for review if relations contradict |
| **Classification** | One source says public; another says internal | Default to more restrictive; user reviews |
| **Sub-type** | One source says architectural decision; another says strategic | User picks (often the architectural sub-type encompasses) |

### Cross-reference rewriting

When an entity promotes to canonical:

- **Per-project KB references rewrite to point at canonical:**
  `[Auth Service](/coolshell/kb/auth-service)` →
  `[Auth Service](/enterprise-kb/entities/products/auth-service)`
  (with the project link kept as `source` reference).
- **Canonical entity records all source references:** under
  `sources` frontmatter field.
- **Bi-directional linking:** canonical entity's "Where it
  appears" section lists every source's reference back to the
  canonical entity.

Rewriting happens atomically per entity to avoid broken
intermediate states.

### Alias capture

When a candidate has a different name from an existing
canonical entity but the same meaning:

- Add the candidate name to the canonical entity's `aliases`
  list.
- Per-project references using the alias rewrite to point at
  canonical.
- The alias is searchable in `enterprise-kb-search-index` (so
  retrieval finds the canonical entity by either name).

### The merge report

Every merge produces `enterprise-kb/merge-reports/<YYYY-MM-DD>-merge.md`:

- Summary: N promoted, M updated, K conflicts surfaced, L per-
  project only.
- Per-entity decision table.
- Per-conflict resolution log.
- Source manifest changes (sources added / removed).
- Cross-reference rewrite count.

The report is the audit trail. Future merges reference it to
avoid re-deciding settled questions.

## The procedure

### Phase 1 — Read architecture + manifest

Open `ARCHITECTURE.md` (locked). Read:

- Taxonomy (where entities belong).
- Entity contract (what fields are required).
- Promotion criteria (when to promote).
- Sunset criteria (when to retire).

Open `source-manifest.md`. Read the current source list.

### Phase 2 — Inventory candidates

For each source, enumerate every entity. Per source type:

- **Per-project KB:** read entity files; parse frontmatter.
- **Book ontology:** call `ontology-extraction` if not already
  extracted; load entities.
- **Memory scope:** read `type: project` / `type: reference`
  memories; filter for entity-shaped ones.
- **External system:** API fetch (Linear / Notion / Confluence
  with cached pagination).

### Phase 3 — Cognitive alignment

Before classification, run `cognitive-alignment` on terms that
appear across multiple sources. Disagreements at the term
level become entity conflicts later — surface them now.

### Phase 4 — Per-entity classification

Walk every candidate through the decision tree. Produce three
piles:

- **Promote** (new canonical or updated existing).
- **Per-project only** (does not meet promotion criteria).
- **Conflict** (needs user resolution).

### Phase 5 — Surface conflicts for resolution

For each conflict, present:

- The entity name + the disagreement type.
- The two (or more) interpretations with sources.
- A recommendation (if one source is more authoritative — e.g.
  a decision memory beats a derived KB entity).

User decides. Resolutions are logged in the merge report.

### Phase 6 — Apply the merge (after dry-run review)

If dry-run was first, surface the proposed merge to the user
for review. Once approved, apply:

- Write/update canonical entities.
- Rewrite cross-references.
- Append to source manifest (new sources / changed sources).
- Generate the merge report.

Apply is atomic per entity — partial failure leaves canonical
in a coherent state.

### Phase 7 — Emit merge report + persist

Write the merge report. Persist as `type: project` memory
(`kb_merge_<date>_v1`).

Hand off to:

- `enterprise-kb-refresh-policy` to schedule the next refresh.
- `enterprise-kb-search-index` to re-index affected entities.
- `enterprise-kb-access-control` to verify classification on
  newly promoted entities.

### Phase 8 — Watch for merge-quality triggers

The merge is high-quality when:

- Conflict count is decreasing across refreshes (alignment is
  improving).
- Cross-reference integrity is 100% (no broken links).
- No "rediscovered" entities (an entity merged last time
  becoming a conflict this time).

When any signal degrades, run `enterprise-kb-architecture`
re-architecture trigger check — taxonomy may not fit reality.

## Anti-patterns

- **Silent conflict resolution.** Auto-picking one source on
  conflict corrupts the canonical layer.
- **Skipping cross-reference rewrite.** Links from per-project
  KBs to local entities go stale; the canonical layer is
  disconnected from sources.
- **No alias capture.** Same-meaning-different-name entities
  duplicate; retrieval fragments.
- **No dry-run.** Direct merge with no review = no chance to
  catch wrong classifications before they land.
- **No merge report.** Without the audit trail, future merges
  re-decide settled questions; canonical layer thrashes.
- **Promotion criteria ignored.** Promoting everything →
  canonical layer floods with noise; signal degrades.
- **Stale source manifest.** Manifest claims sources that no
  longer exist; refresh fails silently.

## Companion skills

- `enterprise-kb-architecture` — upstream (taxonomy +
  contract + criteria).
- `ontology-merging` — sub-skill (single-source merges).
- `cognitive-alignment` — pre-merge term alignment.
- `enterprise-kb-refresh-policy` — schedules re-merges.
- `enterprise-kb-search-index` — re-indexes affected entities.
- `enterprise-kb-access-control` — verifies classification.
- `memory-ontology` — promotes durable facts as candidates.
- `project-knowledge-base` — per-project source.
- `book-to-knowledge-graph` — book source.

## Reference files

- [references/merge-report-template.md](references/merge-report-template.md) —
  canonical merge report shape.
- `references/conflict-resolution-patterns.md` — common
  conflict types with worked resolutions.
- `references/cross-reference-rewrite-cookbook.md` — how to
  rewrite links across source types (markdown / JSON / YAML).
