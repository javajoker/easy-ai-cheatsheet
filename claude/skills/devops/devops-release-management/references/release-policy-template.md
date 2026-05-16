# Release Policy — <project>

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Status:** active | draft | superseded
**Next review:** YYYY-MM-DD (annual)

---

## Cadence

**Choice:** continuous | daily | weekly | bi-weekly | on-demand

**Rationale.** <one paragraph>

**Scheduled release time** (if applicable): <e.g. Tuesdays 10:00 PT>

---

## Freeze windows

Releases are paused (deploy freeze) during:

| Window | Recurrence | Rationale |
|---|---|---|
| Friday 15:00 → Monday 09:00 (TZ) | Weekly | No weekend on-call for non-emergencies |
| Last week of each quarter | Quarterly | Q-end customer demos / reporting |
| Major holidays (region: <regions>) | Per calendar | Skeleton on-call only |
| Customer go-live windows | Per customer | Don't break the customer's launch |
| Major launch -3 days through +3 days | Per launch | Stabilise the launch |

**Code freeze** (no merges to main) applies during: <e.g. major
incident response, security patch coordination>

**Emergency override:**

- Required: documented business justification + approval from
  <named role> + on-call confirmed available + post-deploy
  monitoring.
- Logged in: `docs/freeze-overrides/YYYY-MM-DD-<reason>.md`.

---

## Approval chain

| Stage | Approver | Verification |
|---|---|---|
| Dev | Auto | Pipeline green |
| Staging | Auto | Pipeline green |
| Prod (standard) | Engineer + PR reviewer | Both ✓ in pipeline |
| Prod (high-risk: DB migration, infra, auth, breaking API) | Engineer + reviewer + senior engineer | All three ✓ |
| Prod (during freeze) | Above + override authority `<role>` | All approvals + override log |

**High-risk classification:**

- Database migrations (any schema change).
- Infrastructure changes (IaC apply).
- Authentication / authorization changes.
- Breaking API changes.
- Changes to billing / payment flows.
- Changes to anything tagged `high-risk` in the codebase.

---

## Versioning

**Scheme:** SemVer (`vX.Y.Z`) | CalVer (`YYYY.MM.DD`) | trunk + flags

**Rules:**

- <e.g. "Major version bump only with breaking API change; documented
  in CHANGELOG with migration path">
- <e.g. "Every prod release tagged in git">
- <e.g. "Hotfixes use patch version">

**Enforcement:** CI rejects merges that change `version` inconsistently
with this rule set.

---

## Rollback

### Mode 1 — Reverse deploy (fastest)

**Use when:** no state migrations; previous artifact is still
deployable.

**Verbatim procedure:**

```bash
# Required context: KUBECONFIG=prod
# Approver: <role>
# Expected duration: 2–5 minutes

kubectl rollout undo deployment/<service> -n prod
# Verify
kubectl rollout status deployment/<service> -n prod
```

**Communication template:**

> Rolling back <service> to previous version due to <reason>.
> ETA: <minutes>. Will update when complete.

---

### Mode 2 — Revert + redeploy

**Use when:** reverse deploy not viable; need a clean code state.

**Verbatim procedure:**

```bash
git revert <sha>
git push origin main
# CI builds + auto-deploys to staging
# Then manual approval for prod
```

**Approver:** standard prod approval chain.

---

### Mode 3 — Forward fix

**Use when:** rollback impossible (DB migrated, customer data
written, breaking change already consumed).

**Procedure:**

1. Engineering declares incident (`devops-incident-runbook`).
2. Hotfix branched from main; standard PR process + expedited
   review.
3. Deploy via standard chain.
4. Postmortem within <N> business days.

**Communication:** `arch-breaking-change-comms` if customer
impact.

---

### Rollback drill cadence

**Quarterly minimum.** Last drill: <date>. Next drill: <date>.

Drills run on staging unless explicitly testing the prod
procedure (rare; requires named approver).

---

## Communication

| Audience | Channel | When | Owner |
|---|---|---|---|
| Engineering | `#deploys` | Every deploy (auto) | Pipeline |
| Customers (breaking) | Email + changelog | Per `arch-breaking-change-comms` | Product |
| Customers (feature releases) | Changelog + release notes | Per significant release | Product / Marketing |
| Status page | `status.<domain>` | Incidents + maintenance | On-call |

Templates in `docs/comms-templates/`.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial lock | <name> |
