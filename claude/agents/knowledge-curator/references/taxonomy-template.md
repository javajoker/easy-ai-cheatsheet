# Taxonomy Template (agent-level pointer)

The canonical taxonomy template lives in `enterprise-kb-architecture`:
[`skills/enterprise-kb/enterprise-kb-architecture/references/architecture-template.md`](../../../skills/enterprise-kb/enterprise-kb-architecture/references/architecture-template.md).

## Default 7-domain taxonomy (recap)

```
enterprise-kb/entities/
├── products/        # shipped / sunset / experimental
├── teams/           # engineering / product / ops / leadership
├── decisions/       # architectural / strategic / compliance / tactical
├── terminology/     # canonical / domain / external
├── runbooks/        # incident / operational / drill
├── customers/       # enterprise / SMB / partner-customer
└── partners/        # integration / vendor / channel
```

## Adaptation guide

| Org shape | Adjustment |
|---|---|
| Single product | Replace `products` with `subsystems` |
| Multi-product suite | Default works |
| Agency-style | Replace `products` with `projects`; add `engagements` |
| Open-source heavy | Add `contributors` alongside `teams` |
| Regulated industry | Add `compliance` alongside `decisions` |

Adapt **before** locking the architecture, never after — re-merging
under a changed taxonomy is expensive.

## What the agent guarantees

When the curator declares the architecture workstream done:

- Taxonomy locked with rationale per adapted-from-default decision.
- Empty directory tree scaffolded.
- Entity contract documented per domain.
- Promotion + sunset criteria written.
- Re-architecture triggers list documented.
