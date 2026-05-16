# Notification Templates — owner / governance digests

Email + Slack templates that aggregate notifications. The
discipline: one weekly digest per owner, not per-entity pings.

## Owner — weekly staleness digest (email)

```
From: kb-bot@example.com
Subject: [KB] {N} entities you own are due for review

Hi {owner_first_name},

The following {N} canonical knowledge-base entities you own are
past their staleness review window:

  • {entity_id_1} — last updated {updated_1} ({days_since_1} days ago)
    Domain: {domain_1} / {type_1}
    Edit: {edit_url_1}

  • {entity_id_2} — last updated {updated_2} ({days_since_2} days ago)
    Domain: {domain_2} / {type_2}
    Edit: {edit_url_2}

  ... ({N - 2} more, see full list at {digest_url})

Quick actions:

  → Acknowledge as up-to-date (one-click for entities that need
    no content change): {ack_url}
  → Edit in browser: {edit_url}
  → Mark for sunset: {sunset_url}

If you're no longer the right owner, please reassign or reply to
this email.

— Enterprise KB

—
You're receiving this because you're listed as owner of one or
more canonical entities. Aggregated weekly to avoid spam.
Cadence + filter: {preferences_url}
```

## Owner — Slack DM (alternative to email)

```
:books: *KB digest* — you own {N} entities due for review

Quick actions: <{ack_url}|Ack all> | <{digest_url}|See list>

Top 5:
• `{entity_id_1}` — {domain_1}/{type_1} — {days_since_1}d stale
• `{entity_id_2}` — {domain_2}/{type_2} — {days_since_2}d stale
• ...

Full list: <{digest_url}|→ digest>
```

## Governance — unowned entities (email, weekly)

```
From: kb-bot@example.com
To: governance-authority@example.com
Subject: [KB Governance] {N} unowned entities need attention

The following entities have been unowned for >7 days and require
governance action:

  • {entity_id} — previously owned by {previous_owner} (left
    {days_since} days ago)
    Domain: {domain}/{type}
    Last updated: {updated}
    References from: {reference_count} active artifacts

    Options:
    - Reassign owner: {reassign_url}
    - Mark for sunset: {sunset_url}
    - Defer to quarterly review: {defer_url}

If no action within 30 days, entity surfaces in next quarterly
audit.

— Enterprise KB
```

## Governance — quarterly audit summary (email)

```
Subject: [KB Quarterly Audit] Summary for Q{N} {YYYY}

Knowledge base health summary for Q{N} {YYYY}:

CANONICAL ENTITIES
  Total: {total}
  Active: {active}
  Sunset (this quarter): {sunset_this_q}
  Promoted (this quarter): {promoted_this_q}

STALENESS
  Within window: {fresh} ({pct_fresh}%)
  Approaching expiry: {warning} ({pct_warning}%)
  Past expiry: {stale} ({pct_stale}%)

  Target: <5% past expiry. Current: {pct_stale}%
  Status: {on-track | needs attention | concerning}

OWNERSHIP
  Owned: {owned} ({pct_owned}%)
  Unowned >7d: {unowned}
  Unowned >30d: {long_unowned} — surfaced this audit

ACCESS PATTERNS
  Most-retrieved: {top_5_entities}
  Most-edited: {top_5_edited}
  Anomalies detected: {anomaly_count}

ACTION ITEMS
  • Sunset {N} entities meeting criteria (see attached)
  • Reassign {M} unowned entities (see attached)
  • Re-review staleness rules for {domain} (drift: {drift_pct}%)

Next quarterly audit: {next_audit_date}

Full report: {full_report_url}

— Enterprise KB Governance Bot
```

## On-action confirmation (transactional)

After an owner clicks `/ack` for an entity:

```
:white_check_mark: Acknowledged `{entity_id}` as up-to-date.

Updated timestamp: {today}
Next review due: {next_due}
```

After a sunset is applied:

```
:wave: Sunset applied to `{entity_id}`.

Sunset date: {today}
Successor: {successor_id or "none"}
Audit trail: <{commit_url}|commit>
```

## Anti-patterns

- **Per-entity emails.** 100 stale entities → 100 emails →
  owners stop reading.
- **Generic subject lines.** "KB update" — no urgency, no
  signal. Use the count.
- **No quick-action buttons.** Owners want to acknowledge in one
  click, not click-through-to-edit-form.
- **No reassign path.** Owners who shouldn't be owners need an
  easy out.
- **Too-frequent cadence.** Daily emails → fatigue. Weekly is
  the right cadence for steady-state.

## Notification preferences

Per-owner overrides (configured in user profile):

```yaml
notifications:
  email: weekly       # weekly | daily | never
  slack: weekly       # weekly | daily | never
  digest_day: monday  # day of week for weekly
  digest_hour: 9      # local timezone
  filter:
    domains: [products, decisions]  # only these domains
    include_warning: true            # include approaching-expiry
    include_unowned: false           # skip unowned alerts
```

Default is weekly email at Monday 09:00 local time, all domains,
warnings included.
