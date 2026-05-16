# North-Star Metric Examples

A north-star metric is **one number** that, if it moves, the team
agrees they're winning. It ties to the positioning brief's
*unique value* clause — what the product is fundamentally for.

## Properties of a good north-star

| Property | Why |
|---|---|
| **Single number** | Forces priority; no two-handed metric |
| **Customer-value-aligned** | Moving it = customers getting more value |
| **Measurable** | From product telemetry, not survey |
| **Leading, not lagging** | Predicts future revenue, not just past |
| **Movable** | Team's work demonstrably moves it |
| **Resistant to gaming** | Hard to game by hurting customer experience |
| **Memorable** | The whole team can recite it |

## What a north-star is NOT

- ❌ Revenue (lagging; teams optimise short-term unhealthy)
- ❌ Signups (upstream; gameable via lower-quality acquisition)
- ❌ DAU / MAU (proxy; often gameable by manufactured engagement)
- ❌ Vanity (downloads, pageviews — disconnected from value)

A north-star may *correlate* with revenue, but it captures
**why customers value the product**.

---

## Worked examples by product type

### Productivity tool

**Positioning:** "Where teams get work done together."

**Value moment:** A meaningful piece of work gets created or
shipped.

**North-star options:**

- ✅ Weekly active teams who shipped ≥3 docs / week.
- ✅ Median docs-created per team per week.
- ❌ Total docs created (gameable; padding doesn't deliver value).
- ❌ Daily active users (proxy; not tied to outcomes).

### Developer tool (CI / observability / etc.)

**Positioning:** "Ship better software, faster."

**Value moment:** A deploy ships successfully, with insight.

**North-star options:**

- ✅ Median deploy frequency per team (per week).
- ✅ % of merged PRs that ship to prod within 24h.
- ❌ Total CI runs (volume; doesn't reflect success).
- ❌ Logs ingested (cost, not value).

### Marketing / sales tool

**Positioning:** "Get more pipeline, faster."

**Value moment:** A lead converts to an opportunity.

**North-star options:**

- ✅ Median customer-attributed pipeline per workspace per month.
- ✅ # of sales-qualified leads sourced this week per workspace.
- ❌ Emails sent (volume; spam-correlated).
- ❌ Total contacts in the CRM (capacity, not outcome).

### Consumer mobile app (e.g. fitness)

**Positioning:** "Build the habit."

**Value moment:** User completes a workout / logs a meal /
hits a goal.

**North-star options:**

- ✅ Weekly active users who completed ≥3 workouts.
- ✅ Streak length distribution.
- ❌ Total app opens (vanity; doesn't reflect engagement quality).
- ❌ Total signups (upstream).

### Marketplace (e.g. freelance)

**Positioning:** "Get hired."

**Value moment:** A contract is signed and money flows.

**North-star options:**

- ✅ GMV (gross marketplace volume) per active seller per quarter.
- ✅ % of active sellers who closed ≥1 contract per quarter.
- ❌ Total seller signups (upstream).
- ❌ Listings posted (volume, not outcome).

### B2B SaaS — customer success focus

**Positioning:** "Save your accounts before they churn."

**Value moment:** A customer at risk gets retained.

**North-star options:**

- ✅ # of at-risk accounts who saw a CS-triggered playbook
  intervention this quarter.
- ✅ Net retention rate of cohorts using the platform.
- ❌ Total customers tracked (capacity).
- ❌ Tickets created (volume).

### Search / retrieval (RAG / KB)

**Positioning:** "Find what you need, fast."

**Value moment:** Successful search → action taken.

**North-star options:**

- ✅ % of searches that ended in a click / action within 30s.
- ✅ Median time-to-answer (search → action).
- ❌ Total searches (volume).
- ❌ Index size (capacity).

---

## Picking the north-star — process

1. **Read positioning brief** — what's the value proposition?
2. **Identify the value moment** — the specific event where the
   customer realises value.
3. **Brainstorm 3–5 candidate metrics** that measure that
   moment.
4. **Apply the property filter** — single number, customer-
   value-aligned, measurable, leading, movable, resistant to
   gaming, memorable.
5. **Stress-test:** "If we 10× this metric, would customers love
   us more, or would something else break?"
6. **Commit** — write it on the wall.

## Counter-metrics

For every north-star, name **counter-metrics** to catch gaming
or unhealthy optimisation:

| North-star | Counter-metric |
|---|---|
| Weekly active teams who shipped ≥3 docs | NPS / satisfaction (catches forced usage) |
| Deploy frequency per team | Incident rate (catches reckless deploys) |
| Pipeline per workspace | Win rate (catches stuffing pipeline with junk) |
| Active workouts per user | Injury / app-reviews complaints |
| GMV per seller | Seller satisfaction / churn |

If north-star is up but counter-metric is degraded, you're not
winning — you're harming the customer.

---

## Cadence of review

| Cadence | Action |
|---|---|
| Daily | Glance at the trend; alert on cliff |
| Weekly | Team review; discuss what moved it |
| Monthly | Counter-metric review; check for gaming |
| Quarterly | Strategic review; consider re-targeting |
| Annual | Is this still the right metric? |

---

## Anti-patterns

- **Multiple north-stars.** Defeats the purpose. Pick one;
  others are counter-metrics or secondary.
- **North-star nobody can recite.** It's not actually a north-
  star then.
- **Revenue as north-star.** Lagging; teams optimise short-term
  unhealthy patterns.
- **Vanity as north-star.** Sounds great in board meetings;
  doesn't drive customer value.
- **Changing the north-star quarterly.** No time to act on
  trends. Annual review is the cadence.
