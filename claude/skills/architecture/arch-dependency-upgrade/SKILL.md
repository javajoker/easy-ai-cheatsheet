---
name: arch-dependency-upgrade
description: A tuned migration plan template specifically for major dependency upgrades — Postgres major version, Node LTS, framework major (React 18→19, Rails 7→8, Spring Boot 2→3, Django 4→5), runtime version, etc. Differs from arch-migration-plan in shape — tighter loop focused on changelog scan, test-matrix expansion, optional compat shim, canary fleet, gradual ramp (1% → 10% → 50% → 100%), and cleanup. Special-case for database major upgrades (write-cutover irreversibility). Output is dependency-upgrade-plan.md with the changelog scan, classified breaking changes, test matrix, and ramp schedule. Use this skill when the user says "upgrade Postgres major", "move to Node 22", "upgrade to React 19", "bump the major version of X", "we're on an EOL runtime". Pairs with arch-rollout-strategy (the ramp itself), with devops-ci-cd (test matrix runs in CI), with devops-observability (canary gates depend on metrics), with arch-breaking-change-comms (if the upgrade affects API consumers), and with arch-migration-plan (general parent skill — this is a specialised variant).
status: shipped
owner_agent: architecture-shepherd
---

# Arch Dependency Upgrade

The dep-upgrade variant of `arch-migration-plan`. Same
reversible-checkpoint discipline, but with the standard
dep-upgrade loop pre-shaped: changelog scan → test matrix →
canary → ramp → cleanup.

> **Database major upgrades have a write-cutover point past
> which rollback means data loss.** The skill flags this
> explicitly and adjusts the plan shape — the cutover phase is
> deliberately small with maximum verification before
> committing.

## Why this exists

Dependency upgrades are a recurring, predictable kind of
architectural change. Hand-rolling each one wastes time and
misses common pitfalls:

1. **No changelog scan.** Team upgrades; runtime surprises
   appear in production months later from a deprecated API the
   team didn't notice.
2. **Test-only-after-upgrade.** Tests run against the new
   version after merge; failures cascade; rollback is messy.
3. **All-or-nothing deploy.** New version deployed to 100% at
   once; first user hits the bug; full rollback required.
4. **Compat shim forever.** Bridge code shipped during upgrade
   stays in the codebase indefinitely.
5. **DB upgrade as ordinary deploy.** Major DB version upgrade
   treated like a code deploy; cutover happens without
   acknowledging the write-cutover irreversibility.

This skill ships the tuned loop so each upgrade follows the
same disciplined shape.

## When to fire

Fire when:

- The user says *"upgrade to <major version of X>"*, *"bump
  the major"*, *"we're on an EOL version of <runtime /
  framework / DB>"*, *"move to Node 22 / Postgres 16 / Rails
  8"*.
- A security advisory forces a major-version upgrade.
- Annual dependency-refresh cycle.

Do **not** fire when:

- The upgrade is a minor or patch version (use normal patch
  flow — usually just merge dependabot PR after CI passes).
- The change is a non-dep architectural refactor (use
  `arch-migration-plan` proper).
- The upgrade is across many components in concert (use
  `arch-migration-plan` for the orchestrating plan; this skill
  for each individual upgrade).

## Inputs

Required:

- The dependency name + current version + target version.
- `INSTRUCTIONS/projects/<slug>/project-context.md` — stack +
  test commands.

Asked once (cap at 3):

1. **Reversibility constraint.** Standard (rollback possible)
   / DB-major (write-cutover irreversibility) / runtime
   (host-environment change).
2. **Canary fleet capacity.** Can we run mixed versions in
   production? (Most stacks yes; some legacy ones can't.)
3. **External consumer impact.** Does this upgrade change
   anything externally visible (API responses, error formats,
   webhook shapes)?

## The opinionated dep-upgrade loop

### Step 0 — Changelog scan

Read the upstream changelog from current to target. Classify
each breaking change:

| Class | Example | Action |
|---|---|---|
| **Mechanical fix** | Function renamed; same semantics | Codemod or manual rename |
| **Behavioural change** | Default config changed; output format adjusted | Update tests; verify behavior |
| **Removed feature** | API surface deleted | Find replacement; rewrite call sites |
| **Deprecation warning** | Warns now; removed next major | Track for next upgrade; don't block this one |

Output: a per-change table in the upgrade plan.

### Step 1 — Compat shim (if applicable)

If old + new must coexist temporarily (e.g. some services
upgrade ahead of others), document the shim:

- What it bridges.
- How long it lives (typically ≤2 ramp cycles).
- Cleanup phase that removes it.

Many upgrades don't need a shim (mono-repo with atomic upgrade
across services); skip if not needed.

### Step 2 — Test matrix expansion

Add the target version to CI's test matrix:

- Existing tests run against current + target.
- Failures categorised: mechanical (codemod) / behavioural
  (test update) / unexpected (investigation).
- Fix failures *before* canary.

### Step 3 — Canary fleet

A subset of production traffic runs the new version with extra
observability:

- **Size:** typically start at 1% of traffic / instances.
- **Selection:** random sample (avoid biased subsets like
  "internal traffic only" which won't surface real-world
  patterns).
- **Observability:** elevated logging + tracing for the canary
  fleet; comparison dashboard (canary vs. baseline).
- **Soak period:** minimum 24h at 1% before considering ramp;
  longer for low-volume traffic.

### Step 4 — Ramp schedule

| Stage | % | Soak | Gate |
|---|---|---|---|
| Canary | 1% | 24–48h | Error rate, latency p99 within X% of baseline |
| Early | 10% | 24h | Same |
| Mid | 50% | 12–24h | Same + dependency saturation |
| Full | 100% | – | Complete |

