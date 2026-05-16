# Required Checks Matrix — per project type

What checks should be **required** (block merge) vs **advisory**
per project type. Required checks live in branch-protection
config; advisory checks run but don't block.

## Default per project class

| Check | Web app | API service | Library / SDK | Internal tool |
|---|---|---|---|---|
| Lint | required | required | required | required |
| Type check | required | required | required | required |
| Unit tests | required | required | required | required |
| Integration tests | required | required | required | advisory |
| Build | required | required | required | required |
| Dep vulnerability scan | required | required | required | advisory |
| Secrets scan | required | required | required | required |
| Container scan (Trivy) | required (if containerised) | required | n/a | advisory |
| Code coverage threshold | advisory | advisory | required (≥80%) | advisory |
| E2E tests | advisory | advisory | n/a | advisory |
| Lighthouse / web-vitals | advisory | n/a | n/a | n/a |
| License scan | advisory (org-dependent) | advisory | required | advisory |
| SAST (Semgrep / CodeQL) | required (if regulated) | required (if regulated) | required (if published) | advisory |
| Visual regression | advisory | n/a | n/a | n/a |
| API contract drift | n/a | required (public API) | required | n/a |

## Strict-mode (regulated environments)

For HIPAA / PCI / SOC2 / regulated projects, additional required
checks:

- SAST passing (no high-severity findings).
- License scan passing (no copyleft in proprietary code).
- Audit log verified (every CI run logged with reviewer).
- Approver count ≥2 for production-bound branches.
- Sign-off required from named role (security / compliance).

## Branch protection summary

For `main` (and any protected branch):

- [ ] Require PR before merge.
- [ ] Require ≥1 approval (≥2 for regulated).
- [ ] Dismiss stale approvals on new pushes.
- [ ] Require status checks (from the matrix above) green.
- [ ] Require branches up-to-date before merge.
- [ ] Require conversation resolution before merge.
- [ ] No force push, no deletions.
- [ ] CODEOWNERS for sensitive areas (auth, payments, infra).

## How to add a new required check

1. Run the check as advisory for ≥2 weeks.
2. Verify pass rate ≥95% (high pass rate means the check is
   meaningful and reliable).
3. Identify and fix the persistent failures.
4. Promote to required in branch protection.
5. Document in project's `INSTRUCTIONS/projects/<slug>/`.

Required checks that fail >5% of the time create alert fatigue
and pressure to bypass (`--no-verify`). Either fix the check or
demote to advisory.

## How to remove a required check

If a check is repeatedly failing for reasons unrelated to
quality:

1. Capture data: 30-day failure rate, failure causes.
2. Either fix root cause OR demote to advisory.
3. Document the demotion + reason.

Removing a check without documentation is silent quality
erosion.
