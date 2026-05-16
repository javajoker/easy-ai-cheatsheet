# DB Major Cutover Checklist

Database major version upgrades have a **write-cutover point**
past which rollback means data loss. This checklist is the
discipline that prevents premature cutover.

> **Treat this cutover like a one-way door.** The decision
> authority approves the cutover separately from approving the
> overall upgrade.

## Pre-cutover (reversible)

### Provision

- [ ] New DB instance at target version provisioned via IaC.
- [ ] Network access from app tier verified (security groups,
      firewall rules).
- [ ] TLS certs configured; connection string tested.
- [ ] Resource sizing matches or exceeds old DB.

### Replicate

- [ ] Replication configured (logical or physical, per project).
- [ ] Initial sync complete.
- [ ] Replication lag < 1s sustained for 24h.
- [ ] Disk space adequate on new DB (data + indexes + WAL).

### Verify against new (read-only)

- [ ] App connection-string pointing at new DB (read-only).
- [ ] Sample queries succeed.
- [ ] Query plans verified (extensions, settings — `EXPLAIN
      ANALYZE` on top 10 queries).
- [ ] Performance baseline measured (latency, throughput).

### Pre-cutover gates

- [ ] Backup of old DB taken in last 1h (for emergency restore).
- [ ] On-call engineer aware + available.
- [ ] Status page maintenance window scheduled (if customer-visible).
- [ ] Cutover window outside freeze windows from `devops-release-management`.
- [ ] Cutover decision approved by named decision authority (separately
      from upgrade approval).
- [ ] Rollback decision-maker named for the cutover window.

---

## Cutover (the irreversible step)

### Sequence

1. **Pause writes briefly** (typically <60s).

   ```bash
   # Application-side: stop new requests at LB
   # OR: pg_hba.conf editing to deny writes
   ```

2. **Verify replication caught up.**

   ```sql
   -- On new DB:
   SELECT pg_last_wal_replay_lsn(), pg_last_wal_receive_lsn();
   -- These must be equal
   ```

3. **Switch connection string** in secrets manager / config.

   ```bash
   aws secretsmanager update-secret --secret-id db-conn \
     --secret-string "<new connection string>"
   # OR
   kubectl set env deployment/app DB_HOST=<new-host>
   ```

4. **Restart application** (or trigger graceful reconnect).

5. **Resume writes.**

6. **Verify writes landing on new DB.**

   ```sql
   -- Verify recent write timestamps on new DB
   SELECT max(updated_at) FROM <busy_table>;
   ```

### Cutover gates

- [ ] All steps 1–6 completed within window.
- [ ] Sample queries succeed on new DB post-cutover.
- [ ] Error rate dashboard remains within threshold.

**If any gate fails before resuming writes**, abort cutover and
keep old DB authoritative. **After writes resume on new DB, the
cutover is one-way.**

---

## Post-cutover (forward-only)

### Monitor

- [ ] First 1h: dashboard watch; on-call engineer ready.
- [ ] 24h: full traffic on new DB; metrics within target.
- [ ] 72h: extended soak; performance vs. baseline confirmed.

### Keep old DB

- [ ] Old DB kept read-only and accessible.
- [ ] Retention: typically **7 days** for emergency data lookup.

### Decommission

- [ ] After retention window: old DB decommissioned.
- [ ] Final backup of old DB taken before decommission.
- [ ] Decommission documented in cleanup phase.

---

## Rollback considerations

**Before the cutover** — full rollback to old DB without data loss
(replication is still running; new DB has nothing not also in old).

**After the cutover** — rollback options:

| Option | Cost |
|---|---|
| (a) Reverse replicate new → old + cut back | Requires reverse replication setup *before* cutover; data written post-cutover preserved |
| (b) Restore old DB from pre-cutover backup | Data written post-cutover is **lost** |
| (c) Manual data extraction from new DB + replay on old | Hours of work; data loss for in-flight transactions |

**Option (a) is the only no-data-loss path; set it up pre-cutover
or accept that rollback = data loss.**

---

## Communication

| Audience | Channel | When |
|---|---|---|
| Engineering | `#deploys` | At cutover start + end |
| On-call | PagerDuty | Pre-armed for the window |
| Customers (if maintenance window) | Status page | T-7d, T-1d, T-1h, start, end |
| Internal stakeholders | Email | T-1d |

---

## Postmortem

- **Always** for SEV1 issues during the cutover.
- **Recommended** for clean cutovers too (capture lessons for next
  major upgrade — they recur every 1–3 years per DB).
