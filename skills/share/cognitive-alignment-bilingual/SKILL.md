---
name: cognitive-alignment
description: Use this skill whenever engaged in sustained communication with a user — especially across languages, expertise levels, or domains where the same word can carry different meanings. Trigger it continuously through any consultative, client-facing, or multi-turn conversation, not just at the start. The skill maintains two artifacts: a per-conversation cognitive library of mutually confirmed terms, and a per-person cognitive profile capturing how the user thinks, expresses, and comprehends — so Claude can align its expression to the user's actual cognitive style, not a generic one. Apply whenever a domain term is first introduced, when the user pushes back, when Claude finds itself silently "interpreting" a phrase, or after several turns when drift becomes likely. Pair with Claude Code's /compact command so both artifacts survive context compression. Use proactively even when the user has not asked for "alignment" — they almost never will by name; the cue is the conversational situation, not the keyword.
---

# Cognitive Alignment

A working skill for building, maintaining, and repairing shared understanding between Claude and the person Claude is talking with. The skill produces two durable artifacts:

- A **cognitive library** — a per-conversation list of mutually confirmed concepts (what specific terms mean to this user).
- A **cognitive profile** — a per-person model of how this user thinks, expresses, and comprehends (how to talk with them).

Plus two structured response templates (deviation warning, memory correction) for when alignment slips.

This is a meta-skill. It runs alongside whatever the actual task is. The user almost never asks for "cognitive alignment" by name. You notice the signals (ambiguous term, untranslated concept, user pushback, conversation length) and apply it.

## Why this exists

In sustained client-facing conversation, especially across languages or expertise levels, the same word means different things to different people. "Simple" to a developer is not "simple" to a non-technical client. "Report" in finance is not "report" in marketing. When that gap stays invisible, work compounds in the wrong direction and is expensive to repair later. The cure is cheap: catch the gap early, name it explicitly, confirm what each side actually means, and remember the agreement. The cost of one clarifying question now is much less than the cost of redoing work three turns from now.

## The cognitive library

Maintain a running record of mutually confirmed concepts. This is the durable artifact — it's what survives `/compact`, what carries turn-to-turn, and what tells you when something new contradicts something already agreed.

Keep it visible near the top of your working state as a block:

```
<cognitive_library>
| # | Term (user's wording) | User's meaning | Aligned meaning | Status | Turn |
|---|----------------------|----------------|-----------------|--------|------|
| 1 | 简化报告 | Plain language, same structure | Rewrite for readability without removing sections or data | confirmed | 3 |
| 2 | …                    | …              | …               | …      | …    |
</cognitive_library>
```

