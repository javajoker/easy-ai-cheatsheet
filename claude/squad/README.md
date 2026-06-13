# Squad Engineering — evaluate, organize, and execute across LLM products

The **squad layer** treats external LLM products — OpenAI Codex CLI, Gemini
CLI, local models via Ollama, and whatever ships next — as a managed
**squad of engineers**. Each member is evaluated before it is trusted,
organized into a roster with measured ratings per task class, and dispatched
under explicit control: budget caps, timeouts, sandboxing, and a
verification gate that no output crosses silently.

**The motivation is token cost.** Premium Claude tokens should go to the
work only Claude can do — routing decisions, verification, high-stakes
reasoning — while bulk transforms, translations, summaries, and boilerplate
go to the cheapest member that *measurably* clears the quality bar.
"Measurably" is the whole framework: a member earns work through
evaluation, never through vendor benchmarks.

Two mechanisms make the evaluation precise and the execution efficient:
**kits** package a framework skill's discipline into a member-portable
brief with a JSON wire contract — so the unit of evaluation and routing
is *member × special task* ("can this product execute our skill, our
way?"), not member × vibe — and the **State Ledger** gives multi-member
jobs a shared status/memory across models and modalities without
conversational history, so tokens don't compound as work passes between
members. Design sources for both are attached under
[`references/`](references/README.md).

This folder is **self-contained**: `README.md` (this file, the overview),
`HOWTO.md` (everyday mechanics), `WORKFLOW.md` (the end-to-end pipeline
with gates), `SCENARIOS.md` (playbooks V–Z), `EXAMPLES.md` (worked
examples), and `ROSTER.md` (the member × task-class rating matrix)
together cover everything you need. The top-level docs keep short pointers
back here.

## Why this is a top-level layer

`INSTRUCTIONS/`, `agents/`, and `skills/` are the framework's *content*:
what you use to do project work. `maintenance/` is the *version axis*: what
you use to keep that content current as the model and harness move.
`squad/` is the **executor axis**: *who actually runs a given piece of
work*. The three axes are orthogonal — a task is shaped by skills, kept
current by maintenance, and (when it doesn't need Claude) executed by a
squad member.

This is **not** the same as Claude Code subagents (the Agent tool), which
delegate to the *same* product. Squad members are *other* products with
their own CLIs, costs, context limits, and failure modes. That is exactly
why the control half of this layer exists.

## Layout

```
squad/
├── README.md                  # this file — overview + rationale
├── HOWTO.md                   # everyday mechanics
├── WORKFLOW.md                # end-to-end pipeline: evaluate → organize → execute, with gates
├── SCENARIOS.md               # playbooks V–Z (continue the top-level letter sequence)
├── EXAMPLES.md                # worked examples (eval cycle, routed execution, escalation, DAG job)
├── ROSTER.md                  # member × task-class + member × kit ratings + status vocabulary
├── squad-lead/                # the conductor agent (AGENT.md)
├── member-onboard/            # skill — qualify + scaffold + register a new member
├── member-retune/             # skill — re-evaluate a member when its product/model version changes
├── kit-build/                 # skill — package a framework skill into a member-portable kit
├── eval-design/               # skill — golden tasks + rubric for a task class / kit
├── eval-run/                  # skill — run an eval against members; score; update sheets + roster
├── squad-plan/                # skill — decompose a job into a DAG of nodes (kit × tier × gate)
├── squad-route/               # skill — pick the member for a task/node (rating × cost × risk)
├── squad-dispatch/            # skill — controlled invocation (budget, timeout, sandbox, transcript)
├── squad-verify/              # skill — gate ladder: schema → deterministic oracle → cross-validate → in-house judgment
├── squad-state/               # skill — the State Ledger: shared status/memory across members & modalities
├── kits/                      # packaged skills (KIT.md per kit) — the unit of fine-grained evaluation
│   └── README.md              # the KIT.md contract + template
├── references/                # attached design docs + concept → implementation map
└── members/                   # per-product member sheets (provenance-tagged workers)
    ├── README.md              # the MEMBER.md contract + template
    ├── claude-code/           # the home product — baseline member + conductor host
    ├── codex-cli/             # OpenAI Codex CLI
    ├── gemini-cli/            # Google Gemini CLI
    └── ollama-local/          # local models via Ollama (free band)
```

Run artifacts live in the **project**, not in this layer:
`docs/squad/evals/` (eval reports), `docs/squad/jobs/` (job plans +
State Ledgers), `docs/squad/dispatches/` (dispatch records),
`docs/squad/playbook/` (reusable job plans), and `docs/squad/ledger.md`
(the cost ledger) — the same convention as `docs/skill-evolution/` for
proposals.

## The shape of the family

Three pillars, shared member sheets and kits as workers:

| Pillar | Skill | Job |
|---|---|---|
| **Evaluate** | `kit-build` | Package a framework skill/agent into a member-portable kit (wire contract + criteria, calibrated in-house). |
| | `eval-design` | Golden task set + scoring rubric for one task class — the kit's criteria, when a kit exists. |
| | `eval-run` | Run the eval against named members; score PASS/PARTIAL/FAIL; update sheets + roster (class and kit ratings). |
| **Organize** | `member-onboard` | Qualify a product against the membership bar; scaffold MEMBER.md; register in ROSTER.md. |
| | `member-retune` | When a member's product/model version changes, re-walk its ratings; idempotent via `evaluated:` stamps. |
| **Execute** | `squad-plan` | Decompose a multi-stage job into a DAG of nodes (kit × cost tier × gate); budget + 80% circuit breaker; late member binding. |
| | `squad-route` | Pick the cheapest member that clears the bar for this task/node (kit rating first; cost × risk × data sensitivity). |
| | `squad-dispatch` | Invoke the member through its invocation contract, under budget cap + timeout + sandbox; hydrated payloads; capture the transcript. |
| | `squad-verify` | The gate ladder (schema → deterministic oracle → cross-validate → in-house judgment) before integration; drives the escalation ladder; feeds ratings back. |
| | `squad-state` | The State Ledger — shared status/memory across members, models, and modalities; hydration + verified-delta merges. |

All ten skills read the same sheets under [`members/`](members/), the
same kits under [`kits/`](kits/), and the same matrix in
[`ROSTER.md`](ROSTER.md). The [`squad-lead`](squad-lead/AGENT.md) agent
conducts the execute pillar end-to-end and triggers the other two when
it hits an unrated pair.

## Transferred from the maintenance layer

This layer deliberately reuses the `maintenance/` machinery rather than
inventing new discipline:

| Squad asset | Transferred from | What carried over |
|---|---|---|
| `members/<name>/MEMBER.md` | `maintenance/versions/tune-for-*` | One provenance-tagged capability sheet per target; the dispatchers load the right one. |
| `(measured)` / `(claimed)` tags | `(confirmed)` / `(inferred)` | Honesty about evidence. `(claimed)` = vendor docs; `(measured)` = an eval you ran. |
| `member-onboard` | `maintenance/agent-create` | Qualify against a bar → scaffold from a template → register, with a human checkpoint. |
| `member-retune` | `skill-version-tune` family | Version-change-driven re-walk; never retune toward a version you can't run. |
| `evaluated:` stamp | `tuned-for:` field | Additive idempotency metadata — re-runs only propose deltas. |
| Sheet + roster updates | `skill-evolution` + `skill-merge` loop | Diff preview, human approval, no silent rewrites. |
| `squad-verify` format | `skills/share/requirement-audit` | PASS/PARTIAL/FAIL rows with evidence per row. |

## Seven disciplines the layer enforces

1. **Evidence before trust.** A member×task pair with no `(measured)`
   evidence is rated **U** (unrated) and cannot take work that matters.
   Vendor benchmarks are `(claimed)` and never upgrade a rating.
2. **Evaluate the task, not the product.** The unit of evidence is
   member × kit (a packaged skill with a wire contract) wherever a kit
   exists — eval criteria and production acceptance criteria are the
   same rows, so eval results predict dispatch results.
3. **Cheapest member that clears the bar.** Routing optimizes cost
   *subject to* the quality bar — never quality-blind cost-chasing, never
   cost-blind "use the best." Try-cheap-first: draft low, escalate only
   what fails its gate.
4. **No silent integration; assurance is bounded by the verifier.**
   Every external output passes `squad-verify` before it touches the repo
   or merges into the State Ledger, and the report names its evidence.
   The gate ladder spends the cheapest sufficient check first — schema,
   then a deterministic **results oracle** (compiler/tests/diff), then
   **cross-validate** (cross-vendor, signal-only), then **in-house
   judgment**. Consensus is a filter, never a certificate; no member ever
   self-certifies into the repo. The verifier's *required* power is set
   by the task class, not chosen — see the configurations below.
   **A member's self-reported confidence is a signal, never a certificate
   either:** it can only *raise* scrutiny (low confidence deepens verify
   or pre-empts escalation), never lower a gate. A member confident in
   its own work is still graded by the verifier.
5. **Structured handoffs, not chat.** Members never inherit
   conversational history; they receive hydrated payloads (only the
   ledger keys their node declares) and return schema-checked deltas.
   Cross-modal outputs always carry a text summary so the shared memory
   stays shared.
6. **Data sensitivity gates routing.** A task touching secrets, customer
   data, or unreleased code only routes to members whose sheet has the
   data-handling section cleared by a human. When in doubt, in-house.
7. **The ledger learns, and counts the tax.** Every dispatch records
   estimated vs. actual cost and the verify outcome; jobs run under a
   budget with an 80% circuit breaker. The cost it records is **all-in**:
   the member spend *plus the orchestration tax* — the lead's own
   classify/route/verify tokens — and beside it a **`baseline`** figure
   (what in-house would have cost). The layer only earns its place when
   all-in < baseline, so that comparison is a column, not an article of
   faith — and `squad-plan` declines a job whose all-in can't beat
   baseline. Ratings move on evidence — two verified failures demote;
   sustained passes promote — always through a diff-previewed roster
   edit; successful job plans distill into a reusable playbook.

## Two governance tiers, and the role/permission model

Governance in this layer is a **stack of two tiers**, and the upper one
gates the lower:

- **Strategic tier — the outsourcing policy.** *Whether* a piece of work
  may leave in-house at all. It is set by a human, at onboarding (the
  data-handling clearance — what data classes a vendor may ever see) and
  at classify time (stakes, value/safety constraints, vendor trust). A
  task the strategic tier forbids never reaches routing, however cheap a
  member looks.
- **Tactical tier — the wire contract.** *How* permitted work crosses
  members without losing control: the kit's JSON input/output contract,
  the State Ledger schema, and the five gates. This is the factory floor;
  the strategic tier is the licence to operate it.

This is the concrete form of the **"structured professional roles +
permission boundaries"** model: a member's **per-task-class rating** is
its professional role (what it is *qualified* to do, by `(measured)`
evidence — A clears `ship`, C clears `throwaway`), and its
**data-handling clearance** is its permission boundary (what it may ever
*touch*). Routing is exactly role-based access control: qualified **and**
cleared **and** active, then cheapest. Neither axis substitutes for the
other — a brilliant member with no clearance for the data stays
in-house, and a cleared member with a U rating takes nothing that
matters.

## The `gate` flag — auto or human approval

The five gates pause for a human by default. The **`gate` flag** lets the
caller run them unattended — but only along the line the governance tiers
already draw: **`auto` automates the *tactical* tier; the *strategic*
tier always pauses, regardless of the flag.**

```
gate = human   # DEFAULT — every gate pauses for approval as documented
gate = auto    # tactical gates auto-proceed (recorded, not silent); strategic floors still pause
```

Set it like `lead` — a flag (`gate=auto`) or plain language ("run it
unattended", "auto-approve the gates"). `squad-lead` resolves it, records
it (`gate-mode:` in the routing decision / plan header — named to avoid
colliding with a node's `gate` *rung*), and each gate honors it. **Unset
means `human`** — the safe default; the lead never goes unattended on its
own.

What `auto` may decide on its own (tactical): the eval spec (Gate 1), a
sub-`ship` route under the budget cap (Gate 2), a PASS integration
(Gate 3, as today), and a roster **demotion** (Gate 4 — removing trust is
conservative). What **always** pauses even under `auto` (the strategic
floor):

- **Gate 0** — clearing or widening a member's data-handling clearance.
  *What data may leave in-house is never an auto decision.*
- **Gate 2** — `sensitive` data, `ship` stakes, or any estimate **over
  the budget cap**.
- **Gate 3** — integrating **PARTIAL/FAIL** output at `ship` stakes.
- **Gate 4** — a **promotion to A** (granting `ship`-clearing trust).

So `gate=auto` buys unattended bulk throughput without ever letting the
machine self-grant trust, spend past its cap, or send data a human hasn't
cleared. Everything `auto` decides is still written to the same records —
auto is *unattended*, never *unlogged*.

## The `check` flag — the default verifier or a plugged-in one

The verifier is the in-house gate ladder by default. The **`check` flag**
lets the caller substitute or augment it with a registered third-party
check — your own oracle, an open-source checker, a different vendor's
review agent — without weakening the bright line.

```
check = default        # DEFAULT — the in-house gate ladder (schema → oracle → cross-validate → in-house)
check = <name>         # a registered check (skill or agent) slotted into the ladder at its earned rung
```

A plugged-in check is **a member in the verifier role**: it registers and
rates like any member (its trust is `(measured)`, never `(claimed)`), it
runs through `squad-dispatch` (sandbox, caps, transcript — an external
check is still an external call), and four constraints keep it honest:

1. **Independence.** A check must be a *different vendor/instance* than
   the generator. A check sharing the generator's model is self-grading
   wearing a plugin's costume — `squad-route` refuses it.
2. **The verifier-power table still governs.** A check certifies only
   what its rung earns: a **deterministic** check (runs code/tests —
   objective) can certify verifiable output (assurance bounded by the
   check, like any oracle); a **judgment** check is a `cross-validate`
   signal at sub-`ship` and **escalates** at `ship`. A custom check does
   not raise a generator's ceiling — it fills a rung.
3. **In-house is the backstop.** A check that errors, times out, or is
   unrated falls back to the in-house ladder. A `ship`-stakes judgment
   call still ends at a powerful judge; a plugged-in checker can stand in
   only if it is itself trusted at that power and independent.
4. **It never self-certifies into the repo.** Same Gate 3 as everything
   else — a check's verdict is a signal feeding the gate, not a merge.

So "bring your own checker" is fully supported, and it is governed by the
exact rule that governs everything else: **assurance is bounded by the
verifier's power and independence — whoever the verifier is.**

## Squad inside a Loop

Squad is the level-5 paradigm that extends **Loop Engineering** (level 4
— recursive self-correction within one model); the references trace the
lineage. Operationally the relationship is direct: the **execution loop**
(route → dispatch → verify → escalate, bounded by the 80% breaker) *is* a
controlled Loop, and Squad is its per-step **execution engine** — each
iteration runs a sub-task on the cheapest cleared member instead of on
the one flagship. The escalation ladder and the budget breaker are the
loop's termination conditions; the State Ledger is its memory. A
framework Loop drives the squad; the squad does not replace it. The two
compose.

## Lead–member power configurations

Who is the smart node — the lead or the members? The layer supports both
arrangements, with different guardrails. The invariant underneath both:
**assurance is bounded by the verifier, not the generator** (discipline
4), so the question is always *what is verifying the output*.

**The caller chooses with the `lead` flag.** It is a manual switch, and
**unset means Situation 1** (the safe default — the lead never drops to
`common` on its own):

```
lead = powerful   # Situation 1 — powerful in-house verifier  (DEFAULT)
lead = common     # Situation 2 — cheap conductor; oracles / cross-validate carry verification
alias:  situation = 1 | 2
```

Set it as a skill/agent argument (`lead=common`) or in plain language
("use a common lead", "Situation 2 mode"). `squad-lead` resolves it
first, records it as `lead:` in the routing decision (tasks) and the plan
header (jobs), and `squad-plan` / `squad-verify` enforce the matching
guardrails. The flag sets the *default* posture; in `common` mode the
guard may still force a single verify step up to a powerful judge, which
the caller accepts as a cost.

| | **Situation 1 (`lead=powerful`, default)** | **Situation 2 (`lead=common`)** |
|---|---|---|
| Lead / verifier | powerful (in-house premium Claude) | common (a cheaper conductor) |
| Members | modest, **kit-matched to each task** | the most powerful (frontier tier) |
| Verification | in-house judgment, depth scaled to member rating | a **deterministic results oracle**, or a sub-`ship` cross-validate filter |
| Cost shape | premium spent on routing + verify; generation cheap | members are the expensive part; little saved on the lead |
| Sound when | always — it's the core design | a results oracle (or low-stakes cross-vendor filter) carries the decision |
| Unsound when | — | a `ship`-stakes **judgment-output** node has no oracle (consensus hides correlated error) |

**Situation 1** is the framework's happy path: a powerful lead spends its
judgment where it's leveraged (decompose, route, verify) while modest but
*suitable* members — picked by kit rating — do the bulk, re-checked
harder the weaker they are.

**Situation 2** — a common lead commanding powerful members — is legal
because the framework can move verification off the lead and onto
something objective. It is sound exactly when:

- the output is **verifiable** (code/data/runnable) → a generator-
  independent, trap-covered **results oracle** certifies it (blackbox,
  results-oriented — the oracle's power bounds assurance, not the lead's);
  or
- the output is **judgment** but sub-`ship` → a **cross-vendor
  cross-validate** filter passes high agreement and escalates the rest.

It is **unsound** — and blocked at plan time by `squad-plan`'s
Situation-2 guard — when a `ship`-stakes judgment call has no oracle and
leans on a weak verifier or on raw consensus. There the verify step must
escalate to a powerful judge: you can make the *generator* anything, but
the *verifier's required power is fixed by the task class*. The two
enforcement points are `squad-plan` (the guard, at plan time) and
`squad-verify` (the gate ladder + the verifier-power table, at verify
time).

## Pointers

In this folder (canonical):

- **End-to-end pipeline + gates:** [WORKFLOW.md](WORKFLOW.md)
- **Everyday mechanics:** [HOWTO.md](HOWTO.md)
- **Playbooks (Scenarios V–Z):** [SCENARIOS.md](SCENARIOS.md)
- **Worked examples:** [EXAMPLES.md](EXAMPLES.md)
- **Who can do what, today:** [ROSTER.md](ROSTER.md)
- **The kit contract:** [kits/README.md](kits/README.md)
- **Design sources + concept map:** [references/README.md](references/README.md)
- **Review response (challenges + suggestions → where each landed):** [references/04-review-response.md](references/04-review-response.md)

Elsewhere in the framework:

- **Version axis (the sibling meta-layer):** [`../maintenance/README.md`](../maintenance/README.md)
- **Proposal/merge machinery reused here:** [`../skills/share/skill-evolution/`](../skills/share/skill-evolution/) + [`../skills/share/skill-merge/`](../skills/share/skill-merge/)
- **Verification format reused here:** [`../skills/share/requirement-audit/`](../skills/share/requirement-audit/)
- **Where this sits in the whole framework:** [`../README.md`](../README.md)
