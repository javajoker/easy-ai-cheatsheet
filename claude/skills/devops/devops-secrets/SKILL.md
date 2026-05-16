---
name: devops-secrets
description: Designs the secrets management policy + scaffolds the integration code — choice of vault (AWS Secrets Manager / GCP Secret Manager / HashiCorp Vault / Doppler / 1Password / Infisical), per-class rotation cadence, least-privilege access policy, audit log location with anomaly alerts, and an emergency rotation runbook for when a secret leaks. Outputs secrets-policy.md, IaC modules for the chosen vault, CI integration code (CI consumes secrets at runtime, never bakes into images), and an emergency-rotation.md procedure tied into devops-incident-runbook. Use this skill when the user says "set up secrets management", "we need a vault", "rotate the secrets", "design the secrets policy", "what happens when a key leaks", "audit our secret access". Pairs with devops-iac (vault provisioned via IaC), with devops-security-hardening (secrets scan + rotation), with devops-ci-cd (CI pulls secrets at runtime from vault), with devops-incident-runbook (emergency rotation is a runbook), and with devops-observability (secret access anomalies alert here).
status: shipped
owner_agent: devops-engineer
---

# DevOps Secrets

Secrets policy + the scaffolds that enforce it. Sprawling,
unrotated secrets are the most-common preventable security
failure; this skill makes policy mandatory and rotation
automatic.

> **The day a secret leaks is the wrong day to design rotation.**
> The emergency rotation runbook exists *before* the leak so
> the team isn't designing under pressure.

## Why this exists

Secret-management failures are predictable:

1. **Secrets in code / env / repo.** Auto-scanned by attackers
   within hours. Top breach vector.
2. **Never-rotated long-lived keys.** Service account from 2021
   still in use; access from former employees never revoked.
3. **Same secret everywhere.** Database password reused across
   services; one leak compromises everything.
4. **Ambient access.** Every service can read every secret
   because access policy was "easier without restrictions".
5. **No audit.** A secret leaks; nobody knows when it last
   worked legitimately vs. when the attacker started using it.
6. **Emergency improvisation.** Leak detected; team improvises;
   rotation takes hours; meanwhile attacker still has access.

This skill ships a policy + the code to enforce it + the
runbook for when things go wrong.

## When to fire

Fire when:

- The user asks *"set up secrets management"*, *"we need a
  vault"*, *"rotate secrets"*, *"design the secrets policy"*.
- A new project is preparing for prod and has no vault yet.
- `devops-security-hardening` surfaces a secrets-related FAIL.
- A secret leaks and the team needs the emergency rotation
  runbook (use the runbook; do not redesign).

Do **not** fire when:

- The user wants a one-off secret stored (just store it via
  the existing vault).
- The vault already exists and the team is happy — offer to
  *audit* via `requirement-audit`.

## Inputs

Required:

- `INSTRUCTIONS/projects/<slug>/project-context.md` — cloud +
  stack.

Asked once (cap at 3):

1. **Vault choice.** Recommendations per cloud:
   - AWS: AWS Secrets Manager (default) or HashiCorp Vault.
   - GCP: GCP Secret Manager (default).
   - Azure: Azure Key Vault (default).
   - Multi-cloud / opinionated: HashiCorp Vault, Doppler,
     Infisical, 1Password.
2. **Compliance constraints.** Any regime that constrains
   choice (FedRAMP, HIPAA-BAA, SOC2-attested).
3. **Existing secrets to migrate.** None / few / many. Drives
   migration plan effort.

## The opinionated policy

### Secret classes

| Class | Examples | Rotation cadence |
|---|---|---|
| **Long-lived** | DB master password, root API keys | 90d |
| **Short-lived** | Service-to-service tokens | 24h (or per-request) |
| **One-time** | Magic-link tokens, password-reset tokens | per use, expire ≤1h |
| **External** (3rd party) | Stripe key, SendGrid key, OAuth client secret | 90d or per vendor recommendation |
| **Bootstrap** (CI / infra) | CI access tokens, IaC service account | 30d |

Every secret has a class. Unclassified secrets are auto-classified
as long-lived (safest default).

### Access policy

**Least privilege:**

- Each service can read only the secrets it needs.
- Cross-service access requires explicit grant.
- Human read access is exceptional (incident response,
  rotation); audited per access.

**Implemented via:**

- AWS IAM resource policies on Secrets Manager.
- GCP IAM bindings on Secret Manager.
- Vault policies (HCL).
- Doppler / Infisical / 1Password access groups.

### Audit log

Every secret access logged with:

- Timestamp (UTC).
- Principal (service / human ID).
- Secret name (not value).
- Outcome (success / denied / error).
- Source (IP / pod / CI run ID).

Logs ingested into the chosen observability stack (`devops-
observability`). Anomaly alerts:

- Off-hours human read.
- Unusual principal accessing a secret.
- High-frequency access (rate spike).
- Read failure spikes (attempted unauthorized access).

### Storage discipline

- **Never** in source control (.env, config files, comments).
- **Never** in container images (env vars baked at build).
- **Never** in CI variables that aren't marked as secrets.
- **Always** retrieved at runtime from vault.
- **Always** decrypted in memory only; never written to disk.
- **Always** redacted in logs (CI mask discipline).

### Emergency rotation runbook

When a secret leaks (or is suspected to have leaked), the
runbook fires:

