---
name: devops-security-hardening
description: Runs a pre-prod security pass and emits security-baseline.md — SBOM generation + storage, dependency vulnerability scan, secrets scan of git history, auth review (JWT lifetimes / refresh rotation / RBAC), TLS posture, input validation at API boundaries, OWASP top 10 review. Each row PASS / PARTIAL / FAIL with evidence pointers; FAIL rows block prod launch unless explicitly waived. Complements the language-specific *-security skills (which focus on code-level concerns) by focusing on *operational* concerns — build artifacts, runtime configuration, public surface, audit logging. Use this skill when the user says "harden this for prod", "run a security review", "we need an SBOM", "scan for vulnerabilities", "OWASP review". Pairs with gtm-launch-readiness (provides Security category evidence), with language-specific *-security skills (code-level companion), with devops-secrets (rotation policy follows hardening), with devops-ci-cd (scans run in pipeline as required checks), and with arch-breaking-change-comms (vulnerability disclosure if external impact).
status: shipped
owner_agent: devops-engineer
---

# DevOps Security Hardening

The pre-production security gate. Operational security — what
the artifact looks like, what the public surface allows, what
the audit log captures.

> **Code-level security is its own discipline.** Language-
> specific `*-security` skills cover code concerns (injection,
> deserialization, unsafe APIs). This skill covers operational
> concerns. Both pair; both are required.

## Why this exists

Pre-prod security failures are predictable:

1. **No SBOM.** Vulnerability lands in a transitive dependency
   three months later; team has no idea which services include
   it; takes a week to scope the blast radius.
2. **Secrets in repo / history.** API key committed once, never
   removed from history. Auto-scanned and stolen within hours
   of pushing.
3. **Auth defaults.** JWTs with 24h lifetimes, no refresh
   rotation, no session invalidation. One stolen token = days
   of access.
4. **TLS 1.0/1.1 still enabled.** "We forgot to turn off the
   old config." Modern browsers won't even warn; attackers
   notice.
5. **OWASP not actually reviewed.** Each item assumed handled;
   nobody checked.

This skill ships an opinionated baseline checklist with
PASS/PARTIAL/FAIL evidence per row, blocking-grade gates, and
hand-offs to specialist skills for fixes.

## When to fire

Fire when:

- The user asks *"harden this for prod"*, *"run a security
  review"*, *"we need an SBOM"*, *"OWASP review"*.
- `lifecycle-pilot` reaches Phase 6 (launch readiness) and
  needs Security category evidence.
- A pre-existing security baseline needs refresh (≥6 months
  old or after major architectural change).

Do **not** fire when:

- The user is responding to a specific vulnerability — use
  incident-response (`devops-incident-runbook`) flow, not a
  full baseline pass.
- The user wants code-level security review — language-specific
  `*-security` skill.
- The user wants compliance attestation (SOC2, ISO 27001) —
  this skill produces inputs; compliance proper is auditor work.

## Inputs

Required:

- `INSTRUCTIONS/projects/<slug>/project-context.md` — stack +
  compliance regime declarations.
- Repo access to run scans.

Asked once (cap at 3):

1. **Scope.** Whole project / specific service / specific
   release.
2. **Risk profile.** Standard (default) / regulated (HIPAA, PCI,
   SOC2) / public-target (high-profile / political / financial).
   Drives row weighting.
3. **Tooling preference.** Open-source (Trivy / Grype / gitleaks /
   semgrep) — default. SaaS (Snyk / Dependabot / GitGuardian /
   Aqua) — if already in stack.

## The opinionated baseline

Eight categories, ~40 rows. Each row produces PASS / PARTIAL /
FAIL with pointer evidence.

### 1. Software Bill of Materials (SBOM)

- **SBOM generated** at build time (CycloneDX or SPDX format).
- **SBOM stored** in artifact registry alongside the build.
- **SBOM scanned** against known-vulnerability databases (NVD,
  OSV) per release.
- **SBOM retention** matches binary retention (typically 1y).

### 2. Dependency vulnerability scan

- **Direct deps:** 0 critical, 0 high. PARTIAL: high with
  documented mitigation. FAIL: critical or unmitigated high.
- **Transitive deps:** scanned; criticals surfaced.
- **Scan cadence:** every PR + nightly scheduled.
- **Process for new vulns:** documented; named owner; SLA.

### 3. Secrets scan

- **Git history clean.** `gitleaks` / `trufflehog` full-history
  scan returns zero findings.
- **Pre-commit hook** in place (developer-side scan).
- **CI scan** in place (pipeline-side scan).
- **Incident response for leak:** documented; rotation procedure
  ready (see `devops-secrets`).

### 4. Authentication

- **Token lifetimes:** access ≤1h; refresh ≤30d.
- **Refresh rotation:** enabled (refresh tokens single-use).
- **Session invalidation:** server-side; works for "log out
  everywhere".
- **Password hashing:** bcrypt / argon2 / scrypt; modern cost
  parameters; pepper if applicable.
- **MFA:** TOTP / WebAuthn supported (PARTIAL if optional;
  FAIL if not offered).
- **Account lockout / rate limiting** on auth endpoints.

### 5. Authorization (RBAC)

- **RBAC matrix documented.**
- **Per-role integration test** for at least one
  permission-protected action per role.
- **Default deny** at API boundaries.
- **Object-level authorization** verified per access (no IDOR).

### 6. TLS posture

