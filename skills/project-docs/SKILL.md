---
name: project-docs
description: >
  Generates a complete set of project specification documents — PRD (Product Requirements
  Document), UI/UX Design Spec, and Tech Design Spec including backend API contracts and
  database schema — from a project idea + UI prototype. Output is three structured
  markdown files saved to /mnt/user-data/outputs/, ready to feed into the task-breakdown,
  project-mockup-app, project-frontend, and project-backend skills.

  USE THIS SKILL whenever the user has:
  - just generated a prototype (via project-prototype skill) and wants formal docs
  - has a working prototype/mockup and needs PRD, design spec, or tech spec
  - asks to "create a PRD", "write a design doc", "draft a tech spec", "document the project"
  - says "now formalise this into specs" or "I need real docs before we code"
  - is moving from Phase 1 (prototype) to Phase 2 (specs) of the project-quick-start workflow
  - uploads a UI prototype and asks what to do next
  Trigger this skill even if only one of the three docs is requested — generating all
  three together produces consistent, mutually-referenced documentation.
---

# Project Docs Generator

Step 2 of the project-quick-start workflow. Converts a prototype + idea description
into the three foundational documents needed before any code is written.

---

## What Gets Generated

Three markdown files, all saved to `/mnt/user-data/outputs/`:

1. **PRD.md** — Product Requirements Document (the "what and why")
2. **UIUX_SPEC.md** — UI/UX Design Specification (the "how it looks")
3. **TECH_DESIGN.md** — Technical Design Document (the "how it's built")

These three documents are tightly linked — each references the others. Generate them
together, never separately, to keep them consistent.

---

## Step 0 — Gather Inputs

Required:
- [ ] Original project idea description (concept, goals, constraints)
- [ ] UI prototype (HTML/React file, screenshots, or detailed description)

Optional but very helpful:
- [ ] Tech stack preference (if user has one)
- [ ] Target users/scale (10 users vs 1M users changes a lot)
- [ ] Integration requirements (specific APIs, blockchains, payment processors)
- [ ] Compliance constraints (GDPR, HIPAA, financial regs)

If the prototype is a React artifact from a previous turn, parse it directly — extract
view names, mock data structures, and visible flows. Do not re-ask the user for things
already in the prototype.

---

## Step 1 — Document Generation Order

Generate in this exact order. Each document builds on the last.

### 1a. PRD.md — Product Requirements Document

Read `references/prd-template.md` for the full template.

Required sections:
1. **Executive Summary** — 1 paragraph: what, who, why
2. **Goals and Non-Goals** — explicit scope boundaries
3. **User Personas** — one section per role from the prototype
4. **User Stories / Use Cases** — grouped by persona, format: "As X, I want Y, so that Z"
5. **Feature List** — every feature visible in the prototype, plus inferred features
   (auth, search, notifications, settings) — each with priority (P0/P1/P2)
6. **Business Rules** — pricing, fee structures, permission rules, share ratios,
   validation rules, eligibility criteria
7. **Success Metrics** — how to measure if this is working
8. **Risks and Open Questions** — known unknowns the team must resolve

### 1b. UIUX_SPEC.md — UI/UX Design Specification

Read `references/uiux-template.md` for the full template.

