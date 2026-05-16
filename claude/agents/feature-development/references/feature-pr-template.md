# Feature PR description template

Use this template for any PR that implements a feature owned by the
feature-development agent. The PR description must link back to the
spec, list the verification rows, and record the rollout step.

A reviewer should be able to read this PR description + open the
linked spec and have a complete picture of intent, contract,
verification, and rollout — without asking the author follow-up
questions.

```markdown
## Feature

**Spec:** [docs/features/FEATURE_<slug>.md](../blob/main/docs/features/FEATURE_<slug>.md)
**Status (spec):** in-progress
**Owner:** @<handle>

## What changed

Two-to-five bullets — the *what*, plain prose. Reviewers read this
first to decide where to dig in.

- <change 1>
- <change 2>
- <change 3>

## Why

One paragraph or one link to the spec's section 1. Don't restate the
spec; reference it.

## Contract delta (links into the spec)

- API: [spec §5](../blob/main/docs/features/FEATURE_<slug>.md#5-api-contract-delta)
  | OpenAPI fragment: [api-delta.yaml](../blob/main/docs/features/<slug>/api-delta.yaml)
- Data: [spec §6](../blob/main/docs/features/FEATURE_<slug>.md#6-data-model-delta)
  | Migration preview: [schema-delta.sql](../blob/main/docs/features/<slug>/schema-delta.sql)
- Background: [spec §7](../blob/main/docs/features/FEATURE_<slug>.md#7-background-work-delta)

If a row doesn't apply, leave it as `N/A — <one-line reason>`. Don't
delete the row.

## Verification (mirrors spec §8)

### Automated

- [ ] `<test-file-1>` — covers <behaviour>.
- [ ] `<test-file-2>` — covers <behaviour>.
- [ ] Full project test suite passes locally.
- [ ] Project lint passes locally.
- [ ] Project build passes locally.

### Manual

- [ ] <manual check 1> — owner: @<handle>, when: pre-deploy / post-deploy.
- [ ] <manual check 2> — owner: @<handle>, when: …

### Observability

- [ ] New metric(s) declared: `<metric.name>` — type: counter /
  histogram / gauge.
- [ ] New alert(s) wired (or deferred to devops-engineer with PR /
  issue link).
- [ ] New log line(s) follow the project's structured-logging
  conventions.

## Rollout (mirrors spec §9)

- [ ] **Flag:** `<flag-name>` (or `N/A — straight ship`).
- [ ] **Strategy:** canary / blue-green / dark-launch / straight ship.
- [ ] **Rollback path:** revert this PR (and `<down-migration>` if data
  changed).
- [ ] **Comms drafted:** internal Slack / changelog / customer email
  (link or `N/A`).

## Risks + open questions

Copy or link from spec §10. Anything new the reviewer should weigh.

## Pre-merge checklist (mirrors feature-development Phase 4)

- [ ] Language code-review skill ran against the diff (e.g.
  `go-code-review`, `node-code-review`, `py-code-review`,
  `java-code-review`).
- [ ] Spec status was `approved` before code work began; any
  contract change since then is reflected in the spec.
- [ ] PR description verification rows are real (not aspirational).

## Post-merge follow-ups (queued for Phase 5)

- [ ] Update `docs/knowledge-base/entities/<entity>.md` (if the
  feature changes a KB entity).
- [ ] Update `skills/projects/<slug>/references/` (if the feature
  added internal API surface).
- [ ] Update `docs/PRD.md` section if PRD coverage changed.
- [ ] Write a `memory/` entry: feature identity + this PR's URL +
  metrics to watch.
- [ ] Flip spec status from `in-progress` to `shipped`.
```

## Filling discipline

- Every checkbox must be either checked, marked `N/A — <reason>`, or
  explicitly deferred with an owner.
- A blank checkbox at merge time means the row is unfinished — block
  merge.
- Post-merge follow-ups land within the same week, owned by the same
  person who merged.
