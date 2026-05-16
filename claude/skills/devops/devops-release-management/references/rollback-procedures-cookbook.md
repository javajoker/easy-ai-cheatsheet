# Rollback Procedures Cookbook — by stack

Verbatim rollback procedures per common stack. Use as templates;
adapt to project.

This cookbook lives alongside [arch-rollout-strategy's
rollback-scripts-cookbook](../../../architecture/arch-rollout-strategy/references/rollback-scripts-cookbook.md)
— that file focuses on per-deploy-system patterns; this file
focuses on per-stack release-management rollback.

## Mode 1 — Reverse deploy (fastest)

### Kubernetes-deployed services

```bash
# Required context: KUBECONFIG=<prod>
# Approver: <role>
# Duration: 30-90s

kubectl rollout undo deployment/<service> -n prod
kubectl rollout status deployment/<service> -n prod --timeout=120s
kubectl get pods -n prod | grep <service>
```

### ECS-deployed services

```bash
aws ecs update-service \
  --cluster <cluster> \
  --service <service> \
  --task-definition <previous-task-def-arn> \
  --force-new-deployment
aws ecs wait services-stable --cluster <cluster> --services <service>
```

### Lambda

```bash
aws lambda update-alias \
  --function-name <fn> \
  --name prod \
  --function-version <previous-version>
```

### Cloud Run

```bash
gcloud run services update-traffic <service> \
  --to-revisions <previous-revision>=100 \
  --region <region>
```

### Vercel / Netlify / Cloudflare Pages

```bash
# Vercel
vercel rollback <previous-deployment-url> --token $VERCEL_TOKEN

# Netlify (via UI typically; or)
netlify api restoreSiteDeploy --data '{"site_id":"<site>","deploy_id":"<prev>"}'
```

---

## Mode 2 — Revert + redeploy

When reverse-deploy isn't viable (config changes intertwined with
code changes; secret rotated; can't use previous artifact).

```bash
# Find the offending commit
git log --oneline -20

# Revert (creates new commit; preserves history)
git revert <bad-sha>

# Push; CI builds + deploys
git push origin main

# Wait for staging deploy + smoke
# Then approve prod deploy via normal pipeline
```

For multiple commits to revert:

```bash
# Revert range (newest to oldest)
git revert <newest-bad-sha>..<oldest-bad-sha>

# Or interactive revert
git revert -i HEAD~3..HEAD
```

**Note:** revert preserves history (audit trail). Never `git reset
--hard` on main.

---

## Mode 3 — Forward fix

When rollback is impossible:

- Data migrated (write cutover passed).
- Customer data committed via new path.
- Breaking change already consumed by external integrations.

### Procedure

1. **Declare incident** via `devops-incident-runbook`.
2. **Hotfix branch** from main:
   ```bash
   git checkout main && git pull
   git checkout -b hotfix/<issue-slug>
   ```
3. **Fix the bug** + tests.
4. **Expedited review** — 1 approval; senior engineer notified.
5. **Deploy** via standard chain (faster cadence allowed under
   incident protocol).
6. **Postmortem** within N business days.

---

## DB schema rollback patterns

### Pattern A — Pure column add (safe rollback)

```sql
-- Add (forward)
ALTER TABLE <table> ADD COLUMN <new_col> <type>;

-- Rollback (if no production code wrote to it yet)
ALTER TABLE <table> DROP COLUMN <new_col>;
```

### Pattern B — Column rename (multi-phase; rollback per phase)

```sql
-- Phase 1: Add new column alongside
ALTER TABLE <table> ADD COLUMN <new_name> <type>;

-- Rollback Phase 1
ALTER TABLE <table> DROP COLUMN <new_name>;

-- Phase 2: Backfill (dual-write)
UPDATE <table> SET <new_name> = <old_name>;
-- Application now writes to both

-- Rollback Phase 2: just stop dual-write; old column still authoritative

-- Phase 3: Switch reads
-- Application reads from new column; writes to both
-- Rollback Phase 3: revert app config; old column still has data

-- Phase 4: Stop writing to old
-- Rollback Phase 4: revert app to write to both columns

-- Phase 5: Drop old column (final, irreversible)
ALTER TABLE <table> DROP COLUMN <old_name>;
-- Rollback: restore from backup (data loss)
```

### Pattern C — Data migration (irreversible)

See `arch-migration-plan/references/non-reversibility-traps.md`
Trap 2 for the safe multi-phase decomposition.

---

## Feature flag rollback

```bash
# LaunchDarkly
curl -X PATCH \
  -H "Authorization: $LD_API_KEY" \
  https://app.launchdarkly.com/api/v2/flags/<project>/<flag> \
  -d '[{"op":"replace","path":"/environments/production/on","value":false}]'

# Flagsmith
curl -X PUT \
  -H "Authorization: Token $FLAGSMITH_API_KEY" \
  https://api.flagsmith.com/api/v1/environments/<env>/featurestates/<flag>/ \
  -d '{"feature_state_value":false,"enabled":false}'

# Unleash
curl -X POST \
  -H "Authorization: $UNLEASH_API_KEY" \
  https://<unleash-host>/api/admin/projects/default/features/<flag>/environments/production/off
```

---

## Verification after rollback

Every rollback ends with:

- [ ] Dashboard `<url>` — metrics back to baseline.
- [ ] Sample request: `curl <prod-endpoint>` returns 200.
- [ ] Error rate dashboard returns to baseline (visible within
      5 min).
- [ ] At least one synthetic user flow passes.
- [ ] Internal comms posted to `#deploys`.
- [ ] Status page updated if customer-visible.

---

## What's NOT rolled back

Always document explicitly:

- Data written via new path stays written.
- Cache entries from new behaviour persist until TTL.
- Events emitted from new code stay in event log.
- Audit trail entries from the failed forward + rollback.
- Customer-visible state that consumers may already have seen.

---

## See also

- [`arch-rollout-strategy/references/rollback-scripts-cookbook.md`](../../../architecture/arch-rollout-strategy/references/rollback-scripts-cookbook.md)
  — per-deploy-system rollback scripts.
- [`arch-migration-plan/references/non-reversibility-traps.md`](../../../architecture/arch-migration-plan/references/non-reversibility-traps.md)
  — changes that look reversible but aren't.
- [`devops-incident-runbook/references/runbook-template.md`](../../devops-incident-runbook/references/runbook-template.md)
  — runbook structure for incidents triggered by rollback need.
