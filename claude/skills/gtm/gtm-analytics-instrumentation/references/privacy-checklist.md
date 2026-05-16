# Privacy Checklist for Product Telemetry

Privacy is the load-bearing distinction between *useful product
analytics* and *creepy surveillance*. Get it right before the
first event fires; retrofitting is hard.

---

## Per-event privacy review

For every event in `events.json`, answer:

- [ ] **Does this event contain PII?** (email, name, phone, IP,
      device ID, exact location)
- [ ] **If yes, is it strictly necessary?** Most product
      telemetry needs *event + outcome*, not *user identity*.
- [ ] **If yes, is it redacted / hashed?** (`redact: true` in
      events spec)
- [ ] **Where is the event stored?** Privacy posture of the
      analytics backend.
- [ ] **Who can query the data?** Access control documented.
- [ ] **How long is it retained?** Per data class.
- [ ] **Is it shared with third parties?** If yes, DPA in place.

---

## Identifier hygiene

| Identifier | Use |
|---|---|
| **Anonymous device ID** | Default; auto-generated; cookie / localStorage / IDFA-style |
| **Authenticated user ID** | Set after login; ties device ID to account |
| **Email** | Never in event payload; only in user-table joins |
| **Server-side hash** | If linking is needed for analytics queries |

```typescript
// GOOD
analytics.track('signup_completed', { method: 'google' });
// (current user ID set on identify(); not in event payload)

// BAD
analytics.track('signup_completed', {
  email: 'alice@example.com',  // ← PII in event payload
});
```

---

## GDPR + CCPA checklist

### If serving EU users

- [ ] Cookie consent banner before any tracking starts.
- [ ] Consent stored with timestamp + version.
- [ ] Opt-out clearly accessible.
- [ ] Data Subject Access Request (DSAR) flow:
  - [ ] User can request all their data.
  - [ ] User can request deletion.
  - [ ] Both within 30 days response time.
- [ ] Data Processing Agreement (DPA) with every analytics vendor.
- [ ] Legal basis declared for each tracking category.
- [ ] Data Protection Officer (DPO) identified (if required).

### If serving California users

- [ ] "Do Not Sell My Personal Information" link in footer.
- [ ] CCPA Subject Access Request flow.
- [ ] Disclosure of third-party data sharing.

### If serving children (under 13 US / under 16 EU)

- [ ] COPPA compliance.
- [ ] No tracking without verifiable parental consent.
- [ ] Different consent UI for child users.

---

## Tools per posture

### Cookieless / privacy-first (default for new B2B)

**Tools:** Plausible, Fathom, Simple Analytics.

**Properties:**

- No cookies; no GDPR consent banner required (in most
  jurisdictions).
- No cross-site tracking.
- No PII collection.

**Trade-off:** Less granular than full-tracking; can't tie events
to individual users without authentication.

### Consent-gated (most B2C; B2B with EU customers)

**Tools:** PostHog, Mixpanel, Amplitude.

**Properties:**

- Cookie banner required before tracking starts.
- Can tie events to users post-login.
- Rich behavioural analytics.

**Trade-off:** Banner-fatigue customers may decline; reduced
data quality.

### Opt-in only (high-trust users; enterprise B2B)

**Tools:** Self-hosted PostHog, Snowplow, custom pipeline.

**Properties:**

- No tracking without explicit opt-in.
- User explicitly grants permission.
- Privacy posture pristine.

**Trade-off:** Lowest data volume; need other signals.

---

## What never to track

| Field | Why never |
|---|---|
| Passwords (raw, hashed, attempt counts in event payload) | Auth breach risk |
| Auth tokens / refresh tokens | Auth breach risk |
| Credit card numbers | PCI scope expansion |
| SSN / national IDs | Massive breach liability |
| Health data (unless HIPAA-compliant stack) | Regulatory |
| Sexual orientation, religion, race (without explicit purpose) | GDPR special category |
| Children's data (without parental consent) | COPPA |
| Precise geolocation (lat/long beyond city-level) | GDPR + abuse risk |

---

## What's safe to track

| Field | Safe with conditions |
|---|---|
| Anonymous device ID | Always |
| Authenticated user ID | Always after consent |
| Email domain (not full email) | For B2B; "company size" proxy |
| Plan tier | Always |
| Feature usage | Always |
| Page views (anonymous) | Always |
| Referrer (with PII redaction in URLs) | Always |
| User agent (browser / OS class) | Generally OK |
| IP-based country | Usually OK; classify as PII in EU |
| Timestamp | Always |

---

## Retention

| Data class | Default retention |
|---|---|
| Authenticated user events | 90 days |
| Aggregated metrics | 2+ years |
| PII-redacted raw events | 1 year |
| Anomaly-triggering events (incidents) | 7 years (or per regulation) |
| Failed-auth attempts | 90 days |

Configure retention at the analytics platform; don't rely on
"someone will purge it eventually".

---

## Access control

Per-team access to telemetry:

| Team | Access |
|---|---|
| Product | Read all (post-PII-redaction) |
| Engineering | Read all (debugging) |
| Marketing | Read aggregated funnels |
| Sales | Read account-level (their accounts) |
| Customer Success | Read account-level |
| Security | Read all (with audit log) |
| Anyone else | No direct access; reports only |

Audit log of analytics access (per `enterprise-kb-access-control`'s
audit-log pattern; analytics access is access too).

---

## Opt-out UX

When a user opts out of tracking:

- ✅ Stop emitting new events for them.
- ✅ Their existing event history persists per retention (don't
  delete unless they request deletion).
- ✅ Acknowledge in UI ("Tracking disabled").
- ❌ Don't block product functionality based on opt-out.
- ❌ Don't degrade product experience to nag re-opt-in.

---

## Privacy posture statement

The marketing site should publish the project's privacy posture
in plain English:

> We collect <X events> to help us improve the product. We
> don't track <Y, Z>. You can <opt out / delete data> at any
> time via <flow>. Our analytics is hosted by <vendor> in
> <region> under <DPA reference>.

This builds trust and reduces support ticket volume on privacy
questions.

---

## Anti-patterns

- ❌ Tracking everything "just in case we need it later."
- ❌ PII in event names ("user_alice_signed_up").
- ❌ Sharing data with vendors without DPA.
- ❌ Retention beyond what's documented.
- ❌ Privacy policy + actual practice disagree.
- ❌ Opt-out flow that's hard to find.
- ❌ "Required" tracking that's actually marketing-driven.
- ❌ Re-prompting opt-out users to opt back in (dark pattern).
