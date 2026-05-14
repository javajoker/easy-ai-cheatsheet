# Front Matter Reference

> Schema and conventions for the Obsidian-flavoured documentation extension.
> Lighter, plain-markdown defaults live in `INSTRUCTIONS/markdown-conventions.md`.

## Complete template

```yaml
---
id: "{type}-{topic}-{sequence}"     # required, e.g. spec-order-flow-001
title: "Document title"             # required
aliases: ["alias1", "alias2"]       # required for Obsidian alias search
type: "spec"                        # required, see document types table
category: "prd/wechat"              # required, directory path
tags: ["tag1", "tag2"]              # required, drives Obsidian tag graph
version: "1.0.0"                    # required
created: "YYYY-MM-DD"               # required
updated: "YYYY-MM-DD"               # required, bump on every edit
author: "<author>"                  # required
status: "draft"                     # required, see status values
parent: null                        # optional, parent doc id (hierarchy)
children: []                        # optional, child doc ids
related_docs:                       # strongly recommended; declare relations
  - id: "spec-admin-merchant-001"
    relation: "related_to"          # see relation types
    path: "../admin/merchant-admin-prd.md"
---
```

## Document types

| Value | Meaning |
|---|---|
| `spec` | Requirements specification / PRD |
| `design` | Design document |
| `api` | API documentation |
| `guide` | Development guide |
| `tutorial` | Tutorial / walkthrough |
| `reference` | Reference material |
| `runbook` | Operational procedure |

## Status values

`draft` → `review` → `published` → `archived`

## ID naming rules

Format: `{type}-{topic}-{sequence}`. Lowercase, kebab-case, three parts.

```
spec-miniapp-product-001
design-admin-order-flow-001
api-merchant-endpoints-001
guide-auth-setup-001
```

## Relation types

| Relation | Meaning | Typical use |
|---|---|---|
| `implements` | Realizes a spec document | Code design → PRD |
| `extends` | Extends another document | Submodule design → overall design |
| `references` | Cites another document | Current doc references another |
| `depends_on` | Depends on prerequisite knowledge | API doc → authentication spec |
| `related_to` | Same business domain | Miniprogram PRD ↔ admin PRD |

## Anti-silo rules

- **`related_docs` is non-empty.** Declare at least one relation. If a
  document truly has no peer, link it to the top-level index with
  `related_to`.
- **Relations are bidirectional.** If A `references` B, B's `related_docs`
  must also include A.
- **Hierarchy is explicit.** Documents in a parent-child structure fill
  `parent` and `children`.
