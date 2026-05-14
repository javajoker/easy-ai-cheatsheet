---
name: project-mockup-app
description: >
  Generates a quick-and-dirty demo frontend application using mock data, intended to
  validate the project docs (PRD, UI/UX spec, tech design) before any production code
  is written. Output covers ALL views and interactions from the UI/UX spec, with mock
  data structured to match the eventual database schema. Useful for stakeholder demos,
  user testing, and surfacing spec gaps before they become expensive to fix.

  USE THIS SKILL whenever the user has:
  - completed PRD + UI/UX + tech design (Phase 2 complete) and wants a runnable demo
  - asks for "a mock app", "a demo with mock data", "all-in-one demo", "MVP prototype"
  - wants to validate the docs by running through every flow before task-breakdown / production
  - says "build a frontend with mock data first" or "skip the backend for now"
  - is at Phase 3 of the project-quick-start workflow (between docs and task-breakdown)
  Trigger this skill instead of project-frontend when the user has not yet decided on
  i18n, backend wiring, or production styling — this skill produces a much faster output.
---

# Project Mockup App Generator

Step 3 of the project-quick-start workflow (optional but recommended).
**Position in workflow: AFTER project-docs, BEFORE task-breakdown.**

Builds a runnable React demo with mock data covering every view and interaction.
Used to validate the docs end-to-end before task-breakdown and production code.

This is **deliberately simple** — no fancy styling, no backend, no auth, no i18n.
Just every view + every interaction, working end-to-end with in-memory mock data.

If the mockup reveals spec gaps, **fix the docs (project-docs), not the mockup.**
The mockup is a disposable validation tool, not a code base you keep.

---

## Step 0 — Inputs

Required:
- [ ] PRD.md
- [ ] UIUX_SPEC.md
- [ ] TECH_DESIGN.md (for the mock data schema)

If the user provides only some of these, ask whether to proceed with assumed defaults
or to first run the project-docs skill.

---

## Step 1 — Project Scaffold

Use Vite + React + TypeScript:

```
mockup-app/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.js
├── index.html
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── routes.tsx
    ├── mockData/
    │   ├── users.ts
    │   ├── {entity}.ts
    │   └── index.ts
    ├── components/
    │   ├── ui/              # Button, Card, Modal, Input, Table
    │   ├── layout/          # Navbar, Sidebar, PageShell
    │   └── shared/          # AddressChip, StatusBadge, EmptyState
    ├── views/
    │   ├── public/
    │   ├── creator/
    │   ├── buyer/
    │   └── admin/
    ├── hooks/
    │   ├── useAuth.ts       # mock auth — role switcher
    │   └── useMockApi.ts    # mock API delays + responses
    └── lib/
        └── utils.ts
```

Minimum dependencies:
- `react`, `react-dom`, `react-router-dom`
- `tailwindcss`, `lucide-react`
- `clsx`, `date-fns`
- TypeScript + Vite + types

NOTHING else. No state management library — useState/useContext is enough for mocks.
No form library — controlled inputs are fine. No API client — mockApi hooks return
promises with setTimeout delays.

---

## Step 2 — Mock Data Generation

Mock data MUST follow the database schema from TECH_DESIGN.md. Each entity gets its
own file. Every record has all fields from the schema with realistic values.

### Quality bar for mock data
- At least 20 records per primary entity (Users, Items, Orders) so list views feel real
- Realistic IDs (UUIDs or short slugs) — never "id-1", "id-2"
- Realistic names, descriptions — domain-appropriate, not generic
- Varied statuses across records (some pending, some approved, some rejected)
- Timestamps spanning the last 90 days
- Foreign keys correctly cross-referenced (an order references a real user_id and product_id)
- Multilingual sample data if i18n is in scope (mix of English and Chinese names)

### Helper functions
```ts
// mockData/index.ts
export const findById = <T extends { id: string }>(arr: T[], id: string) =>
  arr.find(x => x.id === id);
export const filterBy = <T>(arr: T[], pred: (x: T) => boolean) => arr.filter(pred);
export const paginate = <T>(arr: T[], page: number, limit: number) =>
  arr.slice((page - 1) * limit, page * limit);
```

---

## Step 3 — Mock API Layer

