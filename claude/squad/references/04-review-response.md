# review response — challenges and suggestions, and where they landed

A 2026-06 external review raised five **challenges** and five
**suggestions** for the squad layer. This file records, item by item,
whether the layer already overcame it, and — where it didn't — exactly
what changed in response. It is the companion to the
[concept → implementation map](README.md): that table tracks the design
*sources*; this one tracks the design *critique*.

The layer's bias throughout: a critique is answered by a **discipline or
a contract change**, not by a new always-on service. Several suggestions
describe runtime machinery (a confidence controller, a semantic cache, a
benchmark harness); each landed as the smallest markdown-driven,
human-gated mechanism that captures the same value without violating the
seven disciplines.

## Challenges

| # | Challenge | Verdict | Where it lives now |
|---|---|---|---|
| C1 | **Orchestration tax** — the router/lead itself burns tokens + latency; multi-step calls cascade errors. | **Was partial → strengthened.** Cascade was already contained (quarantine + backtrack + bounded escalation ladder). The *tax* was only a qualitative "don't route if overhead exceeds the work." | Now an explicit cost dimension: the ledger's **all-in cost** counts the lead's own classify/route/verify tokens, and every entry carries a **`baseline`** column (what in-house would have cost) so net savings is computable, not assumed. `squad-plan` budgets the tax in and **declines** a job whose all-in can't beat baseline. See README discipline 7; [`../squad-plan`](../squad-plan/SKILL.md) Phase 3; [`../squad-dispatch`](../squad-dispatch/SKILL.md) ledger line. |
| C2 | **Consistency** — heterogeneous members vary wildly in output style; needs standardization or a post-processing layer. | **Was partial → strengthened.** Kits already enforced a *structural* contract (JSON wire schema) and inlined the glossary. They did not constrain *voice/format*. | The kit's role/objective + acceptance criteria now carry an explicit **style/normalization** clause (the surviving discipline includes house voice, heading shape, terminology), and `squad-verify` checks style as a first-class criterion — the kit *is* the normalization layer, applied at author time, not bolted on after. See [`../kits/README.md`](../kits/README.md); [`../squad-verify`](../squad-verify/SKILL.md). |
| C3 | **Eval cold-start & bias** — new members are hard to bootstrap; creative tasks are hard to score; the scorer has bias. | **Was partial → strengthened.** Cold-start was handled (U → `throwaway` only → evidence). Two gaps remained: golden-output rubrics don't fit open-ended work, and the in-house scorer can favour Claude-shaped output. | `eval-design` gains a **rubric-band mode** for creative/subjective task classes (criteria-referenced bands, not expected-output match) and an **evaluator-bias guard** (blind scoring; a cross-vendor or human spot-check on a sample). Cold-start gets a **shadow-evidence** path: route low-stakes real work to a U member *in parallel with* in-house to accumulate `(measured)` evidence cheaply. See [`../eval-design`](../eval-design/SKILL.md). |
| C4 | **Rising complexity** — contracts, fallbacks, monitoring all cost engineering. | **Already covered — made explicit.** Every scenario ships a **manual fallback**, the pipeline **degrades gracefully to "Claude just does it"** (the pre-squad baseline), and the layer is opt-in per task. | The new **adoption threshold** makes the cost/benefit a decision, not a faith: don't stand up kit + eval machinery for a task class until the ledger (or a calibration run, S5) shows the all-in beats baseline at your volume. README discipline 7 + the `squad-lead` "do not fire when" list already encode this; the threshold names it. |
| C5 | **"Legal professionals" metaphor** — make it concrete as *structured professional roles + permission boundaries* for role-based routing and governance. | **Already covered in substance — now named.** Per-task-class **ratings** already *are* the professional roles (who is qualified for what, by measured evidence); the per-member **data-handling clearance** already *is* the permission boundary. | README now states the framing directly and ties it to the two governance tiers (S3). No mechanism change — the metaphor was describing what the roster + sheets already do. |

## Suggestions

| # | Suggestion | Verdict | Where it lives now |
|---|---|---|---|
| S1 | **Confidence-aware routing** — members self-report confidence; the orchestrator dynamically reallocates. | **Adopted, bounded.** New, but constrained by discipline 4: a member's self-report can never *certify* its own work (that's self-grading). | Confidence is an **optional output-delta field** (kit schema) treated exactly like the cross-validate signal: it can only **raise** scrutiny — low self-confidence deepens verify and can pre-empt the escalation ladder — **never lower a gate**. `squad-route` uses it as a tie-break and a pre-route flag; `squad-verify` uses it to modulate depth upward only. See [`../squad-route`](../squad-route/SKILL.md), [`../squad-verify`](../squad-verify/SKILL.md), [`../kits/README.md`](../kits/README.md). |
| S2 | **Caching + semantic dedup** to cut cost further. | **Was partial → extended.** `docs/squad/playbook/` already cached *plan shapes*. Result-level reuse was missing. | `squad-plan` gains **input dedup** (near-identical sub-tasks in a bulk fan-out collapse to one dispatch, result fanned back out) and `squad-state` gains a **verified-result cache** (content-addressed: an identical kit+payload that already PASSed reuses the verified delta). Caveats preserved: only *verified* results cache, and a hit still respects the input's data class. See [`../squad-plan`](../squad-plan/SKILL.md) Phase 2; [`../squad-state`](../squad-state/SKILL.md). |
| S3 | **Layered governance** — tactical layer (JSON contract) + strategic layer (values/ethics rules). | **Made explicit.** Both layers existed but weren't named as a stack. | README now names **two governance tiers**: the **tactical tier** (the kit wire contract + the State Ledger schema + the five gates — *how* work crosses members) and the **strategic tier** (the **outsourcing policy** — *whether* a task may leave in-house at all: data sensitivity, vendor trust, and value/safety constraints, set by a human at onboarding and classify time). The strategic tier governs the tactical one. |
| S4 | **Deep Loop integration** — Squad as the execution engine inside a Loop. | **Positioned.** The relationship was in [`01`](01-squad-engineering-blueprint.md)/[`02`](02-structural-framework.md) (Loop is the level-4 paradigm Squad — level 5 — extends) but wasn't operational. | README now states it plainly: the squad **execution loop** (route → dispatch → verify → escalate, under the budget breaker) *is* a controlled Loop, with Squad as its per-step executor. A framework Loop drives the squad; the escalation ladder and the breaker are the loop's termination conditions. The two compose; they don't compete. |
| S5 | **Quantitative experiments** — benchmark cost/quality/latency/success vs a single-model baseline. | **Adopted, lightweight.** The ledger was observational; there was no designed comparison. | The ledger now carries the **baseline** column (C1), turning every accepted task into a running squad-vs-in-house comparison. For a *deliberate* read, a **calibration run** (documented in Scenario W) dispatches a task-class sample both ways and reports cost/quality/latency/success — the evidence that justifies (or retires) the layer for that class. No separate harness: the eval path already dispatches, scores, and ledgers. |

## The one line that governs all ten

Every change above is a **signal that can only tighten the gate, a
contract the kit already owns, or a number the ledger already could have
carried** — never a new way for a cheap component to certify expensive
work. The review's value was in naming costs the layer was paying
silently (the orchestration tax, the unproven baseline) and capabilities
it was leaving on the table (confidence, result caching, creative evals);
the response keeps the bright line intact: **assurance is bounded by the
verifier, not the generator — and not by the generator's confidence in
itself.**
