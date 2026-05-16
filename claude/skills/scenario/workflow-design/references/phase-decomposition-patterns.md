# Phase Decomposition Patterns

Pre-worked phase decompositions for common scenario shapes. Use
as starting points; adapt to the specific scenario.

## Pattern 1 — Build + launch a new product (lifecycle-pilot's arc)

```
1. Ideation — prototype + concept lock
2. Specification — PRD + UI/UX spec + tech design
3. (Optional) Validation — mock app for spec verification
4. Planning — task breakdown
5. Production code — frontend + backend (parallel)
6. Launch readiness — security/perf/legal/ops audit
7. Go-to-market — positioning + pricing + marketing site + beta + analytics
8. Public launch + hand-off
```

Lead agent: `lifecycle-pilot`.
Critical path: 1 → 2 → 4 → 5 → 6 → 7 → 8.
Parallelism: 5a/5b (frontend + backend); 7 (most GTM tasks in
parallel after positioning lands).

---

## Pattern 2 — Re-architect an existing system

```
1. Assess — current architecture + pain + options
2. Decide — pick the target option
3. Plan migration — phased plan with reversible checkpoints
4. Migrate — execute phases
5. Roll out — production cutover
6. Communicate — breaking-change comms
7. Decommission — remove old paths
```

Lead agent: `architecture-shepherd`.
Critical path: 1 → 2 → 3 → 4 → 5 → 7.
Parallelism: 6 runs alongside 4–5.

---

## Pattern 3 — Enterprise initiative spanning multiple teams

```
1. Discovery — scope, stakeholders, constraints
2. Pilot — small-scope proof on one team / one product
3. Refine — adjust based on pilot
4. Expand — roll out to additional teams / products
5. Standardise — promote to org-wide standard
6. Govern — ongoing oversight + audits
```

Lead agent: `scenario-strategist` (form a group).
Critical path: 1 → 2 → 3 → 4 → 5.
6 runs perpetually post-launch.

---

## Pattern 4 — Knowledge base / docs build

```
1. Architect — taxonomy, entity contract, source manifest
2. Ingest — pull entities from sources
3. Merge — canonical layer with conflict resolution
4. Publish — make navigable + searchable
5. Govern — refresh policy + access control + audits
6. Maintain — perpetual
```

Lead agent: `knowledge-curator`.
Critical path: 1 → 2 → 3 → 4.
5–6 ongoing post-launch.

---

## Pattern 5 — Vendor switch / migration

```
1. Evaluate — vendors against criteria
2. Procure — contracts, SLAs, security review
3. Integrate — wire up new vendor; dual-use
4. Migrate — move workloads/data
5. Cutover — old vendor traffic off
6. Decommission — contract end + cleanup
```

Lead agent: scenario-strategist if multi-team; `architecture-
shepherd` if engineering-only.
Critical path: 1 → 2 → 3 → 4 → 5 → 6.

---

## Pattern 6 — Compliance certification (SOC2 / ISO27001 / HIPAA)

```
1. Gap assessment — current vs required controls
2. Remediation — implement missing controls
3. Documentation — policies + procedures
4. Internal audit — verify controls
5. External audit — auditor engagement
6. Certification + maintenance — annual recertification
```

Lead agent: `scenario-strategist` (group: legal + eng-security +
`devops-engineer`).
Critical path: 1 → 2 → 4 → 5.
3 runs alongside 2.

---

## Pattern 7 — Pricing / packaging change

```
1. Analysis — unit economics + market benchmark
2. Design — new tiers + features assigned
3. Internal alignment — Sales / CS / Finance / Legal sign-off
4. Communication design — customer messaging + migration paths
5. Existing-customer migration — grandfathering vs migration
6. New-customer rollout — pricing page + sales enablement
7. Monitor — adoption + churn signals; iterate
```

Lead agent: `scenario-strategist` (group: Product + Finance +
Sales + Marketing).
Critical path: 1 → 2 → 3 → 5 → 6.

---

## Pattern 8 — Incident-driven hardening

After a SEV1 incident, structured response:

```
1. Mitigate — restore service (incident response, not workflow)
2. Postmortem — root cause + contributing factors
3. Action items — categorised + prioritised
4. Quick wins — immediate hardening (days)
5. Structural — architectural changes (weeks)
6. Verify — game-day rehearsal of the failure mode
```

Lead agent: `devops-engineer` (with `architecture-shepherd` for
structural items).
Critical path: 1 → 2 → 3 → 4 → 6.
5 runs alongside 4.

---

## Pattern 9 — Major dependency upgrade

```
1. Changelog scan — classify breaking changes
2. Compat shim (if needed) — bridge old/new
3. Test matrix expansion — CI tests both versions
4. Canary — 1% production traffic
5. Ramp — 10% → 50% → 100%
6. Cleanup — remove shims + old version refs
```

Lead agent: `architecture-shepherd` (via `arch-dependency-upgrade`).
Critical path: 1 → 3 → 4 → 5 → 6.

---

## Common discipline across patterns

### Phase count: 3–7

- Fewer than 3 → scenario is small; use direct execution.
- More than 7 → decomposing too finely; those are tasks within
  phases.

### Phase duration: ≤ sprint (2 weeks)

Longer phases hide drift. If a phase needs more than 2 weeks,
split.

### Every phase has

- One coherent outcome.
- Named owner.
- Specific deliverable.
- Defined gate (see [gate-vocabulary.md](gate-vocabulary.md)).
- Bounded duration.

### Re-using patterns

These patterns aren't templates to fill in mechanically. They're
**starting points** for the scenario-strategist's workflow-design
phase. Adapt:

- Drop phases that don't apply.
- Add phases for scenario-specific needs.
- Re-order if dependencies differ.
- Adjust durations per team capacity.

The pattern gives you a defensible starting structure; the
adaptation gives you the right one.

---

## When no pattern fits

If the scenario doesn't fit any pattern above:

1. **Identify the scenario's load-bearing dependencies** — what
   must exist before the rest can proceed.
2. **Group work into coherent phases** with a deliverable each.
3. **Verify reversibility per phase** — split anything non-
   reversible.
4. **Name owners + gates.**

Then submit the new pattern back to this catalogue.

---

## Anti-patterns

- **"Discovery" forever phase.** Discovery should be time-boxed;
  perpetual discovery = avoidance.
- **No "decide" phase.** Some patterns include explicit decision
  phases; others have decisions implicit in deliverables. Be
  clear which.
- **Cleanup as optional follow-up.** Always make cleanup a
  phase; follow-ups don't happen.
- **Implicit parallelism.** Phases that *could* run in parallel
  should be declared parallel; otherwise sequential is assumed.
- **No critical-path declaration.** Without critical path,
  prioritisation is ad-hoc.
