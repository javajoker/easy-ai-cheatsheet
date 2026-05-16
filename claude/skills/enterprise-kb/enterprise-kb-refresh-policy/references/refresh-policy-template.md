# Enterprise KB Refresh Policy

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Status:** active | draft | superseded
**Next annual review:** YYYY-MM-DD

---

## Staleness rules per entity type

| Domain | Sub-type | Staleness rule | Why |
|---|---|---|---|
| products | shipped | Per release; mandatory quarterly review | Features change per release |
| products | sunset | Updated once at sunset; locked | Historical record |
| teams | * | Per quarter; mandatory at org changes | Org structure shifts |
| decisions | architectural | 6 months default; re-review at related arch changes | Architectural context evolves |
| decisions | strategic | 6 months default; re-review per leadership change | Strategy changes with leadership |
| decisions | compliance | Per regulatory change | Continuous |
| terminology | * | Ongoing (linked to cognitive-alignment library) | Terms evolve with usage |
| runbooks | incident | Per game-day rehearsal (quarterly); after every incident in the runbook's class | Drift is operationally dangerous |
| customers | enterprise | Per quarterly business review | Account state changes |
| partners | integration | Per integration health check | Integrations evolve / deprecate |

---

## Ownership

**Every canonical entity has a named owner** (from the entity
contract's `owner` field). The owner is responsible for:

- Periodic review per the staleness rule.
- Acknowledging refresh-due notifications.
- Updating or initiating sunset when appropriate.

### When an owner becomes unassignable

If an owner leaves the org / role no longer exists / entity no
longer aligns:

1. Entity → `unowned` status.
2. Governance authority notified.
3. **7-day window** to assign new owner.
4. If unassigned after 7 days → entity surfaces in next quarterly
   audit.
5. If quarterly audit doesn't resolve → auto-sunset.

---

## Refresh triggers

### Automatic

| Trigger | Scope | Cadence |
|---|---|---|
| CI on merge to mainline (per source) | Source-scoped re-merge | Per source commit |
| Scheduled staleness audit | Whole KB | Weekly / monthly / quarterly per project |
| Search index rebuild | Whole search index | After every merge |
| Sunset enforcement | Move qualifying entities to sunset | Monthly |
| Unowned entity governance | Surface unowned | Weekly |

### Manual

| Trigger | Scope | When |
|---|---|---|
| Post-launch refresh | New / changed entities related to the launch | After every product launch |
| Post-incident refresh | Affected runbooks + related entities | After SEV1 / SEV2 incidents |
| Post-arch-change refresh | Affected components + related decisions | After `arch-migration-plan` completion |
| Pre-audit refresh | Whole KB or specific compliance entities | Before external audits |
| Owner-initiated | Entities owned by requester | Anytime |

---

## Sunset policy

### Criteria (from `enterprise-kb-architecture`)

- Owner unassignable for 90 days after last owner left.
- No references in active artifacts for 12 months.
- Underlying subject decommissioned.
- Explicit retirement request.

### Soft sunset (default)

- `status: sunset` set in frontmatter.
- Banner displayed at top: *"Sunset on <date>. See <successor_id>
  for the current version."*
- Entity remains navigable + linked-from.
- Excluded from default search results (opt-in to include).

### Hard sunset (per-project configurable)

- Entity moved to `enterprise-kb/archive/<domain>/`.
- Original path returns redirect / pointer.
- Excluded from search by default.

**Never delete.** Audit trail preservation is non-negotiable.

---

## Successor pointers

When an entity sunsets and a successor exists:

- `successor_id` field in frontmatter.
- Successor entity gets `predecessors` list.
- Bi-directional navigation works both ways.

When no successor exists (genuinely retired, not replaced),
`successor_id: null` is the explicit acknowledgement.

---

## Automation

CI pipelines for the automatic triggers:

| Job | Cron / trigger | Action |
|---|---|---|
| Source-commit re-merge | per source PR merge | Trigger incremental merge for the source |
| Staleness audit | Weekly Mon 09:00 UTC | Scan canonical entities; emit owner notifications for stale items |
| Sunset enforcement | Monthly 1st 09:00 UTC | Apply sunset to qualifying entities |
| Unowned governance | Weekly Mon 09:00 UTC | Surface unowned entities to governance authority |
| Search index rebuild | After every merge | Trigger `enterprise-kb-search-index` rebuild |
| Annual policy review | Yearly | Refresh this document |

(See [`automation-cookbook.md`](automation-cookbook.md) for
implementation patterns.)

---

## Owner notification policy

Owners receive a single weekly digest, not per-entity pings:

> **Subject:** [KB] N entities you own are due for review
>
> Hi <owner>,
>
> The following N entities you own are past their staleness
> review window:
>
> - `<entity-id>` (last updated YYYY-MM-DD; rule: <staleness rule>)
> - ...
>
> To acknowledge as up-to-date: <link>
> To update: <edit link>
> To sunset: <sunset link>
>
> If unacknowledged within 30 days, entities will surface to the
> governance audit.

Aggregation avoids alert fatigue. Per-entity escalation only on
governance review.

---

## Governance review

### Quarterly

- Review unowned entities; assign or sunset.
- Review entities approaching sunset criteria.
- Review staleness coverage (% of entities reviewed in window).
- Review owner-notification responsiveness.

### Annual

- Policy review — adjust staleness rules per observed drift.
- Audit cadence review.

---

## Anti-patterns

- **Refresh-as-event.** Treating refresh as a project rather
  than steady process; cycles starve.
- **One cadence fits all.** Quarterly for everything → fast-
  moving entities get stale; stable entities get churn.
- **Delete on sunset.** Audit trail destroyed.
- **Owner-by-team.** "Engineering owns it" → owned by nobody.
- **Notification spam.** Daily notifications → owners ignore.
  Aggregate to weekly digests.
- **No auto-sunset for unowned.** Unowned entities linger forever;
  KB rots quietly.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial lock | <name> |
