# EXAMPLES — worked squad runs

Five worked examples showing the artifacts at each step. Names, scores,
and costs below are **illustrative** — your evals produce your numbers.
Example 1 walks Scenario W (evaluation), Example 2 walks Scenario X
(routed execution), Example 3 shows the escalation ladder and rating
feedback doing their jobs, Example 4 walks Scenario Z (a multi-member
DAG job with a shared State Ledger), and Example 5 shows Situation 2 —
a common (cheap) lead safely commanding powerful members via a results
oracle and a cross-validate gate.

---

## Example 1 — Evaluating two members for `translation`

**Setup.** `gemini-cli` and `ollama-local` are onboarded (Scenario V done):
sheets exist, both `probation`/U. The project has recurring
English → Traditional Chinese doc translation work — exactly the kind of
bulk task that shouldn't burn premium tokens.

**Step 1 — `eval-design`.** Prompt:

> Design a translation eval for the squad: English → zh-TW technical docs.

Output `docs/squad/evals/translation/eval-spec.md` (excerpt):

```markdown
# Eval spec — translation (en → zh-TW), technical docs
golden tasks: 6   stakes calibrated to: internal
| # | Task | Trap? | PASS means |
|---|---|---|---|
| 1 | Translate README section (300w), preserve markdown | no | meaning + all formatting intact; glossary terms per projects/<slug>/ |
| 2 | Translate API error strings table | no | placeholders {0} untouched; table structure intact |
| 3 | Translate doc containing code blocks | yes | code blocks byte-identical — translating code = FAIL |
| 4 | Translate UI copy with brand names | yes | brand names + product terms NOT translated |
| 5 | 2,000-word doc (context-length probe) | no | no truncation, no mid-doc style drift |
| 6 | Doc with ambiguous term ("check") | yes | term resolved per glossary, not guessed |
```

**Gate 1:** user approves the spec.

**Step 2 — `eval-run`.** Each task dispatches through `squad-dispatch`
(sandboxed, capped, transcripts kept). Scoring happens in-house against
the rubric. Scorecard `docs/squad/evals/translation/gemini-cli-2026-06-13.md`
(excerpt):

```markdown
| # | Result | Evidence |
|---|---|---|
| 1 | PASS | meaning + markdown intact; glossary respected |
| 3 | PASS | code blocks byte-identical (diff attached) |
| 4 | PARTIAL | one product term translated ("Workbench" → 工作台) |
| 6 | PASS | glossary term used |
Score: 5 PASS / 1 PARTIAL / 0 FAIL · median latency 11s · cost/task ~low band
```

`ollama-local` (a 9B local model): 3 PASS / 1 PARTIAL / 2 FAIL — both
traps failed (translated inside code blocks; guessed the ambiguous term).

**Gate 4 diff (approved):** ROSTER.md `translation` column:
`gemini-cli U → B`, `ollama-local U → C`; member sheets gain `(measured)`
lines + `evaluated: translation@<version>` stamps.

**Outcome.** Translation work can now route: B-rated gemini-cli for
internal docs with full verify; ollama-local only for throwaway drafts.

---

## Example 2 — Routing a bulk translation through the squad

**Task.** "Translate `docs/manual/` (14 files) to zh-TW — route it through
the squad."

**Step 1 — classify (`squad-lead`).** Task class `translation`; stakes
`internal` (docs, not shipped UI); data sensitivity `internal` —
gemini-cli's data-handling section was cleared for `internal` docs at
Gate 0. Acceptance criteria fixed now: glossary compliance, markdown
intact, code blocks byte-identical, no truncation.

**Step 2 — route (`squad-route`).** Decision record:

```markdown
# Routing decision — 2026-06-13-manual-zhtw
eligible: gemini-cli (B, low band, cleared: internal)
excluded: ollama-local (C — stakes bar is B for internal)
chosen:   gemini-cli · estimated cost: low band × 14 files
fallback: in-house (Claude)
→ under budget threshold: auto-proceed (Gate 2)
```

**Step 3 — dispatch (`squad-dispatch`).** Worktree sandbox; input
allowlist = the 14 files + the glossary; per-file invocation with timeout;
transcript to `docs/squad/dispatches/2026-06-13-manual-zhtw.md`.

**Step 4 — verify (`squad-verify`).** In-house audit, sampling tightened
around the known PARTIAL from the eval (brand terms):

```markdown
| Criterion | Result | Evidence |
|---|---|---|
| Code blocks byte-identical (14/14) | PASS | scripted diff, all clean |
| Markdown structure intact | PASS | rendered spot-check 5/14 |
| Glossary compliance | PASS | grep against glossary, 0 violations |
| Brand terms untranslated | PARTIAL | 2 hits in file 9 — fixed in-house (2 lines) |
Verdict: PASS with noted fix · integrate (Gate 3)
```

**Step 5 — ledger.** `docs/squad/ledger.md` gains:

