# Handoff Contract Template (agent-level pointer)

The canonical template lives in `agent-handoff-protocol`:
[`skills/scenario/agent-handoff-protocol/references/handoff-protocols-template.md`](../../../skills/scenario/agent-handoff-protocol/references/handoff-protocols-template.md).

## The six fields (recap)

Every handoff between agents in a formed group has all six:

| Field | What it captures |
|---|---|
| Producing agent | Who hands off |
| Receiving agent | Who picks up |
| Artifact | Exact file(s) that pass |
| Acceptance criteria | Testable; pre-agreed; usually 3–6 rows |
| Rejection procedure | Names specific gaps; sets re-acceptance target |
| Escalation | Who decides if producer + receiver disagree |

**A handoff with any field empty will fail.**

## Two-rejection rule

If the same handoff is rejected twice, the workflow has a
structural issue — not a quality issue. Conductor escalates to:

1. Re-audit the producing phase's scope.
2. Re-audit the acceptance criteria — appropriate for the
   receiver's actual need?
3. Re-audit the producing agent's capability fit.

## When the strategist uses this

Phase 4 (Handoff protocols) of [scenario-strategist's AGENT.md](../AGENT.md).
The strategist (as conductor) holds the contracts and enforces
them at every transition.