Required sections:
1. **Design Principles** — 3–5 guiding principles (e.g. "Mobile-first", "Trust through
   transparency")
2. **Information Architecture** — sitemap of all views, hierarchical
3. **View Specifications** — ONE SECTION PER VIEW from the prototype:
   - Purpose, primary actions
   - Layout description (header, body, sidebar, footer)
   - Components used (forms, lists, cards, modals)
   - Empty / loading / error states
   - Mobile vs desktop differences
4. **Component Library** — shared components: Button, Card, Modal, Form, Table,
   Notification, Badge — with props and variants
5. **User Flows** — step-by-step for each primary flow, including alternate paths
6. **Missing Views to Add** — views the prototype didn't include but the PRD
   requires (item detail views, error pages, empty states)
7. **Accessibility Requirements** — WCAG 2.1 AA target, keyboard nav, contrast

CRITICAL: include a sub-section for each view in the prototype, plus identify any
missing views that the PRD requires but the prototype skipped (e.g. forgot password,
order detail, dispute submission).

### 1c. TECH_DESIGN.md — Technical Design Document

Read `references/tech-design-template.md` for the full template.

Required sections:
1. **Architecture Overview** — system diagram (text or Mermaid), tech stack rationale
2. **Tech Stack** — explicit choices for frontend, backend, DB, cache, queue, deploy
3. **Database Schema** — every table with columns, types, indexes, foreign keys —
   derived from the prototype's mock data structure
4. **API Specification** — every REST endpoint:
   - Method + path
   - Request body schema
   - Response schema
   - Auth requirements
   - Validation rules
   Group by resource (e.g. "/api/users/...", "/api/products/...").
5. **Auth and Authorisation** — JWT/sessions/OAuth, role mapping, protected resources
6. **External Integrations** — third-party APIs, webhooks, SDKs
7. **Background Jobs / Workers** — async tasks, queues, schedulers
8. **Security Considerations** — encryption, input validation, rate limiting, CSRF, XSS
9. **Deployment Architecture** — containers, orchestration, environments
10. **Performance Targets** — p95 latency, uptime SLA, throughput
11. **i18n Strategy** — supported locales, default, message file format

CRITICAL: the API spec must cover EVERY action visible in the prototype. If the
prototype has a "Submit Bid" button, there must be a `POST /api/bids` endpoint
documented. The downstream project-frontend and project-backend skills depend on
this completeness.

---

## Step 2 — Cross-Document Consistency Check

Before delivering, verify:

- [ ] Every persona in PRD has matching views in UIUX_SPEC
- [ ] Every feature in PRD has corresponding API endpoints in TECH_DESIGN
- [ ] Every entity in TECH_DESIGN database schema appears in UIUX_SPEC views
- [ ] Mock data structures from the prototype are reflected in the DB schema
- [ ] User flows in UIUX_SPEC reference real endpoints from TECH_DESIGN
- [ ] Business rules in PRD are enforced in TECH_DESIGN validation rules

If any inconsistency exists, fix it BEFORE delivering. The downstream code-generation
skills will faithfully implement what's in these docs — bugs here propagate everywhere.

---

## Step 3 — i18n Defaults

Unless the user says otherwise, all three docs assume:
- **Default locale**: English (`en`)
- **Additional locale**: Traditional Chinese (`zh-TW`)
- **Storage format**: i18n JSON files (one per locale, namespaced by feature)
- **Library**: react-i18next on frontend, i18next-fs-backend on backend
- **Fallback chain**: `zh-TW` → `en` → key

Document this in TECH_DESIGN under "i18n Strategy". The project-frontend and
project-backend skills will both implement this exactly.

---

## Step 4 — Deliver

Save the three files:
```bash
/mnt/user-data/outputs/PRD.md
/mnt/user-data/outputs/UIUX_SPEC.md
/mnt/user-data/outputs/TECH_DESIGN.md
```

Use `present_files` to deliver all three at once.

Final summary message to user:
> "Three documents generated:
> - PRD.md — N personas, N user stories, N features (P0: x, P1: y, P2: z)
> - UIUX_SPEC.md — N views including N new ones not in the original prototype
> - TECH_DESIGN.md — N database tables, N API endpoints
>
> **Recommended next step**: run **project-mockup-app** for a quick runnable demo
> with mock data. Validate the docs end-to-end by clicking through every flow.
> If you find spec gaps, come back here and update the docs.
>
> When the docs are validated, run **task-breakdown** to generate the AI-executable
> task plan. Then run **project-frontend** + **project-backend** in parallel — both
> consume the docs AND the task plan, producing code organised around task IDs."

---

## Reference Files

| File | When to read |
|------|--------------|
| `references/prd-template.md` | Generating PRD.md |
| `references/uiux-template.md` | Generating UIUX_SPEC.md |
| `references/tech-design-template.md` | Generating TECH_DESIGN.md |