Wrap mock data in promise-based functions that simulate API calls. These functions
mirror the API spec from TECH_DESIGN.md so the eventual production frontend can swap
in the real backend with mechanical changes.

```ts
// hooks/useMockApi.ts
export const mockApi = {
  ipAssets: {
    list: (params) => delay(300, paginate(mockIPAssets, params.page, params.limit)),
    get: (id) => delay(200, findById(mockIPAssets, id)),
    create: (body) => delay(400, { ...body, id: uuid(), created_at: new Date() }),
    update: (id, body) => delay(300, { ...findById(...), ...body }),
    delete: (id) => delay(200, undefined),
  },
  // ... mirror every endpoint from TECH_DESIGN
};

const delay = <T>(ms: number, value: T): Promise<T> =>
  new Promise(r => setTimeout(() => r(value), ms));
```

EVERY endpoint from TECH_DESIGN.md must have a corresponding mockApi function.

---

## Step 4 — Auth Mock + Role Switcher

Auth in the mockup is just a role switcher. No real login. A persistent UI element
(top-right, "Demo Controls") lets the user switch between:
- Logged out (public views only)
- {Role 1} (e.g. Creator)
- {Role 2} (e.g. Buyer)
- Admin

```tsx
// hooks/useAuth.ts
export const useAuth = () => {
  const [user, setUser] = useLocalStorage('mock-user', null);
  const switchRole = (role: string) => setUser(mockUsers.find(u => u.roles.includes(role)));
  return { user, switchRole, signOut: () => setUser(null) };
};
```

Protected routes redirect to "Sign In" page; "Sign In" has buttons for each role
("Sign in as Creator", "Sign in as Buyer", "Sign in as Admin") — no email/password form.

---

## Step 5 — View Coverage

Generate EVERY view listed in UIUX_SPEC section 3 + section 4 (missing views).

For each view:
- Match the layout described in UIUX_SPEC
- Implement empty / loading / error states from UIUX_SPEC
- Wire up actions to call mockApi functions
- Show a toast on action success
- Use components from the shared component library

### View completeness checklist
- [ ] Every public view (landing, browse, item detail, verify, sign in/up)
- [ ] Every authenticated view per role
- [ ] Every admin view (dashboard, moderation, users, disputes)
- [ ] Every form (create, edit, settings) with all fields from PRD
- [ ] Every list with sort, filter, pagination working in-memory
- [ ] Every detail view showing every relevant field
- [ ] Empty states on every list view
- [ ] 404 page for unknown routes

Do not skip views to save time. The user explicitly chose this skill to demo
end-to-end coverage.

---

## Step 6 — Styling Constraints

This is a **mockup** — keep styling minimal:
- Tailwind utility classes only — no custom CSS
- Neutral palette (slate / zinc / gray) with one accent colour (blue or violet)
- Standard component shapes — no custom illustrations
- No animations beyond `transition-colors` on buttons
- No background images, gradients (except subtle borders), or branding work

The goal: prove the workflow, not impress visually.

---

## Step 7 — Deliver

Create the project as a tar archive in `/mnt/user-data/outputs/`:

```bash
cd /home/claude
tar -czf mockup-app.tar.gz mockup-app/
cp mockup-app.tar.gz /mnt/user-data/outputs/
```

Include a README.md inside the project with:
- How to run: `pnpm install && pnpm dev`
- Demo controls: how to switch roles
- Coverage summary: N views, N entities, N mock records
- What's missing vs production: no backend, no real auth, no i18n
- **Next step recommendation**:
  - If gaps found: fix the docs via `project-docs`, then re-run mockup
  - If ready to proceed: run `task-breakdown` next, then `project-frontend` + `project-backend`

Use `present_files` to deliver the tar.

---

## Workflow Position

```
prototype → docs → [YOU ARE HERE] → task-breakdown → frontend (production)
                                                   → backend (production)
                   project-mockup-app
```

Final summary message:
> "Mockup app generated. N views, N entities, N mock records.
> Open the tar, run `pnpm install && pnpm dev`, click through every flow.
>
> If you find spec gaps, update the docs (project-docs) and re-run this mockup.
>
> When the docs feel complete, run **task-breakdown** to generate the AI-executable
> task plan. The production-frontend and production-backend skills will then consume
> both the docs AND the task plan to align code organisation with the task breakdown."
