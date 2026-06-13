# kits — framework skills packaged for external members

A **kit** is a framework skill or agent procedure re-packaged so an
external LLM product can execute it cold: the skill's load-bearing
discipline condensed into a self-contained brief with a strict JSON wire
contract. Kits are what make the evaluation question precise — not *"is
gemini-cli good?"* nor even *"can it translate?"* but **"can this member
execute `kit-translation-docs` — our translation skill, our glossary
discipline, our output contract — to PASS?"**

`kit-build` creates them; `eval-run` rates members against them
(kit-level rows in [`../ROSTER.md`](../ROSTER.md)); `squad-route`
prefers a kit rating over the coarse task-class rating; and
`squad-dispatch` sends the kit brief + a hydrated payload as the entire
prompt — the member needs nothing else, because a kit that needs
anything else is not done.

## Why kits exist

A framework SKILL.md assumes the Claude Code harness: tools, always-on
INSTRUCTIONS, session context, companion skills. Members have none of
that — they start cold, often tool-poor, and bill by the token. Sending
a member the raw SKILL.md wastes its context on harness instructions it
can't follow; sending it nothing reduces "evaluation" to vibes. The kit
is the deliberate middle: **the discipline survives, the harness
assumptions are stripped, and the I/O becomes a checkable contract.**

## The KIT.md template

One folder per kit: `kits/<kit-name>/KIT.md` (+ optional `fixtures/`).

```markdown
---
name: kit-<task-class>-<variant>      # e.g. kit-translation-docs
source_skill: <framework skill/agent it derives from, with path>
source_version: <that skill's version/state when derived>
task_class: <roster task class it maps to>
modalities: [text]                    # input/output modalities the kit needs
tool_requirements: none | <explicit>  # what the member must be able to DO (most kits: none)
calibrated: <date in-house dry-run passed — a kit Claude can't execute cold is not portable>
---

# <Kit name>

## Role and objective
One paragraph. Who the member "is" for this task and what done means.

## Rules (the surviving discipline)
MUST / MUST NOT lines distilled from the source skill's procedure and
anti-patterns. Each rule earns its tokens — if violating it wouldn't
fail acceptance, cut it.

## Wire contract
### Input payload (JSON schema)
{ "task": …, "inputs": { <hydrated state keys / inlined content> },
  "context": { <minimal project bindings: glossary, conventions — by value, not by reference> } }
### Output delta (JSON schema)
{ "outputs": { <named keys the ledger will merge> },
  "notes": "<member's caveats — surfaced to verify, never auto-trusted>",
  "confidence": <optional 0–1 self-report — a SIGNAL for squad-verify:
                 may only deepen verify when low, never lighten it when
                 high; never a pass> }

## Acceptance criteria
The PASS/PARTIAL/FAIL rows squad-verify will apply — identical to the
eval rubric rows, so eval performance predicts production performance.
Include the **style/normalization** rows: house voice, heading shape,
terminology, formatting conventions. Heterogeneous members diverge in
style by default; the kit is where that divergence is normalized — at
author time, as checkable criteria — so the repo doesn't drift into N
voices (the consistency concern). A correct-but-off-voice return is a
PARTIAL, not a silent accept.

## Worked example
One small input payload → one correct output delta. (Few-shot anchor;
also the smoke fixture.)
```

## Disciplines

- **Calibrate in-house first.** Before a kit rates anyone, Claude
  executes it cold (fresh context, kit + payload only). If the home
  product can't follow it, the kit is underspecified — fix the kit, not
  the member. The dry-run date lands in `calibrated:`.
- **Bind by value.** Members can't read your repo. Project bindings the
  kit needs (glossary terms, conventions) are inlined into the payload's
  `context` — small and allowlisted, per `squad-dispatch` rules.
- **Track the source.** `source_skill` + `source_version` make kit drift
  visible: when the source skill evolves (Scenario L) or gets
  version-tuned (Scenario U), re-derive the kit and re-stamp; member
  ratings against the old kit go `(stale)` only if the contract or
  criteria changed.
- **One contract for eval and production.** The kit's acceptance
  criteria ARE the eval rubric rows for member × kit. Anything else
  measures a different task than the one you'll dispatch.

## Shipped kits

| Kit | Source skill | Task class | Status |
|---|---|---|---|
| *(none yet — run `kit-build` on the skills you most want to route; the translation example in* [`../EXAMPLES.md`](../EXAMPLES.md) *is the natural first)* | | | |
