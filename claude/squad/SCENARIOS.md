# SCENARIOS — squad playbooks (V–Z)

Step-by-step playbooks for the squad layer, continuing the top-level
`SCENARIOS.md` letter sequence (A–U live there; U's canonical home is
`../maintenance/SCENARIO-U.md`, and V–Z's canonical home is this file).
Self-contained — for mechanics see [HOWTO.md](HOWTO.md), for the pipeline
and gates see [WORKFLOW.md](WORKFLOW.md), for worked transcripts see
[EXAMPLES.md](EXAMPLES.md).

---

## Scenario V — Onboarding a new LLM product into the squad

**Goal.** Take a product you can invoke (CLI/API) from "I heard it's good"
to a registered squad member with a provenance-tagged sheet, a working
invocation contract, and a `probation`/U roster row — without granting it
any trust it hasn't earned.

### When this fits

- A new product shipped (or you got access) and you want it available for
  routing — eventually.
- You run local models (Ollama, LM Studio) and want the free band on the
  roster for bulk work.
- A teammate swears by a tool and you want it measured instead of argued
  about.

### Procedure

1. Run [`member-onboard`](member-onboard/) with the product name and how
   you reach it.
2. The skill qualifies it against the **membership bar**: non-interactive
   invocation, capturable output, stated cost model. Fails the bar →
   stop; it's not a member (yet).
3. It scaffolds `members/<name>/MEMBER.md` from the template in
   [`members/README.md`](members/README.md). Every capability line starts
   `(claimed)` with a source; the data-handling section starts **BLOCKED**.
4. **Gate 0:** you review the sheet — especially the invocation contract
   and what data classes you're willing to send this vendor.
5. Smoke test: one trivial prompt through the real invocation contract,
   transcript captured. Confirms auth, output capture, and the cost meter.
6. Register: `probation` status, rating **U** in every task class, in
   [`ROSTER.md`](ROSTER.md).

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `member-onboard` | shipped | Qualify, scaffold, smoke-test, register. |
| `squad-dispatch` | shipped | Runs the smoke test through the real control path. |
| `cognitive-alignment` | shipped (share) | Locks contested product terms ("agent mode", "context window") before they land on a sheet. |
| `memory-ontology` | shipped (share) | Records the onboarding so future sessions know the member exists. |

### Manual fallback

Copy the template from `members/README.md`, fill it by hand from vendor
docs (tag everything `(claimed)`), run one CLI call yourself to confirm
the contract, and add the ROSTER.md row. The skill mainly automates the
qualification bar and keeps the provenance discipline.

### What this scenario does NOT cover

- **Granting ratings.** Onboarding never rates. That's Scenario W.
- **GUI-only products.** If Claude can't invoke it from Bash, it can't be
  dispatched to; it's not a member.
- **Clearing data-handling.** Only a human unblocks that section, after
  reading the vendor's actual data-use terms.

---

## Scenario W — Evaluating squad members for a task class or kit

**Goal.** Produce `(measured)` evidence of how named members perform on
one task class — or, sharper, on one **kit** (a framework skill packaged
for external execution) — and move their ROSTER.md ratings accordingly.
The only mechanism by which a member earns real work, and the squad's
answer to *"can product X execute our special task Y, with our
agent/skill discipline?"*

### When this fits

- A member is U in a task class or kit you keep wanting to route.
- You packaged a skill with `kit-build` and want to know who can run it.
- Two members are both plausible and you need the cost/quality ranking.
- `member-retune` flagged ratings `(stale)` after a version change, or
  a kit re-derivation changed its contract.
- You suspect a rating is wrong (the ledger shows verify failures piling
  up).

### Procedure

1. **If a kit should exist, build it first** — run
   [`kit-build`](kit-build/) on the source skill; the kit's acceptance
   criteria become the eval rubric, so eval performance predicts
   production performance. (Skippable for coarse task-class evals.)
2. Run [`eval-design`](eval-design/) for the task class / kit. It drafts
   `docs/squad/evals/<task-class>/eval-spec.md`: 5–10 golden tasks drawn
   from your real work (as kit payloads, when a kit exists), expected
   outputs, a PASS/PARTIAL/FAIL rubric per task, and at least one
   **trap task** that punishes plausible-but-wrong output.
3. **Gate 1:** you approve the spec before anything is spent.
4. Run [`eval-run`](eval-run/) naming the members. Each golden task goes
   through [`squad-dispatch`](squad-dispatch/) — the same sandbox, caps,
   and transcript capture as real work — so the eval also measures
   latency, cost, and invocation reliability.
5. Scoring is in-house against the rubric. Output: one scorecard per
   member under `docs/squad/evals/<task-class>/`.
6. **Gate 4:** the skill proposes sheet + roster updates as a diff —
   `(measured)` lines, rating moves (kit-level rows when a kit was
   used), `evaluated: <class|kit>@<version>` stamps. You approve; it
   lands.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `kit-build` | shipped | Packages the skill under test; its criteria = the rubric. |
| `eval-design` | shipped | Golden tasks + rubric; the trap-task discipline. |
| `eval-run` | shipped | Dispatch, score, scorecards, sheet + roster diffs. |
| `squad-dispatch` | shipped | The controlled invocation path for every golden task. |
| `squad-verify` | shipped | Rubric scoring reuses its PASS/PARTIAL/FAIL format. |
| `requirement-audit` | shipped (share) | The underlying audit row format. |
| `memory-ontology` | shipped (share) | Records a multi-session eval pass so it resumes. |

### The calibration run (squad vs. baseline benchmark)

A rating says a member *can* do the task; it doesn't prove routing it
*pays*. To get that — the quantitative read the layer's whole premise
rests on — run the eval as a **calibration run**: dispatch the golden set
both ways, **to the member(s) and to in-house**, and report the four
numbers per side — **cost, quality (PASS rate), latency, success rate** —
with the member side counting its **all-in** cost (member + orchestration
tax + verify + expected escalation), not just the band. The output is a
small table in the scorecard: *squad all-in vs. in-house baseline* for
this task class at this volume. That table is what justifies (or retires)
the layer for the class — and it reuses the eval path entirely, so it
costs one extra in-house pass, not a separate benchmark harness. Re-run
it when a member version changes (Scenario Y) or the ledger's live
baseline gap drifts from what calibration predicted.

### Manual fallback

Write 5 representative prompts, run them through each member's CLI by
hand, judge the outputs against criteria you wrote *before* looking, and
edit the sheet + roster yourself. The skills mainly enforce the
pre-committed rubric and keep eval cost/latency data flowing into the
same ledger as real work.

### What this scenario does NOT cover

- **Rating from public benchmarks.** Leaderboard numbers are `(claimed)`.
  They pick what to evaluate first; they never move a rating.
- **One-task "evals".** A single anecdote is not evidence; the spec
  minimum is five tasks.
- **Evaluating with sensitive data.** Golden tasks must be `public`-class
  content unless the member's data-handling is already cleared.

---

## Scenario X — Routed execution of a task with control

**Goal.** Execute a concrete task through the cheapest member that clears
the bar, under full control — sandbox, caps, transcript, verification —
so the work integrates only when proven acceptable, and the ledger
records what it really cost.

### When this fits

- Bulk/mechanical work: format conversions, large mechanical refactors,
  fixture generation, translations, summaries, boilerplate.
- Anything where you catch yourself thinking "this doesn't need Claude,
  but it does need doing."
- Deliberately generating evidence: routing throwaway tasks to a
  probation member.

### Procedure

1. Invoke the [`squad-lead`](squad-lead/AGENT.md) agent ("route this
   through the squad"). Three optional flags, each defaulting to the safe
   option when omitted: `lead=common` (Situation 2; default `powerful`),
   `gate=auto` (unattended tactical gates; default `human`), and
   `check=<name>` (a registered third-party verifier; default the
   in-house ladder). It resolves all three, then **classifies**: task
   class, stakes (`throwaway`/`internal`/`ship`), data sensitivity — and
   fixes the acceptance criteria *before* routing. Under `lead=common`
   the single-task Situation-2 guard applies (verifiable → oracle;
   sub-`ship` judgment → cross-validate; `ship` judgment → escalate or
   decline). Under `gate=auto` routine gates proceed unattended but the
   strategic floor (`sensitive` data, `ship` stakes, over-cap) still
   pauses; the explicit-only `gate=auto-unsafe` removes those pauses too
   for a trusted pipeline, keeping the absolute invariants (verify still
   runs, FAIL never integrates, BLOCKED data still blocks, the hard cap
   still stops). A `check=<name>` is validated for independence + verifier
   rating or it falls back to the in-house ladder.
2. [`squad-route`](squad-route/) filters the roster: rating clears the
   stakes bar, data-handling covers the inputs, status allows the work.
   Cheapest eligible band wins. **Gate 2:** the decision (member, why,
   estimated cost, fallback) auto-proceeds below the budget threshold,
   asks above it, always asks for `ship` stakes or sensitive data.
3. [`squad-dispatch`](squad-dispatch/) invokes per the MEMBER.md
   contract: worktree sandbox, input allowlist, cost cap, timeout, full
   transcript to `docs/squad/dispatches/`.
4. [`squad-verify`](squad-verify/) audits the return against the
   pre-fixed criteria. **Gate 3:** PASS integrates; PARTIAL integrates
   only with gaps explicitly accepted; FAIL triggers the **escalation
   ladder** — one retry with named gaps → next-ranked member → in-house.
5. Ledger entry: estimated vs. actual cost, outcome, escalations. If the
   outcome contradicts the roster, a rating-feedback note proposes the
   move (Gate 4).

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `squad-route` | shipped | Eligibility filter + cheapest-clearing-member choice. |
| `squad-dispatch` | shipped | Controlled invocation; transcript + cost capture. |
| `squad-verify` | shipped | Acceptance gate; escalation ladder driver. |
| `squad-lead` (agent) | shipped | Conducts classify → route → dispatch → verify → ledger. |
| `requirement-audit` | shipped (share) | Verification report format. |
| `compact-ritual` | shipped (share) | Long dispatch sessions survive /compact. |

### Manual fallback

Pick the member yourself from ROSTER.md, run its CLI with only the files
the task needs, diff what came back, check it against criteria you wrote
down first, and append a ledger line. The skills mainly enforce the order
of operations (criteria before routing, verify before integrate) that
manual use tends to skip under time pressure.

### What this scenario does NOT cover

- **Routing work that needs this conversation's context.** A task that
  requires the session's accumulated understanding stays in-house; squad
  members start cold.
- **Skipping verify because the member is A-rated.** A-rated means
  verify-light (spot checks), never verify-none.
- **Real-time collaboration.** Dispatch is fire-and-collect; interactive
  pair-programming with another product is out of scope.

---

## Scenario Y — Member version change, re-evaluation, and retirement

**Goal.** Keep the roster honest as the products underneath it move —
re-measure what a version change plausibly affected, and bench or retire
members the ledger no longer justifies.

### When this fits

- A member's underlying model or CLI shipped a new version.
- The ledger shows a member's verify-failure overhead eating its cost
  advantage.
- A vendor changed pricing or data-use terms (re-gate data-handling).
- A member has taken no work in months and the sheet is presumptively
  stale.

### Procedure

1. Run [`member-retune`](member-retune/) naming the member and what
   changed.
2. It reads the member's `evaluated:` stamps and classifies each rating:
   **keep** (version change can't plausibly affect it), **stale**
   (re-measure before trusting), or **re-gate** (terms changed —
   data-handling goes back to BLOCKED pending human review).
3. Stale ratings are marked `(stale)` on the sheet — routing treats stale
   as one rating lower — and targeted Scenario W re-evals are queued for
   the classes that matter to your actual routing.
4. For ledger-driven concerns: the skill summarizes the member's ledger
   record (pass rate, escalation rate, true cost per accepted task) and
   proposes `benched` (kept on the roster, takes no work) or `retired`
   (sheet archived) when the numbers don't justify the seat.
5. **Gate 4:** every sheet/roster change lands as an approved diff.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `member-retune` | shipped | Stamp-driven staleness analysis; bench/retire proposals. |
| `eval-design` / `eval-run` | shipped | The queued re-evals (Scenario W). |
| `memory-ontology` | shipped (share) | Records the retune pass and pending re-evals. |
| `skill-merge` discipline | shipped (share) | The diff-preview apply for sheet + roster. |

### Manual fallback

On a version announcement, mark the member's measured lines `(stale)`
yourself, re-run the evals you care about, and edit the roster. The skill
mainly prevents the two silent failure modes: trusting pre-version
evidence forever, and blanket re-running everything at full eval cost.

### What this scenario does NOT cover

- **Tuning the squad's own skills.** A squad skill that misfires is
  Scenario L (evolution); a new Claude version is Scenario U
  (maintenance). This scenario is about the *members*.
- **Punitive retirement.** One bad dispatch is ledger noise; bench/retire
  proposals cite a record, not an incident.

---

## Scenario Z — Multi-member job with shared state (DAG execution)

**Goal.** Execute a multi-stage job across several members — different
sub-tasks on different products, in parallel where possible — with
status and memory shared through a State Ledger instead of compounding
chat history, deterministic gates between stages, and a job budget with
a circuit breaker. This is where the layer's efficiency-and-effectiveness
target is won or lost.

### When this fits

- The job has ≥2 stages with a data dependency: *"extract the data, then
  generate the script, then validate it."*
- Different stages suit different cost tiers (bulk extraction vs.
  frontier coding).
- Stages are independent enough to parallelize (N files through the same
  kit).
- A recurring job shape exists in `docs/squad/playbook/` and should be
  re-run, not re-planned.

### Procedure

1. Invoke the [`squad-lead`](squad-lead/AGENT.md) agent (optionally with
   `lead=common` / `situation=2`; omit for the `powerful` default). It
   resolves the `lead` mode, then classifies and recognizes a *job*
   (multi-stage), not a task.
2. [`squad-plan`](squad-plan/) checks the playbook for a reusable plan,
   else inherits the **verifier posture** from the caller's `lead` flag
   (`powerful` default, or `common` for a cheap conductor — Situation 2)
   and decomposes the job into a DAG: per node a **kit** (or task class),
   **target cost tier**
   (never a member name — members resolve at dispatch time against the
   live roster), declared **ledger inputs/outputs**, and the **cheapest
   sufficient gate** (schema → deterministic oracle → cross-validate →
   in-house). Under a `common` posture the **Situation-2 guard** fires:
   a frontier-tier node must carry a deterministic oracle (verifiable
   output) or a sub-`ship` cross-vendor cross-validate gate (judgment
   output) — a `ship`-stakes judgment node with neither is a plan error.
   Job budget set; **80% circuit breaker** armed. **Gate 2** covers the
   plan (a guard failure never reaches it).
3. [`squad-state`](squad-state/) opens the ledger
   (`docs/squad/jobs/<job-id>/ledger.json`). All cross-member
   status/memory flows through it: nodes read **hydrated payloads**
   (only their declared keys, verified entries only) and write
   **schema-checked deltas** that stay quarantined until verified.
   Cross-modal outputs enter as artifact + mandatory text summary.
4. The lead walks the DAG: ready nodes route → dispatch → verify →
   merge; independent nodes dispatch in parallel; node failures run the
   standard escalation ladder (one retry → next member → in-house)
   without re-planning the job; the job resumes from the last verified
   state after any interruption.
5. The breaker tripping at 80% pauses execution with a state summary —
   raise, simplify, or finish in-house; a human decision, not a top-up.
6. Close: final verify of the deliverable, job budget reconciled into
   `docs/squad/ledger.md`, durable facts distilled via
   `memory-ontology`, and recurring shapes promoted to
   `docs/squad/playbook/`.

### Skills involved — checklist

| Skill | Status | Role |
|---|---|---|
| `squad-plan` | shipped | DAG decomposition, tiers, gates, budget + breaker, playbook reuse. |
| `squad-state` | shipped | The State Ledger: hydration, verified-delta merges, modality rule. |
| `squad-route` | shipped | Per-node tier → member resolution at dispatch time. |
| `squad-dispatch` | shipped | Per-node controlled invocation with hydrated payloads. |
| `squad-verify` | shipped | Gate ladder per node; merge approval; escalation ladder. |
| `kit-build` | shipped | Nodes want kits; recurring kit-less nodes get one built. |
| `squad-lead` (agent) | shipped | Conducts the DAG walk end to end. |
| `compact-ritual` | shipped (share) | Long jobs survive /compact (the ledger is the checkpoint). |
| `memory-ontology` | shipped (share) | End-of-job distillation. |

### Manual fallback

Write the stage list and per-stage input/output keys by hand, keep a
plain JSON file as the shared state, dispatch each stage yourself
through the members' CLIs with only that stage's keys inlined, run your
compiler/tests as the gate between stages, and stop when you've spent
your mental budget. The skills mainly enforce hydration discipline,
delta quarantine, and the breaker — the three things ad-hoc multi-model
pipelines skip until the bill arrives.

### What this scenario does NOT cover

- **Multi-agent (not multi-member) coordination.** Phases owned by
  different framework *agents* on the home product are
  `workflow-design` + `agent-group-formation` (Scenario N). A workflow
  phase may *contain* a squad job; the two compose, not compete.
- **Conversational member collaboration.** Members never see each
  other's transcripts — by design. If a job seems to need members
  "discussing," it needs a better decomposition.
- **Cyclic flows.** The DAG is acyclic; iteration lives inside a node
  (the retry) or in the escalation ladder, never as a loop between
  nodes.

---

## See also

- [README.md](README.md) — layer overview + the seven disciplines.
- [WORKFLOW.md](WORKFLOW.md) — the pipeline these scenarios walk, with gates.
- [EXAMPLES.md](EXAMPLES.md) — worked transcripts of W, X, and the Z DAG job.
- [kits/README.md](kits/README.md) — the kit contract (Scenario W's unit).
- [references/README.md](references/README.md) — the design sources behind Z.
- [`../SCENARIOS.md`](../SCENARIOS.md) — scenarios A–U (framework-wide).
