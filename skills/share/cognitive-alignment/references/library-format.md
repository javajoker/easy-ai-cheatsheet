# Cognitive Library — Graph Format & Examples

The cognitive library is a per-conversation knowledge graph of mutually confirmed terms. It lives in a `<cognitive_library>…</cognitive_library>` block in Claude's working context. It is the durable substrate for alignment — what carries across turns and survives `/compact`.

All data captured in the library is in **the user's primary language**. No parallel translation. The user's word is the canonical key; the user's framing is the canonical reading.

## Why a graph instead of a list

A flat list of "term → meaning" can hold definitions, but it can't hold:
- Two terms that sound similar but mean different things ("don't conflate these").
- A term whose meaning depends on which sub-context the user is in.
- The history of a term that's been revised over the course of the conversation.
- The fact that one term *preserves* or *applies to* a specific entity.

These relationships are where the real alignment value lives. The graph form makes them explicit and queryable.

## Schema

The graph has three kinds of entities and a small set of relation types.

### Entities

```
[C<n>] <context name>                       — a context node (project, sub-area, topic)
[T<n>] "<exact user phrasing>"              — a term node
[X<n>] <named entity>                       — a referent (a section, a persona, a section name, etc.)
```

### Term entity properties

```
[T<n>] "<exact user phrasing in user's language>"
  context: [C<n>], [C<m>]                   — which contexts this term lives in
  user_means: "<user's own description>"    — paraphrased minimally, in their framing
  aligned: "<working definition>"           — what both sides confirmed, in user's language
  evidence: turn <n> ("<short quote>")      — traceable to a specific moment
  status: confirmed | tentative | superseded
  rel: <relations to other entities>
```

### Relation types

- `distinct-from: [T<n>]` — explicitly not the same as another term, even if it looks similar.
- `supersedes: [T<n>]` / `superseded-by: [T<n>]` — revision history. Both sides of the relation are kept.
- `revises: [T<n>]` — a softer form of supersession (refinement, not replacement).
- `preserves: [X<n>]` — the term carries an obligation to preserve a specific entity.
- `applies-to: [X<n>]` / `does-not-apply-to: [X<n>]` — scope of the term.
- `narrower-than: [T<n>]` / `broader-than: [T<n>]` — hierarchical relation between related terms.

You can add ad-hoc relation types as needed (`triggers:`, `requires:`, etc.). Keep them named consistently across the conversation.

### Status lifecycle

```
(new term observed) → tentative → confirmed → superseded
                          ↓             ↓
                  (discarded if    (replaced by a new
                   never confirmed) confirmed entry,
                                    old row kept)
```

A `tentative` that's been sitting unconfirmed for several turns is a signal that you haven't actually checked. Either run a natural restate to confirm, or discard. Silent tentatives are how drift starts.

## Worked example

A consulting engagement where the user is a Chinese-speaking marketing director working through a brand refresh. The library is shown at turn ~10.

```
<cognitive_library>

# Contexts
[C1] 品牌焕新项目
[C2] 文案工作 (in C1)
[C3] 视觉工作 (in C1)
[C4] 目标受众工作 (in C1)

# Referents
[X1] 创始人故事章节
[X2] 主要目标用户画像

# Terms
[T1] "简化品牌故事"
  context: [C2]
  user_means: "去掉企业话, 保留创始人叙事"
  aligned: "用平实的语言重写品牌故事, 完整保留创始人故事章节"
  evidence: turn 2 ("能不能把品牌故事简化一下")
  status: confirmed
  rel:
    distinct-from: [T4]
    preserves: [X1]

[T2] "高端"
  context: [C3]
  user_means: "看起来贵但不张扬 —— 安静的奢华"
  aligned: "视觉调性: 低饱和度配色、留白、衬线字体, 避免金色或金属元素"
  evidence: turn 4
  status: superseded
  rel:
    superseded-by: [T5]

[T3] "目标客户"
  context: [C4]
  user_means: "30-45 岁, 一线城市, 双职工家庭, 孩子读私立"
  aligned: "主要画像: 城市专业人士, 家庭收入前 10%, 学龄儿童"
  evidence: turn 5
  status: confirmed
  rel:
    defines: [X2]

[T4] "简洁的设计"
  context: [C3]
  user_means: (pending — 还没具体描述)
  aligned: (pending)
  evidence: turn 7 ("我想要简洁的设计")
  status: tentative
  rel:
    distinct-from: [T1]
    note: 两个词里都有"简", 但作用于不同环节 (文案 vs 视觉) — 不要合并

[T5] "高端" (revised)
  context: [C3]
  user_means: "更像低调的权威感, 不是奢华感"
  aligned: "视觉调性: 低饱和度配色、留白、衬线字体, 避免任何光泽感 (不限于金属感)"
  evidence: turn 9 ("更像 understated authority, 不是 luxury")
  status: confirmed
  rel:
    revises: [T2]

</cognitive_library>
```

Notes on this example:
- **[T4] is tentative, not collapsed into [T1].** Both phrases contain "简"; both gesture at "simpler." But the user said two different things at two different moments, about two different things (copy vs. design). The graph holds them as separate entities related by `distinct-from`. The `note` field is reminder-for-Claude: do not collapse these even if it feels intuitive.
- **[T5] revises [T2], not replaces it from history.** [T2] stays in the graph, marked `superseded`. The audit trail is what tells you, after `/compact`, that "high-end" had a meaning shift around turn 9 — a fact that may matter again when reviewing earlier work.
- **Contexts are first-class.** [T1] lives in [C2] (copy); [T2] and [T5] live in [C3] (visual). If the user had used "简化" in [C3] later, that would be yet another entity, not a fold-in of [T1].

## What belongs in the library

Load-bearing terms only. A term belongs if **misunderstanding it would make work go in a meaningfully wrong direction**.

Good candidates:
- Domain terms with a non-obvious specific meaning to this user.
- Words the user keeps reaching for (a sign the concept matters to them).
- Names that map to ambiguous referents — needs a `defines:` or `applies-to:` relation.
- Verbs hiding a process decision ("clean up the data" — which kind of cleanup?).

## What does not belong

- Generic vocabulary with no domain-specific reading.
- Words you understood fine and the user used in a standard way.
- Your own jargon you used and the user accepted without engaging — that's not alignment, that's the user being polite. If you want it in the library, run a restate first.
- Anything the user has not engaged with. Without engagement, the entry is at most `tentative`.

## Anti-patterns

- **Over-stuffing.** A 30-entity library is noise. `/compact` will compress it anyway. Be ruthless about the load-bearing test.
- **Translating the user's phrasing.** The user's word is the canonical lookup key. Translating it defeats the purpose and makes it un-quotable back to them.
- **Silent confirmation.** Marking `confirmed` because the user said "okay" or "go on." Acknowledgment is not confirmation. Confirmation is when they say something specific about *what you said*.
- **Deleting superseded rows.** They are the audit trail. If the same term keeps getting superseded, that's also a profile signal — the user is still working out what they mean.
- **Skipping relations.** A term entity with no relations is half an entity. If two terms could be confused, write the `distinct-from`. If a term preserves something, write the `preserves`. The relations are why this is a graph.
- **Using the library as a leash.** Once you have an aligned meaning, you act on it — you don't quote the graph at the user every turn. The library is *your* working memory; surface it explicitly only at checkpoints (pre-compact, when drift is detected, when the user asks).
