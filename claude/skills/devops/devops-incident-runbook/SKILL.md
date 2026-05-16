---
name: devops-incident-runbook
description: Produces a fixed-shape runbook per incident class (Detect → Diagnose → Mitigate → Recover → Postmortem) with verbatim commands, decision trees, and named first-responders. Generates a quarterly game-day plan so each runbook is rehearsed against a controlled failure injection — untested runbooks are aspirational docs. Output is one runbook file per incident class in runbooks/, a game-day-plan.md, and a postmortem template. Use this skill when the user asks "write a runbook for X", "we had an incident — capture the runbook", "set up on-call procedures", "what does the team do when alert Y fires"; or when devops-observability surfaces a new alert class that needs runbook coverage. Pairs with devops-observability (every runbook points at the alert + dashboard that triggered it), with memory-ontology (record the incident class + owner + first responder), with knowledge-curator (runbooks promote into the enterprise KB once stable), and with arch-breaking-change-comms (postmortems often require external communication).
status: shipped
owner_agent: devops-engineer
---

# DevOps Incident Runbook

Every recognised incident class gets a runbook of a **fixed shape**
so on-call engineers don't have to invent the response under
pressure.

> **An untested runbook is a wish.** Every runbook is rehearsed
> at least once per quarter via a controlled failure injection
> (game day). If the runbook hasn't been rehearsed, it doesn't
> count — flag it for the next game day.

## Why this exists

Incident response failures are predictable:

1. **Runbook missing.** Alert fires; on-call has to debug from
   first principles. Recovery is 3× slower than it should be.
2. **Runbook wrong.** Runbook was written once, hasn't been
   tested since, references commands that no longer exist or
   dashboards that have been renamed.
3. **Runbook unfindable.** It exists somewhere — wiki, Slack,
   someone's gist — but the on-call engineer can't find it at
   3am.
4. **Postmortem skipped.** Incident resolved; nobody writes
   what happened or how to prevent it. The same incident
   recurs.

This skill ships a runbook *format*, a *practice cadence*, and
a *postmortem template* — together they turn incident response
from heroics into routine.

## When to fire

Fire when:

- The user asks *"write a runbook for X"*, *"capture this
  incident as a runbook"*, *"set up the on-call procedures"*.
- `devops-observability` defines a new alert class that needs
  runbook coverage.
- A recent incident exposed missing or wrong runbook coverage.
- Quarterly game-day cycle is starting.

Do **not** fire when:

- The "runbook" requested is really a one-time investigation
  doc (write that doc directly).
- The user wants help during an active incident — don't write
  a runbook; help them resolve, then write the runbook after.

## Inputs

Required:

- The incident class to runbook. Either:
  - From an alert (preferred — alerts and runbooks pair 1:1).
  - From a real incident postmortem.
  - From a known failure mode the team anticipates.
- `devops-observability` output (dashboards + alerts) for the
  detection step.

Asked once (cap at 3):

1. **First responder.** Named individual or on-call rotation.
2. **Severity classification.** SEV1 (page immediately) / SEV2
   (page during business hours) / SEV3 (next-day investigation).
3. **External-comms requirement.** Does this incident class
   require status-page update / customer notification?

## The fixed runbook shape

Five sections, always in this order. **Do not rearrange.** The
order matches the cognitive flow during a real incident.

### 1. Detect

- **Which alert fires.** Alert name + alert URL.
- **First dashboard to open.** Dashboard URL.
- **First three things to look at on the dashboard.** Specific
  charts / panels.
- **Confirmation checks.** How to confirm this is the incident
  the alert thinks it is (alerts have false positives).

### 2. Diagnose

A decision tree. Each node:

- **Symptom** to check for.
- **Command / query** to check (verbatim).
- **If yes** → next node or "mitigate Y".
- **If no** → next node or "escalate to <X>".

Tree depth: 3–6 levels typical. Deeper than 6 means the
incident class is too broad — split it.

### 3. Mitigate

Verbatim commands. Not pseudocode. Not "you would …".

- **Most-likely mitigation first.** Documented commands.
- **Verification** after each step.
- **Escalation** if mitigation doesn't work (next runbook or
  named engineer).

### 4. Recover

Returning to steady state after mitigation:

- **Verify** the service is healthy (which dashboards, what
  thresholds).
- **Unwind** any temporary mitigations (restore traffic to
  affected region, re-enable feature flag, restart paused
  workers).
- **Communicate** internally — incident channel update; on-call
  hand-off if shift is changing.
- **Time check** — record when the incident is considered
  resolved.

### 5. Postmortem

Pointer + template, not the postmortem itself (postmortems are
per-incident, not per-runbook):

- **When required.** Default: every SEV1; SEV2 if novel;
  SEV3 by judgement.
- **Template.** Link to
  [references/postmortem-template.md](references/postmortem-template.md).
- **Where filed.** Standard location (e.g. `docs/postmortems/`).
- **Review cadence.** Reviewed in team retro; learnings update
  the runbook.

## The procedure

