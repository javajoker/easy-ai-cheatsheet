# Role-to-Agent Map

Current mapping of common role-hints (from
`workflow-design.md` phases) to shipped agents. **Regenerate when
the agent catalogue changes** — read `claude/agents/CHECKLIST.md`
fresh.

## Current shipped agents

| Agent | Focus area | `fires_on` keywords |
|---|---|---|
| `lifecycle-pilot` | Prototype → prod → GTM | "build", "launch", "go-to-market", "ship a product" |
| `architecture-shepherd` | Architecture upgrade | "re-architect", "migrate", "upgrade dep", "deprecate API" |
| `scenario-strategist` | Multi-agent coordination | "complex situation", "design workflow", "form group" |
| `devops-engineer` | Operational layer | "CI/CD", "observability", "runbooks", "secrets" |
| `knowledge-curator` | Enterprise KB | "build KB", "merge KBs", "RAG", "knowledge graph" |

---

## Mapping table — role hints to lead agents

| Role hint in workflow-design phase | Lead agent | Confidence |
|---|---|---|
| "Build the product end-to-end" | `lifecycle-pilot` | strong |
| "Take this idea to launch" | `lifecycle-pilot` | strong |
| "Drive the launch" | `lifecycle-pilot` | strong |
| "Design the GTM plan" | `lifecycle-pilot` | strong |
| "Architectural change" | `architecture-shepherd` | strong |
| "Re-architect" | `architecture-shepherd` | strong |
| "Migration plan" | `architecture-shepherd` | strong |
| "Database major upgrade" | `architecture-shepherd` | strong |
| "Deprecate v1 API" | `architecture-shepherd` | strong |
| "Rollout strategy" | `architecture-shepherd` | strong |
| "Ops/deployment/observability" | `devops-engineer` | strong |
| "Runbook" / "on-call procedures" | `devops-engineer` | strong |
| "CI/CD" | `devops-engineer` | strong |
| "Secrets / vault" | `devops-engineer` | strong |
| "Infrastructure / IaC" | `devops-engineer` | strong |
| "Security hardening" | `devops-engineer` | strong |
| "Release management" | `devops-engineer` | strong |
| "Knowledge base" | `knowledge-curator` | strong |
| "Enterprise docs / KB" | `knowledge-curator` | strong |
| "RAG / retrieval" | `knowledge-curator` | strong |
| "Decide / plan / coordinate" | `scenario-strategist` | strong (when multi-agent) |
| "Form a group / team" | `scenario-strategist` | strong |
| "Multi-agent workflow" | `scenario-strategist` | strong |

---

## Mapping table — common supporting agents

Many phases have **supporting** agents beyond the lead:

| Lead | Common supporters |
|---|---|
| `lifecycle-pilot` | `devops-engineer` (CI/CD, observability, security); `architecture-shepherd` if non-trivial arch decisions surface |
| `architecture-shepherd` | `devops-engineer` (rollout gates, runbooks); `knowledge-curator` if public docs/KB updates |
| `devops-engineer` | None typical; cross-cutting itself |
| `knowledge-curator` | `devops-engineer` (vector DB hosting, audit log infra); `lifecycle-pilot` if AI features consume the KB |
| `scenario-strategist` | All others — strategist forms the group; others execute |

---

## Multi-agent compositions

Common multi-agent scenarios with their groupings:

| Scenario shape | Group |
|---|---|
| "Build + launch a new product" | `lifecycle-pilot` (lead) + `devops-engineer` (supports from Phase 5) |
| "Upgrade architecture during ongoing operations" | `architecture-shepherd` (lead) + `devops-engineer` (supports throughout) |
| "Re-architecture and relaunch" | `scenario-strategist` (conductor); `architecture-shepherd` then `lifecycle-pilot` (sequential leads) |
| "Migrate platform while shipping v2" | `scenario-strategist` (conductor); `lifecycle-pilot` + `devops-engineer` + `architecture-shepherd` |
| "Enterprise KB + AI feature launch" | `scenario-strategist` (conductor); `knowledge-curator` + `lifecycle-pilot` |
| "Compliance certification" | `scenario-strategist` (conductor); `devops-engineer` + named legal/compliance roles |

---

## Missing roles (no agent currently shipped)

When the workflow needs a role no agent owns:

| Role gap | Closest shipped agent + documented gap | Suggested new agent name |
|---|---|---|
| Customer success / account management | None | `cs-strategist` (proposed) |
| Sales engineering / pre-sales | None | `pre-sales-architect` (proposed) |
| Marketing campaign execution | `lifecycle-pilot` (GTM kit) but only for launches | `marketing-engineer` (proposed) |
| Finance / unit economics | `lifecycle-pilot`'s `gtm-pricing-model` skill helps | None — finance is typically human-led |
| Legal review | None — human role | None |
| Compliance attestation | None — human + auditor role | None |
| Data engineering / pipeline | `devops-engineer` partial overlap | `data-engineer` (proposed) |
| ML / AI feature engineering | `lifecycle-pilot` for launches; `knowledge-curator` for RAG | `ai-engineer` (proposed) |

For each gap row in `agent-group.md`, link to the closest agent
+ document the manual fallback.

---

## Catalogue freshness

This map ages whenever:

- A new agent is shipped.
- An existing agent's `fires_on` triggers expand or narrow.
- A common multi-agent pattern is identified and promoted.

Regenerate by reading `claude/agents/CHECKLIST.md` + each
agent's `AGENT.md` `fires_on` field.

---

## Anti-patterns

- **Hardcoding agent names in this file.** This map is a
  snapshot; check catalogue at runtime.
- **Forcing a phase into an ill-fitting agent.** When no agent
  fits, surface the gap; don't silently route.
- **Two leads per phase.** Each phase has exactly one lead.
  Supporters support; lead owns.
- **Stale map.** When the catalogue changes, this map needs
  refresh. Otherwise group formation routes to wrong agents.
