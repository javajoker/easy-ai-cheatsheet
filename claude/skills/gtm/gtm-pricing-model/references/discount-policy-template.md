# Discount Policy — <project>

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Status:** active | draft | superseded

---

## Why a policy

Without a written policy, every deal re-negotiates discounts.
Sales reps lean on heavy discounting; customers learn the list
price is fiction; CAC payback periods stretch.

A policy makes discounts predictable + bounded + signed-off.

---

## Discount categories

| Category | Default discount | Approval | Renewal |
|---|---|---|---|
| Annual commitment | 10–15% off monthly | Auto (built into pricing page) | Default |
| Multi-year commitment (2y / 3y) | +5% / +10% on top of annual | Sales rep | Default |
| Volume (over X units) | Tiered — see table below | Auto for self-serve; Sales for negotiated | Default |
| Non-profit / education | 25% off list | Sales (with verification) | Annual re-verification |
| Startup program | 50% off list, year 1 only | Self-serve apply form | Reverts to list after 12 months |
| Enterprise negotiated | Up to 30% off list | Sales lead | Per contract terms |
| Strategic / land-grab | Up to 50% off list | VP Sales + Finance | Per contract terms |
| Promotional (time-limited) | Up to 25% off, ≤3 months | Marketing + Sales lead | Reverts to list |
| Migration credit | Up to 12 months value | Sales lead | One-time only |

---

## Volume discount table (example)

For per-seat pricing:

| Seats | Discount off list |
|---|---|
| 1–10 | 0% |
| 11–50 | 5% |
| 51–200 | 10% |
| 201–500 | 15% |
| 501+ | Negotiated (typically 20–25%) |

For usage-based pricing (e.g. per million events):

| Monthly volume | Discount off list per-unit |
|---|---|
| 0–1M | 0% |
| 1–10M | 10% |
| 10–100M | 20% |
| 100M+ | Negotiated |

---

## Approval thresholds

| Discount % | Approval |
|---|---|
| ≤10% | Sales rep |
| 10–20% | Sales manager |
| 20–30% | VP Sales |
| 30%+ | VP Sales + CFO |
| 50%+ | CEO |

Stacking multiple discounts (e.g. annual + volume + promotional)
sums to the effective discount; approval applies to the
**total**.

---

## Stacking rules

- **Annual + volume + non-profit:** allowed; sums.
- **Promotional + others:** not stacking (promotional displaces
  others during promo window).
- **Startup + others:** not stacking (startup is its own program).
- **Strategic / land-grab + others:** not stacking (it's already
  a one-off).

---

## Documentation per deal

Every discount > 10% logged in CRM with:

- Customer name + ID.
- List price.
- Effective price.
- Discount % + categories applied.
- Approver name + date.
- Term + renewal-discount commitment (does discount carry on
  renewal?).
- Justification (one paragraph).

---

## Renewal-time discount handling

By default, discounts **do not auto-renew at the same level**.
Renewal price is list price unless explicitly negotiated
otherwise.

Common renewal patterns:

| Pattern | Default |
|---|---|
| First-year promotional discount | Reverts to list at renewal |
| Annual / multi-year commitment | Same discount carries |
| Volume | Recalculated at renewal based on current volume |
| Non-profit / education | Carries with re-verification |
| Startup program | Reverts to list at renewal (year-1 only program) |
| Enterprise negotiated | Per contract — typically same or step-down |

Communicate at sale time so renewal isn't a surprise.

---

## Sunset / removal of discounts

| Discount | When sunset / removed |
|---|---|
| Promotional | At end of promo window |
| Strategic / land-grab | At contract renewal |
| Negotiated discount above policy | At renewal (unless re-approved) |

A discount that's been in place "since the customer signed in
2022" without ever being re-reviewed is **policy drift**. Annual
review of all customer discounts.

---

## Reporting

Monthly to leadership:

- % of deals with discounts.
- Average discount %.
- Discount distribution (histogram by 5% buckets).
- Approval breakdown (% at each approval level).
- Deal-by-deal report for discounts >30%.

Patterns to watch:

- Average discount creeping up → policy is too tight; deals
  pressure the line.
- Frequent CEO-level approvals → threshold is wrong or sales is
  asking for too much.
- Promotional discounts not sunsetting → operational gap.

---

## Anti-patterns

- ❌ No policy — every deal negotiated from scratch.
- ❌ Verbal-only approvals.
- ❌ Discount stacking without total cap.
- ❌ "Special exceptions" that become routine.
- ❌ Renewal discount surprises (customer expects same, gets list).
- ❌ Permanent promotional discounts.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial | <name> |
