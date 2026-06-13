---
name: squad-route
description: Pick who executes a task — the cheapest squad member whose measured rating clears the stakes bar, whose data-handling clearance covers the inputs, and whose status allows the work; in-house (Claude) when nobody clears. Reads ROSTER.md and the member sheets at runtime (never hardcodes members), applies the eligibility filter, orders eligible members by cost band, and surfaces a routing decision record: chosen member, why, estimated cost, fallback. Honors Gate 2 and the gate mode — under gate=human ask above the budget threshold; under gate=auto proceed unattended below the strategic floor (sensitive data, ship stakes, over-cap pause under auto); the explicit gate=auto-unsafe crosses those pauses too but still cannot send to a BLOCKED data class or exceed the hard cap. Validates a check=<name> for independence (different vendor than the chosen member) and a verifier rating, falling back to the in-house ladder otherwise. Use this skill when the user says "who should do this", "route this", "can this go to a cheaper model", "pick a squad member for X", or as the squad-lead agent's step 2 after classification. Requires the task to be classified first (task class, stakes, data sensitivity, acceptance criteria fixed). Pairs with squad-dispatch (executes the decision), squad-verify (the criteria the decision will be judged by), eval-design/eval-run (when an unrated pair blocks a route worth unblocking), and ROSTER.md (the single source of routing truth).
---

# Squad Route

The decision: *who runs this task*. Routing is a filter then a sort —
never a vibe. Everything it reads is on the roster and the sheets;
everything it decides is written down before dispatch.

## Procedure

### Phase 0 — Require classification

Inputs (from `squad-lead`'s classify step, or gathered now):

- **`lead` mode** — `powerful` (default if unset) or `common`. The
  caller's switch between the two situations; it decides whether the
  single-task guard below applies.
- **`gate` mode** — `human` (default) or `auto`. Sets the Phase-3
  disposition: `auto` proceeds without asking *below the strategic floor*
  (`sensitive` data, `ship` stakes, over-cap), which always pauses.
- **`check`** — `default` (in-house ladder) or a registered check name.
  A named check is validated here for **independence** (different vendor
  than the chosen member) and a verifier rating before it is recorded.
- **Task class** — one of the roster columns.
- **Stakes** — `throwaway` / `internal` / `ship`.
- **Data sensitivity** — `public` / `internal` / `sensitive`, judged on
  *everything* the dispatch would send: files, prompt text, error
  messages.
- **Acceptance criteria** — must already be fixed. Routing before
  criteria invites criteria that fit whatever came back.

**Single-task Situation-2 guard.** When `lead=common`, the same rule
`squad-plan` applies per node applies to a lone task: if it routes a
member more capable than the common verifier, its verification must rest
on a deterministic oracle (verifiable output) or a sub-`ship` cross-vendor
`cross-validate` gate (judgment output). A `ship`-stakes judgment task
under `lead=common` with no oracle is **not routable as-is** — surface
it and either escalate its verify step to a powerful judge (caller
accepts the premium spend) or decline. Under `lead=powerful` (default)
the guard is inactive — the in-house judge can certify anything.

### Phase 1 — Filter for eligibility

From [`ROSTER.md`](../ROSTER.md), a member is eligible iff **all** hold:

1. **Rating clears the stakes bar** (roster's stakes-bar table; a
   `(stale)` rating counts one lower).
2. **Data-handling clearance covers** the inputs' data class (member
   sheet frontmatter; BLOCKED covers nothing).
3. **Status allows it**: `active` for real work; `probation` for
   `throwaway` only; `home` is always eligible as fallback.

The filter order is deliberate: capability, then safety, then — only
among survivors — cost.

### Phase 2 — Sort and choose

Cheapest cost band wins; within a band, the better measured result for
this task class (kit rating first); still tied → lower measured latency.
In-house is the choice when no member survives the filter, when the task
needs session context (cold-start members can't have it), or when the
**all-in cost won't beat the in-house baseline** — that is the member
band *plus the orchestration tax* (this lead's own classify/route/verify
tokens) *plus expected verify-and-escalation overhead*, compared against
Claude just doing it. Routing a $0.02 task that costs $0.05 to route and
check is a loss the layer exists to avoid; the estimate below makes that
comparison explicit, and in-house is a first-class answer to it.

**Confidence as a re-route input.** If this route is the escalation step
after a prior return, read that return's self-reported `confidence` (the
optional kit field): a member that *flagged its own low confidence*
should not get the one same-member retry (it already told you it would
fail) — skip straight to the next-ranked fallback. High self-confidence
never shortcuts anything (it is the generator grading itself); it is
verify's job, not routing's, to disbelieve it.

