# Runbook Template (agent-level pointer)

The canonical runbook template lives in `devops-incident-runbook`:
[`skills/devops/devops-incident-runbook/references/runbook-template.md`](../../../skills/devops/devops-incident-runbook/references/runbook-template.md).

The companion postmortem template:
[`skills/devops/devops-incident-runbook/references/postmortem-template.md`](../../../skills/devops/devops-incident-runbook/references/postmortem-template.md).

## Runbook structure recap (the fixed shape)

Every runbook has 5 sections, in this order:

1. **Detect** — alert + dashboard + first three things to look at.
2. **Diagnose** — decision tree (capped at depth 6).
3. **Mitigate** — verbatim commands; named approver; expected duration.
4. **Recover** — verify steady state; unwind temporary mitigations; communicate.
5. **Postmortem** — when required; template pointer; review cadence.

Plus a **game-day plan** with quarterly rehearsal cadence — untested
runbooks don't count.

## What the agent guarantees

When `devops-engineer` declares the runbooks workstream done:

- One runbook per recognised incident class.
- Each runbook game-day-rehearsed at least once.
- Postmortem template + filing location documented.
- Runbook URLs cross-linked from the corresponding alerts in
  `devops-observability`.
