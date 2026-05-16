---
name: devops-release-management
description: Defines the release *policy* for a project — cadence (daily / weekly / on-demand), freeze windows (end-of-quarter, holidays, customer events), approval chain (who signs off), versioning scheme (SemVer / CalVer / trunk-based with feature flags), rollback procedure (verbatim, with named decision-maker), and communication (where releases are announced). Output is release-policy.md ready to live in the project repo and be referenced by every release. Distinct from devops-ci-cd (which is the pipeline that runs releases) and arch-rollout-strategy (which is in-flight strategy for a specific change). This skill is the *policy* layer all three converge on. Use this skill when the user asks "how do we release", "set the release cadence", "define the freeze windows", "what's the rollback procedure", "we keep arguing about who approves". Pairs with devops-ci-cd (pipeline implements the policy's approval gate), with arch-rollout-strategy (rollout strategy operates within the policy), with arch-breaking-change-comms (communication template for breaking releases), with gtm-launch-readiness (launch is a release with extra checks), and with memory-ontology (the policy is a `type: project` decision worth persisting).
status: shipped
owner_agent: devops-engineer
---

# DevOps Release Management

Owns the *policy* for releases — the rules every release follows.
The pipeline implements the policy; the rollout strategy operates
within it; this skill writes the policy down.

> **Without a policy, every release re-negotiates.** Cadence,
> approval, rollback are re-decided per release; sometimes nobody
> approves; sometimes the rollback is *"hope"*. A written policy
> turns recurring decisions into routine.

## Why this exists

Release-management failures are predictable:

1. **No cadence.** Releases happen when someone feels like it.
   Bunched releases on Fridays; nothing for two weeks; then a
   panic deploy Friday night.
2. **No freeze policy.** Releases ship during major customer
   events / Black Friday / end-of-quarter; outages land at the
   worst times.
3. **Ambiguous approval.** "Who approves prod deploys?" → "I
   thought you did" → broken deploy.
4. **Versioning anarchy.** Some commits get tagged; some don't;
   nobody knows what shipped when.
5. **Rollback as folklore.** "We'd just revert the deploy" —
   nobody has tested that's actually a working command for the
   current setup.
6. **Silent releases.** Code ships; customers find out from
   bugs; support has no idea what's new.

This skill ships an opinionated policy template that names the
load-bearing decisions and forces explicit choices.

## When to fire

Fire when:

- The user asks *"how do we release"*, *"set the cadence"*,
  *"define freeze windows"*, *"what's the rollback procedure"*,
  *"we keep arguing about approvals"*.
- A project is preparing for prod (needs a policy before first
  release).
- An existing policy is being revisited (annual review;
  post-incident change).

Do **not** fire when:

- The user wants a specific in-flight rollout designed — that's
  `arch-rollout-strategy`.
- The user wants the pipeline written — that's `devops-ci-cd`.
- The user wants to *do* a release, not write the policy — help
  them release per the existing policy.

## Inputs

Required:

- `INSTRUCTIONS/projects/<slug>/project-context.md` — project
  stage (pre-launch / launched), team size, customer profile.

Asked once (cap at 4):

1. **Risk tolerance.** Conservative / balanced / move-fast.
   Drives cadence + approval depth.
2. **Customer profile.** Enterprise (predictability matters) /
   consumer (velocity matters) / both.
3. **Team size.** <5 / 5–20 / 20+. Drives approval-chain shape.
4. **External commitments.** Customer SLAs that constrain freeze
   windows or change-notification timelines.

## The opinionated policy framework

### Decision 1 — Cadence

| Cadence | Use when |
|---|---|
| **Continuous** (every PR) | Trunk-based + feature flags; high team trust |
| **Daily** | Small team; SaaS; balanced risk |
| **Weekly** | Mid-size team; predictable cycle |
| **Bi-weekly / Sprint** | Larger teams; coordinated release trains |
| **On-demand** | Low-volume; legacy systems; high-risk domains |

The skill suggests based on inputs; the user decides.

### Decision 2 — Freeze windows

Times when releases are paused unless explicitly approved as an
emergency:

- **Code freeze** — no merges to main.
- **Deploy freeze** — merges allowed, deploys paused.

Default freezes:

| Window | Type | Why |
|---|---|---|
| Friday afternoon → Monday morning | Deploy | No on-call for weekend incidents |
| Last week of each quarter | Deploy | Q-end customer demos / financial reporting |
| Major holidays | Deploy | Skeleton on-call only |
| Customer's go-live week (B2B) | Deploy | Don't break the customer's launch |
| Major launch -3 days through +3 days | Deploy | Stabilise the launch |

Emergency override: explicit approval from <named role> +
documented business justification + on-call confirmed available.

### Decision 3 — Approval chain

| Stage | Approver |
|---|---|
| Dev deploy | Auto |
| Staging deploy | Auto |
| Prod deploy (standard) | Engineer + 1 reviewer (typically the PR reviewer) |
| Prod deploy (high-risk: data migration, infra change, auth) | Engineer + 1 reviewer + 1 senior engineer |
| Prod deploy (during freeze) | Above + named override authority |

Never ambiguous. The pipeline (`devops-ci-cd`) implements these
gates.

### Decision 4 — Versioning

Three viable patterns:

| Pattern | When |
|---|---|
| **SemVer** (`v1.2.3`) | Libraries; APIs with explicit contract |
| **CalVer** (`2026.5.15`) | Apps; "what date is this from" matters most |
| **Trunk + flags** (no versions; flags gate features) | High-velocity SaaS; feature-flagged delivery |

Pick one. Document the convention. Enforce in CI (tag every
release; reject merges that change version inconsistently).

### Decision 5 — Rollback

**Three modes**, escalating cost:

| Mode | When |
|---|---|
| **Reverse deploy** | Redeploy the previous artifact (fastest, no state migrations) |
| **Revert + redeploy** | `git revert`, merge, deploy — when reverse deploy fails |
| **Forward fix** | Ship a fix forward — when rollback impossible (DB migrated, customer data committed) |

Each mode has a verbatim procedure documented:

- Required CLI / kubectl context.
- Named approver who can authorise.
- Communication template.
- Expected duration.
- Verification command.

**Rollback drill cadence:** Quarterly minimum. If the team hasn't
done a rollback in 3 months, schedule a drill.

### Decision 6 — Communication

| Audience | Channel | When |
|---|---|---|
| Engineering | `#deploys` channel | Every deploy (auto-posted by pipeline) |
| Customers (breaking changes) | Email + changelog | Per `arch-breaking-change-comms` |
| Customers (feature releases) | Changelog + release notes | At each significant release |
| Status page | `status.<domain>` | During incidents + scheduled maintenance |

Templates committed in `docs/comms-templates/`.

## The procedure

### Phase 1 — Read context

Open project-context.md. Pull stage, team size, customer
profile, any existing release notes.

### Phase 2 — Decisions 1–6

Run through each decision with the user. Cap at 4 questions
total — the skill recommends defaults and asks where the
defaults clearly don't fit.

### Phase 3 — Write the policy

Write `release-policy.md` using
[references/release-policy-template.md](references/release-policy-template.md).

The policy is **canonical** — every release references it.
Versioned (`v1`, `v2`); changes go through a documented review,
not silent edits.

### Phase 4 — Wire enforcement

- `devops-ci-cd` implements the approval-chain gates.
- Freeze windows are enforced via pipeline check (CI refuses to
  deploy during freezes without override flag).
- Rollback commands live as scripts in `scripts/rollback/` —
  not as Slack-message folklore.

### Phase 5 — First release drill

Before declaring done, walk through one full release per the
policy:

- Merge a no-op PR.
- Deploy through the chain.
- Run a rollback drill on staging (reverse-deploy mode).
- Confirm communication landed in the expected channels.

A policy untested in practice is aspirational. The first drill
catches the mismatches between policy and reality.

### Phase 6 — Persist

- Persist as `type: project` memory (`release_policy_<slug>_v1`).
- Schedule the next review (annual default).
- Hand off to `lifecycle-pilot` if the project is approaching
  launch (launches inherit the policy with extra checks via
  `gtm-launch-readiness`).

## Anti-patterns

- **Policy as wiki page nobody reads.** Live in the repo
  (`release-policy.md` at root or under `docs/`). Referenced
  by CI. Reviewed annually.
- **Heroic Friday deploys.** The freeze is for everyone — most
  often violated by senior engineers who think they're the
  exception. Make exceptions explicit and rare.
- **Ambiguous approver.** "The team" approves means nobody
  approves. Name the role.
- **Rollback as theory.** A rollback procedure that's never been
  tested doesn't exist. Quarterly drills.
- **Silent releases.** Even tiny releases get a one-line
  changelog. Customers tracking your product appreciate it; you
  appreciate it post-incident.
- **Releasing during launch week.** A launch is the worst time
  for an unrelated release. Freeze the unrelated work.
- **Versioning by gut feel.** "I think this is a minor bump" →
  consumers can't predict. Document the rule; enforce in CI.

## Companion skills

- `devops-ci-cd` — implements the gates.
- `arch-rollout-strategy` — in-flight strategy operates within
  the policy.
- `arch-breaking-change-comms` — comms template for breaking
  releases.
- `gtm-launch-readiness` — launch is a release with extra
  checks.
- `devops-incident-runbook` — rollback procedures live alongside
  runbooks.
- `memory-ontology` — persist the policy.

## Reference files

- [references/release-policy-template.md](references/release-policy-template.md) —
  canonical policy document.
- `references/freeze-window-examples.md` — worked freeze policies
  for common project types.
- `references/rollback-procedures-cookbook.md` — verbatim
  rollback procedures for common stacks.
