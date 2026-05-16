# Staleness Rules Catalogue

Default staleness rules per entity sub-type with adaptation
guidance.

## Default rules

| Domain | Sub-type | Default rule | Cadence rationale |
|---|---|---|---|
| products | shipped | Quarterly review; mandatory at major releases | Features evolve per release |
| products | sunset | Locked at sunset | Historical |
| products | experimental | Monthly review | Fast-moving |
| products | internal | Quarterly review | Slower-moving |
| teams | engineering | Quarterly; per org change | Reorgs trigger refresh |
| teams | product | Quarterly; per org change | Same |
| teams | ops | Quarterly; per on-call rotation change | On-call drift |
| teams | leadership | Quarterly; per appointment | Same |
| teams | cross-functional | Quarterly | Cross-team alignment |
| decisions | architectural | 6 months; per related arch change | Architectural context evolves |
| decisions | strategic | 6 months; per leadership change | Strategy shifts with leadership |
| decisions | compliance | Per regulatory change; quarterly audit | Continuous |
| decisions | tactical | Yearly (often stable once made) | Implementation detail |
| decisions | experiment | At experiment end-date | Time-boxed |
| terminology | canonical | Ongoing (alignment library is source) | Continuous |
| terminology | domain | Quarterly | Domain evolution |
| terminology | external | Per standards update | Slow-moving |
| terminology | deprecated | Locked | Historical |
| runbooks | incident | Quarterly game-day rehearsal; per incident in class | Drift is dangerous |
| runbooks | operational | Quarterly | Routine procedures evolve |
| runbooks | drill | Per quarterly drill | Continuous |
| runbooks | recovery | Annual full test; quarterly walk-through | DR tests are expensive |
| customers | enterprise | Quarterly QBR sync | Account state changes |
| customers | mid-market | Bi-annual sync | Lighter touch |
| customers | smb | Annual | Mostly self-serve |
| customers | partner-customer | Quarterly | Active relationship |
| partners | integration | Quarterly health check | Integrations evolve |
| partners | vendor | Annual contract review | Slower |
| partners | channel | Per quarterly commission cycle | Active relationship |
| partners | technology | Bi-annual sync | Slower |

---

## Adaptation guidance

### Fast-moving product

If product changes per sprint, tighten:

- `products/shipped` quarterly → **per sprint** (or per release).
- `decisions/architectural` 6 months → **3 months** if architecture
  evolves fast.

### Stable product (legacy / mature)

If product is in maintenance mode, relax:

- `products/shipped` quarterly → **bi-annual**.
- `decisions/architectural` 6 months → **annual** (architecture
  rarely changes).

### Regulated industry

Tighten compliance-touching entities:

- `decisions/compliance` → **per regulatory cycle** (quarterly if
  regulator demands; monthly during audit periods).
- `customers/enterprise` → **per contract milestone** (some
  regulations require attestation per quarter).

### Open-source project

Different cadences for community-driven KB:

- `terminology` → **per release** (terms shipped with each release).
- `decisions` → **per RFC closure** (RFCs are the decision artifact).

---

## Per-project override

Each project can override defaults in their
`INSTRUCTIONS/projects/<slug>/kb-overrides/staleness-rules.md`:

```yaml
overrides:
  - domain: products
    type: shipped
    rule: "Per sprint"  # tighter than default
    rationale: "Product team ships weekly; KB drifts otherwise"

  - domain: decisions
    type: architectural
    rule: "Annual"  # looser
    rationale: "Mature platform; arch decisions stable post-2024"
```

Overrides apply only to that project's entities. Cross-project
canonical entities follow the org-wide rule.

---

## Visibility

Each canonical entity displays `updated:` in its frontmatter and
prominently in its rendered view. Consumers can assess freshness
at a glance.

For staleness detection in UI:

- ✅ Within window — green badge "current"
- ⚠️ Approaching staleness window expiry (next 30 days) — yellow
  "review soon"
- ❌ Past staleness window — red "stale"

---

## Audit query examples

### "Show me all entities past staleness"

```sql
SELECT id, domain, type, owner, updated
FROM canonical_entities
WHERE updated < staleness_cutoff_per_rule(domain, type)
ORDER BY updated ASC;
```

### "Show me owner backlog by domain"

```sql
SELECT owner, domain, COUNT(*) AS stale_count
FROM canonical_entities
WHERE updated < staleness_cutoff_per_rule(domain, type)
GROUP BY owner, domain
ORDER BY stale_count DESC;
```

### "Show me sunset candidates"

```sql
SELECT id, domain, type, owner, last_reference_at
FROM canonical_entities
WHERE last_reference_at < NOW() - INTERVAL '12 months'
   OR owner_status = 'unassignable_90d';
```

(Adapt SQL to the actual storage; this is illustrative.)

---

## Anti-patterns

- **Same cadence for all entity types.** Fast-moving products
  drift; stable entities get unnecessary churn.
- **No staleness visibility.** Consumers can't tell what's current.
- **Staleness rule with no notification mechanism.** Rule that
  fires nothing changes nothing.
- **Rule "per quarter" without specifying which quarter.** End-of-
  quarter cliffs cause batch churn. Per **rolling** quarter.
