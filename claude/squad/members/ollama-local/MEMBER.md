---
name: ollama-local
product: Ollama (local models)
vendor: self-hosted (Ollama runtime; model varies)
interface: cli
status: probation
cost_band: free
data_handling: BLOCKED   # see below — local ≠ automatically cleared; clear it consciously
roles: [generator]       # rate it as a verifier before using it as a check=<name>
evaluated: []
member_version: UNVERIFIED — record `ollama --version` + the exact model tag (e.g. qwen3:8b)
---

# Ollama (local models)

Locally-run open-weight models via the Ollama runtime. The **free band**:
zero marginal dollar cost, no rate limits, no data leaving the machine.
The trade is quality — small local models fail trap tasks far more often
than hosted frontier models (see EXAMPLES.md Example 1), so the expected
home is `throwaway`-stakes bulk work, draft generation, and
evidence-generation for evals. **The model tag is part of the member
identity:** `qwen3:8b` and `llama3.3:70b` are effectively different
members — record which one the evidence is anchored on, or onboard them
as separate members if you use several.

## Invocation contract

- **Command:** `ollama run <model-tag> "<prompt>"`
- **Auth:** none (local daemon must be running: `ollama serve`)
- **Input:** prompt arg or stdin; file content must be inlined into the
  prompt — there is no filesystem access, which is also a sandbox property
- **Output:** stdout
- **Non-interactive flags:** single-prompt `run` is non-interactive
- **Timeout default:** 300s (local inference can be slow on big prompts —
  measure)
- **Smoke test:** `ollama run <model-tag> "Reply with exactly: squad-ok"`

## Capability sheet

| Capability / limit | Tag | Source |
|---|---|---|
| Zero marginal cost, unlimited volume | (claimed) | structural — hardware + electricity are the real cost |
| Nothing leaves the machine | (claimed) | structural — strongest data-handling story on the roster once cleared |
| Quality strongly model- and size-dependent; expect trap-task failures | (claimed) | general open-weights experience — eval the exact tag you run |
| Effective context window often far below hosted models | (claimed) | model card of the chosen tag — verify |
| No tool use / no file access in plain `run` mode | (claimed) | runtime behaviour — confirm at onboarding |

## Cost model

(measured-by-construction) $0 marginal. The ledger's real entries for
this member are latency and the verify/escalation overhead — a free
member that fails verify half the time is not free.

## Data handling

**BLOCKED** by default even though it's local: clearing is a conscious
human act in this framework, and "local" still deserves the question
(shared machine? model telemetry settings?). Typically cleared quickly to
`sensitive` after that check — the strongest clearance on the roster.

## Eval history

| Date | Task class | Scorecard | Outcome |
|---|---|---|---|