**Cross-validate gate → select cross-vendor peers.** If the node's gate
is `cross-validate`, resolve **≥2 eligible members from different
vendors** (decorrelation is the whole point — two instances of one model
prove nothing). If only one vendor is eligible, the cross-validate gate
is not satisfiable: say so, and fall back to the deterministic oracle or
in-house judgment per `squad-verify`'s ladder. Record all peers in the
decision.

**Custom check → validate independence + rating.** If `check=<name>` is
set, the named check is the verifier for this route. Validate it like a
cross-vendor peer: it must be a **different vendor than the chosen
member** (a check sharing the generator's model is self-grading) and
carry a verifier rating. An **unrated** check may add signal but cannot
replace the in-house rung at stakes; a **non-independent** check is
refused outright — fall back to `check=default`. Record the resolved
check (and the fallback, if it was refused) in the decision.

### Phase 3 — Record and gate (Gate 2)

Write the routing decision (it becomes the head of the dispatch record):

```markdown
# Routing decision — <date>-<slug>
lead: <powerful|common>      # the caller's mode (powerful if unset)
gate-mode: <human|auto>      # approval mode (human if unset); auto still pauses the strategic floor
check: <default|<name>>      # verifier: in-house ladder, or a validated independent check
task class / stakes / data: <…>
eligible:  <member (rating, band, clearance)>…
excluded:  <member — first failed filter>…
chosen:    <member> · estimated cost: <band × volume>
all-in:    <member est + orchestration tax + expected verify/escalation>
baseline:  <est. in-house cost for the same task>   # route only if all-in < baseline
gate-rung: <schema|deterministic|cross-validate|in-house>   # under lead=common, what carries verification
fallback:  <next-ranked member or in-house>
```

Then the gate, modulated by the `gate` mode:

- **`gate=human` (default):** estimated cost within the roster's budget
  threshold → surface and proceed; above it, `ship` stakes, or
  `sensitive` data → ask first.
- **`gate=auto`:** proceed unattended *below the strategic floor*
  (recording the decision); the floor — over-cap cost, `ship` stakes, or
  `sensitive` data — **still pauses for a human**, exactly as in `human`
  mode. Auto removes the click on routine routes, never on the floor.
- **`gate=auto-unsafe`:** proceed unattended through `ship` stakes and
  `sensitive` data **too** (recorded, flagged `auto-unsafe`) — *but
  within the two hard limits a route cannot cross even here*: a member
  whose `data_handling` does **not** already clear the inputs is still
  ineligible (BLOCKED blocks — `auto-unsafe` never auto-writes a
  clearance), and an estimate **over the hard cap** still stops (not
  pauses — re-plan or raise the cap explicitly). `auto-unsafe` removes
  the high-stakes click; it does not widen the data boundary or the spend
  ceiling.

If the route failed only because a pair is **U**, say which eval
(Scenario W) would unlock it — that note is how the roster grows where
routing pressure actually is.

## Anti-patterns

- **Cost-first filtering.** Filtering by price before capability/safety
  is how C-rated free members end up writing shipped code. Filter, then
  sort.
- **Reputation routing.** "X is supposed to be great at this" — U is U.
- **Sensitivity creep.** The data class is judged on the full dispatch
  payload, including "just one config file" that happens to hold keys.
- **Unwritten decisions.** A route with no record can't be audited when
  verify fails or the ledger looks wrong.
- **Routing for routing's sake.** In-house is a first-class answer, not
  a defeat — the layer exists to make the *choice* deliberate.
- **Ignoring the orchestration tax.** Comparing the member's band against
  in-house while forgetting the lead's own routing + verify tokens makes
  every route look cheaper than it is. Compare all-in vs. baseline.
- **Trusting confidence to route up.** A member's high self-confidence is
  not eligibility — only `(measured)` ratings are. Confidence may only
  *redirect an escalation*, never grant a route.

## Companion skills

| When… | Use |
|---|---|
| Executing the decision | `squad-dispatch` |
| A U pair blocks a route worth unblocking | `eval-design` + `eval-run` |
| The criteria + gate ladder the route will be judged by | `squad-verify` |
| The node's gate kind + verifier posture that shape eligibility | `squad-plan` |
| Contested classification terms | `cognitive-alignment` |
