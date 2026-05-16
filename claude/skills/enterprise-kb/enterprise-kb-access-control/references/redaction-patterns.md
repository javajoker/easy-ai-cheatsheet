# Redaction Patterns — per PII type

When retrieval surfaces an entity at the caller's classification
but the content contains PII or sensitive fields above the
caller's level, redaction may apply (alternative to outright
refusal).

## Redaction policy decisions

Per the access-control policy, redaction is one of four
behaviours when caller's classification < entity's classification:

| Policy | Behaviour |
|---|---|
| `redact` | Return chunk with sensitive fields removed |
| `refuse` | Omit chunk entirely from results (default) |
| `log + refuse` | As refuse + log the attempted access |
| `log + alert + refuse` | As log + page security |

`redact` is rarer than `refuse`. The default for cross-
classification access is `refuse` because partial-content
retrieval can leak more than it intends (negative-space leakage:
"this exists but we can't show it" itself is information).

**When to use `redact`:** The entity is genuinely useful at a
broader classification with sensitive fields removed (e.g. a
customer playbook usable internally with the customer name
masked).

---

## PII type catalogue + redaction patterns

### Email addresses

**Pattern.** `[\w._%+-]+@[\w.-]+\.[A-Za-z]{2,}`

**Redaction.**

- Full: `alice@example.com` → `[REDACTED]`
- Partial (domain-preserving): `alice@example.com` → `[REDACTED]@example.com`
- Hash-preserving: `alice@example.com` → `<hash:a1b2c3>` (allows
  de-duplication without revealing identity)

### Phone numbers

**Pattern.** Various — `+1-555-555-5555`, `(555) 555-5555`, etc.

**Redaction.** Full: `+1-555-555-5555` → `[REDACTED]`.

### SSN / equivalent national IDs

**Pattern.** `\d{3}-\d{2}-\d{4}` (US SSN); regional variants.

**Redaction.** Always full redaction. Never partial — last-4-
digits exposure is enough for some attacks. SSNs in KB content
are usually a categorisation error; flag for re-classification.

### Credit card numbers

**Pattern.** 13–19 digit sequences passing Luhn check.

**Redaction.** Full: `4111111111111111` → `[REDACTED-CARD]`.

PCI compliance forbids unencrypted CC numbers in any log /
storage; KB should never contain raw CC numbers. If found,
file a security incident.

### Authentication tokens

**Pattern.** JWT-shaped (`eyJ...`); long random strings in
auth-related contexts; bearer tokens.

**Redaction.** Full: `eyJabc...` → `[REDACTED-TOKEN]`.

Like CC numbers, tokens in KB content are usually a leakage; flag
for security incident.

### Names of individuals

**Pattern.** Hard to regex; requires NER (named entity
recognition) tool like spaCy + custom rules.

**Redaction.** Full: `Alice Smith` → `[PERSON]` or
`[INDIVIDUAL]` per context.

Be careful: names in technical contexts (e.g. "the alice@example
service") may be infra references, not PII. Tune your NER
allowlist.

### Customer-identifying information

**Pattern.** Customer names + identifying details (e.g. "Acme
Corp's customer ID 0011234567890").

**Redaction.**

- Customer name: `Acme Corp` → `[CUSTOMER]`
- Customer ID: `0011234567890` → `[CUSTOMER-ID]`

### Financial figures (revenue, salary)

**Pattern.** Dollar amounts + currency in financial context.

**Redaction.** Per policy — sometimes redact entirely; sometimes
preserve order of magnitude (`$5M+` is informative; `$5,234,567`
is too specific).

### IP addresses

**Pattern.** IPv4 / IPv6 regex.

**Redaction.**

- Public IPs: full redaction.
- Private IPs (RFC1918): often safe to leave; check policy.

### Database connection strings

**Pattern.** `postgresql://...`, `mongodb://...`, etc. containing
credentials.

**Redaction.** Full: `postgresql://user:pass@host/db` →
`postgresql://[REDACTED]@[REDACTED]/db`.

---

## Redaction tools

### Microsoft Presidio (recommended)

```python
from presidio_analyzer import AnalyzerEngine
from presidio_anonymizer import AnonymizerEngine

analyzer = AnalyzerEngine()
anonymizer = AnonymizerEngine()

text = "Alice Smith works at alice@example.com, phone 555-555-5555"

results = analyzer.analyze(text=text, language="en")
anonymized = anonymizer.anonymize(text=text, analyzer_results=results)
# → "[PERSON] works at [EMAIL_ADDRESS], phone [PHONE_NUMBER]"
```

Configure per project policy (custom recognisers for customer
names, internal IDs, etc.).

### Custom regex (simpler use cases)

```python
import re

PATTERNS = {
    r'\b[\w._%+-]+@[\w.-]+\.[A-Za-z]{2,}\b': '[EMAIL]',
    r'\b\d{3}-\d{2}-\d{4}\b': '[SSN]',
    r'\beyJ[A-Za-z0-9_-]+\b': '[TOKEN]',
}

def redact(text: str) -> str:
    for pattern, replacement in PATTERNS.items():
        text = re.sub(pattern, replacement, text)
    return text
```

### Vault Transform (HashiCorp Vault)

For deterministic, reversible redaction at scale:

```bash
vault write transform/encode/email \
  value="alice@example.com" \
  transformation=email_format
# Returns format-preserving encrypted version
```

Reversible by privileged callers; safe for cross-classification
retrieval.

---

## Per-classification redaction defaults

| Caller's classification | What to redact when retrieving higher-class entity |
|---|---|
| anonymous | Don't retrieve; refuse + log |
| internal viewing restricted | Don't retrieve; refuse |
| internal/restricted viewing confidential | If redaction permitted: redact all PII + customer-identifying + financial; else refuse |
| any viewing regulated | Don't redact; refuse outright; log + alert |

---

## Redaction at chunk-prefix level

Redaction applies to chunk content, not the chunk **prefix**:

```
[entity_id: customer-acme-deal-2026]
[domain: customers]
[type: enterprise]
[chunk: 1/1 — Deal terms]
[classification: confidential]
[updated: 2026-04-15]

[CUSTOMER] signed a [DEAL-VALUE] contract on [DATE] for
[PRODUCT] usage. Account owner: [INDIVIDUAL].
```

Prefix preserved (entity_id is needed for cross-referencing);
content redacted.

If the prefix itself contains sensitive info (e.g. customer
name in the entity ID), refuse instead of redact — partial
visibility of metadata is worse than no visibility.

---

## Audit + alerting on redaction

Every redaction event is logged:

```json
{
  "event_type": "kb_redaction",
  "principal": { ... },
  "entity": { ... },
  "redaction_applied": true,
  "redacted_types": ["email", "person", "financial"],
  "redaction_tool": "presidio"
}
```

Anomaly: if a single principal triggers high volume of
redactions (e.g. >50/h), they may be **probing** for the redacted
content. Alert.

---

## Anti-patterns

- **Partial redaction that's reconstructable.** "Alice S." +
  "...@example.com" → trivially reconstructable. Full redaction
  if you're going to redact.
- **No redaction for confidential.** Defaulting to refuse is
  safer than partial-revelation.
- **Redaction of metadata that's already public.** If the entity's
  classification leaks via the public entity list, redacting the
  body doesn't help.
- **Inconsistent redaction across chunks.** Same entity has
  multiple chunks; only one redacted → partial picture leaks.
  All chunks of the same entity must redact identically.
- **Unaudited redaction.** Redaction events not logged →
  anomaly detection blind to probing.
