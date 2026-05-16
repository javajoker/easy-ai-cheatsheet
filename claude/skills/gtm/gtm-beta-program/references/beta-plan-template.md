# Beta Program Plan — <project>

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Status:** draft | active | completed | sunset

---

## Goal

<one paragraph: what we want to learn from the beta, framed by
the chosen positioning brief.>

## Scope

| In scope | Out of scope |
|---|---|
| <feature/persona/region> | <…> |
| <…> | <…> |

## Phases

### Phase 0 — Internal dogfood

| Field | Value |
|---|---|
| Cohort | <e.g. all employees, ~50> |
| Duration | 1–2 weeks |
| Entry criteria | All P0 functionality complete |
| Exit criteria | (see below) |
| Feedback channel | `#dogfood` Slack |

**Exit criteria (move to Phase 1):**

- [ ] No P0 bugs open.
- [ ] Core flow completable end-to-end by every employee tester.
- [ ] Onboarding doc draft exists.
- [ ] Internal NPS / satisfaction ≥ <threshold>.

### Phase 1 — Closed beta

| Field | Value |
|---|---|
| Cohort | <10–50 hand-picked ICP users> |
| Duration | 4–8 weeks |
| Entry criteria | Phase 0 exit + intake form live |
| Exit criteria | (see below) |
| Feedback channel | `#beta-private` (invited) + weekly check-in calls |
| Recruitment | <waitlist / outbound / community> |
| NDA | <none / soft / formal> |

**Recruitment:**

- Target: <N> ICP-matching candidates per `gtm-positioning`.
- Channels: <waitlist / outbound / referrals>.
- Screening: see [intake-form-template.json](intake-form-template.json).

**Exit criteria (move to Phase 2):**

- [ ] ≥70% of closed beta cohort activated (defined event).
- [ ] ≥30% retained at week 4.
- [ ] NPS ≥ 30 (or qualitative equivalent).
- [ ] Critical-path issues found in closed beta are all fixed.
- [ ] Support load per user sustainable at 10× volume.

### Phase 2 — Open beta

| Field | Value |
|---|---|
| Cohort | <100–1000+ from waitlist or public> |
| Duration | 4–12 weeks |
| Entry criteria | Phase 1 exit + scaled support/ops |
| Exit criteria | (see below) |
| Feedback channel | Public forum + in-app feedback widget |
| Recruitment | Waitlist drainage + public marketing |
| NDA | None (open) |

**Exit criteria (move to Phase 3):**

- [ ] Conversion + retention metrics meet pre-defined targets.
- [ ] `gtm-launch-readiness` audit is PASS.
- [ ] Pricing model validated (open-beta users converted at
      expected rate, if monetised).
- [ ] Support + on-call capacity sized for public launch.

### Phase 3 — Public launch

Per `gtm-launch-readiness` + `lifecycle-pilot` Phase 8.

---

## Feedback loop

| Channel | Use | Triage SLA |
|---|---|---|
| Primary: `<channel>` (Slack / Discord / forum) | All beta feedback | 48h acknowledge |
| Secondary: `feedback@example.com` | Async / private | 48h acknowledge |
| Weekly check-in (Phase 1 only) | Qualitative depth | – |
| In-app feedback widget (Phase 2+) | Casual / volume | 48h acknowledge |
| Office hours (across all phases) | Open Q&A | – |

### Triage rubric

Every piece of feedback classified using
[feedback-triage-rubric.md](feedback-triage-rubric.md):

| Class | Action |
|---|---|
| Bug | File in tracker; prioritise per severity |
| Gap (feature PRD missed) | PM review; PRD update if material |
| Misalignment (expected ≠ shipped) | Clarify docs/copy; don't ship |
| Wishlist | Log for post-GA roadmap |

### Closing the loop

Beta users hear back when feedback ships (or doesn't, with why).
Weekly recap email summarises:

- What shipped this week
- What's in flight
- What we won't ship + why

---

## Beta-specific telemetry

Events from `gtm-analytics-instrumentation` apply to all users.
Beta cohorts also need *transient* events:

- `beta_user_signed_up`
- `beta_user_activated`
- `beta_user_retained_week_2/4/8`
- Per-feature deep-dive events for Phase 1 focus areas
- Session replays (if privacy-acceptable; users consented)

Beta events tagged `beta_only: true` and pruned after Phase 3.

---

## Communication plan

### Pre-launch (waitlist)

| Moment | Audience | Channel | Content |
|---|---|---|---|
| T-30d | Waitlist | Email | "Beta opens in 30 days; here's what to expect" |
| T-7d | Selected cohort | Email | "You're in! Onboarding instructions" |
| T-0 | Selected cohort | Email + product | "Welcome — get started" |

### During beta

| Moment | Audience | Channel | Content |
|---|---|---|---|
| Weekly | Beta cohort | Email | Recap + what's coming + open Q&A reminder |
| Per release | Beta cohort | In-app + email | What's new + known issues |
| Per critical bug | Beta cohort | Email + Slack | Heads up + workaround |

### Phase transitions

| Moment | Audience | Channel | Content |
|---|---|---|---|
| Phase 1 → Phase 2 | Closed beta cohort + waitlist | Email | "We're opening up — thank you" |
| Phase 2 → Phase 3 | All beta users | Email + product | "Public launch tomorrow — pricing change details" |

---

## Pricing during beta

| Phase | Pricing |
|---|---|
| 0 — internal | Free |
| 1 — closed | Free (or heavily discounted; reset on GA) |
| 2 — open | Free or paid trial (per `pricing-model.md`) |
| 3 — public launch | Standard pricing |

Communicate pricing intent at sign-up time so phase transitions
aren't a surprise.

---

## Risks

| Risk | Mitigation |
|---|---|
| Cohort isn't representative | ICP-based screening + diverse recruitment |
| Feedback overwhelms team | Triage rubric + capped weekly capacity |
| Beta becomes the product (never exits) | Pre-agreed exit criteria + decision authority |
| Cohort churns mid-beta | Engagement metrics + outreach |
| Public competitive sensitivity | NDA + selective recruitment |

---

## Decision authority

| Decision | Authority |
|---|---|
| Add a beta phase | PM |
| Extend a phase | PM + Eng lead |
| Skip a phase | VP Product |
| End the beta (success) | VP Product |
| End the beta (failure / pivot) | VP Product + CEO |

---

## Anti-patterns

- ❌ No screening for closed beta.
- ❌ No exit criteria.
- ❌ Beta drifts indefinitely; no GA date.
- ❌ Feedback in 6 channels; nobody triages.
- ❌ Beta users surprised by pricing at launch.
- ❌ Public launch before exit criteria pass.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial plan | <name> |
