# Document Standards — quick reference

> Full conventions in `../markdown-conventions.md`. This file is the quick
> reference. On conflict, `markdown-conventions.md` wins.

## Required front-matter fields

| Field | Notes |
|---|---|
| `id` | `{type}-{topic}-{seq}`, e.g. `design-auth-flow-001`. |
| `title` | Human-readable. |
| `type` | `spec` \| `design` \| `api` \| `guide` \| `tutorial` \| `reference` \| `runbook`. |
| `status` | `draft` \| `review` \| `published` \| `archived`. |
| `created` | `YYYY-MM-DD`. |
| `updated` | `YYYY-MM-DD`. Bump on every edit. |
| `tags` | Non-empty list. |

Optional but encouraged: `aliases`, `related`, `category`, `parent`, `children`.

## Cross-references — pick one per project

Default: plain markdown links — `[descriptive text](relative/path.md)`.

Obsidian-flavoured project override: `[[id]]` or `[[id|display text]]`. If a
project uses WikiLinks, it does so consistently — do not mix styles.

## Section markers (optional, for long docs)

```markdown
<!-- @section: architecture -->
## Architecture
...
<!-- @end-section -->
```

## After-generation output

When Claude has generated or substantially edited a documentation file, it
should surface:

1. **Document meta** — id, path, type, status.
2. **Index update** — if the project maintains an index file
   (`docs/docs-index.md` or equivalent), the exact line to add.
3. **Related document list** — links from `related:` resolved to paths.

---

**Version**: 2.0.0
**Updated**: 2026-05-13
