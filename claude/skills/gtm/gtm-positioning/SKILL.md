---
name: gtm-positioning
description: Produces a positioning brief — category, ideal customer profile (ICP), anti-ICP, value proposition, differentiation against named competitors, messaging hierarchy (headline → pillars → proof points), and voice. Reads the PRD as the product input, asks the user for market context (named competitors, current positioning attempts, brand voice cues). Output is positioning-brief.md, designed to feed gtm-pricing-model, gtm-marketing-site, gtm-beta-program, and sales/marketing artifacts. Use this skill when the user is preparing to launch and needs positioning before any marketing asset can be written; or when they say "write the positioning", "what's our message", "who is this for", "how do we differentiate". Pairs with project-docs (consumes PRD), cognitive-alignment (category and ICP terms are load-bearing — locking them prevents months of rewrites later), gtm-pricing-model (pricing follows positioning), and gtm-marketing-site (positioning drives every page).
status: shipped
owner_agent: lifecycle-pilot
---

# GTM Positioning

Turns a product into a *positioned* product. Without positioning,
marketing copy drifts, sales calls re-explain the product from
scratch, and customers can't tell what category to mentally file
this under.

## Why this exists

Positioning is the load-bearing decision underneath every downstream
GTM artifact:

- Pricing tiers map to ICP segments — no ICP, no tier rationale.
- Marketing copy lives or dies by the headline + 3 pillars — these
  come from the messaging hierarchy.
- Sales conversations open with the category framing — pick the
  wrong category and the buyer's frame is wrong from the start.
- Competitive responses sound defensive without explicit
  differentiation.

Engineering teams ship products without positioning constantly; the
artifacts they produce afterward are then unfixable because the
foundation isn't there. This skill enforces the discipline of
positioning *before* any GTM asset is generated.

## When to fire

Fire when:

- The user says *"write the positioning"*, *"what's our message"*,
  *"who is this for"*, *"how do we differentiate"*.
- `lifecycle-pilot` reaches Phase 7 (GTM) and no positioning brief
  exists.
- A downstream GTM skill (`gtm-marketing-site`, `gtm-pricing-model`,
  `gtm-beta-program`) is about to fire and there is no
  `positioning-brief.md` in the project.

Do **not** fire when:

- The product is pre-PRD (positioning needs a defined product to
  position).
- The team has already shipped a brief they want to keep (offer to
  *review* instead of *replace*).
- The user just wants tagline help — that's a copy task; this skill
  is the foundation, not the copy.

## Inputs

Required:

- **PRD** (from `project-docs`). The product's defined capabilities,
  personas, business goals.

Asked at the start (cap at 5 questions; offer reasonable defaults):

1. **Category framing.** "Are we entering an existing category, or
   defining a new one?" (Existing is the safer default; new
   categories are 5–10× harder to land.)
2. **Named competitors.** 3–5 by name. If the user can't name them,
   that's a signal the product's category is unclear.
3. **Brand voice cues.** 2–3 adjectives the brand sounds like; 2–3
   the brand does *not* sound like.
4. **Buyer vs user.** Who pays, who uses? Often different in B2B;
   identical in many B2C cases.
5. **Stage of customer awareness.** Unaware → problem-aware →
   solution-aware → product-aware → most aware (Schwartz's
   taxonomy). Decides whether copy needs to teach or to sell.

## The procedure

### Phase 1 — Read PRD + lock category

Open PRD.md. Pull personas, feature list, business model, target
scale. Decide category framing with the user — *"file this against
existing X"* or *"create a new category called Y"*.

Lock the category language via `cognitive-alignment` before any
brief is written. Category language is the single hardest thing to
change later.

### Phase 2 — Define ICP

From the PRD's personas plus the user's market input, write the ICP:

- **Firmographics** (B2B): company size, industry, geography,
  org structure, tech stack.
- **Demographics** (B2C): age range, life stage, geography,
  income bracket if it matters.
- **Behaviours**: what they already do today that this product
  replaces / augments / threatens.
