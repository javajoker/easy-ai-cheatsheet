# Breaking Change Comms — <change>

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Severity:** minor | medium | major | security
**Sunset window:** 30 days | 90 days | 6-12 months | per security policy
**Status:** active | draft | superseded

---

## Anchor

**What breaks.** <one paragraph; precise — endpoint? response shape?
behaviour? required header? auth method?>

**Why.** <one paragraph; tied to the architectural reason from
arch-assessment>

**What replaces it.** <new endpoint? new auth method? different
default behaviour?>

**Migration path.** See [migration-guide-template.md](migration-guide-template.md).

---

## Impacted consumers

### Internal

- <team> — <how they're affected>
- <team> — <…>

### External — impacted

| Customer / consumer | Endpoint usage in last 30d | Contact | Migration owner |
|---|---|---|---|
| <name> | <count> | <email> | <name on our side> |

### External — public / unknown

- Public API consumers (cannot enumerate) — addressed via
  changelog + docs banner.
- SDK users — addressed via SDK release notes.

---

## Sunset schedule

| Stage | Start date | End date | Old path behaviour | Comms |
|---|---|---|---|---|
| Stage 1 — Soft deprecation | YYYY-MM-DD | YYYY-MM-DD | Works normally; banner in docs | Initial comms (this doc's announcements) |
| Stage 2 — Warn in response | YYYY-MM-DD | YYYY-MM-DD | Works normally; deprecation header in responses; log warning | Reminder comms |
| Stage 3 — Soft fail | YYYY-MM-DD | YYYY-MM-DD | Works for low-volume callers; 410 Gone for high-volume | Final-week reminder |
| Stage 4 — Removed | YYYY-MM-DD | – | 410 Gone with link to new endpoint | Removal announcement |

(See [sunset-schedule-examples.md](sunset-schedule-examples.md)
for worked sunset patterns.)

---

## Comms artifacts

### Internal Slack announcement

> **Breaking change: <change> — sunset YYYY-MM-DD**
>
> What: <one line>
> Why: <one line>
> Affected internal teams: <list>
> Migration support: <contact>
> Full plan: <link>

### Internal email

```
Subject: Breaking change to <surface> — please migrate by <date>

Hi team,

We're sunsetting <old surface> on <date> in favour of <new
surface>. This affects <teams>.

Migration steps: <link>
Why: <reason>
Migration support: <contact / channel>

Timeline:
- <date>: Deprecation banner ships
- <date>: Warn-in-response begins
- <date>: Soft-fail for high-volume callers
- <date>: Final removal

Reply to this email or ping <channel> with questions.

— <name>
```

### Customer email (impacted)

```
Subject: Action needed: <change> by <date>

Hi <customer name>,

We noticed your integration uses <old surface>. We're sunsetting
this on <date> in favour of <new surface>.

Your endpoint usage in the last 30 days: <count>

Migration steps: <link>
Estimated migration effort: <time>
Direct migration support: <email>

We're available to walk through the migration any time before
<date>.

— <name>
```

### Changelog entry

```markdown
## <date> — Breaking change: <change>

**Status:** Deprecated; removal on <date>

We're sunsetting <surface> in favour of <surface>.

**Why:** <reason>

**What changes:** <details>

**Migration guide:** <link>

**Timeline:**
- <date>: Deprecation banner
- <date>: Warn-in-response
- <date>: Soft-fail
- <date>: Removal

**Questions:** <support channel>
```

### API docs deprecation banner

```html
<div class="deprecation-banner">
  ⚠️ <strong>Deprecated</strong> — This endpoint will be removed
  on <date>. Use <new endpoint> instead.
  <a href="<migration-guide>">Migration guide →</a>
</div>
```

(Place on every page documenting the deprecated surface.)

### FAQ

**Q: Why are you sunsetting this?**
A: <reason>

**Q: Can we get an extension?**
A: <escalation path — see below>

**Q: What if our integration breaks before we migrate?**
A: <support contact + workaround if any>

**Q: Will old data still be accessible after sunset?**
A: <yes/no + details>

**Q: How does this affect billing / contracts?**
A: <if applicable>

---

## Escalation path

| Request | Decided by |
|---|---|
| Engineering scope (extend warn-in-response by 30 days) | Tech lead |
| Product scope (delay sunset; affects N customers) | Product owner |
| Business scope (key customer threatens churn) | <named business authority> |

---

## Monitoring

Track migration progress weekly:

- % of impacted customers migrated (telemetry-based).
- Support ticket volume mentioning the deprecation.
- Number of calls to deprecated endpoint over time.

If progress lags (<50% migrated at start of Stage 3), trigger
extra customer outreach OR consider schedule extension.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial | <name> |
