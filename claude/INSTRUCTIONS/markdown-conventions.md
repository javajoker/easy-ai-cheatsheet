---
applyTo: "**/*.md"
description: "Default markdown conventions for project documentation. Projects override via their own CLAUDE.md or projects/<name>/markdown-conventions.md."
---

# Markdown Conventions — default

This is the **default markdown contract** for documentation in any project
adopting this framework. A project that wants a different contract (e.g.
strict Obsidian, MkDocs, Docusaurus, Sphinx) overrides it by placing a more
specific file under `projects/<name>/markdown-conventions.md` and referencing
that file from the project's own `CLAUDE.md`.

The conventions below are the lowest-common-denominator: they work everywhere,
including plain markdown viewers, GitHub, GitLab, and most static site
generators.

## Front matter

Every documentation file has YAML front matter at the top:

```yaml
---
id: "{type}-{topic}-{seq}"        # required, e.g. design-auth-flow-001
title: "Human-readable title"      # required
type: spec | design | api | guide | tutorial | reference | runbook
status: draft | review | published | archived
created: YYYY-MM-DD
updated: YYYY-MM-DD                # bump on every edit
tags: ["tag", "tag"]               # required for findability
related:                           # optional but encouraged
  - id: "design-other-001"
    relation: implements | extends | references | depends-on | related-to
aliases: ["short name", "another"] # optional, helps search
---
```

A project that uses Obsidian, Dataview, Hugo, or another platform may extend
this with its own fields (e.g. `aliases`, `category`, `author`,
`parent`/`children`). The required fields above stay required everywhere.

## ID convention

`{type}-{topic}-{seq}` — kebab case, three parts.

- **type** — one of the values in the front matter `type` field.
- **topic** — short identifier, kebab case. Example: `auth-flow`, `redis-client`.
- **seq** — three-digit number, starting at `001`, to distinguish documents
  on the same topic.

Examples:

- `design-auth-flow-001`
- `api-user-endpoints-001`
- `spec-content-requirements-001`

## Section markers

For long documents that other tools need to extract from, mark major sections
with HTML comments so they remain readable as plain markdown and machine-parseable:

```markdown
<!-- @section: architecture -->
## Architecture
...
<!-- @end-section -->

<!-- @section: implementation -->
## Implementation
...
<!-- @end-section -->
```

Use sparingly — short documents do not need section markers.

## Cross-references

The default is **plain markdown links**: `[descriptive text](relative/path.md)`.

A project that adopts Obsidian-style WikiLinks (`[[id|text]]`) declares that
in its own `markdown-conventions.md` override. Do not mix conventions within
one project.

When linking by document ID, link to the actual file path; do not assume a
resolver exists in every viewer:

```markdown
See [auth flow design](../design/auth-flow.md) for the request/response shape.
```

If the project uses an `id`-based system, the override file specifies whether
to write `[design-auth-flow-001](path)` or `[[design-auth-flow-001]]`.

## "Related documents" section

Most documentation benefits from a trailing `## Related` section that lists
upstream and downstream documents:

```markdown
## Related

- [Auth subsystem overview](../overview.md) — parent doc.
- [API authentication endpoints](../../api/auth-endpoints.md) — implements this design.
```

If the project uses an index file (`docs-index.md` or similar), the
`related:` front matter field is the structured source of truth and the
"Related" section is rendered from it.

## Index files

If the project maintains a `docs/docs-index.md` (or equivalent), every new
document MUST update the index in the same commit. The skill
`doc-markdown-standards` enforces this for projects that opt in.

If the project does not maintain an index, do not invent one — let the file
system and the front matter `id` field be the index.

## Document type meanings

| Type | Meaning |
|---|---|
| `spec` | Requirements specification — *what* must be true. |
| `design` | Architectural or design document — *how* a solution works. |
| `api` | API reference — endpoints, parameters, response shapes. |
| `guide` | Walkthrough for performing a task. |
| `tutorial` | Step-by-step learning material. |
| `reference` | Lookup material — tables, glossaries, command lists. |
| `runbook` | Operational procedure for incidents or routine ops. |

## Relation semantics

| Relation | Meaning |
|---|---|
| `implements` | This document realizes a `spec` or `design`. |
| `extends` | This document adds to another (same scope, more detail). |
| `references` | This document cites another (loose link). |
| `depends-on` | Reader must understand the referenced doc first. |
| `related-to` | General sibling relation, no specific direction. |

## Code blocks

Always include a language tag. Untagged blocks bypass syntax highlighting and
hurt readability:

````markdown
```python
def example():
    return 42
```
````

For inline shell snippets, prefer `bash` or `sh` over no tag.

## After-generation checklist

After Claude generates or substantially edits a markdown file:

- [ ] Front matter is complete (id, title, type, status, created, updated, tags).
- [ ] `updated` has today's date.
- [ ] All cross-references use the project's chosen link style consistently.
- [ ] Code blocks have language tags.
- [ ] If the project uses an index file, it has been updated in the same edit.
- [ ] If the document declares `related:` entries, the linked documents exist.

## Project overrides

A project's `projects/<name>/markdown-conventions.md` can override:

- Whether to use Obsidian WikiLinks vs plain markdown links.
- Additional required front-matter fields.
- Project-specific section markers.
- Index file location and shape.
- Custom relation values.

It cannot override the universal pieces above (front matter is required,
language tags on code blocks, etc.).

---

**Version**: 2.0.0
**Updated**: 2026-05-13
