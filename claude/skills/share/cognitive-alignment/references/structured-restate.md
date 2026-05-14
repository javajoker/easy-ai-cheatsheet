# Structured Restate — for high-stakes alignment moments

The natural restate (see `alignment-responses.md`) is the everyday tool. This file
covers two situations where a longer, more structured restate is worth the cost:

1. **Deviation Warning** — you suspect the current direction has drifted from a
   library entry that was previously confirmed.
2. **Memory Correction** — an existing library entry needs to be revised because
   new evidence contradicts or refines it.

Both still happen in the user's language. Neither is a side-by-side bilingual
scaffold — the cognitive library and profile already commit to "user's language
is canonical." The structure here is what makes the move legible to the user,
not a translation device.

## Principle: scaffold, not script

These are scaffolds. Fill in the slots, but rewrite the prose to fit the
conversation. The fastest way to make alignment feel like an interrogation is
to read these out verbatim every time.

Use them when:

- You need to surface a specific misalignment cleanly.
- You are at a checkpoint (pre-`/compact`, end of a working session, before
  producing a deliverable).
- The conversation has tangled and you need to reset to a shared base.

Do not use them:

- For minor word-choice questions — just ask.
- Every few turns ritualistically — alignment loses its weight when bureaucratic.
- When the user is mid-thought — wait for a natural pause.

---

## Deviation Warning

**When to fire** — you've detected possible drift from a previously confirmed
meaning. Either you caught yourself silently interpreting something, or something
the user just said does not fit an existing library entry, or a partial
deliverable is diverging from what was agreed.

**Goal** — surface the drift in one short, specific message. Make it cheap to
repair now.

### Structure

1. **Name the term.** One specific concept — not a vague "I'm not sure we're aligned."
2. **State what was agreed** — reference the library entity (e.g. `[T2]`).
3. **State what you are now seeing** that does not fit.
4. **Ask one targeted question** — the smallest one that resolves it.

### Worked example

The user just said *"I want the design to feel 简洁"* (clean / simple). Library
entry `[T1]` already defined `简化品牌故事` (simplify the brand story) as
*"rewrite in plain language, preserving the founder origin section in full."*
"简洁的设计" is adjacent and could be wrongly collapsed into `[T1]`.

> ⚠️ 想跟你对一下 "简洁的设计" 这个理解。
>
> 我们之前对齐过 `[T1] 简化品牌故事` 是指: 用平实的语言重写, 但完整保留创始人故事那一段。
>
> "简洁的设计" 可能是另一回事 —— 是指视觉上的简洁 (留白、少元素), 还是文案上的简洁?
>
> 你的意思更接近哪种?

When the user answers, a new entity `[T4] 简洁的设计` goes into the library with
`status: confirmed` and a `distinct-from: [T1]` relation. The relation is the
record that prevents future conflation.

### Severity variants

- **Gentle nudge** (drift is small, you are ~70% sure of the right reading) —
  drop the warning glyph, soften the framing: *"Just to make sure I'm tracking
  — when you say X, do you mean…?"*
- **Mid-course correction** (you have been acting on the wrong reading for
  several turns, work is going off-track) — keep the warning glyph, add an
  explicit *"I think I've been working from the wrong reading; let me pause
  and check before continuing."* Do not soft-pedal — a fluent-sounding
  course-correction the user misses is expensive.

---

## Memory Correction

**When to fire** — new information contradicts or refines an existing library
entry. You need to mark the old entity `superseded` and add a new `confirmed`
entity that supersedes it, linked by a `superseded-by` / `supersedes` relation.

**Goal** — make the change explicit and reversible. The user should be able to
say *"no, actually keep the original"* without friction.

### Structure

1. **Name the entity being revised** — with its ID from the library.
2. **Show the old aligned meaning.**
3. **Show what changed** — quote the new evidence.
4. **Propose the new aligned meaning.**
5. **Ask for confirmation** — never assumed.

### Worked example

Turn 9, the user said *"actually, more 'understated authority' than 'luxury'."*
Library entity `[T2] 高端` needs updating.

> 🔄 我想更新一下记录里 `[T2] 高端` 的理解。
>
> 之前对齐的是: 视觉调性 — 低饱和度配色、留白、衬线字体, 避免金色或金属元素。
>
> 你刚才说 "更像低调的权威感, 不是奢华感", 我想把它调整成: 视觉调性 — 低饱和度配色、留白、衬线字体, 避免任何光泽感 (不只是金属感)。
>
> 这样改对吗? 还是要保留原来的?

On confirmation: mark `[T2]` as `superseded`, add `[T5]` as `confirmed` with
relation `supersedes: [T2]`. The old entity stays in the library — do not
delete. Its existence is part of the record of how the alignment evolved.

---

## Rendering in other languages

The worked examples above use Chinese to make the structure concrete. The same
move in other languages:

- 日本語 — *"確認させてください。今おっしゃった「X」は、…ということでしょうか？"*
- Español — *"Déjame confirmar: cuando dijiste 'X', te referías a … ¿es así?"*
- العربية — *"اسمح لي أن أتحقق: عندما قلت «X»، هل تقصد …؟"*

What matters is that the structure (name the term → show prior → show new →
ask one question) survives the translation, not the literal phrasing.

For right-to-left languages the visual layout reverses naturally; do not paste
left-to-right scaffolds into RTL contexts.

---

## Anti-patterns

- **Firing too often.** Three structured restates in five turns and the user
  starts nodding along to make them stop. Reserve for real moments.
- **Burying the question.** The single specific question should be the last
  thing in the message, easy to find and easy to answer.
- **Apologizing inside the template.** *"Sorry, I'm not sure I understood…"* —
  no. The structured restate is a tool, not a confession. The user wants the
  misalignment fixed, not your contrition.
- **Skipping the confirmation step on Memory Correction.** *"I'm updating
  `[T2]` to mean …"* — without asking — turns the library into your version
  of events instead of a shared artifact. Always ask, even when you are almost
  certain.
- **Mistaking length for thoroughness.** A longer message is not a more careful
  one. The structured restate works because it is *one* term, *one* question,
  *one* exchange.