Each stage has explicit metric gates (per `devops-observability`).
Gate failures abort the ramp.

### Step 5 — Rollback per stage

Rollback procedure per stage (verbatim commands):

- **Canary failure** → remove canary subset; new version off
  production immediately.
- **Early / Mid failure** → roll back to previous stage's
  percentage; investigate.
- **Full failure** → emergency rollback procedure (per
  `devops-release-management` rollback policy).

For non-rollbackable upgrades (DB major), the rollback per
stage exists only *before* the write-cutover.

### Step 6 — Cleanup

After 100% on target version + soak period (typically 1 week
of stable operation):

- Remove compat shims (if any).
- Remove version pins / conditional code.
- Update docs / READMEs that mention the old version.
- Close the upgrade ticket / project.

Cleanup is a *phase* of the upgrade plan, not a follow-up.

## Special-case: database major upgrades

DB major version upgrades (e.g. Postgres 14 → 15 → 16) have
unique shape:

### Pre-cutover (reversible)

- Provision new DB instance at target version.
- Replicate from old → new (logical or physical).
- Verify replication lag low + consistent.
- Run application against new DB read-only — verify queries
  succeed.

### Cutover (write-cutover point — past this, rollback means data loss)

- Quiesce writes briefly (typically <60s).
- Verify replication caught up.
- Repoint application connection string to new DB.
- Resume writes.

### Post-cutover (forward-only)

- Monitor for 24–72h at full traffic.
- Keep old DB available read-only for emergency data lookup
  (typically 7 days).
- Decommission old DB.

**Rollback after cutover** requires either:

- (a) Replicating new → old (rarely set up; data written
  post-cutover is lost on rollback), or
- (b) Restoring old DB from backup taken just before cutover
  (post-cutover writes lost).

Both are forms of data loss. The cutover phase plan must
acknowledge this explicitly and the cutover decision must be
authorised by the named decision authority.

## The procedure

### Phase 1 — Read inputs + classify reversibility

Pull dep name, current version, target version. Classify per
the inputs question.

### Phase 2 — Changelog scan

Walk the changelog. Build the per-change table. Identify which
changes apply to *this* project (most don't — but the ones that
do are critical).

### Phase 3 — Test matrix update

Update CI to run against both current + target. Drive failures
to zero before canary.

### Phase 4 — Build the ramp plan

Per the loop. Set explicit per-stage gates referencing actual
dashboards (not "we'll watch carefully").

### Phase 5 — Special-case DB cutover (if applicable)

If reversibility is "DB-major": insert the pre-cutover /
cutover / post-cutover phases. Decision authority confirms
cutover separately from "do this upgrade" — these are different
decisions.

### Phase 6 — Documentation impact

Inventory what mentions the old version:

- READMEs.
- Architecture diagrams.
- Runbooks (from `devops-incident-runbook`).
- API docs (if the dep is API-facing).
- Customer-facing docs.

Each gets updated in the cleanup phase.

### Phase 7 — Emit the upgrade plan

Write `dependency-upgrade-plan.md` using
[references/dependency-upgrade-template.md](references/dependency-upgrade-template.md).

After writing:

1. Surface to user; confirm.
2. Persist as `type: project` memory (`dep_upgrade_<dep>_<from-to>_v1`).
3. Hand off:
   - `arch-rollout-strategy` for the ramp itself.
   - `devops-ci-cd` for the test matrix update.
   - `devops-observability` for the canary dashboards.
   - `arch-breaking-change-comms` if external consumer impact.

### Phase 8 — Watch for abort triggers

Abort the upgrade (rollback to current version) when:

- Gate failure at any ramp stage.
- Critical regression discovered post-cutover (DB-major:
  immediate restore from pre-cutover backup; accept data loss).
- Vendor publishes critical bug in target version.

Aborts are documented; the upgrade is re-planned (often
targeting a different version or after the upstream bug is
fixed).

## Anti-patterns

- **No changelog scan.** Surprises in production.
- **No canary.** Bug hits 100% of users on day one.
- **Canary as "deploy to staging".** Staging doesn't surface
  production-traffic patterns. Canary is *production-tier
  traffic at small percentage*.
- **Soak skipped.** "Looks good after 5 minutes; ramp."
  Subtle bugs need hours.
- **Compat shim that doesn't get removed.** Add the cleanup
  phase to the plan; assign owner; track to completion.
- **DB cutover without explicit acknowledgement of write-
  cutover.** Treating a one-way decision like a reversible
  one. Decision authority must explicitly approve.
- **Documentation drift.** Old version still referenced in
  docs months after upgrade. Cleanup phase covers this.

## Companion skills

- `arch-migration-plan` — parent skill; this is the specialised
  variant.
- `arch-rollout-strategy` — implements the ramp.
- `arch-breaking-change-comms` — external comms if applicable.
- `devops-ci-cd` — test matrix.
- `devops-observability` — canary dashboards.
- `devops-incident-runbook` — runbook for cutover incident.
- `devops-release-management` — rollback procedure tie-in.

## Reference files

- [references/dependency-upgrade-template.md](references/dependency-upgrade-template.md) —
  canonical output document.
- `references/db-major-cutover-checklist.md` — pre-cutover /
  cutover / post-cutover discipline for database major
  upgrades.
- `references/changelog-scan-vocabulary.md` — classification
  rules for breaking-change types.
- `references/ramp-schedule-examples.md` — pre-worked ramp
  schedules for common upgrade types.
