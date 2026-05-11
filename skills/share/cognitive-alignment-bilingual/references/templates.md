# Alignment Templates

Two structured responses for the moments when alignment slips. Both are written **bilingual side-by-side** — the user's native language on the left, English on the right. The user reads their own side. The English side is the durable anchor that goes into the library / profile, survives `/compact`, and stays interpretable to a future Claude instance.

The worked examples below use Chinese as the user's language. Swap in whatever the user is actually speaking — Spanish, Japanese, Arabic, etc. The structure stays the same; only the left column changes.

## Principle: scaffold, not script

These templates are scaffolds. Fill in the slots, but rewrite the prose to fit the conversation's tone. The fastest way to make alignment feel like an interrogation is to read these out verbatim every time.

Use them when:
- You need to surface a specific misalignment cleanly.
- You're at a checkpoint (pre-compact, end of a working session, before producing a deliverable).
- The conversation has gotten tangled and you need to reset to a known shared base.

Don't use them:
- For minor word-choice questions — just ask.
- Every few turns ritualistically — alignment loses its weight when it's bureaucratic.
- When the user is mid-thought — wait for a natural pause.

---

## Template 1: Deviation Warning

**When to fire**: you've detected that the current direction may have drifted from a previously confirmed meaning — either because you caught yourself interpreting something silently, or because something the user just said doesn't fit an existing library entry, or because a partial deliverable seems to be diverging from what was agreed.

**Goal**: surface the drift in one short, specific message. Make it cheap to repair now.

### Structure

1. **Name the term.** One specific concept, not a vague "I'm not sure we're aligned."
2. **State what was agreed** (with reference to the library entry).
3. **State what you're now seeing** that doesn't fit.
4. **Ask one targeted question** — the smallest one that resolves it.

### Bilingual scaffold

```
┌─────────────────────────────────────────────┬─────────────────────────────────────────────┐
│ [user's language]                            │ [English]                                    │
├─────────────────────────────────────────────┼─────────────────────────────────────────────┤
│ ⚠️ 想跟你对一下 "<term>" 这个理解。           │ ⚠️ Quick alignment check on "<term>".        │
│                                              │                                              │
│ 我们之前对齐过:                              │ We previously aligned on:                    │
│ <prior aligned meaning, in user's language>  │ <prior aligned meaning, English>             │
│                                              │                                              │
│ 但你刚才说的 "<recent phrase>",              │ But your recent phrase "<recent phrase>"     │
│ 让我觉得可能不完全是同一件事。               │ suggests it may not be quite the same thing. │
│                                              │                                              │
│ 我想确认一下:                                │ I want to confirm:                           │
│ <one specific question>                      │ <one specific question>                      │
└─────────────────────────────────────────────┴─────────────────────────────────────────────┘
```

### Worked example

Context: turn 7, the marketing director just said "I want the design to be 简洁" (clean / simple). Library entry #1 already defined `简化品牌故事` (simplify the brand story) as "rewrite in plain language, preserving the founder origin section in full." But "简洁的设计" sounds adjacent and could collapse into #1 wrongly.

```
┌─────────────────────────────────────────────┬─────────────────────────────────────────────┐
│ ⚠️ 想跟你对一下 "简洁的设计" 这个理解。       │ ⚠️ Quick alignment check on "simple design". │
│                                              │                                              │
│ 我们之前对齐过 "简化品牌故事" 是指:           │ We previously aligned that "simplify the     │
│ 用平实的语言重写,                            │ brand story" meant: rewrite in plain         │
│ 但完整保留创始人故事那一段。                  │ language while preserving the founder        │
│                                              │ origin section in full.                      │
│ "简洁的设计" 可能是另一回事 ——               │ "Simple design" may be a different thing —   │
│ 是指视觉上的简洁 (留白、少元素),              │ visual minimalism (whitespace, few elements) │
│ 还是文案上的简洁?                            │ or copy minimalism?                          │
│                                              │                                              │
│ 你的意思更接近哪种?                          │ Which is closer to what you mean?            │
└─────────────────────────────────────────────┴─────────────────────────────────────────────┘
```

The user's response goes into a new library entry (entry #4 from the library example), confirmed.

### Severity variants

