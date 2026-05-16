---
name: gtm-pricing-model
description: Designs the pricing model (not the pricing page) — model choice (per-seat / per-usage / per-feature / flat / hybrid), tier count, feature-to-tier assignment, free path (none / trial / freemium / open-source-core), anchoring tier, discount policy, and the internal rationale that justifies the numbers. Output is pricing-model.md plus a feature-tier matrix the gtm-marketing-site skill renders into the actual pricing page. Use this skill when the user asks "how should we price this", "design the pricing tiers", "should we have a free tier", "set the prices". Pairs with gtm-positioning (tiers map to ICP segments), with project-docs (every PRD feature lands in exactly one tier or in an explicit not-priced bucket), with requirement-audit (verifies the mapping is complete), and with gtm-marketing-site (which renders the page).
status: shipped
owner_agent: lifecycle-pilot
---

# GTM Pricing Model

Decides the pricing *strategy*. The marketing site renders it as a
page; the analytics skill instruments it; sales sells against it.
This skill is the load-bearing decision underneath all three.

## Why this exists

Pricing is the most-changed and least-rigorously-designed GTM
artifact in most launches. Common failure shapes:

- **Tier creep.** Teams add a fourth tier "for the enterprise"
  without thinking about why the buyer would jump from 3 to 4.
- **Feature scramble.** Features are assigned to tiers by gut feel,
  not by ICP segment.
- **Free-tier kneejerk.** *"Everyone has a free tier"* drives
  unsustainable unit economics if the free user never converts.
- **No anchor.** Prices look arbitrary because nothing anchors the
  ladder.
- **Discount inflation.** Without a discount policy, sales gives
  discounts ad hoc; list price loses meaning within 90 days.

This skill ships an opinionated decision frame that produces a
defensible pricing model, with the *rationale* documented so future
re-prices have something to argue against.

## When to fire

Fire when:

- The user asks *"how should we price this"*, *"design the
  pricing"*, *"set the tiers"*.
- `lifecycle-pilot` reaches Phase 7 and no `pricing-model.md`
  exists.
- The user is preparing to re-price (existing model exists; the
  skill produces a *new* model, the old one is archived).

Do **not** fire when:

- The product is internal-only (no pricing).
- The user only wants the *page* — that's `gtm-marketing-site`
  reading an existing model. This skill produces the model.
- Pricing is dictated externally (regulated industry, partnership
  terms) — document the constraints, then run only the
  feature-tier-assignment phase.

## Inputs

Required:

- **PRD** — feature list with priority bands (P0 / P1 / P2).
- **Positioning brief** (from `gtm-positioning`) — ICP segments
  drive tier targeting.

Asked up front (cap at 4):

1. **Model preference if any.** (Per-seat / per-usage / per-
   feature / flat / hybrid.) If the user has no preference, the
   skill recommends based on PRD signals.
2. **Free path preference.** (None / trial / freemium / OSS-core.)
   Heavy implications — ask once.
3. **Floor and ceiling.** Lowest paid tier price; highest tier
   price ceiling. Sets the ladder shape.
4. **Currency + billing cycle.** Default USD monthly; specify
   otherwise.

## The procedure

### Phase 1 — Pick the model

Decide the pricing *model* (not the *numbers* yet):

| Signal in PRD | Suggests model |
|---|---|
| Per-user collaboration; user-generated content | per-seat |
| Heavy compute / API calls / storage | per-usage |
| Distinct capabilities used by distinct buyer roles | per-feature |
| Simple SaaS, low variance in usage | flat |
| Multiple of above | hybrid (per-seat base + per-usage overage is most common) |

Document the rationale in `pricing-model.md`. Without it, future
re-pricing has nothing to push against.

### Phase 2 — Design tier count + anchor

**Tier count: typically 3** (e.g. Free/Starter, Pro, Business +
Enterprise on request). Two tiers is hard to justify a step-up;
four tiers means at least one is doing too little work.

**Anchor tier:** the tier the team expects most paying customers to
land on. Price the anchor *first*; the other tiers price relative
to it.

The "no-decoy" rule: every tier exists because a real customer
segment wants it. No tier exists *only* to make another tier look
attractive.

### Phase 3 — Map ICP segments → tiers

