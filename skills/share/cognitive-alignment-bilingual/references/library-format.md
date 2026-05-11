# Cognitive Library — Format & Examples

The cognitive library is a per-conversation record of mutually confirmed concepts. It lives in a `<cognitive_library>…</cognitive_library>` block in Claude's working context. It is the durable substrate for alignment — what carries across turns and survives `/compact`.

## Schema

```
<cognitive_library>
| # | Term (user's wording) | User's meaning           | Aligned meaning              | Status     | Turn |
|---|----------------------|--------------------------|------------------------------|------------|------|
| 1 | <verbatim phrase>    | <user's own description> | <English working definition> | confirmed  | 3    |
</cognitive_library>
```

### Field semantics

- **#** — sequence number. Never reused. If an entry is superseded, the new entry gets a new number; the old row stays.
- **Term (user's wording)** — the exact phrase the user used, in their native language, untranslated. Do not normalize or translate this field. The whole point is that *their* word is the lookup key.
- **User's meaning** — how the user described what they meant, paraphrased minimally and in their framing. Not your interpretation. If they haven't described it yet, leave blank and mark the row `tentative`.
- **Aligned meaning** — the working definition that both sides confirmed, written in English. This is what Claude acts on. Keep it operational: "rewrite for readability without removing sections or data" beats "make it simpler."
- **Status** — one of:
  - `tentative` — Claude inferred this; the user has not explicitly confirmed.
  - `confirmed` — both sides explicitly agreed on the aligned meaning.
  - `superseded` — replaced by a later entry. Keep the row; do not delete. The history matters for `/compact` recovery and for catching repeated drift.
- **Turn** — approximate turn number of confirmation. Used for traceability after compaction.

### Status lifecycle

```
(new term) → tentative → confirmed → superseded
                ↓             ↓
            (discarded if   (replaced by a new
             never confirmed) confirmed entry)
```

A `tentative` entry that's been sitting for several turns without confirmation is a signal that you haven't actually checked. Either check it or discard it — silent tentatives are how drift starts.

## Worked example

A consulting engagement where the user is a Chinese-speaking marketing director, working through a brand refresh:

```
<cognitive_library>
| # | Term (user's wording) | User's meaning                                          | Aligned meaning                                                                            | Status     | Turn |
|---|----------------------|---------------------------------------------------------|--------------------------------------------------------------------------------------------|------------|------|
| 1 | 简化品牌故事         | "Cut the corporate language, keep the founder narrative" | Rewrite the brand story in plain language, preserving the founder origin section in full   | confirmed  | 2    |
| 2 | 高端                 | "Looks expensive but not flashy — quiet luxury"          | Visual register: muted palette, generous whitespace, serif typography; avoid gold/metallic | confirmed  | 4    |
| 3 | 目标客户             | "30-45, tier-1 city, dual income, kids in private school"| Primary persona: urban professional, household income top 10%, school-age children          | confirmed  | 5    |
| 4 | 简洁的设计           | (not yet described)                                      | (pending — possibly distinct from #1's "simplify"; do not assume)                          | tentative  | 7    |
| 5 | 高端                 | "Actually, more 'understated authority' than 'luxury'"   | Visual register: muted palette, generous whitespace, serif typography; avoid all gloss     | confirmed  | 9    |
| 2 | 高端 (superseded by #5) | —                                                    | —                                                                                          | superseded | —    |
</cognitive_library>
```

Notes on this example:
- Entry #4 is a `tentative` for a *different* term (`简洁的设计` = "clean design") that surfaced in turn 7 without being defined. It does not collapse into #1 (`简化品牌故事` = "simplify brand story") even though both involve "simple-ish" ideas — *the user said two different things*, and conflating them is exactly the kind of silent interpretation alignment is meant to prevent.
- Entry #5 supersedes #2. Entry #2's row is kept and re-marked. The aligned meaning of #2 was *close* to right but missed "all gloss" — small refinements like this are what make the library a real working artifact rather than a vanity glossary.

## What belongs in the library

Load-bearing terms only. A term belongs in the library if **misunderstanding it would make work go in a meaningfully wrong direction**. That's the test. A library with 4 well-confirmed load-bearing entries is far better than one with 40 trivially-defined ones.

Good candidates:
- Domain terms with a non-obvious specific meaning to this user ("simple," "high-end," "the report").
- Names that map to ambiguous referents ("the team" — which one?).
- Verbs hiding a process decision ("clean up the data" — which kind of cleanup?).
- Adjectives the user keeps using ("modern," "professional," "tight").

## What doesn't belong

- Generic vocabulary with no domain-specific reading. ("Email" usually doesn't need an entry.)
- Words you understood fine and the user used in a standard way.
- Your own jargon you used and the user accepted — that's not alignment, that's the user being polite. If you want it in the library, *check first*.
- Anything the user has not engaged with. If they haven't reacted to your definition, it is at most `tentative`.

## Anti-patterns

- **Over-stuffing.** A 30-entry library is noise; the user can't scan it, you can't reason over it, and `/compact` will compress it away anyway. Be ruthless about the load-bearing test.
- **Translating the Term field.** Defeats the purpose. The user's word is the lookup key precisely so you can quote it back to them and they recognize it.
- **Silent confirmation.** Marking `confirmed` when the user only said "okay" or "go on." Acknowledgment is not confirmation. Confirmation is when they say something specific about *what you said*.
- **Deleting superseded rows.** They're the audit trail. If the same term keeps getting superseded, that's a profile signal — the user is still working out what they mean.
- **Using the library as a leash.** Once you have an aligned meaning, you act on it — you don't quote the table at the user every turn. The library is *your* working memory; surface it explicitly only at checkpoints (pre-compact, when drift is detected, when the user asks).
