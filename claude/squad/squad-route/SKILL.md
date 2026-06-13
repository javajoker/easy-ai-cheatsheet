---
name: squad-route
description: Pick who executes a task — the cheapest squad member whose measured rating clears the stakes bar, whose data-handling clearance covers the inputs, and whose status allows the work; in-house (Claude) when nobody clears. Reads ROSTER.md and the member sheets at runtime (never hardcodes members), applies the eligibility filter, orders eligible members by cost band, and surfaces a routing decision record: chosen member, why, estimated cost, fallback. Honors Gate 2 — auto-proceed below the roster's budget threshold, ask above it, always ask for ship stakes or sensitive data. Use this skill when the user says "who should do this", "route this", "can this go to a cheaper model", "pick a squad member for X", or as the squad-lead agent's step 2 after classification. Requires the task to be classified first (task class, stakes, data sensitivity, acceptance criteria fixed). Pairs with squad-dispatch (executes the decision), squad-verify (the criteria the decision will be judged by), eval-design/eval-run (when an unrated pair blocks a route worth unblocking), and ROSTER.md (the single source of routing truth).
---

# Squad Route

The decision: *who runs this task*. Routing is a filter then a sort —
never a vibe. Everything it reads is on the roster and the sheets;
everything it decides is written down before dispatch.

## Procedure

### Phase 0 — Require classification

Inputs (from `squad-lead`'s classify step, or gathered now):

- **Task class** — one of the roster columns.
- **Stakes** — `throwaway` / `internal` / `ship`.
- **Data sensitivity** — `public` / `internal` / `sensitive`, judged on
  *everything* the dispatch would send: files, prompt text, error
  messages.
- **Acceptance criteria** — must already be fixed. Routing before
  criteria invites criteria that fit whatever came back.

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
task is so small that routing overhead exceeds the work.

**Cross-validate gate → select cross-vendor peers.** If the node's gate
is `cross-validate`, resolve **≥2 eligible members from different
vendors** (decorrelation is the whole point — two instances of one model
prove nothing). If only one vendor is eligible, the cross-validate gate
is not satisfiable: say so, and fall back to the deterministic oracle or
in-house judgment per `squad-verify`'s ladder. Record all peers in the
decision.

### Phase 3 — Record and gate (Gate 2)

Write the routing decision (it becomes the head of the dispatch record):

```markdown
# Routing decision — <date>-<slug>
task class / stakes / data: <…>
eligible:  <member (rating, band, clearance)>…
excluded:  <member — first failed filter>…
chosen:    <member> · estimated cost: <band × volume>
fallback:  <next-ranked member or in-house>
```

Then the gate: estimated cost within the roster's budget threshold →
surface and proceed; above it, `ship` stakes, or `sensitive` data →
ask first. If the route failed only because a pair is **U**, say which
eval (Scenario W) would unlock it — that note is how the roster grows
where routing pressure actually is.

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

## Companion skills

| When… | Use |
|---|---|
| Executing the decision | `squad-dispatch` |
| A U pair blocks a route worth unblocking | `eval-design` + `eval-run` |
| The criteria + gate ladder the route will be judged by | `squad-verify` |
| The node's gate kind + verifier posture that shape eligibility | `squad-plan` |
| Contested classification terms | `cognitive-alignment` |
