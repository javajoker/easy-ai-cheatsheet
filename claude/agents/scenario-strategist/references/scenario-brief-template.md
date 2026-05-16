# Scenario Brief Template (agent-level pointer)

The canonical template lives in `scenario-analysis`:
[`skills/scenario/scenario-analysis/references/scenario-brief-template.md`](../../../skills/scenario/scenario-analysis/references/scenario-brief-template.md).

This file exists so the agent definition can reference the brief
without duplicating the canonical template.

## Brief structure (recap)

A scenario brief covers:

1. **Goal** — one paragraph; the outcome being aimed for.
2. **Scope** — in / out (the *out* list does the harder work).
3. **Constraints** — time / budget / headcount / regulatory /
   technical, each with consequence-if-violated.
4. **Success criteria** — each row testable + pre-agreed.
5. **Risks** — severity × likelihood + mitigation.
6. **Non-negotiables** — positions the team will not move on.

## When the strategist uses this

Phase 1 (Analysis) of [scenario-strategist's AGENT.md](../AGENT.md).
The brief is locked before options analysis begins. Every
downstream phase references the locked brief.

A locked brief is persisted as `type: project` memory
(`scenario_<slug>_brief_v1`).
