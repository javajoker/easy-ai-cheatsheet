# Sunset Schedule Examples

Pre-worked sunset schedules per severity. The mechanical
escalation (deprecation → warn → soft-fail → removed) is the
same; only durations differ.

## Severity rubric

| Severity | Definition | Default window |
|---|---|---|
| Minor | Workaround exists; consumers can defer briefly | 30 days |
| Medium | Real consumer work needed | 90 days |
| Major | Major migration; enterprise customers need long runway | 6–12 months |
| Security (active exploit) | Risk of leaving vuln > risk of breaking consumers | 7–30 days |

## Example 1 — Minor sunset (30 days)

| Day | Stage | Action |
|---|---|---|
| 0 | Soft deprecation | Banner in docs; announcement comms sent |
| 10 | Warn in response | `Deprecation` header in responses; log warnings |
| 22 | Final reminder | Reminder email to impacted customers |
| 25 | Soft-fail (high-volume) | High-volume callers (>100 req/hr) get 410 |
| 30 | Removed | All calls return 410 |

## Example 2 — Medium sunset (90 days)

| Day | Stage | Action |
|---|---|---|
| 0 | Soft deprecation | Banner; initial comms; customer emails to impacted |
| 30 | Warn in response | Deprecation header; log warnings |
| 60 | Reminder + check progress | Reminder email; check migration progress (% migrated) |
| 75 | Soft-fail (high-volume) | High-volume callers get 410 |
| 85 | Final-week reminder | Email + status page banner |
| 90 | Removed | All calls return 410 |

## Example 3 — Major sunset (12 months)

| Month | Stage | Action |
|---|---|---|
| 0 | Soft deprecation | Banner; announcement; customer emails; migration guide published |
| 3 | First reminder | Email + Slack to impacted customers; check progress |
| 6 | Warn in response | Deprecation header begins; log warnings |
| 9 | Soft-fail (high-volume) | Tiered: top-10% volume callers get 410 |
| 10 | Soft-fail (mid-volume) | Mid-volume callers get 410 |
| 11 | Final-month reminder | Multi-channel: email, Slack, status page, sales rep outreach |
| 11.5 | Soft-fail (all) | All callers get 410 |
| 12 | Removed | API surface deleted from code |

## Example 4 — Security sunset (7 days, active exploit)

| Day | Stage | Action |
|---|---|---|
| 0 | Emergency announcement | Security advisory published; customer emails to all impacted; CVE filed |
| 0 | Mitigation guidance | Migration steps available; workaround if any |
| 1 | Warn in response | Deprecation header begins immediately |
| 3 | Soft-fail (high-volume) | High-volume callers get 410 |
| 5 | Soft-fail (all) | All callers get 410 |
| 7 | Removed | Code path deleted |

Documented acceptance of accelerated breakage from named
security authority required.

## Example 5 — Regulatory-driven sunset

Regulator mandates deprecation by date X. Work backward from X.

| Working backward from X | Stage |
|---|---|
| X − 90d | Soft deprecation; legal review of comms |
| X − 60d | Warn in response |
| X − 30d | Reminder + customer outreach for laggards |
| X − 14d | Soft-fail (high-volume) |
| X − 7d | Soft-fail (mid-volume) |
| X | Removed |

The schedule **cannot slip past X** — regulatory deadline is
absolute.

## When to deviate from defaults

Faster than default:

- Security with active exploit.
- Vendor-mandated change with fixed external deadline.

Slower than default:

- Enterprise customers with long change-management cycles
  (often quarterly planning).
- Compliance windows where customer is in regulator review.
- High-volume integration where customer's team is in transition.

Slips are renegotiated with the named decision authority, not
unilaterally extended. Each extension documented in the comms
plan's change log.

## Anti-patterns

- **Silent removal.** Skipping stages because "nobody's using it
  anyway" — until someone is.
- **No warn-in-response.** Customers don't read your changelog;
  they read their logs. Make it land where they look.
- **All-at-once soft-fail.** Soft-failing 100% of callers in one
  step is just removal with extra steps. Tier the soft-fail.
- **Extension by exception.** Granting one customer an extension
  without policy → others ask too; the schedule becomes fiction.
  Either everyone gets the extension or no one does.
