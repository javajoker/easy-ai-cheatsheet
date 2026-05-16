# Entity Contract — Worked Examples

Filled examples of the canonical entity contract per domain.
Copy + adapt for new entities.

## products/shipped — Auth Service

```markdown
---
id: auth-service
name: Auth Service
domain: products
type: shipped
owner: jane.doe@example.com
status: active
classification: internal
updated: 2026-05-15
created: 2024-03-01
launch_date: 2024-04-15
tier_table: see related-entity pricing-tiers
sources:
  - per-project-kb: stardust / docs/knowledge-base/services/auth
  - memory: project:stardust / auth_service_v2_decision
aliases:
  - Auth
  - Identity Service
related:
  - jwt-rotation-decision-2025
  - users-data-schema
---

# Auth Service

## Definition

The org-wide authentication service. Issues JWTs, validates them,
manages refresh-token rotation, integrates with SSO providers.

## Context

Standalone service extracted from the monolith in Q2 2024 (decision
`auth-extraction-2024`). Powers authentication for all products
under the `stardust` family.

## Where it appears

- `stardust` project — primary deployment.
- `dustmite` project — consumes via JWT validation.
- Public API docs at api.example.com/auth.

## See also

- `jwt-rotation-decision-2025` — refresh-token rotation policy.
- `users-data-schema` — user entity authoritative shape.
```

---

## decisions/architectural — JWT Rotation Decision 2025

```markdown
---
id: jwt-rotation-decision-2025
name: JWT Refresh-Token Rotation Policy 2025
domain: decisions
type: architectural
owner: security-team@example.com
status: active
classification: restricted
updated: 2025-08-22
created: 2025-08-22
affected_components: [auth-service, mobile-clients, web-clients]
sources:
  - per-project-kb: stardust / docs/knowledge-base/decisions/jwt-rotation
  - memory: project:stardust / jwt_rotation_2025_decision
aliases:
  - Refresh Token Single-Use
related:
  - auth-service
  - security-baseline-2025
---

# JWT Refresh-Token Rotation Policy 2025

## Definition

Refresh tokens are single-use: each refresh request issues a new
refresh token and invalidates the old. Reuse of an old refresh
token triggers immediate session revocation across all devices.

## Context

Adopted after the 2025-Q2 security review surfaced replay risk on
long-lived refresh tokens. Decision driven by SOC2 attestation
requirements.

## Where it appears

- `auth-service` implementation (token-rotation.go).
- Security baseline checklist row 4.3.
- Mobile + web client refresh handling.

## See also

- `security-baseline-2025` — full baseline this contributed to.
- `auth-service` — where rotation is implemented.
```

---

## terminology/canonical — Tenant

```markdown
---
id: tenant
name: Tenant
domain: terminology
type: canonical
owner: product-team@example.com
status: active
classification: internal
updated: 2026-05-10
created: 2024-01-15
definition: A logically isolated customer workspace; the unit of multi-tenancy + billing.
usage_examples:
  - "Each tenant has its own data namespace."
  - "Tenant admins can invite users."
  - "Tenant deletion is a 30-day soft-delete + 60-day purge."
sources:
  - per-project-kb: stardust / docs/knowledge-base/terminology/tenant
  - memory: global / tenant_definition_canonical
aliases:
  - Workspace
  - Organisation
  - Account
related:
  - user
  - billing-account
---

# Tenant

## Definition

A logically isolated customer workspace; the unit of multi-tenancy
+ billing. One tenant maps to one billing account; one tenant can
contain many users.

## Context

The canonical org-wide definition. **Not interchangeable** with
"user" (a person) or "billing-account" (a finance record),
although the three closely relate.

## Aliases

Different teams historically used different terms:
- "Workspace" (product team)
- "Organisation" (in some API responses, deprecated)
- "Account" (in pricing docs — being migrated to `tenant`)

All three retrieve to this canonical entity via the search index.

## Where it appears

- API: `/api/v1/tenants/`
- Database: `tenants` table
- Billing: `billing_accounts.tenant_id`
- All products under `stardust` family

## See also

- `user` — a person; can belong to multiple tenants.
- `billing-account` — finance record; 1:1 with tenant.
- `tenant-isolation-decision` — architectural decision on isolation strategy.
```

---

## runbooks/incident — Auth Service Down

```markdown
---
id: auth-service-down
name: Runbook — Auth Service Down
domain: runbooks
type: incident
owner: ops-team@example.com
status: active
classification: internal
updated: 2026-04-30
created: 2024-04-20
severity_class: SEV1
first_responder: on-call-platform
sources:
  - per-project-kb: stardust / runbooks/auth-service-down
  - memory: project:stardust / runbook_auth_down_v3
aliases:
  - "Auth Outage"
related:
  - auth-service
  - postmortem-template
---

# Runbook — Auth Service Down

## Definition

The 5-section runbook for responding when `auth-service` is
unavailable (all auth requests failing). SEV1.

## Context

Auth-service outage is total — every product depends on token
validation. Mitigation under 10 min is the SLA.

## Where it appears

Linked from:
- Alert `auth-service-up == 0` (Prometheus).
- Dashboard `auth-service-golden-signals`.
- On-call rotation README.

## See also

- `auth-service` — the system being supported.
- `postmortem-template` — template for SEV1 postmortem.
```

---

## customers/enterprise — Acme Corp

```markdown
---
id: acme-corp
name: Acme Corp
domain: customers
type: enterprise
owner: account-mgr-alice@example.com
status: active
classification: confidential
updated: 2026-05-01
created: 2024-09-15
contract_tier: enterprise-plus
account_owner: alice.smith@example.com
sources:
  - external: salesforce / 0011234567890
  - memory: project:stardust / customer_acme_v1
aliases: []
related:
  - acme-integration-2025
  - acme-soc2-audit-evidence
---

# Acme Corp

## Definition

Enterprise customer, Fortune 500 manufacturer. Adopted us
Q3 2024 for compliance + audit logging features.

## Context

(Restricted — see Salesforce for current contract terms.)

## Where it appears

- Salesforce account `0011234567890`.
- Compliance dashboard (SOC2 evidence trail).

## See also

- `acme-integration-2025` — the custom integration we built.
- `acme-soc2-audit-evidence` — audit evidence reference.
```

---

## Notes on classification per entity

- `products/shipped` — usually `internal` (technical detail); some
  marketing-mentioned features may be `public`.
- `decisions/architectural` — often `internal` or `restricted`;
  security-related decisions may be `confidential`.
- `terminology/canonical` — usually `internal`.
- `runbooks/incident` — almost always `restricted` (operational
  detail not for public).
- `customers/enterprise` — usually `confidential` (customer
  contract details).
- `partners/integration` — usually `internal`; some public partners
  may be `public`.

When in doubt, classify *higher* (more restrictive) and loosen
deliberately via the governance process.