Pull the ICP from the positioning brief. Map each segment to its
target tier. A segment with no tier is either out of scope (move
to anti-ICP) or the tier is missing.

| ICP segment | Target tier | Why |
|---|---|---|
| Hobbyist | Free (or trial) | Discovery / loyalty path |
| Small team (1–5) | Starter | Anchor segment |
| Mid team (5–50) | Pro | Highest LTV likely |
| Enterprise (50+) | Business / Enterprise | Custom contracting |

### Phase 4 — Assign features to tiers

Open the PRD feature list. For each feature, decide:

- **Free / Starter** — must-have for the entry tier; gates nothing
  fundamental.
- **Pro** — distinguishes the upgrade; meaningful but not
  scope-creep features.
- **Business / Enterprise** — admin, audit, compliance, SSO,
  custom integrations, dedicated infra.
- **Not yet priced** — built but withheld from current model;
  documented separately.

Run `requirement-audit` against the PRD feature list: every feature
landed in exactly one bucket. Unassigned features signal incomplete
design.

### Phase 5 — Decide the free path

Four options; pick exactly one:

| Option | Use when | Risk |
|---|---|---|
| **None** (paid-only, no trial) | Strong existing demand; very specific buyer | High friction; weeds out the curious |
| **Free trial** (time-limited) | Product has clear quick-win in 7–14d | Trial extensions become support burden |
| **Freemium** (free tier exists forever) | Distribution-led growth strategy; viral / network effects | Sustained free-tier cost; conversion engineering needed |
| **OSS-core + paid layer** | Developer tool; technical audience | Open-source community maintenance |

Document the choice and the unit-economics assumption (e.g. "free
tier costs $X / user / month; conversion target 5% within 90d").

### Phase 6 — Set the numbers

Anchor first. Other tiers as multiples:

- Starter (or Free→Pro step): the anchor.
- Pro: typically 2–5× starter for clear feature delta.
- Business / Enterprise: 3–10× pro, often "Contact us" without a
  public price.

Discounts:

- **Annual discount**: 15–20% off monthly equivalent is the norm.
- **Volume discount**: documented breakpoints (e.g. 10+ seats:
  10%, 50+: 15%).
- **Non-profit / education**: documented policy with eligibility.
- **Anything else**: requires a written exception with sign-off.

Without this policy, sales discount-creep degrades list price by
20%+ in the first year.

### Phase 7 — Document the rationale

`pricing-model.md` must include:

- The model choice with rationale.
- Tier table.
- ICP → tier mapping.
- Feature → tier mapping (one row per PRD feature).
- Free-path choice with unit-economics assumption.
- Discount policy.
- What would trigger a re-price (e.g. *"conversion <2% after
  90d"*, *"competitor cuts list by 30%"*).
- Review date (typically 6 months).

Use [references/pricing-model-template.md](references/pricing-model-template.md).

After writing, the model is locked and persisted via
`memory-ontology` (`type: project`, `pricing_<slug>_v1`).

## Anti-patterns

- **Pricing before positioning.** Tiers without ICP segments are
  arbitrary. Run `gtm-positioning` first.
- **Round numbers without rationale.** $99 because round is a
  reason. $99 because it's at the upper edge of what the anchor ICP
  expense-codes without approval is a *good* reason.
- **One mega-tier.** A single tier that "covers everything" loses
  the up-sell path; growth flatlines.
- **Decoy tier.** A tier that exists only to make another tier look
  good erodes trust when buyers figure it out.
- **Silent discounting.** No documented policy means sales
  improvises and list price loses meaning.
- **Permanent freemium with no conversion engineering.** Free
  users with no upgrade path are a cost center.

## Companion skills

- `gtm-positioning` — ICP is the input.
- `project-docs` — PRD feature list is the input.
- `gtm-marketing-site` — renders the model as a page.
- `gtm-analytics-instrumentation` — instruments conversion + tier
  upgrade events.
- `requirement-audit` — verify every PRD feature is assigned.
- `memory-ontology` — persist the locked model.

## Reference files

- [references/pricing-model-template.md](references/pricing-model-template.md) —
  the canonical output shape.
- `references/discount-policy-template.md` — discount policy
  template with worked examples.
- `references/unit-economics-worksheet.md` — helps the team
  pressure-test the free-path assumption.
