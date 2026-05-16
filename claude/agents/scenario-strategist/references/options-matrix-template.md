# Options Matrix Template (agent-level pointer)

The canonical template lives in `scenario-analysis`:
[`skills/scenario/scenario-analysis/references/options-analysis-template.md`](../../../skills/scenario/scenario-analysis/references/options-analysis-template.md).

For architecture-specific options (during an architectural change
scenario), see [`agents/architecture-shepherd/references/options-matrix-template.md`](../../architecture-shepherd/references/options-matrix-template.md)
which points at `arch-assessment`.

## Structure (recap)

For each option:

- Description (one paragraph).
- Critical assumption (the one belief that, if wrong, makes this
  option fail).
- Time / cost estimate.
- Risk profile.

Plus a weighted scoring matrix across explicit criteria, with
recommendation + dissent.

## Discipline

- ≥2 options (single-option "analysis" is confirmation bias).
- ≤4 options (more than 4 = unreadable comparison).
- **Option 0 (do nothing / minimum action) is mandatory** — the
  baseline against which others justify themselves.
- Each criterion has an explicit weight (no "all are important").
- Recommendation + rationale + dissent + decision authority.

## When the strategist uses this

Phase 1 (Analysis) of [scenario-strategist's AGENT.md](../AGENT.md).
