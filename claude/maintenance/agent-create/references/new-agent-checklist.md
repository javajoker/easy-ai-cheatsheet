# New-Agent Registration Checklist

Copy-paste and tick off. This is the Phase-5 wiring that makes a scaffolded
agent actually fire — the step the manual `agents/README.md` procedure is
easiest to forget. The six numbered steps map 1:1 to that procedure.

```
[ ] Phase 1 — Qualify
    [ ] Clears the "job, not a task" bar (multi-skill, multi-phase, owns a
        deliverable contract) — NOT a wrapper around one skill
    [ ] All five questions answerable: role / when-to-fire / skills /
        workflow / deliverables+verification
    [ ] Single-owner rule holds (each deliverable has exactly one agent)
    [ ] If not formalised: routed to scenario-strategist first, then resumed

[ ] Phase 2 — Skill set
    [ ] Read agents/CHECKLIST.md (live catalogue — did NOT hardcode)
    [ ] skills_used split into shipped: vs proposed:
    [ ] Missing skills recorded as proposed follow-ups (not blocking)

[ ] Phase 3 — Draft AGENT.md
    [ ] Frontmatter matches the agents/README.md contract
    [ ] Body sections present: Why / When-to-fire (+do-not-fire) /
        N-phase workflow / Inputs upfront / Companion agents /
        Companion skills / Anti-patterns / Deliverable contract / References
    [ ] focus_area is a valid enum value (or a new value, noted for the README)

[ ] Phase 4 — Checkpoint
    [ ] Surfaced full drafted AGENT.md to the user
    [ ] User approved
    [ ] Wrote agents/<name>/AGENT.md

[ ] Phase 5 — Register (the six steps)
    [ ] 1. agents/<name>/AGENT.md written
    [ ] 2. agents/CHECKLIST.md — per-agent status block added at correct
           status (draft/stub/shipped), shipped vs proposed skills listed
    [ ] 3. agents/README.md — table row added (+ focus-area enum if new)
    [ ] 4. SCENARIOS.md — scenario added, OR flagged as a follow-up
           (no scenario ⇒ status stays draft, not shipped)
    [ ] 5. skill-orchestrator catalogue — orchestrator can prefer the agent
           (it reads agents/CHECKLIST.md at runtime; verify step 2 covers it)
    [ ] 6. companion_agents mirrored — bidirectional partners name it back

[ ] Phase 6 — Memory
    [ ] type: project memory written (identity + contract + status)

[ ] Status gate
    [ ] status = draft unless: all dependent skills shipped AND a SCENARIOS
        entry exists AND the deliverable contract is real → then shipped
```

## The status-promotion gate

A new agent is **`shipped`** only when *all three* hold:

1. Every skill in `skills_used.shipped` actually exists.
2. A `SCENARIOS.md` entry documents when it fires.
3. The deliverable contract names real, auditable artifacts.

Until then it is **`draft`** (AGENT.md complete) or **`stub`** (frontmatter
+ intent only). Recording an honest `draft` is better than a `shipped`
label that lies — the CHECKLIST is read by `agent-group-formation` to decide
what's available, so a false `shipped` mis-staffs future groups.

## What to surface to the user

After Phase 5, report which steps landed and which are deferred:

```
Scaffolded agent: agents/<name>/AGENT.md (status: draft)
Registered:
  [x] CHECKLIST.md status block
  [x] README.md table row
  [ ] SCENARIOS.md entry — deferred (follow-up)
Proposed skills (gaps): <list> — create via skill-creator / skill-evolution
Promote to shipped when: skills exist + SCENARIOS entry written.
```
