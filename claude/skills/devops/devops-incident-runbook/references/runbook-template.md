# Runbook: <incident class>

**Severity:** SEV1 | SEV2 | SEV3
**First responder:** <on-call rotation name>
**Owner team:** <team name>
**Last reviewed:** YYYY-MM-DD
**Last game-day rehearsal:** YYYY-MM-DD
**Status:** active | draft | superseded

---

## 1. Detect

**Alert:** [<alert-name>](<alert-url>)

**Dashboard:** [<dashboard-name>](<dashboard-url>)

**First three things to look at:**

1. <chart / panel name + what to look for>
2. <…>
3. <…>

**Confirmation checks** (rule out false positives):

- <check 1>
- <check 2>

---

## 2. Diagnose

Decision tree. Start at the top.

```
Is <symptom A> present?
├── YES → Likely <cause A>; go to Mitigate § A
└── NO  → Is <symptom B> present?
         ├── YES → Likely <cause B>; go to Mitigate § B
         └── NO  → Is <symptom C> present?
                  ├── YES → Likely <cause C>; go to Mitigate § C
                  └── NO  → Escalate to <named engineer / next runbook>
```

**How to check each symptom:**

| Symptom | Command / query | Expected if present |
|---|---|---|
| <symptom A> | `<verbatim command>` | <expected output> |
| <symptom B> | `<verbatim command>` | <expected output> |
| <symptom C> | `<verbatim command>` | <expected output> |

---

## 3. Mitigate

### § A — <cause A>

**Why it happens.** <one paragraph>

**Mitigation commands** (verbatim; copy-paste-ready):

```bash
# Required context: KUBECONFIG=prod
# Required role: deployer
# Time: 30–90s

kubectl rollout restart deployment/<service> -n prod
# Verify:
kubectl get pods -n prod | grep <service>
# Wait until all pods Running before continuing
```

**If mitigation succeeds** → go to § Recover.

**If mitigation fails after 5 min** → escalate to <named
engineer>.

---

### § B — <cause B>

(same shape)

---

### § C — <cause C>

(same shape)

---

## 4. Recover

**Verify steady state:**

- Dashboard `<url>` — <metric> back below <threshold>.
- Sample request succeeds: `curl <verification-endpoint>`.
- Error rate dashboard returns to baseline.

**Unwind temporary mitigations:**

- <e.g. re-enable feature flag X>
- <e.g. restart paused workers>
- <e.g. restore traffic to <region>>

**Internal communication:**

> Incident #<id> resolved at <time>. Cause: <one-line>.
> Mitigation: <one-line>. Postmortem to follow within <N>
> business days.

**External communication** (if required):

- Status page update: see `arch-breaking-change-comms`.
- Customer email: see `arch-breaking-change-comms`.

**Record:**

- Incident start time: <from alert>
- Mitigation applied: <time>
- Resolved: <time>
- Detection-to-resolution: <duration>

---

## 5. Postmortem

**Required for this severity?** YES (SEV1) / IF NOVEL (SEV2) /
JUDGEMENT (SEV3)

**Template.** [postmortem-template.md](postmortem-template.md)

**Filed at.** `docs/postmortems/YYYY-MM-DD-<incident-slug>.md`

**Reviewed in.** Team retro on <day>.

---

## Game-day plan

**Last rehearsal:** YYYY-MM-DD

**Next rehearsal:** YYYY-MM-DD (quarterly)

**Failure injection method:** <command / chaos tool / staging
procedure>

**Success criteria:**

- Mitigation step reached within <X> minutes.
- No improvisation needed beyond what's documented.
- Observer notes captured for runbook updates.

---

## Change log

| Date | Change | By |
|---|---|---|
| YYYY-MM-DD | initial | <name> |
