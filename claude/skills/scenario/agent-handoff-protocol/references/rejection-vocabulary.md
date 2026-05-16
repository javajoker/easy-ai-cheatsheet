# Rejection Vocabulary — specific gap names for handoff rejections

When a receiving agent rejects a handoff, the rejection note
must **name specific gaps** using consistent vocabulary, not
vague dissatisfaction.

## Why vocabulary matters

Vague rejection (*"this doesn't work"*) → producer doesn't know
what to fix → re-submission likely also rejected → trust breaks
down.

Specific rejection with named gaps → producer knows the work →
single iteration to acceptance.

---

## Gap categories

### G1 — Structural

The artifact's shape is wrong (sections missing, format
incorrect).

**Examples:**

- "Missing § Decision Record."
- "Phase 3 has no rollback procedure."
- "Migration plan has only 2 phases; needs ≥3."
- "No interface-lock notification mechanism specified for Phase 2."

**Resolution:** Add the missing section(s); resubmit.

---

### G2 — Content quality

Sections exist but content doesn't meet the bar.

**Examples:**

- "Option 0 (do nothing) baseline missing in options matrix."
- "Phase 3 deliverable is too vague (\"build the feature\")."
- "Rollback procedure is prose; needs verbatim commands."
- "Acceptance criteria are non-testable (\"high quality\")."
- "Pain points lack anchors — only one of five cites evidence."

**Resolution:** Rewrite affected sections; resubmit.

---

### G3 — Quantitative

A numerical threshold is unmet.

**Examples:**

- "Error rate canary 1.12× baseline (gate threshold: 1.05×)."
- "p95 latency 240ms (target: 200ms)."
- "Coverage 73% (threshold: 80%)."
- "Recall@10 0.87 (threshold: 0.90)."

**Resolution:** Address the underlying issue; resubmit when
metric meets threshold.

---

### G4 — Ownership / accountability

Named owner / approver missing or unclear.

**Examples:**

- "Phase 3 owner is \"the team\" — needs named individual or team-with-lead."
- "Decision approver not recorded in Decision Record section."
- "Migration plan critical-path phase has no on-call coverage."

**Resolution:** Assign named owner; record approval; resubmit.

---

### G5 — Verification

Verification mechanism missing.

**Examples:**

- "Audit gate declared but no audit rows specified."
- "Metric gate declared but no dashboard URL."
- "Decision gate declared but no recording mechanism."

**Resolution:** Add verification mechanism; resubmit.

---

### G6 — Dependency

A required upstream input is missing or stale.

**Examples:**

- "Migration plan references arch-assessment, but assessment is
  v1; latest is v2."
- "Workflow design assumes scenario-brief v1; v2 was locked
  yesterday."

**Resolution:** Update to current upstream input; rework as
needed; resubmit.

---

### G7 — Compliance / regulatory

Compliance requirement unmet.

**Examples:**

- "Security baseline FAIL row 4.6 unresolved + unwaived."
- "Customer data handling not GDPR-compliant per § 3.5."
- "HIPAA-PHI in event payload — must be removed."

**Resolution:** Address compliance gap; resubmit.

---

### G8 — Scope creep / scope mismatch

Deliverable doesn't match the scope it was supposed to address.

**Examples:**

- "Deliverable addresses Phase 2 + Phase 3; scope was Phase 2
  only."
- "Migration plan covers system X; scenario brief was about
  system Y."

**Resolution:** Re-scope deliverable to match agreed scope;
resubmit.

---

## Rejection note format

```markdown
## Rejection — <handoff name>

**Date:** YYYY-MM-DD
**Rejecter:** <agent / receiver name>
**Re-acceptance target:** YYYY-MM-DD (typically +3 business days
or next sync point)

### Gaps named

- **G1 (structural):** Migration plan has 2 phases; needs ≥3.
  Reference: `migration-plan.md` (current state).
- **G4 (ownership):** Phase 2 owner field empty.
- **G3 (quantitative):** Coverage 73% (threshold 80%); see
  `coverage-report.html`.

### Resolution path

The producer addresses the gaps above and resubmits. The receiver
re-audits at the next sync point.

### Escalation if disputed

If the producer disagrees with any of the rejection rows, escalate
to the conductor (per `handoff-protocols.md`).
```

---

## Two-rejection rule

If the same handoff is rejected **twice**, the workflow has a
structural issue. Conductor escalates:

1. **Re-audit producing phase scope** — is the work scoped
   correctly?
2. **Re-audit acceptance criteria** — are they appropriate for
   the receiver's actual need?
3. **Re-audit producing agent's capability fit** — was group
   formation correct?

Don't allow a third rejection of the same handoff; that's a
process failure.

---

## Anti-patterns

- **Vague rejection.** "Doesn't work" / "not good enough" / "needs
  more work" — useless to producer.
- **Multiple gaps as single note.** Each gap gets its own row in
  the rejection note; aggregation hides specifics.
- **Rejection without re-acceptance target.** Producer doesn't
  know when to resubmit.
- **Rejection without escalation path.** Producer and receiver
  disagree; no path forward.
- **Verbal rejection.** No record means no rejection; gap
  resurfaces on next attempt.
- **Punitive language.** Rejections are about *the work*, not
  *the producer*. "Phase 2 has gap G4" not "Phase 2 author
  didn't include owner."