- **Gentle nudge** (drift is small, you're 70% sure of the right reading): drop the ⚠️, soften the framing — "Just to make sure I'm tracking — when you say X, do you mean…?"
- **Mid-course correction** (you've been acting on the wrong reading for several turns, work is going off-track): keep the ⚠️, add an explicit "I think I've been working from the wrong reading; let me pause and check before continuing." Don't soft-pedal — the cost of a fluent-sounding course-correction the user misses is high.

---

## Template 2: Memory Correction

**When to fire**: new information contradicts or refines an existing library entry. You need to mark the old entry `superseded` and add a new `confirmed` entry. The user needs to see what changed and agree to the revision before it goes live.

**Goal**: make the change explicit and reversible. The user should be able to say "no, actually keep the original" without friction.

### Structure

1. **Name the entry being revised** (with its number from the library).
2. **Show the old aligned meaning.**
3. **Show what changed** — quote the new evidence.
4. **Propose the new aligned meaning.**
5. **Ask for confirmation** — not assumed.

### Bilingual scaffold

```
┌─────────────────────────────────────────────┬─────────────────────────────────────────────┐
│ [user's language]                            │ [English]                                    │
├─────────────────────────────────────────────┼─────────────────────────────────────────────┤
│ 🔄 我想更新一下记录里 "<term>" 的理解。       │ 🔄 Proposing to update the entry for         │
│ (#<library number>)                          │ "<term>" (#<library number>).                │
│                                              │                                              │
│ 之前对齐的是:                                │ Previously aligned:                          │
│ <old aligned meaning, user's language>       │ <old aligned meaning, English>               │
│                                              │                                              │
│ 但你刚才说: "<new phrase>",                  │ But your recent phrase "<new phrase>"        │
│ 这让我想调整一下:                            │ suggests I should adjust this to:            │
│ <new aligned meaning, user's language>       │ <new aligned meaning, English>               │
│                                              │                                              │
│ 这样改对吗? 还是要保留原来的?                │ Does this revision look right, or should I   │
│                                              │ keep the original?                           │
└─────────────────────────────────────────────┴─────────────────────────────────────────────┘
```

### Worked example

Context: turn 9, the user said "actually, more 'understated authority' than 'luxury'." Library entry #2 (`高端`) needs updating.

```
┌─────────────────────────────────────────────┬─────────────────────────────────────────────┐
│ 🔄 我想更新一下记录里 "高端" 的理解。(#2)     │ 🔄 Proposing to update the entry for         │
│                                              │ "高端" (#2).                                 │
│                                              │                                              │
│ 之前对齐的是:                                │ Previously aligned:                          │
│ 视觉调性 — 低饱和度配色、留白、衬线字体,      │ Visual register — muted palette, generous   │
│ 避免金色或金属元素。                          │ whitespace, serif typography; avoid          │
│                                              │ gold/metallic.                               │
│                                              │                                              │
│ 你刚才说 "更像低调的权威感, 不是奢华感",      │ Your recent phrase "more understated         │
│ 我想把它调整成:                              │ authority than luxury" suggests I adjust to: │
│ 视觉调性 — 低饱和度配色、留白、衬线字体,      │ Visual register — muted palette, generous    │
│ 避免任何光泽感 (不只是金属感)。               │ whitespace, serif typography; avoid all      │
│                                              │ gloss (not just metallic).                   │
│                                              │                                              │
│ 这样改对吗? 还是要保留原来的?                │ Does this revision look right, or should I   │
│                                              │ keep the original?                           │
└─────────────────────────────────────────────┴─────────────────────────────────────────────┘
```

On confirmation, entry #2 is marked `superseded`, and entry #5 is added as `confirmed`. The old row stays in the library — do not delete it.

---

## Adapting to other languages

The Chinese examples above are illustrative. For other languages, the bilingual layout is the same; only the left column changes:

- **Right column is always English** — this is the durable anchor.
- **Left column matches the user's primary language** as identified in the cognitive profile.
- **If the user is bilingual and switches mid-conversation**, the left column should match whichever language they used for the term in question. The term itself appears in its original language in both columns (do not translate it in the English column — preserve the lookup key).

For right-to-left languages (Arabic, Hebrew), put the user's language on the right and English on the left. The principle — user's language adjacent to where their eye starts — is what matters, not the literal side.

## Anti-patterns

- **Firing too often.** If you send three alignment templates in five turns, the user will start nodding along to make them stop. Reserve for real moments.
- **Burying the question.** The single specific question should be the last thing in the template, easy to find and easy to answer.
- **Using the template to apologize.** "Sorry, I'm not sure I understood…" — no. The template is a tool, not a confession. The user wants the misalignment fixed, not your contrition.
- **Filling in both columns identically by translating word-for-word.** The point of bilingual is that each column reads naturally to its intended reader. A stiff translation in either column means a stiff template.
- **Skipping the confirmation step on Template 2.** "I'm updating entry #2 to mean…" — without asking — turns the library into your version of events instead of a shared artifact. Always ask, even when you're almost certain.
