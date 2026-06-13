# WORKFLOW — the squad pipeline, end to end

The full pipeline from "a new LLM product exists" to "it routinely takes
work and the ledger proves it saves tokens." Two loops share one roster:
the **evaluation loop** (slow, deliberate, builds trust) and the
**execution loop** (fast, per-task or per-job, spends trust). Five gates
keep both honest; the **State Ledger** keeps multi-member jobs from
compounding tokens.

```
        EVALUATION LOOP (builds trust)
  ┌────────────────────────────────────────────────────────┐
  │  ONBOARD ──► KIT-BUILD ──► EVAL-DESIGN ──► EVAL-RUN    │
  │  member-onboard  kit-build    eval-design     eval-run │
  │    [Gate 0]     (calibrate)    [Gate 1]       [Gate 4] │
  └───────────────────────────┬────────────────────────────┘
                              ▼
                  ROSTER.md (class + kit ratings) ◄────────────┐
                              │                                │
        EXECUTION LOOP (spends trust)                          │ rating
  ┌───────────────────────────▼────────────────────────────┐   │ feedback
  │  CLASSIFY ──► PLAN? ──┬─(task)──► ROUTE ──► DISPATCH   │   │
  │  squad-lead  squad-plan│        squad-route squad-disp.│   │
  │               [Gate 2] │                               │   │
  │                        └─(job)──► per-node loop ──┐    │   │
  │                                   ▲               │    │   │
  │                     STATE LEDGER ─┴── hydrate /   │    │   │
  │                     (squad-state)     merge deltas│    │   │
  │                                                   ▼    │   │
  │   ──► VERIFY (gate ladder) ──► INTEGRATE ──► LEDGER ───┼───┘
  │       squad-verify [Gate 3]                            │
  └────────────────────────────────────────────────────────┘
```

## The five gates

