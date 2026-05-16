# Rollback Scripts Cookbook

Verbatim rollback patterns per deploy system. Save under
`scripts/rollback/` in the project; reference from the rollout
strategy and from each phase's runbook.

## Pattern 1 — Kubernetes (kubectl)

`scripts/rollback/kubectl-rollout-undo.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail
# Required context: KUBECONFIG=<env>
# Required role: deployer
# Expected duration: 30-90s

SERVICE="${1:-api}"
NAMESPACE="${2:-prod}"

echo "Rolling back deployment/${SERVICE} in ${NAMESPACE}..."
kubectl rollout undo "deployment/${SERVICE}" -n "${NAMESPACE}"

echo "Waiting for rollout to complete..."
kubectl rollout status "deployment/${SERVICE}" -n "${NAMESPACE}" --timeout=120s

echo "Verifying pods are Running..."
kubectl get pods -n "${NAMESPACE}" -l "app=${SERVICE}"

echo "Rollback complete."
```

## Pattern 2 — Argo Rollouts (traffic split)

`scripts/rollback/argo-rollback.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:-api}"
NAMESPACE="${2:-prod}"

echo "Aborting current rollout for ${SERVICE}..."
kubectl argo rollouts abort "${SERVICE}" -n "${NAMESPACE}"

echo "Promoting stable revision..."
kubectl argo rollouts undo "${SERVICE}" -n "${NAMESPACE}"

echo "Verifying status..."
kubectl argo rollouts get rollout "${SERVICE}" -n "${NAMESPACE}"
```

## Pattern 3 — ECS service rollback

`scripts/rollback/ecs-rollback.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

CLUSTER="${1:?cluster required}"
SERVICE="${2:?service required}"
PREV_TASK_DEF="${3:?previous task definition ARN required}"

echo "Reverting ${SERVICE} to ${PREV_TASK_DEF}..."
aws ecs update-service \
  --cluster "${CLUSTER}" \
  --service "${SERVICE}" \
  --task-definition "${PREV_TASK_DEF}" \
  --force-new-deployment

echo "Waiting for service to stabilize..."
aws ecs wait services-stable --cluster "${CLUSTER}" --services "${SERVICE}"

echo "Rollback complete."
```

## Pattern 4 — Lambda alias shift

`scripts/rollback/lambda-alias-rollback.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

FN="${1:?function name required}"
PREV_VERSION="${2:?previous version required}"

echo "Shifting alias 'prod' on ${FN} to version ${PREV_VERSION}..."
aws lambda update-alias \
  --function-name "${FN}" \
  --name prod \
  --function-version "${PREV_VERSION}"

echo "Verifying..."
aws lambda get-alias --function-name "${FN}" --name prod
```

## Pattern 5 — Cloud Run revision

`scripts/rollback/cloudrun-rollback.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:?service required}"
REGION="${2:?region required}"
PREV_REVISION="${3:?previous revision required}"

echo "Shifting traffic to ${PREV_REVISION}..."
gcloud run services update-traffic "${SERVICE}" \
  --to-revisions "${PREV_REVISION}=100" \
  --region "${REGION}"

echo "Verifying..."
gcloud run services describe "${SERVICE}" --region "${REGION}" \
  --format='value(status.traffic)'
```

## Pattern 6 — Feature flag disable (LaunchDarkly)

`scripts/rollback/ld-flag-disable.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

FLAG="${1:?flag key required}"
PROJECT="${2:-default}"
LD_API_KEY="${LD_API_KEY:?must be set}"

echo "Disabling flag ${FLAG} in production..."
curl -sf -X PATCH \
  -H "Authorization: ${LD_API_KEY}" \
  -H "Content-Type: application/json" \
  "https://app.launchdarkly.com/api/v2/flags/${PROJECT}/${FLAG}" \
  -d '[{"op":"replace","path":"/environments/production/on","value":false}]'

echo "Verifying flag state..."
curl -sf -H "Authorization: ${LD_API_KEY}" \
  "https://app.launchdarkly.com/api/v2/flags/${PROJECT}/${FLAG}" \
  | jq '.environments.production.on'
```

## Pattern 7 — Istio VirtualService weight reset

`scripts/rollback/istio-weight-reset.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

SERVICE="${1:?service required}"
NAMESPACE="${2:-prod}"

kubectl apply -n "${NAMESPACE}" -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: ${SERVICE}
spec:
  hosts: [${SERVICE}]
  http:
  - route:
    - destination:
        host: ${SERVICE}
        subset: stable
      weight: 100
EOF

echo "Verifying..."
kubectl get vs -n "${NAMESPACE}" "${SERVICE}" -o yaml | grep -A2 weight
```

## Script discipline

Every rollback script must:

1. **Be idempotent** — running twice doesn't break state.
2. **Use `set -euo pipefail`** — fail fast.
3. **Require explicit args** — never assume context.
4. **Include verification** — exit only after confirming rollback.
5. **Be committed in the repo** — `scripts/rollback/` directory.
6. **Be game-day rehearsed** — quarterly.

A rollback script that hasn't been rehearsed within the last
quarter is suspect. Mark it `untested` in the cookbook until
rehearsed.
