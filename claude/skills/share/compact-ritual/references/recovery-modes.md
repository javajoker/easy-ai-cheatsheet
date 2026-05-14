# Compact Ritual — recovery modes

What to do when each of the three artifacts fails to survive `/compact`. The
common thread: ask before rebuilding.

## Cognitive library

### Mode A — block is intact

Continue. Nothing to do beyond the normal post-compact verification.

### Mode B — block is summarized

You see something like:

```
<cognitive_library>
Several confirmed terms from earlier turns including simplified brand
story, high-end aesthetic, and others.
</cognitive_library>
```

The summarizer collapsed the structure. Two-step recovery:

1. Re-render the full structured form from your memory of it.
2. Surface it to the user and ask: *"the library got summarized during
   compaction. Here is my reconstruction — does each entry match what you
   remember agreeing to?"* Wait for confirmation before treating any entry
   as `confirmed`.

### Mode C — block is missing

The summarizer dropped it. Worst case for the library.

1. Do NOT silently rebuild.
2. Tell the user: *"the cognitive library did not survive compaction. I can
   reconstruct it from my recollection of the conversation, but I would
   rather confirm each entry with you before treating it as live. The terms I
   recall agreeing on are: A, B, C. Are those right?"*
3. Mark every reconstructed entry as `status: tentative` until the user
   confirms each.

## Cognitive profile

The profile is more resilient than the library because its entries are
typically broader (linguistic style, comprehension patterns, constraints) and
less easily mis-summarized. But the same three modes apply.

For Mode C specifically, the profile can usually be rebuilt to ~80% accuracy
from a quick re-read of the user's last few messages. Do that re-read first,
then surface a draft profile and ask for confirmation on the specific entries.
A profile entry that the user does not actively recognize as their own is
worse than no entry.

## MEMORY ontology

The memory files are on disk. They do not literally disappear during
compaction — what disappears is the live-conversation knowledge that they
exist and what they say. Two recovery modes:

### Mode A — snapshot block survived

Use it as the inventory. Cross-check the snapshot against actual files on
disk (the harness still has them). If they match, continue.

### Mode B — snapshot block did not survive

Re-read `MEMORY.md`. For each entry that the conversation is likely to need,
load the corresponding memory file. Treat this as a small "hydration" pass.

The flag here is when MEMORY.md and your post-compact context disagree:

- `MEMORY.md` lists a memory you do not recall — read the file, then proceed.
  No need to involve the user.
- Your post-compact context references a memory that is not in `MEMORY.md` —
  this is a real anomaly. Tell the user. Likely either a memory was deleted
  in another session or your context is corrupted.

## Recovering from multiple-block loss

If all three blocks are missing, treat it as a full reset and ask the user
explicitly: *"I lost the working context across /compact — can you give me a
quick recap of where we were?"* The recap will let you triangulate which
artifacts to rebuild and in what order.

Resist the urge to rebuild everything in parallel from your guesses. One
recovered artifact at a time, confirmed before moving to the next, beats a
fast guess-fest by a wide margin.

## Documenting the recovery

If recovery was non-trivial, write a short memory:

```markdown
---
name: Compact recovery 2026-06-15
description: lost cognitive library during /compact; reconstructed and re-confirmed all five entries
type: project
scope: project:<slug>
created: 2026-06-15
status: active
---

During the 2026-06-15 session, `/compact` was triggered around turn 47 and the
cognitive library did not survive. Entries `[T1]` through `[T5]` were
reconstructed from memory and confirmed entry-by-entry with the user.
Rebuilt entries are now in the live library.

How to apply: next time compaction is anticipated on this project, surface the
library block explicitly even if the harness does not warn.
```

This memory ages out quickly (delete after a few sessions), but in the short
term it teaches future Claude instances on the same project to be paranoid
about compaction.
