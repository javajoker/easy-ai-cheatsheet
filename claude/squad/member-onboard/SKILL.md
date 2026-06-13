---
name: member-onboard
description: Qualify, scaffold, smoke-test, and register a new LLM product as a squad member. The squad sibling of maintenance/agent-create — qualify against a bar, scaffold from a template, register with a human checkpoint. Checks the membership bar (non-interactively invocable from Bash, capturable output, stated cost model), scaffolds members/<name>/MEMBER.md with every capability line tagged (claimed) and the data-handling section BLOCKED, runs one smoke-test prompt through squad-dispatch, and adds a probation/U row to ROSTER.md. Use this skill when the user says "onboard <product> into the squad", "add <CLI/model> as a squad member", "add my local Ollama model to the squad", "can we use <product> for squad work", or names a product squad-route doesn't know. Never grants ratings (that is eval-design + eval-run, Scenario W) and never clears data-handling (human-only). Pairs with squad-dispatch (smoke test), eval-design/eval-run (the trust-building follow-up), member-retune (when the product later moves), and memory-ontology (records the new member).
---

# Member Onboard

Adds a product to the roster **without** adding trust. The output is a
provenance-honest sheet, a working invocation contract, and a U-rated
probation row — the starting state from which only evals (Scenario W)
move anything.

> Transferred from [`maintenance/agent-create`](../../maintenance/agent-create/):
> the same qualify → scaffold → register shape, with the membership bar in
> place of the "job, not a task" bar and MEMBER.md in place of AGENT.md.

## Procedure

### Phase 0 — Qualify against the membership bar

A member must be:

1. **Non-interactively invocable** — a CLI or API Claude can call from
   Bash with no human in the loop mid-call. GUI-only products fail.
2. **Capturable** — output lands on stdout or in files that can be
   diffed.
3. **Cost-stated** — a knowable cost model (metered, subscription, or
   free-local). "We'll see on the bill" fails.

Fails the bar → stop and say so; suggest what would change the answer
(e.g. the vendor ships a CLI). Don't scaffold a sheet for a product that
can't be dispatched to.

Also resolve identity: for local runtimes, the **model tag is part of the
member identity** — `ollama-local` running `qwen3:8b` is a different
member than one running `llama3.3:70b`. One sheet per identity the user
will actually route to.

### Phase 1 — Scaffold the sheet

Create `members/<name>/MEMBER.md` from the template in
[`members/README.md`](../members/README.md):

- Frontmatter: `status: probation`, the best-guess `cost_band`,
  `data_handling: BLOCKED`, `evaluated: []`, and `member_version` from the
  actual installed version (`<cli> --version`) — run it; don't guess.
- Invocation contract: exact command shape, auth **mechanism** (never the
  value), input/output paths, non-interactive flags, timeout default.
- Capability sheet: vendor-doc facts only, each line `(claimed)` with a
  source. Limits and known failure modes are as load-bearing as
  capabilities.

### Phase 2 — Gate 0 (human checkpoint)

Show the user the draft sheet and ask them to confirm the invocation
contract and read the data-handling note. The data-handling section stays
BLOCKED — clearing it is a separate, conscious human act after reading
the vendor's terms; this skill never does it.

### Phase 3 — Smoke test

One trivial prompt through [`squad-dispatch`](../squad-dispatch/)'s real
control path (it may cost a few cents — Gate 0 covered that):

```
<invocation> "Reply with exactly: squad-ok"
```

Proves auth, non-interactive operation, and output capture. Record the
verbatim command + result in the sheet's invocation contract. A failing
smoke test means the contract is wrong — fix it or mark the member
`benched` with the failure noted; never register a contract that hasn't
run.

### Phase 4 — Register

- Add the ROSTER.md row: `probation`, the cost band, **U in every task
  class** — as a diff the user approves.
- Write a `type: project` memory via `memory-ontology` noting the new
  member and the evals that would unlock routing.
- Recommend the first eval: the task class the user most wants to route,
  per Scenario W.

## Anti-patterns

- **Onboarding = endorsing.** The sheet records that the product is
  *reachable*, not that it is *good*. No rating moves here.
- **Copying benchmark tables into the sheet untagged.** Every line is
  `(claimed)` with a source, or it doesn't land.
- **Storing secrets.** Auth lines name the env var or login mechanism.
  Values never appear in the sheet, the transcript, or the smoke test
  command as recorded.
- **Skipping the smoke test.** An unverified invocation contract fails at
  dispatch time, mid-task, which is the expensive place to discover it.

## Companion skills

| When… | Use |
|---|---|
| Running the smoke test | `squad-dispatch` |
| Building trust after onboarding | `eval-design` + `eval-run` (Scenario W) |
| The product's version later moves | `member-retune` |
| Recording the member across sessions | `memory-ontology` |
