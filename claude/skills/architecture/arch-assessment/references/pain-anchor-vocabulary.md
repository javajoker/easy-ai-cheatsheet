# Pain Anchor Vocabulary

What counts as an **anchor** for a pain point in the assessment.
Anonymous gripes don't count. Each row in `## 3. Pain points`
must cite an anchor.

## Valid anchor types

| Anchor type | Example citation |
|---|---|
| **Incident postmortem** | "Incident 2026-03-12 — DB CPU 95% during EU hours; mitigation: temp read replica" |
| **Production metric** | "Grafana dashboard `db-health` (link) — p95 query duration 2.4× baseline EU business hours, sustained 30 days" |
| **Alert volume** | "PagerDuty: 14 fires in the last 30 days for `db-cpu-high`" |
| **Support ticket pattern** | "Zendesk: 23 tickets in 90d mentioning `slow load times` correlated with EU hours" |
| **Eng-team retro theme** | "Retro 2026-04 — 4 of 6 engineers raised deploy-coupling friction" |
| **Stakeholder interview** | "VP Eng interview 2026-04-22: deploy of API requires worker restart, blocks Friday releases" |
| **Cost report** | "AWS bill — DB instance class `db.r6g.4xlarge` reaching CPU ceiling; vertical scale runway 90d" |
| **Survey / NPS** | "Internal eng survey Q1: 68% rate deploy process below 'acceptable'" |

## Invalid anchors (rejected at write-up time)

- "We feel slow."
- "Things seem fragile."
- "The team is frustrated."
- "I think there's a problem with X."
- "It's been an issue for a while."

These get **rephrased as a finding** *or* the assessor goes and
finds a real anchor before including the pain point.

## Anchor confidence

Even with an anchor, label confidence:

- **(confirmed)** — anchor is a primary source (incident report,
  raw metric, stakeholder quote).
- **(inferred)** — anchor is secondary (assumed from observation,
  derived from related data).

The walkthrough at end of `arch-assessment` walks every `(inferred)`
to confirm or correct.

## Format guidance

Pain point rows in `## 3. Pain points` use this shape:

```markdown
| # | Symptom | Anchor | Affected components | Cost of doing nothing |
|---|---|---|---|---|
| P1 | <one-line symptom> | <citation type + link> *(confirmed/inferred)* | <component list> | <operational/business/velocity impact> |
```
