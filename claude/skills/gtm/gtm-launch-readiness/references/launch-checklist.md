# Launch Readiness Checklist (canonical row roster)

The baseline. Projects may add or remove rows via
`INSTRUCTIONS/projects/<slug>/launch-checklist-overrides.md`, but the
six categories below are the framework's opinionated default.

Each row has: an ID, a one-line description, a verification step, and
the evidence type expected.

---

## 1. Security

| ID | Check | Verification | Evidence type |
|---|---|---|---|
| 1.1 | SBOM generated and stored | Run `syft` or equivalent; store artifact | file path |
| 1.2 | Dependency vulnerability scan — 0 critical, 0 high | Run `grype` / `npm audit` / `pip-audit` / `govulncheck` | tool output |
| 1.3 | Secrets scan of git history clean | Run `gitleaks` / `trufflehog` against full history | tool output |
| 1.4 | Auth — JWT lifetimes ≤ 1h, refresh rotation enabled | Inspect auth config | config path + line |
| 1.5 | RBAC matrix documented and tested | Read RBAC doc + per-role integration test | doc path + test path |
| 1.6 | TLS — TLS 1.3 only, HSTS enabled, valid cert with auto-renewal | `curl --tlsv1.3 -I` + cert inspection | command output |
| 1.7 | Input validation at every API boundary | Spot-check 3 endpoints | code paths |
| 1.8 | OWASP top 10 baseline pass | Reference `devops-security-hardening` output | audit doc path |
| 1.9 | Rate limiting / abuse protection in place | Inspect middleware / WAF rules | config path |
| 1.10 | Bug-bounty / vulnerability-disclosure policy published | URL or `security.txt` | URL |

## 2. Performance

| ID | Check | Verification | Evidence type |
|---|---|---|---|
| 2.1 | p95 latency under target on critical paths | Load test result | report path |
| 2.2 | Throughput meets target QPS | Load test result | report path |
| 2.3 | Soak test passes — 24h sustained load with no leak / degradation | Soak test result | report path |
| 2.4 | Failure-mode test — degrades gracefully under DB/cache outage | Chaos test result | report path |
| 2.5 | CDN configured for static assets (if web product) | Inspect headers | command output |
| 2.6 | Database has connection pooling tuned + query budget | Pool config + slow-query log | config path |
| 2.7 | Worker queue capacity sized for launch traffic + 3× | Queue config | config path |

## 3. Legal

| ID | Check | Verification | Evidence type |
|---|---|---|---|
| 3.1 | Terms of Service published | URL | URL |
| 3.2 | Privacy Policy published | URL | URL |
| 3.3 | Cookie policy + consent banner (if GDPR / CCPA applicable) | Live in production | URL |
| 3.4 | Data Processing Agreement (DPA) available on request | URL or doc reference | URL |
| 3.5 | Data residency commitment matches reality (where is data stored?) | Architecture diagram + cloud region config | doc path |
| 3.6 | Data deletion / export endpoints work end-to-end | Manual test as test-user | test result |
| 3.7 | Age gate (COPPA) if applicable | Live in production | URL |
| 3.8 | Trademark search completed for product name | Search result | doc reference |

## 4. Operational

| ID | Check | Verification | Evidence type |
|---|---|---|---|
| 4.1 | On-call rotation set up and named | PagerDuty / Opsgenie schedule | URL |
| 4.2 | Alerts tied to SLOs; burn-rate alerts fire pre-incident | Alert rules | alert config path |
| 4.3 | Dashboards for golden signals per service | Dashboard URLs | URL |
| 4.4 | Runbook exists for each named incident class | Run `devops-incident-runbook` output | doc paths |
| 4.5 | Logs ingested + queryable; correlation IDs propagated | Sample log query | query + result |
| 4.6 | Backup / restore tested in the last 30 days | Restore test result | doc path |
| 4.7 | DR / failover tested in the last 90 days | DR test result | doc path |
| 4.8 | Incident communication channel pre-defined (status page, customer email template) | Status page URL + template | URL + doc path |
| 4.9 | Rollback procedure verbatim documented and rehearsed | Game day record | doc path |

## 5. Support

| ID | Check | Verification | Evidence type |
|---|---|---|---|
| 5.1 | Help docs cover top 10 expected questions | docs/help/ exists, ToC complete | URL |
| 5.2 | Ticket intake channel live (form / email / chat) | Send a test ticket | confirmation |
| 5.3 | Support response SLA agreed and communicated | Doc reference | doc path |
| 5.4 | Refund / cancellation policy live (if monetised) | URL | URL |
| 5.5 | First-line responder roster + escalation path defined | Doc reference | doc path |
| 5.6 | Feedback channel for customers (e.g. feedback@, public board) | URL or address | URL |

## 6. Compliance (project-specific)

Loaded from `INSTRUCTIONS/projects/<slug>/compliance-checklist.md`
when the project declares one of:

- **GDPR** — DPA + DSR endpoints + DPIA filed.
- **HIPAA** — BAA in place + PHI flow diagram + access logs.
- **PCI** — cardholder data scope minimised + SAQ filed.
- **SOC2** — control evidence collected (Type I before launch; Type II
  on rolling basis).
- **KYC / AML** — verification flow live + sanctions screening live.
- **COPPA** — age gate + parental consent + restricted data flow.

If the project declares no compliance regime, mark this entire
category `➖ N/A` with a one-line reason.

---

## Total row count

- Security: 10
- Performance: 7
- Legal: 8
- Operational: 9
- Support: 6
- Compliance: project-specific (typically 5–15)

**Baseline total: 40 + compliance.** Most launches end up with 45–55
rows after compliance is factored in.

## How to extend per project

1. Create `INSTRUCTIONS/projects/<slug>/launch-checklist-overrides.md`.
2. Use the same table shape.
3. Mark additions with a project ID prefix (e.g. `coolshell-3.1`) so
   they're distinguishable from the baseline.
4. Mark removals with a one-line rationale.

The skill merges the override file at audit time.
