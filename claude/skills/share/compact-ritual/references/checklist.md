# Compact Ritual — checklists

Literal pre/post checklists, ready to surface in the conversation when a status
update is appropriate.

## Pre-compact checklist

```
[ ] Inventory live artifacts
    [ ] Cognitive library entries (count: __)
    [ ] Cognitive profile entries (count: __)
    [ ] Memory files written or updated this session (count: __)
    [ ] In-flight decisions not yet written to memory (count: __)
[ ] Promote any in-flight decisions to memory if they should outlive the session
[ ] Surface the three tagged blocks in full:
    [ ] <cognitive_library>
    [ ] <cognitive_profile>
    [ ] <memory_ontology_snapshot>
[ ] Surface <in_flight> block if any task is partially complete
[ ] Confirm any uncertain entries with the user (one targeted question per term)
[ ] Confirm with the user that /compact is OK to proceed (if not user-initiated)
```

## Post-compact checklist

```
[ ] Verify three tagged blocks are present in post-compaction context
    [ ] <cognitive_library>            — present / degraded / missing
    [ ] <cognitive_profile>            — present / degraded / missing
    [ ] <memory_ontology_snapshot>     — present / degraded / missing
[ ] For each missing or degraded block: ask the user before rebuilding
[ ] Reconcile cognitive library against MEMORY ontology (treat memory as canonical on conflict, but ask)
[ ] Read the <in_flight> block aloud (paraphrase, one sentence) and confirm
    the next step before continuing
[ ] If no <in_flight> block exists, ask the user where to pick up
```

## When the checklist itself is appropriate to display

- The user explicitly asks *"what does the compact ritual look like?"*
- You are walking a new user through their first compaction.
- A previous compaction failed and you want to slow down for the next one.

Otherwise the checklist is for your internal use. The user should see the
*output* of the ritual (the tagged blocks, the targeted question, the
confirmation), not the procedure itself. Ritualizing visible process is what
makes alignment feel like an interrogation.
