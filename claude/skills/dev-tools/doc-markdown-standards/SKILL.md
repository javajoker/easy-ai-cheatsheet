---
name: doc-markdown-standards
description: Use when creating or editing markdown documents in projects that have opted into the Obsidian-flavoured documentation convention — enforces full Front Matter (id, type, status, tags, related), WikiLink internal links, `@section` markers, declared document relationships, and docs-index.md maintenance. Skip this skill for projects using the framework default (plain markdown links) — those follow the lighter `INSTRUCTIONS/markdown-conventions.md` directly. Trigger phrases include "write a design doc", "create a PRD", "add documentation", "update the docs index", or any time a `.md` file is created or substantially edited in an Obsidian-style project.
project-specific: opt-in (Obsidian convention)
---

# Markdown Documentation Standards (Obsidian-flavoured)

## Overview

This skill enforces an Obsidian-flavoured documentation convention. **Core goal:
eliminate information silos by making document relationships explicit and using
WikiLinks for all internal references.**

This is an *opt-in extension* of the framework's default markdown conventions
(see `INSTRUCTIONS/markdown-conventions.md`). Plain-markdown projects do not
need this skill.

## The four hard rules

1. **Front matter is required and complete** — every required field present.
   See `front-matter-ref.md`.
2. **`related` is non-empty** — at least one relation declared, with both
   directions filled in. If there is a hierarchy, fill `parent` / `children`.
3. **Internal links use `[[WikiLink]]`** — never `[text](path.md)` inside body
   prose or the `## Related` section.
4. **`docs-index.md` is updated on every doc change** — provide both the
   index-table row and the keyword-table row.

## Reference files

| Need | File |
|---|---|
| Full Front Matter schema, ID conventions, document types, relation types | `front-matter-ref.md` |
| Complete document template (copy-paste ready) | `document-template.md` |
| Verification checklist + AI output format + docs-index update format | `checklist.md` |

## Common mistakes

| Mistake | Correct |
|---|---|
| `related: []` left empty | Find at least one related document in the same domain |
| `[doc](./doc.md)` internal link | `[[doc-id\|display text]]` |
| Skipped updating `docs-index.md` | Always provide the index update snippet |
| Forgot to bump `updated:` | Update the date on every edit |
| No `## Related` section | Required at the end of every document, in WikiLink format |
| Skipped `<!-- @section -->` markers | All major sections should be marked |

## Relationship to framework defaults

- Framework default: plain markdown links, optional front matter, `## Related`
  with `[text](path)` links. Defined in `INSTRUCTIONS/markdown-conventions.md`.
- This skill: Obsidian extension with WikiLinks, required `related`, index
  maintenance, section markers.

A project opts into this skill by referencing it in its own `CLAUDE.md` and
by adopting the document layout described in `front-matter-ref.md`. Mixing
the two conventions inside one project will fragment the link graph and
break Obsidian's graph view — pick one.
