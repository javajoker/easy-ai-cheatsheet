# Launch Readiness Checklist (agent-level index)

This file is the **agent's** view of the launch-readiness checklist —
the canonical detail lives in the `gtm-launch-readiness` skill.

For the full audit shape with PASS/PARTIAL/FAIL rows and evidence,
see [`skills/gtm/gtm-launch-readiness/references/launch-checklist.md`](../../../skills/gtm/gtm-launch-readiness/references/launch-checklist.md)
and the skill itself at
[`skills/gtm/gtm-launch-readiness/SKILL.md`](../../../skills/gtm/gtm-launch-readiness/SKILL.md).

## Quick reference — the six categories

| # | Category | Owner skill / agent |
|---|---|---|
| 1 | Security | `gtm-launch-readiness` + `devops-security-hardening` |
| 2 | Performance | `gtm-launch-readiness` + `devops-observability` |
| 3 | Legal | `gtm-launch-readiness` (product / legal liaison) |
| 4 | Operational | `gtm-launch-readiness` + `devops-engineer` |
| 5 | Support | `gtm-launch-readiness` (CS / product) |
| 6 | Compliance | per-project (HIPAA / SOC2 / PCI as applicable) |

Each category produces one or more rows in the final
`launch-readiness-audit.md`. Lifecycle-pilot's Phase 6 will not
declare passed until every row is PASS or PARTIAL-with-mitigation.

## When the agent invokes this

Phase 6 of [lifecycle-pilot's AGENT.md](../AGENT.md). The agent
delegates the actual audit to `gtm-launch-readiness`; this file
exists so the agent has a quick-reference index without loading
the full skill content.
