# Merge Checklist

The phase-by-phase checklist for a merge run. Copy-paste and tick off.

```
[ ] Phase 1 — Gather
    [ ] Identified merge mode (solo / multi / override-promotion)
    [ ] Read every proposal file in scope
    [ ] Parsed front matter; rejected proposals with status != "proposed"
    [ ] Grouped proposals by target file

[ ] Phase 2 — Detect conflicts (multi-merge / override-promotion only)
    [ ] For each target with multiple proposals:
        [ ] Classified overlap as none / adjacent / direct
        [ ] If direct: surfaced conflict to user with resolution options
        [ ] User chose: pick one / merge by hand / sequence
    [ ] All direct conflicts resolved before continuing

[ ] Phase 3 — Preview the diff
    [ ] For each target file:
        [ ] Rendered new content
        [ ] Generated unified diff
        [ ] Surfaced to user
    [ ] User signaled approval (or aborted cleanly)

[ ] Phase 4 — Apply
    [ ] For each target:
        [ ] Wrote new content
        [ ] Bumped version (patch / minor / major as appropriate)
        [ ] Updated `updated:` to today
        [ ] Recorded `last-evolved:` and merged proposal IDs

[ ] Phase 5 — Update proposal status
    [ ] Changed status from "proposed" to "merged"
    [ ] Added `merged-at:` and `merged-into:` fields
    [ ] Did NOT delete the proposal files

[ ] Phase 6 — Downstream cross-reference check
    [ ] skill-orchestrator/SKILL.md
    [ ] references/workflow-patterns.md
    [ ] SCENARIOS.md (all relevant scenarios + appendix)
    [ ] README.md (only if counts changed)
    [ ] Companion sections in sibling SKILL.md files
    [ ] INSTRUCTIONS/projects/*/skill-overrides/ (for promotion mode)
    [ ] Generated cross-reference report

[ ] Phase 7 — Memory hook
    [ ] Wrote type: feedback memory pointing at the merged proposals
```

## When to display the checklist to the user

Display the checklist when:

- The merge is non-trivial (more than two proposals, or any proposal
  with `kind: procedure`).
- The user is doing their first merge in the framework.
- A previous merge had a problem and slowing down is appropriate.

For routine single-proposal merges, the checklist is internal — the
user sees the diff preview (Phase 3) and the final report (Phase 6 +
the success summary), not the procedural details.

## Success summary template

After Phase 7, produce:

```
Merge complete.

Applied: <N> proposal(s) → <M> target file(s)
Versions bumped:
  - skills/<group>/<skill>/SKILL.md: <old> → <new>
  - ...
Downstream updates:
  - <file>: <one-line summary>
  - ...
Proposal status updates:
  - <count> proposals marked "merged"
Memory entry written: <path>

Recommended next step:
  <one concrete action — usually "run requirement-audit against the merged
  proposals to confirm the change landed everywhere">
```
