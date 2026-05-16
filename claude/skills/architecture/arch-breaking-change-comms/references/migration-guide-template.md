# Migration Guide — <old surface> → <new surface>

**Version:** 1
**Audience:** consumers of <old surface>
**Estimated effort:** <e.g. 15 min / 1 day / 1 week>
**Owner:** <name>
**Status:** active

---

## TL;DR

<3-bullet summary. What changes; what to do; deadline.>

- <bullet 1>
- <bullet 2>
- <bullet 3>

---

## Why this is changing

<one paragraph — why the change is happening. Tied to the
architectural reason. Customers are more cooperative when they
understand the why.>

---

## What's changing

### Before (old surface)

```
<example old usage — code snippet, API call, config>
```

### After (new surface)

```
<example new usage — code snippet, API call, config>
```

### Side-by-side comparison

| Aspect | Old | New |
|---|---|---|
| Endpoint | `/api/v1/foo` | `/api/v2/foo` |
| Auth | API key in header | OAuth bearer |
| Response shape | `{ result: ... }` | `{ data: ..., meta: ... }` |
| Error format | string | structured `{ code, message, details }` |

---

## Step-by-step migration

### Step 1 — <action>

```
<exact code or command>
```

What this does: <one line>

Verification: <how to check this step worked>

### Step 2 — <action>

```
<exact code or command>
```

What this does: <one line>

Verification: <how to check>

### Step 3 — <action>

(continue for as many steps as needed)

---

## Edge cases

- **If you use <X feature>:** <special handling>
- **If you have multiple instances:** <special handling>
- **If you're on an older SDK version:** <special handling>

---

## Verifying your migration

Once migrated:

- [ ] Deprecation warning header no longer appears in responses.
- [ ] All test suites pass.
- [ ] Spot-check 3 user flows.
- [ ] Monitor logs for 24h — no `LegacyAPIUsedWarning` entries.

---

## What stays the same

To save you re-reading old docs:

- <thing that didn't change>
- <thing that didn't change>

---

## Common gotchas

| Gotcha | Solution |
|---|---|
| <e.g. response field renamed> | <e.g. update field name in client> |
| <e.g. timezone now UTC> | <e.g. convert before display> |

---

## Support

- **Slack:** <channel>
- **Email:** <support email>
- **Office hours:** <day/time>
- **Migration questions:** typically answered within <hours>

---

## Timeline

- **Today:** new surface available; migrate at your pace.
- **<date>:** warn-in-response begins (your old calls log
  warnings).
- **<date>:** soft-fail for high-volume callers (you'll start
  seeing 410s if you call more than <threshold>/hour).
- **<date>:** old surface removed entirely.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial | <name> |
