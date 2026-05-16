# Dependency Upgrade Plan — <dependency> <from> → <to>

**Version:** 1
**Locked:** YYYY-MM-DD
**Owner:** <name>
**Decision authority:** <name>
**Reversibility:** standard | DB-major (write-cutover irreversible after step X) | runtime (host env change)
**Status:** active | draft | superseded

---

## Context

- Affected projects / services: <list>
- Triggering reason: <security advisory | EOL | new feature needed | annual refresh>
- Wall-clock target: YYYY-MM-DD

---

## Changelog scan

Read upstream changelog from current to target. Per breaking change:

| # | Change | Class | Impact on this project | Action |
|---|---|---|---|---|
| C1 | <description> | mechanical / behavioural / removed / deprecated | <how it affects us> | codemod / test update / rewrite / track for next major |
| C2 | <…> | … | … | … |

Class definitions:

- **mechanical** — rename, signature, no semantic change → codemod
  or simple rename.
- **behavioural** — same API, different runtime behaviour → tests
  need to verify; may need fixes.
- **removed** — API gone → find replacement; rewrite call sites.
- **deprecated** — works now; gone next major → track; do not
  block this upgrade.

---

## Compat shim (if needed)

| Field | Value |
|---|---|
| What it bridges | <e.g. old + new coexisting during ramp> |
| Where it lives | <file paths> |
| Lifetime | <typically ≤2 ramp cycles> |
| Cleanup phase | <which phase removes it> |

If no shim needed, write *"None — atomic upgrade across services."*

---

## Test matrix

CI runs both current + target versions:

| Test class | Current version | Target version | Notes |
|---|---|---|---|
| Unit tests | ✓ | ✓ | drive failures to 0 before canary |
| Integration tests | ✓ | ✓ | |
| Smoke / e2e | ✓ | ✓ | |
| Soak / load | run on staging | run on staging | |

Failures categorised:

- **mechanical** — apply codemod.
- **behavioural** — update test or fix application.
- **unexpected** — investigate before proceeding.

---

## Ramp schedule

| Stage | Traffic % | Soak | Metric gate | Approver |
|---|---|---|---|---|
| Canary | 1% | 24–48h | err_rate ≤ 1.05× baseline; p99 ≤ 1.10× baseline | <name> |
| Early | 10% | 24h | same gates | <name> |
| Mid | 50% | 12–24h | same + dependency saturation < threshold | <name> |
| Full | 100% | – | – | <name> |

**Stage transition rule:** all gates green for the full soak
period; any gate red → abort + rollback.

---

## Rollback per stage

| Stage | Rollback procedure | Duration |
|---|---|---|
| Canary | Remove canary subset; revert deploy | < 5 min |
| Early / Mid | Drop traffic % to 0; investigate | < 5 min |
| Full | Emergency rollback per `devops-release-management` Mode 1 | < 15 min |

Verbatim commands per stage in `scripts/rollback/` (see
`arch-rollout-strategy/references/rollback-scripts-cookbook.md`).

---

## Special-case: DB major upgrade

If reversibility = DB-major, the cutover phase is **non-
reversible without data loss**. Apply [db-major-cutover-checklist.md](db-major-cutover-checklist.md)
before scheduling the cutover.

Decision authority must explicitly approve the cutover separately
from approving the overall upgrade.

---

## Documentation impact

Inventory of artifacts that mention the old version:

- [ ] README.md
- [ ] Architecture diagrams
- [ ] Runbooks under `runbooks/`
- [ ] API docs / OpenAPI
- [ ] Customer-facing docs
- [ ] INSTRUCTIONS/projects/<slug>/project-context.md

All updated in the cleanup phase.

---

## Abort triggers

Abort the upgrade if:

- Any ramp-stage gate red beyond grace period.
- Critical regression discovered post-cutover.
- Vendor publishes critical bug in target version.
- Compat shim creates production incidents.

Aborts trigger documented postmortem + replanning.

---

## Cleanup phase (post-100%)

- [ ] Remove compat shims.
- [ ] Remove version pins / conditional code.
- [ ] Update docs (per documentation impact above).
- [ ] Close upgrade ticket.

---

## Change log

| Version | Date | Change | By |
|---|---|---|---|
| 1 | YYYY-MM-DD | initial | <name> |
