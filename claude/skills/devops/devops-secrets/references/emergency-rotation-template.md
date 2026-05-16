# Emergency Rotation Runbook — <secret class>

**Severity:** SEV1 (treat all leak suspicions as SEV1 until
scope is bounded)
**First responder:** <security on-call rotation>
**Owner team:** <team>
**Last reviewed:** YYYY-MM-DD
**Last game-day rehearsal:** YYYY-MM-DD

---

## Trigger

Fire this runbook when ANY of:

- Secrets scanner reports a finding in committed code or logs.
- Public source spotted (gist, paste site, public repo).
- Vault audit shows unauthorized read.
- Vendor reports compromise (Stripe / SendGrid / GitHub / etc.).
- Employee with access departs unexpectedly.
- "Just to be safe" — when in doubt, rotate.

---

## 1. Identify scope (≤5 min)

**Which secret?** Identify the specific secret name in the
vault.

**Which services use it?** Query the vault access policy:

```bash
# AWS Secrets Manager example
aws secretsmanager describe-secret --secret-id <name>
# Inspect the resource policy for principals
```

**What does the secret grant?**

- Database access? Which DB, which permissions?
- API access? Which API, which scopes?
- Infrastructure access? Which IAM role, which actions?

**Exposure window:** When could the secret have leaked vs. when
was it last rotated?

---

## 2. Generate new secret (≤5 min)

```bash
# AWS Secrets Manager example
aws secretsmanager rotate-secret --secret-id <name> --rotation-lambda-arn <arn>
# Or manual:
aws secretsmanager update-secret --secret-id <name> --secret-string '<new-value>'
```

If the secret is a database password:

```bash
# Update in DB first, then in vault:
psql -c "ALTER USER <user> WITH PASSWORD '<new>';"
aws secretsmanager update-secret --secret-id <name> --secret-string '<new>'
```

If the secret is a vendor API key:

- Rotate via vendor console / API.
- Capture new value.
- Update vault.

---

## 3. Roll out new secret (5–30 min)

**Strategy depends on the service architecture:**

### Strategy A — All services parallel (fast, brief disruption)

```bash
# Restart all consuming services to pick up new secret
kubectl rollout restart deployment/<service-1> deployment/<service-2> -n prod
# Verify
kubectl rollout status deployment/<service-1> -n prod
```

### Strategy B — Rolling (zero-downtime, slower)

Service must support secret-refresh without restart (most
modern apps do via SDK):

```bash
# Trigger refresh via vault SDK or signal
kubectl exec deployment/<service-1> -n prod -- /app/refresh-secrets
```

### Strategy C — Sequential (high-stakes, careful)

For services where simultaneous rotation could break
inter-service auth: rotate in dependency order.

---

## 4. Revoke old secret (≤5 min)

```bash
# Mark old version as deprecated in vault
aws secretsmanager update-secret-version-stage \
  --secret-id <name> \
  --version-stage AWSPREVIOUS \
  --move-to-version-id <old-version-id>

# Or delete entirely if confident no consumer is on old
aws secretsmanager delete-secret --secret-id <old-name> --recovery-window-in-days 7
```

For vendor secrets: revoke at the vendor (Stripe / SendGrid /
GitHub).

---

## 5. Audit access during exposure window (≤30 min)

Query the audit log:

```bash
# Example for AWS CloudTrail
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=<secret-name> \
  --start-time <exposure-start> \
  --end-time <rotation-time>
```

For each access:

- Was the principal expected? (Service / known operator)
- Was the time / IP expected?
- Were there reads followed by suspicious activity downstream?

If anything looks suspicious → escalate to security incident
(`devops-incident-runbook` security class).

---

## 6. Verify all consumers on new secret (≤15 min)

For each consuming service:

- Health check passing.
- No auth errors in logs.
- No spikes in vault access errors.

Dashboard: <link to secrets-health dashboard from `devops-
observability`>

---

## 7. Communication

**Internal (immediate):**

> Rotating <secret name> due to <reason>. ETA <minutes>.
> Will update when complete.

**External (if customer impact possible):**

- Hand off to `arch-breaking-change-comms` for customer email
  + status page.
- Disclosure timeline per project compliance regime.

---

## 8. Postmortem (within <N> business days)

Required for any rotation triggered by:

- Confirmed leak (any public exposure).
- Unauthorized access in audit.
- Vendor-reported compromise.

Optional but recommended for:

- Departure-triggered rotation (process review).
- "Just to be safe" rotation (review what trigger should be
  formalised).

Use [postmortem-template.md](../../devops-incident-runbook/references/postmortem-template.md).

---

## Game-day plan

**Last rehearsal:** YYYY-MM-DD

**Next rehearsal:** YYYY-MM-DD (quarterly)

**Failure injection:** rotate a non-critical secret in staging
following this procedure end-to-end.

**Success criteria:**

- All steps completable from this runbook (no improvisation).
- Total time within <X> minutes.
- All consuming services healthy after rotation.

---

## Change log

| Date | Change | By |
|---|---|---|
| YYYY-MM-DD | initial | <name> |