```markdown
| 2026-06-13 | translation | gemini-cli | est: low×14 | actual: low×14 + in-house verify | PASS (1 fix) | escalations: 0 |
```

**Outcome.** Premium tokens were spent on classification, routing, and
verification only; generation ran in the low band. The two-line fix cost
less than re-doing one file in-house.

---

## Example 3 — Escalation ladder + rating feedback

**Task.** "Squad this: generate table-driven tests for `pkg/parser`."
Task class `test-gen`, stakes `ship`. Roster: `codex-cli` A `(measured)`,
`gemini-cli` B.

1. Route picks `codex-cli` (A clears `ship`; cheapest eligible).
2. Verify **FAIL**: 3 of 12 generated cases assert the parser's *current
   buggy* behaviour (the criteria — fixed pre-dispatch — required cases
   derived from the spec in `docs/parser-spec.md`, not from the
   implementation).
3. **Ladder step 1:** one retry to codex-cli with the named gap. Retry
   returns 12/12 spec-derived but misses the two error-path cases the
   criteria listed. **FAIL** — and that's the one allowed retry.
4. **Ladder step 2:** next-ranked member is B-rated gemini-cli — but
   stakes `ship` requires A-or-B *plus* full verify; the lead estimates
   verify-plus-likely-fix at B quality exceeds in-house cost for this
   task size. **Ladder step 3:** in-house. Claude writes the error-path
   cases, reusing the 12 verified-good cases from the retry.
5. Ledger records both dispatches, the escalation, and the true cost.
   Rating feedback note: codex-cli `test-gen` now has 2 verified failures
   at `ship` stakes in the rolling record → proposes A → B demotion
   (Gate 4). User approves; the sheet's `(measured)` line gains the
   failure citation.

**Outcome.** The bad cases never reached the repo (Gate 3 did its job);
the partial work was still salvaged; the roster now reflects reality
instead of the eval from three months ago. Total cost exceeded pure
in-house for *this* task — the ledger records that honestly, which is
what keeps routing thresholds calibrated for the next hundred tasks.

---

## Example 4 — Multi-member DAG job with a shared State Ledger

**Task.** "Analyze the 50-page Q3 financial report and generate a Python
script that graphs its revenue trends." (The reference docs' worked
scenario — see [`references/`](references/README.md).)

**Step 1 — classify + plan (`squad-lead` → `squad-plan`).** This is a
*job*, not a task. No matching playbook, so `squad-plan` decomposes it.
`docs/squad/jobs/2026-06-13-q3-trends/plan.md` (excerpt):

```markdown
# Job plan — 2026-06-13-q3-trends
lead: powerful            # caller set no flag ⇒ Situation 1 default
objective: Extract Q3 revenue metrics from the 50-pg report and graph the trend.
budget: mid band, breaker at 80%

| node | kit | tier | required_inputs | outputs | gate |
|---|---|---|---|---|---|
| n1 | kit-extract-financials | low-volume (long ctx) | global.report_chunks[*] | extracted_metrics | schema |
| n2 | kit-pandas-chart | mid-coding | ledger.extracted_metrics | plot_script | deterministic (run in sandbox) |
| n3 | — (in-house) | in-house | ledger.plot_script, ledger.extracted_metrics | final_chart | in-house judgment |

dependencies: n2←n1, n3←n2     parallelism: n1 fans out over report chunks
```

Note: nodes bind **tiers**, not members — resolved at dispatch. **Gate 2:**
user approves the plan (mid band, sensitive? the report is internal-class
and gemini-cli is cleared for `internal`).

**Step 2 — open the ledger (`squad-state`).** `ledger.json` starts with
the objective and budget; the 50 pages land in `artifacts/` and enter as
chunked entries with summaries — never inlined whole into any prompt.

**Step 3 — n1, fanned out (extraction).** Route resolves `low-volume` →
`gemini-cli` (B on `kit-extract-financials`). Five parallel dispatches,
each hydrated with **one 5-page chunk only** (not the whole report — the
token saving). Returns are schema-checked deltas; on PASS they merge:

```json
"extracted_metrics": {
  "value": { "q1_rev": 45.0, "q2_rev": 47.1, "q3_rev": 46.2, "unit": "M_USD" },
  "producer": "gemini-cli@n1", "status": "verified", "modality": "data"
}
```

