# Non-Reversibility Traps

Changes that *look* reversible but aren't, or are reversible only
at high cost. Each trap surfaces a phase that needs to be split or
explicitly acknowledged as one-way.

## Trap 1 — DB schema column drop

**Looks like:** "Just drop the column; we don't need it anymore."

**Trap:** Dropping a column with data is unrecoverable without
backup restore. Rollback means data loss.

**Split into:**

1. Stop writing to the column.
2. Stop reading from the column.
3. (Wait several releases; verify no consumers.)
4. Drop the column.

Each step is independently reversible.

## Trap 2 — Data migration with write cutover

**Looks like:** "Migrate users table to new shape; switch reads
and writes."

**Trap:** Once writes go to new shape, data written after cutover
isn't in old shape. Rolling back means losing that data (or doing
a reverse-migration).

**Split into:**

1. Dual-write (writes to both old and new shape).
2. Backfill (catch up historical data into new shape).
3. Verify dual-write parity.
4. Cut reads over.
5. Cut writes over (irreversible from here — acknowledge
   explicitly).
6. Remove old shape.

## Trap 3 — API endpoint removal

**Looks like:** "We sunset v1, just delete the endpoint."

**Trap:** Consumers still on v1 break instantly. Rolling back the
delete doesn't undo their code shipping with v2 calls.

**Split into:**

1. Deprecation banner in docs + response header.
2. Warn-in-response (log warning; still works).
3. Soft-fail for high-volume callers (410 Gone for them; works for
   others).
4. Removal.

Coordinated with `arch-breaking-change-comms`.

## Trap 4 — Configuration default change

**Looks like:** "Flip the default config value."

**Trap:** Consumers depending on the old default break silently
on next restart. Rollback restores the default but doesn't undo
the operational chaos.

**Split into:**

1. Add new config option (with old default).
2. Migrate every consumer to set the new value explicitly.
3. Change the default (no operational impact since everyone is
   explicit).
4. Remove the old config option.

## Trap 5 — Event bus / queue topic deletion

**Looks like:** "Delete the old topic; everything's on the new one."

**Trap:** Replay isn't possible after deletion; in-flight messages
on the old topic are lost.

**Split into:**

1. Stop producers writing to old topic.
2. Drain consumers (process remaining messages).
3. Verify drain complete.
4. Delete topic.

## Trap 6 — DNS / load balancer cutover

**Looks like:** "Point DNS at new endpoint."

**Trap:** DNS TTL means caching can persist for hours/days.
Cached resolutions hit the old endpoint after rollback should
have happened.

**Split into:**

1. Lower TTL well in advance of the cutover.
2. Wait for old TTL to expire across consumers.
3. Cutover.
4. Verify no traffic to old endpoint.
5. Decommission old endpoint.

## Trap 7 — Stateful migration of long-running connections

**Looks like:** "Migrate websocket / SSE / gRPC streaming
connections to new server."

**Trap:** Existing connections hold state; reconnect means session
loss. Rolling back doesn't restore lost sessions.

**Split into:**

1. New server accepts new connections.
2. Wait for old connections to drain naturally (or force
   reconnect with explicit migration handling).
3. Decommission old server.

## Trap 8 — Cryptographic key rotation

**Looks like:** "Rotate the signing key."

**Trap:** Tokens signed with the old key fail validation
immediately after rotation. Rolling back doesn't make those
already-issued tokens valid again.

**Split into:**

1. Add new key alongside old (validate against both).
2. Issue new tokens with new key.
3. Wait for old-token expiry.
4. Remove old key.

## Trap 9 — Removing a feature flag

**Looks like:** "We've fully rolled out feature X; remove the flag."

**Trap:** If issues surface post-removal, you can't quickly
disable. Rolling back requires a code deploy.

**Defer the flag removal** to a separate phase, after the feature
is verified stable for ≥1 release cycle.

## Detection discipline

When drafting a phase, ask:

1. If this phase ships and we discover a problem next week, what
   reverses the change?
2. If reversal involves anything more than a deploy + config
   flip, the phase is non-reversible or partially reversible.
3. Split the phase until each piece passes the reversibility test
   — OR explicitly acknowledge non-reversibility and require named
   approval at that phase boundary.

## See also

- [`decomposition-patterns.md`](decomposition-patterns.md) — patterns
  that pre-split common shapes.
- [`rollback-procedure-patterns.md`](rollback-procedure-patterns.md) — verbatim
  rollbacks for reversible phases.
