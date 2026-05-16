# SLO Worksheet — per critical journey

One worksheet per critical user journey. Fill in before deploying
SLO alerts; review quarterly.

---

## Journey: <name>

**One-sentence description.** <e.g. "Signup completion — user
submits the signup form and receives the welcome email">

**Why this journey is critical.** <e.g. "Top of the activation
funnel; failures here block all downstream value">

---

## Service Level Indicator (SLI)

**What we measure.** <e.g. "% of signup attempts that complete
within 5 seconds end-to-end (form submit → welcome email queued)">

**Why this SLI.** <e.g. "Captures user perception; the email is
the value moment">

**Query / definition.** <Promql / Honeycomb / Datadog query that
computes the SLI>

```
sum(rate(signup_completed_total{success="true"}[5m]))
/
sum(rate(signup_attempt_total[5m]))
```

**Excluded from SLI numerator/denominator.**

- <e.g. "Bot signups (User-Agent matching bot patterns) excluded
  from both">
- <e.g. "Synthetic monitor traffic excluded">

---

## Service Level Objective (SLO)

**Target.** <e.g. 99.9% over rolling 30 days>

**Rationale.** <one paragraph — why this target, not higher or
lower>

**Error budget.** <derived: 0.1% = ~43.2 minutes of allowable
misses per 30 days>

---

## Burn-rate alerts

Two alert windows; both fire BEFORE the budget is spent.

| Alert | Burn rate | Window | Page? | Why |
|---|---|---|---|---|
| Fast burn | >14.4× | 5 min | yes | Consumes 1h budget in 5 min — about to be a real incident |
| Slow burn | >6× | 6h | no, notify | Consumes 6h budget in 6h — sustained degradation |

(Multi-window-multi-burn-rate from the Google SRE book; tune if
the SLO target differs from 99.9%.)

---

## Routing

| Field | Value |
|---|---|
| Dashboard URL | <link> |
| Runbook URL | <link to per-journey runbook from `devops-incident-runbook`> |
| First responder | <on-call rotation name> |
| Owner team | <team name> |
| Slack channel | <channel> |

---

## Review

**Last reviewed:** YYYY-MM-DD
**Next review:** YYYY-MM-DD (quarterly)

**Review questions:**

- Is the SLI still measuring the right thing? (User behaviour
  changes; what mattered last quarter may not now.)
- Is the target still right? (Too tight → constant alerts; too
  loose → users hurting and SLO sleeps.)
- Has the journey changed shape? (New steps, new dependencies,
  new failure modes.)
- Has the runbook stayed accurate?

---

## Change log

| Date | Change | By |
|---|---|---|
| YYYY-MM-DD | initial | <name> |
