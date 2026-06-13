# HOWTO — running the squad

Everyday mechanics for the squad layer. For the layer rationale and the
family map, see [README.md](README.md); for the full pipeline with gates,
see [WORKFLOW.md](WORKFLOW.md); for step-by-step playbooks, see
[SCENARIOS.md](SCENARIOS.md). This file is self-contained — you do not need
to read the top-level `HOWTO.md` to use the layer.

The premise: you pay premium tokens for everything Claude does, including
work a cheaper product could do at acceptable quality. The squad layer
moves that work out — but only after **measuring** the cheaper product on
the exact task class, and only with a **verification gate** between its
output and your repo.

## The shape of the family

| You want to… | Run this skill |
|---|---|
| Add a new LLM product to the squad | `member-onboard` |
| Package a framework skill so members can execute it | `kit-build` |
| Build the test set + rubric for a task class / kit | `eval-design` |
| Measure members against a task class / kit | `eval-run` |
| Break a multi-stage job into a DAG with a budget | `squad-plan` |
| Pick who executes a given task or node | `squad-route` |
| Actually invoke the chosen member, with control | `squad-dispatch` |
| Accept or reject what came back | `squad-verify` |
| Share status/memory between members across a job | `squad-state` |
| A member's product/model version changed | `member-retune` |

The [`squad-lead`](squad-lead/AGENT.md) agent chains
plan → route → dispatch → verify for you and falls back to the evaluate
pillar when it hits an unrated member×task pair.

## Onboarding a member

```
> Onboard the Gemini CLI into the squad.
> Add my local Ollama qwen model as a squad member for bulk work.
```

`member-onboard` will:

1. **Qualify** the product against the membership bar — it must be
   invocable non-interactively (a CLI or API Claude can call from Bash),
   produce capturable output, and have a stated cost model. A product you
   can only drive through a GUI is not a member.
2. **Scaffold** `members/<name>/MEMBER.md` from the template in
   [`members/README.md`](members/README.md) — invocation contract,
   capability sheet (everything starts `(claimed)`), cost band, limits,
   and a **data-handling section that starts BLOCKED** until you clear it.
3. **Smoke-test** the invocation contract with one trivial prompt (your
   approval first — it may cost a few cents).
4. **Register** the member in [`ROSTER.md`](ROSTER.md) with status
   `probation` and rating **U** in every task class.

## Packaging a skill into a kit

```
> Build a kit from our translation discipline so the squad can run it.
> Package the feature-spec skill for external members.
```

`kit-build` extracts the source skill's load-bearing rules (MUST /
MUST NOT — harness assumptions stripped), defines a JSON wire contract
(input payload / output delta) plus acceptance criteria, inlines the
project bindings by value (glossary, conventions — members can't read
your repo), and **calibrates the kit with an in-house cold dry-run**
before it ever rates a member. The kit lands at
`kits/<kit-name>/KIT.md`. This is what makes the evaluation question
precise: not "is this product good?" but "can it execute *this* skill,
our way, to PASS?"

## Evaluating for a task class or kit

```
> Evaluate codex-cli and ollama-local for the translation task class.
> Rate gemini-cli against kit-translation-docs.
> Which squad members can handle test-gen? Run the eval.
```

Two skills, two checkpoints:

1. `eval-design` produces `docs/squad/evals/<task-class>/eval-spec.md` —
   5–10 golden tasks with expected outputs and a PASS/PARTIAL/FAIL rubric
   per task. **When a kit exists, the kit's acceptance criteria ARE the
   rubric rows and golden tasks are kit payloads** — one contract for
   eval and production. **You approve the spec before anything is
   spent** (Gate 1).
2. `eval-run` dispatches the golden tasks to each named member through
   `squad-dispatch` (same control path as real work), scores the returns
   against the rubric, and writes
   `docs/squad/evals/<task-class>/<member>-<date>.md`. It then proposes
   the sheet + roster updates as a **diff you approve** — `(measured)`
   evidence lands on the member sheet, the rating moves in ROSTER.md
   (kit-level rows when a kit was used), and an
   `evaluated: <task-class|kit>@<member-version>` stamp makes the run
   idempotent.

## Choosing the lead mode (the caller's switch)

Before (or while) you hand work to the squad, you can pick which power
configuration runs with the **`lead` flag** — and **if you set nothing,
you get Situation 1** (powerful in-house verifier), the safe default:

```
lead = powerful   # Situation 1 — DEFAULT (omit the flag and you're here)
lead = common     # Situation 2 — cheap conductor; oracles / cross-validate verify
alias:  situation = 1 | 2
```

```
> Squad this: convert these 40 YAML configs to TOML.            (no flag ⇒ powerful)
> Generate the OpenAPI client — lead=common.                    (Situation 2)
> Run this whole job in Situation 2: extract, code, document.   (alias)
```

