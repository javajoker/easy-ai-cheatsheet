# Taxonomy Adaptation — Worked Examples

Default taxonomy adapted to different org shapes. Adapt **before**
the architecture is locked, never after.

## Default 7-domain taxonomy

```
products / teams / decisions / terminology / runbooks / customers / partners
```

Works for: most multi-product SaaS B2B orgs.

---

## Single-product startup

```
subsystems / teams / decisions / terminology / runbooks / customers / partners
```

`products` → `subsystems` (the single product has internal
subsystems worth cataloguing as entities; e.g. auth-service,
billing-service, search-service).

Sub-types under `subsystems`:

| Sub-type | Examples |
|---|---|
| `service` | auth-service, billing-service |
| `library` | shared SDK, internal SDK |
| `worker` | background job processors |
| `frontend` | web app, mobile app |

---

## Multi-product suite (default works well)

Default taxonomy unchanged. Sub-types per `products`:

| Product | Sub-type |
|---|---|
| Coolshell | products/shipped |
| Stardust | products/shipped |
| Sundust (next) | products/experimental |
| Olderprod (sunset) | products/sunset |

---

## Agency / consultancy

```
projects / engagements / teams / decisions / terminology / runbooks / customers / partners
```

`products` → `projects` + new `engagements` domain.

- `projects` — codebases / deliverables the agency owns or has
  shipped.
- `engagements` — client engagements; sub-types `active` /
  `paused` / `completed`.

Each engagement entity references the projects involved.

---

## Open-source heavy

```
projects / teams / contributors / decisions / terminology / runbooks / customers / partners
```

New domain `contributors` distinct from `teams`:

- `teams` — employed staff with org reporting structure.
- `contributors` — external contributors with various levels of
  trust (committer, maintainer, casual).

Sub-types under `contributors`:

| Sub-type | Trust level |
|---|---|
| `maintainer` | Can merge to main |
| `committer` | Recurring contributor; can review |
| `casual` | One or more PRs |

---

## Regulated industry (healthcare / finance)

```
products / teams / decisions / terminology / runbooks / customers / partners / compliance
```

New `compliance` domain alongside `decisions`:

- `compliance` — entities tied to regulatory compliance:
  attestations, audits, regulatory anchors, compliance controls.

Sub-types:

| Sub-type | Definition |
|---|---|
| `attestation` | SOC2 / ISO27001 / HIPAA attestation evidence |
| `audit` | Audit cycle records |
| `control` | Specific compliance control implementation |
| `regulator` | Regulatory body relationships |

All `compliance` entities default to `restricted` or `confidential`
classification.

---

## Platform org (internal customers)

```
products / teams / decisions / terminology / runbooks / partners / internal-customers
```

Replace `customers` with `internal-customers` (other teams in the
org consuming the platform team's products).

Sub-types under `internal-customers`:

| Sub-type | Example |
|---|---|
| `consumer-team` | Engineering team consuming the platform |
| `tier-1` | Business-critical consumer; SLA contracts |
| `tier-2` | Standard consumer |
| `experimental` | Trying the platform; pre-commit |

---

## Heavy M&A history

```
products / teams / decisions / terminology / runbooks / customers / partners / acquisitions
```

New `acquisitions` domain to track entities from acquired companies
that haven't fully integrated:

- `acquisitions/integrated` — fully absorbed; product now appears
  in `products`.
- `acquisitions/in-progress` — being integrated.
- `acquisitions/sunset` — acquired but discontinued.

Helpful when integrating across multiple acquired KBs.

---

## When to adapt

| Signal | Adaptation |
|---|---|
| Default `products` doesn't fit (e.g. single product, agency model) | Rename or split |
| Compliance regime requires explicit attestation entities | Add `compliance` domain |
| External contributors are first-class citizens | Add `contributors` |
| Internal-customer relationships matter more than external | Rename or split `customers` |
| M&A activity produces hard-to-classify entities | Add `acquisitions` |

## When NOT to adapt

- **Per-project quirks.** If only one project would benefit, use
  per-project sub-types within the default domain.
- **Temporary need.** Re-architecture is expensive; don't adapt
  for a transient classification need.
- **Sub-type would do.** If the new "domain" you want is really
  a sub-type variant, add the sub-type instead.

## Adaptation discipline

1. **Document the adaptation rationale** in `ARCHITECTURE.md`'s
   "Domain rationale" section per adapted-from-default decision.
2. **Lock the adapted taxonomy** before any merging.
3. **Re-architecture afterward is expensive** — get this right
   upfront.
