# Cross-Reference Rewrite Cookbook

Patterns for rewriting cross-references when an entity promotes
from per-project to canonical. Per-project references should
link *up* to canonical; canonical should link *down* to all
source instances.

## Pattern 1 — Markdown links

### Before (per-project KB)

```markdown
See [Auth Service](../services/auth.md) for details.
```

### After (rewritten to point at canonical)

```markdown
See [Auth Service](/enterprise-kb/entities/products/auth-service.md)
for details.
```

### Rewrite logic

For each markdown link in the source KB, if the target maps to a
canonical entity:

1. Replace the target path with the canonical entity's path.
2. Preserve the link text (the human label may differ from the
   canonical entity name).
3. Add to the canonical entity's `sources` frontmatter list.

---

## Pattern 2 — Wiki-style references (Obsidian, etc.)

### Before

```markdown
The flow uses [[auth-service]] to validate tokens.
```

### After

```markdown
The flow uses [[/enterprise-kb/entities/products/auth-service|auth-service]] to validate tokens.
```

(Or, depending on tool: `[[auth-service]]` resolved at render
time via a configured shortcut to the enterprise-kb path.)

---

## Pattern 3 — YAML / JSON frontmatter relations

### Before (per-project entity)

```yaml
---
id: stardust-token-rotation
related:
  - auth-service   # local reference
---
```

### After

```yaml
---
id: stardust-token-rotation
related:
  - auth-service   # now resolves to canonical entity
---
```

The IDs are stable — the canonical entity keeps the same ID it
had pre-promotion (provided the promotion was clean). Relations
continue to resolve.

If the canonical was renamed during promotion (alias resolution),
the original ID becomes an alias of the canonical. Tooling should
resolve aliases at lookup time so existing references continue
to work.

---

## Pattern 4 — Source-back-link on canonical entity

### Canonical entity body

```markdown
# Auth Service

## Where it appears

- `coolshell` KB — [`services/auth.md`](https://github.com/x/coolshell/blob/main/docs/knowledge-base/services/auth.md)
- `stardust` KB — [`services/auth.md`](https://github.com/x/stardust/blob/main/docs/knowledge-base/services/auth.md)
- Memory entry: `project:stardust / auth_service_v2_decision`
```

The canonical entity's body lists every source instance with a
direct link back to the source-of-origin. Bidirectional
navigation.

---

## Pattern 5 — Wiki redirects (per-project KB → canonical)

For per-project KBs, leave a redirect file at the original
location:

### `coolshell/docs/knowledge-base/services/auth.md`

```markdown
---
redirect_to: /enterprise-kb/entities/products/auth-service
---

This page has moved to the enterprise knowledge base:
[/enterprise-kb/entities/products/auth-service](/enterprise-kb/entities/products/auth-service)

(Local references now resolve to the canonical entity.)
```

Redirect files are valid for ~6 months post-promotion; then
cleaned up.

---

## Pattern 6 — Search-index aliases

The canonical entity's `aliases` list is indexed by
`enterprise-kb-search-index` so retrieval finds the canonical
entity by either name:

```yaml
aliases:
  - Auth
  - Identity Service
  - Workspace Auth        # legacy name from acquired product
```

A search for "Workspace Auth" returns the canonical `auth-service`
entity — no broken-link surprise for the searcher.

---

## Pattern 7 — Code references

For references **in code** (comments, docstrings) to KB entities:

### Before

```python
# See coolshell wiki: services/auth.md
def validate_token(token: str) -> bool:
    ...
```

### After (option 1 — update comments)

```python
# See enterprise KB: /enterprise-kb/entities/products/auth-service
def validate_token(token: str) -> bool:
    ...
```

### After (option 2 — stable ID reference)

```python
# Entity: kb:auth-service
def validate_token(token: str) -> bool:
    ...
```

Option 2 (stable ID) is preferred — KB structure can change; IDs
are stable.

---

## Atomic rewriting discipline

When promoting an entity:

1. **Snapshot the source state** before any rewrites.
2. **Apply rewrites in a single transaction** — either all
   succeed or none do.
3. **Verify cross-reference integrity** — no broken links after
   rewrite (CI step: link-checker).
4. **Commit with a clear message** — `kb: promote auth-service
   to canonical; rewrite N references`.

Partial rewrites leave the KB in a broken state. Use a tool that
batches the writes (or atomic-commit via git).

---

## Verification

Post-rewrite, run a link-checker:

```bash
# Markdown link checker
markdown-link-check 'enterprise-kb/**/*.md' --quiet

# Per-source rewrites verified
find <source-kb> -name '*.md' -exec markdown-link-check {} \;
```

Any broken link = the rewrite missed a reference. Fix before
declaring merge done.

---

## Anti-patterns

- **Silent rewrites.** Source-of-origin KBs should know they got
  rewritten. Use git commits with clear messages, not silent
  edits.
- **No source back-links.** Canonical entities should reference
  their sources; otherwise the audit trail is broken.
- **Rewrites outside merge.** Editing per-project KBs to link to
  canonical entities should happen *during* the merge, not as a
  follow-up task. Follow-ups don't happen.
- **Hard-coded paths in app code.** App code references to KB
  entities should use stable IDs; paths change.