| Gate | Where | What a human approves | Default |
|---|---|---|---|
| **0 — Membership** | `member-onboard`, before first invocation | The MEMBER.md draft: invocation contract, cost band, and especially the data-handling section (starts BLOCKED). | Always ask. |
| **1 — Eval spec** | `eval-design`, before any eval spend | The golden task set + rubric (= the kit's acceptance criteria when a kit exists). Bad rubric = worthless ratings. | Always ask. |
| **2 — Routing / plan** | `squad-route` per task; `squad-plan` per job | The routing decision (member, rationale, estimated cost, fallback) — or for jobs, the whole plan: verifier posture, nodes, tiers, gate kinds, budget, breaker. A plan failing the Situation-2 guard never reaches this gate. | Auto-proceed below the budget threshold in `ROSTER.md`; ask above it, ask always for sensitive data or `stakes: ship`. |
| **3 — Integration** | `squad-verify`, after dispatch | Nothing integrates (and no delta merges into the State Ledger) without a PASS. PARTIAL integrates only with gaps explicitly accepted. Quarantined deltas are readable/editable before the decision — the Glass Box. | Always enforced; report always shown. |
| **4 — Roster movement** | `eval-run` / rating feedback | Any rating or status change, as a diff preview (the `skill-merge` discipline). | Always ask. |

## Phase by phase

### Phase 1 — Onboard (`member-onboard`)

**In:** a product name and how to reach it. **Out:**
`members/<name>/MEMBER.md` + a `probation`/U row in ROSTER.md.

The membership bar: non-interactively invocable, capturable output,
stated cost model. The sheet starts all-`(claimed)`; the data-handling
section starts BLOCKED. A smoke test (one trivial prompt) confirms the
invocation contract actually works. Gate 0 closes the phase.

### Phase 2 — Package and evaluate (`kit-build` → `eval-design` → `eval-run`)

**In:** the skill/task you want routable + the members to measure.
**Out:** a calibrated kit, an approved eval spec, per-member scorecards,
`(measured)` evidence, ratings, and `evaluated:` stamps.

The evaluation unit is **member × kit** wherever a kit exists: `kit-build`
packages the framework skill's discipline into a member-portable brief
with a JSON wire contract and acceptance criteria, calibrated by an
in-house cold dry-run. `eval-design` then reuses the kit's criteria as
the rubric (one contract for eval and production — eval results predict
dispatch results) and adds golden payloads, including at least one
**trap task** and one **scale probe**. Where no kit exists, the eval
falls back to bare task-class prompts — coarser, still honest.

Eval dispatches go through `squad-dispatch`, so the eval also measures
invocation reliability, latency, and cost. Gates 1 and 4 bracket the
phase.

### Phase 3 — Organize (ROSTER.md)

The roster is the single source of routing truth, at two granularities:
the **class matrix** (coarse) and **kit ratings** (fine — preferred by
routing when present). The org disciplines:

- **U takes nothing that matters.** Unrated pairs may take
  `stakes: throwaway` tasks only, and only to generate evidence.
- **Stale is not rated.** When `member-retune` flags a version change —
  or a kit's contract changes under `kit-build` re-derivation — affected
  ratings carry `(stale)`; routing treats stale as one rating lower.
- **Demotion is mechanical.** Two verified failures at a rating's stakes
  level propose a demotion (Gate 4). Promotion needs a fresh eval or a
  sustained pass record, never a single good day.

### Phase 4 — Execute (`squad-plan?` → per node: `squad-route` → `squad-dispatch` → `squad-verify`)

**In:** a task or a job. **Out:** integrated work + records + ledger
entries.

1. **Resolve `lead` mode + classify** (`squad-lead`). Read the caller's
   `lead` flag (`powerful` default if unset — Situation 1; `common` for
   Situation 2) and carry it as the verifier posture. Then: task
   class/kit; stakes (`throwaway`/`internal`/`ship`); data sensitivity.
   Acceptance criteria are fixed **now** (the kit's criteria, when one
   exists) — criteria written after seeing output are not criteria.
2. **Plan — jobs only** (`squad-plan`). Multi-stage work becomes a DAG:
   nodes bind **kits + cost tiers** (never member names — members
   resolve at dispatch time, so a roster change re-routes the next node
   with no plan edit), declare ledger inputs/outputs, and pick the
   cheapest sufficient gate. Job budget set, **80% circuit breaker**
   armed, State Ledger opened (`squad-state`). Single-stage tasks skip
   straight to routing. Gate 2 covers the decision either way.
3. **Route** (`squad-route`). Eligible = rating (kit rating first)
   clears the stakes bar AND data-handling covers the inputs AND status
   allows it. Cheapest band wins. **Try-cheap-first** is the default
   shape: draft tiers low, with escalation behind the gate.
4. **Dispatch** (`squad-dispatch`). Per the MEMBER.md contract:
   sandboxed worktree, **hydrated payload** (kit brief + only the
   ledger keys the node declared — never history), cost cap, timeout,
   transcript. Returns are schema-validated on arrival (free,
   deterministic) and land **quarantined**.
5. **Verify** (`squad-verify`) — the **gate ladder**, cheapest first:
   schema (already done) → **deterministic** results oracle (run the
   code, run the tests, diff the artifact, grep the invariant — free; if
   a compiler can decide it, no LLM is asked) → **cross-validate**
   (≥2 cross-vendor members compared — signal only: passes low-stakes
   agreement, escalates disagreement or `ship` stakes) → **in-house
   judgment** (premium, the rung of last resort). PASS → merge the delta
   / integrate. PARTIAL/FAIL → the escalation ladder: **one** retry with
   named gaps → next-ranked member → in-house. Never more than one retry
   to the same member on the same node. Gate 3. **The verifier's
   required power is set by the task class** — a verifiable-output node
   can be certified by the oracle even under a common lead (Situation 2);
   a `ship`-stakes judgment node always needs in-house judgment.
6. **Ledger.** Per dispatch: estimated vs. actual cost, outcome,
   escalations — into `docs/squad/ledger.md`; job ledgers reconcile on
   close. The ledger is the proof the layer pays for itself: the
   number that matters is **cost per accepted task** (member + verify +
   escalation overhead) vs. in-house.

### Phase 5 — Learn (rating feedback + `member-retune` + playbook)

Execution outcomes flow back three ways: verify results accumulate per
member×kit and propose rating moves (Gate 4); product version changes
trigger `member-retune` (targeted re-evals, never blanket); and
completed job plans with their actuals distill into
`docs/squad/playbook/` so recurring job shapes skip re-planning.

## Who conducts

The [`squad-lead`](squad-lead/AGENT.md) agent owns the execution loop —
classify, plan-or-route, and the per-node walk — and triggers the
evaluation loop when routing hits a gap. The human owns the five gates.
Claude in-house remains the verifier always and the executor of last
resort — the pipeline degrades gracefully to "Claude just does it,"
which is exactly the pre-squad baseline.

## Artifact map

| Artifact | Lives at | Written by |
|---|---|---|
| Member sheet | `squad/members/<name>/MEMBER.md` | `member-onboard`, updated by `eval-run` / `member-retune` |
| Kit | `squad/kits/<kit-name>/KIT.md` | `kit-build` |
| Roster (class + kit ratings) | `squad/ROSTER.md` | `eval-run`, rating feedback (Gate 4) |
| Eval spec | `docs/squad/evals/<task-class>/eval-spec.md` | `eval-design` |
| Scorecard | `docs/squad/evals/<task-class>/<member>-<date>.md` | `eval-run` |
| Job plan | `docs/squad/jobs/<job-id>/plan.md` | `squad-plan` |
| State Ledger | `docs/squad/jobs/<job-id>/ledger.json` (+ `artifacts/`) | `squad-state` (merges gated by `squad-verify`) |
| Dispatch record | `docs/squad/dispatches/<date>-<slug>.md` | `squad-dispatch` |
| Verification report | inside the dispatch record | `squad-verify` |
| Cost ledger | `docs/squad/ledger.md` | `squad-dispatch` + `squad-verify` |
| Playbook (reusable plans) | `docs/squad/playbook/<shape>.md` | `squad-plan` (Phase 5 distillation) |

Layer-owned files (under `squad/`) are portable across projects; run
artifacts (under `docs/squad/`) belong to the project that spent the
money.
