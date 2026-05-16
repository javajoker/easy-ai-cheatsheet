---
name: enterprise-kb-access-control
description: Defines the access-control model for the enterprise KB — five-level classification scheme (public / internal / restricted / confidential / regulated), per-classification ACL rules with per-entity override capability, redaction policy for cross-classification retrieval (redact / refuse / log), audit log with retention + anomaly detection, and quarterly access audits. Non-negotiable default classification is internal; promoting to public is a deliberate action with sign-off. Output is enterprise-kb/access-control.md plus the ACL enforcement spec for enterprise-kb-search-index (which filters retrieval per principal) and the audit log spec for devops-observability. Use this skill before any sensitive content lands in the KB; or when the user says "set up access control", "we need to classify the entities", "what happens when a restricted entity is retrieved", "set up the audit log", "comply with HIPAA / GDPR for the KB". Pairs with enterprise-kb-architecture (entity contract includes classification field — both skills must agree on the enum), with enterprise-kb-merge (verifies classification on newly promoted entities), with enterprise-kb-search-index (retrieval layer enforces ACLs), with devops-observability (audit log → metrics + alerts), and with devops-security-hardening (KB ACL is part of the security baseline).
status: shipped
owner_agent: knowledge-curator
---

# Enterprise KB Access Control

Phase 5 of the `knowledge-curator` agent. Non-negotiable for
any KB that contains sensitive material (most do once they grow
past pure terminology).

> **Default to internal.** Promoting an entity to public is a
> deliberate action with sign-off — never a default. Public-by-
> default classification is a data-leak waiting to happen.

## Why this exists

KB access-control failures are predictable:

1. **Public-default leak.** New entity defaults to readable-by-
   anyone; sensitive content (customer info, internal
   strategies, security details) leaks via retrieval API.
2. **ACL only at the LLM layer.** Restricted content reaches
   the LLM with "please don't mention it"; LLM mentions it
   anyway; data exfiltration.
3. **No audit log.** Sensitive entity accessed by an unexpected
   principal; nobody notices until external alert.
4. **Coarse-grained ACLs only.** Either fully open or fully
   closed; no middle ground; teams either over-grant or over-
   restrict.
5. **No classification on entities.** ACLs can't be enforced
   without knowing what's sensitive; classification is the
   prerequisite.
6. **No quarterly review.** Classifications drift; new entity
   types added without classification; the model fragments.

This skill enforces a 5-level scheme, restrictive defaults,
audit-by-default, anomaly alerts, and quarterly review cadence.

## When to fire

Fire when:

- The enterprise KB will hold any non-public content
  (essentially always).
- The user says *"set up access control"*, *"classify the
  entities"*, *"what happens when a restricted entity is
  retrieved"*, *"comply with HIPAA / GDPR for the KB"*.
- A new compliance regime applies (regulated entity type
  needed).
- An access incident exposes a gap in the current policy.

Do **not** fire when:

- The KB is genuinely public-only (rare; verify with user).
- The team wants to query the KB, not configure access (use
  retrieval directly via the client from `enterprise-kb-
  search-index`).

## Inputs

Required:

- `enterprise-kb/ARCHITECTURE.md` — entity contract (the
  `classification` field is set here).
- `enterprise-kb/entities/` — current entities to classify.

Asked once (cap at 4):

1. **Compliance regime(s).** None / GDPR / HIPAA / SOC2 / PCI
   / industry-specific. Drives the `regulated` classification
   rules.
2. **Principal model.** What identifies a retrieval caller —
   API token / OAuth identity / service account / agent
   identity. Drives ACL implementation.
3. **Audit log destination.** Default: same observability
   stack as `devops-observability`. Override per compliance
   (some regulators require dedicated audit storage).
4. **Redaction tooling.** None (refuse instead) / PII
   detection library / vendor (e.g. Presidio / Vault
   transform).

## The five-level classification

| Level | Definition | Default ACL | Audit |
|---|---|---|---|
| **public** | Anyone with the URL can read | Anyone | Sampled |
| **internal** (default) | Anyone in the org | Authenticated org member | Sampled |
| **restricted** | Named roles only | Members of named role(s) | All |
| **confidential** | Named individuals only | Members of named individual(s) | All + alert on access |
| **regulated** | Bound by external compliance | Per regulatory regime | All + retention per regime |

