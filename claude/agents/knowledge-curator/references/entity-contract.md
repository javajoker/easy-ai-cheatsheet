# Entity Contract (agent-level reference)

Every canonical entity in the enterprise KB has this frontmatter
contract. Defined by `enterprise-kb-architecture`; enforced at
promotion time by `enterprise-kb-merge`.

## Base required fields

```yaml
---
id: <kebab-case-stable-id>          # canonical; never changes
name: <human-readable name>
domain: products | teams | decisions | terminology | runbooks | customers | partners
type: <sub-type within domain>
owner: <named individual or team>   # mandatory; unowned cannot promote
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
related:                            # links to other canonical entities by id
  - <id>
---
```

## Per-domain extra required fields

| Domain | Sub-type | Extra required |
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

## Body structure

```markdown
# <Name>

## Definition

<one paragraph; canonical definition>

## Context

<background; why this entity exists in the KB>

## Where it appears

<per-source list — which project KBs, which docs, which features>

## See also

<cross-references within KB and to authoritative external sources>
```

## Enforcement

`enterprise-kb-merge` refuses to promote an entity missing any
required field. The default-to-`internal` classification rule
**only** applies if classification is explicitly set; an entity
with no `classification` field is rejected outright.

See [`skills/enterprise-kb/enterprise-kb-architecture/SKILL.md`](../../../skills/enterprise-kb/enterprise-kb-architecture/SKILL.md)
for the canonical definition.