- **TLS 1.3 only** on public endpoints (TLS 1.2 acceptable
  with documented reason).
- **HSTS** header set with `max-age` ≥ 6 months.
- **Cert auto-renewal** working; tested.
- **OCSP stapling** enabled where supported.
- **Cipher suites:** modern (per Mozilla "Intermediate" or
  "Modern" config).
- **Certificate transparency** logs check passes.

### 7. Input validation

- **At every API boundary:** schema validation (zod / pydantic /
  ozzo / similar) — not "if/else checks".
- **CSP** (web frontend): present and restrictive (`default-src
  'self'`).
- **CORS** policy: explicit origins, not `*`.
- **File upload:** content-type + size + magic-number checks.
- **SQL:** parameterized queries only; ORM / prepared
  statements.
- **Output encoding:** XSS-safe in templating layer.

### 8. OWASP Top 10 (2024)

Row per item. PASS / PARTIAL / FAIL with evidence:

- A01 Broken Access Control
- A02 Cryptographic Failures
- A03 Injection
- A04 Insecure Design
- A05 Security Misconfiguration
- A06 Vulnerable + Outdated Components
- A07 Identification and Authentication Failures
- A08 Software + Data Integrity Failures
- A09 Security Logging + Monitoring Failures
- A10 Server-Side Request Forgery

## The procedure

### Phase 1 — Scope

Confirm scope per inputs. If "whole project", enumerate
services to be reviewed.

### Phase 2 — Run automated scans

Run the scan tools per category:

| Category | Tool defaults |
|---|---|
| SBOM | `syft` (generate) + `grype` (scan) |
| Dep vulns | `npm audit` / `pip-audit` / `govulncheck` / OWASP dep-check |
| Secrets | `gitleaks` (history) + pre-commit hook |
| Container | `trivy image` |
| SAST | `semgrep` with default rule packs |
| TLS | `testssl.sh` / `ssllabs-scan` |
| OWASP | partly automated (ZAP baseline scan); partly manual |

Capture outputs as evidence artifacts in `docs/security-audit/
<YYYY-MM-DD>/`.

### Phase 3 — Manual review

Automated scans cover ~60% of rows. Manual review for:

- RBAC matrix walkthrough.
- Auth flow review (refresh rotation, session invalidation).
- Insecure design (A04) — architectural-level concern.
- Custom code paths semgrep doesn't cover.
- Privacy-related rows (PII handling).

### Phase 4 — Per-row classification

For each row in the 8 categories, classify:

- **✅ PASS** — evidence confirms compliance.
- **⚠ PARTIAL** — partial; mitigation documented; owner +
  due date.
- **❌ FAIL** — non-compliant; blocking unless waived.
- **➖ N/A** — does not apply; one-line reason.

### Phase 5 — Emit the baseline

Write `security-baseline.md` using
[references/security-baseline-template.md](references/security-baseline-template.md).

Output shape mirrors `gtm-launch-readiness` (same audit format
the framework uses everywhere).

### Phase 6 — Waiver discipline

A FAIL can be waived only with:

- Named approver (typically CTO / security lead).
- Documented business justification.
- Mitigation in place (compensating control).
- Fix-by date.
- Logged in `docs/security-audit/waivers/`.

Unwaived FAILs block production launch via `gtm-launch-
readiness`.

### Phase 7 — Wire into CI

Hand off to `devops-ci-cd`:

- SBOM generation in build stage.
- Dep + secrets scan in security stage (required check).
- SAST in security stage.
- TLS scan as nightly job against staging.

Recurring failures become alerts via `devops-observability`.

### Phase 8 — Recurrence

Baselines drift. Schedule:

- **Quarterly** full re-audit minimum.
- **After major arch change** — re-audit affected scope.
- **After incident** — re-audit related rows.
- **On new compliance regime** — extend baseline with
  regime-specific rows.

## Anti-patterns

- **Scanning without acting.** SBOMs + scans that produce
  reports nobody reads = decoration. Wire to action.
- **PARTIAL as "we'll fix it later".** PARTIAL requires owner
  + date. Otherwise it's FAIL.
- **Waiver creep.** Waivers accumulate; the baseline becomes
  fiction. Review waiver list at each re-audit; un-waive
  what's been fixed; chase what hasn't.
- **Public-default deployment.** New services default to
  internal-only network; public exposure is a deliberate
  decision per service.
- **"We use TLS"** — version matters. *"TLS"* without version
  = often TLS 1.0/1.1.
- **OWASP as checkbox.** Reviewing OWASP top 10 without
  evidence is theatre. Each row needs evidence.
- **Penetration test as substitute.** Pen tests are
  complementary, not substitutes. Pen-tested ≠ hardened.

## Companion skills

- `gtm-launch-readiness` — consumes evidence as Security
  category.
- Language `*-security` skills — code-level companion.
- `devops-secrets` — rotation follows hardening; leak response
  ties in.
- `devops-ci-cd` — scans run as required checks.
- `arch-breaking-change-comms` — vulnerability disclosure.
- `devops-incident-runbook` — security incident runbooks.
- `requirement-audit` — same audit format.

## Reference files

- [references/security-baseline-template.md](references/security-baseline-template.md) —
  canonical output template.
- `references/scan-tools-cookbook.md` — per-tool config + invocation
  patterns.
- `references/owasp-evidence-patterns.md` — what evidence looks
  like for each OWASP top-10 item.
- `references/waiver-template.md` — waiver document shape.
