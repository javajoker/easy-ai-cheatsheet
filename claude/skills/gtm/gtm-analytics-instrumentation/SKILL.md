---
name: gtm-analytics-instrumentation
description: Designs the product-telemetry plan for a launch — event taxonomy (verb-noun naming), north-star metric, counter-metrics, funnels (acquisition / activation / retention / revenue / referral), pre-built dashboards per audience, alerts for metric deviations, and privacy posture. Output is analytics-instrumentation.md plus events.json (the events spec the frontend and backend implement) and a dashboard-spec.md per audience (CEO / PM / Eng). Distinct from devops-observability (technical telemetry — latency, errors, saturation) — this skill owns the product side. Use this skill when the user says "what do we measure at launch", "set up the analytics", "build the launch dashboards", "instrument the product"; or when lifecycle-pilot reaches Phase 7. Pairs with project-docs (user stories drive what's worth measuring), gtm-positioning (the value proposition's unique-value clause anchors the north-star metric), gtm-beta-program (beta-specific events compose alongside production events), gtm-marketing-site (site analytics use the same event names), and devops-observability (technical telemetry counterpart).
status: shipped
owner_agent: lifecycle-pilot
---

# GTM Analytics Instrumentation

Designs *what gets measured* at launch — the events, dashboards,
and alerts the team relies on to know whether the product is
working.

> Distinct from `devops-observability`. That skill owns **technical**
> telemetry (RED metrics, USE metrics, distributed tracing, SLO
> burn-rate). This skill owns **product** telemetry (signup,
> activation, retention, feature adoption, revenue). The two pair —
> both have dashboards; both have alerts — but their concerns and
> their owners are different.

## Why this exists

Launches without instrumentation discover six weeks later that
nobody knows whether anyone is using the product. By then:

- Events are added retroactively to figure out *"how did we get
  here"* — but old data is gone.
- Event names accumulate without a convention; nobody can tell
  `signup`, `user_signup`, `signed_up`, `account_created` apart.
- The team optimises for whatever metric is easiest to see, not
  the one that matters.
- Privacy reviews catch the team retroactively for tracking PII
  by accident.

This skill ships the instrumentation plan *before* launch, with
naming convention, north-star, funnels, and privacy posture
locked in.

## When to fire

Fire when:

- The user says *"set up the analytics"*, *"what do we measure"*,
  *"build the dashboards"*, *"instrument the product"*.
- `lifecycle-pilot` reaches Phase 7 and no `analytics-
  instrumentation.md` exists.

Do **not** fire when:

- The product has zero users planned (no instrumentation needed
  yet).
- The team has rich analytics already and just wants tweaks —
  audit instead.

## Inputs

Required:

- `PRD.md` — user stories drive what's worth measuring.
- `positioning-brief.md` — the value-prop's *unique value* clause
  anchors the north-star metric.

Asked once (cap at 3):

1. **Analytics tool.** Plausible (default — privacy-first, simple) /
   GA4 / PostHog (default if behavioural + session replay needed) /
   Amplitude / Mixpanel / Snowplow.
2. **Data warehouse.** None (default at launch) / BigQuery /
   Snowflake / Redshift. (Warehouse maturity = post-launch concern
   for most.)
3. **Privacy posture.** Cookieless (default if Plausible) / consent-
   gated (GDPR) / opt-in only.

## The procedure

### Phase 1 — Pick the north-star metric

There is one. The number that, if it moves up, the team agrees
they're winning.

The north-star must tie to the positioning brief's *unique value*
clause. Examples:

- Positioning: *"AI-powered code review that catches bugs humans
  miss."* → North-star: **% of merged PRs where the bot caught ≥1
  bug that humans missed.**
- Positioning: *"Effortless team scheduling."* → North-star:
  **Weekly active scheduled meetings per team.**
- Positioning: *"Self-serve customer feedback aggregation."* →
  North-star: **# of insights surfaced per workspace per week.**

A north-star is **not** revenue (revenue is downstream and lagging);
it's **not** signups (signups are upstream and gameable).

### Phase 2 — Define counter-metrics

Counter-metrics catch the team optimising the north-star at the
cost of something worse:

- Load on backend (cost per unit of north-star).
- Support tickets per user (frustration).
- Churn rate (long-term retention).
- Time-to-first-value (onboarding friction).

Each counter-metric has a threshold — *"if this goes above X
while north-star is up, investigate."*

### Phase 3 — Design the funnels

