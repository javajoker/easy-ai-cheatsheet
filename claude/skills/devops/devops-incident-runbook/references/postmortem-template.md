# Postmortem — <incident name>

**Incident ID:** <id>
**Date:** YYYY-MM-DD
**Severity:** SEV1 | SEV2 | SEV3
**Duration:** <detection> → <resolved> (<total minutes>)
**Author:** <name>
**Status:** draft | reviewed | actioned

> **Blameless.** This document uses "the service did X" and "the
> alert routed to Y", not "Alice did X". The goal is to learn,
> not to assign fault. If you find a clause that names a
> human as the cause, rephrase it as a process / system issue.

---

## Summary

<2–3 sentences. What happened in plain language; what the impact
was; how it was resolved. This is what someone catching up on
the postmortem reads first.>

---

## Impact

- **Users affected:** <count / percentage / segment>
- **Geographies affected:** <list>
- **Features affected:** <list>
- **External communication issued:** <yes/no; URLs if yes>
- **Revenue / contractual impact:** <if applicable>

---

## Timeline

(Local timezone: <TZ>)

| Time | Event |
|---|---|
| HH:MM | Issue began (per metric / log evidence) |
| HH:MM | Alert fired → on-call paged |
| HH:MM | On-call acknowledged |
| HH:MM | Cause hypothesised |
| HH:MM | Mitigation applied |
| HH:MM | Service recovered |
| HH:MM | Internal channel updated |
| HH:MM | External comms sent (if applicable) |
| HH:MM | Postmortem started |

---

## Root cause

<One paragraph. What actually caused the incident, system-level.
Not "Alice deployed bad code" → "deploy pipeline allowed a config
mismatch between staging and prod, surfaced by the auth flow on
prod load".>

### Contributing factors

- <factor>
- <factor>

---

## What went well

- <something the team did or systems supported that helped>
- <…>

(This section is non-optional. Postmortems that only catalogue
failures train the team to fear incidents.)

---

## What went poorly

- <delay or process gap>
- <missing tooling>
- <gaps in runbook / alert / dashboard>

---

## What we got lucky with

- <thing that could have been worse>
- <…>

(Identifies fragile dependencies for the action items.)

---

## Action items

| # | Action | Owner | Priority | Due |
|---|---|---|---|---|
| 1 | <specific action> | <name> | high | YYYY-MM-DD |
| 2 | <…> | <…> | … | … |

Action items are tracked in <tracker>; this postmortem links
to each.

---

## Lessons learned

<One paragraph. What did this incident teach the team that
should change how we operate going forward — beyond the
specific action items.>

---

## Runbook updates

- <update applied to runbook X>
- <new runbook needed for class Y>

---

## Reviewed in

- Team retro on YYYY-MM-DD.
- Engineering all-hands on YYYY-MM-DD (if SEV1).
- Customer-facing comms team on YYYY-MM-DD (if external impact).
