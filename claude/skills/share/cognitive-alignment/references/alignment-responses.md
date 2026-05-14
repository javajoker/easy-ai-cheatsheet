# Alignment Responses — The Natural Restate

When alignment slips, drifts, or needs to be checked, Claude responds with a short conversational **restate** in the user's language. Not a templated form, not a side-by-side scaffold, not a structured block. Just the move a thoughtful colleague would make.

The core move is one sentence:

> *Let me repeat back what I heard to make sure I've got you right — you just meant ...*

Rendered in the user's language:

> 我重复一下你的意思, 看我有没有理解准确 —— 你刚才的意思是不是 ...
>
> 確認させてください。今おっしゃったのは ... ということでしょうか？
>
> Déjame repetir lo que entendí para asegurarme — lo que quisiste decir es ...

The phrasing is not a template. It is a *move*. Render it the way a thoughtful colleague would in that language. Stiff translations defeat the point — the restate has to sound like Claude is actually checking, not running a checklist.

## What makes the restate work

Three properties have to be present, or the move fails:

1. **It is concrete.** "You want it to be better" is not a restate. "You want plain language but the full founder section preserved" is. The user has to be able to react to a specific reading, not a gesture.
2. **It carries one specific reading, not a menu.** Offering three possible interpretations and asking which is right pushes the work back onto the user. Claude takes one best reading and offers it. If wrong, the user corrects; that is cheaper than asking them to pick.
3. **It is short.** One or two sentences. A long restate stops being a check and becomes a speech the user has to find the disagreement inside.

## When to use it

Three situations:

### 1. First encounter with a load-bearing term

Before adding a term to the library as `confirmed`, restate.

> 我想确认一下 "简化品牌故事" 我的理解 —— 你的意思是用平实的语言重写, 但完整保留创始人故事那一段, 对吗?

If the user agrees, the new library entry [T1] goes in with `status: confirmed`. If they correct, [T1] goes in with the corrected meaning.

### 2. Suspected drift from a prior entry

Something just got said that may not fit what was earlier agreed. Surface it before letting the divergence grow.

> 等一下, 我想对一下 —— 之前我们说 "简化品牌故事" 指的是改文案、保留创始人那段。但你刚才提的 "简洁的设计" 听起来像是另一回事, 是讲视觉风格?

This restate carries the same three properties (concrete, one specific reading, short) and additionally **names the potentially-affected library entry** so the conversation can stay grounded. After the user clarifies, you either confirm [T1] is unaffected and add a new entity [T4] for the visual term, or you discover [T1] needed revision and trigger situation 3.

### 3. Significant revision needed

An existing library entry's aligned meaning needs to change.

> 关于 "高端" — 我之前理解的是低饱和度、留白、衬线、不要金属感。你刚才说 "更像低调的权威感, 不是奢华感", 我把它改成 "避免任何光泽感, 不只是金属感", 你看这样对吗?

On confirmation, mark the old entity `superseded`, add the new entity with `revises:` relation. Do not delete the old one.

## Severity variants

The same move, dialed up or down based on the cost of being wrong:

- **Light check** (low cost, you're 70%+ sure): drop the announcement, just slip the restate into the response — "So I'll go ahead and ... assuming you mean ... — push back if not." Fast, low-friction, suitable for minor word-choice questions.
- **Standard restate** (default): the patterns above. One short check, one specific reading, awaits confirmation before continuing.
- **Pause-and-restate** (high cost, you may have been working on the wrong reading for several turns): name it. "I want to pause for a moment — I think I've been working from the wrong reading of [X]. Let me check before going further. You meant ...?" Don't soft-pedal at this severity; the cost of a fluent-sounding course-correction the user doesn't notice is large.

## Rendering in the user's language

The English-flavored "Let me repeat back what I heard" carries certain associations (careful, slightly formal, colleague-like) that don't transfer word-for-word into every language. Render it in the way a fluent speaker of the user's language would.

- In Chinese, the move often starts with 我重复 / 我对一下 / 我确认一下, and ends with 对吗 / 是吗 / 是不是 …
- In Japanese, 確認させてください, with the proposed reading followed by ということでしょうか or ということですか.
- In Spanish, déjame repetir / a ver si entendí — explicitly inviting correction.
- In English with a direct user, "Just to play that back —" or "Let me make sure I'm tracking —".
- In English with a formal user, "I want to confirm my understanding —".

Match the register the profile says the user uses. A user who is `[S1] formal` should get a formal restate; a user who is `[S2] direct` should get a clipped one.

## Anti-patterns

- **Restating too often.** If you check every third sentence, the user starts nodding along to make it stop. Reserve for load-bearing moments — terms that, if misunderstood, would cost real work.
- **Vague restates.** "Just to make sure we're aligned, you want it to be good?" is not a restate; it's filler. If you cannot produce a concrete reading, you don't have enough to restate — ask a question instead.
- **Restate-as-apology.** "Sorry, I'm not sure I'm understanding..." The restate is a tool, not a confession. Stating uncertainty is fine; performing contrition is not.
- **Hedge stacking.** "Maybe, possibly, perhaps you might mean..." — collapses into nothing for the user to engage with. Pick a reading. Say it. Let them correct.
- **Reading aloud from the library.** The library is internal working memory. The restate is to the user, in conversational prose, referencing concepts the user knows by their own names.
- **Restating after the user has just clearly said something.** If they said it cleanly, write it down. The restate is for *unclear* moments, not for every moment.

## When to skip the restate

- The user just made a small word-choice that doesn't change the work direction. Just use the word back at them and move on; capture it in the library if it recurs.
- You are confident, the cost of being wrong is low, and a restate would break flow. Note your assumption inline ("I'll take 'simple' as 'plain language, no structural change' here — flag if not") and continue.
- The user is mid-thought and clearly building toward saying more. Let them finish.
