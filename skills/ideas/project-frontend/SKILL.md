---
name: project-frontend
description: >
  Generates a production-grade frontend application from project docs (PRD + UI/UX spec
  + tech design) AND the task breakdown produced by the task-breakdown skill. Output
  includes i18n (English + Traditional Chinese by default), a folder structure aligned
  with the task-breakdown components (so each task ID maps to a real folder in code),
  every view from the UI/UX spec implemented, working API client wired to backend
  endpoints from the tech design, and a mock-fallback mode. Output is a complete
  runnable React project saved as a tar archive.

  USE THIS SKILL whenever the user has:
  - completed PRD + UI/UX + tech design AND task breakdown, and wants the real frontend
  - asks to "build the frontend", "create the production web app", "scaffold the React app"
  - wants i18n, structured codebase, real API integration, AND code organised by tasks
  - is at Phase 5 of the project-quick-start workflow (after task-breakdown)
  - says "I'm ready for the production frontend now" or "build the frontend from the
    task plan and docs"
  Trigger this skill instead of project-mockup-app when the user wants a real,
  production-quality codebase organised around the task breakdown rather than a quick demo.
---

# Project Frontend Generator

Step 5a (parallel with project-backend) of the project-quick-start workflow.
**Position: AFTER task-breakdown.**

Builds a production-grade React frontend from THREE sources of truth:
1. Project docs (PRD, UI/UX spec, tech design) — the *what*
2. Task breakdown (AGENT.md, DEPENDENCY_GRAPH.md, task files) — the *how-organised*
3. User overrides if provided — explicit decisions

The generated code's folder structure mirrors the task breakdown's frontend
components, so each task ID (e.g. `FE-003 Auth Module`) maps to a real folder
in the codebase. When you sit down to work on a single task, the matching
folder already exists.

---

## Step 0 — Inputs

