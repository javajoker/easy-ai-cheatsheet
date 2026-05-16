# Domain Catalogues — sub-types per top-level domain

Sub-type vocabulary per top-level domain. Defining sub-types per
domain makes the entity contract enforceable + queryable.

## products

| Sub-type | Definition | Extra required fields |
|---|---|---|
| `shipped` | Live product available to customers | `launch_date`, `tier_table` |
| `sunset` | Retired product; preserved for audit | `sunset_date`, `successor_id` (optional) |
| `experimental` | Beta / experimental; behind feature flag | `flag_name`, `cohort` |
| `internal` | Internal-only product (admin tools, internal services) | `audience` |

## teams

| Sub-type | Definition | Extra required fields |
|---|---|---|
| `engineering` | Engineering teams | `manager`, `members` |
| `product` | Product management teams | `manager`, `members` |
| `ops` | Operations / SRE / DevOps | `manager`, `members`, `on_call_rotation` |
| `leadership` | Leadership cohort | `members` |
| `cross-functional` | Spans engineering + product + design | `members`, `lead` |

## decisions

| Sub-type | Definition | Extra required fields |
|---|---|---|
| `architectural` | Cross-cutting technical decisions | `affected_components` |
| `strategic` | Business strategy decisions | `decision_authority` |
| `compliance` | Decisions driven by regulatory requirements | `regulatory_anchor` |
| `tactical` | Implementation-level decisions worth recording | `scope_components` |
| `experiment` | Time-boxed experiments with success criteria | `hypothesis`, `success_criteria`, `end_date` |

## terminology

| Sub-type | Definition | Extra required fields |
|---|---|---|
| `canonical` | Org-wide canonical definitions | `definition`, `usage_examples` |
| `domain` | Domain-specific terminology (per product domain) | `definition`, `domain_scope` |
| `external` | Industry / standards terms we adopt | `definition`, `source_authority` |
| `deprecated` | Terms we no longer use; preserved for context | `replacement_term` |

## runbooks

| Sub-type | Definition | Extra required fields |
|---|---|---|
| `incident` | Incident response runbooks | `severity_class`, `first_responder` |
| `operational` | Routine operational procedures | `frequency`, `owner` |
| `drill` | Game-day exercise scripts | `last_rehearsed`, `injection_method` |
| `recovery` | Disaster recovery procedures | `rto_target`, `rpo_target` |

## customers

| Sub-type | Definition | Extra required fields |
|---|---|---|
| `enterprise` | High-touch enterprise accounts | `contract_tier`, `account_owner` |
| `mid-market` | Mid-tier; lighter touch | `account_owner` |
| `smb` | Self-serve small business | `tier` |
| `partner-customer` | Customers who also resell / build on us | `partnership_type` |

## partners

| Sub-type | Definition | Extra required fields |
|---|---|---|
| `integration` | Products that integrate with us | `integration_path`, `sla_tier` |
| `vendor` | Vendors we consume | `vendor_type` (infra / saas / consulting) |
| `channel` | Resellers / channel partners | `commission_tier`, `geo` |
| `technology` | Tech partners (joint solutions, co-marketing) | `partnership_scope` |

---

## Choosing sub-types per project

Most projects use a subset of the default 7 domains. Per-project
adaptation lives in `enterprise-kb/ARCHITECTURE.md`. Sub-types
may also be added or removed:

- **Single-product orgs:** `products` becomes `subsystems`; sub-
  types become `service` / `library` / `worker`.
- **Agency-style orgs:** add `engagements` domain; sub-types
  `active` / `paused` / `completed`.
- **OSS-heavy orgs:** add `contributors` domain alongside `teams`.

## Adding a new sub-type

1. Propose in `enterprise-kb-architecture` review.
2. Define extra required fields.
3. Update this catalogue.
4. Update entity templates per the new sub-type.
5. `enterprise-kb-merge` rejects entities of the new sub-type
   until fields are filled.

## Anti-patterns

- **Sub-type proliferation.** Sub-types should be 3–5 per domain.
  More than 5 = under-specified categorisation. Reconsider.
- **Free-form `type` values.** Enum-only; if a new type is
  needed, add it to this catalogue.
- **Per-team sub-types.** Sub-types should be org-wide, not
  team-specific.