Field meaning:
- **Term**: the exact phrase the user used, in their language, untranslated.
- **User's meaning**: how *they* described it, in their words. Not your paraphrase.
- **Aligned meaning**: the version both sides confirmed, in English. This is what you act on.
- **Status**: `confirmed` (both sides explicitly agreed) | `tentative` (one-sided assumption, not yet checked) | `superseded` (replaced by a later entry — keep the row, mark it, don't delete).
- **Turn**: roughly when it was confirmed, for traceability after compaction.

See `references/library-format.md` for the full schema and worked examples.

## The cognitive profile

If the library answers *"what do specific words mean to this user,"* the profile answers *"how does this user think, express, and comprehend."* The profile is what makes the library actionable. Without it, you have a glossary; with it, you have a model of the person you can align your expression to.

The profile captures, with explicit confidence levels and supporting evidence:

- **Language & translation pattern** — primary language, fluency in others, when they switch, what concepts they only have words for in one language.
- **Domain expertise map** — where they're expert, intermediate, novice. Important because expertise is rarely uniform: a CFO can be expert in finance and novice in software, and the same word ("performance," "model") means radically different things in each.
- **Linguistic style** — formality, directness, use of jargon, sentence length, metaphors that land vs ones that don't.
- **Comprehension patterns** — how they best receive new information: examples first or principles first, top-down or bottom-up, concrete or abstract, visual aids or pure prose, analogies (from which domains?), step-by-step or gestalt.
- **Expression-comprehension gap** — *the key alignment failure mode*. Where their vocabulary outpaces their understanding (uses jargon they don't fully grasp), or their understanding outpaces their vocabulary (grasps deeply but expresses simply, often when working in a non-native language). Tracking this is what separates real alignment from surface mimicry.
- **Feedback signals** — what their pushback looks like (sharp questions? silence? changing the subject?), what their confusion looks like (rephrasing your words back as questions? agreeing too quickly?), what their satisfaction looks like.
- **Constraints** — things to avoid based on what's already gone wrong this conversation or in past sessions.

Keep the profile as a tagged block, like the library:

```
<cognitive_profile>
... structured profile ...
</cognitive_profile>
```

The profile is **observation-based, not questionnaire-based**. You populate it from things the user has already shown you, not from asking them to fill in a form. Every field should be traceable to actual conversational evidence. Unsupported entries are worse than empty entries — they bake in your assumptions instead of the user's reality.

See `references/profile.md` for the full schema, population method, and a worked example.

## Library vs profile — when each one fires

| Situation | Use library | Use profile |
|---|---|---|
| User uses a domain term in an unusual way | ✓ | |
| User repeatedly prefers examples over abstract explanation | | ✓ |
| User pushes back on a specific word you used | ✓ | |
| User pushes back on *how* you explained something | | ✓ |
| User uses jargon but their follow-up questions suggest they don't fully grasp it | ✓ (define the term) | ✓ (note the expression-comprehension gap) |
| `/compact` is about to run | Surface both | Surface both |

Both feed into the same alignment goal — but the library tells you *which words* to use, while the profile tells you *how to use them*.

## The three moves

Three behaviors do the real work. Don't apply all three to every term — spend the alignment effort on the load-bearing concepts (the ones that, if misunderstood, would waste real work).

1. **Question** — when a term is ambiguous or domain-loaded, ask before assuming. One question, specific, in the user's language. Not a barrage.
2. **Restate** — paraphrase the user's intent back to them *in their framing, not yours*. "So you mean X, where X = [your reading]." Give them the chance to correct cheaply.
3. **Confirm** — before acting on a high-stakes concept, get an explicit acknowledgment. Then write it into the library.

Restate is the one most often skipped. Skipping it is what causes the slow drift the deviation warning later has to clean up.

## When to trigger an alignment check

Proactively, not only on request:

- First time a domain term appears.
- The user uses a common word in an unusual way.
- You catch yourself mentally translating, interpreting, or "filling in" what they probably meant.
- The user pushes back on a previous response — pushback is almost always alignment data.
- 10+ turns have passed with no new library entries confirmed.
- Immediately after `/compact` runs, to verify the library survived intact.
- Before producing any deliverable (document, code, plan) that depends on a term in the library.

## Interaction with `/compact`

Claude Code's `/compact` summarizes long conversations to reclaim context space. Both the cognitive library and the cognitive profile must survive this. Three practices make that reliable:

1. **Keep both artifacts in tagged blocks** (`<cognitive_library>…</cognitive_library>` and `<cognitive_profile>…</cognitive_profile>`). Tagged blocks are more likely to be preserved verbatim or near-verbatim by summarization, and the tags themselves are easy to scan for after compaction.
2. **Pre-compact ritual**: if the user signals `/compact` is about to run, or you notice context pressure, output both blocks in full as your final visible artifact in that turn. This ensures they appear in the conversation history the summarizer reads.
3. **Post-compact check**: right after `/compact`, verify both artifacts are still present and intact. If entries are missing or vague, ask the user to confirm the ones you remember rather than silently rebuilding from guesses — silent reconstruction is the most expensive form of misalignment, because it looks fine until it isn't.

## Two response templates

When alignment drifts or needs updating, use one of two structured responses. Full templates with bilingual scaffolding are in `references/templates.md`.

- **Deviation warning** — when you detect that the current direction may have drifted from a previously confirmed meaning. Surface it immediately rather than letting it grow.
- **Memory correction** — when an entry in the cognitive library needs to be revised because new information contradicts it. This produces a `superseded` row plus a new `confirmed` row.

Both templates are written **side-by-side in the user's native language and English**. The user's-language side is for them to read and react to; the English side is your durable anchor for the library. Use the templates as scaffolds, not scripts — make the misalignment explicit and cheap to repair, not ritualistic.

## What success looks like

After several turns: the user feels Claude is *getting it* — using their terminology, mirroring their framing, anticipating their constraints, explaining in the style they actually absorb. The cognitive library has 3–10 entries, each load-bearing, all confirmed. The cognitive profile has enough structure that a fresh Claude instance reading it could pick up the conversation without re-asking everything. When something does go off-track, it's caught within one or two turns, not five.

What failure looks like: Claude produces fluent answers that quietly use a meaning the user didn't intend, in a style the user doesn't actually absorb, the user nods and accepts them anyway, and three turns later the work is wrong and has to be redone.

## A note on tone

Alignment work, done badly, feels like an interrogation. Done well, it feels like a colleague checking in. Ask one question at a time. Keep restates short. Acknowledge when the user has clarified something — don't make them feel like they're being audited. The point is that *you* are doing the work of understanding, not asking *them* to do the work of being understood.
