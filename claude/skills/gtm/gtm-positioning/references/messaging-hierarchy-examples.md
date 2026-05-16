# Messaging Hierarchy Examples

The **messaging hierarchy** is the structure that takes your
value proposition and breaks it into headlines + supporting
pillars + proof points. Used to write the marketing site, the
sales deck, the launch announcement.

## Structure

```
Headline                           ← one sentence
  ├── Pillar 1                     ← supporting claim
  │   ├── Proof point 1.1          ← evidence
  │   ├── Proof point 1.2
  │   └── Proof point 1.3
  ├── Pillar 2
  │   └── ...
  └── Pillar 3
      └── ...
```

**Default cap:** 1 headline + 3 pillars + 2–4 proof points per
pillar. More than 3 pillars → diluted message; fewer than 2
proof points per pillar → unsupported claim.

---

## Example 1 — Developer infrastructure (Stripe-style)

**Category:** Online payments

**Value proposition:** "Accept payments online — without the
hassle."

### Headline

> Payments for the internet, built for developers.

### Pillar 1 — Developer-first

> One API, every payment method, every country.

- Proof: SDKs in 10 languages, all generated from one OpenAPI spec.
- Proof: Test mode + sandbox indistinguishable from production.
- Proof: 99.99% API uptime SLA (publicly tracked).
- Proof: < 50ms p95 API latency globally.

### Pillar 2 — Comprehensive

> From day one or scale to billions — same platform.

- Proof: Stripe Atlas for startups (form a company + accept money).
- Proof: Stripe Treasury for embedded finance.
- Proof: Customers from Shopify to Salesforce.

### Pillar 3 — Trusted

> Built for the security + compliance you need.

- Proof: PCI Level 1 certified.
- Proof: SOC2 Type II.
- Proof: Available in 47 countries, compliant with each.

---

## Example 2 — Observability platform

**Category:** Open-source observability platform

**Value proposition:** "Open-source observability without the
ops burden."

### Headline

> The observability platform you can host yourself — or have us
> host it for you.

### Pillar 1 — OpenTelemetry-native

> Standards, not lock-in.

- Proof: OTel instrumentation + collector; no proprietary agent.
- Proof: Export to any backend with one config change.
- Proof: Active contributor to OTel project.

### Pillar 2 — Cost-effective at scale

> Open-source means cost predictability.

- Proof: 70% lower than equivalent SaaS at 1B events/day.
- Proof: Self-host = control your spend; managed = predictable.
- Proof: Pricing calculator + customer case studies.

### Pillar 3 — Production-ready

> Tools your SRE team actually wants.

- Proof: Used in production by N companies (logos).
- Proof: 99.9% SLA on managed offering.
- Proof: 24x7 enterprise support available.

---

## Example 3 — B2B SaaS for non-technical buyer

**Category:** Customer success platform

**Value proposition:** "Know which customers will churn — before
they do."

### Headline

> Predict churn. Prevent churn. Plain English.

### Pillar 1 — Predictive

> Health scores driven by AI + usage data, not gut feel.

- Proof: 87% accuracy predicting churn 60 days out (per study).
- Proof: Integrates 200+ signals from product + support tools.
- Proof: Confidence-weighted scores — no false positives.

### Pillar 2 — Actionable

> Every prediction comes with a recommended action.

- Proof: Playbook library: "If X is at risk, do Y."
- Proof: One-click ticket creation in your CS tool.
- Proof: Customer success ROI dashboard.

### Pillar 3 — Quick to value

> Live in 2 weeks; ROI in 1 quarter.

- Proof: Onboarding service included.
- Proof: Pre-built integrations for top 50 CS + support tools.
- Proof: Customer case studies showing ROI achievement.

---

## Example 4 — Consumer mobile app

**Category:** Personal finance app

**Value proposition:** "Spend less, save more — without thinking
about it."

### Headline

> The money app that thinks so you don't have to.

### Pillar 1 — Automatic

> Set goals; we move the money.

- Proof: AI moves $X/day on average per user, towards goals.
- Proof: 4.7-star App Store rating across 500K reviews.
- Proof: Average user saves N% more than non-users (per study).

### Pillar 2 — Trustworthy

> Bank-level security; clear pricing.

- Proof: FDIC-insured partner banks.
- Proof: No hidden fees — pricing on one page.
- Proof: SOC2 Type II.

### Pillar 3 — In your pocket

> The app you check 3× a day, not 3× a month.

- Proof: Daily push: "You saved $X today."
- Proof: Apple Watch + widgets.
- Proof: Voice assistant integration.

---

## Tactical patterns

### Pillar count

- **Two pillars:** under-served. Customers can't choose between
  reasons to care.
- **Three pillars:** sweet spot. Memorable; covers the typical
  decision tree.
- **Four pillars:** acceptable if the product has genuinely
  distinct value drivers.
- **Five+ pillars:** message dilution. Cut.

### Proof point types (mix at least 3 types)

- Customer reference / logo.
- Quantitative metric (uptime %, latency, savings %).
- Public certification (SOC2, PCI, ISO).
- Industry recognition (Gartner, G2, capterra).
- Case study link.
- Demo / hands-on (sandbox URL).
- Quote from customer / analyst.

### Order pillars by buyer concern

Order matters. Lead with what the **primary buyer** cares about
most. Don't start with "secure" if the buyer's primary worry is
"will it work for my use case".

For technical buyers: feature-fit > performance > developer
experience > security.

For business buyers: ROI > time-to-value > security > references.

For users: ease-of-use > beautiful > everything else.

---

## Anti-patterns

- **Headlines that say nothing.** "The future of X" / "Reimagining
  X" — meaningless. The headline should describe the value, not
  hand-wave at it.
- **Unsupported pillars.** Pillar claims without proof points =
  marketing copy that customers discount.
- **Proof points that are just restatements.** "Pillar: easy.
  Proof: it's really easy." Show, don't tell.
- **Inconsistent voice across pillars.** Each pillar should
  reinforce the same tone established by the headline.
- **Pillars that overlap.** Pillar 1 and Pillar 2 say similar
  things → consolidate.
- **Hero metrics that age badly.** "Trusted by 50 customers"
  reads great this year; ages oddly when you reach 5000.
