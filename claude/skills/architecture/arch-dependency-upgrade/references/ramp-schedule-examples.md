# Ramp Schedule Examples

Pre-worked ramp schedules for common dependency-upgrade types.

## Example 1 — Low-risk minor-impact upgrade

Postgres patch version, Node minor (e.g. 22.5 → 22.7).

| Stage | % | Soak |
|---|---|---|
| Dev | 100% | 1 day |
| Staging | 100% | 1 day |
| Prod canary | 5% | 12h |
| Prod | 100% | – |

Total: ~3 days.

## Example 2 — Standard major framework upgrade

React 18 → 19, Spring Boot 2 → 3, FastAPI minor with deprecations.

| Stage | % | Soak |
|---|---|---|
| Dev | 100% | 3 days |
| Staging | 100% | 1 week (run full smoke / load) |
| Prod canary | 1% | 48h |
| Prod early | 10% | 24h |
| Prod mid | 50% | 12h |
| Prod full | 100% | – |

Total: ~2 weeks (excluding fix time for test failures).

## Example 3 — Major runtime upgrade

Node 20 LTS → 22 LTS, Python 3.11 → 3.12.

| Stage | % | Soak |
|---|---|---|
| Dev | 100% | 1 week (find perf regressions) |
| Staging | 100% | 1 week (full load + soak) |
| Prod canary | 1% | 72h (extra soak for runtime surprises) |
| Prod early | 10% | 48h |
| Prod mid | 50% | 24h |
| Prod full | 100% | – |

Total: ~3 weeks.

## Example 4 — Postgres major version

Postgres 14 → 16.

| Stage | What | Reversibility |
|---|---|---|
| Provision new | New DB at target version | fully reversible |
| Replicate | logical replication, lag <1s | reversible |
| Verify read-only | app reads from new in staging | reversible |
| Pre-cutover gates | backup, on-call, status page | reversible |
| **Cutover** | switch writes to new DB | **one-way after this point** |
| Post-cutover monitor | 24h at full traffic | forward-only |
| Old DB read-only | retained 7 days for emergency lookup | – |
| Decommission old | delete old DB | final |

Total: 2–4 weeks. See [db-major-cutover-checklist.md](db-major-cutover-checklist.md).

## Example 5 — High-risk dependency with sparse production data

Major DB driver upgrade, payment SDK major, auth library major.

| Stage | % | Soak |
|---|---|---|
| Dev | 100% | 1 week |
| Staging — synthetic traffic | 100% | 1 week |
| Staging — shadow prod traffic (read-only) | 100% | 1 week |
| Prod canary | 1% | 1 week (longer soak; data variety matters) |
| Prod early | 10% | 3 days |
| Prod mid | 50% | 2 days |
| Prod full | 100% | – |

Total: ~4–5 weeks.

## Soak-period principles

- **Cover at least one peak + one off-peak cycle.**
- **Include a weekly cycle** for cron/scheduled-job behaviour.
- **Include known traffic spikes** (e.g. Monday morning, hour
  before close-of-business in primary timezone).
- **Don't accelerate "because it looks fine"** — subtle bugs
  often surface in low-traffic hours after data accumulates.

## When to deviate

Faster:

- Security CVE with active exploit → compress canary to hours,
  not days. Document acceptance of accelerated risk.
- Low-volume internal-only service.

Slower:

- Regulated environment requiring evidence at each stage.
- Distributed system where consistency bugs surface only at scale.
- Customer base with long change-management windows (B2B
  enterprise).
