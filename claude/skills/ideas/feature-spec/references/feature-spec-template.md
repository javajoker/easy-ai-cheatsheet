# Feature spec template

Drop this template into `docs/features/FEATURE_<slug>.md` and fill every
section. Sections marked **(required)** must be non-empty before the
spec status can flip from `draft` to `approved`.

```markdown
---
feature: <one-line title>
slug: <kebab-case-slug>
status: draft  # draft | approved | in-progress | shipped
owners:
  - <name or handle>
created: YYYY-MM-DD
target_date: YYYY-MM-DD  # optional
related_prs: []  # filled as work lands
spec_version: 1
---

# Feature — <one-line title>

## 1. Why (required)

One paragraph. What user problem this solves, what changes for the user,
why now. Cite the PRD persona or knowledge-base entity this serves where
relevant.

## 2. Out of scope (required)

Bulleted list of what this feature deliberately does *not* include.
Often longer than the goals section. Naming non-goals up front prevents
scope creep mid-implementation.

- <non-goal 1, with one line of context>
- <non-goal 2>
- …

## 3. Load-bearing terms (required)

Run `cognitive-alignment` and capture the terms here. Each term:
definition + (optional) link to its knowledge-base entity.

| Term | Definition | Entity |
|---|---|---|
| <term> | <one-line definition> | `docs/knowledge-base/entities/<file>.md` (or `–`) |

## 4. User-facing change (required if the feature has a UI)

Walk through the flow. Screens affected. Copy changes. Error states.
Keep this written prose + bullets — full mocks belong in design tools,
not here.

- **Entry point:** <where the user starts>
- **Steps:** <happy-path walkthrough>
- **Edge cases:** <what happens when X fails, Y is empty, Z is denied>
- **Empty / loading / error states:** <copy + behaviour>

## 5. API contract delta (required if the feature touches an API)

For each new or changed endpoint:

### `<METHOD> /<path>` — <one-line summary>

- **Status:** new | changed | removed
- **Breaking?** yes / no — and if yes, the sunset plan.
- **Auth:** <required role / scope>
- **Request:**
  ```json
  { ... }
  ```
- **Response (200):**
  ```json
  { ... }
  ```
- **Error responses:** 400 (validation), 401, 403, 404, 409, 500 — list
  the ones actually returned and the body shape.
- **Idempotency:** <yes/no, key strategy if yes>
- **Rate limit:** <if different from project default>

If multiple endpoints, repeat the block. Drop a complete OpenAPI fragment
in `docs/features/<slug>/api-delta.yaml` for anything non-trivial.

## 6. Data model delta (required if the feature touches the DB)

- **New tables:** name + purpose + columns + indexes.
- **Changed tables:** column adds (with default + nullable), column
  renames (with the migration strategy), column drops (with the
  deprecation window).
- **Migration preview:** drop a SQL or Prisma diff in
  `docs/features/<slug>/schema-delta.sql` (or `.prisma`).
- **Backfill plan:** for each non-null column added to a non-empty
  table, name the default value and the backfill strategy.

## 7. Background work delta (required if the feature touches jobs)

- **New jobs:** name + trigger + payload + retry policy + DLQ.
- **New cron entries:** name + schedule + idempotency.
- **Queue topic changes:** name + producer/consumer impact.

## 8. Verification plan (required)

### Automated

| Behaviour | Test level | Where it lives |
|---|---|---|
| <behaviour 1> | unit / integration / E2E | `<test-file-path>` (new or existing) |

### Manual

| Check | Who | When |
|---|---|---|
| <visual smoke / third-party handshake> | <role> | <pre-deploy / post-deploy> |

### Observability

- **New metrics:** name + type (counter / histogram / gauge) + label set.
- **New log lines:** event name + severity + sample structure.
- **New alerts:** name + condition + severity + runbook link (often a
  TODO at spec time, owned by `devops-engineer`).

## 9. Rollout plan (required)

- **Feature flag?** yes/no. If yes: flag name, owner, default value,
  segment plan, sunset date.
- **Deployment strategy:** straight ship / canary / dark launch /
  blue-green.
- **Rollback path:** explicit steps. If data changes are involved, name
  the down-migration or restore procedure.
- **Communication:** internal (Slack/email), external (changelog / API
  consumer notice).

## 10. Risks + open questions (required)

- **Risks:** what could break, with the code path or contract cited.
- **Open questions:** what isn't decided yet, with an owner and a
  resolution date. Open questions are allowed; un-owned open questions
  are not.

## 11. Related artifacts

- PRD section: `docs/PRD.md#<anchor>` (or `–` if not in PRD yet)
- Tech design section: `docs/TECH_DESIGN.md#<anchor>` (or `–`)
- Knowledge base entity: `docs/knowledge-base/entities/<file>.md` (or
  `–`)
- Predecessor / supersedes: `docs/features/FEATURE_<slug>.md` (or `–`)
- Linked PRs: filled as implementation lands.
```

## Filling discipline

- Each `(required)` section must be non-empty.
- Sections that genuinely don't apply (e.g. no UI change for a
  backend-only feature) can be marked `N/A — <reason>`. Empty is not
  acceptable.
- `status: approved` requires `requirement-audit` PASS on this spec.
- After shipping, leave the spec in `status: shipped` as the historical
  record — do not delete.

## Companion files (optional, per-feature subfolder)

When the delta is substantial:

```
docs/features/
├── FEATURE_<slug>.md
└── <slug>/
    ├── api-delta.yaml       # OpenAPI fragment
    ├── schema-delta.sql     # or .prisma
    └── ui-delta.md          # if UI surface is large
```
