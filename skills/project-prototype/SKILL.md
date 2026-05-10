---
name: project-prototype
description: >
  Generates a complete clickable HTML or React UI prototype from a plain-language project
  idea or concept description. Produces a navigable, multi-view prototype with mock data
  and basic interactions that demonstrates every major user role and primary flow — ready
  for stakeholder review or as input to the project-docs skill.

  USE THIS SKILL whenever the user is at the very earliest stage of a project and:
  - describes a new product/app/platform/marketplace idea in plain language
  - says "design a web app for...", "create a prototype for...", "I have an idea for..."
  - asks "what would this look like?" or "show me a UI mockup"
  - wants to explore a concept visually before writing any specs
  - mentions "build a prototype", "wireframe", "clickable demo", or "interactive mockup"
  - is starting Phase 1 of the project-quick-start workflow
  Even when the user only says "I'm thinking about building X" with no further direction,
  trigger this skill — generating a prototype is almost always the right next step.
---

# Project Prototype Generator

Step 1 of the project-quick-start workflow. Turns a fuzzy idea into a concrete, clickable
prototype that exposes every user role and primary flow. The output becomes the visual
basis for all later docs and code.

---

## Step 0 — Understand the Idea

Read the user's description carefully. Extract:

1. **Core concept**: One sentence — what problem does this solve and for whom?
2. **User roles**: Identify ALL distinct user types. Look for words like "creator",
   "buyer", "operator", "admin", "moderator", "member", "guest". A platform with
   "anyone can register IP and anyone can buy" has at least 3 roles: creator, buyer,
   admin (implicit).
3. **Key entities/objects**: What does the system manage? (e.g. IP assets, products,
   licenses, orders, users)
4. **Primary flows**: What does each role do end-to-end? List 2–4 flows per role.
5. **Trust/verification points**: Any place where authenticity, ownership, or
   permissions matter — these usually need their own dedicated views.

If any of these are unclear from the description, ask 1–3 short questions before
generating. Don't ask more than 3 — fill gaps with sensible defaults and call them out.

---

## Step 1 — Plan the View Inventory

Before writing any code, list every view the prototype will include. Use this
checklist to make sure nothing's missed:

### Universal views (almost every project)
- [ ] **Landing / Home** — public-facing hero, value prop, CTA
- [ ] **Sign in / Register** — auth screens with role selection if multi-role
- [ ] **Dashboard** — post-login home, role-specific
- [ ] **Profile / Settings** — account info, preferences
- [ ] **Notifications** — inline list or dropdown

### Role-specific views (one set per role)
For each role identified, include:
- [ ] **Dashboard for {role}** — role-specific home
- [ ] **List view of their items** — e.g. "My IPs", "My Products", "My Orders"
- [ ] **Detail view of one item** — drill-down with all fields and actions
- [ ] **Create / edit form** — with all relevant fields
- [ ] **Action history** — past activity, audit trail

### Marketplace / catalog views (if applicable)
- [ ] **Browse / Search** — public catalog with filters
- [ ] **Item detail (public)** — shoppable view with pricing, "Buy" CTA
- [ ] **Cart / Checkout** — multi-step flow
- [ ] **Order confirmation** — post-purchase

### Trust / verification views (if applicable)
- [ ] **Authenticity / verification** — scan or look-up flow with chain-of-trust display
- [ ] **License / authorisation chain** — visual tree showing provenance

### Admin views (almost always needed)
- [ ] **Admin dashboard** — overview metrics
- [ ] **Moderation queue** — items pending approval
- [ ] **User management** — search, suspend, role changes
- [ ] **Dispute resolution** — if applicable

Output the view inventory as a checklist BEFORE generating code, so the user can confirm
or add missing views.

---

## Step 2 — Choose the Output Format

Default to **single-file React (artifact-style)** unless the user specifies otherwise.

Decision tree:
- **Single React artifact** (default): Tailwind + lucide-react icons + simple in-memory
  routing via state. Good for quick iteration. ≤ 1500 lines.
- **Multi-file React (Vite)**: When the prototype has >15 views or the user explicitly
  asks for a project structure. Output as files saved to `/mnt/user-data/outputs/`.
- **Plain HTML + Tailwind CDN**: When the user requests "no framework" or wants
  a single static file shareable as-is.

For Claude.ai chat artifacts, prefer the single React artifact path — render directly
in the chat and let the user click through it.

---

## Step 3 — Generate the Prototype

### Quality bar (non-negotiable)
- Every view in the inventory is reachable from the navigation
- Mock data feels realistic — not "Lorem ipsum" or "Item 1, Item 2, Item 3"
- Every form has at least 3 plausible fields with sensible placeholders
- Every list has at least 5 mock items with varied data
- Detail views show ALL the metadata that would exist (status badges, timestamps,
  related items, action buttons)
- Role switching is supported — a "demo controls" panel lets the user simulate
  different roles without real auth
- All primary CTAs (Buy, Apply for License, Submit, Approve) are clickable and
  show a confirmation modal or toast — even if they don't persist anything

### Style minimalism
This is a PROTOTYPE — keep styling simple:
- Tailwind utility classes only, no custom CSS
- Neutral palette (slate/gray) with one accent colour
- No fancy animations, gradients, or background images
- Standard component shapes (cards, tables, forms, modals)
- Use lucide-react icons sparingly, only where they aid comprehension

### Required interactions
- Navigation: click between all views without errors
- Filtering / search: must work on at least one list view (in-memory filter)
- Form submission: shows success toast, optionally adds the new item to a list
- Role switcher: changes the dashboard and visible nav items based on selected role
- Modals: open / close cleanly, ESC to dismiss

### Mock data structure
Mock data should foreshadow the eventual database schema. Include realistic IDs
(UUIDs or short strings), timestamps, status enums, and foreign-key-style references
between objects. The project-docs skill will reuse this structure as the basis for
the data model.

---

## Step 4 — Deliver and Document

After generating the prototype:

1. **Show it inline** as an artifact (if React) — let the user click through
2. **List the views generated** — give the user a checklist of what's covered
3. **Flag any assumptions made** — call out gaps you filled with defaults
4. **Suggest next step**: the project-docs skill (Phase 2) takes this prototype +
   the original idea description and produces the formal PRD, UI/UX spec, and tech
   design spec.

---

## Workflow Position

```
[YOU ARE HERE]
─────────────
[1] prototype → [2] docs → [3] mockup (optional) → [4] task-breakdown → [5] frontend + backend
```

After generating the prototype, hand off to the user with this exact message:

> "Prototype complete with N views covering [roles]. Next step: run the
> **project-docs** skill with this prototype + your original description as input.
> It'll produce the PRD, UI/UX design spec, and tech design spec — and from those
> you can run **project-mockup-app** (validation), **task-breakdown** (planning),
> and finally **project-frontend** + **project-backend** (production code)."
