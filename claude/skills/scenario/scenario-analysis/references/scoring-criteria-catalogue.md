# Scoring Criteria Catalogue

Common criteria for scoring options in a scenario analysis. Pair
with `scenario-analysis`'s weighted options matrix.

Each criterion has:

- **Definition** — what it measures.
- **Scoring rubric** — 1–5 scale.
- **When it matters most** — which scenarios it discriminates.

## Time-to-delivery

**Definition.** How long the option takes from kick-off to
production / live.

| Score | Range |
|---|---|
| 5 | < 4 weeks |
| 4 | 4–8 weeks |
| 3 | 8–16 weeks |
| 2 | 16–26 weeks |
| 1 | > 26 weeks |

**Matters most when.** Deadline-driven scenarios; competitive
moves; security/compliance hard dates.

---

## Reversibility

**Definition.** Cost of backing out if the option turns out wrong.

| Score | Meaning |
|---|---|
| 5 | Reversible in <1 day; no data impact |
| 4 | Reversible in <1 week; minor cleanup |
| 3 | Reversible in <1 month; documented effort |
| 2 | Significant rework required to reverse |
| 1 | One-way decision (data deleted, contract signed) |

**Matters most when.** High-uncertainty scenarios; first-time
work; experimental moves.

---

## Team capability fit

**Definition.** How well the option matches existing team skills.

| Score | Meaning |
|---|---|
| 5 | Team has shipped this before; primary stack |
| 4 | Team has shipped adjacent work; minor ramp |
| 3 | Team can learn quickly; 1–2 sprint ramp |
| 2 | Significant learning required; training plan |
| 1 | Genuinely new domain for the team |

**Matters most when.** Resource-constrained scenarios; tight
timelines; high-stakes execution.

---

## Operational cost change

**Definition.** % change in monthly ongoing operating cost.

| Score | Range |
|---|---|
| 5 | −20% or more (cost reduction) |
| 4 | −20% to 0% |
| 3 | 0% to +20% |
| 2 | +20% to +50% |
| 1 | > +50% |

**Matters most when.** Cost-pressured scenarios; long-lived
systems; high-volume operations.

---

## Customer / user impact

**Definition.** Severity of customer-visible change during the
transition.

| Score | Meaning |
|---|---|
| 5 | Zero customer-visible impact |
| 4 | Minor (e.g. performance improvement only) |
| 3 | Some visible change; non-breaking |
| 2 | Breaking change with migration path |
| 1 | Breaking change requiring customer action |

**Matters most when.** Customer-facing changes; SLA-bound
systems; B2B with contractual obligations.

---

## Risk of failure

**Definition.** Probability the option fails to meet stated
goals within stated horizon.

| Score | Meaning |
|---|---|
| 5 | < 5% probability of failure |
| 4 | 5–15% |
| 3 | 15–30% |
| 2 | 30–50% |
| 1 | > 50% |

**Matters most when.** High-stakes scenarios; regulated
environments; investor / leadership scrutiny.

---

## Strategic alignment

**Definition.** How well the option aligns with the org's stated
strategy.

| Score | Meaning |
|---|---|
| 5 | Directly supports a stated strategic objective |
| 4 | Compatible with strategy; no contradiction |
| 3 | Neutral / orthogonal to strategy |
| 2 | Mild tension with strategy |
| 1 | Direct contradiction with strategy |

**Matters most when.** Decisions visible to leadership / board;
multi-year initiatives.

---

## Compliance / regulatory fit

**Definition.** How well the option fits regulatory requirements
(HIPAA, SOC2, PCI, GDPR, etc.).

| Score | Meaning |
|---|---|
| 5 | Strengthens compliance posture |
| 4 | Compliant; no new burden |
| 3 | Compliant; some additional process |
| 2 | Requires significant new compliance work |
| 1 | Cannot be made compliant in current form |

**Matters most when.** Regulated industries; pre-IPO; pre-
attestation cycles.

---

## Vendor / dependency risk

**Definition.** Risk introduced by new vendor or dependency
relationships.

| Score | Meaning |
|---|---|
| 5 | No new external dependencies |
| 4 | Mature, multi-customer vendor; low risk |
| 3 | Established vendor; some risk |
| 2 | New / smaller vendor; meaningful risk |
| 1 | Single-source dependency; high risk |

**Matters most when.** Long-term commitments; mission-critical
systems; enterprise compliance constraints.

---

## Maintainability / sustainability

**Definition.** Long-term cost of owning + evolving the option.

| Score | Meaning |
|---|---|
| 5 | Easier to maintain than current state |
| 4 | About same; established patterns |
| 3 | Manageable; some learning required |
| 2 | Higher maintenance burden; specialised skills |
| 1 | Bus-factor-1 patterns; hard to evolve |

**Matters most when.** Long-lived systems; small team; ops cost
sensitivity.

---

## Reach / market expansion

**Definition.** Degree to which the option enables new markets,
segments, or use cases.

| Score | Meaning |
|---|---|
| 5 | Unlocks significant new market segment |
| 4 | Notable expansion of reach |
| 3 | Moderate expansion |
| 2 | Marginal expansion |
| 1 | No reach impact |

**Matters most when.** Growth-focused scenarios; product-led-
growth strategies.

---

## Decision-making process

Per `scenario-analysis`:

1. **Pick 4–7 criteria** for this scenario (fewer = under-spec;
   more = unreadable).
2. **Weight each explicitly** (1–5) — no hand-waving "all are
   important".
3. **Score each option per criterion** (1–5).
4. **Weighted total per option** = Σ (weight × score).
5. **Recommendation** = highest score *unless* non-quantifiable
   factor overrides (document the override).

---

## Anti-patterns

- ❌ Picking 10+ criteria — analysis becomes noise.
- ❌ Equal weights — the matrix doesn't discriminate.
- ❌ Scores without rubric — different scorers, different scales.
- ❌ Cherry-picking criteria that favour a pre-chosen option.
- ❌ "All options score 4/5 on everything" — criteria aren't
  discriminating; reconsider.
