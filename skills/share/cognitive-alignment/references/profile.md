# Cognitive Profile — Graph of the Person

The cognitive profile is a structured model of *how this user thinks, expresses, and comprehends*. It is the answer to: "what does it mean to align my expression to this specific person, not a generic one?"

Like the library, the profile is **a knowledge graph in the user's primary language**. Entities are dimensions of the user; relations connect dimensions to each other and to entries in the library.

The profile is **observation-based, not interview-based**. Every entity traces to actual conversational evidence — a turn number, a quote, an observed reaction. You are not interviewing the user. You are watching them, and writing down what you see.

## Why the profile matters

The library answers *what specific words mean*. The profile answers *how to use those words*. Two users can have nearly identical libraries and still need entirely different responses — one wants the principle first and one wants the example first, one wants the bottom line and one wants the reasoning, one reads a second language fluently and one is translating in their head.

The highest-leverage single dimension is the **expression-comprehension gap**: the asymmetry between how a person speaks and how a person understands. Most users have one. Tracking it is what separates real alignment from surface mimicry.

## Schema

The profile graph has entity types for each dimension, evidence on every entity, and relations between entities (and out to the library).

### Entity prefixes (suggested)

```
[L<n>] Language & translation pattern
[E<n>] Domain expertise
[S<n>] Linguistic style
[K<n>] Comprehension pattern (K for "知" / "knowing")
[G<n>] Expression-comprehension gap
[F<n>] Feedback signal
[X<n>] Constraint / avoid
```

Use whatever prefix scheme makes sense for the language. The point is that entities have stable IDs you can refer to in relations.

### Standard fields

```
[<id>] <short label>
  <key>: <value>
  evidence: turn <n> ("<short quote>" or "<observed pattern>")
  confidence: high | provisional | low
  rel: <relations>
```

### Relation types

- `ties-to: [<id>]` — connects related entities (e.g., a constraint to a feedback signal that caused it).
- `implication-for: [T<n>]` — out-going relation pointing into a library entry. *This is the most important relation type in the profile.* It tells Claude how to handle a specific library term differently because of a profile trait.
- `revises: [<id>]` — when a profile entry replaces an earlier reading.
- `exception-to: [<id>]` — when a general rule has a specific exception.

## Worked example

Mid-conversation profile of the same Chinese-speaking marketing director from the library example. Shown at turn ~11.

```
<cognitive_profile>

# Language & translation pattern
[L1] 主语言: 普通话
  evidence: 全程使用中文
  confidence: high

[L2] 工作语言能力: 阅读英文流畅, 写作有限
  evidence: turn 5 引用了英文行业报告; turn 9 中英混用
  confidence: high

[L3] 切换到英文的触发: 谈到可量化结果或国际参照
  evidence: turn 4 "tier-1 city", turn 9 "understated authority"
  confidence: provisional

[L4] 只用中文能表达的概念: "高端" (该词在英文里无单一对应)
  evidence: turn 4, 9 — 反复在不同英文词之间摇摆
  confidence: high
  rel:
    implication-for: [T2], [T5]

# Domain expertise
[E1] 品牌策略, 中国消费者营销 — expert
  evidence: turn 2, 5, 11
  confidence: high

[E2] 视觉设计词汇 — intermediate
  evidence: turn 4 知道想要什么, 但倾向于用范例而非术语
  confidence: provisional

[E3] 字体排印 — novice
  evidence: turn 8 ("用 serif"; 但后续问题显示对 serif 的理解约等于"不是 sans-serif")
  confidence: provisional (单一数据点)
  rel:
    ties-to: [G1]

# Linguistic style
[S1] 正式度: 偏正式, 谈到具体事时口语化
  evidence: 开头用 "您", 之后转为 "你"
  confidence: high

[S2] 直接度: 目标上直接, 反馈上间接
  evidence: turn 6 "或许可以换个角度" = "这样不对, 重做"
  confidence: high
  rel:
    ties-to: [F2]

[S3] 她产出的句子长度: 中等
[S4] 她最容易吸收的句子长度: 短句, 配一个具体例子
  evidence: turn 4, 6, 8 — 长解释她会回到第一句话问
  confidence: high

[S5] 适用的比喻类型: 服装/面料 ("质感", "重量")
  evidence: turn 5 主动用了"质感"
  confidence: provisional

[S6] 不适用的比喻类型: 汽车 ("引擎盖下面...")
  evidence: turn 7 反应冷淡, 之后没接话
  confidence: provisional
  rel:
    ties-to: [X1]

# Comprehension patterns
[K1] 接收新信息: 先例后理 (例子先, 然后是原则)
  evidence: turn 2, 6
  confidence: high

[K2] 倾向: 具体 over 抽象
  evidence: 反复要求 "举个例子"
  confidence: high

[K3] 视觉辅助: 主动要求, 非常欢迎
  evidence: turn 6 "你能不能做一个图给我看?"
  confidence: high

[K4] 顺序偏好: 先看过程, 再看结论 (不要 bottom-line first)
  evidence: turn 3, 11 — 直接给结论时她会问 "等一下, 你怎么得出这个的?"
  confidence: high
  rel:
    ties-to: [X2]

# Expression-Comprehension Gap — 关键对齐风险
[G1] 词汇 > 理解: 字体排印术语
  evidence: turn 8 自信使用 "serif", 但后续显示理解模糊
  confidence: provisional
  implication: 当她使用这些术语时, 顺势在回答里插入定义, 但不要做正式定义 (会显得居高临下 — 见 [X3])
  rel:
    implication-for: 任何 [C3] 下涉及字体的 term

[G2] 理解 > 词汇: 视觉美学
  evidence: turn 4, 9 — 能精准判断 (反复修正 [T2]→[T5]), 但只能通过类比和参照品牌表达
  confidence: high
  implication: 信任她的判断, 即使表达不精确; Claude 负责把她的类比翻译成具体规范
  rel:
    implication-for: [T2], [T5]

# Feedback signals (how to read her)
[F1] 困惑的样子: 长停顿后用问题重述我刚说的话
  evidence: turn 3 "所以你的意思是 — 把整个故事改掉?" (我没说过)
  confidence: provisional

[F2] 反对的样子: "也许...", "或者我们..."
  evidence: turn 6, 10
  confidence: high
  rel:
    ties-to: [S2]

[F3] 满意的样子: 主动给出自己的同类例子
  evidence: turn 5 (举了另一个品牌), turn 9
  confidence: high

[F4] 礼貌不接受的样子: "好的, 然后..." 后立即换话题
  evidence: turn 3
  confidence: provisional

# Constraints (things to avoid)
[X1] 避免汽车类比喻
  evidence: turn 7
  rel:
    ties-to: [S6]

[X2] 不要先给结论, 先展示推理过程
  evidence: turn 3, 11
  rel:
    ties-to: [K4]

[X3] 不要过度定义她流利使用的词
  evidence: turn 5 反应: "我知道什么是 persona"
  exception-to: [X3] when 字体排印术语 (见 [G1])

</cognitive_profile>
```