1. **Identify scope.** Which secret; which services use it;
   what access it grants.
2. **Generate new secret.** In the vault.
3. **Roll out new secret.** Per service, in order (most-critical
   service first or all-in-parallel depending on dependency
   shape).
4. **Revoke old secret.** Disable in the vault; revoke at the
   provider (Stripe, OAuth, etc.).
5. **Audit access during exposure window.** From the audit log,
   who used this secret between exposure time and rotation.
6. **Postmortem.** Per `devops-incident-runbook`.

The runbook is documented per secret class; the team has
practiced it via game day (see `devops-incident-runbook`).

## The procedure

### Phase 1 — Choose the vault

Per inputs. The choice is documented with rationale (cloud fit,
compliance, cost, team familiarity).

### Phase 2 — Scaffold the vault via IaC

Hand off to `devops-iac` to provision the vault + its access
infrastructure:

- The vault itself (or namespace within an existing vault).
- IAM / policies for service principals.
- Audit log destination.
- Cross-region replication (if applicable).

The vault is in its own Terraform module, applied early in the
infrastructure lifecycle (before any service that needs
secrets).

### Phase 3 — Classify existing secrets

If the project has existing secrets (env files, config files):

- Enumerate every secret.
- Classify per the table.
- Migrate to the vault.
- Remove from old locations.
- Scan git history with `gitleaks` to verify removal.
- For secrets that were in history: assume compromised; rotate
  via the emergency procedure.

### Phase 4 — Application integration

Per language, scaffold the secret-fetching helper:

- **Node:** `@aws-sdk/client-secrets-manager` (or chosen
  vendor SDK); helper module `src/lib/secrets.ts`.
- **Python:** `boto3` (or vendor SDK); helper module
  `app/lib/secrets.py`.
- **Go:** AWS / GCP SDK; helper package `internal/secrets/`.
- **Java:** Vendor SDK; helper class
  `com.<org>.secrets.SecretsClient`.

Helper enforces:

- Read at startup or on-demand (depending on secret class).
- Cache with short TTL (matches secret class — long-lived can
  cache for minutes; short-lived per-request).
- Refresh on rotation event (vault webhook or polling).
- Never log secret values.

### Phase 5 — CI integration

Hand off to `devops-ci-cd` to:

- Configure CI's vault access (service principal with read-only
  on CI-needed secrets).
- Replace any plaintext CI variables with vault references.
- Mask secrets in CI logs.
- Audit CI secret access in the unified audit log.

### Phase 6 — Rotation automation

Per class:

- **Long-lived (90d):** automated rotation via vault's
  rotation Lambda / function (AWS Secrets Manager pattern);
  schedule check that age <90d alerts at 80d.
- **Short-lived (24h):** rotation built into service auth flow.
- **External (90d):** rotation requires vendor API; scripted
  where vendor supports; manual + scheduled where they don't.
- **Bootstrap (30d):** rotation is infrastructure-as-code
  change; scheduled via release calendar.

### Phase 7 — Emergency rotation runbook

Write the runbook(s) — one per secret class, since the
mechanics differ:

- Use [references/emergency-rotation-template.md](references/emergency-rotation-template.md).
- Lives under `runbooks/secrets/<class>.md`.
- Cross-linked from `devops-incident-runbook` index.
- Game-day rehearsed quarterly.

### Phase 8 — Write the policy

Write `secrets-policy.md` using
[references/secrets-policy-template.md](references/secrets-policy-template.md).

The policy is canonical; every project that adopts the framework
references it; deviations are documented per project.

Persist as `type: project` memory (`secrets_policy_<slug>_v1`).

## Anti-patterns

- **`.env` in `.gitignore` is not security.** A single
  forgotten commit and the secret is in history forever. Use a
  vault.
- **"We rotate when someone leaves."** Rotation must be
  automatic and scheduled; departure-driven rotation misses
  service accounts.
- **One secret for everything.** Same DB password in dev /
  staging / prod is a single compromise = total breach.
  Per-environment secrets.
- **Vault as glorified env file.** Secrets in vault but never
  rotated, never audited, no access policy = config file with
  extra steps.
- **Human-readable secret names that leak.** `stripe_prod_key`
  in audit log → attacker learns infrastructure. Use opaque
  names (`secret_a1b2c3`); look up via mapping doc.
- **No emergency procedure.** Designing rotation during a leak
  is panic engineering. Procedure exists before the leak.
- **Untested emergency procedure.** Quarterly game day — same
  as `devops-incident-runbook`.

## Companion skills

- `devops-iac` — vault provisioned via IaC.
- `devops-security-hardening` — secrets scan + audit; this
  skill provides the rotation policy.
- `devops-ci-cd` — CI consumes secrets via vault.
- `devops-incident-runbook` — emergency rotation runbook ties
  in.
- `devops-observability` — secret access anomalies surface
  here.
- `requirement-audit` — verify rotation schedule + access
  policy quarterly.

## Reference files

- [references/secrets-policy-template.md](references/secrets-policy-template.md) —
  canonical policy document.
- [references/emergency-rotation-template.md](references/emergency-rotation-template.md) —
  per-class emergency rotation runbook.
- `references/per-vault-cookbook.md` — setup patterns per vault
  vendor (AWS / GCP / Azure / HashiCorp / Doppler /
  Infisical / 1Password).
- `references/classification-decision-tree.md` — how to classify
  a new secret.
