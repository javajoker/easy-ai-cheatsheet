# Strategy Decision Matrix

Mapping common change shapes to rollout strategies. Defaults; the
user may override with documented rationale.

## The five strategies

| Strategy | Mechanic | Cost | Risk |
|---|---|---|---|
| **big-bang** | Deploy 100% at once | low | high (bug → all users) |
| **blue-green** | Two stacks; atomic switch | high (2× infra during cutover) | low (instant rollback via switch) |
| **canary** | Small % first; ramp on metrics | medium | medium (requires good obs) |
| **dark-launch** | Mirror traffic; users see old | high (duplicate infra) | low (no user impact during test) |
| **feature-flagged** | Code deploys; flag gates | low (flag service cost) | low (instant disable) |

## Decision matrix

| Change shape | Recommended strategy | Why |
|---|---|---|
| Internal tool refactor | big-bang | No user impact; speed wins |
| New service stand-up | canary or blue-green | Verify behaviour before full traffic |
| New API endpoint (additive) | canary | Catch regressions on small slice |
| API contract change (breaking) | feature-flagged at API boundary | Per-consumer migration; old + new coexist |
| Behaviour change (algorithm, business logic) | feature-flagged + canary on flag | Fine-grained control |
| Performance optimisation | canary | Verify perf gain at scale |
| Major framework upgrade | canary | Verify runtime behaviour at scale |
| DB major version upgrade | canary (read-only) → blue-green cutover | Pre-cutover verification; atomic switch |
| Configuration default change | feature-flagged | Per-consumer migration |
| Security patch (critical) | canary (compressed) or big-bang per CVE policy | Risk acceptance documented |
| Cosmetic UI change | big-bang | No backend risk |
| Pricing / billing change | feature-flagged | Strict customer cohort control |
| ML model swap | dark-launch → canary | Verify quality before exposure |
| Search index swap | dark-launch → canary | Verify relevance before exposure |
| High-risk experimental change | dark-launch → feature-flagged → canary | Maximum safety; multiple gates |

## When to deviate

| Force a different strategy when… | Deviation |
|---|---|
| Stateful long-running connections (websocket, gRPC streaming) | Add session-affinity to canary; reconnects gracefully handled |
| Heavy regulatory environment | Add audit-log gate between every stage |
| Customer pre-announces freeze window | Strict feature-flagged; release within the customer-specific cohort |
| Vendor SLA penalties for incidents | Add extended soak; require named approver for each stage |

## Anti-patterns

- **Big-bang for DB-major upgrades.** The one strategy that
  should *never* be big-bang.
- **Canary without good observability.** Canary is meaningless
  if you can't compare canary vs. baseline. Confirm
  `devops-observability` is in place first.
- **Feature flag debt.** Adding a flag during rollout that's
  never cleaned up. Always include flag cleanup in the
  post-rollout phase.
- **Dark launch with side effects enabled.** Dark traffic must
  not trigger external calls, writes, charges, emails. Easy to
  forget one.
- **Strategy choice by team preference.** Strategy is chosen by
  the change shape + risk; not by what the team likes.
