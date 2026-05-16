# Launch Report Template

The one-page report the lifecycle-pilot agent writes at Phase 8
(post-launch hand-off). This is the agent's own deliverable —
not a skill output.

---

# Launch Report — <project>

**Launch date:** YYYY-MM-DD
**Launch type:** closed beta | open beta | public launch
**Author:** lifecycle-pilot agent (session `<id>`)
**Status:** shipped

---

## What shipped

<2–3 sentences. The product, the audience, the channels.>

## Headline metrics — day 0 / day 7 / day 30 targets

| Metric | Day 0 target | Day 7 target | Day 30 target | Owner |
|---|---|---|---|---|
| <north-star metric, e.g. signups> | <n> | <n> | <n> | <name> |
| <activation rate> | <%> | <%> | <%> | <name> |
| <retention week-1> | <%> | <%> | <%> | <name> |
| <p95 latency> | <ms> | <ms> | <ms> | <name> |
| <error rate> | <%> | <%> | <%> | <name> |

## Audits passed

- [ ] `gtm-launch-readiness` audit — `<link to audit.md>`
- [ ] `requirement-audit` final pass — `<link>`
- [ ] `devops-security-hardening` security baseline — `<link>`

## Open follow-ups (carried into post-launch)

| # | Item | Owner | Due |
|---|---|---|---|
| 1 | <e.g. close PARTIAL row from launch-readiness audit> | <name> | YYYY-MM-DD |
| 2 | <…> | <…> | <…> |

## Alerts wired

- [ ] North-star metric deviation alert routed to <channel>.
- [ ] Error rate alert (per `devops-observability` SLO) routed to <on-call>.
- [ ] Support volume threshold alert routed to <CS lead>.

## Communications sent

| Audience | Channel | Date | Content |
|---|---|---|---|
| Engineering | `#engineering` Slack | YYYY-MM-DD | launch announcement |
| Customers (impacted) | Email | YYYY-MM-DD | launch + migration guide |
| Public | Changelog + blog | YYYY-MM-DD | feature announcement |
| Status page | `status.<domain>` | YYYY-MM-DD | launch banner |

## Hand-off

- **DevOps ownership:** `devops-engineer` agent — see `release-policy.md`.
- **KB / docs ownership:** `knowledge-curator` agent — see published KB.
- **Next review:** YYYY-MM-DD (post-launch retrospective).

## Memory entries persisted

- `project_<slug>_launch_v1` — launch date, stack, audience.
- `project_<slug>_metrics_v1` — north-star + counter-metrics + targets.
- `project_<slug>_decisions_v1` — pricing model, GTM positioning, ICP.

---

The launch report lives in the project (typically
`docs/launches/YYYY-MM-DD-<slug>.md`) and is referenced from
`INSTRUCTIONS/projects/<slug>/project-context.md`.
