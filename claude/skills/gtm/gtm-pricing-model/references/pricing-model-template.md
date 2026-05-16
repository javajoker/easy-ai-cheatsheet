# Pricing Model — <product>

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Status:** active | draft | superseded
**Review date:** YYYY-MM-DD (~6 months after lock)

---

## Model

**Choice:** per-seat | per-usage | per-feature | flat | hybrid (specify)

**Rationale:** <one paragraph; cite PRD signal>

---

## Tiers

| Tier | Target ICP segment | Price (monthly) | Price (annual) | Anchor? |
|---|---|---|---|---|
| Free / Starter | <segment> | $X | $Y | – |
| Pro | <segment> | $X | $Y | ✓ |
| Business | <segment> | $X | $Y | – |
| Enterprise | <segment> | Contact us | Contact us | – |

(Currency: USD. Other currencies: documented in `references/currencies.md` if applicable.)

---

## Feature → Tier matrix

| Feature (PRD ID) | Free | Pro | Business | Enterprise | Notes |
|---|---|---|---|---|---|
| F-001 user auth | ✓ | ✓ | ✓ | ✓ | core |
| F-002 collab editing | – | ✓ | ✓ | ✓ | gates upgrade from Free |
| F-003 SSO | – | – | ✓ | ✓ | enterprise gate |
| F-004 audit log | – | – | ✓ | ✓ | compliance |
| ... | | | | | |

Unassigned features: <list — or "none, all PRD features assigned">

---

## Free path

**Choice:** none | trial (N days) | freemium | OSS-core + paid

**Rationale:** <one paragraph>

**Unit-economics assumption (if freemium):**

- Free tier infrastructure cost: $X / user / month
- Conversion target: Y% within Z days
- Net free-tier cost at scale (10k users): $K / month
- Sensitivity: if conversion drops to (Y/2)%, reassessment trigger

---

## Discount policy

| Discount class | Rate | Eligibility | Approval needed |
|---|---|---|---|
| Annual prepay | 15–20% off monthly equivalent | Any tier | none |
| Volume (10+ seats) | 10% | Pro / Business | self-serve |
| Volume (50+ seats) | 15% | Pro / Business | self-serve |
| Volume (100+ seats) | 20% | Business / Enterprise | sales rep |
| Non-profit / 501(c)(3) | 30% | Documented status | sales rep |
| Education | 50% | .edu email + manual verification | sales rep |
| Custom exception | varies | – | written sign-off, logged |

Any discount not in the above table requires written sign-off and
is logged for the quarterly discount audit.

---

## ICP segment → tier mapping

(Pulled from positioning brief.)

| ICP segment | Target tier | Why |
|---|---|---|
| <segment> | <tier> | <why> |
| <segment> | <tier> | <why> |

---

## Re-price triggers

The model is re-evaluated if any of the following are observed:

- Free-to-paid conversion <X% after 90 days from launch.
- Anchor tier average revenue per account drops by >20% in a
  quarter due to discount creep.
- A direct competitor cuts list price by >30%.
- Tier distribution skews so heavily to one tier that the others
  lose justification.
- Product capability expansion creates a meaningful new tier
  candidate.

Otherwise: review at the scheduled review date.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial lock | <name> |
