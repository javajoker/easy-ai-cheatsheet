# Enterprise KB Architecture

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Decision authority:** <name>
**Status:** active | draft | superseded

---

## Org context

- Org shape: single product | multi-product suite | agency-style | other
- Primary KB consumers: AI features | human navigation | compliance | all
- Compliance regime(s): <list>

---

## Top-level taxonomy

```
enterprise-kb/
├── entities/
│   ├── products/        # <sub-types: shipped / sunset / experimental>
│   ├── teams/           # <sub-types: engineering / product / ops / leadership>
│   ├── decisions/       # <sub-types: architectural / strategic / compliance / tactical>
│   ├── terminology/     # <sub-types: canonical / domain / external>
│   ├── runbooks/        # <sub-types: incident / operational / drill>
│   ├── customers/       # <sub-types: enterprise / SMB / partner-customer>
│   └── partners/        # <sub-types: integration / vendor / channel>
├── relations.md
├── source-manifest.md
├── refresh-policy.md
├── access-control.md
├── search-index/
└── governance.md
```

**Domain rationale.** <one paragraph per adapted-from-default decision>

---

## Entity contract

Every canonical entity has frontmatter with these **base required**
fields:

| Field | Type | Purpose |
|---|---|---|
| `id` | kebab-case string | stable; never changes |
| `name` | string | human-readable |
| `domain` | enum | one of the 7 top-level domains |
| `type` | enum (per domain) | sub-type within domain |
| `owner` | string | named individual or team |
| `status` | active / deprecated / sunset | lifecycle |
| `classification` | public / internal / restricted / confidential / regulated | access control |
| `updated` | YYYY-MM-DD | last modification |
| `created` | YYYY-MM-DD | first creation |
| `sources` | list | what fed this entity (per-project KB, book, memory, external) |
| `aliases` | list | other names |
| `related` | list of ids | cross-entity links |

### Per-domain extra required fields

| Domain | Sub-type | Extra required fields |
|---|---|---|
| products | shipped | `launch_date`, `tier_table` |
| products | sunset | `sunset_date`, `successor_id` (optional) |
| teams | * | `members` (list) |
| decisions | architectural | `affected_components` (list) |
| decisions | strategic | `decision_authority` |
| decisions | compliance | `regulatory_anchor` |
| terminology | * | `definition`, `usage_examples` |
| runbooks | incident | `severity_class`, `first_responder` |
| customers | enterprise | `contract_tier`, `account_owner` |
| partners | integration | `integration_path`, `sla_tier` |

---

## Promotion criteria

A per-project entity promotes to canonical when ANY of:

- Appears in ≥2 project KBs.
- Named in a strategic / architectural decision memory.
- Referenced in a public artifact (docs site, marketing).
- Referenced by an external partner / customer.
- Specifically requested for promotion (with documented rationale).

**Promotion is owned by:** the source-project owner (proposes) +
the curator (approves).

---

## Sunset criteria

A canonical entity sunsets when ANY of:

- Owner unassignable for 90 days after last owner left.
- No references in active artifacts for 12 months.
- Underlying subject decommissioned (product killed, partner
  ended, team dissolved).
- Explicit retirement request.

**Sunset != delete.** Retired entities become read-only with
`status: sunset`, optional `successor_id`, and remain in the
audit trail.

---

## Source manifest pointer

See [source-manifest.md](source-manifest.md) for the live list
of sources. The manifest is updated by `enterprise-kb-merge` at
each sync; this architecture document is updated only when new
*kinds* of sources are added (e.g. adding "external system"
sources for the first time).

---

## Re-architecture triggers

Architecture is locked but revisitable. Re-architect when:

- Org shape fundamentally changes.
- Compliance regime expands materially.
- Merge skill fails repeatedly because taxonomy doesn't fit.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial lock | <name> |