### Phase 1 — Pick the class boundary

A *runbook class* is "all incidents that detect via the same
alert and have similar mitigation". Too broad and the runbook
is unusable; too narrow and you have 200 runbooks.

Heuristics:

- **One runbook per alert** is usually right.
- **One runbook per dependency outage class** (e.g. "Postgres
  unavailable", "Redis unavailable", "external auth provider
  down") regardless of which service hits it.
- **Per-service** runbooks for service-specific failure modes
  (e.g. "Auth service: token signing key expired").

### Phase 2 — Detect step

Pull from `devops-observability` output:

- The alert name + URL.
- The matching dashboard + URL.
- The first three charts to inspect.

If the alert doesn't exist yet, **stop** — you're writing a
runbook for a failure mode the team can't detect. Add the alert
via `devops-observability` first.

### Phase 3 — Diagnose tree

Brainstorm the top 3–5 causes for this class. For each:

- Identifying symptom.
- Verification command (use the actual env's CLI / dashboard).
- Branch decision.

Order causes by historical likelihood (if data exists) or by
ease-of-check (cheap checks first).

### Phase 4 — Mitigation commands

For each cause-branch, document the mitigation as **verbatim
commands** the on-call can paste:

- Exact CLI / `kubectl` / cloud-console command.
- Env vars or context required (`KUBECONFIG`, `AWS_PROFILE`).
- Required permissions (named role).
- Time the command typically takes.
- How to verify it worked.

Anti-pattern: *"SSH to the box and restart the service"* — too
vague. *"Run `kubectl rollout restart deployment/auth -n prod`
(requires kubectl context `prod`; takes 30–90s; verify via
`kubectl get pods -n prod | grep auth`)"* — correct.

### Phase 5 — Recovery + communication

- **Verify** steps with thresholds.
- **Unwind temporary mitigations** (often forgotten — feature
  flags left flipped, workers left paused).
- **Internal communication template** — what to say in the
  incident channel.
- **External communication trigger** — when status page update
  / customer email is required. Hand off to `arch-breaking-
  change-comms` for the comms artifacts.

### Phase 6 — Postmortem section

Reference the postmortem template. Don't reinvent the postmortem
per runbook — one template across all runbooks.

### Phase 7 — Game-day plan

For each runbook, schedule a quarterly game day:

| Field | Detail |
|---|---|
| Cadence | Quarterly minimum; before any major launch |
| Failure injection | How to controllably reproduce the incident class (e.g. `kubectl scale --replicas=0`; chaos engineering tool; staging env failure) |
| Participants | On-call rotation + 1 observer (records what's confusing) |
| Success criteria | Mitigation step reached within target time; no improvisation needed |
| Out-of-bounds | What's off-limits (e.g. don't touch prod) |
| After-action | Update the runbook with anything that surprised the participants |

Write `runbooks/game-day-plan.md` covering the schedule across
all runbook classes.

### Phase 8 — Emit the runbook

Write `runbooks/<incident-class>.md` using
[references/runbook-template.md](references/runbook-template.md).

After writing:

1. Cross-link from the matching alert (alert's runbook URL).
2. Add to the runbook index (`runbooks/INDEX.md`).
3. Schedule first game-day rehearsal.
4. Persist as `type: project` memory (`runbook_<slug>_<class>_v1`).
5. Optionally promote to `knowledge-curator` for the enterprise
   KB once the runbook has survived two game-day cycles
   unchanged.

## Anti-patterns

- **Runbook as prose.** *"Check whether the database is healthy
  and consider restarting it"* is not actionable at 3am. Commands.
- **Untested runbook.** Schedule the game day before writing the
  runbook; the schedule keeps you honest.
- **Runbook in five places.** Single source of truth in
  `runbooks/`. Link from everywhere else.
- **Decision tree depth >6.** The class is too broad; split.
- **No postmortem trigger.** Without a documented "when we
  postmortem", the team postmortems some incidents and not
  others; learning is uneven.
- **Postmortem as blame.** The template enforces blameless
  language. Read the postmortem template before writing one.
- **Runbook drift.** Runbook references commands / dashboards
  that don't exist. Quarterly game day catches this; if a game
  day surfaces drift, fix it before declaring the game day
  done.

## Companion skills

- `devops-observability` — alerts + dashboards the runbooks
  point at.
- `arch-breaking-change-comms` — external comms when an
  incident affects customers.
- `memory-ontology` — record incident class, owner, first
  responder.
- `knowledge-curator` — runbooks promote to the enterprise KB
  once stable.
- `requirement-audit` — verify each declared runbook actually
  exists and has been game-dayed.

## Reference files

- [references/runbook-template.md](references/runbook-template.md) —
  the fixed-shape runbook template.
- [references/postmortem-template.md](references/postmortem-template.md) —
  blameless postmortem template.
- [references/game-day-template.md](references/game-day-template.md) —
  per-runbook game-day plan.
- `references/severity-classification.md` — SEV1 / SEV2 / SEV3
  definitions and decision rules.
