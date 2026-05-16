# Rollback Procedure Patterns

Verbatim rollback patterns for common deploy systems. Use as
templates; adapt to project specifics.

## Pattern A — Kubernetes Deployment

```bash
# Required context: KUBECONFIG=<env>
# Required role: deployer
# Expected duration: 30–90s

kubectl rollout undo deployment/<service> -n <namespace>

# Verify
kubectl rollout status deployment/<service> -n <namespace>
kubectl get pods -n <namespace> -l app=<service>
```

## Pattern B — Kubernetes traffic split (e.g. Argo Rollouts, Istio, Linkerd)

```bash
# Drop canary subset to 0%
kubectl argo rollouts set image <service> <container>=<previous-image> -n <namespace>
kubectl argo rollouts promote <service> -n <namespace>

# OR for Istio
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata: { name: <service>, namespace: <namespace> }
spec:
  http:
  - route:
    - destination: { host: <service>, subset: stable }
      weight: 100
EOF
```

## Pattern C — ECS service rollback

```bash
# Required: AWS_PROFILE=<env>
aws ecs update-service \
  --cluster <cluster> \
  --service <service> \
  --task-definition <previous-task-def-arn> \
  --force-new-deployment

# Verify
aws ecs wait services-stable --cluster <cluster> --services <service>
```

## Pattern D — Lambda alias shift

```bash
aws lambda update-alias \
  --function-name <fn> \
  --name prod \
  --function-version <previous-version>

# Verify
aws lambda get-alias --function-name <fn> --name prod
```

## Pattern E — Cloud Run revision rollback

```bash
gcloud run services update-traffic <service> \
  --to-revisions <previous-revision>=100 \
  --region <region>

# Verify
gcloud run services describe <service> --region <region> --format='value(status.traffic)'
```

## Pattern F — Feature flag disable

```bash
# LaunchDarkly example
curl -X PATCH \
  -H "Authorization: $LD_API_KEY" \
  https://app.launchdarkly.com/api/v2/flags/<project>/<flag> \
  -d '[{"op":"replace","path":"/environments/production/on","value":false}]'

# Verify
curl -H "Authorization: $LD_API_KEY" \
  https://app.launchdarkly.com/api/v2/flags/<project>/<flag> \
  | jq '.environments.production.on'
```

## Pattern G — DB schema add-column rollback (safe)

```sql
-- if the migration only added a column (no data backfill yet)
ALTER TABLE <table> DROP COLUMN <new_column>;

-- verify
\d <table>
```

(Drop-column rollback is safe ONLY if no production code wrote to
the new column yet. See `non-reversibility-traps.md` Trap 1.)

## Pattern H — DNS rollback

```bash
# Route 53 example — revert recordset
aws route53 change-resource-record-sets \
  --hosted-zone-id <zone> \
  --change-batch file://revert.json

# revert.json contains the previous record values
# Note: DNS TTL means propagation can take time; cached lookups
# will continue hitting current value until TTL expires.
```

## Verification template

After every rollback, verify:

1. **Health check** — service `/health` endpoint returns 200.
2. **Sample request** — `curl <prod-endpoint>` returns expected
   shape.
3. **Error rate** — drop in error rate on `<dashboard-url>`.
4. **Customer surface** — at least one synthetic user flow runs
   green.
5. **Communication sent** — internal channel + status page if
   customer-visible.

## What's NOT rolled back

Document explicitly per rollback:

- Data written via new path stays written.
- Cache entries from new behaviour persist until TTL.
- Events emitted from new code stay in event log.
- Audit trail of the failed forward and rollback events.

## See also

- [`non-reversibility-traps.md`](non-reversibility-traps.md)
- [`decomposition-patterns.md`](decomposition-patterns.md)
- [`devops-release-management`](../../../devops/devops-release-management/SKILL.md)'s
  three-tier rollback (reverse-deploy / revert / forward-fix).
