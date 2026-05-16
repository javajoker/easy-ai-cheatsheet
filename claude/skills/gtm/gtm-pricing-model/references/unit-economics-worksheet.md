# Unit Economics Worksheet

The math behind a pricing decision. Fill in before locking the
pricing model; revisit annually.

---

## Per-customer / per-unit costs

### Cost of goods sold (COGS) per customer

| Component | Cost | Notes |
|---|---|---|
| Compute (per active user / per request) | $<X> | From cloud cost tracking |
| Storage (per GB stored / per month) | $<X> | |
| Bandwidth (per GB egress) | $<X> | |
| Third-party services per customer (auth, email, etc.) | $<X> | |
| Support cost per customer (per ticket × avg tickets) | $<X> | |
| **Total COGS per customer per month** | $<X> | |

### Customer Acquisition Cost (CAC)

| Component | Cost | Notes |
|---|---|---|
| Marketing spend / signups | $<X> | Direct attribution |
| Sales cost / signups (for assisted deals) | $<X> | Sales rep + tools, allocated |
| Onboarding cost per customer | $<X> | CSM time, training |
| **Total CAC per customer** | $<X> | |

### Lifetime Value (LTV) signals

| Component | Value | Notes |
|---|---|---|
| Average Revenue Per User (ARPU) per month | $<X> | |
| Gross margin % (1 − COGS/ARPU) | <X>% | Should be >70% for SaaS |
| Average customer lifetime (months) | <N> | From churn cohort analysis |
| **Estimated LTV per customer** | $<X> | ARPU × lifetime × margin |

---

## Key ratios

| Ratio | Target | Current |
|---|---|---|
| **LTV / CAC** | ≥3 (SaaS standard); ≥4 for healthy | <X> |
| **CAC payback (months)** | ≤12; ≤6 for healthy | <X> |
| **Gross margin** | ≥70% (SaaS); higher better | <X> |
| **Net Revenue Retention** | ≥100% (any product); ≥120% (best-in-class enterprise) | <X> |

If LTV/CAC < 3 or CAC payback > 18 months:
- Either pricing is too low.
- Or CAC is too high (sales / marketing inefficient).
- Or churn is too high (product-market fit issue).

---

## Pricing decisions driven by economics

### Floor — what each tier must cover

| Tier | Min ARPU |
|---|---|
| Free | $0 (must be covered by paid tier conversion at <X>%) |
| Starter | COGS per customer × 3 (gross margin ≥66%) |
| Pro | Starter × 3–5 |
| Enterprise | "Cost-plus" with minimum commitment |

### Free tier sustainability check

| Component | Value |
|---|---|
| Free users count | <N> |
| Free user COGS per month | $<X> |
| Conversion rate to paid | <X>% |
| Cost per converted customer | (Free COGS × Free users) / (Free users × conversion rate) = $<X> |
| Equivalent paid CAC | $<X> (compare against paid CAC) |

If free-tier "CAC" exceeds paid-tier CAC, the free tier isn't a
sustainable acquisition channel.

### Price elasticity considerations

If you've A/B tested prices:

| Price | Conversion rate | Effective revenue per visitor |
|---|---|---|
| $10/mo | <X>% | $<X> |
| $20/mo | <Y>% | $<Y> |
| $30/mo | <Z>% | $<Z> |

Best price = max(effective revenue per visitor).

If you haven't tested: anchor to comparable products in the
market.

---

## Tier-mix targets

The pricing page is optimised when tier distribution falls in a
healthy range. Common patterns:

| Tier | Target % of customers |
|---|---|
| Free | 50–80% |
| Starter | 10–30% |
| Pro | 5–15% |
| Enterprise | 1–5% |

| Tier | Target % of revenue |
|---|---|
| Free | 0% |
| Starter | 10–30% |
| Pro | 30–50% |
| Enterprise | 30–60% |

If 90% of revenue comes from one tier, pricing is mis-calibrated
or tiers don't actually differentiate.

---

## Re-pricing triggers

Revisit pricing when:

- LTV / CAC ratio drops below target.
- Gross margin drops below target.
- Net Revenue Retention drops below 100%.
- Tier distribution skews unhealthily (one tier dominates).
- Competitor pricing shifts materially.
- COGS structure changes (e.g. cloud cost reduction allows price
  cut; or inflation / FX changes).
- New feature adds material value (justifies tier reshuffle).
- Product-market fit improves (can raise prices).

Re-pricing is non-trivial — existing customers may be grandfathered
or migrated; communication is sensitive. Plan 2–3 months ahead.

---

## Sanity checks before locking pricing

- [ ] Each tier covers its COGS with target margin.
- [ ] Free tier (if any) is acquisition-channel-grade, not just a
      cost center.
- [ ] Highest tier captures enterprise willingness-to-pay.
- [ ] Pricing-page conversion rate has been A/B-validated where
      possible.
- [ ] Competitor benchmark — within reasonable range or
      justifiably outside.
- [ ] Discount policy is consistent with the pricing model.
- [ ] Pricing page is understandable in 30 seconds.

---

## Anti-patterns

- ❌ Pricing without unit economics analysis — surprises post-
  launch.
- ❌ Free tier without sustainability math — kills LTV/CAC.
- ❌ All tiers similar — customers don't see the upgrade reason.
- ❌ Enterprise-only "talk to sales" with no list anchor — slows
  procurement cycles.
- ❌ Annual discount > 50% — implies list price is fiction.
- ❌ Re-pricing every 6 months — customers lose trust.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial | <name> |