The five-funnel default (Dave McClure's AARRR with adjustments):

| Funnel | Events |
|---|---|
| Acquisition | `landing_page_view`, `cta_clicked`, `signup_started`, `signup_completed` |
| Activation | `signup_completed`, `onboarding_step_1/2/3`, `first_value_reached` (custom — defined per product) |
| Retention | `session_started` per day/week; cohort retention curves |
| Revenue | `pricing_page_view`, `tier_selected`, `payment_started`, `payment_completed` |
| Referral | `invite_sent`, `invite_accepted`, `share_clicked` |

Each funnel has a **healthy ratio** target — the % expected to make
it through each step. The team alerts when ratios drop below
threshold.

### Phase 4 — Author the event taxonomy

The naming convention (non-negotiable):

- **verb_noun** snake_case (e.g. `signup_completed`, not
  `signupCompleted` or `completed_signup`).
- **Past tense** verbs (`completed`, `viewed`, `clicked` — not
  `complete`, `view`).
- **Specific subject** — `pricing_tier_selected` beats `selected`.
- **Properties for variation** — one event `pricing_tier_selected`
  with property `tier: "pro"`, not three events.
- **No PII in event names.** `user_signed_up` ✓; `john_doe_
  signed_up` ✗.

Output `events.json`:

```json
{
  "events": [
    {
      "name": "signup_completed",
      "owner": "growth",
      "rationale": "Top of activation funnel",
      "properties": [
        { "key": "method", "type": "enum", "values": ["email", "google", "github"] },
        { "key": "referrer", "type": "string", "redact": true }
      ],
      "fires_when": "Account created and email verified",
      "fires_where": "frontend (post-verify redirect)"
    },
    {
      "name": "first_value_reached",
      "owner": "product",
      "rationale": "Defines activation",
      "properties": [
        { "key": "time_to_value_seconds", "type": "number" }
      ],
      "fires_when": "User completes the activation action (defined per product)",
      "fires_where": "backend (event handler)"
    }
    // ...
  ]
}
```

The events spec is the contract frontend and backend implement.
Engineering uses it as source-of-truth; no events fire that aren't
in the spec.

### Phase 5 — Build the dashboards per audience

Three default audiences, three default dashboards:

| Audience | Dashboard contents |
|---|---|
| **CEO / Founders** | North-star + revenue + active users + 1 trend chart per week |
| **Product** | Per-funnel conversion rates; activation cohort curves; feature adoption ranked |
| **Engineering** | Per-event volume; failed events; latency of analytics pipeline itself |

Each dashboard is a separate file/spec. The user implements in
the chosen tool; the skill produces the spec.

### Phase 6 — Alerts

Alert when:

- North-star drops by >X% week-over-week.
- Any funnel step's conversion drops by >Y% week-over-week.
- A counter-metric crosses its threshold while north-star is
  unchanged or up (the "winning unsustainably" alert).
- Event volume drops to zero on an event that should fire
  continuously (instrumentation broke).

Each alert routes to: Slack channel + on-call if persistent.

### Phase 7 — Privacy posture

Document:

- **What is tracked** — the event list.
- **What is *not* tracked** — explicitly. (PII fields, sensitive
  app surfaces.)
- **Redaction** — properties marked `redact: true` are hashed
  before storage.
- **Opt-out** — every user has a documented way to opt out of
  product analytics (independently of consent banner if GDPR).
- **Retention** — how long event data is kept. (Default 25
  months for warehouse; tool-default for the analytics tool.)
- **DPA** — analytics tool's DPA reviewed and on file.

### Phase 8 — Emit the plan

Write:

- `analytics-instrumentation.md` — the human-readable plan.
- `events.json` — the engineering-implementable spec.
- `dashboards/ceo.md`, `dashboards/product.md`,
  `dashboards/engineering.md` — per-audience dashboard specs.
- `alerts.md` — alert configuration.
- `privacy-posture.md` — privacy documentation for compliance.

Persist as `type: project` memory (`analytics_<slug>_v1`).

## Anti-patterns

- **More events ≠ more insight.** A taxonomy of 200 events that
  nobody looks at is worse than 20 that everyone watches. Cap
  the launch taxonomy at ~30 events.
- **Vanity metrics as north-star.** Signups, page views, total
  registered users — gameable, lagging, doesn't reflect product
  value. Anchor north-star to *unique value*.
- **PII in events.** Email addresses, names, IDs — easy to slip
  in, expensive to remove later. Audit before launch.
- **Tracking before the event spec exists.** Each ad hoc `track()`
  call without an `events.json` entry creates technical debt.
  Enforce the spec.
- **One dashboard for everyone.** Engineering wants different
  numbers than the CEO. Build per-audience.
- **No "instrumentation broke" alert.** When events stop firing,
  the team finds out from product confusion days later. Alert on
  it directly.

## Companion skills

- `project-docs` — user stories.
- `gtm-positioning` — anchors the north-star.
- `gtm-beta-program` — beta-specific events compose.
- `gtm-marketing-site` — site uses the same event names.
- `devops-observability` — technical telemetry counterpart.
- `memory-ontology` — persist the locked plan.

## Reference files

- [references/events-json-schema.md](references/events-json-schema.md) —
  schema for `events.json` with validation rules.
- `references/north-star-examples.md` — worked examples of
  north-star metrics tied to positioning across product types.
- `references/dashboard-templates/` — starter templates for the
  three audience dashboards in common tools (Plausible / PostHog
  / GA4).
- `references/privacy-checklist.md` — the privacy posture
  checklist enforced at lock time.
