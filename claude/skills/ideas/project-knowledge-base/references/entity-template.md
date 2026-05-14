# Entity File Template

Copy this template per entity in the knowledge base. Replace placeholders;
remove unused sections.

```markdown
---
id: entity-<type>-<slug>-001
title: <Entity Name>
type: feature | module | service | abstraction | external | role | decision | term
status: active | deprecated | planned | decided
created: YYYY-MM-DD
updated: YYYY-MM-DD
related:
  - id: entity-<type>-<slug>-001
    relation: implements | implemented-by | uses | used-by | exposes | exposed-by | belongs-to | contains | evolves-from | evolves-into | referenced-by | references | decided-by | decides | integrates-with
code:
  - path/to/source.go
docs:
  - path/to/design.md
---

# <Entity Name>

<One-paragraph description. What this is, who uses it, why it exists. Use the
project's primary language for body content.>

## Where it lives

- `path/to/source.go` — primary implementation
- `path/to/handler.go` — HTTP binding
- `path/to/repo.go` — persistence
- (etc.)

## How it relates

<Plain-text walkthrough of the relations declared in front matter. Examples:

- Implements the [User Authentication](feature-auth.md) feature.
- Used by the [Order Processing](feature-orders.md) feature to verify
  identity before creating orders.
- Depends on the [Database](abstraction-database.md) abstraction to load
  user records.
- Exposed via the [HTTP API](service-http.md) service at `/auth/*`.>

## Open questions

<Anything the skill could not determine. Flag for the user to clarify in a
follow-up pass. Examples:

- Is rate limiting on `/auth/login` configured per IP or per user?
- The `legacy_auth.go` file is referenced from production code but not
  imported anywhere visible — confirm it is dead.>

## Decisions

<For type: decision only. The decision, the date it was made, the
rationale, the constraints it imposes.>
```

## Field reference

| Field | Required | Notes |
|---|---|---|
| `id` | yes | `entity-<type>-<slug>-001` — kebab-case, three parts, sequential. |
| `title` | yes | Human-readable name. |
| `type` | yes | One of the eight types. |
| `status` | yes | `active`, `deprecated`, `planned`, `decided` (for decisions). |
| `created` | yes | ISO date when the entity was first added to the knowledge base. |
| `updated` | yes | Bump on every edit. |
| `related` | yes | At least one relation. An orphan entity is rarely useful. |
| `code` | optional | List of code paths. Required for `module`, `service`, `abstraction`. |
| `docs` | optional | List of doc paths. Required for `decision`. |

## Slug conventions

- Lowercase, kebab-case.
- Singular noun where possible.
- Match the natural name used in the project's docs and code.
- Examples: `auth`, `payment-processing`, `user-profile`, `stripe`, `admin-role`.
