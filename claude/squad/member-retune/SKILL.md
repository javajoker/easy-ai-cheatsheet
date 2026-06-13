---
name: member-retune
description: Keep a member's evidence honest when the product underneath it moves — the squad sibling of maintenance's skill-version-tune. When a member's model/CLI version, pricing, or data-use terms change, read its evaluated: stamps and (measured) lines, classify each rating as keep (version change can't plausibly affect it), stale (mark (stale) — routing treats it one rating lower — and queue a targeted Scenario W re-eval), or re-gate (terms changed — data_handling back to BLOCKED pending human review); and on ledger-driven concerns, summarize the member's true record (pass rate, escalation rate, cost per accepted task) and propose benched or retired. All sheet/roster changes land as Gate 4 diffs. Use this skill when the user says "gemini-cli shipped a new model — retune it", "<member>'s pricing changed", "is <member> still worth its seat", "the ledger looks bad for <member>", or "this member hasn't been used in months". Never blanket re-runs everything and never silently keeps pre-version evidence. Pairs with eval-design/eval-run (the queued re-evals), member-onboard (re-anchoring member_version), and memory-ontology (records pending re-evals).
---

# Member Retune

The roster decays silently: products ship new models, prices move, terms
change, and yesterday's `(measured)` becomes today's folklore. This skill
is the deliberate response — transferred from
[`maintenance/skill-version-tune`](../../maintenance/skill-version-tune/),
with the member sheet in place of the capability sheet and ratings in
place of skill shape.

The two failure modes it exists to prevent, equally costly:

- **Trusting forever** — routing `ship` work on evidence from three
  versions ago.
- **Re-running everything** — paying full eval cost for task classes the
  change can't plausibly have moved.

## Procedure

### Phase 0 — Establish what actually changed

Confirm the change against the runtime, not the rumor: run the version
command from the invocation contract, compare against the sheet's
`member_version`; for pricing/terms changes, ask the user for the source.
Classify the change: **model** (quality may move), **CLI/interface**
(contract may break), **pricing** (band may move), **terms**
(data-handling must re-gate). No actual change → stop; nothing to retune.

### Phase 1 — Walk the evidence

For each `evaluated: <task-class>@<old-version>` stamp and its
`(measured)` lines, classify:

- **keep** — the change can't plausibly affect it (a pricing change
  doesn't move translation quality; a model change doesn't move the
  invocation contract). Say why in the proposal.
- **stale** — the change plausibly moves the result (model change vs.
  any quality rating; CLI change vs. reliability). Mark `(stale)` on the
  sheet; ROSTER treats it one rating lower until re-measured.
- **re-gate** — terms/pricing: `data_handling` → BLOCKED pending the
  human re-reading the new terms; `cost_band` re-estimated.

Interface changes additionally require re-running the onboarding smoke
test before any further dispatch.

### Phase 2 — Queue targeted re-evals

For stale ratings, recommend re-evals (Scenario W) **in routing-pressure
order**: task classes the ledger shows actually route to this member
first; classes nobody routes can stay `(stale)` indefinitely at zero
cost. Existing eval specs are reused — scores stay comparable across
versions. Record queued re-evals via `memory-ontology` so they survive
the session.

### Phase 3 — Ledger-driven review (when invoked for performance, not version)

Summarize the member's record from `docs/squad/ledger.md`: dispatches,
pass rate, escalation rate, **true cost per accepted task** (member cost
+ verify + escalation overhead). Compare against in-house doing the same
work. Propose accordingly: keep / `benched` (seat not currently
justified; sheet kept) / `retired` (sheet archived, roster row kept for
ledger history). A bench/retire proposal cites the record, never an
incident.

### Phase 4 — Land it (Gate 4)

One reviewable diff: sheet tag changes, `member_version` re-anchor,
roster suffixes/status, and the re-eval queue. User approves; it lands.

## Anti-patterns

- **Rumor-triggered retunes.** "I heard they shipped a new model" —
  verify against the runtime first; retuning toward an unconfirmed
  version is the same sin as maintenance tuning toward an unreachable
  one.
- **Blanket staleness.** Marking everything stale on any change is lazy
  and triggers eval spend the change doesn't justify. Classify per
  rating, with reasons.
- **Silent evidence carry-over.** The opposite sin: a model changed and
  the quality ratings just… stayed. Every kept rating states why keeping
  is sound.
- **Punitive retirement.** One bad week is ledger noise. Bench/retire
  cites the rolling record.
- **Hand-editing tags.** Staleness lands through this skill's Gate 4
  diff, so the reasoning is on the record.

## Companion skills

| When… | Use |
|---|---|
| Running the queued re-evals | `eval-design` + `eval-run` (Scenario W) |
| The contract broke with the new CLI | `member-onboard` (re-run smoke test, fix contract) |
| Recording the queue across sessions | `memory-ontology` |
| The version-axis sibling for the framework's own artifacts | `../../maintenance/skill-version-tune` |
