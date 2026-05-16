---
name: gtm-beta-program
description: Designs a structured beta program — cohort phases (internal dogfood → closed beta → open beta → public launch), per-phase cohort size, intake form, screening criteria from the ICP, success criteria, exit criteria, feedback loop, and beta-specific telemetry. Output is beta-program-plan.md plus an intake-form schema and a feedback-triage rubric. Use this skill when the user says "we want to run a beta", "design the beta cohort", "what does the closed beta look like", "set the exit criteria"; or when lifecycle-pilot reaches Phase 7. Pairs with gtm-positioning (ICP drives screening, anti-ICP drives rejection), gtm-analytics-instrumentation (beta cohorts get extra telemetry), requirement-audit (verifies exit criteria are testable), and memory-ontology (records cohort decisions for the post-launch review).
status: shipped
owner_agent: lifecycle-pilot
---

# GTM Beta Program

A beta isn't *"let some users in early"* — it's a structured
learning program. This skill produces the plan.

## Why this exists

Unstructured betas fail in predictable ways:

- **No screening.** Anyone in. The cohort is unrepresentative; the
  feedback is unrepresentative.
- **No exit criteria.** Beta drifts indefinitely; nobody knows when
  "GA" happens.
- **No feedback discipline.** Feedback lands in 6 different
  channels; the team triages by gut feel; learnings don't compound.
- **No beta telemetry.** The team can't tell what beta users do
  differently from internal users.
- **Same cohort, no phases.** Going from 5 friendlies to 50 strangers
  to 500 cold signups in one step skips the chance to learn at each
  scale.

This skill ships a phased plan with cohort sizes, screening
criteria, exit gates, and a feedback rubric.

## When to fire

Fire when:

- The user says *"design the beta"*, *"plan the closed beta"*,
  *"what does the beta look like"*.
- `lifecycle-pilot` reaches Phase 7 and a beta is part of the
  launch posture.

Do **not** fire when:

- The user is shipping straight to public (no beta) — the launch
  audit covers them; no beta plan needed.
- A beta is already running with a documented plan — offer to
  *audit* instead of *replace*.

## Inputs

Required:

- `positioning-brief.md` (ICP + anti-ICP).
- `PRD.md` (what's being tested).
- (Optional) `pricing-model.md` (decides if beta is free / paid-with-
  discount / unpaid trial).

Asked once (cap at 3):

1. **Beta scope.** What's in scope for beta (full product / one
   feature / one persona). Defaults to full product.
2. **Recruitment channels.** Where will candidates come from
   (waitlist / outbound / community / customer base).
