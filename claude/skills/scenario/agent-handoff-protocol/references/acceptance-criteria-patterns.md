# Acceptance Criteria Patterns

Common shapes of acceptance criteria for inter-agent handoffs.
Each handoff has 3–6 criteria; this catalogue helps author them
consistently.

## The four shapes

| Shape | Source | Use when |
|---|---|---|
| **Audit-shaped** | `requirement-audit` row | Deliverable has structured rows |
| **Metric-shaped** | Dashboard threshold | Outcome is measurable |
| **Artifact-shaped** | File existence + structure | Deliverable is a document/file |
| **Decision-shaped** | Named authority sign-off | Outcome is a choice |

---

## Audit-shaped criteria

The producing agent runs `requirement-audit` against the
receiver's pre-agreed audit template.

### Examples

| Handoff | Acceptance criterion |
|---|---|
| `arch-assessment` → `arch-migration-plan` | `requirement-audit` against `assessment-template.md` quality criteria — all rows PASS |
| `lifecycle-pilot` Phase 6 → Phase 7 | `gtm-launch-readiness` audit — all rows PASS or PARTIAL-with-mitigation |
| `devops-engineer` workstream → `lifecycle-pilot` Phase 6 | Security audit — all rows PASS |
| `enterprise-kb-merge` → `enterprise-kb-search-index` | Merge report — all conflicts resolved + cross-refs rewritten |

### Verification snippet

```
`requirement-audit` against rows A1, A2, A3 in <template>.md
```

---

## Metric-shaped criteria

The receiving agent verifies a measurable threshold.

### Examples

| Handoff | Acceptance criterion |
|---|---|
| Canary stage 1 → stage 2 | `error_rate_canary / error_rate_baseline ≤ 1.05` over 1h |
| Beta Phase 1 → Phase 2 | `≥70% of closed beta cohort activated` (defined event) |
| Performance optimisation phase | `p95 latency ≤ 200ms sustained over 24h` |
| Search index re-index | `recall@10 ≥ baseline × 0.95` on benchmark |
| KB refresh policy | `≥95% of canonical entities reviewed in window` |

### Verification snippet

```
Dashboard <url>; metric <metric_name> meets <threshold> over <window>
```

---

## Artifact-shaped criteria

The receiving agent verifies the artifact's existence and structure.

### Examples

| Handoff | Acceptance criterion |
|---|---|
| Phase 1 deliverable → Phase 2 | `<path/to/file.md>` exists with sections A, B, C populated |
| Migration plan handoff | `migration-plan.md` contains 3–8 phases, each with reversible-checkpoint + owner + deliverable |
| Group formation output | `agent-group.md` exists with lead + supporters + conductor per phase |
| Comms artifacts | `breaking-change-comms.md` + per-audience drafts under `comms/` |

### Verification snippet

```
File `<path>` exists; has sections <A, B, C>; passes structural lint
```

---

## Decision-shaped criteria

A named authority's decision is recorded.

### Examples

| Handoff | Acceptance criterion |
|---|---|
| Options matrix → migration plan | Named decision authority recorded chosen option in `arch-assessment.md` § Decision Record |
| Launch readiness → launch | Launch decision authority approved GO with rationale |
| Pricing change | CFO + VP Product signed off on new pricing in `pricing-model.md` § Decision Record |
| Breaking change sunset | Named override authority recorded extension (if applicable) |

### Verification snippet

```
<file>.md § Decision Record contains: decision + date + authority + rationale
```

---

## Hybrid criteria (combine shapes)

A handoff may use multiple shapes:

```
Acceptance criteria for migration-plan → rollout-strategy handoff:

A1 (audit)    — `requirement-audit` against migration-plan quality rows (every phase reversible; every phase has owner; every interface lock has notification mechanism)

A2 (artifact) — `migration-plan.md` exists with all phases + dependency graph + sync points

A3 (decision) — Engineering lead's sign-off recorded in plan's decision section

A4 (metric)   — If the plan includes performance targets, baseline measurements captured for comparison
```

---

## Authoring acceptance criteria — discipline

1. **Each criterion is testable.** Either via audit, metric,
   artifact check, or decision verification.
2. **Each criterion is pre-agreed.** Producer and receiver both
   know what they're signing up for.
3. **3–6 criteria per handoff.** Fewer = under-specified; more =
   bureaucratic.
4. **Specific, not vague.** "High quality" fails the testability
   check. "All FAIL rows resolved or waived" passes.
5. **Tied to the receiver's actual need.** Criteria from the
   receiving agent's deliverable contract, not the producer's
   convenience.

---

## Common criteria mistakes

| Bad | Good |
|---|---|
| "Deliverable is high quality" | "All FAIL rows in audit resolved" |
| "Tests pass" | "`pnpm test` exits 0; coverage report shows ≥80%" |
| "Performance is acceptable" | "p95 latency ≤ 200ms over 24h on production traffic" |
| "Documentation is complete" | "`<path>/README.md` exists with sections A, B, C" |
| "Stakeholders are aligned" | "Named approver from <role> recorded sign-off" |
| "No major bugs" | "Zero P0 bugs in tracker; ≤3 P1 bugs with documented workarounds" |

---

## Source for criteria

Per `agent-handoff-protocol` Phase 2, criteria come from:

1. **The workflow's per-phase gate** (audit / review / metric /
   decision) — primary source.
2. **The receiving agent's AGENT.md deliverable contract** —
   what the receiver actually needs to do its job.
3. **Project-specific compliance / quality requirements** —
   anything documented in `INSTRUCTIONS/projects/<slug>/`.

---

## Anti-patterns

- **Vague criteria.** "Good enough" / "high quality" / "approved"
  → not testable.
- **Criteria not derived from receiver.** Producer-friendly
  criteria; receiver gets unusable input.
- **No verification mechanism.** Criterion exists; no way to
  check.
- **One mega-criterion.** "Phase is done" — split into specific
  testable criteria.
- **Acceptance by silence.** "If not rejected in 24h, considered
  accepted" — hides actual disagreement.