- **Problems**: the top 3 problems this customer has *that this
  product addresses*. Stated in the customer's words, not the
  product's words.
- **Triggers**: what event in their life / business causes them to
  start looking for a product like this.

### Phase 3 — Define anti-ICP

Just as important as ICP. Who is this product *not* for? List 2–3
adjacent profiles the product is *not* designed for, with one-line
reasons. This saves sales time and prevents bad-fit churn.

### Phase 4 — Value proposition (one sentence)

Apply the "so what" test: every clause has to earn its place.

A workable template (not mandatory): **For [ICP] who [problem /
trigger], [product] is a [category] that [unique value]. Unlike
[alternative], we [differentiation].**

Iterate until it passes the "so what" test out loud (read it; ask
"so what?"; the sentence either has an answer or it doesn't).

### Phase 5 — Differentiation against named competitors

For each named competitor:

- **What they do well.** Stated honestly (defensive positioning
  fools nobody).
- **What this product does differently.** Specific. Not "better" —
  *differently*, with the *who-it's-for* attached.
- **What this product does *less well*.** Acknowledged. Anchored
  to deliberate scope choices.

The differentiation row is what the marketing copy lifts from.
Vague differentiation produces vague copy.

### Phase 6 — Messaging hierarchy

Structured as a tree:

- **Headline.** One sentence; passes the "so what" test; ideally
  ≤12 words.
- **Three pillars.** The three things this product is about, in
  priority order. The hero pillar is the headline's anchor.
- **Per-pillar proof points.** 2–4 each. Specific, testable
  claims. Tied to product capabilities documented in the PRD.

The hierarchy is the source the marketing site, sales deck, and
launch email all pull from. If a downstream artifact says
something that's not in the hierarchy, either the artifact is
off-message or the hierarchy needs to grow.

### Phase 7 — Voice + tone

- **Voice** (consistent): the personality. Adjectives.
- **Tone** (varies by context): formal in policy docs, conversational
  in onboarding emails.
- **What we sound like.** 2–3 examples.
- **What we don't sound like.** 2–3 examples. (The negative list
  catches drift faster than the positive list.)

### Phase 8 — Emit the brief

Write `positioning-brief.md` (default location: project root or
`docs/gtm/positioning-brief.md`). Use the template in
[references/positioning-brief-template.md](references/positioning-brief-template.md).

After writing, surface the brief to the user and ask for one round
of edits before treating it as locked. A locked brief gets a memory
entry (`type: project`, `positioning_<slug>_v1`) so future GTM
skills can rely on its stability.

## Anti-patterns

- **Differentiating on features.** Features change; positioning
  shouldn't. Differentiate on *for whom* and *what kind of value*.
- **Vague ICP.** *"SMBs"* or *"developers"* is not an ICP — too
  broad to anchor the rest of the brief. Get specific.
- **Skipping anti-ICP.** Without it, sales chases anyone with a
  pulse and the product accumulates technical debt serving
  unsuitable customers.
- **Three headlines.** There is one headline; the pillars are
  *not* alternate headlines.
- **Marketing-team-only language.** If engineering can't recite the
  pillars, the pillars won't survive a product roadmap meeting.
  Validate the brief with the eng team before locking.
- **No competitor named honestly.** Pretending competitors don't
  exist or only naming weak ones erodes trust. Name the real ones.

## Companion skills

- `project-docs` — PRD is the product input.
- `cognitive-alignment` — lock the load-bearing terms (category,
  ICP, problems-in-customer-words) before they recur everywhere.
- `gtm-pricing-model` — pricing tiers map to ICP segments.
- `gtm-marketing-site` — pulls headline + pillars + proof points.
- `gtm-beta-program` — ICP drives beta screening.
- `memory-ontology` — persist the locked brief as a `type: project`
  memory.

## Reference files

- [references/positioning-brief-template.md](references/positioning-brief-template.md) —
  the canonical output shape.
- `references/category-frame-examples.md` — worked examples of
  "existing category" vs "new category" framings.
- `references/messaging-hierarchy-examples.md` — three worked
  hierarchies across different product types.
