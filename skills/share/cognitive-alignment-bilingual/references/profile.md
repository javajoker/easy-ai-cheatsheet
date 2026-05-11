# Cognitive Profile — Modeling the Person

The cognitive profile is a structured model of *how this user thinks, expresses, and comprehends*. It is the answer to the question: "what does it mean to align my expression to this specific person, not a generic one?"

The profile is observation-based. Every entry traces to actual conversational evidence. You are not interviewing the user — you are watching them, and writing down what you see.

## Why the profile matters

The library answers *what specific words mean*. The profile answers *how to use those words*. Two users can have nearly identical libraries and still need entirely different responses, because one wants the principle first and one wants the example first, one wants the bottom line and one wants the reasoning, one reads English fluently and one is translating in their head.

The single highest-leverage dimension is the **expression-comprehension gap**: the asymmetry between how a person speaks and how a person understands. Most users have one. Tracking it is what separates real alignment from surface mimicry.

## Schema

```
<cognitive_profile>

## Language & translation pattern
- Primary language: <e.g. Mandarin Chinese>
- Other languages used: <e.g. English (technical reading; mid fluency in writing)>
- Switches into <language> when: <observed trigger>
- Concepts they only have words for in <language>: <list, with evidence>

## Domain expertise map
- Expert: <domain> — evidence: <turn / quote>
- Intermediate: <domain> — evidence: <…>
- Novice: <domain> — evidence: <…>
- Unknown: <domain> (no evidence yet)

## Linguistic style
- Formality: <formal | conversational | mixed>
- Directness: <direct | indirect | varies by topic>
- Sentence length they produce: <short / medium / long>
- Sentence length they best absorb: <short / medium / long> — may differ
- Metaphors that land: <observed examples>
- Metaphors that did not land: <observed examples>

## Comprehension patterns
- Best receives information via: <examples-first | principles-first | top-down | bottom-up | other>
- Concrete vs abstract preference: <…>
- Visual aids: <welcomes | tolerates | prefers prose>
- Step-by-step vs gestalt: <…>
- Wants summary before detail, or detail before summary: <…>

## Expression-comprehension gap
- Vocabulary outpaces understanding for: <terms / domains where they use words confidently but follow-up reveals partial grasp>
- Understanding outpaces vocabulary for: <areas where they grasp deeply but express simply, often non-native language>
- Implications for Claude's response: <e.g. "define jargon they reuse, even if they sound expert in it"; "trust their gist even when phrasing is rough">

## Feedback signals
- Confusion looks like: <observed pattern — e.g. "rephrases my words back as a question">
- Pushback looks like: <observed pattern — e.g. "switches to short sentences and asks a sharp question">
- Satisfaction looks like: <observed pattern — e.g. "elaborates with their own example">
- Polite non-acceptance looks like: <observed pattern — e.g. "says 'okay' and changes the subject">

## Constraints / things to avoid
- <e.g. "Avoid sports metaphors — landed badly turn 6">
- <e.g. "Do not bottom-line first; user prefers to see the reasoning then the conclusion">

## Confidence
- High-confidence sections: <…>
- Provisional sections: <…>
- Sections with no evidence yet (do not act on these): <…>

</cognitive_profile>
```

## How to populate it

Observation, not interrogation. The profile grows from things the user has already shown you. Each entry should be traceable to a specific moment in the conversation — ideally with a turn number or short quote.

Sources of evidence, ranked by reliability:

1. **What they corrected.** The strongest signal. If they pushed back on a word, a framing, or a tone, that's gold.
2. **What they elaborated on unprompted.** Tells you what they consider important and how they naturally explain.
3. **What they ignored.** Reliably indicates lack of resonance, though not always lack of comprehension.
4. **How they asked questions.** Question shape reveals comprehension structure better than question content.
5. **Direct statements about themselves.** Useful but discount slightly — people's self-models aren't always accurate, especially about how they best learn.

**What is *not* evidence:** the user saying "okay," "got it," "go on," or any other minimal acknowledgment. These are conversational lubricant, not data. Treating them as confirmation is a primary failure mode.

## Update discipline

- **Add entries with quotes or turn numbers.** "Prefers concrete examples (turn 4: asked 'can you give me a real case?')" beats "prefers concrete examples."
- **Revise, don't delete.** When a profile entry turns out to be wrong, note the revision. "Originally thought formal-direct; turn 12 revealed they soften critical feedback heavily — actually formal-indirect." Repeated revisions to the same dimension are themselves a signal.
- **Mark confidence honestly.** If you only have one data point for a claim, it's provisional. Saying "high confidence" with one data point is worse than saying nothing — it bakes in your assumption and shapes future responses around a shaky reading.
- **Do not generalize from one conversation across users.** This is a profile of *this* person. A profile that drifts toward "what kind of user is this" categorization is starting to fail.