Required:
- [ ] PRD.md
- [ ] UIUX_SPEC.md
- [ ] TECH_DESIGN.md (especially the API specification section)
- [ ] Task breakdown tar (or its extracted contents) — specifically:
  - [ ] `AGENT.md` (for the project's prompt templates and conventions)
  - [ ] `DEPENDENCY_GRAPH.md` (for component list and dependencies)
  - [ ] `tasks/` folder with all frontend task files
  - [ ] `CONVENTIONS.md` (for naming and style)

Optional but useful:
- [ ] UI prototype (for visual reference, not the source of truth)
- [ ] Existing mockup app (if user ran project-mockup-app first — reuse mock data)

If the user has not run task-breakdown yet, ASK FIRST whether to:
- (a) Run task-breakdown first (recommended) — produces aligned code organisation
- (b) Generate without task plan using flat default structure (faster but less organised)

Default to (a) unless the user explicitly says otherwise.

---

## Step 1 — Parse the Task Breakdown First

Before scaffolding any code, read the task breakdown:

1. **Open `DEPENDENCY_GRAPH.md`** — list every frontend-related task ID and title
2. **Open each frontend task file** in `tasks/` — extract:
   - Component / module name (the folder this becomes)
   - Listed file paths in "Expected Outputs" — these become the actual file structure
   - Dependencies between frontend tasks — these inform import boundaries
3. **Open `CONVENTIONS.md`** — apply the project's conventions to overrides
4. **Open `AGENT.md`** — read section 4 (Standard Prompt Templates) to understand
   the project's preferred frontend stack if it differs from defaults

The folder structure of the generated frontend MUST mirror the task component list.
Do not improvise organisation when the task breakdown specifies it.

---

## Step 2 — Tech Stack (defaults)

Unless the AGENT.md / tech design specified otherwise:

- **Framework**: Vite + React 18 + TypeScript strict mode
- **Routing**: react-router-dom v6
- **Server state**: TanStack Query v5
- **Client state**: Zustand
- **Forms**: react-hook-form + Zod resolver
- **Styling**: Tailwind CSS 3
- **Component primitives**: shadcn/ui (Radix-based)
- **i18n**: react-i18next + i18next-http-backend + i18next-browser-languagedetector
- **API client**: axios with interceptors
- **Date / number**: date-fns + Intl APIs
- **Icons**: lucide-react
- **Testing**: Vitest + React Testing Library + Playwright (E2E)

If AGENT.md or tech design specified different choices, follow them.

---

## Step 3 — Project Structure (aligned with task breakdown)

The structure is derived from the task breakdown's frontend task list. The general
shape:

```
{project-name}-frontend/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── tailwind.config.js
├── .env.example
├── .eslintrc.cjs
├── .prettierrc
├── README.md
├── public/
│   └── locales/
│       ├── en/
│       │   ├── common.json
│       │   └── {feature}.json    # one file per feature task
│       └── zh-TW/
│           └── ...
└── src/
    ├── main.tsx
    ├── App.tsx
    ├── i18n.ts
    ├── routes/
    ├── pages/                     # one folder per role group from UI/UX spec
    │   ├── public/
    │   ├── auth/
    │   ├── creator/
    │   ├── buyer/
    │   └── admin/
    ├── features/                  # ONE FOLDER PER FRONTEND TASK ID
    │   ├── {task-id-slug}/        # e.g. fe-003-auth/
    │   │   ├── README.md          # links back to tasks/.../FE-003-auth.md
    │   │   ├── api.ts             # endpoints owned by this task
    │   │   ├── types.ts
    │   │   ├── hooks.ts           # TanStack Query hooks
    │   │   ├── components/
    │   │   └── index.ts           # public exports
    │   └── ...
    ├── components/
    │   ├── ui/                    # shadcn primitives + custom
    │   ├── layout/
    │   ├── forms/
    │   └── shared/
    ├── lib/
    │   ├── api-client.ts
    │   ├── auth.ts
    │   ├── utils.ts
    │   └── mock-fallback.ts
    ├── stores/
    ├── hooks/
    ├── types/
    └── styles/
        └── globals.css
```

### Key alignment rule
For every frontend task in the task breakdown:
1. Create a folder in `src/features/` named `{task-id-slug}/`
2. Add a top-level `README.md` in that folder linking back to the source task file
3. Place all feature-scoped code (api, hooks, types, components) inside that folder
4. Pages that consume the feature go in `src/pages/` and import from the feature folder

This gives a 1-to-1 mapping: when an AI agent picks up `FE-003 Auth Module`, it
knows exactly where to work.

---

## Step 4 — i18n Setup

### Configuration

```ts
// src/i18n.ts
import i18n from 'i18next';
import HttpBackend from 'i18next-http-backend';
import LanguageDetector from 'i18next-browser-languagedetector';
import { initReactI18next } from 'react-i18next';

i18n
  .use(HttpBackend)
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    fallbackLng: 'en',
    supportedLngs: ['en', 'zh-TW'],
    defaultNS: 'common',
    ns: ['common', /* ...one per feature task */],
    backend: { loadPath: '/locales/{{lng}}/{{ns}}.json' },
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
    },
    interpolation: { escapeValue: false },
  });

export default i18n;
```

### Translation file conventions
- One JSON file per feature task namespace (matches `src/features/` folders)
- Keys are camelCase, organised by view → element
- ALL user-facing text uses `t('key')` — no hardcoded strings
- Date / number formatting via `Intl` localised by current language

Example: feature `fe-003-auth` gets:
- `public/locales/en/auth.json`
- `public/locales/zh-TW/auth.json`

### Language switcher
Persistent UI element in the navbar. Updates `i18n.language` and persists to
localStorage. The HTML lang attribute is updated on language change for screen reader
correctness.

---

## Step 5 — API Client Layer

### axios instance with interceptors

```ts
// src/lib/api-client.ts
import axios from 'axios';
import { useAuthStore } from '@/stores/auth';

export const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api/v1',
  timeout: 15_000,
});

apiClient.interceptors.request.use(config => {
  const token = useAuthStore.getState().accessToken;
  if (token) config.headers.Authorization = `Bearer ${token}`;
  config.headers['Accept-Language'] = i18n.language;
  return config;
});

apiClient.interceptors.response.use(
  res => res,
  async error => {
    if (error.response?.status === 401) {
      const refreshed = await refreshTokenSilently();
      if (refreshed) return apiClient.request(error.config);
      useAuthStore.getState().signOut();
    }
    return Promise.reject(error);
  }
);
```

### Per-feature API modules (in feature folders)

Every feature folder owns its own API module:

```ts
// src/features/fe-007-ip-assets/api.ts
import { apiClient } from '@/lib/api-client';

export const ipAssetsApi = {
  list: (params) => apiClient.get('/ip-assets', { params }).then(r => r.data),
  get: (id) => apiClient.get(`/ip-assets/${id}`).then(r => r.data),
  create: (body) => apiClient.post('/ip-assets', body).then(r => r.data),
  update: (id, body) => apiClient.patch(`/ip-assets/${id}`, body).then(r => r.data),
  remove: (id) => apiClient.delete(`/ip-assets/${id}`),
};
```

### Per-feature TanStack Query hooks

```ts
// src/features/fe-007-ip-assets/hooks.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ipAssetsApi } from './api';

export const useIpAssets = (params) =>
  useQuery({ queryKey: ['ip-assets', params], queryFn: () => ipAssetsApi.list(params) });

export const useCreateIpAsset = () => {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ipAssetsApi.create,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['ip-assets'] }),
  });
};
```

EVERY endpoint from TECH_DESIGN.md must have a corresponding api function and hook,
placed in the feature folder for the task that owns it.

---

## Step 6 — Mock Fallback Mode

When `VITE_USE_MOCK=true` env var is set, the api-client transparently routes calls
to in-memory mock implementations instead of the real backend.

If the user ran `project-mockup-app` first, copy the mockData and mockApi from there
directly into `src/lib/mock-fallback.ts` — no need to regenerate.

---

## Step 7 — View Implementation

Implement EVERY view from UIUX_SPEC.md section 3 + 4 (including missing views).

For each view:
1. Create file at `src/pages/{role}/{view-name}.tsx`
2. Import the relevant feature folder from `src/features/{task-id-slug}/`
3. Use components from the shared component library
4. Wire up data fetching via the feature's TanStack Query hooks
5. Implement empty / loading / error states from UIUX_SPEC
6. All text via `t('key')` — register translation keys in `public/locales/`
7. Handle responsive layout (mobile differences from UIUX_SPEC)
8. Accessibility: aria-labels, keyboard nav, focus management

### View checklist
- [ ] All public views
- [ ] All authenticated views per role
- [ ] All admin views
- [ ] All forms with react-hook-form + Zod validation
- [ ] All lists with pagination, sort, filter
- [ ] All detail views with all relevant data
- [ ] Empty states
- [ ] Loading skeletons
- [ ] Error boundaries
- [ ] 404 page

---

## Step 8 — Quality Standards

### Required
- TypeScript strict mode — zero `any`
- All forms validated client-side via Zod schemas (matching backend validation)
- All async operations show loading + error states
- All destructive actions have confirmation modals
- All forms protect against double-submit
- All routes protected by role-based ProtectedRoute wrapper
- All env vars validated at startup
- Lighthouse: Performance ≥ 85, Accessibility ≥ 90

### Required toolchain
- ESLint with TypeScript + React rules — `pnpm lint` passes
- Prettier — `pnpm format` formats consistently
- TypeScript — `pnpm typecheck` passes
- Vitest — `pnpm test` runs unit tests for hooks and utilities
- Playwright (optional but recommended) — `pnpm test:e2e` runs primary user flows

### .env.example
```
VITE_API_BASE_URL=http://localhost:3000/api/v1
VITE_USE_MOCK=false
VITE_SENTRY_DSN=
VITE_DEFAULT_LOCALE=en
```

---

## Step 9 — Cross-reference task files

For every feature folder created, the README.md inside it MUST link back to the
source task file:

```markdown
# Feature: Auth (FE-003)

This feature implements the authentication module described in:
**[../../tasks/02-frontend/FE-003-auth.md](../../tasks/02-frontend/FE-003-auth.md)**

## Status
- [x] Group 01 — Scaffold
- [x] Group 02 — Sign-in flow
- [ ] Group 03 — Password reset
- [ ] Group 04 — Tests

When working on this feature, update both this README and the task file.
```

This makes the round-trip between task plan and code mechanical.

---

## Step 10 — Deliver

```bash
cd /home/claude
tar -czf {project-name}-frontend.tar.gz {project-name}-frontend/
cp {project-name}-frontend.tar.gz /mnt/user-data/outputs/
```

Include README.md in the project root with:
- Setup: `pnpm install && pnpm dev`
- Env vars to configure
- Project structure overview — call out the `src/features/` ↔ task-breakdown alignment
- How i18n works + how to add a new language
- How mock fallback works
- Link to the task breakdown tar — this is the source of truth for organisation
- Link to backend repo (if generated separately)

Use `present_files` to deliver.

---

## Workflow Position

```
prototype → docs → mockup → task-breakdown → [YOU ARE HERE]  +  project-backend-{node|go|python}
                                              project-frontend
```

Final summary:
> "Production frontend generated. N feature modules aligned with N frontend task IDs.
> N translation keys.
> Run `pnpm install && pnpm dev`. Toggle `VITE_USE_MOCK=true` for offline mode.
> Each `src/features/{task-id-slug}/` folder links back to its source task file —
> when you work on a task, the corresponding code folder is already in place.
> Pair with the **project-backend-node**, **project-backend-go**, or
> **project-backend-python** skill running in parallel — pick the one matching
> the language chosen in TECH_DESIGN.md."
