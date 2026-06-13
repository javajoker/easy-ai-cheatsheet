# references — the Squad Engineering design sources

Three design documents the squad layer's v2 mechanics derive from,
attached verbatim (user-provided, 2026-06):

- [`01-squad-engineering-blueprint.md`](01-squad-engineering-blueprint.md)
  — the concept: multi-model arbitrage, the Scout/Captain/Whitebox
  three-layer split, contract-based communication.
- [`02-structural-framework.md`](02-structural-framework.md) — the
  structural design: dynamic capability matrix, squad formations, tiered
  escalation, deterministic gates, token budgeting, semantic caching.
- [`03-technical-architecture.md`](03-technical-architecture.md) — the
  technical spec: wire protocol + State Ledger, state hydration and
  deltas, DAG configuration contract, Glass Box interception, the
  Auditor circuit breaker, the AEI routing index.

## Concept → implementation map

How each reference concept landed in this layer — adopted, adapted, or
deliberately not taken. The references describe a runtime *product*;
this layer implements the same discipline as a *markdown-driven process*
conducted by Claude Code, so several always-on services become
on-demand, human-gated skills.

| Reference concept | Source | Landed as | Decision |
|---|---|---|---|
| Capability Matrix / live registry | 01 §1, 02 §1, 03 §2 | [`../ROSTER.md`](../ROSTER.md) + member sheets | **Adapted** — ratings move only via evals + Gate 4 diffs, not automatic writes. |
| Micro-skill grading ("who is good at *what*") | 01 §1, 02 §1 | **Kits** ([`../kits/README.md`](../kits/README.md)) + kit-level ratings in ROSTER | **Adopted** — the eval unit is member × *packaged skill*, not member × vibe. |
| Evaluator Agent / Scout canaries | 01 §1, 02 §1, 03 §2 | `eval-run` golden tasks + `member-retune` canary re-runs | **Adapted** — on-demand and routing-pressure-ordered, not an hourly cron; eval spend is gated (Gate 1). |
| AEI (capability ÷ cost × latency) routing index | 03 §2 | Ledger-derived *cost per accepted task* + measured latency in scorecards | **Adapted** — same inputs, but kept as inspectable ledger columns instead of a single opaque index. |
| Captain / Task Decomposer → DAG | 01 §2, 02 §2, 03 §3 | [`../squad-plan/`](../squad-plan/) — plan-not-execute, nodes bind *tiers*, members resolve at dispatch time | **Adopted** — including late binding for swapability. |
| Squad formations (Elite/Swarm/Critic) | 02 §2 | Routing patterns in `squad-plan` (draft-cheap-fix-expensive; generator+verifier pairs; cross-vendor critic = the `cross-validate` rung) | **Adapted** — patterns, not preset rosters; the Critic formation is signal-only (escalates, never certifies). |
| Wire protocol / State Ledger / pure-function agents | 03 §1, 01 §3 | [`../squad-state/`](../squad-state/) — `docs/squad/jobs/<job-id>/ledger.json`, hydration, deltas | **Adopted** — plus a modality rule (artifact + text summary) the references don't cover. |
| Context isolation / state hydration / delta updates | 02 §2–3, 03 §1 | `squad-dispatch` payloads carry only declared `required_inputs` keys; returns are deltas | **Adopted**. |
| Deterministic evaluation gates (compiler-as-gate) | 02 §3, 03 §4 | `squad-verify` **gate ladder**: schema → deterministic results oracle → cross-validate → in-house judgment | **Adopted** — free gates run first; the oracle is what lets a *common* lead certify a *powerful* member's output (Situation 2); premium judgment only when no cheaper rung can decide. |
| Glass Box checkpoints / pause-and-edit state | 01 §3, 03 §4 | The five human gates (WORKFLOW.md) + quarantined deltas readable/editable before merge | **Adopted**. |
| Auditor Agent (cheap LLM watching handoffs) | 01 §3, 03 §4 | Schema validation is deterministic (free, in `squad-dispatch`); cross-vendor agreement is a **signal-only** `cross-validate` rung; the integration *decision* stays on an oracle or in-house | **Adapted** — a member's verdict can filter low stakes or escalate the hard case, but never self-certifies into the repo (the bright line the self-grading rule draws). |
| Token budgeting + circuit breakers (80%) | 02 §3, 03 §4 | Per-node caps in `squad-dispatch`; job-level budget + 80% breaker in `squad-plan` | **Adopted**. |
| Quarantine + backtrack to last healthy checkpoint | 03 §4 | Unverified deltas never merge; DAG resumes from the last merged state | **Adopted**. |
| Semantic caching of successful paths | 02 §3 | `docs/squad/playbook/` — approved plan records reused for recurring jobs | **Adapted** — explicit playbook reuse, not embedding-similarity magic. |
| PostgreSQL/Redis ledger backend, async merge service | 03 §1 | Plain JSON files in the project + synchronous merges | **Not taken** — right for a runtime product; wrong for a portable markdown framework. Revisit if a real runtime is built. |
| Hourly cron Scout service | 03 §2 | — | **Not taken** — unattended recurring spend conflicts with the gate discipline; `member-retune` covers drift on demand. |
| Naming (Scout/Captain/Commander) | all | Evaluate pillar / `squad-plan` / `squad-lead` | Kept the layer's own names; this table is the translation. |

## Reading order

New to the layer: read [`../README.md`](../README.md) first, then 01 for
the concept, 03 for the mechanics, and this table to see where each idea
lives. The references are inputs, not specs — where they disagree with
the layer's seven disciplines (e.g. unattended spend, member-graded
audits), the disciplines win.
