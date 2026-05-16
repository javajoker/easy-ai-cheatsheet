# Options Criteria Catalogue

Common criteria for scoring architecture options. Each criterion
has a **definition** and a **scoring rubric** so different options
get rated consistently.

## Time-to-migrate

How long to complete the migration end-to-end (calendar weeks).

| Score | Range |
|---|---|
| 5 | < 4 weeks |
| 4 | 4–8 weeks |
| 3 | 8–16 weeks |
| 2 | 16–26 weeks |
| 1 | > 26 weeks |

## Reversibility

How cheaply can we back out if the option turns out wrong?

| Score | Meaning |
|---|---|
| 5 | Reversible in <1 day with no data impact |
| 4 | Reversible in <1 week with minor cleanup |
| 3 | Reversible in <1 month with documented effort |
| 2 | Reversible only with significant rework |
| 1 | One-way decision (e.g. DB write cutover, data deleted) |

## Team capability fit

Does the team already have the skills, or is significant learning required?

| Score | Meaning |
|---|---|
| 5 | Team has shipped this before; primary stack |
| 4 | Team has shipped adjacent work; minor learning curve |
| 3 | Team can learn quickly; ramp 1–2 sprints |
| 2 | Significant learning required; hire/training plan needed |
| 1 | Genuinely new domain for the team |

## Operational cost change

% change in monthly ongoing cost (compute + storage + ops time).

| Score | Range |
|---|---|
| 5 | −20% or more (cost reduction) |
| 4 | −20% to 0% |
| 3 | 0% to +20% |
| 2 | +20% to +50% |
| 1 | > +50% |

## Strategic alignment

How well the option aligns with the organisation's published strategy.

| Score | Meaning |
|---|---|
| 5 | Directly supports a stated strategic objective |
| 4 | Compatible with strategy; no contradiction |
| 3 | Neutral; orthogonal to strategy |
| 2 | Mild tension with strategy |
| 1 | Direct contradiction with strategy |

## Risk of failure (within stated horizon)

Probability the migration fails to meet its goals.

| Score | Meaning |
|---|---|
| 5 | < 5% probability of failure |
| 4 | 5–15% |
| 3 | 15–30% |
| 2 | 30–50% |
| 1 | > 50% |

## Customer impact

How visible is the migration to customers?

| Score | Meaning |
|---|---|
| 5 | Zero customer-visible impact |
| 4 | Minor (improved performance only) |
| 3 | Some visible change (UI / API; non-breaking) |
| 2 | Breaking change with migration path |
| 1 | Breaking change requiring customer action |

## Picking the criteria for a specific assessment

Use 4–7 criteria total — fewer than 4 underspecifies; more than 7
becomes unreadable. The criteria you pick should match the
scenario's drivers (e.g. deadline-driven → time-to-migrate
heavier; risk-averse → reversibility heavier).

**Weight each criterion explicitly** (1–5). Don't hand-wave that
"all are important" — that's how options matrices stop
discriminating.