## Worked example

Mid-conversation profile of the same Chinese-speaking marketing director from the library example:

```
<cognitive_profile>

## Language & translation pattern
- Primary language: Mandarin Chinese
- Other languages used: English (reads fluently; writes with mild rigidity; switches to English for technical/business terms — "KPI", "persona", "tier-1 city")
- Switches into English when: discussing measurable outcomes or international references
- Concepts she only has words for in Chinese: 高端 (turn 4, 9 — she struggled to map this to one English term; "high-end," "luxury," "understated authority" all came up)

## Domain expertise map
- Expert: brand strategy, consumer marketing in mainland China (turn 2, 5, 11)
- Intermediate: visual design vocabulary — knows what she wants but reaches for examples rather than terms (turn 4)
- Novice: typography specifics (turn 8 — used "serif" but follow-up question revealed she meant "any non-sans-serif")
- Unknown: print production, digital advertising operations

## Linguistic style
- Formality: conversational with formal anchors (uses 您 once early, then settles into 你)
- Directness: direct on goals, indirect on feedback ("maybe we can try another angle" = "this is wrong, redo it" — turn 6)
- Sentence length she produces: medium
- Sentence length she best absorbs: short, with one example each
- Metaphors that landed: clothing/fabric ("texture," "weight" — turn 5)
- Metaphors that did not: car ("under the hood" — fell flat, turn 7)

## Comprehension patterns
- Best receives information via: example-first, then principle
- Concrete vs abstract: concrete, strongly
- Visual aids: welcomes, asks for them ("can you mock something up?" — turn 6)
- Wants summary before detail: no — wants to see the work, then the takeaway

## Expression-comprehension gap
- Vocabulary outpaces understanding for: typography terms ("serif", "kerning" — used confidently but follow-ups revealed approximate grasp)
- Understanding outpaces vocabulary for: visual aesthetics — describes only by analogy and reference brands, but the underlying judgment is sharp and consistent
- Implications: when she uses a typography term, define it inline without making a thing of it. When she gestures at aesthetics with brand references, trust her judgment and translate to specifics myself.

## Feedback signals
- Confusion looks like: long pause, then a question that rephrases my last sentence back as a question
- Pushback looks like: "maybe…", "or we could…" (turn 6, 10)
- Satisfaction looks like: she gives a new example of the same concept (turn 5, 9)
- Polite non-acceptance: "好的，然后..." ("okay, and then…") with no engagement on what I just said (turn 3)

## Constraints / things to avoid
- No car or sports metaphors
- Do not lead with the conclusion; show the work first
- Do not over-define terms she uses fluently — she finds it patronizing (turn 5 reaction)
- Exception: typography terms — define these gently, because of the expression-comprehension gap

## Confidence
- High: language pattern, linguistic style, comprehension patterns
- Provisional: domain expertise map (especially "novice in typography" — only one data point)
- No evidence yet: how she handles disagreement on strategy (vs. on execution)

</cognitive_profile>
```

## Using the profile

The profile is reference material for *Claude*, not output to the user. You don't read it aloud and you don't quote from it. You consult it before responding, and you let it shape:

- Which examples you reach for.
- Whether you lead with the principle or the case.
- How long your sentences run.
- Which library terms you take extra care to define inline.
- How you interpret the user's next message (their "okay" probably means X based on the profile, not Y).

The profile is most valuable in conjunction with the library. The library tells you what the user means by their words. The profile tells you which of your possible responses will actually land.

## Anti-patterns

- **Filling it in fast.** A profile written confidently in turn 2 is mostly a profile of your assumptions. Let it grow.
- **Removing the evidence column.** Without quotes or turn numbers, the profile becomes ungrounded — and after `/compact` you'll have no way to tell which entries to trust.
- **Treating the profile as a category.** "Detail-oriented user, type B" is not a profile, it's a stereotype. The profile is of *this* person.
- **Locking it in.** People change within a conversation. Especially the expression-comprehension gap — as they get more comfortable, they may speak more loosely, or as the topic shifts, the gap moves.
- **Exporting it without consent.** If the profile is going to persist across sessions or be reused for "AI alignment use" more broadly, that's a privacy-sensitive artifact about a specific person. Treat it accordingly.
