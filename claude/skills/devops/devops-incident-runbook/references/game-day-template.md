# Game-Day Plan — <incident class>

**Runbook under test:** [<incident class runbook>](.<incident-class>.md)
**Last rehearsal:** YYYY-MM-DD
**Next rehearsal:** YYYY-MM-DD (quarterly)
**Game-day owner:** <on-call rotation lead>

---

## Goal

Verify the runbook can be executed under realistic conditions
without improvisation. Game days don't test the *system* — they
test the *runbook*.

## Scope

**In scope.** The runbook's 5 sections (detect → diagnose →
mitigate → recover → postmortem trigger).

**Out of scope.**

- Production environment (game day runs on staging unless
  explicitly testing prod-only path).
- Changes that affect real customers.
- Side-effect-producing operations (real payments, real
  emails) — mock or skip.

---

## Failure injection method

| Method | Use when |
|---|---|
| `kubectl scale --replicas=0` | Testing service-unavailable runbook |
| Chaos Mesh / Litmus | Testing degradation runbooks (network, disk, latency) |
| Manual config break | Testing config-error runbooks |
| Synthetic load | Testing capacity-threshold runbooks |
| Disable downstream dep | Testing dep-outage runbooks |
| Expired cert / token | Testing auth-failure runbooks |
| Time jump (NTP) | Testing time-sensitive runbooks |

Document the **exact** injection command:

```bash
# Verbatim failure injection
kubectl scale deployment/<service> --replicas=0 -n staging
# Verify injection: should see service unavailable in dashboard within 60s
```

---

## Participants

- **First responder** — the engineer who would normally take the
  alert (typically on-call rotation member).
- **Observer** — second engineer; records what's confusing,
  ambiguous, or wrong in the runbook. Doesn't help; doesn't
  intervene.
- **Facilitator** — game-day owner; injects the failure;
  declares success/abort.
- **(Optional) shadow** — junior engineer or new team member
  observing for training.

---

## Success criteria

The game day **passes** when ALL:

- [ ] First responder reached mitigation step within target time
      (typically 15 min for SEV1, 30 min for SEV2).
- [ ] No improvisation needed beyond what's documented.
- [ ] All commands in the runbook ran without error.
- [ ] Observer notes captured for runbook updates (if any).

The game day **fails** if any of:

- First responder couldn't find the right runbook from the alert.
- A documented command doesn't work.
- A documented dashboard URL is broken.
- Mitigation took longer than target (runbook may be wrong /
  out-of-date).

---

## Out-of-bounds (don't do during game day)

- ❌ Touch production resources.
- ❌ Charge real customers.
- ❌ Send real emails / notifications to anyone outside the
  game-day participants.
- ❌ Modify the runbook during the exercise (capture issues;
  fix after).
- ❌ Run during a customer-facing event window.

---

## Pre-game-day checklist

- [ ] Staging environment in known-good state.
- [ ] Failure injection command tested separately (you know it
      reproduces the failure).
- [ ] Participants notified of scheduled exercise.
- [ ] Observer notebook ready.
- [ ] Real on-call rotation aware that any new pages during the
      window may be the exercise.

---

## During the exercise

| Time | Step | Owner |
|---|---|---|
| T-15 min | Brief participants; review scope | Facilitator |
| T+0 | Inject failure | Facilitator |
| T+0 onward | Respond per runbook | First responder + observer |
| T+timeout | Declare success / failure | Facilitator |
| T+exercise end | Restore staging to clean state | Facilitator |

---

## After-action review

Within 24h:

- **What went well.** <points>
- **What was unclear in the runbook.** <points>
- **What commands didn't work as documented.** <points>
- **What took longer than expected.** <points>
- **Updates needed to the runbook.** <list of edits>

The runbook gets updated within 1 week. Schedule the next game
day quarterly from today.

---

## When to escalate to a real-prod fire drill

For SEV1 runbooks that must work in prod (e.g. region failover,
DB failover), an annual **production fire drill** is recommended.
This is a real-prod exercise with extra preparation:

- Maintenance window scheduled and announced.
- Customer comms pre-staged.
- Rollback plan pre-rehearsed.
- All hands on deck.

Production fire drills are expensive but catch the things staging
game days miss.

---

## Change log

| Date | Result | Runbook updates needed |
|---|---|---|
| YYYY-MM-DD | pass / fail | <link to PR / commit> |
