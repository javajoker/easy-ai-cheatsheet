---
name: arch-breaking-change-comms
description: Produces internal and external communication artifacts for a breaking change — Slack and email announcements (internal), changelog entry, customer email, API docs deprecation banners, FAQ, and a sunset schedule for the old path with deprecation warnings → log warnings → error responses → removal timeline. Output is breaking-change-comms.md with audience-specific drafts ready to send + the sunset schedule rendered as a timeline. Use this skill when an architectural change will affect downstream consumers (internal teams, external customers, API users); or when the user says "draft the deprecation notice", "write the breaking-change announcement", "what's the sunset schedule for v1", "we need to communicate this API change". Pairs with arch-migration-plan (consumes the lock/sunset schedule), with arch-rollout-strategy (comms aligned with each rollout stage), with knowledge-curator agent (updates public KB / docs), with lifecycle-pilot agent (coordinates with launch comms if both happen in the same window), and with devops-incident-runbook (if a breaking change requires post-incident comms).
status: shipped
owner_agent: architecture-shepherd
---

# Arch Breaking Change Comms

Most *"we broke a customer"* failures are communication
failures, not engineering failures. This skill produces the
comms artifacts before the change ships, not after.

> **No silent breaking changes.** A change that breaks
> downstream consumers without a notification period is a
> process failure, regardless of how small the change is.

## Why this exists

Comms failures around breaking changes are predictable:

1. **No notification.** Change ships; customer integration
   breaks; customer learns from support ticket spike or social
   media; trust damaged.
2. **Insufficient runway.** "Heads up, this changes Monday."
   Customer has no time to migrate; they pushback; ship gets
   delayed.
3. **Mixed signals.** Engineering says "non-breaking"; product
   says "breaking but minor"; customer experiences breakage.
4. **No sunset plan.** Old version deprecated but never
   actually removed; both versions maintained forever; tech
   debt compounds.
5. **No escalation path.** Customer asks "this breaks our
   workflow; can we delay?" — nobody knows who decides.

This skill ships an opinionated comms framework: audience-
specific artifacts, runway aligned to change risk, sunset
schedule with mechanical warning escalation, escalation path
documented.

## When to fire

Fire when:

- An `arch-migration-plan` or `arch-dependency-upgrade` phase
  introduces a change visible to downstream consumers.
- The user says *"draft the deprecation notice"*, *"write the
  breaking-change announcement"*, *"what's the sunset
  schedule"*, *"we need to communicate this API change"*.
- A vulnerability fix requires a breaking change with
  disclosure timeline.

Do **not** fire when:

- The change is non-breaking (additive — new endpoint, new
  optional field).
- The change affects only internal-only consumers who can
  coordinate directly (still notify them, but a one-line
  Slack message often suffices).
- The user wants to communicate a *launch*, not a breaking
  change — that's `lifecycle-pilot` (GTM kit).

## Inputs

Required:

- Description of the breaking change.
- Target audience (internal teams / external customers / API
  consumers / SDK users).

Asked once (cap at 4):

1. **Severity.** Minor (workaround exists; minor refactor for
   consumers) / Medium (consumers need real change) / Major
   (consumers may break without migration).
2. **Sunset window.** How long old + new coexist before old
   is removed. Default depends on severity.
3. **External-comms required?** Public changelog, customer
   email, status page entry — or internal-only?
4. **Escalation authority.** Who decides if a customer
   requests an extension to the sunset.

## The opinionated comms framework

### Audience-specific artifacts

| Audience | Artifact | Purpose |
|---|---|---|
| Engineering org | Slack announcement + email | Awareness; align on schedule |
| Product / CS / Support | Internal brief | Pre-arm support for questions |
| External customers (general) | Changelog entry | Searchable record |
| External customers (impacted) | Personalised email | Direct heads-up; migration guide |
| API / SDK users | API docs deprecation banner | In-context warning |
| Public (security disclosures) | Security advisory + CVE | Compliance + reputation |

Not every change needs every artifact. Severity + audience
drives the subset.

### Runway by severity

| Severity | Default sunset window | Rationale |
|---|---|---|
| Minor | 30 days | Workaround exists; consumers can defer briefly |
| Medium | 90 days | Real consumer work needed; quarterly planning cycles |
| Major | 6–12 months | Major migration; annual planning; enterprise customers need long runway |
| Security (with active exploit) | 7–30 days | Risk of leaving the vuln > risk of breaking consumers; legal teams may set the window |

Customers may negotiate longer; the escalation authority
decides.

### Sunset escalation pattern

Old path goes through stages, each mechanically escalating:

| Stage | Old path behaviour | Duration | Notification |
|---|---|---|---|
| 1 — Soft deprecation | Works normally; deprecation banner in docs | Day 0 → 1/3 of window | Initial comms |
| 2 — Warn in response | Works normally; deprecation header in responses (e.g. `Deprecation: Sun, 01 Jun 2026 23:59:59 GMT`); log warning | 1/3 → 2/3 of window | Reminder comms; impacted customers contacted |
| 3 — Soft fail | Works for low-volume callers; returns 410 Gone for high-volume callers ("you should have migrated") | 2/3 → end of window | Final-week reminder |
| 4 — Removed | Returns 410 Gone with link to new endpoint | After window | Removal announcement |

This pattern gives mechanical pressure that escalates — silent
deprecation = nobody migrates until removal.

## The procedure

### Phase 1 — Anchor the change

Get a precise statement:

- **What** breaks. (API endpoint? Response shape? Behaviour?
  Required header? Auth method?)