Notes on this example:

- **[G1] is provisional but already firing implications.** With one data point, the entity is correctly marked low-confidence — but the implication is concrete enough to act on. If the next data point contradicts it, [G1] gets revised; until then, it shapes how Claude handles typography terms in the library.
- **The relation `[G2] implication-for: [T2], [T5]` is the bridge.** Profile entry [G2] says "trust her aesthetic judgment, translate into specifics yourself." The two library entries [T2] and [T5] are where that plays out — the user gave fuzzy aesthetic input and Claude rendered concrete style rules. The relation makes that link explicit and survives `/compact`.
- **[X3] has an exception, also written as a relation.** Real rules have exceptions; the graph holds them rather than forcing the rule to be either rigid or vague.

## Sources of evidence, ranked by reliability

1. **What they corrected.** Strongest signal. Pushback on a word, a framing, or a tone is gold.
2. **What they elaborated on unprompted.** Tells you what they consider important and how they naturally explain.
3. **What they ignored.** Reliably indicates lack of resonance (though not always lack of comprehension).
4. **How they asked questions.** Question shape reveals comprehension structure better than question content.
5. **Direct statements about themselves.** Useful but discount slightly — self-models are not always accurate, especially about how one best learns.

**Not evidence:** "okay," "got it," "go on," or any minimal acknowledgment. Conversational lubricant, not data. Treating it as confirmation is a primary failure mode.

## Update discipline

- **Every entity needs evidence.** Without it, the entry is your assumption, not the user.
- **Revise, do not delete.** Use the `revises:` relation. Repeated revisions to the same dimension are themselves a signal.
- **Mark confidence honestly.** One data point is `provisional`. Claiming `high` on one data point is worse than `provisional` on five.
- **Profile *this* user, not a category.** "Detail-oriented user, type B" is a stereotype, not a profile. Stay specific.
- **Let it grow.** A profile written confidently in turn 2 is mostly a profile of your assumptions.

## Using the profile

The profile is reference material for Claude. You don't read it aloud and you don't quote from it. You consult it before responding, and you let it shape:

- Which examples you reach for.
- Whether you lead with principle or case.
- How long your sentences run.
- Which library terms you take extra care to define inline (and which you must *not* define).
- How you interpret the user's next message — their "好的" probably means X based on the profile, not Y.

The `implication-for: [T<n>]` relations are where the profile and library connect. When you're about to use a library term, check whether any profile entity has an outgoing implication into that term. If yes, that's a constraint on how you use it.

## Privacy note

If the profile is going to persist across sessions or be reused for "AI alignment use" more broadly, it is a privacy-sensitive artifact about a specific person. Storage, retention, and consent should be handled accordingly. The graph format makes export easy; that's a feature, but it's also a responsibility.
