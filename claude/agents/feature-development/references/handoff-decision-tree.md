# Hand-off decision tree

When the feature-development arc should yield the floor to another
agent. Each branch starts with a condition seen during the arc and
ends with a hand-off (or a "stay") decision.

## Hand off to `architecture-shepherd`

Trigger conditions:

- The feature requires a change to **how services talk to each other**
  (sync → async, REST → events, new queue, new service boundary).
- The feature requires a **database technology change** (Postgres →
  Mongo for this feature only — usually a red flag, sometimes
  justified).
- The feature surfaces a **scaling decision** that affects more than
  this feature (horizontal sharding, read-replica routing).
- The feature requires **deprecating** an existing API or behaviour.

Procedure:

1. Pause the feature arc in Phase 1 or Phase 2 (whichever surfaces it).
2. Hand the relevant `feature-spec` section + the project context to
   `architecture-shepherd`.
3. Wait for its `arch-assessment` + `arch-migration-plan` outputs.
4. Resume Phase 2 of the feature arc with the architecture decision
   recorded in section 9 (Rollout) of the spec.

**Do not** hand off when: the feature only *uses* existing
infrastructure differently; the choice is local to the feature's
module.

## Hand off to `devops-engineer`

Trigger conditions (any):

- The feature needs **new metrics or alerts** that don't have an
  obvious home in the existing observability stack.
- The feature introduces a **new background-job class** that needs a
  runbook (Phase 4 of `devops-incident-runbook`).
- The feature requires **secret rotation** or new vault entries.
- The feature changes the **release process** (e.g. needs a
  canary rollout where the project has only ever done straight ship).
- The feature's **migration plan** requires ops support (locking
  windows, blue-green DB cutover).
- The feature needs a **new feature-flag** in a project that has no
  flag system.

Procedure:

1. The feature-development agent continues to own the *feature*.
2. `devops-engineer` is engaged in parallel for the ops slice — they
   produce the alert rule, runbook, vault entry, or pipeline change.
3. Phase 5 of the feature arc cannot complete until the ops slice
   lands.

**Do not** hand off when: the feature uses existing alerts, existing
runbooks, existing secrets, existing flag system.

## Hand off to `knowledge-curator`

Trigger conditions:

- The feature changes an entity in the **published / enterprise
  knowledge base** (not just the project's local KB).
- The feature introduces a new **canonical term** that other projects
  in the enterprise KB will want to align with.
- The feature changes the **public docs surface** (developer portal,
  API reference site, customer help center).

Procedure:

1. Phase 5 of the feature arc engages `knowledge-curator` for the
   relevant `enterprise-kb-*` slice (typically `enterprise-kb-merge`
   or `enterprise-kb-refresh-policy`).
2. The feature ships in the codebase before the KB update, but the
   KB update is on the feature arc's deliverable list — Phase 5 isn't
   done until it lands.

**Do not** hand off when: the change only affects the project's local
KB (`docs/knowledge-base/`); update that yourself via
`project-knowledge-base`.

## Hand off back to `lifecycle-pilot`

Trigger conditions (rare):

- What was described as a "feature" turns out to be a **full new
  product surface** — its own personas, its own pricing implications,
  its own launch.

Procedure:

1. Stop the feature arc at Phase 1 (no spec written yet).
2. Surface the re-scope explicitly: *"This isn't a feature — it's a
   sub-product. Routing to lifecycle-pilot."*
3. `lifecycle-pilot` may route back to feature-development for the
   first concrete deliverable inside the larger arc, but the *arc
   ownership* moves up.

This is uncommon. Most feature requests stay feature-sized.

## Stay (do not hand off)

The most common decision is to stay. Cases:

- Feature is purely additive within an existing module.
- Feature uses existing infra, existing alerts, existing flags.
- Feature only updates the project's local KB.
- Feature can be specced, coded, tested, and rolled out within the
  team's normal sprint.

Hand-offs cost time and coordination — when in doubt, stay; promote
later if a sub-task needs another agent's depth.

## One-line summary

| If the feature… | Engage |
|---|---|
| Changes service-to-service shape, DB tech, or deprecates an API | `architecture-shepherd` |
| Needs new alerts, runbooks, secrets, or pipeline changes | `devops-engineer` |
| Changes a published / enterprise KB entity or public docs surface | `knowledge-curator` |
| Turns out to be a whole sub-product | `lifecycle-pilot` |
| Fits within the project's existing infra + KB + ops | Stay — own it end-to-end |
