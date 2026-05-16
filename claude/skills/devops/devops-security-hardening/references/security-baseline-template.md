# Security Baseline — <project>

**Version:** 1
**Audit date:** YYYY-MM-DD
**Auditor:** <name>
**Next audit:** YYYY-MM-DD (quarterly)
**Status:** draft | locked | superseded
**Risk profile:** standard | regulated | public-target

---

## Summary

| Status | Count |
|---|---|
| ✅ PASS | N |
| ⚠ PARTIAL | M |
| ❌ FAIL | K |
| ➖ N/A | L |
| **Total rows** | <total> |

**FAIL rows block production launch unless explicitly waived
per [`waiver-template.md`](waiver-template.md).**

---

## 1. Software Bill of Materials (SBOM)

| # | Check | Status | Evidence |
|---|---|---|---|
| 1.1 | SBOM generated at build time | ✅ / ⚠ / ❌ | `<artifact path>` |
| 1.2 | SBOM stored in artifact registry | ✅ / ⚠ / ❌ | `<registry path>` |
| 1.3 | SBOM scanned against NVD / OSV | ✅ / ⚠ / ❌ | `<scan report link>` |
| 1.4 | SBOM retention ≥1y matches binary retention | ✅ / ⚠ / ❌ | `<policy link>` |

## 2. Dependency vulnerability scan

| # | Check | Status | Evidence |
|---|---|---|---|
| 2.1 | 0 critical direct deps | ✅ / ⚠ / ❌ | `<scan report>` |
| 2.2 | 0 high direct deps (or documented mitigation) | ✅ / ⚠ / ❌ | `<scan report>` |
| 2.3 | Transitive deps scanned | ✅ / ⚠ / ❌ | `<scan report>` |
| 2.4 | Scan cadence: every PR + nightly | ✅ / ⚠ / ❌ | `<CI config>` |
| 2.5 | New-vuln response SLA documented | ✅ / ⚠ / ❌ | `<runbook>` |

## 3. Secrets scan

| # | Check | Status | Evidence |
|---|---|---|---|
| 3.1 | Git history clean (gitleaks / trufflehog full scan) | ✅ / ⚠ / ❌ | `<scan output>` |
| 3.2 | Pre-commit hook installed | ✅ / ⚠ / ❌ | `<.pre-commit-config>` |
| 3.3 | CI scan as required check | ✅ / ⚠ / ❌ | `<workflow>` |
| 3.4 | Leak-response runbook | ✅ / ⚠ / ❌ | `<runbook link>` |

## 4. Authentication

| # | Check | Status | Evidence |
|---|---|---|---|
| 4.1 | Access tokens lifetime ≤1h | ✅ / ⚠ / ❌ | `<config link>` |
| 4.2 | Refresh tokens lifetime ≤30d | ✅ / ⚠ / ❌ | `<config>` |
| 4.3 | Refresh rotation enabled (single-use) | ✅ / ⚠ / ❌ | `<config>` |
| 4.4 | Server-side session invalidation works | ✅ / ⚠ / ❌ | `<test result>` |
| 4.5 | Password hashing: bcrypt / argon2 / scrypt with modern cost | ✅ / ⚠ / ❌ | `<config>` |
| 4.6 | MFA supported (TOTP / WebAuthn) | ✅ / ⚠ / ❌ | `<feature config>` |
| 4.7 | Rate limiting / lockout on auth endpoints | ✅ / ⚠ / ❌ | `<config>` |

## 5. Authorization (RBAC)

| # | Check | Status | Evidence |
|---|---|---|---|
| 5.1 | RBAC matrix documented | ✅ / ⚠ / ❌ | `<doc link>` |
| 5.2 | Per-role integration test exists | ✅ / ⚠ / ❌ | `<test paths>` |
| 5.3 | Default deny at API boundaries | ✅ / ⚠ / ❌ | `<code paths>` |
| 5.4 | Object-level authz (no IDOR) | ✅ / ⚠ / ❌ | `<test paths>` |

## 6. TLS posture

| # | Check | Status | Evidence |
|---|---|---|---|
| 6.1 | TLS 1.3 enabled on public endpoints | ✅ / ⚠ / ❌ | `<ssllabs scan>` |
| 6.2 | HSTS header `max-age` ≥6 months | ✅ / ⚠ / ❌ | `<curl test>` |
| 6.3 | Cert auto-renewal working | ✅ / ⚠ / ❌ | `<renewal log>` |
| 6.4 | OCSP stapling enabled | ✅ / ⚠ / ❌ | `<test result>` |
| 6.5 | Modern cipher suites (Mozilla Intermediate or Modern) | ✅ / ⚠ / ❌ | `<ssllabs scan>` |
| 6.6 | Cert transparency logs check pass | ✅ / ⚠ / ❌ | `<crt.sh link>` |

## 7. Input validation

| # | Check | Status | Evidence |
|---|---|---|---|
| 7.1 | Schema validation at every API boundary | ✅ / ⚠ / ❌ | `<validation lib usage>` |
| 7.2 | CSP present + restrictive (web) | ✅ / ⚠ / ❌ | `<header test>` |
| 7.3 | CORS policy explicit (not `*`) | ✅ / ⚠ / ❌ | `<config>` |
| 7.4 | File upload: content-type + size + magic-number checks | ✅ / ⚠ / ❌ | `<upload handler code>` |
| 7.5 | SQL: parameterized / ORM / prepared statements only | ✅ / ⚠ / ❌ | `<code review notes>` |
| 7.6 | Output encoding XSS-safe in templating | ✅ / ⚠ / ❌ | `<framework config>` |

## 8. OWASP Top 10 (2024)

See [`owasp-evidence-patterns.md`](owasp-evidence-patterns.md) for what
evidence looks like per row.

| # | OWASP Item | Status | Evidence |
|---|---|---|---|
| A01 | Broken Access Control | ✅ / ⚠ / ❌ | <link> |
| A02 | Cryptographic Failures | ✅ / ⚠ / ❌ | <link> |
| A03 | Injection | ✅ / ⚠ / ❌ | <link> |
| A04 | Insecure Design | ✅ / ⚠ / ❌ | <link> |
| A05 | Security Misconfiguration | ✅ / ⚠ / ❌ | <link> |
| A06 | Vulnerable + Outdated Components | ✅ / ⚠ / ❌ | <link> |
| A07 | Identification + Authentication Failures | ✅ / ⚠ / ❌ | <link> |
| A08 | Software + Data Integrity Failures | ✅ / ⚠ / ❌ | <link> |
| A09 | Security Logging + Monitoring Failures | ✅ / ⚠ / ❌ | <link> |
| A10 | Server-Side Request Forgery | ✅ / ⚠ / ❌ | <link> |

---

## FAIL row remediation

| # (from above) | Owner | Remediation | Due | Status |
|---|---|---|---|---|
| <row id> | <name> | <action> | YYYY-MM-DD | open / closed |

---

## PARTIAL row mitigation

| # | Owner | Mitigation in place | Path to PASS | Due |
|---|---|---|---|---|
| <row id> | <name> | <compensating control> | <action> | YYYY-MM-DD |

---

## Waivers

Any FAIL waived per [`waiver-template.md`](waiver-template.md). Waivers
must include named approver + business justification + compensating
control + fix-by date.

| Waiver ID | Row | Approver | Justification | Compensating control | Fix-by |
|---|---|---|---|---|---|
| <W1> | <row> | <name> | <…> | <…> | YYYY-MM-DD |

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial audit | <name> |