- **Why** the change is happening (tied to the architectural
  reason from `arch-assessment`).
- **What replaces it.** (New endpoint? New auth method?
  Different default behaviour?)
- **Migration path.** (Step-by-step instructions consumers
  follow.)

Vague comms cause more breakage than the change itself.
Anchor with `cognitive-alignment` if there's any ambiguity.

### Phase 2 — Identify impacted consumers

- **Internal:** Which teams / services consume the affected
  surface? Query the consumer registry (or grep across known
  consumer repos).
- **External (customers):** Pull from API access logs — which
  API keys / OAuth clients call the affected endpoint?
  Frequency? Last call?
- **Public (SDKs / open-source consumers):** Likely cannot
  enumerate; treat as broad audience.

For external impacted, the personalised email goes to *them
specifically*; this is far more effective than blast
announcements.

### Phase 3 — Set the sunset schedule

Per severity defaults; adjust for context:

- **Faster** if security risk dominates.
- **Slower** if customer base includes large enterprises with
  long change-management cycles.
- **Aligned to consumer rhythms** (avoid sunsetting during
  customer-side freeze windows like end-of-quarter).

Document the schedule with explicit dates for each stage
transition.

### Phase 4 — Draft each audience artifact

Use the templates in
[references/comms-templates/](references/comms-templates/).

Per audience:

- **Internal Slack:** brief; links to full plan.
- **Internal email:** more detail; includes migration support
  contact.
- **Changelog entry:** dated; categorised; links to migration
  guide.
- **Customer email (impacted):** personalised; specific
  endpoint usage data; migration steps; offer support.
- **API docs deprecation banner:** in-context warning at every
  affected endpoint.
- **FAQ:** anticipated questions with answers.

Drafts go to the user for review before sending.

### Phase 5 — Schedule the comms cadence

| Moment | Comms |
|---|---|
| Day 0 (announcement) | Internal Slack + email; Changelog entry; Customer emails; API docs banner |
| Day 1 (start of stage 2) | Reminder Slack; warn-in-response shipped |
| Day 2/3 of window | Reminder customer email; FAQ updated based on questions received |
| Last week | Final-week reminder; soft-fail shipped for high-volume callers |
| Removal day | Removal announcement; old endpoints return 410 |
| Post-removal | Confirmation; monitor support volume for unexpected breakage |

### Phase 6 — Document the escalation path

Customers may request:

- Sunset extension.
- Different migration path.
- Workaround / compatibility layer.

Document who decides:

- **Engineering scope** (e.g. "can we extend the warn-in-
  response stage by 30 days"): tech lead.
- **Product scope** (e.g. "this affects 3 enterprise
  customers; can we delay"): product owner.
- **Business scope** (e.g. "key customer threatens to churn"):
  named business authority.

Without explicit escalation paths, customer requests bounce
between teams.

### Phase 7 — Emit the comms plan

Write `breaking-change-comms.md` using
[references/breaking-change-comms-template.md](references/breaking-change-comms-template.md).

After writing:

1. Surface drafts to user for review.
2. Coordinate with `lifecycle-pilot` if there's a launch in
   the same window (don't blast competing comms).
3. Coordinate with `knowledge-curator` if public docs need
   updates beyond the deprecation banner.
4. Hand the sunset schedule back to `arch-migration-plan`
   (the schedule becomes part of the migration timeline).
5. Persist as `type: project` memory (`breaking_change_<topic>_v1`).

### Phase 8 — Execute + monitor

The skill doesn't *send* — humans send. But the skill provides:

- A checklist of who-sends-what-when.
- Templates copy-paste-ready.
- A monitoring guide (support ticket volume, customer
  responses, migration progress).

If migration progress lags (e.g. <50% of impacted consumers
migrated at the warn-in-response stage), the schedule may
need re-planning.

## Anti-patterns

- **Single-channel announcement.** Email only / Slack only —
  some customers miss it. Multi-channel.
- **"Heads up, this changes next week."** Insufficient runway
  causes pushback and damages trust.
- **No personalised email to impacted customers.** Blast
  announcements are easy to miss; personalised is effective.
- **Silent removal.** Path was deprecated; removal day comes
  with no final reminder. Reminder is non-negotiable.
- **No sunset.** Path deprecated but never removed → infinite
  support cost.
- **Vague migration path.** "Use the new endpoint" without
  step-by-step instructions. Consumers will get it wrong;
  blame goes both ways.
- **Negotiating extensions case-by-case without policy.** The
  escalation path is documented; same rules for everyone.
- **No monitoring of migration progress.** Without tracking,
  the sunset arrives and most consumers are unmigrated;
  emergency extension required.

## Companion skills

- `arch-migration-plan` — sunset schedule integrates here.
- `arch-rollout-strategy` — comms align with rollout stages.
- `arch-dependency-upgrade` — if upgrade is externally visible.
- `lifecycle-pilot` — coordinate with launch comms.
- `knowledge-curator` — public docs / KB updates.
- `devops-incident-runbook` — if a breaking change requires
  incident comms.
- `cognitive-alignment` — anchor the change description.

## Reference files

- [references/breaking-change-comms-template.md](references/breaking-change-comms-template.md) —
  canonical output document.
- [references/comms-templates/](references/comms-templates/) —
  per-audience template starters (internal Slack, internal
  email, changelog entry, customer email, API docs banner,
  FAQ).
- `references/sunset-schedule-examples.md` — pre-worked sunset
  schedules per severity.
- `references/migration-guide-template.md` — template for the
  step-by-step migration instructions consumers follow.
