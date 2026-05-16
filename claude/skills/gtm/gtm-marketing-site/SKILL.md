---
name: gtm-marketing-site
description: Generates a runnable marketing site (Vite + React + Tailwind + i18n by default) from the positioning brief, pricing model, and PRD. Produces home, pricing, features, about, and contact pages with an SEO baseline (sitemap, robots.txt, structured data, OpenGraph) and an analytics snippet pre-wired to events defined by gtm-analytics-instrumentation. Output is a tar archive ready to deploy to Vercel / Cloudflare Pages / Netlify / S3+CF. Use this skill when the user asks "build the marketing site", "generate the landing page", "we need a pricing page", "build the launch site". Pairs with gtm-positioning (consumes the brief — headline + pillars become hero + sections), gtm-pricing-model (renders the tier table), gtm-analytics-instrumentation (event names + analytics snippet), project-frontend (shares Vite + React + Tailwind tooling but uses a marketing-shaped template), and devops-iac (site hosting + DNS).
status: shipped
owner_agent: lifecycle-pilot
---

# GTM Marketing Site

Generates the marketing site — a *separate* artifact from the
product frontend. Same build tooling family (Vite + React +
Tailwind), but a marketing-shaped template optimised for SEO,
conversion, and analytics, not application UX.

## Why this exists

Teams default to one of two failure shapes:

1. **Ship the product frontend as the marketing site.** Application
   UX makes a poor sales surface — wrong information density, wrong
   priorities above the fold, wrong page-to-page navigation.
2. **Hand-roll a marketing site with no positioning input.** The
   site says different things than the pricing page, which says
   different things than the sales deck. Customers lose the plot.

This skill produces a site that:

- Pulls hero copy directly from the locked positioning brief.
- Renders the locked pricing model as the pricing page.
- Pre-wires the analytics events the team will watch at launch.
- Uses the same i18n approach as the product frontend so en + zh-TW
  copy stays consistent across surfaces.

## When to fire

Fire when:

- The user says *"build the marketing site"*, *"generate the
  landing page"*, *"build the launch site"*.
- `lifecycle-pilot` reaches Phase 7 and both `positioning-brief.md`
  and `pricing-model.md` exist.

Do **not** fire when:

- No positioning brief exists yet (run `gtm-positioning` first).
- No pricing model exists yet (run `gtm-pricing-model` first).
- The user wants a custom design system the framework's default
  doesn't fit — produce the structure and copy, but the user
  installs their own design system.

## Inputs

Required (skill refuses to run if missing):

- `positioning-brief.md` — headline, pillars, proof points,
  voice + tone.
- `pricing-model.md` — tiers and feature-tier matrix.
- `PRD.md` — features list (optional but useful — drives the
  Features page).

Asked once:

1. **Locales.** Default en + zh-TW. Specify others.
2. **Hosting target.** Vercel (default) / Cloudflare Pages /
   Netlify / S3 + CloudFront / GitHub Pages.
3. **Analytics tool.** Plausible (default) / GA4 / PostHog /
   Fathom / none.
4. **Contact form handler.** Default: mailto + form post to a
   serverless function stub the user wires up. Pluggable: HubSpot
   / Pipedrive / Mailchimp.

## The procedure

### Phase 1 — Compose copy from positioning

For each page:

| Page | Copy source |
|---|---|
| Home / hero | Positioning brief: headline + pillar 1 |
| Home / 3-pillar section | Positioning brief: 3 pillars + 1 proof point each |
| Home / proof section | Positioning brief: remaining proof points + (optional) customer quotes |
| Pricing | Pricing model: tier table + feature-tier matrix as comparison grid |
| Features | PRD: P0 features promoted; P1 below; P2 in "Coming soon" |
| About / Company | Stub the team fills in |
| Contact / Sales | Form with serverless function stub |

The skill **does not invent copy** beyond minor connective text.
If a section has no source copy, surface to the user before
making it up.

### Phase 2 — Scaffold the project

Generate a Vite + React + TypeScript project:

