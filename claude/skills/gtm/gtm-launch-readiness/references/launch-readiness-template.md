# Launch Readiness Audit — <project>

**Version:** 1
**Audit date:** YYYY-MM-DD
**Audit owner:** <name>
**Launch target date:** YYYY-MM-DD
**Status:** draft | locked | passed | failed

---

## Summary

| Status | Count |
|---|---|
| ✅ PASS | N |
| ⚠ PARTIAL | M |
| ❌ FAIL | K |
| ➖ N/A | L |

**FAIL rows block launch unless explicitly waived per
[`waiver-template.md`](waiver-template.md).**

---

## 1. Security

(Cross-reference `devops-security-hardening`'s security
baseline for detailed scan results.)

| # | Check | Status | Evidence |
|---|---|---|---|
| 1.1 | SBOM generated + scanned | ✅ / ⚠ / ❌ | `<security-baseline.md row 1.1>` |
| 1.2 | 0 critical / high dep vulns | ✅ / ⚠ / ❌ | `<security-baseline.md row 2>` |
| 1.3 | Secrets scan clean (history + working tree) | ✅ / ⚠ / ❌ | `<security-baseline.md row 3>` |
| 1.4 | Auth review (JWT lifetimes, refresh rotation, MFA) | ✅ / ⚠ / ❌ | `<security-baseline.md row 4>` |
| 1.5 | TLS 1.3 + HSTS + cert auto-renewal | ✅ / ⚠ / ❌ | `<ssllabs scan>` |
| 1.6 | Input validation at API boundaries | ✅ / ⚠ / ❌ | `<security-baseline.md row 7>` |
| 1.7 | OWASP top 10 pass | ✅ / ⚠ / ❌ | `<security-baseline.md row 8>` |
| 1.8 | Penetration test (if applicable) | ✅ / ⚠ / ❌ / ➖ | `<pen test report>` |
| 1.9 | Vulnerability disclosure policy published | ✅ / ⚠ / ❌ | `<URL>` |

---

## 2. Performance

| # | Check | Status | Evidence |
|---|---|---|---|
| 2.1 | Load test passes target p95 | ✅ / ⚠ / ❌ | `<load test report>` |
| 2.2 | Soak test (24h+) passes | ✅ / ⚠ / ❌ | `<soak report>` |
| 2.3 | Failure-mode test (dep failures handled) | ✅ / ⚠ / ❌ | `<chaos test report>` |
| 2.4 | Auto-scaling configured + tested | ✅ / ⚠ / ❌ | `<scaling test report>` |
| 2.5 | DB query plans reviewed; indexes verified | ✅ / ⚠ / ❌ | `<EXPLAIN ANALYZE output>` |
| 2.6 | CDN configured for static assets | ✅ / ⚠ / ❌ / ➖ | `<CDN config>` |

---

## 3. Legal

| # | Check | Status | Evidence |
|---|---|---|---|
| 3.1 | Terms of Service published | ✅ / ⚠ / ❌ | `<URL>` |
| 3.2 | Privacy Policy published | ✅ / ⚠ / ❌ | `<URL>` |
| 3.3 | Cookie / tracking consent flow | ✅ / ⚠ / ❌ / ➖ | `<implementation>` |
| 3.4 | Data residency declared (region(s)) | ✅ / ⚠ / ❌ | `<doc>` |
| 3.5 | GDPR DSAR flow (if EU users) | ✅ / ⚠ / ❌ / ➖ | `<process doc>` |
| 3.6 | CCPA flow (if CA users) | ✅ / ⚠ / ❌ / ➖ | `<process doc>` |
| 3.7 | COPPA compliance (if minors) | ✅ / ⚠ / ❌ / ➖ | `<process doc>` |
| 3.8 | Trademark / IP cleared for brand | ✅ / ⚠ / ❌ | `<legal sign-off>` |

---

## 4. Operational

