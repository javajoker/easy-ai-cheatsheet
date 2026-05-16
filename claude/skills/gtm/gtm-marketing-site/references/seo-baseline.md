# SEO Baseline for Marketing Site

Opinionated SEO baseline for a new marketing site. Not exhaustive;
covers the high-leverage items that move the needle without
becoming SEO-as-religion.

## On-page basics (every page)

### `<head>` requirements

```html
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">

  <!-- Title: 50-60 chars; brand at end -->
  <title>Page-specific value prop — Brand</title>

  <!-- Description: 150-160 chars; action-oriented -->
  <meta name="description" content="Concrete description of what this page offers; pass the so-what test.">

  <!-- Canonical: prevent dup-content issues -->
  <link rel="canonical" href="https://example.com/this-page">

  <!-- Open Graph (Facebook/LinkedIn/etc.) -->
  <meta property="og:title" content="Same as title or richer">
  <meta property="og:description" content="Same as description or richer">
  <meta property="og:image" content="https://example.com/og-image-1200x630.png">
  <meta property="og:url" content="https://example.com/this-page">
  <meta property="og:type" content="website">

  <!-- Twitter card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="...">
  <meta name="twitter:description" content="...">
  <meta name="twitter:image" content="https://example.com/twitter-image-1200x600.png">

  <!-- Robots: explicit is better than implicit -->
  <meta name="robots" content="index, follow">
</head>
```

### Heading hierarchy

- **One** `<h1>` per page.
- `<h2>` for major sections; `<h3>` nested.
- Don't skip levels (no `<h1>` → `<h3>`).
- Headings used for **content** structure, not styling — use CSS
  for visual hierarchy.

### Body content

- **First paragraph** restates value prop in plain English.
- **Word count** depends on page type:
  - Home: 200–500 visible words.
  - Pricing: 100–300 words.
  - Feature pages: 500–1500 words.
  - Blog posts: 1000+ words (industry standard for ranking).
- **Internal links** to related pages (3–7 per page).
- **External links** to authoritative sources where appropriate.

---

## Sitemap + robots

### `sitemap.xml`

Auto-generated from the site's route table. Includes:

- All public pages.
- `lastmod` timestamps.
- `priority` (home = 1.0; main pages = 0.8; blog = 0.6).

Submitted to:

- Google Search Console.
- Bing Webmaster Tools.

### `robots.txt`

```
User-agent: *
Allow: /

# Don't index utility paths
Disallow: /api/
Disallow: /admin/

Sitemap: https://example.com/sitemap.xml
```

---

## Structured data (JSON-LD)

For the homepage:

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "Brand Name",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "description": "One-sentence description.",
  "sameAs": [
    "https://twitter.com/brand",
    "https://linkedin.com/company/brand",
    "https://github.com/brand"
  ]
}
</script>
```

For product pages (`Product` schema), pricing pages
(`Offer` schema), blog posts (`Article` schema). See
[schema.org](https://schema.org) for the full vocabulary.

---

## Performance (Core Web Vitals)

| Metric | Target | Why |
|---|---|---|
| LCP (Largest Contentful Paint) | < 2.5s | Visual loading |
| INP (Interaction to Next Paint) | < 200ms | Responsiveness |
| CLS (Cumulative Layout Shift) | < 0.1 | Visual stability |

Tools:

- Lighthouse (in dev).
- PageSpeed Insights (real-world data).
- Search Console Core Web Vitals report.

Common wins:

- Image lazy-loading + modern formats (WebP / AVIF).
- Font preloading + `font-display: swap`.
- Reduce JS bundle size (tree-shaking + code splitting).
- Static rendering / SSG for marketing pages (Vite static, Next
  static export, Astro).

---

## URLs

| Pattern | Use |
|---|---|
| `/` | Homepage |
| `/pricing` | Pricing |
| `/features/<feature-slug>` | Feature pages |
| `/about` | Company / team |
| `/blog/<post-slug>` | Blog posts |
| `/<category>/<post-slug>` | Categorised content |

Rules:

- Lowercase, hyphenated.
- Short but descriptive.
- Avoid querystring params for canonical pages.
- Trailing slash consistency (pick one; redirect the other).

---

## Internal linking

Build content clusters around primary keywords:

```
pillar page (broad topic) — e.g. "Customer Success"
├── topic page 1 — "Health Scores"
├── topic page 2 — "Churn Prediction"
├── topic page 3 — "Renewals Playbook"
└── topic page 4 — "QBR Templates"
```

Each topic page links to pillar; pillar links to all topics.
Internal-linking signals authority.

---

## Backlink strategy (post-launch)

Not part of the site itself, but the site should be link-worthy:

- **Original research / data reports** — high-value, easily cited.
- **Free tools** (e.g. ROI calculator) — link magnets.
- **Comparison pages** ("X vs Y") — captures comparison-shopping
  search intent.

---

## What NOT to do

- ❌ Keyword stuffing. (Modern search engines penalise.)
- ❌ Cloaking (different content to bots vs users).
- ❌ Buying low-quality backlinks.
- ❌ Duplicate content across pages (use canonical to consolidate).
- ❌ Thin content (200-word pages targeting valuable queries).
- ❌ Auto-generated content for SEO (modern AI detection
  penalises).
- ❌ "SEO-first" copy that sacrifices clarity.

---

## Monitoring

Set up:

- **Google Search Console** + **Bing Webmaster Tools** —
  indexing, queries, performance.
- **Plausible / GA4** — traffic + behaviour.
- **Lighthouse CI** — Core Web Vitals on every deploy.
- **Search rank tracker** (Ahrefs / SEMrush / similar) — top
  keyword rankings monthly.

Track:

- Organic traffic.
- Top-ranking keywords.
- Bounce rate per page.
- Conversion (signup) rate per source.
- Core Web Vitals score.

---

## Anti-patterns

- **Treating SEO as one-time.** Drift sets in within 6 months.
- **Indexing everything.** Some pages (login, internal admin)
  shouldn't be indexed. Use `noindex` for those.
- **Premature optimization.** Don't over-engineer SEO before you
  have content worth ranking.
- **SEO without content strategy.** Technical SEO can't save
  thin or generic content.
