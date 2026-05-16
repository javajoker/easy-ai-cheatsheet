---
name: arch-rollout-strategy
description: Designs the rollout strategy for an architectural change — picks among blue-green / canary / dark-launch / feature-flagged / big-bang with justification, defines the sequence (environments × percentages × durations), the metric gates that must stay green to ramp (tied to SLOs from devops-observability), the abort conditions (automatic vs human-initiated), and the verbatim rollback commands per stage. Output is rollout-strategy.md ready to hand to devops-engineer for gate implementation and to the release approver for sign-off. Use this skill when the user asks "how do we roll this out", "plan the deploy", "design the canary", "what's our rollback procedure for this change". Pairs with arch-migration-plan (consumes the migrated state and rolls it out), with arch-dependency-upgrade (provides the ramp mechanic), with devops-engineer agent (builds the gates this skill specifies), with devops-observability (gates depend on SLO burn-rate + custom metrics), with devops-release-management (operates within the release policy), and with requirement-audit (per-stage PASS/FAIL gates).
status: shipped
owner_agent: architecture-shepherd
---

# Arch Rollout Strategy

The deployment side of an architectural change. The migration
plan changes the code; the rollout strategy changes runtime
behaviour without breaking users.

> **Strategy choice has trade-offs; defaults are not safe by
> default.** Big-bang is fastest and most fragile. Blue-green
> is safest and most expensive. Canary balances both but
> requires good observability. The skill makes the trade-off
> explicit and justifies the choice.

## Why this exists

Deployment failures during architectural changes are
predictable:

1. **Default to big-bang.** Team deploys 100% at once because
   it's "simple"; first user hits the bug; rollback is full
   redeploy of previous version.
2. **Canary with no gates.** Canary deployed; nobody watches;
   ramp proceeds on calendar not on metrics; bug hits 100%
   anyway.
3. **Rollback as theory.** Rollback procedure documented but
   never tested; first attempt during incident reveals
   broken procedure; outage extends.
4. **No abort conditions.** "Roll forward at engineer's
   discretion" → engineer is tired / under pressure / wrong;
   ramp continues past failure.
5. **Customer-visible flap.** Rolling deploy without session
   stickiness causes users to bounce between versions;
   inconsistent UX.

This skill enforces strategy choice with rationale, metric
gates tied to dashboards, automatic abort conditions, and
verbatim per-stage rollback.

## When to fire

Fire when:

- An `arch-migration-plan` phase ships code to production and
  needs a rollout plan.
- `arch-dependency-upgrade` reaches the ramp planning.
- The user asks *"plan the deploy"*, *"design the canary"*,
  *"how do we roll this out"*, *"what's our rollback for this
  change"*.
- A high-risk feature is about to ship and needs strategy
  beyond the standard `devops-release-management` cadence.

Do **not** fire when:

- The deploy is a routine patch / minor release — `devops-
  release-management` covers it.
- The change is internal (no user impact) and can ship via
  standard pipeline.
- The user wants the policy, not a specific rollout — that's
  `devops-release-management`.

## Inputs

Required:

- `arch-migration-plan` (specific phase being rolled out) OR
  `arch-dependency-upgrade` ramp plan.
- `devops-observability` SLOs for the affected services
  (drives the gates).

Asked once (cap at 3):

1. **Customer impact tolerance.** Internal-only / low (some
   users may notice) / zero (must be invisible).
2. **Reversibility.** Reversible / partially / one-way (e.g.
   data migration past cutover).
3. **Speed target.** Hours / days / weeks — drives strategy
   choice.

## The five strategies

### 1. Big-bang

**Mechanic:** Deploy to 100% at once. Stop old version.

**Use when:** Internal tools; no user impact; full
reversibility; speed >> safety.

**Cost:** Cheapest; no infrastructure overhead.

**Risk:** Any bug hits 100% of users immediately.

**Rollback:** Redeploy previous version (per `devops-release-
management` rollback procedure).

### 2. Blue-green

**Mechanic:** Two identical production stacks (blue + green).
New version deploys to green while blue serves traffic. Cut
traffic from blue → green atomically. Keep blue available for
fast rollback.

**Use when:** Need atomic cut + fast rollback; can afford
double infrastructure during cutover.

**Cost:** 2× infrastructure during cutover (typically minutes
to hours).

**Risk:** Stateful components (DBs) complicate the picture —
both colours typically share the DB; schema changes need to be
backward-compatible.

**Rollback:** Redirect traffic blue → green back to blue (one
config change).

### 3. Canary

**Mechanic:** New version receives a small percentage of
traffic; monitor; ramp if healthy.

**Use when:** Need to verify behaviour at production load
before full deploy. The dominant strategy for most non-trivial
changes.

**Cost:** Modest — both versions running in parallel for the
ramp duration.

**Risk:** Requires good observability (canary vs. baseline
comparison) and disciplined ramp gates. Sticky sessions or
user-affinity may be needed to avoid bouncing users between
versions.

**Rollback:** Drop canary subset to 0%.

### 4. Dark launch / shadow traffic

**Mechanic:** Deploy new version; mirror production traffic to
it (in addition to old version); compare outputs; users see
old version's responses.

**Use when:** Change is risky and you need real-traffic data
without user-visible risk.

**Cost:** High — new infrastructure runs at full traffic
duplicate; comparison tooling needed.

**Risk:** Side-effects must be disabled in dark path (no
writes, no external calls); easy to forget one.

**Rollback:** Stop the dark traffic; deploy nothing user-
visible.

### 5. Feature-flagged

**Mechanic:** Code deploys; behaviour gated by feature flag;
flag rolled out gradually (per-user, per-cohort, per-percentage).

**Use when:** Behaviour change rather than infrastructure
change; need fine-grained control over who sees the new
behaviour.

