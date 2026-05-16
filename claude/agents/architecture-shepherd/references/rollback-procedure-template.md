# Rollback Procedure Template (agent-level)

Used at every phase boundary in `arch-migration-plan` and every
ramp stage in `arch-rollout-strategy`. The rollback procedure is
**verbatim commands**, not gestures.

---

## Per-rollback fields

```markdown
## Rollback — <phase / stage name>

**When to invoke.** <specific trigger — failed audit gate, abort
condition fired, manual decision>

**Decision-maker.** <named role; never "the team">

**Required context / permissions.**
- KUBECONFIG=<env>
- AWS_PROFILE=<profile>
- IAM role: <role>

**Expected duration.** <minutes>

**Verbatim commands.**

```bash
# Step 1 — what this does
<command 1>
# Verify
<verify command>

# Step 2 — what this does
<command 2>
# Verify
<verify command>
```

**Verification of rollback success.**

- Dashboard `<url>` — <metric> back to baseline.
- Sample request: `curl <endpoint>` returns 200.
- Error rate dashboard returns to <% baseline>.

**Communication template.**

> Rolling back <change> due to <reason>. ETA <minutes>. Will
> update when complete.

**What is NOT rolled back.**

- <data written via new path>
- <consumer behaviour that learned about new contract>
- <…>

**Postmortem trigger.**

- <yes/no — SEV1 always; SEV2 if novel; SEV3 by judgement>
```

## Three-tier rollback pattern (from `devops-release-management`)

| Tier | Mechanism | Use when |
|---|---|---|
| 1. Reverse deploy | Redeploy previous artifact | No state migrations; fast |
| 2. Revert + redeploy | `git revert` + new build + deploy | Reverse deploy failed |
| 3. Forward fix | Hotfix branch + expedited deploy | Rollback impossible (data migrated, write cutover passed) |

Each tier has its own procedure block above.

## Anti-patterns

- **"Revert the deploy."** Not a procedure.
- **Unnamed decision-maker.** Rollback during incident is no time
  to look up authority.
- **No verification.** Rolling back without checking it worked.
- **No "what is not rolled back" section.** Surprises after rollback
  (data state, consumer behaviour) become incidents themselves.

## Companion skills

- `arch-migration-plan` — per-phase rollback.
- `arch-rollout-strategy` — per-ramp-stage rollback.
- `devops-release-management` — overall policy.
- `devops-incident-runbook` — rollback drills.