**Step 4 — n2 (coding).** Route resolves `mid-coding` → `codex-cli`.
Hydrated payload = `kit-pandas-chart` brief + **only** `extracted_metrics`
(not the report, not n1's transcript). Returns `plot_script` as a
quarantined delta.

**Step 5 — n2's gate (deterministic, free).** `squad-verify` runs the
gate ladder: the script executes in the sandbox. **First run errors**
(missing axis labels required by the kit's criteria). No LLM is asked
"is this right?" — the sandbox decided. FAIL → **one retry** to
codex-cli with *only the error log + the script* (still no 50 pages).
Retry runs clean, produces `trends.png`; delta merges with an
`artifact` + summary entry.

**Step 6 — n3 (in-house judgment).** The one node where a machine can't
decide "does this chart actually tell the revenue story?" — kept
in-house by design (premium tokens spent exactly where they're worth
it). Claude reads `trends.png` + `extracted_metrics`, confirms the Q3
dip is visible and labeled, approves.

**Step 7 — close.** Job ledger reconciled into `docs/squad/ledger.md`:

```markdown
| 2026-06-13 | job:q3-trends | n1 gemini-cli ×5 / n2 codex-cli ×2 | est: mid | actual: low×5 + mid×2 + in-house n3 | PASS | escalations: 1 (n2 gate) |
```

Budget never hit the breaker. The plan shape distills to
`docs/squad/playbook/financial-report-to-chart.md` for next quarter.

**Outcome.** Three cognitive tiers ran each at its right cost; the 50
pages were inlined into exactly *zero* prompts beyond the 5-page chunks
n1 needed; the deterministic gate caught the bug for free; premium
tokens were spent only on routing, the final judgment, and the one fix —
not on generation or on shuttling history between members.

---

## Example 5 — Situation 2: a common lead commanding powerful members

**Setup.** The caller invokes with the switch set —
*"build the API client — `lead=common`"* (equivalently `situation=2`).
Had they omitted the flag, the job would run Situation 1 (`powerful`)
and none of the guard below would apply. The conductor is therefore a
cheap model, and the job routes *frontier* members. The question
Situation 2 forces: with a weak lead, what verifies the powerful
members' output? Two job nodes, two answers.

**Job plan header (`squad-plan`, posture inherited from the flag):**

```markdown
# Job plan — 2026-06-13-api-client
lead: common              # from the caller's flag — the Situation-2 guard is active
budget: mid band, breaker at 80%

| node | kit | tier | output | gate | guard check |
|---|---|---|---|---|---|
| n1 | kit-openapi-client | frontier-reasoning | client_code | deterministic (generated tests + typecheck) | ✅ verifiable output → oracle |
| n2 | kit-api-overview-doc | frontier-reasoning | overview_md | cross-validate (codex-cli ∥ gemini-cli) | ⚠️ judgment, internal stakes → cross-vendor filter |
```

**Guard at plan time.** Both nodes route a frontier tier under a *common*
lead, so `squad-plan`'s Situation-2 guard checks each:

- **n1** produces code — *verifiable*. Its gate is a **deterministic
  results oracle** (the kit ships a generated test suite + `tsc
  --noEmit`). Legal ✅ — assurance is bounded by the oracle, not the weak
  lead. Had n1 carried no oracle, the plan would fail Gate 2.
- **n2** produces a prose API overview — *judgment*, no oracle exists. It
  is `internal` stakes (not `ship`), so a **cross-vendor cross-validate**
  gate is permitted ⚠️. `squad-route` resolves two *different-vendor*
  peers (codex-cli ∥ gemini-cli) — decorrelation is the point.

**n1 verify (oracle, free).** The frontier member writes the client; the
sandbox runs the kit's tests and the type-check. 28/28 pass, types
clean. The common lead doesn't *read* the code — it runs the oracle and
reads the exit code. **PASS**, delta merged. A weak lead just certified a
frontier member's output, soundly, because the oracle did the judging.

**n2 verify (cross-validate, signal-only).** Both peers produce an
overview. The lead diffs them structurally: they agree on every endpoint
and the auth flow, disagree on one rate-limit number (codex says 100/s,
gemini says 60/s). **Agreement is a pass-filter; the disagreement
escalates** — and here's the catch the guard anticipates: at `ship`
stakes this would force an in-house judge, but at `internal` stakes the
lead escalates just the one disputed row to the deterministic source
(greps the rate-limit header in the actual API spec → 60/s, gemini
right). The agreed remainder passes on consensus; the one conflict was
resolved by an oracle, not by the weak lead guessing.

**What if n2 had been `ship` stakes?** The guard would have made
`cross-validate` illegal as the terminal gate — the plan would either
mark n2 `gate: in-house` (accepting premium verify spend on that one
node — the verify step reverts to Situation 1) or not pass Gate 2. The
generator stays frontier; the *verifier* power is dictated by the task,
not the budget.

**Outcome.** A common lead safely commanded frontier members on both
nodes — because neither relied on the lead's judgment: n1's oracle and
n2's cross-vendor filter (with an oracle tie-break) carried the
decisions. The configuration the framework *blocks* — a weak lead
rubber-stamping frontier prose at ship stakes — never got past planning.

---

## See also

- [SCENARIOS.md](SCENARIOS.md) — the playbooks these examples walk.
- [WORKFLOW.md](WORKFLOW.md) — gates and artifact map.
- [ROSTER.md](ROSTER.md) — where the ratings in these examples live.
