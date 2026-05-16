# HOWTO Examples — instruction → agent → skill → reference, end to end

Two worked examples showing how the four-layer framework runs in
practice. Both use a fictional project — **`acme-shop`**, an e-
commerce app with a React frontend, a Go backend, and the usual
operational stack — to make the chain concrete.

- [Example 1 — Generating project skills + instructions from an existing project](#example-1--generating-project-skills--instructions-from-an-existing-project)
- [Example 2 — Adding a new feature end-to-end, including docs, FE, BE, tooling, tests](#example-2--adding-a-new-feature-end-to-end)

If you just want the mechanics, see [HOWTO.md](HOWTO.md). If you want
the scenario index, see [SCENARIOS.md](SCENARIOS.md). This file is
the *worked tour* — the same chains, with real prompts and real
intermediate artifacts.

---

## Example 1 — Generating project skills + instructions from an existing project

**Goal.** Take an existing repository — frontend, backend, docs,
tooling, the lot — and produce the framework artifacts that let
future Claude Code sessions start fully oriented:

1. `INSTRUCTIONS/projects/acme-shop/` — portable project context +
   repository structure.
2. `docs/knowledge-base/` — conceptual map of the project's entities
   and relationships.
3. `skills/projects/acme-shop/` — a project-specific skill capturing
   the internal API surface and conventions (if the project warrants
   one).

**Agents involved.** None directly — this is a skill-level chain
that produces the inputs an agent later needs. (Scenario A in
SCENARIOS.md is the playbook version.)

**Skills involved.** `project-onboarding` → `create-project-instruction`
→ `project-knowledge-base` → (optional) hand-authored
`skills/projects/<slug>/`.

### Step 1 — Open Claude Code in the repo and onboard

```
You: Onboard this project.
```

[`project-onboarding`](skills/ideas/project-onboarding/SKILL.md)
fires. Its procedure:

1. **Read the repo** — top-level layout, `package.json` / `go.mod` /
   `pyproject.toml`, README, CI configs, lint configs, test
   configurations, any existing `docs/`. Reads, does not edit.
2. **Identify the stack** — frontend framework, backend framework,
   database, queue, deploy target, observability stack.
3. **Identify the conventions** — naming, folder layout, branch
   strategy, commit-message style, lint rules.
4. **Ask 3–7 targeted questions** for things it cannot infer — e.g.
   *"I see Stripe in the deps but no use of it; is it staging-only or
   actively integrated?"*; *"The lint config allows `any` in TS but
   the codebase doesn't use it — preferred or just historical?"*

For `acme-shop`, the onboarding skill might surface:

```
Inferred (with confidence):
  - Stack: React 18 + Vite + TypeScript (frontend),
           Go 1.22 + Gin + GORM + Postgres (backend),
           Redis (cache + asynq job queue)
  - Test commands:
      FE: pnpm test       (vitest)
      BE: make test       (go test ./... with -race)
  - Lint: pnpm lint (FE: eslint+prettier),
          make lint (BE: golangci-lint)
  - Build: pnpm build, make build
  - Deploy: GitHub Actions → AWS ECS (terraform-managed)
  - Observability: OpenTelemetry → Datadog

Uncertain (need confirmation):
  1. What's the canonical local-dev workflow? docker-compose detected
     but README doesn't mention it.
  2. Are these naming patterns intentional?
     - FE components: PascalCase folders + lowercase entry files
     - BE packages: snake_case folders, camelCase types
  3. Is there a release calendar I should record?
```

You confirm or correct. The skill then **delegates to
[`create-project-instruction`](skills/ideas/create-project-instruction/SKILL.md)**
(Mode A — existing codebase) which writes:

- `INSTRUCTIONS/projects/acme-shop/project-context.md`
- `INSTRUCTIONS/projects/acme-shop/repository-structure.md`

These files become part of the **instruction layer** — they load
automatically next time anyone opens Claude Code in this repo.

A baseline of memory entries also lands at this point: project name,
stack, primary owners, languages, lint/test/build commands.

### Step 2 — Build the conceptual knowledge base

```
You: Build a knowledge base for this project.
```

[`project-knowledge-base`](skills/ideas/project-knowledge-base/SKILL.md)
fires. It reads the codebase and produces a navigable
`docs/knowledge-base/` tree:

```
docs/knowledge-base/
├── INDEX.md
├── entities/
│   ├── product.md
│   ├── order.md
│   ├── cart.md
│   ├── checkout.md
│   ├── customer.md
│   ├── discount.md
│   └── webhook.md
├── relations.md
├── terminology.md
└── decisions/         # captured architectural decisions found in code/docs
    ├── 0001-postgres-not-mysql.md
    └── 0002-asynq-not-rabbitmq.md
```

Each `entities/<name>.md` is a one-page conceptual entity: definition,
fields, key flows, related entities, key code files. This is the
**reference layer** for project-specific knowledge — agents and
skills link into it later.

### Step 3 — Decide whether the project needs a project-specific skill

The framework keeps the portable skill catalog clean. A project-
specific skill (`skills/projects/<slug>/`) is justified when:

| Criterion | acme-shop check |
|---|---|
| Substantial internal API surface (several packages) | ✅ `pkg/cart`, `pkg/checkout`, `pkg/inventory`, `pkg/webhooks` — reused across services. |
| Conventions deviate enough from defaults that generic dev skills produce wrong output | ✅ The project uses a custom `errx.Wrap` instead of `fmt.Errorf` — a generic Go style check would flag false positives. |
| Operational quirks worth a runbook | ⚠ Some (custom Stripe webhook signature verification) — but small enough to live in a runbook page, not a whole skill. |

Two of three: create one. The skill would be `skills/projects/acme-shop/`
with conventions like:

```
skills/projects/acme-shop/
├── SKILL.md                    # English wrapper — discoverable
└── references/
    ├── error-handling.md       # errx conventions
    ├── service-layout.md       # pkg/<domain> structure
    ├── webhook-verification.md # Stripe / shipping-provider signatures
    └── i18n.md                 # en + zh-TW locale layout
```

Per [`skills/projects/README.md`](skills/projects/README.md),
the SKILL.md is English (so description-matching works in mixed-
language environments) and the references can be in the project's
primary language.

This step is typically *hand-authored* by the onboarding session
based on what the codebase taught Claude — the skill is small and
context-specific enough that auto-generation tends to produce
generic output. The
[`skills/projects/stardust-rtl/`](skills/projects/stardust-rtl/)
directory is a shipped example of what one looks like.

### Step 4 — Register the project + verify

Once the artifacts are in place:

1. Add `acme-shop` to the table in
   [`INSTRUCTIONS/projects/README.md`](INSTRUCTIONS/projects/README.md)
   "Existing instances" so other agents discover it.
2. Run [`requirement-audit`](skills/share/requirement-audit/SKILL.md)
   against the onboarding deliverable list:

```
You: requirement-audit the onboarding.
```

The audit returns a PASS/PARTIAL/FAIL table. For `acme-shop`:

| # | Requirement | Status | Evidence |
|---|---|---|---|
| 1 | INSTRUCTIONS/projects/acme-shop/project-context.md exists with stack + commands | ✅ PASS | File present, all required sections filled |
| 2 | INSTRUCTIONS/projects/acme-shop/repository-structure.md exists | ✅ PASS | File present, FE + BE + ops folders mapped |
| 3 | docs/knowledge-base/ exists with entities, relations, terminology | ✅ PASS | 7 entities, 1 relations file, 1 terminology file |
| 4 | Baseline memory entries seeded | ✅ PASS | Stack, commands, lint config recorded |
| 5 | Project registered in INSTRUCTIONS/projects/README.md | ✅ PASS | Added to "Existing instances" |
| 6 | Project-specific skill created if warranted | ✅ PASS | skills/projects/acme-shop/ shipped |

### What you produced

After Example 1, the project has:

- **Instruction layer:** `INSTRUCTIONS/projects/acme-shop/` (loads on
  every future session).
- **Skill layer (project-specific):** `skills/projects/acme-shop/`
  (triggers when working in this project).
- **Reference layer (within both):** docs the agents and skills load
  on demand.
- **Knowledge graph:** `docs/knowledge-base/` — the conceptual map.
- **Memory:** baseline entries (stack, commands, owners).

The project is now ready for any agent to engage. Example 2 picks up
from here.

### Cross-references

| What | Where |
|---|---|
| Scenario playbook | [SCENARIOS.md Scenario A](SCENARIOS.md#scenario-a--onboarding-an-existing-project) |
| Per-project skill convention | [skills/projects/README.md](skills/projects/README.md) |
| Onboarding skill | [skills/ideas/project-onboarding/](skills/ideas/project-onboarding/SKILL.md) |
| Instructions templates | [INSTRUCTIONS/templates/](INSTRUCTIONS/templates/) |

---

## Example 2 — Adding a new feature end-to-end

**Goal.** Add a working **discount-code** feature to `acme-shop`:
spec it, build the API, update the database, update the frontend,
wire metrics + alerts, ship behind a feature flag, verify, hand off
clean.

**Agent involved.**
[`feature-development`](agents/feature-development/AGENT.md) —
owns the five-phase arc.

**Skills involved.**
[`feature-spec`](skills/ideas/feature-spec/SKILL.md) (the
single-feature delta spec) + language dev/testing/lint/review skills
(`go-*` for backend, `node-*` for frontend) +
[`requirement-audit`](skills/share/requirement-audit/SKILL.md)
+ [`cognitive-alignment`](skills/share/cognitive-alignment/SKILL.md)
+ [`memory-ontology`](skills/share/memory-ontology/SKILL.md).
Optionally hands off slices to
[`devops-engineer`](agents/devops-engineer/AGENT.md) for
metrics + alerts, and
[`knowledge-curator`](agents/knowledge-curator/AGENT.md) if a
published KB entity changes.

### Phase 1 — Anchor + align

```
You: Add discount codes to acme-shop. Single-use codes, percentage or
fixed amount, optional minimum cart subtotal, optional product
restriction.
```

`feature-development` fires (matched `fires_on: "Add <feature> to
this project"`). It runs Phase 1:

1. Loads `INSTRUCTIONS/projects/acme-shop/project-context.md`
   (produced by Example 1). Stack, conventions, commands all in
   scope.
2. Loads `INSTRUCTIONS/projects/acme-shop/repository-structure.md` —
   knows where new code goes.
3. Reads the KB (`docs/knowledge-base/entities/`) for related
   entities — finds `cart.md`, `checkout.md`, `order.md`. Notes that
   no `discount.md` exists yet (will be created).
4. Loads `skills/projects/acme-shop/references/error-handling.md` —
   knows to use `errx.Wrap`, not `fmt.Errorf`.
5. Runs `cognitive-alignment` to lock the load-bearing terms:

   | Term | Definition |
   |---|---|
   | **Discount code** | Per-order, single-use, applies at cart-subtotal time. |
   | **Single-use** | First successful checkout consumes it; subsequent attempts return 409. |
   | **Percentage discount** | Applies to the cart subtotal *before* shipping + tax. |
   | **Fixed-amount discount** | Capped at the cart subtotal (never goes negative). |
   | **Eligibility** | Optional product/category whitelist; optional min subtotal. |

The agent asks three setup questions (Phase 1 cap):

```
1. Target environment for the rollout: dev → staging → prod? (default)
2. Risk posture: feature flag (default for user-visible changes) or
   straight ship? — recommend flag.
3. Single owner for spec + rollout?

You: defaults + I'll own it.
```

### Phase 2 — Spec

The agent triggers [`feature-spec`](skills/ideas/feature-spec/SKILL.md):

```
You: Spec the feature.
```

`feature-spec` reads the template at
`skills/ideas/feature-spec/references/feature-spec-template.md` and
writes `docs/features/FEATURE_discount-codes.md`. The 11 sections
get populated:

```markdown
---
feature: Discount codes at checkout
slug: discount-codes
status: draft
owners: [@you]
created: 2026-05-16
target_date: 2026-06-06
related_prs: []
spec_version: 1
---

# Feature — Discount codes at checkout

## 1. Why
Customers expect promo codes for marketing campaigns and retention
offers. Without them, the team relies on per-customer manual price
adjustments via support, which doesn't scale past a few hundred
orders per month.

## 2. Out of scope
- Multi-use / per-customer-N-uses codes (single-use only this round).
- Stackable codes (one code per order; second code returns 409).
- Auto-apply on customer return (manual entry only).
- Code generation API (codes are created in admin UI; admin UI itself
  is out of scope — codes seeded in DB for v1).

## 3. Load-bearing terms
(from cognitive-alignment, links to docs/knowledge-base/entities/...)

## 4. User-facing change
On the checkout page, a new "Apply discount code" field appears
between the cart summary and the totals block. Empty state, applied
state, error states (invalid, expired, ineligible, already-used)
defined.

## 5. API contract delta
### POST /api/cart/{cartId}/apply-discount   (new)
- Auth: customer session
- Request: { "code": "SUMMER25" }
- Response 200: { cart with .discount populated, recomputed totals }
- Errors: 400 (empty/malformed), 404 (no such code), 409 (already
  used), 422 (ineligible — min subtotal not met, product restriction
  violated), 410 (expired)
- Breaking? no (new endpoint).

### DELETE /api/cart/{cartId}/discount  (new)
- Removes applied code; recomputes totals.
- Breaking? no.

### POST /api/checkout   (changed — additive)
- Existing request body unchanged.
- Response 200 envelope gains optional .appliedDiscount field.
- Breaking? no (additive, omitempty).

(Full OpenAPI fragment in docs/features/discount-codes/api-delta.yaml)

## 6. Data model delta
New table `discount_codes`:
  id uuid PK
  code text UNIQUE NOT NULL
  kind text NOT NULL CHECK (kind in ('percent', 'fixed'))
  value numeric(10,2) NOT NULL
  min_subtotal numeric(10,2)
  product_restriction jsonb
  expires_at timestamptz
  used_at timestamptz
  used_on_order_id uuid REFERENCES orders(id)
  created_at timestamptz DEFAULT now()

Index: UNIQUE(code) WHERE used_at IS NULL — enforces single-use at
the constraint layer.

Migration: docs/features/discount-codes/schema-delta.sql.
Backfill: not required (new table).

## 7. Background work delta
None for v1. (v2 may add expiry-sweep cron.)

## 8. Verification plan
### Automated
- A1: integration test `pkg/cart/discount_test.go` covers apply +
  remove happy path + each 4xx error path.
- A2: unit test for fixed-amount cap (never goes negative).
- A2: unit test for percentage applied to subtotal (not subtotal+
  shipping).
- A3: E2E test `apps/web/e2e/discount-codes.spec.ts` covers
  apply-on-checkout happy path.
- A4: 409 case (already-used code) covered by integration test using
  a sequential test fixture.
- A5: N/A — no background jobs.

### Manual
- M1: visual smoke — discount line renders correctly across
  desktop + mobile + RTL locale. Owner: @you, post-deploy.

### Observability
- O2: counter `cart.discount.applied{kind=percent|fixed,outcome=success|reject}`.
- O2: counter `cart.discount.rejected_reason{reason=expired|already_used|ineligible|invalid|empty}`.
- O1: alert on `rate(cart.discount.applied{outcome=reject}) > 0.5 *
  rate(cart.discount.applied{})` over 15m (would indicate a bad code
  campaign or a bug). Owner: devops-engineer (handed off).
- O4: log line `cart.discount.applied` at info severity with cart_id,
  code_id, kind, value, outcome fields.

## 9. Rollout plan
- Feature flag: `flag.checkout.discount_codes` (default off).
- Strategy: enable in dev → staging → 10% prod canary for 24h →
  100% prod.
- Rollback: flag flip off. No data migration to reverse (new table
  stays; rows ignored).
- Comms: internal Slack #checkout when 100% prod; no customer comms
  until first marketing campaign uses the field (marketing owns).

## 10. Risks + open questions
- Risk: race condition on UNIQUE(code) WHERE used_at IS NULL — covered
  by index, but verify under load test.
- Open: should we log the customer email or just cart_id in the
  observability lines? Owner: @you, resolve before code work.
- Open: what's the rate limit on apply-discount? Owner: @devops-engineer,
  resolve in Phase 5.

## 11. Related artifacts
- PRD section: docs/PRD.md#checkout (will add new sub-section)
- Tech design: docs/TECH_DESIGN.md#checkout-api (will add new endpoints)
- KB entity: docs/knowledge-base/entities/discount.md (will create)
- Predecessor: – (first version)
- Linked PRs: – (filled later)
```

The agent runs `requirement-audit` against the spec template's
verification rubric
(`skills/ideas/feature-spec/references/verification-rubric.md`).
Audit returns PASS. The spec status flips: `draft` → `approved`.

### Phase 3 — Contract lock + planning

Contracts are committed. The implementation task list:

```
1. DB migration + ORM model         (BE — pkg/discount/)
2. POST /apply-discount endpoint    (BE — pkg/cart/)
3. DELETE /discount endpoint        (BE — pkg/cart/)
4. Checkout response envelope       (BE — pkg/checkout/)
5. Feature flag wiring              (BE + FE — shared flag service)
6. Checkout UI field + states       (FE — apps/web/src/checkout/)
7. E2E test                         (FE — apps/web/e2e/)
8. Integration + unit tests         (BE — *_test.go)
9. Metrics + log lines              (BE — observability bundle)
10. KB entity + project-specific skill update (docs + skills/projects/acme-shop/)
```

The agent decides
`skills/projects/acme-shop/references/` needs a new
`discount-codes.md` page documenting the internal `pkg/discount` API
(the feature adds a meaningful internal surface). Queued.

`memory-ontology` records the feature decision.

### Phase 4 — Implement + verify

The agent works the task list. For each PR, the relevant dev skills
fire:

| Task | Skills used |
|---|---|
| DB migration + ORM | `go-style-core`, `go-naming`, `go-error-handling` (uses `errx.Wrap` per project conventions) |
| Endpoints | `go-functions`, `go-error-handling`, `go-testing` (integration tests) |
| Tests | `go-testing`, `go-table-driven-tests` reference |
| Flag wiring | `go-style-core` + `node-types` (FE side) |
| Checkout UI | `node-types`, `node-style-core`, `node-testing` (E2E via Playwright) |

Per the project's commands (from
`INSTRUCTIONS/projects/acme-shop/project-context.md`):

```
make test       # full BE suite, includes new pkg/cart/discount tests
make lint       # golangci-lint with the project config
pnpm test       # vitest, includes new checkout tests
pnpm test:e2e   # playwright, includes new discount-codes spec
pnpm lint
```

The agent runs each before opening the PR. Once green:

```
PR opened: feat(checkout): single-use discount codes (#412)
PR description follows agents/feature-development/references/feature-pr-template.md
Spec linked, verification rows checked, rollout plan listed.
```

The agent runs `go-code-review` against the BE diff and
`node-code-review` against the FE diff before requesting human
review. Findings (if any) are addressed; the PR description is
updated to reflect what the review caught.

The user starts the dev server, exercises the feature in the
browser (apply code → see discount → remove code → see totals
restore → try invalid code → see error state).

PR merges to main; main green.

### Phase 5 — Rollout + ship

The agent works the rollout per spec §9:

1. Flag flipped on in dev. Smoke check.
2. Flag flipped on in staging. Internal team uses it; one minor bug
   surfaces (the error toast doesn't auto-dismiss). Quick patch PR.
3. Hand-off to `devops-engineer` for the alert rule that wasn't
   wired in the feature PR — they own the project's alerting stack.
   `devops-observability` + `devops-incident-runbook` skills produce:
   - alert rule wired in the project's alerting config
   - one-paragraph runbook entry: *"discount-code reject rate >50%
     means a bad code or a bug — check `cart.discount.rejected_reason`
     to disambiguate"*.
4. Canary at 10% prod for 24h. Metrics watched:
   `cart.discount.applied`, `cart.discount.rejected_reason`. Numbers
   look normal.
5. Flag flipped to 100%.

After ship, the agent runs Phase 5 cleanup:

- **Final `requirement-audit`** against the spec — every section
  reflects shipped reality. PASS.
- **Knowledge base entity created.** `project-knowledge-base` writes
  `docs/knowledge-base/entities/discount.md` and adds the relation
  to `cart.md` + `order.md`. Index regenerated.
- **Project-specific skill updated.** A new
  `skills/projects/acme-shop/references/discount-codes.md` page
  documents the internal `pkg/discount` API and the `errx` error
  shapes for use by future feature work in this area.
- **PRD updated.** `docs/PRD.md#checkout` gets a new sub-section
  linking to the feature spec.
- **Memory entry written.** Feature identity, PR #412, metrics to
  watch (`cart.discount.*`), the flag name.
- **Spec status flipped** from `in-progress` to `shipped`.

The agent emits a one-paragraph handoff:

```
Feature shipped: discount codes (single-use, percent or fixed).
Spec: docs/features/FEATURE_discount-codes.md (shipped).
PR: #412.
Flag flipped 100% at 2026-06-04 14:22 UTC.
Metrics live: cart.discount.applied, cart.discount.rejected_reason.
Alert wired by devops-engineer (handoff #devops-413).
KB updated: entities/discount.md, cart.md relation.
Project skill updated: skills/projects/acme-shop/references/discount-codes.md.
Open follow-ups: 0.
```

### Cross-references

| What | Where |
|---|---|
| Agent | [agents/feature-development/AGENT.md](agents/feature-development/AGENT.md) |
| Skill | [skills/ideas/feature-spec/SKILL.md](skills/ideas/feature-spec/SKILL.md) |
| Execution checklist | [agents/feature-development/references/feature-development-checklist.md](agents/feature-development/references/feature-development-checklist.md) |
| Hand-off rules | [agents/feature-development/references/handoff-decision-tree.md](agents/feature-development/references/handoff-decision-tree.md) |
| PR template | [agents/feature-development/references/feature-pr-template.md](agents/feature-development/references/feature-pr-template.md) |
| Spec template | [skills/ideas/feature-spec/references/feature-spec-template.md](skills/ideas/feature-spec/references/feature-spec-template.md) |
| Verification rubric | [skills/ideas/feature-spec/references/verification-rubric.md](skills/ideas/feature-spec/references/verification-rubric.md) |
| Scenario playbook | [SCENARIOS.md Scenario T](SCENARIOS.md#scenario-t--adding-a-feature-to-an-onboarded-project-feature-development) |

---

## How the four layers showed up in each example

| Layer | Example 1 | Example 2 |
|---|---|---|
| **Instruction** | Produced new `INSTRUCTIONS/projects/acme-shop/*` | Loaded `INSTRUCTIONS/projects/acme-shop/*` to anchor the feature against the right stack and commands |
| **Agent** | None directly (skill-level chain) | `feature-development` owned the arc; engaged `devops-engineer` for alerts |
| **Skill** | `project-onboarding`, `create-project-instruction`, `project-knowledge-base`, `requirement-audit` | `feature-spec`, language dev/test/lint/review skills, `cognitive-alignment`, `memory-ontology`, `requirement-audit` |
| **Reference** | Templates under `INSTRUCTIONS/templates/`, the new `skills/projects/acme-shop/references/` | `feature-spec-template.md`, `verification-rubric.md`, `feature-development-checklist.md`, `handoff-decision-tree.md`, `feature-pr-template.md` |

The pattern: agents conduct, skills produce, instructions anchor,
references give the producers a deterministic shape.

## Common variations

| If… | Adjust |
|---|---|
| The project's primary language is non-English | Onboarding writes English INSTRUCTIONS, project-specific skill references in the project's language. Spec is in English; the user-facing copy in the spec follows project conventions. |
| The feature is whole-system architectural | Phase 1 hands off to `architecture-shepherd` before spec. |
| The feature requires no new contract | Don't engage `feature-development` — use dev-* skills directly (this is the bug-fix path, not the feature path). |
| The project hasn't been onboarded yet | Run Example 1 first; only then run Example 2. The framework refuses to spec features against an un-onboarded project for good reason — the spec would be guesses. |
| Multiple features in flight at once | Each gets its own `FEATURE_<slug>.md`; the agent runs them in parallel phases, but Phase 5 (rollout) for any one feature must serialize on the shared rollout infra (flags, canary slots). |

## See also

- [HOWTO.md](HOWTO.md) — the everyday mechanics + agents layer.
- [SCENARIOS.md](SCENARIOS.md) — situational playbooks (A–T).
- [agents/README.md](agents/README.md) — the agents layer
  rationale.
- [agents/CHECKLIST.md](agents/CHECKLIST.md) — build status
  of all agents.
- [skills/ideas/README.md](skills/ideas/README.md) — the
  project-lifecycle skill pack.
