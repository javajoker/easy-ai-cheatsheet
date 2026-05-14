---
name: compact-ritual
description: The pre- and post-/compact procedure that ensures three durable artifacts survive Claude Code's context compression — the cognitive library, the cognitive profile, and the MEMORY ontology. Trigger this skill whenever the user signals "/compact" is imminent, whenever you detect context pressure (auto-compact warnings, near-budget tool returns), immediately after a /compact event has happened, and at the end of any long working session even if compaction has not fired yet. Coordinates with cognitive-alignment (which owns the library + profile) and memory-ontology (which owns MEMORY.md and the per-memory files). Without this ritual, the most expensive failure mode is silent reconstruction — Claude continues without noticing that an artifact was lost or partly garbled, and acts on guesses for several turns before the user notices.
---

# Compact Ritual

Claude Code's `/compact` summarizes long conversations to reclaim context space.
Three artifacts must survive this transition or the session loses memory of what
both sides have aligned on:

1. **Cognitive library** — terms confirmed in this conversation.
2. **Cognitive profile** — how the user thinks, expresses, comprehends.
3. **MEMORY ontology** — the durable cross-session knowledge graph (`MEMORY.md` index + memory files).

The first two are session-scoped and live in tagged blocks in the conversation
itself; they are the most vulnerable. The third is on disk and rarely lost
literally, but its *connection* to the live conversation has to be re-established
after the compaction.

This skill is the procedure that makes the three survive intact.

## When to fire

Two prompts, one tail:

- **Pre-compact** — the user signals `/compact` is about to run, OR
- **Pre-compact** — the harness shows context-pressure warnings (auto-compact
  notice, tool results getting truncated, model warning of token limits), OR
- **Post-compact** — immediately after a `/compact` event, before the next
  substantive action.

A long working session (say, more than two hours of dense back-and-forth)
should run the pre-ritual proactively as a checkpoint, even if no compaction
is imminent. Treat it as a save point.

## The pre-compact procedure

Five steps. Do them in order. Skipping any of them is what produces the silent
reconstruction failure mode.

### 1. Inventory what is live

List, in your head or in scratch:

- Every confirmed cognitive library entry (with ID).
- Every confirmed cognitive profile entry (with ID).
- Every memory file that has been written or updated this session.
- Every decision the user has made this session that should outlive it.

If anything in the fourth category has not yet been written to the memory
ontology, this is the moment — promote it before compaction, not after.

### 2. Surface the artifacts in full

Output both tagged blocks as your last visible artifact in this turn:

```
<cognitive_library>
... full content of every active entry ...
</cognitive_library>

<cognitive_profile>
... full content of every active entry ...
</cognitive_profile>

<memory_ontology_snapshot>
... full MEMORY.md content, plus a one-line summary per memory file that exists ...
</memory_ontology_snapshot>
```

The `<memory_ontology_snapshot>` block is new for this skill. It is not a
substitute for `MEMORY.md` — the harness already loads that — but it puts the
*current* state of the ontology in the conversation history so the summarizer
sees it and the post-compact verification has something to compare against.

Tagged blocks are preserved more reliably than free prose. The tags
themselves also let you grep the post-compaction context to verify presence.

### 3. Confirm the snapshot is accurate

If anything in the snapshot is uncertain (an entry you marked `confirmed` but
were not 100% sure of, a memory you wrote but the user has not seen yet),
ask now. *"Before we compact, one quick check — entry `[T3]` reads as X. Is
that still right?"* One question, one term, one exchange.

This is the cheapest moment to fix misalignment. The cost goes up sharply
after compaction.

### 4. Note any in-flight work

If there is a task in progress — a half-written file, a partial plan, a
pending decision — write a short `<in_flight>` block describing where you are:

```
<in_flight>
- Working on: implementing the prototype-docs handoff in WORKFLOW.md
- Next step: update phase 3 numbering bug (currently "Phase 3" appears twice)
- Files touched: skills/ideas/WORKFLOW.md
- Blocked on: nothing
</in_flight>
```

This is for *Claude after compaction*. Past Claude is writing a note to future
Claude so the work can resume without re-asking the user where things stand.

### 5. Confirm with the user that compaction is OK to proceed

If the user invoked `/compact` themselves, they have already signed off. If
the trigger was context pressure rather than an explicit request, surface
that: *"context is getting tight; want me to run /compact now or finish the
current step first?"*

## The post-compact procedure

Three steps. Run them as the first thing in the next turn after compaction,
not after another task is already in progress.

### 1. Verify the three artifacts are present

Look for the three tagged blocks in the post-compaction context. For each:

- Present and intact → good, continue.
- Present but vague or summarized → degraded but recoverable. Re-render the
  full version from your memory of it, then ask the user to confirm the
  re-rendered version is right.
- Missing → ask the user before rebuilding. Silent reconstruction is the
  failure mode this whole skill exists to prevent.

### 2. Reconcile cognitive library against MEMORY

A common slip: a library entry was promoted to MEMORY during the session, and
both copies survive compaction but with subtly different wording. Re-read the
relevant `type: project` or `type: user` memories. If the library and the
memory disagree, surface it: *"the library entry says X, the memory says Y —
which should I treat as canonical?"*

The right answer is usually the memory (it is the durable artifact). But the
ask gives the user the chance to update either side intentionally.

### 3. Recover in-flight work

If a `<in_flight>` block exists, that is the seam to pick up at. Read it
aloud (or paraphrase it in one sentence) so the user can see you understood
where the work was paused, then continue from that step.

If no `<in_flight>` block exists and the user does not pick up a new thread
immediately, ask: *"after /compact — where would you like to pick up?"* Do
not guess at the next action based on what was happening before.

## Anti-patterns

- **Surfacing the artifacts only sometimes.** Either every pre-compact does
  it, or the ritual stops working as a defence. The user starts to trust
  that the artifacts survive automatically. Be ritualistic about *this*
  moment even though most things should not be ritualistic.
- **Silent reconstruction.** *"I think the library had X, Y, Z — let me
  rebuild it."* No. If the artifact is missing, ask. Reconstruction without
  confirmation is the most expensive form of misalignment because it looks
  fine until it does not.
- **Apologizing for the ceremony.** *"Sorry for the long block, just want to
  make sure things survive…"* — no. The block is the work. The user did not
  ask you to apologize for doing it.
- **Compacting mid-decision.** If a question is on the table and the user has
  not answered, do not run the pre-ritual. Wait for the answer first.
  Otherwise the answer arrives after compaction and now there is no context
  for what it answers.
- **Running pre-ritual without the post-ritual.** Pre on its own is a save
  point with no readback. Always pair them. If you ran pre and the user
  never triggered `/compact`, the save was free; no harm done.

## Reference files

- `references/checklist.md` — the literal pre/post checklists in copy-paste
  form, useful when you want to surface them in the conversation as a status
  update.
- `references/recovery-modes.md` — what to do when each of the three artifacts
  fails to survive, with worked examples for each failure mode.
