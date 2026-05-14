# Promotion — from cognitive library / profile to memory ontology

The cognitive library and profile (see `cognitive-alignment` skill) are
conversation-scoped. The memory ontology is session-spanning. The bridge
between them is **promotion**: when a library entry or a profile observation
has held across several sessions, it stops being a "this conversation"
artifact and becomes a "next session too" artifact.

## When to promote

A library entry `[T_n]` is a candidate for promotion when:

- It has appeared in three or more sessions on the same project, with `status:
  confirmed` each time.
- It is load-bearing — if forgotten, real work would be wasted.
- It is not already in the memory ontology under a different name (search
  before promoting).

A profile observation is a candidate for promotion when:

- It has been re-confirmed in two or more separate sessions.
- It is general enough to apply outside the current conversation (e.g.
  *"prefers principle-first explanations"* applies generally; *"is in a hurry
  today"* does not).
- It is observation-based, not assumption-based. The cognitive profile only
  contains evidence-traceable entries to begin with, but verify the evidence
  is from real conversation turns before promoting.

## Promotion is opt-in

Never promote silently. Promotion changes what future Claude instances will
"know" about the user — that is a privacy-adjacent move and the user gets to
say no.

The promotion offer is short and concrete:

> Across our last few sessions you have consistently preferred examples
> before principles. Want me to save that as a durable preference so I do
> not have to relearn it next time?

If the user agrees, write the memory and reference the cognitive artifact
that originated it:

```markdown
---
name: Comprehension pattern
description: prefers examples before principles in technical explanations
type: user
scope: global
created: 2026-05-13
status: active
---

User absorbs technical material best when one concrete example precedes the
general principle. Confirmed across sessions on 2026-04-21, 2026-05-02, and
2026-05-13.

Originated from cognitive-profile observation [P3] (see
cognitive-alignment skill) across multiple sessions on the coolshell project.
```

## What does not promote

- **Tentative library entries** — they are not even mutually confirmed yet.
  Resolve them in the live conversation first.
- **Conversation-internal terms** — a definition that only matters because of
  *this* deliverable. Stays in the library.
- **Highly volatile profile observations** — "in a hurry today", "wants
  brief answers right now". These are session-state, not the user.

## Reverse direction — loading memory into a fresh library

The reverse of promotion is **hydration**: at the start of a new session, the
relevant `type: user` and `type: project` memories should seed the cognitive
profile and library. This is not duplication — it is the same fact, expressed
once durably (memory) and once locally (library) for fast retrieval.

The cognitive-alignment skill's *post-`/compact` check* uses the same
mechanic. Treat compaction and a fresh session as the same kind of
discontinuity for these purposes.

## Avoiding the duplicate trap

A promoted memory and the library entry it came from now both exist. They will
slowly drift if both are edited independently. Two practices keep them aligned:

1. **The memory file references the cognitive artifact ID** (`[T_n]`,
   `[P_n]`) in its body. When the library entry evolves and the user
   confirms the evolution, that is the signal to also update the memory.
2. **`/compact` is the reconciliation point.** During the pre-`/compact`
   ritual, both the cognitive library and the relevant memories are surfaced.
   Differences become visible. Ask the user to reconcile if there is drift.
