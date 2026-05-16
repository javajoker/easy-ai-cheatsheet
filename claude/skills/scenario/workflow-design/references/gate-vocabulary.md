# Workflow Gate Vocabulary

Concrete examples of each of the four gate kinds used in
`workflow-design`. A gate is what moves the workflow from one
phase to the next.

## The four gate kinds

| Kind | What it checks | Source of truth |
|---|---|---|
| **Audit** | Deliverable passes a structured audit | `requirement-audit` PASS rows |
| **Review** | Named human reviewer signs off | Reviewer's recorded approval |
| **Metric** | A measured threshold is met | Dashboard / observability data |
| **Decision** | A named authority decides | Decision record |

Pick the gate kind that fits the phase's deliverable. Different
phases may use different gate kinds.

---

## Audit gates

The phase's deliverable is structured enough for row-by-row
verification.

### Examples

| Phase deliverable | Audit gate |
|---|---|
| Architecture assessment (`arch-assessment` output) | `requirement-audit` against assessment quality criteria (every option has critical assumption; every pain anchored; etc.) |
| Migration plan (`arch-migration-plan` output) | `requirement-audit` against plan quality criteria (every phase reversible; every phase has owner; etc.) |
| Launch readiness audit | The audit itself — all FAIL rows resolved or waived |
| Security baseline | Security audit — all FAIL rows resolved or waived |
| KB merge | Merge report — all conflicts resolved before apply |

### When to use

- Deliverable is a structured document with verifiable claims.
- Quality criteria are pre-agreed.
- Repeatable verification across reviewers.

---

## Review gates

A named human reviewer signs off.

### Examples

| Phase deliverable | Review gate |
|---|---|
| PRD draft | Product lead approves |
| API contract | Tech lead approves |
| Migration plan | VP Engineering approves |
| Rollout strategy | SRE lead approves |
| Customer comms draft | Marketing lead approves |
| Pricing change | CFO approves |

### When to use

- Deliverable requires expert judgement.
- Reviewer brings specialised context (legal, security, brand).
- Lower-stakes than audit; doesn't need structured row-by-row.

### Discipline

- Reviewer is **named**, not "the team."
- Approval is **recorded** — Slack message, PR comment, email.
- Reviewer has **authority** — empowered to actually block.

---

## Metric gates

A measured threshold from observability / analytics data.

### Examples

| Phase | Metric gate |
|---|---|
| Performance optimisation | p95 latency ≤ target (e.g. 200ms) |
| Canary ramp stage 1 | Error rate canary ≤ 1.05× baseline over 1h |
| Activation funnel improvement | Activation rate ≥ baseline × 1.10 |
| Cost optimisation | Monthly cost ≤ budget × 1.05 |
| KB freshness | % entities reviewed in window ≥ 95% |
| Search relevance | Recall@10 ≥ 90% on benchmark |

### When to use

- Deliverable has a measurable outcome.
- Baseline exists for comparison.
- Observability instrumentation in place.

### Discipline

- Gate is **specific** — a number, a unit, a time window.
- Gate has a **dashboard URL** — auditors and operators see the
  same data.
- Gate is **sustained** — not point-in-time; required over a
  window.

See `arch-rollout-strategy/references/gate-vocabulary.md` for
production-rollout-specific metric gates.

---

## Decision gates

A named authority makes a decision.

### Examples

| Phase | Decision gate |
|---|---|
| Options matrix complete | Decision authority picks chosen option |
| Beta exit | Product VP decides "open beta vs hold" |
| Launch decision | Launch committee says GO / NO-GO |
| Migration commitment | CTO commits to the migration plan |
| Public deprecation | Engineering + Product + Legal align |

### When to use

- Deliverable requires a strategic choice, not just verification.
- Multiple stakeholders need alignment.
- Reversal is significant (locking in direction).

### Discipline

- Authority is **named** — one role; not a committee unless the
  committee has a designated decision-maker.
- Decision is **recorded** — meeting notes, decision memo, memory
  entry.
- Rationale is **documented** — the *why* outlives the decision.

---

## Combining gate kinds

A single phase may have **multiple gates** that must all be
satisfied:

| Phase | Combined gates |
|---|---|
| Phase: "Launch readiness assessment" | Audit gate (`gtm-launch-readiness` PASS) + Decision gate (launch authority GO) |
| Phase: "Canary at 1%" | Metric gate (error rate threshold) + Review gate (on-call approves ramp) |
| Phase: "Migration plan locked" | Audit gate (plan quality) + Decision gate (decision authority commits) |

Don't conflate — list each gate explicitly. Conflated gates
become ambiguous.

---

## Gate documentation in workflow-design.md

For each phase:

```markdown
### Phase 3 — <name>

| Field | Value |
|---|---|
| Gate kind | audit + decision |
| Audit | `requirement-audit` against `assessment-template.md` quality criteria |
| Decision | <named authority> commits to chosen option |
| Verification | Both checks at sync-point 1 |
```

---

## Anti-patterns

- **"Gates green when team agrees we're done."** That's not a
  gate; that's an opinion.
- **No verification step.** Gate exists but nobody runs the
  check.
- **Verification by the gate-passer.** Engineer self-approves
  their own gate. Use independent verification.
- **Gates without sustained-over-window for metric gates.**
  Point-in-time spikes pass; sustained issues miss.
- **Decision gate without recorded rationale.** Six months
  later, nobody knows why.
- **Audit gate without rubric.** Different auditors, different
  results.