```
marketing-site/
├── package.json
├── vite.config.ts
├── tailwind.config.ts
├── tsconfig.json
├── index.html              # base meta + OG fallbacks
├── public/
│   ├── robots.txt
│   ├── sitemap.xml         # generated at build time
│   ├── og-default.png      # OG fallback image
│   └── favicon.ico
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── i18n/
│   │   ├── index.ts
│   │   ├── en.json
│   │   └── zh-TW.json
│   ├── pages/
│   │   ├── Home.tsx
│   │   ├── Pricing.tsx
│   │   ├── Features.tsx
│   │   ├── About.tsx
│   │   └── Contact.tsx
│   ├── components/
│   │   ├── Hero.tsx
│   │   ├── PillarSection.tsx
│   │   ├── PricingTable.tsx
│   │   ├── FeatureGrid.tsx
│   │   ├── ContactForm.tsx
│   │   ├── Nav.tsx
│   │   └── Footer.tsx
│   ├── lib/
│   │   ├── analytics.ts    # event helper; wraps chosen tool
│   │   └── seo.tsx         # structured data + OG helpers
│   └── styles/
│       └── globals.css
├── content/                # copy lifted from positioning + pricing
│   ├── positioning.json    # generated from positioning-brief.md
│   ├── pricing.json        # generated from pricing-model.md
│   └── features.json       # generated from PRD
└── README.md
```

`content/*.json` files are the bridge — copy is pulled from the
project docs into structured JSON the components render. Updating
the brief and regenerating these files keeps the site in sync.

### Phase 3 — SEO baseline

- **sitemap.xml** generated from the route table.
- **robots.txt** allows all by default; project can override.
- **Structured data** (JSON-LD): Organization, Product (per tier),
  WebSite.
- **OpenGraph** + Twitter card meta on every page; per-page
  `og:image` falls back to default.
- **Meta description** per page; sourced from positioning brief.
- **Canonical URL** per page.
- **hreflang** tags for each locale.

### Phase 4 — Analytics snippet

Wire the chosen tool (Plausible by default) and import the event
names from `gtm-analytics-instrumentation` output:

```ts
// src/lib/analytics.ts
import { track } from './<tool-wrapper>';

export const events = {
  // generated from gtm-analytics-instrumentation/events.json
  cta_clicked: (loc: string) => track('cta_clicked', { loc }),
  pricing_tier_viewed: (tier: string) => track('pricing_tier_viewed', { tier }),
  signup_started: () => track('signup_started'),
  contact_form_submitted: () => track('contact_form_submitted'),
  // ...
};
```

Components import from `events`, never call `track` directly. This
keeps the event names in one place and matches the analytics spec.

### Phase 5 — Hosting + deploy

Generate `README.md` with:

- Local dev: `pnpm install && pnpm dev`.
- Production build: `pnpm build`.
- Deploy commands for the chosen hosting target.
- Environment variables (analytics key, form handler URL).
- Custom-domain + TLS setup pointing at `devops-iac` for the DNS
  side.

Package the project as `marketing-site.tar.gz` and place it in
`/mnt/user-data/outputs/` (or the user's specified output path).

### Phase 6 — Hand-off

After generation:

1. Surface the file list and copy origin map ("hero copy is from
   positioning-brief.md pillar 1; pricing copy is from
   pricing-model.md").
2. List any sections the user must fill in (typically About /
   Company copy, team photos, customer logos).
3. Flag any positioning ↔ pricing mismatches found during
   generation (e.g. pricing tier's target ICP isn't named in the
   positioning brief).
4. Persist as `type: project` memory (`marketing_site_<slug>_v1`).

## Anti-patterns

- **Inventing copy.** If positioning + pricing don't supply the
  copy, surface the gap. Don't write marketing copy from
  imagination — it will conflict with the rest of GTM.
- **Cleverness over clarity.** The hero is for buyers who arrived
  10 seconds ago. They need to know what this is in 5 seconds.
  Resist clever framing that needs the user to think.
- **No analytics on the CTAs.** Every CTA is an instrumented
  event. If you can't see what's converting, you can't optimise.
- **Hardcoded copy in components.** Copy lives in `content/*.json`
  (which mirrors positioning + pricing). Components render; they
  don't author.
- **Skipping i18n.** Even English-only launches should ship the
  i18n harness so a future locale doesn't require a rewrite.
- **Shipping without sitemap + structured data.** SEO baseline
  is hours of work and weeks of compounding benefit. Don't skip.

## Companion skills

- `gtm-positioning` — copy source.
- `gtm-pricing-model` — pricing source.
- `gtm-analytics-instrumentation` — event names.
- `project-frontend` — shared tooling family.
- `project-docs` — PRD provides features list.
- `devops-iac` — DNS + hosting.

## Reference files

- [references/site-template/](references/site-template/) — the
  scaffolded project structure the skill generates.
- `references/seo-baseline.md` — SEO checklist the skill enforces.
- `references/copy-origin-map.md` — explains which positioning /
  pricing fields drive which page sections.
