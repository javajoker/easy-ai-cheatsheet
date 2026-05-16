---
name: gtm-launch-readiness
description: Runs an opinionated pre-launch audit against six categories (security, performance, legal, operational, support, compliance) and emits a launch-readiness-audit.md with PASS / PARTIAL / FAIL per row plus evidence pointers. Reuses requirement-audit's format so the output is consistent with the rest of the framework's audits. Use this skill when the user asks "are we ready to launch", "run the pre-launch checklist", "what's left before go-live"; or when lifecycle-pilot reaches Phase 6. Pairs with requirement-audit (this is a templated audit), devops-engineer agent (most operational rows delegate there), cognitive-alignment (lock the meaning of "ready" — the team's definition matters), and memory-ontology (record the launch date and the FAIL rows still open at launch).
status: shipped
owner_agent: lifecycle-pilot
---

# GTM Launch Readiness

The pre-launch gate. Produces an audit with row-level evidence that
decides whether the product is allowed to ship to customers.

> **FAIL rows block launch.** PARTIAL rows ship only with an
> explicit mitigation note and a named owner for the follow-up.
> PASS rows are the bar; the audit's job is to make missing PASS
> rows visible *before* customers find them.

## Why this exists

Pre-launch is the moment where the cost of finding a problem is
cheapest and the cost of *missing* a problem is highest. Without a
templated audit:

- Each project re-invents its own checklist; coverage is uneven.
- Security and legal rows get under-covered (engineers don't think
  about them by default).
- The team learns about a missing piece in production, when fixing
  it is most expensive.
- There is no audit trail proving the team checked.

This skill ships an opinionated baseline checklist drawn from years
of launch postmortems, mapped to PASS / PARTIAL / FAIL with evidence
pointers, in the same format as `requirement-audit` so the output
slots into existing audit workflows.

## When to fire

Fire when:

- The user asks *"are we ready to launch"*, *"run the pre-launch
  checklist"*, *"what's left before go-live"*.
- `lifecycle-pilot` reaches Phase 6.
- A release-management decision needs evidence that a release is
  safe (this skill works for major releases too, not just first
  launches).
- A regulatory or contractual obligation requires a documented
  pre-launch audit.

Do **not** fire when:

- The release is a minor patch or bug fix (use the normal release
  process, not the launch audit).
- The product is still in active development without a target
  launch window (the audit is wasted if there's no decision pending).

## The six categories

| # | Category | Owner who provides evidence |
|---|---|---|
| 1 | Security | `devops-security-hardening` skill |
| 2 | Performance | `devops-observability` + load-test results |
| 3 | Legal | Legal team / templates in `references/` |
| 4 | Operational | `devops-engineer` agent (runbooks, on-call, alerts) |
| 5 | Support | Product / Support team |
| 6 | Compliance | Project-specific (declared in `INSTRUCTIONS/projects/<slug>/`) |

Each category has 6–10 row items (~50 total). The exact roster is in
[references/launch-checklist.md](references/launch-checklist.md). The
skill reads that file at runtime so updates to the checklist
propagate without changing the skill body.

## The procedure

### Phase 1 — Scope

Confirm what is being launched:

- Product / feature / surface (Web app? Mobile? API? Public website?
  Internal admin? Each has different rows.)
- Audience (Internal pilot? Closed beta? Open beta? Public launch?)
- Geography (Single-country? Multi-region? Each adds compliance rows.)
- Compliance regime (None? GDPR? HIPAA? PCI? SOC2? KYC?)

These four scoping decisions decide which optional rows light up.
Don't audit rows that don't apply — `➖ N/A` with a one-line reason
is the right entry.

### Phase 2 — Read the project context

Open `INSTRUCTIONS/projects/<slug>/project-context.md` for the
project's stack, compliance declarations, and any project-specific
checklist additions.

If the project has a `INSTRUCTIONS/projects/<slug>/launch-checklist-
overrides.md`, merge its rows into the baseline checklist (additions
and removals both allowed, with documented rationale).

### Phase 3 — Audit each row

For every active row:

1. Read the row's verification step.
2. Run the verification (or ask the owner to). For automated checks,
   run the script in `references/scripts/` if one exists.
3. Classify:
   - **✅ PASS** — verification succeeded; cite the evidence.
   - **⚠ PARTIAL** — partially met; record what's missing and the
     mitigation; assign an owner for the follow-up.
   - **❌ FAIL** — not met; **launch is blocked** unless explicitly
     waived (waiver requires a named owner, a reason, and a
     follow-up date).
   - **➖ N/A** — not applicable to this launch; one-line reason.

Evidence is **pointer-style** wherever possible — file path + line
range, command output, dashboard URL, signed-off doc reference. Not
prose.

### Phase 4 — Emit the audit

Write `launch-readiness-audit.md` to the project's output location
(by default `docs/audits/<YYYY-MM-DD>-launch-readiness.md`).

Output shape:

```markdown
# Launch Readiness Audit — <product>

**Audit date:** <YYYY-MM-DD>
**Launch target:** <date>
**Audience:** <internal | closed-beta | open-beta | public>
**Auditor:** <session id>

## Summary

✅ <N> PASS · ⚠ <N> PARTIAL · ❌ <N> FAIL · ➖ <N> N/A

**Verdict:** <Cleared to launch | Cleared with mitigations | BLOCKED>

## 1. Security

| # | Check | Status | Evidence / Mitigation | Owner |
|---|---|---|---|---|
| 1.1 | SBOM generated and stored | ✅ PASS | `artifacts/sbom-2026-05-15.json` | @devops |
| 1.2 | Dependency vulnerability scan: 0 critical / high | ⚠ PARTIAL | 2 high-severity; mitigation: workaround in `src/x.ts:42`; fix by 2026-06-01 | @alice |
| ... |

(One section per category.)

## Open items at launch

| Severity | Item | Owner | Fix-by date |
|---|---|---|---|
| ... |
```

### Phase 5 — Decide and record

Three possible verdicts:

- **Cleared to launch.** All rows PASS or N/A. Update `memory-
  ontology` with the launch date.
- **Cleared with mitigations.** Some PARTIAL rows; each has an
  owner + fix-by date. Update memory with the launch date AND the
  open-items list.
- **BLOCKED.** ≥1 FAIL row without a waiver. Surface to the user;
  the launch does not happen until the FAIL is addressed.

In all three cases, persist the audit file in the project (not just
in the chat) — it's a load-bearing artifact for compliance and for
the post-launch review.

## Override + waiver discipline

Any row can be **waived**, but a waiver requires:

- A named owner (a human, not "the team").
- A documented reason that survives scrutiny.
- A follow-up date by which the row is re-audited.
- Sign-off recorded in the audit file.

Waivers are first-class — not hidden in conversation. If you find
yourself waiving more than 3 rows for a launch, the launch isn't
ready; rethink the timeline.

## Companion skills

- `requirement-audit` — the underlying audit mechanic. This skill is
  essentially `requirement-audit` with the launch checklist
  pre-loaded.
- `devops-security-hardening` — provides Security category evidence.
- `devops-observability` — provides Performance + Operational
  evidence (dashboards, alerts, SLO burn-rate).
- `devops-incident-runbook` — provides Operational evidence
  (runbooks exist for the launch surface).
- `cognitive-alignment` — *"ready"* means different things in
  different orgs; lock the meaning before auditing.
- `memory-ontology` — record the launch date and open items.

## Anti-patterns

- **Auditing the rows that pass.** The audit's value is the rows
  that *don't* pass. Don't skip uncomfortable categories (legal,
  compliance) because they're harder.
- **Prose evidence.** *"Looks good, we've handled this"* is not
  evidence. File paths, dashboard URLs, command output.
- **Silent waiver.** A waiver not written down doesn't exist for the
  post-launch review.
- **Audit at launch -1d.** The audit's purpose is to surface gaps
  early. Aim for launch -2 weeks for the first pass, launch -3 days
  for the final pass.
- **One-time audit for a launching product.** Re-audit before every
  major release. The checklist evolves; the threats evolve.

## Reference files

- [references/launch-checklist.md](references/launch-checklist.md) —
  the canonical row roster. Source-of-truth for what gets audited.
- `references/scripts/` — automation for rows where it makes sense
  (SBOM gen, dep scan, secret scan, etc.).
- `references/waiver-template.md` — the shape every waiver follows.
- `references/launch-readiness-template.md` — the audit-output
  template the skill emits.
