# Options Analysis — <slug>

**Version:** 1
**Created:** YYYY-MM-DD
**Decision authority:** <name>
**Decision deadline:** YYYY-MM-DD
**Status:** open | decided | superseded
**Decision:** <option-name> (decided YYYY-MM-DD by <name>)

---

## Context

<2–3 sentences referencing the locked scenario brief.>

Related brief: [scenario-brief.md](scenario-brief.md) — version <N>.

---

## Options

### Option A — <name>

**Description.** <one paragraph>

**Critical assumption.** <the one belief that, if wrong, makes
this option fail>

**Time estimate.** <weeks / months>

**Cost estimate.** <coarse $ / engineer-months>

**Risk profile.** <one paragraph>

---

### Option B — <name>

**Description.** <one paragraph>

**Critical assumption.** <…>

**Time estimate.** <…>

**Cost estimate.** <…>

**Risk profile.** <…>

---

### Option C — Minimum action / status quo

**Description.** <what happens if we do the minimum or nothing>

**Critical assumption.** <…>

**Time estimate.** <near-zero>

**Cost estimate.** <near-zero (often hides ongoing cost)>

**Risk profile.** <often the highest long-run risk despite the
appearance of safety — surface this honestly>

---

## Weighted scoring

Weights chosen by <name> on YYYY-MM-DD.

| Criterion | Weight (1–5) | Option A | Option B | Option C |
|---|---|---|---|---|
| Time-to-delivery | 4 | 3 | 2 | 5 |
| Reversibility | 3 | 2 | 4 | 5 |
| Team capability fit | 5 | 4 | 3 | 5 |
| Ongoing operational cost | 3 | 4 | 3 | 2 |
| Customer impact | 4 | 5 | 4 | 1 |
| Risk of failure | 4 | 3 | 4 | 5 |
| **Weighted total** | – | **76** | **70** | **78** |

(Each cell: option-score × criterion-weight; column sum at bottom.)

---

## Recommendation

**Recommended option:** <Option A — name>

**Rationale.** <one paragraph; reference the scoring, but also any
non-quantifiable factor that informs the recommendation>

**Why not the higher-scored option** (if applicable). <e.g. Option C
scored highest on the matrix but does not satisfy the success
criteria from the brief — it preserves the status quo, which the
brief explicitly rejects.>

---

## Dissent

If the recommendation turns out wrong, the next-best choice is
<Option B>. **Switch trigger:** <specific event that would cause
us to fall back to Option B — e.g. "Option A's critical assumption
fails verification by week 4">.

---

## Revisit triggers

This analysis should be re-run if any of the following occur:

- <constraint change>
- <critical assumption of chosen option proves wrong>
- <non-negotiable changes>
- <meaningfully better option emerges>
- <fixed-date review: YYYY-MM-DD>

---

## Decision record

**Decided on:** YYYY-MM-DD
**Decided by:** <name>
**Decision:** <Option A — name>
**Vote / sign-off chain:** <if relevant>

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | options drafted | <name> |
| 1 | YYYY-MM-DD | decision recorded: Option A | <name> |