3. **NDA posture.** None / soft (please don't share) / formal NDA.

## The procedure

### Phase 1 — Define the phases

The default four-phase ladder (each can be skipped with explicit
reasoning):

| Phase | Cohort | Goal |
|---|---|---|
| **0 — Internal dogfood** | Company employees | Surface obvious bugs before showing anyone outside |
| **1 — Closed beta** | 10–50 hand-picked ICP users | Validate value prop in real conditions; learn what we don't know |
| **2 — Open beta** | 100–1000+ from waitlist | Pressure-test scale; refine onboarding |
| **3 — Public launch** | Everyone | Steady-state operation |

For each phase, the skill emits:

- Cohort size range with rationale.
- Duration (typical: dogfood 1–2 weeks; closed 4–8 weeks; open
  4–12 weeks).
- Entry criteria.
- Exit criteria (load-bearing — must be defined before phase starts).

### Phase 2 — Screen candidates against ICP

Closed beta especially: every candidate is scored against the ICP
table from the positioning brief.

Output: **intake form schema** with questions that map directly
onto the ICP fields:

```json
{
  "questions": [
    { "id": "company_size", "label": "Company size", "type": "select",
      "options": ["1-5", "6-20", "21-100", "100+"], "icp_field": "size" },
    { "id": "current_solution", "label": "What do you use today?",
      "type": "text", "icp_field": "behavioural" },
    { "id": "trigger", "label": "What made you sign up?",
      "type": "text", "icp_field": "trigger" },
    { "id": "expected_use", "label": "How would you use this?",
      "type": "text", "icp_field": "problem" },
    { "id": "commit_feedback", "label": "Willing to commit to a
      15-min weekly check-in for the beta?", "type": "boolean", "icp_field": null }
  ]
}
```

**Scoring rubric:** 0–3 per ICP field; cohort fills with the top
N scorers. Reject candidates matching anti-ICP regardless of
ICP score.

### Phase 3 — Define exit criteria per phase

This is the discipline that prevents indefinite-beta drift.

Each exit criterion must be:

- **Testable** — a number or a yes/no answerable from telemetry or
  user research, not from gut feel.
- **Pre-agreed** — agreed before the phase starts, not negotiated
  while the phase is running.

Example exit criteria:

**Phase 0 → Phase 1 (Internal → Closed):**
- ✓ No P0 bugs open
- ✓ Core flow completable end-to-end by every employee tester
- ✓ Onboarding doc draft exists

**Phase 1 → Phase 2 (Closed → Open):**
- ✓ ≥70% of closed beta cohort activated (defined event)
- ✓ ≥30% retained at week 4
- ✓ NPS ≥ 30 (or qualitative equivalent — top-2-box satisfaction)
- ✓ Critical-path issues found in closed beta are all fixed
- ✓ Support load per user is sustainable at 10× volume

**Phase 2 → Phase 3 (Open → Public):**
- ✓ Conversion + retention metrics meet pre-defined targets
- ✓ Launch-readiness audit (`gtm-launch-readiness`) is PASS
- ✓ Pricing model validated (open-beta users converted at
  expected rate, if monetised)
- ✓ Support + on-call capacity sized for public launch

### Phase 4 — Feedback loop design

Specify:

- **Channels.** One primary (e.g. dedicated Slack / Discord /
  community forum); one secondary (email feedback@); explicit
  *not channels* (no Twitter DMs counted as feedback).
- **Cadence.** Weekly check-in calls in closed beta; bi-weekly in
  open beta; office hours always.
- **Triage rubric.** Every piece of feedback classified:
  - **bug** — file in tracker, prioritise normally.
  - **gap** — feature the PRD missed; PM review.
  - **misalignment** — user expected something we don't do; clarify
    docs/copy, don't ship.
  - **wishlist** — log for post-GA roadmap.
- **Acknowledgement SLA.** Every piece of feedback acknowledged
  within 48h (even if not actioned).
- **Closing the loop.** Beta users hear back when feedback ships
  (or doesn't, with why).

### Phase 5 — Beta-specific telemetry

Most events from `gtm-analytics-instrumentation` apply to all
users. Beta cohorts also need *transient* events the team won't
keep tracking forever:

- `beta_user_signed_up`, `beta_user_activated`,
  `beta_user_retained_week_2/4/8`.
- Per-feature deep dives that production users won't get.
- Session replays (if privacy-acceptable and beta users
  consented).
- Synthetic events for friction (e.g. `clicked_help_link_during_X`).

These events are tagged `beta_only:true` and pruned after public
launch.

### Phase 6 — Emit the plan

Write `beta-program-plan.md` using
[references/beta-plan-template.md](references/beta-plan-template.md).

After writing:

1. Persist as `type: project` memory (`beta_<slug>_v1`).
2. Hand off intake form schema to engineering for implementation.
3. Hand off telemetry list to `gtm-analytics-instrumentation`.

## Anti-patterns

- **No screening for closed beta.** The wrong cohort produces the
  wrong learnings. Screen.
- **Unbounded beta.** Without exit criteria, beta becomes the
  product. Exit criteria are non-negotiable.
- **Feedback channel sprawl.** Pick a primary; route the rest to it.
- **Skipping internal dogfood.** Showing strangers the product
  before employees have used it produces avoidable embarrassment.
- **Same cohort 5 → 500.** Skipping a phase doubles the surprise
  surface area. If you must skip, document why and brace.
- **Lifetime "beta" badge.** A label that never goes away means
  the team isn't confident in the product. Either GA it or kill it.

## Companion skills

- `gtm-positioning` — ICP + anti-ICP for screening.
- `gtm-analytics-instrumentation` — telemetry pairing.
- `gtm-launch-readiness` — Phase 2→3 gate.
- `requirement-audit` — verify exit criteria are testable.
- `memory-ontology` — persist cohort decisions.

## Reference files

- [references/beta-plan-template.md](references/beta-plan-template.md) —
  canonical output shape.
- `references/intake-form-template.json` — JSON schema for the
  intake form.
- `references/feedback-triage-rubric.md` — the four-class
  classification with worked examples.