**Key properties:**

- **public**: deliberate; sign-off required (default
  `knowledge-curator` agent's governance authority).
- **internal**: the default; no special handling required.
- **restricted**: typical for team-specific runbooks, business
  unit info.
- **confidential**: typical for HR, legal, M&A, security
  incident details.
- **regulated**: when compliance attaches (HIPAA-PHI, PCI-PAN,
  GDPR-sensitive). Triggers per-regime handling.

### Classification at promotion

`enterprise-kb-merge` verifies every promoted entity has a
classification. Entities without one cannot promote — the
default-to-internal applies only if explicitly set; absence is
not "assume internal", it's "blocked".

### Per-entity override

The classification is per-entity. Overrides:

- **Tighten** (e.g. mark an `internal` decision as
  `confidential` because it discusses a confidential customer
  deal) — anyone can tighten.
- **Loosen** (e.g. promote a `confidential` policy to
  `internal` because it's now broadly applicable) — requires
  named governance authority sign-off.

## The redaction policy

When a retrieval caller's principal is below the entity's
classification:

| Policy | Behaviour |
|---|---|
| **redact** | Return the chunk with sensitive fields removed; principal sees redacted version |
| **refuse** | Omit the chunk entirely (most common — invisible to caller) |
| **log + refuse** | As refuse + log the attempted access |
| **log + alert + refuse** | As log + refuse + page security on the access |

**Default per classification:**

| Caller classification < Entity classification | Default policy |
|---|---|
| any → public | n/a (anyone can read public) |
| anonymous → internal | refuse + log |
| internal → restricted | refuse |
| internal / restricted → confidential | log + refuse |
| any → regulated | log + alert + refuse |

The `enterprise-kb-search-index` retrieval client enforces this
at the retrieval layer (not at the application layer).

## The audit log

Every retrieval is logged with:

| Field | Purpose |
|---|---|
| `timestamp` (ISO 8601) | When |
| `principal_id` | Who (service / human / agent) |
| `principal_classification` | Caller's access level |
| `entity_id` | What entity was accessed |
| `entity_classification` | Entity's classification |
| `outcome` | success / denied / redacted |
| `query` (hashed if sensitive) | Why (search query) |
| `source` | Where (IP / pod / CI run / agent session) |
| `correlation_id` | Tying to broader trace |

Retention per classification:

| Classification | Retention |
|---|---|
| public / internal | 90 days |
| restricted | 1 year |
| confidential | 2 years |
| regulated | Per regulatory regime (often 7+ years) |

### Anomaly alerts

- **Off-hours human read** of restricted / confidential.
- **Unusual principal** accessing an entity (not in historical
  access pattern).
- **High-frequency** accesses (rate spike vs. baseline).
- **Repeated denials** from same principal (probing).
- **Regulated entity access** without compliance-required
  context (e.g. PHI access without patient relationship).

Alerts route per `devops-observability` (Slack channel +
security on-call for confidential / regulated).

## Quarterly access audits

Every quarter:

- **Classification audit:** Are entities classified correctly?
  Spot-check 5% sample + 100% of new entities since last
  audit.
- **ACL audit:** Are role memberships current? Departed
  principals removed from sensitive ACLs?
- **Access pattern audit:** Who actually accessed restricted /
  confidential entities? Was access appropriate?
- **Anomaly review:** Were alerts triggered? Were they real?
- **Retention check:** Old logs aged out per retention policy?

Audit findings produce action items (fix classifications,
update ACLs, tighten alerts). Recurring issues escalate to
`enterprise-kb-architecture` re-review.

## The procedure

### Phase 1 — Read architecture + entities

Pull the entity contract (verify `classification` field is in
the base required fields).

Inventory current entities by current classification (if any
exist).

### Phase 2 — Run a classification pass

For every existing entity:

- Assign classification (default `internal` unless evidence
  of needing higher or lower).
- Tag any compliance-regulated entities explicitly.
- Flag entities that are *currently* public — these need
  sign-off to remain public.

If the classification audit reveals patterns (e.g. all
`runbooks/security` should be `restricted`), encode as a rule
in the classification policy.

### Phase 3 — Define ACLs per classification

Per the table above; adjust per project.

For role-based ACLs (`restricted`), enumerate roles:

- `eng-all` — any engineer in the org.
- `eng-security` — security team only.
- `eng-platform` — platform team only.
- `business-finance` — finance team only.
- `legal-team` — legal team only.

For individual-based ACLs (`confidential`), enumerate principals
explicitly per entity (typically frontmatter override).

### Phase 4 — Implement enforcement

Hand off to `enterprise-kb-search-index` to wire ACL
enforcement at the retrieval layer:

- Retrieval client takes a `principal` parameter.
- Per result, classification compared to principal's access.
- Apply redaction policy per the table.
- Log the access per audit shape.

### Phase 5 — Wire the audit log

Hand off to `devops-observability`:

- Audit log destination (with per-classification retention).
- Anomaly alerts (per the alert list above).
- Dashboards: access volume by classification; denied access
  trends; anomaly count.

### Phase 6 — Define quarterly audit procedure

Write the procedure:

- Trigger (calendar — first Monday of each quarter).
- Audit checklist (per the audit list above).
- Findings → action items.
- Escalation if patterns repeat.

### Phase 7 — Emit access-control.md

Write `enterprise-kb/access-control.md` using
[references/access-control-template.md](references/access-control-template.md).

After writing:

1. Surface to user; especially flag any currently-public
   entities for sign-off.
2. Persist as `type: project` memory
   (`kb_access_control_v1`).
3. Hand off to:
   - `enterprise-kb-search-index` for retrieval-layer
     enforcement.
   - `devops-observability` for audit log infra.
   - `devops-security-hardening` to include KB ACL in the
     security baseline.
   - `knowledge-curator/governance.md` for governance
     authority assignment.

### Phase 8 — Watch for policy-failure triggers

The policy is failing when:

- Anomaly alerts fire frequently (real anomalies or false
  positives — both bad).
- Quarterly audit finds material misclassifications.
- Regulators flag compliance issues.
- Teams over-restrict (everything `confidential`) → KB unused.
- Teams over-grant (everything `internal`) → KB leaks.

Either failure mode triggers policy review.

## Anti-patterns

- **Public default.** Sensitive content leaks. Always default
  to internal.
- **ACL at the LLM layer only.** Restricted content reaches
  the LLM; the LLM is asked to be discreet; LLMs are not
  reliably discreet.
- **Coarse two-level scheme** (public / private). Forces over-
  restriction or over-grant. Five levels balances.
- **No audit log.** Sensitive access invisible. Always log.
- **Audit log without anomaly alerts.** Logs without alerts
  are post-incident archaeology, not security.
- **Permanent ACLs.** Role memberships drift; quarterly audit
  required.
- **Conflating sensitive with restricted-to-individuals.** Some
  entities are sensitive role-wide (use `restricted`); some are
  to individuals only (use `confidential`); some bound by
  regulation (use `regulated`). The scheme distinguishes.
- **No sign-off for public promotion.** Public is deliberate;
  not a default.

## Companion skills

- `enterprise-kb-architecture` — classification field in
  entity contract.
- `enterprise-kb-merge` — verifies classification at promotion.
- `enterprise-kb-search-index` — enforces ACLs at retrieval.
- `enterprise-kb-refresh-policy` — re-verifies classification
  at refresh.
- `devops-observability` — audit log + anomaly alerts.
- `devops-security-hardening` — KB ACL in security baseline.
- `memory-ontology` — persist policy decisions.
- `requirement-audit` — quarterly policy compliance audit.

## Reference files

- [references/access-control-template.md](references/access-control-template.md) —
  canonical policy document.
- `references/classification-decision-tree.md` — how to
  classify a new entity.
- `references/redaction-patterns.md` — per-PII-type redaction
  patterns (email, SSN, credit card, custom).
- `references/audit-log-schema.md` — exact audit log record
  shape for ingestion + querying.
