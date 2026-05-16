# Phase Decomposition Patterns

Pre-worked phase decompositions for common migration shapes. Use
as starting points; adapt to the specific scenario.

## Pattern 1 — Service extraction

Extracting a service out of a monolith (or split between services).

| Phase | Deliverable | Reversible checkpoint |
|---|---|---|
| 1 — Stand up new service (empty) | Service deployed; health check green | Service runs but receives 0 traffic; safe to delete |
| 2 — Mirror writes | Service captures writes; data persists in both old + new | Stop mirror; old path still has all data |
| 3 — Backfill historical data | New service has full historical data | Old DB still authoritative; cancel cleanly |
| 4 — Mirror reads (shadow) | New service serves reads in shadow mode; compare outputs | Stop shadow; old path serves all traffic |
| 5 — Cutover reads | New service serves live read traffic | Repoint reads back to old — both still write |
| 6 — Cutover writes | New service is authoritative | Tricky — possible only if old kept writing in mirror |
| 7 — Decommission old | Old code removed; old DB taken down | Not reversible; final |

## Pattern 2 — Database major version upgrade

Postgres N → N+1; MySQL 5.7 → 8.0; etc.

| Phase | Deliverable | Reversible checkpoint |
|---|---|---|
| 1 — Provision new DB at target version | Empty new DB ready; connection tested | Drop new DB; no impact |
| 2 — Replicate old → new | Replication lag < 1s sustained | Pause replication; old DB unaffected |
| 3 — Verify app against new DB read-only | App runs against new DB in dev/staging | Continue using old DB; no impact |
| 4 — Write cutover (irreversible after this) | App writes to new DB | **NOT REVERSIBLE** beyond backup restore |
| 5 — Verify steady state on new DB | 24–72h at full traffic; metrics within target | Forward-only |
| 6 — Decommission old DB | Old DB retained read-only 7d, then deleted | Final |

## Pattern 3 — Sync → async (event-driven)

Moving a previously-synchronous flow to async.

| Phase | Deliverable | Reversible checkpoint |
|---|---|---|
| 1 — Stand up event infra | Kafka/SQS/NATS deployed; topics created | No producer/consumer; safe to delete |
| 2 — Producer also enqueues | Existing sync flow unchanged; events also emitted | Disable enqueueing; no impact |
| 3 — Consumer reads + processes (no side effects) | Consumer runs; logs what it would do | Stop consumer; no impact |
| 4 — Consumer enables side effects | Consumer behaves identically to sync flow | Disable side effects via feature flag |
| 5 — Sync flow disabled | Async is sole path | Re-enable sync via flag |
| 6 — Remove sync code | Sync code deleted | Final |

## Pattern 4 — Major framework upgrade (e.g. React 18 → 19)

| Phase | Deliverable | Reversible checkpoint |
|---|---|---|
| 1 — Pin old + install new (compat layer) | App still runs on old; new available | Remove new dep; back to status quo |
| 2 — Migrate modules incrementally | % of modules on new framework | Per-module revert possible |
| 3 — Cutover entrypoint | App now boots on new framework | Revert entrypoint; modules still compat |
| 4 — Remove compat layer | Old framework dep removed | Final (or pin again, expensive) |

## Pattern 5 — Vendor switch (e.g. logging SaaS)

| Phase | Deliverable | Reversible checkpoint |
|---|---|---|
| 1 — Procure + integrate new vendor | New vendor accepts events alongside old | Disable new emitter |
| 2 — Dual-emit | Events go to both vendors; alerts in old | Stop dual-emit |
| 3 — Migrate alerts | Alerts now fire from new vendor | Re-enable old alerts |
| 4 — Verify dashboards | Dashboards on new vendor at parity | Old still works |
| 5 — Decommission old vendor | Old vendor contract ended | Final |

## Common discipline across patterns

1. Every phase has a reversible checkpoint *or* it's explicitly
   marked non-reversible with the cost.
2. Phases that produce contracts (API, schema) include the lock
   moment + downstream notification.
3. Test plans ship with each phase; don't defer to a "stabilisation"
   period.
4. Each phase has a named owner (team or individual).

## See also

- [`non-reversibility-traps.md`](non-reversibility-traps.md) — changes
  that *look* reversible but aren't.
- [`rollback-procedure-patterns.md`](rollback-procedure-patterns.md) — verbatim
  rollback procedures per pattern.