| # | Check | Status | Evidence |
|---|---|---|---|
| 4.1 | Runbooks exist per recognised incident class | ✅ / ⚠ / ❌ | `<runbooks/ list>` |
| 4.2 | On-call rotation set up | ✅ / ⚠ / ❌ | `<PagerDuty schedule>` |
| 4.3 | Alert thresholds tied to SLOs | ✅ / ⚠ / ❌ | `<devops-observability slo-worksheet>` |
| 4.4 | Rollback procedure documented + tested | ✅ / ⚠ / ❌ | `<release-policy.md>` |
| 4.5 | Disaster recovery plan (RTO/RPO documented) | ✅ / ⚠ / ❌ | `<DR plan>` |
| 4.6 | Backup verified via test restore | ✅ / ⚠ / ❌ | `<restore test report>` |
| 4.7 | Capacity planning done | ✅ / ⚠ / ❌ | `<capacity doc>` |
| 4.8 | Game-day rehearsal completed | ✅ / ⚠ / ❌ | `<game-day report>` |

---

## 5. Support

| # | Check | Status | Evidence |
|---|---|---|---|
| 5.1 | Help docs published | ✅ / ⚠ / ❌ | `<URL>` |
| 5.2 | Ticket intake (email / form / chat) live | ✅ / ⚠ / ❌ | `<system URL>` |
| 5.3 | Support SLA documented | ✅ / ⚠ / ❌ | `<doc>` |
| 5.4 | First-line support trained on the product | ✅ / ⚠ / ❌ | `<training records>` |
| 5.5 | Escalation path to engineering | ✅ / ⚠ / ❌ | `<process doc>` |
| 5.6 | Refund / cancellation policy (if monetised) | ✅ / ⚠ / ❌ / ➖ | `<doc>` |
| 5.7 | Feedback intake channel for users | ✅ / ⚠ / ❌ | `<channel>` |

---

## 6. Compliance (per project regime)

Per `INSTRUCTIONS/projects/<slug>/project-context.md` declared
regime(s):

| # | Regime | Check | Status | Evidence |
|---|---|---|---|---|
| 6.1 | HIPAA | BAA in place (if applicable) | ✅ / ⚠ / ❌ / ➖ | <evidence> |
| 6.2 | HIPAA | PHI encryption at rest + transit | ✅ / ⚠ / ❌ / ➖ | <evidence> |
| 6.3 | SOC2 | Type II attestation underway / complete | ✅ / ⚠ / ❌ / ➖ | <evidence> |
| 6.4 | PCI | Saqr / questionnaire complete | ✅ / ⚠ / ❌ / ➖ | <evidence> |
| 6.5 | PCI | Cardholder data scope documented | ✅ / ⚠ / ❌ / ➖ | <evidence> |
| 6.6 | GDPR | Data Processing Agreement template | ✅ / ⚠ / ❌ / ➖ | <evidence> |
| 6.7 | GDPR | DPO identified (if required) | ✅ / ⚠ / ❌ / ➖ | <name> |
| 6.8 | Industry-specific | <e.g. HITRUST / FedRAMP / FERPA> | ✅ / ⚠ / ❌ / ➖ | <evidence> |

---

## FAIL remediation

| # (from above) | Owner | Remediation | Due | Status |
|---|---|---|---|---|
| <row id> | <name> | <action> | YYYY-MM-DD | open / closed |

## PARTIAL mitigation

| # | Owner | Mitigation in place | Path to PASS | Due |
|---|---|---|---|---|
| <row id> | <name> | <compensating control> | <action> | YYYY-MM-DD |

## Waivers

Any FAIL waived per [`waiver-template.md`](waiver-template.md):

| Waiver ID | Row | Approver | Justification | Compensating control | Fix-by |
|---|---|---|---|---|---|
| <W1> | <row> | <name> | <…> | <…> | YYYY-MM-DD |

---

## Decision

**Launch readiness decision:** GO / NO-GO / CONDITIONAL

**Decision authority:** <name> on YYYY-MM-DD

**Rationale.** <one paragraph; if CONDITIONAL, state the
conditions>

**If GO:** launch proceeds per `release-policy.md`.

**If NO-GO:** remediation plan + re-audit date.

**If CONDITIONAL:** specific gates that must close before launch.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial audit | <name> |
