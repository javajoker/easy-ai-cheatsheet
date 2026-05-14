# Integration Guide

How the project knowledge base connects to other parts of the framework.

## With `cognitive-alignment`

The cognitive library and the knowledge base's `terminology.md` cover the
same ground from two ends:

- Cognitive library is **conversation-scoped** and grows incrementally as
  the user and Claude align on terms.
- `terminology.md` is **project-scoped** and is generated as a batch from
  the codebase + docs.

Reconciliation:

1. When generating the knowledge base, seed `terminology.md` from the
   cognitive library entries that have already been confirmed for this
   project.
2. When starting a new session, hydrate the cognitive library from
   `terminology.md` — every term becomes a `confirmed` library entry with
   evidence pointing back to the knowledge base file.
3. If a term is added to one but not the other, the next audit pass picks
   it up.

## With `memory-ontology`

Significant decisions discovered while generating the knowledge base are
promoted into the MEMORY ontology:

- `decision` entities that constrain ongoing work → `type: project` memory
  with `scope: project:<slug>`.
- `external` entities that are operationally important → `type: reference`
  memory if they have a URL / dashboard / runbook the user references.

Conversely, MEMORY entries that pre-existed the knowledge base seed the
knowledge base in Phase 3:

- `type: project` memories with a clear conceptual subject → candidate
  knowledge-base entities.
- `type: reference` memories → candidate `external` entities.

The promotion direction is symmetric and intentional: facts can live in
either store, and an audit reconciles them.

## With `task-breakdown`

The task breakdown references knowledge base entity IDs in task contexts:

```markdown
## Context
Implements feature [entity-feature-auth-001](../../knowledge-base/entities/feature-auth.md).
Depends on [entity-abstraction-database-001](../../knowledge-base/entities/abstraction-database.md).
```

This gives every AI task agent a stable, deep pointer into the conceptual
model. It is much more useful than "implement auth" — it tells the agent
what concept they are realizing, where related code lives, and what
existing entities they should not duplicate.

## With Obsidian

If the project uses Obsidian for documentation:

- The knowledge base lives inside the Obsidian vault.
- Front-matter `id` fields become Obsidian aliases for WikiLink resolution.
- The `related:` relations show in Obsidian's graph view directly.
- `terminology.md` becomes the project's glossary.

A small Obsidian-flavored override:

- Use `[[id]]` style links in entity bodies (instead of plain markdown).
- Add `aliases:` field to front matter for common variations.
- Mark major sections with `<!-- @section -->` for `doc-markdown-standards`
  compatibility.

## With `book-to-knowledge-graph`

The two pipelines share the *graph* output format conceptually but target
different inputs:

- `book-to-knowledge-graph` ingests long-form prose; output entities are
  characters, places, events, themes.
- `project-knowledge-base` (this skill) ingests code + docs; output
  entities are features, modules, services, abstractions.

The exporters can produce compatible JSON, JSON-LD, and Turtle from both
pipelines. A user comparing two systems' domain models (e.g. "how does the
auth feature compare to chapter 3 of the textbook on identity systems?")
can load both graphs into the same tool and reason across them.

## With CI / search

`relations.md` is machine-readable on purpose. Common downstream consumers:

- **Repository search** — a code search tool can query "find all features
  that depend on the database abstraction" by reading the relation manifest.
- **Architecture lint** — CI can detect when new code imports across module
  boundaries that the knowledge base says shouldn't exist.
- **Documentation freshness** — CI can compare `updated:` dates against
  recent git history and flag entities whose code has changed without the
  doc being updated.

These integrations are project-specific. The knowledge base exposes the
data; the project chooses what to do with it.
