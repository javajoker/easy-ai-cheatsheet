---
name: enterprise-kb-refresh-policy
description: Defines per-entity-type staleness rules, named owners per canonical entity, refresh cadence (automatic triggers + manual triggers), sunset policy (read-only with successor pointer; never delete), and the governance procedure for stale-without-owner entities. Without a refresh policy, a KB is a frozen snapshot, not a living knowledge resource. Output is enterprise-kb/refresh-policy.md plus automation hooks (CI jobs / scheduled checks) that surface stale entities to owners. Use this skill after enterprise-kb-architecture is locked and enterprise-kb-merge has produced a populated canonical layer; or when the user says "how do we keep this fresh", "set up the refresh schedule", "define ownership", "when do entities expire". Pairs with enterprise-kb-architecture (entity contract includes owner field — required), with enterprise-kb-merge (refresh re-runs merge), with enterprise-kb-search-index (refresh triggers re-indexing), with memory-ontology (ownership decisions recorded), and with knowledge-curator agent governance (this skill's outputs feed governance.md).
status: shipped
owner_agent: knowledge-curator
---

# Enterprise KB Refresh Policy

Phase 3 of the `knowledge-curator` agent. Without a refresh
policy, the KB is a snapshot — useful for the week it was
written; misleading six months later.

> **Staleness without ownership is decay.** A canonical entity
> without a named owner becomes nobody's job; it goes stale
> silently and the KB loses signal. Ownership is non-negotiable
> at promotion; staleness without owner triggers governance.

## Why this exists

Refresh failures are predictable:

1. **Snapshot KB.** Built once, never updated. Six months in,
   half the entries are outdated; consumers learn not to trust
   the KB.
2. **Refresh on impulse.** Random spurts of update activity;
   no consistent quality.
3. **No staleness signal.** Entries don't display "last
   verified" prominently; consumers can't tell what's current.
4. **No sunset.** Decommissioned products still surface in
   retrieval; signal-to-noise degrades.
5. **No owner for stale entities.** Stale entries persist
   because nobody is on the hook to update them.
6. **Refresh = full re-merge.** No incremental refresh —
   re-merge takes hours; team avoids running it; KB ages.

This skill enforces per-type staleness rules, named ownership,
automated triggers, manual triggers, and governance for the
edge cases.

## When to fire

Fire when:

- The canonical layer has been populated by `enterprise-kb-
  merge` and needs an ongoing maintenance plan.
- The user says *"how do we keep this fresh"*, *"set up the
  refresh schedule"*, *"define ownership"*, *"when do entities
  expire"*.
- Existing refresh policy needs revision (rare; annual
  review).

Do **not** fire when:

- The KB hasn't been built yet (architecture + merge first).
- The team wants to do one specific refresh (just run
  `enterprise-kb-merge` with incremental scope).

## Inputs

Required:

- `enterprise-kb/ARCHITECTURE.md` — entity contract + sunset
  criteria.
- Populated `enterprise-kb/entities/` (at least one merge has
  run).

Asked once (cap at 3):

1. **Cadence preference.** Aggressive (refresh weekly,
   maintenance overhead higher) / balanced (refresh monthly,
   default) / minimal (refresh quarterly, KB drifts more).
2. **Owner assignment authority.** Who can assign ownership
   when an entity's current owner becomes unassignable?
   (Default: governance committee from
   `knowledge-curator/governance.md`.)
3. **Sunset enforcement.** Soft (mark sunset but keep
   navigable) / hard (move sunset entities to archive
   directory).

## The opinionated refresh policy

### Per-entity-type staleness rules

Default rules by domain (configurable per project):

| Domain | Staleness rule | Why |
|---|---|---|
| `products/shipped` | Per release; mandatory review per quarterly product review | Features change with releases |
| `products/sunset` | Updated once at sunset; then locked | Historical record |
| `teams` | Per quarter; mandatory review at org changes | Org structure shifts |
| `decisions/architectural` | 6 months default; re-review at related arch changes | Architectural context evolves |
| `decisions/strategic` | 6 months default; re-review per leadership change | Strategy changes with leadership |
| `decisions/compliance` | Per regulatory change | Compliance evolves continuously |
| `terminology` | Ongoing (linked to cognitive-alignment library); reviewed at quarterly KB audit | Terms evolve with usage |
| `runbooks/incident` | Per game-day rehearsal (quarterly); after every incident in the runbook's class | Drift is operationally dangerous |
| `customers/enterprise` | Per quarterly business review | Account state changes |
| `partners/integration` | Per integration health check | Integrations evolve / deprecate |

**Each canonical entity displays `updated:` prominently** so
consumers can assess freshness at a glance.

### Owner assignment

At promotion (via `enterprise-kb-merge`), an entity gets a
named owner. The owner is responsible for:

- Periodic review per the entity-type staleness rule.
- Acknowledging refresh-due notifications.
- Updating or initiating sunset when appropriate.

When an owner becomes unassignable (left the org; role no
longer exists; no longer relevant to the entity), the
governance procedure kicks in:

1. The entity goes into `unowned` status.
2. Governance authority gets a notification (default 7-day
   window to assign new owner).
3. If unassigned after 7 days → entity surfaces in the next
   quarterly KB audit for explicit decision (new owner /
   sunset / convert to per-project-only).

### Refresh triggers

**Automatic triggers:**

| Trigger | Scope | Frequency |
|---|---|---|
| Per-source CI on merge to mainline | Source-scoped re-merge | Per source commit |
| Scheduled staleness audit | Whole KB; surfaces stale entities to owners | Per cadence (weekly / monthly / quarterly) |
| Search index rebuild | Whole search index | After every merge |
| Sunset enforcement | Move qualifying entities to sunset status | Monthly |
| Unowned entity governance | Surface unowned entities | Weekly |

**Manual triggers:**

| Trigger | Scope | When |
|---|---|---|
| Post-launch refresh | New / changed entities related to the launch | After every product launch |
| Post-incident refresh | Affected runbooks + related entities | After SEV1 / SEV2 incidents |
| Post-architecture-change refresh | Affected components + related decisions | After arch-migration-plan completion |
| Pre-audit refresh | Whole KB or specific compliance-relevant entities | Before external audits |
| Ad-hoc owner-initiated | Entities owned by requester | Anytime |

### Sunset policy

Sunset criteria (from `enterprise-kb-architecture`):

- Owner unassignable for 90 days.
- No references in active artifacts for 12 months.
- Underlying subject decommissioned.
- Explicit retirement request.

When an entity meets criteria:

1. **Soft sunset (default):**
   - `status: sunset` set in frontmatter.
   - Banner displayed at top of entity: *"Sunset on <date>.
     See <successor_id> for the current version."*
   - Entity remains navigable + linked-from.
   - Excluded from default search results (opt-in to include).

2. **Hard sunset (configurable per project):**
   - Entity moved to `enterprise-kb/archive/<domain>/`.
   - Original path returns a redirect / pointer to the
     archive location.
   - Excluded from search by default.

**Never delete.** Audit trail preservation is non-negotiable.

### Successor pointers

When an entity sunsets and a successor exists:

- `successor_id` field in frontmatter.
- Successor entity gets a `predecessors` list in its
  frontmatter.
- Bi-directional navigation works both ways.

When no successor exists (genuinely retired, not replaced),
`successor_id: null` is the explicit acknowledgement.

### Governance — unowned entities

The hardest case. An entity exists, has value, but no current
owner. The governance procedure:

```
1. Entity flagged unowned (owner field empty or pointing at
   inactive principal).
2. Notification → governance authority (default: knowledge-
   curator agent's named human authority).
3. 7-day window: assign new owner OR initiate sunset.
4. If 7 days pass with no action → entity surfaces in next
   quarterly KB audit.
5. Quarterly audit: explicit decision (new owner / sunset / 
   demote to per-project-only).
6. No action after audit → entity auto-sunset.
```

Auto-sunset is the safety valve — unowned entities can't
linger forever, but the procedure gives ample opportunity for
human assignment.

## The procedure

### Phase 1 — Read architecture + canonical state

Open `ARCHITECTURE.md`. Pull entity contract + sunset criteria.

Inventory current canonical entities; bucket by domain;
identify ownership coverage (% of entities with named owners).

If ownership coverage is <95%, **fix this first** — the policy
relies on owners. Run an ownership-assignment pass before
writing the policy.

### Phase 2 — Decide cadence per type

Default rules adapt per project context. Adjust where needed:

- Fast-moving products → tighter cadence.
- Stable / sunset products → looser cadence.
- Compliance-regulated entities → cadence per regulatory cycle.

### Phase 3 — Decide sunset enforcement

Soft (default) or hard. Document per project.

### Phase 4 — Wire automation

Implement the automatic triggers as scheduled jobs:

- **CI-time** — runs per source commit (re-merge incremental
  changes from that source).
- **Cron** (weekly / monthly / quarterly) — staleness audit
  emits a report; owners get pings.
- **Post-merge** — search index rebuild triggered.
- **Daily** — sunset enforcement check.

The automation is typically GitHub Actions / GitLab CI /
scheduled cloud function, depending on hosting.

### Phase 5 — Document the policy

Write `enterprise-kb/refresh-policy.md` using
[references/refresh-policy-template.md](references/refresh-policy-template.md).

The policy is canonical; persisted as `type: project` memory
(`kb_refresh_policy_v1`).

### Phase 6 — Run the first refresh + report

Execute one full cycle of the policy:

- Staleness audit on whole KB.
- Owner notification dispatch.
- Sunset enforcement on qualifying entities.
- Search index rebuild.

Capture the report:

- N entities found stale; M acknowledged; K acted on.
- L entities sunset.
- Search index size + freshness.

This first report is the baseline; subsequent reports compare.

### Phase 7 — Hand-off

- `enterprise-kb-merge` runs at each refresh trigger.
- `enterprise-kb-search-index` re-indexes after merge.
- `enterprise-kb-access-control` re-verifies classification
  on updated entities.
- `knowledge-curator/governance.md` references this policy.

### Phase 8 — Watch for policy-failure triggers

The policy is failing when:

- Staleness coverage drops (% of entities reviewed in their
  cadence window).
- Unowned-entity count grows.
- Owners ignore notifications (alert fatigue).
- Refresh runs but content quality doesn't improve.

When any signal degrades, audit the policy (cadence too
aggressive? Ownership not really assigned? Notifications going
nowhere?).

## Anti-patterns

- **Refresh-as-event.** Refresh treated as a project rather
  than a steady process. Cycles starve.
- **One-cadence-fits-all.** Quarterly review for everything
  → fast-moving entities get stale; stable entities get
  unnecessary churn.
- **Delete on sunset.** Audit trail destroyed; future
  consumers can't see what existed.
- **No staleness display.** Consumers can't tell if an entity
  is current; they don't trust the KB.
- **Owner-by-team.** "Owned by engineering" → owned by nobody.
  Named individuals or named-roles-with-rotation.
- **Notification spam.** Daily notifications about every stale
  entity → owners ignore. Aggregate.
- **No auto-sunset for unowned.** Unowned entities linger
  forever; KB rots quietly.

## Companion skills

- `enterprise-kb-architecture` — owner field + sunset
  criteria.
- `enterprise-kb-merge` — re-runs at refresh triggers.
- `enterprise-kb-search-index` — re-indexes after refresh.
- `enterprise-kb-access-control` — re-verifies classification.
- `memory-ontology` — persists policy + ownership decisions.
- `requirement-audit` — periodic policy compliance audit.

## Reference files

- [references/refresh-policy-template.md](references/refresh-policy-template.md) —
  canonical policy document.
- `references/staleness-rules-catalogue.md` — per-entity-type
  staleness rules with adaptation guidance.
- `references/automation-cookbook.md` — CI / cron / cloud-
  function patterns for the automatic triggers.
- `references/notification-templates.md` — owner-notification
  templates that aggregate to avoid spam.