`lead=common` only routes safely where verification can rest on a
deterministic oracle (verifiable output) or a sub-`ship` cross-vendor
cross-validate filter (judgment output); a `ship`-stakes judgment task
under `common` will be flagged and either escalated to a powerful judge
(you accept the spend) or declined. Unsure which to use? Omit the flag —
`powerful` is always correct, just not always cheapest.

## Executing a task through the squad

```
> Translate docs/manual/ to Traditional Chinese — route it through the squad.
> Have the squad generate table-driven tests for pkg/parser.
> Squad this: convert these 40 YAML configs to TOML.
```

The `squad-lead` agent runs the execute pillar:

1. **Classify** — task class (or kit), stakes, data sensitivity.
   Contested terms go through `cognitive-alignment` first. Acceptance
   criteria fixed now.
2. **Plan — multi-stage jobs only** (`squad-plan`) — the job becomes a
   DAG of nodes (kit × cost tier × gate), with a job budget, an 80%
   circuit breaker, and a State Ledger opened via `squad-state`.
   Single-stage tasks skip this step entirely.
3. **Route** (`squad-route`) — per task or per node: cheapest member
   whose rating (kit rating first) clears the bar for this stakes level
   and whose data-handling clearance covers the inputs. It surfaces the
   decision: *member, why, estimated cost, fallback*. Above your budget
   threshold it asks; below, it proceeds (Gate 2).
4. **Dispatch** (`squad-dispatch`) — invokes the member per its MEMBER.md
   invocation contract, inside a worktree sandbox, with a token/cost cap
   and a timeout; the payload is the kit brief + **hydrated state** (only
   the ledger keys the node declared — never history); captures the full
   transcript to `docs/squad/dispatches/`. Returns are schema-validated
   on arrival and quarantined.
5. **Verify** (`squad-verify`) — the gate ladder against the criteria
   fixed in step 1: deterministic checks first (free), in-house judgment
   only where machines can't decide. Nothing integrates — and no delta
   merges into the State Ledger — without PASS (Gate 3). PARTIAL/FAIL
   drives the escalation ladder: one retry with named gaps →
   next-ranked member → in-house.
6. **Close the loop** — ledger entry (estimated vs. actual cost, verify
   outcome), a rating-feedback note if the outcome contradicts the
   roster, and for recurring job shapes a playbook entry
   (`docs/squad/playbook/`) so the next run skips re-planning.

## Sharing status and memory across members

Members never see each other's transcripts — they share a per-job
**State Ledger** (`docs/squad/jobs/<job-id>/ledger.json`, owned by
`squad-state`): members receive *hydrated payloads* (only the verified
ledger keys their node declares) and return *schema-checked deltas*
that merge only after verification. Cross-modal outputs (images,
binaries) enter as artifact + mandatory text summary, so text-only
members consume the same shared memory as vision-capable ones. At job
end, durable facts distill into `memory-ontology`; the ledger stays as
the audit record. Full rules in [`squad-state/`](squad-state/SKILL.md).

## When the underlying product moves

```
> Gemini CLI just shipped a new model — retune its squad ratings.
```

`member-retune` is the squad sibling of `skill-version-tune`: it reads the
member's `evaluated:` stamps, identifies which ratings are anchored on the
old version, and proposes which evals to re-run (not all — only task
classes where the version plausibly moved the result). Old `(measured)`
evidence is demoted to `(stale)` until re-measured, never silently kept.

## Four disciplines that keep it honest

- **Never route on `(claimed)`.** Vendor benchmarks decide *what to
  evaluate first*, never *who gets work*. Only `(measured)` evidence moves
  a rating above U.
- **Verification is in-house and non-negotiable.** The point of the layer
  is to spend Claude tokens on verification instead of generation. Skipping
  verify to save the verify cost re-imports the risk you delegated away.
- **Free gates before premium judgment.** If a compiler, test suite, or
  schema check can decide a node's output, no LLM is asked. In-house
  judgment is the gate of last resort, not the default.
- **The bar scales with stakes, not with enthusiasm.** A C-rated member can
  take throwaway drafts; shipping code needs A or B plus full verify. A
  task touching sensitive data needs a cleared data-handling section — or
  it stays in-house.

## How this differs from neighbouring machinery

| | Squad layer | Claude subagents (Agent tool) | Maintenance layer |
|---|---|---|---|
| **Delegates to** | Other LLM products | The same product, parallel contexts | Nobody — retunes artifacts |
| **Axis** | Executor (who runs it) | Concurrency (how many at once) | Version (what the runtime can do) |
| **Trust source** | `(measured)` eval evidence | Inherited (same model) | Capability sheets |
| **Cost effect** | Moves spend to cheaper products | Multiplies premium spend | n/a |

Both meta-layers share the same merge discipline: diff preview, human
approval, additive idempotency stamps, no silent rewrites.