**Cost:** Modest — feature flag service + flag management.

**Risk:** Flag debt — flags that are never removed accumulate
forever and create test-matrix explosion.

**Rollback:** Disable the flag (one config change).

## The procedure

### Phase 1 — Match strategy to change

Use the input answers + the change shape to pick:

| Change | Recommended strategy |
|---|---|
| Internal tool refactor | Big-bang |
| New service stand-up | Canary or Blue-green |
| Major framework upgrade | Canary |
| DB major upgrade | Canary (read-only first) → blue-green cutover |
| Behaviour change (algorithm, business logic) | Feature-flagged + canary on the flag |
| High-risk experimental change | Dark launch → Feature-flagged → Canary ramp |
| API contract change | Feature-flagged at the API boundary |

The user may override; document the rationale either way.

### Phase 2 — Define the sequence

For canary / blue-green / feature-flagged, define the ramp:

```
Stage 1: 1% of traffic for 24h
Stage 2: 10% of traffic for 12h
Stage 3: 50% of traffic for 12h
Stage 4: 100%
```

Adjust durations per:

- Traffic volume (low volume needs longer soak).
- Change risk (riskier = longer soak).
- Time-of-day patterns (cover peak + off-peak).
- External constraints (freeze windows from `devops-release-
  management`).

### Phase 3 — Define metric gates

Each stage has explicit gates. Sources:

- **SLO burn-rate** from `devops-observability` (already
  defined; reference them).
- **Error rate** vs. baseline (canary vs. control).
- **Latency p95/p99** vs. baseline.
- **Custom business metrics** if applicable (e.g. conversion
  rate must not drop).

Gates are concrete:

- ✓ "Canary error rate ≤ 1.05× baseline error rate over 1h
  window".
- ✗ "Canary looks healthy".

### Phase 4 — Define abort conditions

Two classes:

| Abort class | Trigger | Action |
|---|---|---|
| Automatic | SLO burn-rate >14.4× for 5 min | Pipeline auto-aborts; rollback initiated |
| Automatic | Error rate >3× baseline | Pipeline auto-aborts |
| Automatic | Canary p99 latency >2× baseline | Pipeline auto-aborts |
| Human-initiated | Pattern observed by on-call | On-call calls abort + initiates rollback |

Automatic aborts are non-negotiable for high-risk rollouts —
don't rely on humans to abort under pressure.

### Phase 5 — Rollback per stage

Each stage gets a verbatim rollback procedure:

- **Required CLI / kubectl / cloud-console commands.**
- **Required permissions / context.**
- **Named decision-maker** authorised to invoke.
- **Expected duration.**
- **Verification command** (how we know rollback succeeded).

The rollback procedure is **scripted**, not documented prose:

```bash
# scripts/rollback/stage-2.sh
#!/usr/bin/env bash
set -euo pipefail
# Required context: KUBECONFIG=prod
# Approver: <role>
# Expected duration: 2-5 minutes

kubectl set traffic-split <service> --canary 0 --stable 100 -n prod
kubectl rollout status -n prod <service>
echo "Rollback complete; verify dashboard <url>"
```

### Phase 6 — Communication

For each stage transition + abort scenario:

- Internal Slack message template.
- Status-page update template (if customer-visible).
- Customer email template (if customer-impacting).
- On-call paging trigger.

Templates committed in `docs/comms-templates/rollout/`.

### Phase 7 — Emit the strategy

Write `rollout-strategy.md` using
[references/rollout-strategy-template.md](references/rollout-strategy-template.md).

After writing:

1. Surface to user; confirm strategy + sequence + gates.
2. Hand off to `devops-engineer` agent to implement the
   metric gates + automatic abort wiring in CI/CD.
3. Sign-off from release authority (per `devops-release-
   management`).
4. Persist as `type: project` memory (`rollout_<change>_v1`).

### Phase 8 — Watch during ramp

The conductor (or named on-call) watches the rollout:

- Each stage's gates green for the required soak.
- Any abort condition triggers stop-the-ramp.
- Each stage transition has a one-line announcement in the
  internal channel.
- Completion or abort is recorded; if aborted, postmortem per
  `devops-incident-runbook`.

## Anti-patterns

- **Big-bang for risky changes.** Speed-vs-safety trade-off
  goes wrong in production.
- **Canary without gates.** "Canary looks fine" is opinion;
  numbers are evidence.
- **Calendar ramps.** Ramping by clock rather than by metric
  state defeats the purpose of canary.
- **Rollback as prose.** Documented but un-scripted rollback
  fails under pressure.
- **No automatic abort.** Humans miss alerts under load.
- **Feature flag debt.** Flag added during rollout; never
  removed; persists for years.
- **DB-major as big-bang.** The one strategy that should
  *never* be big-bang. Use blue-green + canary read-only
  combination.

## Companion skills

- `arch-migration-plan` — upstream input.
- `arch-dependency-upgrade` — provides the ramp mechanic.
- `arch-breaking-change-comms` — customer comms during rollout
  if applicable.
- `devops-engineer` (agent) — implements the gates.
- `devops-observability` — gates depend on SLO + custom
  metrics.
- `devops-release-management` — operates within the release
  policy.
- `devops-incident-runbook` — abort triggers an incident;
  runbook ties in.
- `requirement-audit` — per-stage PASS/FAIL.

## Reference files

- [references/rollout-strategy-template.md](references/rollout-strategy-template.md) —
  canonical output document.
- `references/strategy-decision-matrix.md` — how to pick among
  the five strategies for common change shapes.
- `references/gate-vocabulary.md` — concrete examples of
  measurable gates per metric type.
- `references/rollback-scripts-cookbook.md` — verbatim
  rollback patterns for common deploy systems (k8s, ECS, Lambda,
  Cloud Run).
