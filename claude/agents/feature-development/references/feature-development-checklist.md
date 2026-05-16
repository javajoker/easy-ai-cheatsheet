# Feature-development execution checklist

The five-phase arc, with the boxes to tick per phase. The agent runs
this checklist live during the work — the user sees a copy with
checkmarks as items land.

## Phase 1 — Anchor + align

- [ ] `INSTRUCTIONS/projects/<slug>/project-context.md` loaded; stack
  + test/lint/build commands confirmed.
- [ ] `INSTRUCTIONS/projects/<slug>/repository-structure.md` loaded;
  feature's target folders identified.
- [ ] `cognitive-alignment` ran; load-bearing terms recorded.
- [ ] Knowledge base checked for related entities; links collected.
- [ ] Stack-mismatch check: feature shape is compatible with the
  project's platform (e.g. no GraphQL on REST-only without surfacing).
- [ ] Owner named (single person/role accountable for the feature).

**Gate to Phase 2:** all six rows checked.

## Phase 2 — Spec

- [ ] `docs/features/FEATURE_<slug>.md` created from
  `skills/ideas/feature-spec/references/feature-spec-template.md`.
- [ ] Section 1 (Why) written — one paragraph, user-problem framing.
- [ ] Section 2 (Out of scope) written — non-empty, real non-goals.
- [ ] Section 3 (Load-bearing terms) populated from Phase 1.
- [ ] Section 4 (User-facing change) written if the feature has a UI.
- [ ] Section 5 (API contract delta) written if the feature touches an
  API; OpenAPI fragment dropped to `docs/features/<slug>/api-delta.yaml`
  if non-trivial.
- [ ] Section 6 (Data model delta) written if the feature touches the DB;
  migration preview dropped to `docs/features/<slug>/schema-delta.sql`
  or `.prisma`.
- [ ] Section 7 (Background work delta) written if the feature adds jobs.
- [ ] Section 8 (Verification plan) written — every behaviour has a
  test row or an explicit manual check; observability covers silent
  failure modes.
- [ ] Section 9 (Rollout plan) written — flag? canary? rollback path
  named.
- [ ] Section 10 (Risks + open questions) written — open questions
  have owners + dates.
- [ ] `requirement-audit` ran against the spec — PASS.
- [ ] Spec status flipped from `draft` to `approved`.

**Gate to Phase 3:** all rows checked + audit PASS.

## Phase 3 — Contract lock + planning

- [ ] API contract committed to the spec; the same shape will land in
  the implementation.
- [ ] Data model contract committed to the spec; migration sketched.
- [ ] Implementation task list produced (informal — not full
  `task-breakdown`; a few bullets or a sub-checklist is enough).
- [ ] Decision made on whether `skills/projects/<slug>/` needs an
  update; if yes, queued as a deliverable.
- [ ] `memory-ontology` records the feature decision + locked contract.

**Gate to Phase 4:** contract recorded; task list exists.

## Phase 4 — Implement + verify

For each PR in the implementation:

- [ ] Code follows the project's conventions (per `INSTRUCTIONS/projects/<slug>/`).
- [ ] Tests added per the spec's verification plan (unit + integration
  + E2E as called for).
- [ ] Language-specific code-review skill (e.g. `go-code-review`,
  `node-code-review`) ran against the diff.
- [ ] Lint passes locally with the project's lint command.
- [ ] Full project test suite passes locally.
- [ ] Build passes locally.
- [ ] For UI: dev server started, feature exercised in browser,
  edge cases manually checked.
- [ ] For backend: API exercised with curl / Postman / Bruno against
  local server.
- [ ] PR description follows `references/feature-pr-template.md`.
- [ ] Linked back to the spec in the PR description.

**Gate to Phase 5:** PR(s) merged + main green.

## Phase 5 — Rollout + ship

- [ ] Rollout plan executed per the spec (flag flip / canary stage /
  straight ship).
- [ ] Metrics + alerts verified firing as expected (or deferred to
  `devops-engineer` with owner + date).
- [ ] Rollback path tested in non-prod if the feature is high-risk.
- [ ] Final `requirement-audit` against the spec — every section
  reflects shipped reality. PASS.
- [ ] Knowledge base entity updated (`project-knowledge-base`).
- [ ] Project-specific skill references updated if the feature
  introduced internal API surface.
- [ ] PRD section updated (linked from the spec).
- [ ] Memory entry written: feature identity, related PRs, metrics to
  watch.
- [ ] Spec status flipped from `in-progress` to `shipped`.
- [ ] Hand-off complete: any follow-up tasks (deferred observability,
  doc updates, KB merges) recorded with owners.

**Done when:** all rows checked. Deliverable contract (1)–(7) in
AGENT.md satisfied.
