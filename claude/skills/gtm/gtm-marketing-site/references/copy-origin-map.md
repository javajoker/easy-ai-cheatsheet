# Copy Origin Map — where each piece of marketing site copy comes from

The marketing site reuses positioning + pricing + PRD content
rather than re-inventing it. This map shows what comes from where.

## Page-by-page origin map

### Homepage

| Section | Origin | Notes |
|---|---|---|
| Hero headline | `positioning-brief.md` § Headline | Same exact text |
| Hero sub-headline | `positioning-brief.md` § Value proposition | Same exact text |
| Pillars (3-column) | `positioning-brief.md` § Messaging hierarchy → Pillar names | Pillar 1/2/3 → 3 columns |
| Pillar 1 body | Pillar 1's proof points 1.1 + 1.2 | Format as 1–2 sentences each |
| Pillar 2 body | Pillar 2's proof points 2.1 + 2.2 | Same |
| Pillar 3 body | Pillar 3's proof points 3.1 + 3.2 | Same |
| Social proof | Customer logos | From CRM + permission to use |
| Quote section | Customer quotes | Solicit; permission required |
| CTA | Sign-up / contact form | Wired to backend or vendor (HubSpot etc.) |

### Pricing page

| Section | Origin |
|---|---|
| Tier names | `pricing-model.md` § Tiers |
| Per-tier features list | `pricing-model.md` § Feature assignment |
| Per-tier prices | `pricing-model.md` § Pricing |
| Comparison table | Generated from feature assignment matrix |
| FAQ section | `pricing-model.md` § Common questions + custom |
| Discount policy summary | `discount-policy-template.md` § Categories (filtered to customer-relevant only) |

### Features pages (one per major feature)

| Section | Origin |
|---|---|
| Feature name | `PRD.md` § Feature list |
| Headline | `positioning-brief.md` + feature-specific value prop |
| Description | `PRD.md` § Feature description (rewritten for marketing voice) |
| Use cases | `PRD.md` § User stories (filtered + reframed) |
| Screenshots / demo | Product screens; designed |

### About page

| Section | Origin |
|---|---|
| Mission | `positioning-brief.md` § Category re-frame OR explicit mission statement |
| Team | Marketing-owned content |
| Investors / advisors | Marketing-owned (if applicable) |
| Press / awards | Marketing-owned |

### Blog / Resources

| Section | Origin |
|---|---|
| Posts | Marketing-owned editorial calendar |
| Categories | Aligned with messaging-hierarchy pillars |

### Contact / Sales

| Section | Origin |
|---|---|
| Form | Built by `gtm-marketing-site`; wired to chosen handler (email / HubSpot / Pipedrive / Mailchimp) |
| Confirmation copy | Marketing-owned |

---

## Voice + tone (from positioning)

The site's voice comes from `positioning-brief.md` § Voice:

- Tone: <e.g. "Direct, technical, slightly playful">
- Register: <e.g. "Conversational; assumes intelligent reader">
- What we sound like: <e.g. "Honest engineer talking to a peer">
- What we don't sound like: <e.g. "Salesy, jargon-laden, hyperbolic">

Every page should be readable in the declared voice. If a page
sounds different (e.g. legal page must sound formal), that's
intentional but documented.

---

## Update cadence

When source documents change, site copy updates:

| Source change | Site impact |
|---|---|
| `positioning-brief.md` headline | Homepage hero — manual update |
| `positioning-brief.md` pillar | Homepage columns + relevant feature pages — manual update |
| `pricing-model.md` tier name / price | Pricing page — manual update; backend pricing pages may need code change |
| `PRD.md` feature add | New feature page (or feature added to existing) |
| `PRD.md` feature deprecation | Feature page sunsetted (or marked deprecated) |
| Customer logo permission added | Social proof section |
| New customer quote | Quote section |

---

## Diff discipline

Mark every site update with the source document version:

```html
<!-- Last source: positioning-brief.md v2 (2026-04-22) -->
<section class="hero">
  ...
</section>
```

When the source changes, grep for the old version + update.

---

## Anti-patterns

- **Reinventing copy on the marketing site.** Site copy drifts
  from positioning; sales pitch contradicts site; customers
  confused.
- **Marketing-only edits to positioning.** Marketing rewrites a
  pillar on the site → positioning brief stale → product /
  sales misaligned. Update the source first; site follows.
- **No origin tags.** When source documents update, no
  systematic way to find affected site copy.
- **Out-of-date customer logos.** Customer churns / doesn't want
  to be featured → site shows them anyway. Quarterly review.
- **Feature pages for features that don't exist yet.** "Coming
  soon" → SEO indexes them → customers click → disappointment.
  Don't pre-publish.
