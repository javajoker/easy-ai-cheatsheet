# Enterprise KB Access Control Policy

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Status:** active | draft | superseded
**Next annual review:** YYYY-MM-DD

---

## Classification scheme

| Level | Definition | Default ACL | Audit |
|---|---|---|---|
| **public** | Anyone with the URL can read | Anyone | Sampled |
| **internal** *(default)* | Anyone in the org | Authenticated org member | Sampled |
| **restricted** | Named roles only | Members of named role(s) | All |
| **confidential** | Named individuals only | Members of named individual(s) | All + alert on access |
| **regulated** | Bound by external compliance | Per regulatory regime | All + retention per regime |

**Key rule:** every promoted entity has an explicit classification.
Missing `classification` field → promotion rejected. Default-to-
internal applies only when explicitly set, never to absent values.

---

## Per-classification access rules

### public

- Readable by: anyone with the URL.
- Promotion to public: **requires governance authority sign-off**
  (never default; never owner's unilateral decision).
- Examples: public-facing product docs, published terminology,
  public partner announcements.

### internal (default)

- Readable by: any authenticated org member.
- Promotion: by entity owner (default).
- Examples: most technical decisions, terminology, runbooks,
  product internals.

### restricted

- Readable by: named role(s) listed in the entity's frontmatter
  `acl` field.
- Examples: team-specific runbooks, business-unit info,
  security details.

### confidential

- Readable by: named individuals listed in entity's `acl` field.
- Examples: HR matters, legal cases, M&A, security incident
  details.
- Alert on every access.

### regulated

- Readable per regulatory regime (HIPAA-covered entities only
  to HIPAA-covered roles, etc.).
- Examples: PHI, PCI cardholder data, GDPR-sensitive personal
  data.

---

## Per-classification redaction policy

When a caller's principal classification is **below** the entity's
classification:

| Caller → Entity | Default policy |
|---|---|
| any → public | n/a (anyone can read public) |
| anonymous → internal | refuse + log |
| internal → restricted | refuse |
| internal / restricted → confidential | log + refuse |
| any → regulated | log + alert + refuse |

**"refuse"** means the entity / chunk is **omitted** from
retrieval results — not redacted; fully absent. Below-
classification callers don't even know the entity exists.

---

## Per-entity overrides

Entity can override defaults via frontmatter:

```yaml
---
id: secret-roadmap
classification: confidential
acl:
  individuals: [ceo@example.com, cto@example.com]
  roles: []
acl_audit: alert  # every access pages security
---
```

Or:

```yaml
---
id: team-x-runbook
classification: restricted
acl:
  individuals: []
  roles: [team-x, ops-oncall]
---
```

### Tighten vs loosen

- **Tighten** (e.g. `internal` → `confidential`) — owner can do
  unilaterally.
- **Loosen** (e.g. `confidential` → `internal`) — requires
  governance authority sign-off + documented rationale.

---

## Audit log

**Destination:** <log destination from `devops-observability`>

**Retention:**

| Classification | Retention |
|---|---|
| public / internal | 90 days |
| restricted | 1 year |
| confidential | 2 years |
| regulated | Per regulatory regime (HIPAA: 7y; PCI: 1y; etc.) |

**Fields logged per access:**

- `timestamp` (UTC, ISO 8601)
- `principal_id` (service / human / agent identity)
- `principal_classification` (caller's max access level)
- `entity_id` (what entity was accessed)
- `entity_classification` (entity's classification)
- `outcome` (success / denied / refused)
- `query` (hashed if originating query may contain PII)
- `source` (IP / pod / CI run / agent session)
- `correlation_id` (for tracing across systems)

---

## Anomaly alerts

| Alert | Trigger | Routing |
|---|---|---|
| Off-hours human read of restricted+ | Human principal, outside 09:00–17:00 local, on restricted/confidential/regulated | Slack `#kb-anomalies` + security on-call PagerDuty if confidential+ |
| Unusual principal | Principal not in this entity's historical access pattern (last 90d) | Slack `#kb-anomalies` |
| High-frequency access | Rate >10× baseline for this principal | Slack `#kb-anomalies` |
| Read failure spike | >5 denials from same principal in 1h | Slack `#kb-anomalies` + security on-call |
| Regulated entity access without context | Regulated entity accessed without required context (e.g. PHI without patient relationship) | Security on-call PagerDuty |

---

## Quarterly access audits

Every quarter, governance reviews:

- **Classification audit.** Are entities classified correctly?
  Spot-check 5% sample + 100% of new entities since last audit.
- **ACL audit.** Are role memberships current? Departed
  principals removed from sensitive ACLs?
- **Access pattern audit.** Who actually accessed restricted /
  confidential entities? Was access appropriate?
- **Anomaly review.** Were alerts triggered? Were they real?
  Tune thresholds if too many false positives.
- **Retention check.** Old logs aged out per retention policy?

Audit findings produce action items in
[`audit-log-schema.md`](audit-log-schema.md).

---

## Roles vocabulary (org-specific; adapt)

Common role definitions (define org-wide so ACLs resolve):

| Role | Members | Use cases |
|---|---|---|
| `eng-all` | All engineering | General eng KB access |
| `eng-security` | Security team | Security runbooks, vuln disclosures |
| `eng-platform` | Platform team | Platform decisions, infra runbooks |
| `eng-on-call` | On-call rotation | All operational runbooks |
| `product-all` | All product managers | Product decisions, customer info (non-sensitive) |
| `customer-success` | CS team | Customer entities |
| `legal` | Legal team | Legal matters, contracts |
| `finance` | Finance team | Financial entities, customer-billing |
| `leadership` | Executive team | Strategic decisions, confidential matters |
| `governance` | KB governance | Sunset, promotion, override approval |

Role definitions live in `<org>/access-roles.yaml` and are
referenced by the access-control system.

---

## Anti-patterns

- **Public default.** Sensitive content leaks. Always default to
  `internal`.
- **ACL at the LLM layer only.** Restricted content reaches the
  LLM; the LLM is asked to be discreet; unreliable. Filter at
  retrieval.
- **Coarse two-level scheme** (public / private). Five-level
  scheme balances over-restriction vs over-grant.
- **No audit log.** Sensitive access invisible.
- **Audit log without anomaly alerts.** Logs without alerts =
  post-incident archaeology, not security.
- **Permanent ACLs.** Role memberships drift; quarterly audit
  required.
- **No sign-off for public promotion.** Public is deliberate;
  not a default.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial lock | <name> |
