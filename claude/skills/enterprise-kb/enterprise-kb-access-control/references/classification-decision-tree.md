# KB Entity Classification Decision Tree

How to classify a new canonical entity. Walk the tree top-to-
bottom; first match wins.

```
Is the entity bound by external regulation (HIPAA / PCI / GDPR-sensitive)?
├── YES → regulated
└── NO  → continue

Does the entity contain personally identifiable information of named individuals (not just role names)?
├── YES → Is the audience necessarily limited to specific individuals?
│        ├── YES → confidential
│        └── NO  → restricted (with PII redaction at retrieval)
└── NO  → continue

Does the entity describe security details (auth, vulns, incident response, etc.)?
├── YES → restricted (eng-security role minimum)
└── NO  → continue

Does the entity describe a specific customer's terms, integrations, or financial details?
├── YES → confidential (account-owner + CS-team + leadership)
└── NO  → continue

Does the entity describe internal architecture or technical decisions?
├── YES → internal (default)
└── NO  → continue

Is the entity public-facing marketing / docs?
├── YES → public (requires governance sign-off for promotion)
└── NO  → internal (default)
```

## Examples

| Entity | Classification | Reason |
|---|---|---|
| `auth-service` (architecture) | internal | Technical detail; org members can see |
| `jwt-rotation-decision-2025` | restricted | Security-related |
| `tenant` (terminology) | internal | Org-wide concept |
| `customer-acme-corp` | confidential | Specific customer; CS + account owner only |
| `customer-acme-soc2-audit` | regulated | Compliance evidence; HIPAA-PHI if applicable |
| `incident-2026-03-12-postmortem` | restricted | Operational detail; eng + on-call |
| `pricing-tiers-2026` | internal (or public if published) | Internal by default; deliberate promotion to public |
| `team-engineering-roster` | internal | Org chart; org-wide |
| `cto-1on1-notes` | confidential | Individuals only |
| `hipaa-controls-attestation` | regulated | HIPAA evidence |
| `public-changelog-2026-q2` | public | Published externally |

---

## Special-case patterns

### Decision entities

| Decision sub-type | Default classification |
|---|---|
| architectural (low-risk) | internal |
| architectural (security-touching) | restricted |
| strategic | restricted (leadership + product) |
| compliance (HIPAA-touching) | regulated |
| compliance (other) | restricted |
| tactical | internal |
| experiment | internal |

### Runbook entities

| Runbook sub-type | Default classification |
|---|---|
| incident (general) | restricted (eng + on-call) |
| incident (security-class) | restricted (eng-security + on-call) |
| operational | restricted (eng-platform + on-call) |
| drill | restricted (drill participants) |
| recovery | restricted (DR-team + leadership) |

### Customer entities

| Customer sub-type | Default classification |
|---|---|
| enterprise | confidential (account-owner + CS + leadership) |
| mid-market | restricted (CS-team) |
| smb | internal |
| partner-customer | confidential |

---

## When in doubt — classify higher

A wrongly-too-restrictive classification:

- Minor inconvenience for legitimate consumers.
- Easily corrected by loosening (with sign-off).
- No data leak risk.

A wrongly-too-permissive classification:

- Real data leak risk.
- Hard to detect after the fact.
- Can require security incident response, customer notification,
  regulatory disclosure.

**Default to higher (more restrictive) classification when
uncertain.** Loosening is a deliberate, documented action via
governance.

---

## Loosening process

To loosen an entity's classification (e.g. `restricted` →
`internal` or `internal` → `public`):

1. **Owner proposes** the loosening with rationale.
2. **Governance reviews** — is the rationale sound? Are the
   contents actually appropriate at the new level?
3. **Sign-off recorded** in the entity's change log:
   ```markdown
   ## Change log
   | Version | Date | Change | By |
   |---|---|---|---|
   | 1 | 2025-08-22 | initial; classification: restricted | jane@ |
   | 2 | 2026-05-10 | reclassified to internal | jane@ (with gov approval from john@) |
   ```
4. **Audit log notes the change** with the approver.

---

## Reclassification triggers

Periodic re-classification may be needed:

- **Regulation change.** New compliance regime applied to existing
  entities → re-classify affected entities.
- **Public release.** Entity previously internal → published in
  product changelog → re-classify to public.
- **Sunset.** Sunset entities may need re-classification (historical
  decisions may be sharable as case studies).
- **Audit finding.** Audit reveals over- or under-classification →
  re-classify affected entities.

Reclassification follows the same loosening / tightening process.

---

## Anti-patterns

- **Classifying after promotion.** Classification is part of
  promotion; rejected entities don't promote. Don't ship to
  canonical first and classify later.
- **Bulk classification without review.** "Set all customer
  entities to internal" — without per-entity review, some end
  up classified wrong.
- **Owner-decides everything.** Owner can tighten unilaterally;
  loosening requires governance.
- **No documented rationale.** Classification without rationale
  → future reclassifications re-litigate.
