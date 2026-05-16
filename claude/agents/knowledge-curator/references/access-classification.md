# Access Classification (agent-level reference)

The 5-level classification scheme used by every canonical entity.
Defined by `enterprise-kb-access-control`; enforced at retrieval
by `enterprise-kb-search-index`.

## The five levels

| Level | Definition | Default ACL | Audit |
|---|---|---|---|
| **public** | Anyone with the URL can read | Anyone | Sampled |
| **internal** *(default)* | Anyone in the org | Authenticated org member | Sampled |
| **restricted** | Named roles only | Members of named role(s) | All |
| **confidential** | Named individuals only | Members of named individual(s) | All + alert on access |
| **regulated** | Bound by external compliance | Per regulatory regime | All + retention per regime |

## Key rules

- **Default is `internal`.** Promoting to `public` is a deliberate
  action requiring governance sign-off.
- **Classification at promotion** — `enterprise-kb-merge` rejects
  entities without a classification (default does not silently
  apply to missing field).
- **Per-entity override** — tighten anytime; loosen requires
  governance authority.
- **Retrieval enforces ACLs** — not the LLM layer. Restricted
  content is filtered out of retrieval results below the caller's
  classification.

## Redaction policy table (when caller < entity classification)

| Caller → Entity | Default policy |
|---|---|
| anonymous → internal | refuse + log |
| internal → restricted | refuse |
| internal/restricted → confidential | log + refuse |
| any → regulated | log + alert + refuse |

## What the agent guarantees

When the curator declares the access-control workstream done:

- Every canonical entity has a classification (none default-applied).
- ACLs implemented at the retrieval client layer.
- Audit log routes to the chosen observability backend.
- Anomaly alerts wired for off-hours / unusual-principal / probing.
- Quarterly access audit cadence scheduled.

See [`skills/enterprise-kb/enterprise-kb-access-control/SKILL.md`](../../../skills/enterprise-kb/enterprise-kb-access-control/SKILL.md)
for the full enforcement model.
