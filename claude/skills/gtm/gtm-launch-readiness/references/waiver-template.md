# Launch Readiness Waiver — <row id>

**Waiver ID:** LRW-<sequential>
**Issued:** YYYY-MM-DD
**Expires:** YYYY-MM-DD (mandatory; must be ≤ 90 days post-launch)
**Status:** active | expired | resolved | revoked

---

## Waived row

**Launch-readiness audit row:** <e.g. 4.6 — Backup verified via
test restore>

**Original status:** FAIL

**Why FAIL.** <one paragraph; what doesn't meet the bar>

---

## Justification

**Business justification.** <one paragraph; why we're launching
despite this gap. What would we delay if we waited?>

**Risk acceptance.** <what risk we're accepting; blast radius if
the gap is exploited / surfaces post-launch>

**Customer impact if risk materialises.** <e.g. "data loss for up
to 24h of activity"; "extended outage during recovery">

---

## Compensating control

**What's in place instead.** <one paragraph; the workaround,
mitigation, or alternative control bridging the gap>

**Where to find it.** <links to the implementation>

**Why this is adequate for launch.** <argument for why this
control addresses the risk to an acceptable level for the launch
window>

---

## Approval

**Approver:** <named individual + role>

**Approval date:** YYYY-MM-DD

**Approval evidence.** <link to approval record — Slack thread,
email, board meeting minutes>

**Secondary approval** (required for high-severity rows or
regulated environments):

- <named individual + role>
- Date: YYYY-MM-DD
- Evidence: <link>

---

## Path to close

**Plan.** <what we'll do to close the waiver after launch>

**Owner.** <named individual>

**Estimated effort.** <hours/days/weeks>

**Target close date.** YYYY-MM-DD (must be ≤ waiver expiry)

**Tracking.** <link to ticket / issue / project>

**Re-audit trigger.** <when the row will be re-audited; typically
within 30–90 days of launch>

---

## Customer communication (if applicable)

If the waived gap affects customers in a way they should know about:

- [ ] Disclosed in launch announcement? <yes/no + how>
- [ ] Disclosed in privacy policy / ToS? <yes/no + section>
- [ ] Direct customer notification needed? <yes/no + recipient list>

---

## Monitoring

**During waiver window:**

- [ ] Specific metric monitored for risk materialisation:
  `<metric + threshold>`
- [ ] Alert configured for the metric: `<alert URL>`
- [ ] Watch dashboard: `<dashboard URL>`
- [ ] Weekly review: <day of week>

**Trigger if the risk materialises:**

- [ ] Incident response: `<runbook>`
- [ ] Customer comms: `<comms template>`
- [ ] Waiver review (early close): `<review process>`

---

## Renewal policy

If the waiver expires without resolution:

- ⚠️ Operations: notify approver 30d before expiry.
- 🔄 Renewal: requires fresh approval; **not auto-renewed**.
- ❌ If approval not refreshed: status → `expired`; row becomes
  blocking for next release.

A launch waiver renewed more than **once** indicates the
path-to-close isn't realistic; trigger an architecture / scope
review.

---

## Communication

**Disclosed to:**

- [ ] Eng team — date: YYYY-MM-DD
- [ ] Security team — date: YYYY-MM-DD
- [ ] Compliance team (if applicable) — date: YYYY-MM-DD
- [ ] Leadership — date: YYYY-MM-DD
- [ ] On-call team — date: YYYY-MM-DD

---

## Anti-patterns

- ❌ Waivers issued silently (not surfaced to leadership).
- ❌ Waivers with no monitoring (we don't know if the risk
  materialises).
- ❌ Waivers extended beyond 90 days post-launch.
- ❌ Multiple stacked waivers for the same row.
- ❌ Waivers for security-critical rows without compensating
  control.

---

## Change log

| Date | Change | By |
|---|---|---|
| YYYY-MM-DD | initial waiver issued | <approver> |
| YYYY-MM-DD | weekly review (no change) | <reviewer> |
| YYYY-MM-DD | resolved — row now PASS | <reviewer> |
