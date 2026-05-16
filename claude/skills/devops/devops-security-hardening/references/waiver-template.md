# Security Waiver — <row id>

**Waiver ID:** W-<sequential>
**Issued:** YYYY-MM-DD
**Expires:** YYYY-MM-DD (mandatory; no indefinite waivers)
**Status:** active | expired | resolved | revoked

---

## Waived row

**Security baseline row:** <e.g. 4.6 — MFA supported>

**Original status:** FAIL

**Why FAIL.** <one paragraph; what doesn't meet the bar>

---

## Justification

**Business justification.** <one paragraph; why we're shipping
despite this gap. What would we delay if we waited for PASS?>

**Risk acceptance.** <what risk we're accepting; blast radius if
the gap is exploited>

---

## Compensating control

**What's in place instead.** <one paragraph; the workaround,
mitigation, or alternative control>

**Where to find it.** <links to the implementation>

**Why this is adequate.** <argument for why this control
addresses the risk to an acceptable level>

---

## Approval

**Approver:** <named individual + role; e.g. "Jane Doe, VP Engineering">

**Approval date:** YYYY-MM-DD

**Approval evidence.** <link to approval record — Slack thread,
email, ticket>

**Secondary approval** (required for regulated environments or
high-severity rows):

- <named individual + role>
- Date: YYYY-MM-DD
- Evidence: <link>

---

## Path to PASS

**Plan.** <what we'll do to close the waiver>

**Owner.** <named individual>

**Estimated effort.** <hours/days/weeks>

**Target close date.** YYYY-MM-DD (must be ≤ waiver expiry)

**Tracking.** <link to ticket / issue>

---

## Renewal policy

If the waiver expires without resolution:

- ⚠️ Operations: notify approver 30d before expiry.
- 🔄 Renewal: requires fresh approval (not auto-renewed).
- ❌ If approval not refreshed: status → `expired`; FAIL row
  becomes blocking for production releases.

A waiver renewed more than twice indicates the path-to-PASS
isn't realistic; trigger an architecture / scope review.

---

## Communication

**Disclosed to.**

- [ ] Security team — date sent: YYYY-MM-DD
- [ ] Compliance team (if applicable) — date sent: YYYY-MM-DD
- [ ] On-call team (so they know what to look for) — date: YYYY-MM-DD
- [ ] Customer / external (if material) — date: YYYY-MM-DD

---

## Quarterly review

- [ ] Q1 review: <date>. Findings: <…>. Renewed/closed: <action>.
- [ ] Q2 review: <date>. Findings: <…>.
- [ ] Q3 review: <date>. Findings: <…>.
- [ ] Q4 review: <date>. Findings: <…>.

---

## Anti-patterns (do not do)

- ❌ Indefinite waivers (no expiry).
- ❌ Waivers approved by the same person whose work caused the
  FAIL.
- ❌ Waivers without a documented compensating control.
- ❌ Waivers stacked indefinitely (renewed quarterly forever).
- ❌ Waivers for entire categories (must be row-specific).
- ❌ Verbal waivers — no record means no waiver.

---

## Change log

| Date | Change | By |
|---|---|---|
| YYYY-MM-DD | initial waiver issued | <approver> |
| YYYY-MM-DD | quarterly review | <reviewer> |
