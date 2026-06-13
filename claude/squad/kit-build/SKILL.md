---
name: kit-build
description: Package a framework skill or agent procedure into a member-portable task kit — the unit that lets the squad evaluate and dispatch *special tasks* (a specific skill's discipline) on different LLM products, not just coarse task classes. Extracts the source skill's load-bearing rules, strips harness assumptions (tools, INSTRUCTIONS, session context), defines a strict JSON wire contract (input payload / output delta), inlines minimal project bindings by value, sets acceptance criteria identical to the eval rubric, and calibrates the kit with an in-house cold dry-run before it ever rates a member. Output is kits/<kit-name>/KIT.md per the contract in kits/README.md. Use this skill when the user says "package <skill> for the squad", "build a kit for translation/test-gen/…", "can <member> run our <skill> discipline", "make this task portable to other models", or when eval-design / squad-route hit a task class that keeps routing but has no kit. Pairs with eval-design + eval-run (rate members against the kit, Scenario W), squad-dispatch (sends kit + hydrated payload as the whole prompt), squad-state (the delta schema the kit's output merges into), and skill-evolution/skill-merge (when the source skill moves, the kit re-derives).
---

# Kit Build

Turns *"is this member any good?"* into *"can this member execute our
skill, our way, to PASS?"* — by making the skill itself portable. The
kit is the squad layer's answer to evaluating **special tasks with an
LLM-compatible agent/skill**: the discipline travels; the harness stays
home.

## Procedure

### Phase 0 — Pick the source and qualify

- **Source:** a framework skill (SKILL.md), an agent phase (AGENT.md),
  or a project-specific procedure. If the user named a task class
  instead, pick the skill that owns that class's discipline (e.g.
  `translation` → the doc-standards + project-glossary discipline).
- **Qualify:** the task must be **cold-startable** (inputs expressible
  as a payload; no session context required) and within members'
  modality/tool reach (`tool_requirements: none` is the strong default —
  a kit needing file access excludes prompt-only members and must say
  so). A task failing this isn't kit-able; it stays in-house.

### Phase 1 — Extract the surviving discipline

Walk the source skill and keep only what changes the output:

- Procedure steps → **MUST** rules (imperative, checkable).
- Anti-patterns → **MUST NOT** rules.
- Companion-skill references, harness mechanics, and meta-commentary →
  **dropped** (members can't act on them; tokens are billed).

The test for every line: *if the member ignored this, would
`squad-verify` fail the output?* No → cut.

### Phase 2 — Define the wire contract

Per [`kits/README.md`](../kits/README.md): an **input payload** schema
(task + hydrated inputs + minimal `context` bindings inlined by value)
and an **output delta** schema (named keys for the ledger + a `notes`
field for member caveats). The schemas are what `squad-dispatch`
validates deterministically on return — make every field's type and
bounds explicit. Acceptance criteria are written now, in
`requirement-audit` row form: they will serve as **both** the eval
rubric (member × kit) and the production verify contract — one
contract, so eval results predict dispatch results.

### Phase 3 — Write KIT.md + worked example

Fill the template: frontmatter (source + version + task class +
modalities + tool requirements), role, rules, contract, criteria, and
**one worked example** (small payload → correct delta). The example is
the few-shot anchor and doubles as the smoke fixture.

### Phase 4 — Calibrate in-house

Execute the kit **cold** in-house: fresh context, kit + example payload
only, no repo access. If the home product can't produce a PASS delta,
the kit is underspecified — fix the kit, never blame the member it
hasn't met yet. On pass, stamp `calibrated: <date>` and register the kit
in the `kits/README.md` table.

### Phase 5 — Hand off to evaluation

Recommend the Scenario W eval for the members the user wants rated:
`eval-design` reuses the kit's criteria as rubric rows and the worked
example's shape for golden payloads; `eval-run` stamps
`evaluated: <kit-name>@<member-version>` and lands kit-level rows in
ROSTER.md.

## Anti-patterns

- **The SKILL.md dump.** Pasting the whole source skill into a kit
  ships harness instructions members can't follow and bills for them on
  every dispatch. Extract; don't copy.
- **Binding by reference.** "Per the project glossary" means nothing to
  a cold member. Inline the twenty terms that matter.
- **Criteria fork.** Eval rubric ≠ kit criteria means you measured one
  task and dispatch another. One contract.
- **Skipping calibration.** An uncalibrated kit that fails on a member
  tells you nothing — kit bug or member gap? The in-house dry-run is
  the control.
- **Silent kit drift.** Source skill evolved, kit didn't. Re-derive on
  source changes; if the contract or criteria changed, existing member
  ratings against the kit go `(stale)` via `member-retune` discipline.

## Companion skills

| When… | Use |
|---|---|
| Rating members against the kit | `eval-design` + `eval-run` (Scenario W) |
| Dispatching the kit in production | `squad-dispatch` (kit + payload = the whole prompt) |
| The delta the kit's output merges into | `squad-state` |
| The source skill evolved | `skill-evolution` / `skill-merge`, then re-derive here |
