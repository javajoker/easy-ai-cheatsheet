# Secrets Policy — <project>

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Status:** active | draft | superseded
**Next review:** YYYY-MM-DD (annual)

---

## Vault choice

**Chosen vault:** AWS Secrets Manager | GCP Secret Manager | Azure Key Vault | HashiCorp Vault | Doppler | 1Password | Infisical

**Rationale.** <one paragraph: cloud fit, compliance, cost, team familiarity>

**Compliance constraints addressed.** <e.g. HIPAA-BAA / FedRAMP / SOC2-attested>

---

## Secret classes + rotation cadence

| Class | Examples | Rotation cadence | Rotation method |
|---|---|---|---|
| Long-lived | DB master password, root API keys | 90d | Automated (Lambda / vault rotation) |
| Short-lived | Service-to-service tokens | 24h | Built into service auth flow |
| One-time | Magic links, password reset | per use, expire ≤1h | Per-token; expire on use |
| External (3rd party) | Stripe key, SendGrid, OAuth client secret | 90d or vendor recommendation | Scripted via vendor API where supported; manual + scheduled where not |
| Bootstrap | CI access tokens, IaC service account | 30d | Scheduled IaC change |

**Unclassified secrets auto-classified as long-lived** (safest
default).

---

## Access policy (least privilege)

### Service principals

Each service can read **only the secrets it needs**:

| Service | Secrets it can read |
|---|---|
| `api` | `db/api-conn`, `stripe/secret`, `jwt/signing-key` |
| `worker` | `db/api-conn`, `queue/auth` |
| `frontend` | (none — uses public API only) |

### Human principals

- **Engineers:** read access to development secrets only.
- **On-call:** elevated access during active incident (audited
  + time-bound).
- **Security team:** audit access to all secrets (read metadata,
  not values).
- **Vault admin:** named individuals; rotated quarterly.

### Cross-service access

Requires explicit grant + documented use case. Reviewed quarterly.

---

## Audit log

**Destination:** <e.g. CloudWatch Logs / Cloud Logging / Splunk>

**Retention:** <e.g. 7 years for regulated; 1 year for others>

**Fields logged:**

- timestamp (UTC, ISO 8601)
- principal_id (service / human)
- secret_name (not value)
- outcome (success / denied / error)
- source (IP / pod / CI run ID)
- correlation_id

**Anomaly alerts (routed to security on-call):**

- Off-hours human read (any sensitive secret outside business hours)
- Unusual principal accessing a secret (not in historical pattern)
- High-frequency access (rate spike vs. baseline)
- Read failure spike (probing)

---

## Storage discipline

| What | Rule |
|---|---|
| `.env` files in repo | ❌ never |
| Secrets in container images | ❌ never (env vars baked at build) |
| Secrets in CI variables (unmasked) | ❌ never |
| Secrets in logs | ❌ never (redact at emit time) |
| Secrets on disk | ❌ never (memory only) |
| Vault retrieval at runtime | ✅ always |

**Pre-commit hook** (gitleaks / trufflehog) scans for accidental
commits.

**CI pipeline** (gitleaks step) is a required check on every PR.

---

## Emergency rotation

When a secret leaks or is suspected to have leaked:

1. **Identify scope** (≤5 min) — which secret, which services
   use it, what access it grants.
2. **Generate new secret** in vault (≤5 min).
3. **Roll out new secret** to all consumers (5–30 min depending
   on strategy).
4. **Revoke old secret** at vault + vendor (≤5 min).
5. **Audit access during exposure window** — identify any
   unauthorised use.
6. **Postmortem** if confirmed leak.

See [`devops-secrets/references/emergency-rotation-template.md`](emergency-rotation-template.md)
for the verbatim runbook.

**Game day cadence:** quarterly. Practise rotation on a non-
critical secret in staging.

---

## Incident response (suspected leak)

- **Trigger:** scanner finding, public source spotted (gist /
  paste), vault audit anomaly, vendor compromise report,
  unexpected employee departure.
- **Default action:** rotate the secret following the emergency
  rotation runbook. **When in doubt, rotate.**
- **Cost of false-positive rotation:** low.
- **Cost of missed leak:** high.

---

## Annual review

The policy is reviewed annually:

- [ ] Vault choice still appropriate (no migration warranted).
- [ ] Rotation cadences still appropriate (no class drift).
- [ ] Access policy still aligned with org / team structure.
- [ ] Audit log retention compliant with regulations.
- [ ] Emergency rotation runbook game-day-rehearsed.
- [ ] No accumulated waivers / exceptions.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial lock | <name> |
