# OWASP Top 10 (2024) — Evidence Patterns

What evidence looks like per OWASP item. Each row in the
security-baseline gets one of these evidence shapes.

## A01 — Broken Access Control

**What to prove.** Default deny at API boundaries; object-level
authz; horizontal + vertical privilege checks.

**Evidence patterns:**

- Code review notes pointing at authorization middleware
  consistently applied (file paths + line ranges).
- Integration tests: at least one per role × at least one per
  resource type. `test_user_cannot_access_admin_endpoint`, etc.
- IDOR test: explicitly try to access another user's resource
  by ID manipulation.
- RBAC matrix doc with current state.

## A02 — Cryptographic Failures

**What to prove.** Strong algorithms; proper key management; TLS;
no roll-your-own crypto.

**Evidence patterns:**

- Password hashing config: bcrypt cost ≥12 / argon2 with modern
  params.
- TLS scan (`ssllabs-scan` / `testssl.sh`) result attached.
- Keys stored in vault, not in code (cross-reference with secrets
  scan).
- No `random.random()` for security tokens (use `secrets` /
  `crypto.randomBytes` / `os.urandom`).
- HTTPS-only via HSTS + redirect at LB.

## A03 — Injection

**What to prove.** Parameterized queries; output encoding; no
shell injection.

**Evidence patterns:**

- ORM / prepared statements throughout (grep proves: no
  `f"SELECT ... {user_input}"` or `cursor.execute(query + var)`).
- SAST scan (Semgrep `python.lang.security.injection` ruleset)
  green.
- Template auto-escaping enabled (Jinja2 `autoescape=True`,
  React JSX, etc.).
- Shell calls use array form (`subprocess.run([...], shell=False)`),
  never string concat.

## A04 — Insecure Design

**What to prove.** Threat model exists; security requirements
documented; defence in depth.

**Evidence patterns:**

- Threat model document (STRIDE / attack tree / data-flow
  diagram with trust boundaries).
- Security requirements in PRD or design doc.
- Architecture review notes showing security considered.
- This is the row most often FAIL or PARTIAL — design-time
  security is often an afterthought.

## A05 — Security Misconfiguration

**What to prove.** Hardened defaults; no default credentials; no
unnecessary features enabled; error pages don't leak.

**Evidence patterns:**

- IaC review: no public S3 buckets, no `0.0.0.0/0` SGs except
  LB ingress.
- Container scan (Trivy): no high-severity findings on base
  image.
- Configuration audit: dev defaults overridden in prod
  (`DEBUG=False`, etc.).
- Error pages don't include stack traces / internal info.
- Admin / debug endpoints disabled in prod.

## A06 — Vulnerable + Outdated Components

**What to prove.** Dep scan, SBOM, patch SLA.

**Evidence patterns:**

- Cross-reference with section 1 (SBOM) + section 2 (dep
  vulnerability scan).
- Documented patch SLA (e.g. critical within 7d; high within
  30d).
- Renovate / Dependabot enabled with auto-merge for minor
  patches.

## A07 — Identification + Authentication Failures

**What to prove.** Strong session management; MFA; rate limiting;
credential security.

**Evidence patterns:**

- Cross-reference with section 4 (authentication).
- Session timeout enforced server-side.
- "Log out everywhere" verified to invalidate all sessions.
- Failed-login rate limiting (lockout / captcha / exponential
  backoff).

## A08 — Software + Data Integrity Failures

**What to prove.** Signed artifacts; integrity checks on
deserialization; secure pipelines.

**Evidence patterns:**

- Artifact signing (Sigstore / cosign / GPG) on container
  images / package builds.
- SLSA level documented (e.g. SLSA 2+ for production releases).
- Pipeline IaC reviewed for tamper-resistance (branch
  protection, signed commits where applicable).
- No `pickle.load` / `yaml.load` on untrusted input (use
  `yaml.safe_load`).
- Webhook payloads verified via signature.

## A09 — Security Logging + Monitoring Failures

**What to prove.** Security events logged + alerted; audit trail
complete.

**Evidence patterns:**

- Auth events (login, logout, password change, role change,
  privileged actions) logged with principal + IP + outcome.
- Failed-login alert configured.
- Privilege-escalation alert configured.
- Log retention compliant with project's regulatory regime.
- Cross-reference with `devops-observability` audit log
  configuration.

## A10 — Server-Side Request Forgery (SSRF)

**What to prove.** No unfiltered URL-based request emitted from
server-side code.

**Evidence patterns:**

- URL allowlist / denylist for any feature that fetches user-
  provided URLs.
- Block IMDS access (AWS: deny 169.254.169.254 at egress; or use
  IMDSv2).
- Block internal CIDR (10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16,
  127.0.0.0/8) for any user-provided URL fetch.
- DNS resolution after fetch (re-resolve to prevent DNS rebinding).
- SAST scan for the `requests.get(user_url)` anti-pattern.

---

## Evidence quality

Each evidence pointer should be:

- **A file path + line range** (most-specific), OR
- **A scan report URL + timestamp** (auto-generated; freshness
  matters), OR
- **A test path** (proof-by-existence-of-passing-test), OR
- **A named approver + date** (when human judgement is the
  source).

Vague evidence (*"we do this"*, *"it's handled"*) is rejected.
Promote to PARTIAL if you can name the gap; demote to FAIL if
you can't.

---

## Patterns that signal PARTIAL or FAIL

| Pattern | Likely status | Why |
|---|---|---|
| "We're working on it" | FAIL | Not done |
| "It's covered by the framework" | PARTIAL | Verify configuration is actually correct |
| "Engineers know to do this" | FAIL | Tribal knowledge ≠ enforcement |
| Single example file with the right pattern | PARTIAL | Verify consistency across codebase |
| Architecture decision doc but no code check | PARTIAL | Decision without enforcement drifts |
| Passing scan with no clear coverage | PARTIAL | Verify what was scanned |

The auditor's job is to **distinguish performance from
enforcement**. Performance: *"we do this"*. Enforcement:
*"violations are detected automatically"*.
