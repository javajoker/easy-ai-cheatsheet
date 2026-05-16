---
name: skill-orchestrator
description: Picks the right combination of skills for a user request, chains them into a workflow, and asks for all required inputs upfront in one consolidated prompt before executing. Trigger this whenever the user describes a multi-step task that likely needs more than one skill chained together (examples - "read this PDF and make a presentation", "build me a full SaaS app for X", "extract data from this xlsx and write a report", "turn these meeting notes into a project plan"), or any time the request implicitly spans content extraction plus generation, project scaffolding, document conversion, or a pipeline of operations. Also trigger when the user explicitly asks "what skills should I use", "which skill fits", "how do I combine skills", "help me choose a workflow", or anything similar. Always trigger BEFORE invoking any single downstream skill if the request could plausibly need more than one - it is much cheaper to plan and consolidate input questions upfront than to ask the user piecemeal mid-workflow.
---

# Skill Orchestrator

A meta-skill that reads the available skill catalog, picks the right chain for the user's request, gathers all required inputs in a single consolidated prompt, then executes the workflow end-to-end.

This skill is one of eight in the `share/` family that hold a Claude Code session together:

- `skill-orchestrator` (this) — picks the chain.
- `cognitive-alignment` — keeps shared meaning straight during the chain.
- `memory-ontology` — promotes durable facts to MEMORY so the next session does not start from zero.
- `compact-ritual` — protects all of the above when `/compact` runs.
- `scenario-checklist` — produces the "Skills involved" checklist for a workflow before execution.
- `requirement-audit` — verifies the workflow's deliverables against the user's original asks after execution.
- `skill-evolution` — captures evolution candidates noticed during live use as reviewable proposals.
- `skill-merge` — applies accepted proposals into canonical skills with conflict detection and downstream consistency checks.

The orchestrator's job is to *plan and execute* the workflow. The other seven skills are not steps in the workflow itself — they run alongside it and ensure the workflow's plan, output, durability, recoverability, and the framework's own continued improvement are all sound.

## Why this exists

When a user says "build me a habit-tracking app" or "summarize this PDF as a slide deck", the right answer is almost never one skill — it's two to five skills chained together. Without orchestration, three failure modes recur:

1. **Wrong skill fires.** The closest single match triggers, but the workflow is missing an upstream extraction step or a downstream packaging step. The deliverable is half-finished and the user has to ask again.
2. **Death by a thousand questions.** Each skill asks for its inputs as it needs them, so the user gets pinged every two minutes for the next missing piece. Worse than a single up-front intake.
3. **Skipped reasoning.** Claude jumps to executing without first checking whether the planned chain actually serves the user's goal.

This skill solves all three by planning first and consolidating input collection.

## The four-phase loop

When this skill triggers, run these four phases in order. Do not skip phase 3.

Throughout all four phases, keep the three companion skills active in the background:

- **Cognitive alignment** — every time a load-bearing term is introduced or re-introduced, run the alignment check (see `cognitive-alignment`). The library and profile blocks should remain visible at the top of working state.
- **Memory ontology** — when a fact surfaces that should survive the next `/compact`, write it to the MEMORY ontology immediately rather than waiting for the end of the workflow (see `memory-ontology`).
- **Compact ritual** — if context pressure builds during a long workflow, run the pre-compact ritual proactively before continuing (see `compact-ritual`). Do not let a workflow finish with the artifacts in a fragile state.

If a workflow runs to completion without any of these companion skills firing, that is a signal — most multi-skill workflows touch at least one load-bearing term and at least one durable fact.

### Phase 1 — Read the catalog (skills AND agents)

The available skills are listed in the system prompt under `<available_skills>`. Each entry has a name, a description, and a SKILL.md path. Before planning anything, scan that list and identify every skill whose description plausibly relates to the user's request.

**Then check `agents/CHECKLIST.md` for shipped agents.** Agents are named roles that bundle a workflow + skills + deliverables for a specific job. When an agent's `fires_on` triggers match the request, **prefer the agent over re-planning the chain from skills** — the agent's workflow is a tested, named chain that survives sessions.

Two rules:

- **Read descriptions, not just names.** `pdf` is for *creating/manipulating* PDFs; `pdf-reading` is for *reading* them. A skill's name often understates what it does.
- **If relevance is unclear, view the SKILL.md.** A two-line description hides nuance. Spend the tool call to confirm before including or excluding a borderline skill.

Also check whether the system prompt has any user-loaded skills (often under `/mnt/skills/user/`) — these are usually more specific to the user's domain and should be preferred over public ones when both could apply.

### Phase 1b — Agent preference (when applicable)

Agents live under `agents/<name>/AGENT.md`. The current catalogue is in `agents/CHECKLIST.md` (read it fresh; don't hardcode).

Decision flow for whether to engage an agent:

1. Does the request's intent match any agent's `fires_on` triggers? (Read the agent's AGENT.md frontmatter; the `fires_on` list is the matching surface.)
2. If exactly one agent matches → invoke that agent by name; its workflow is the plan.
3. If multiple agents match → engage `scenario-strategist`; it forms a group via `agent-group-formation`.
4. If no agent matches → fall back to skill-level orchestration (Phases 2–4 below).

Single-agent invocation looks like: *"This matches the lifecycle-pilot agent — its workflow is X phases; here's the consolidated intake."* The agent's AGENT.md is the workflow definition; this orchestrator's job is to surface inputs upfront so the agent doesn't ping the user mid-phase.

When invoking by agent, the consolidated intake (Phase 3) covers inputs needed across the *whole agent arc*, not just the first phase.

### Phase 2 — Plan the workflow

With the candidate skills selected, sketch the workflow as an ordered list. Each step has:

- **Skill name** (or "native tool" if no skill is needed for that step)
- **Purpose** in plain language ("extract text from the uploaded PDF")
- **Inputs needed** (files, parameters, decisions)
- **Output** that feeds the next step

Most workflows fall into one of these shapes — use them as starting points, not straitjackets. See `references/workflow-patterns.md` for fleshed-out examples.

- **Extract → Transform → Produce**: read input file → restructure content → generate output file
- **Idea → Spec → Build**: concept → prototype → docs → task breakdown → frontend + backend
- **Single deliverable with prep**: gather decisions → produce one artifact
- **Skill about a skill**: when the user is building or improving a skill itself

If the workflow runs longer than ~5 skills, pause and reconsider — you are probably overcomplicating it. Trim aggressively.

### Phase 3 — Generate the input hint, ask once

This is the most important phase, and the one most likely to be skipped under time pressure. Don't skip it.

Look at the planned workflow and enumerate everything the user must provide for the *entire chain* to succeed:

- **File inputs** — which uploads are needed? Are they already attached?
- **Choices** — language stack, output format, audience, length, tone, style
- **Scope decisions** — how many pages/slides/screens, which sections, which roles
- **Names/identifiers** — project name, recipient, title, locale

Then present a single consolidated intake. Three rules:

- **Use interactive question tools when available.** In environments with `ask_user_input_v0` or equivalent, tappable options beat typing every time. Cap at 3 questions — if you need more than 3, you are asking about things the user hasn't decided yet and you should help them decide instead.
- **Don't re-ask what's obvious.** If the user already uploaded a PDF, don't ask "do you have a PDF". State it back as a confirmed assumption: "Using the PDF you uploaded — `report.pdf`." This respects their time.
- **Show the plan alongside the questions.** A short bullet list of the planned steps. The user can spot a mis-planned workflow far better than they can spot a missing question.

If the workflow has *prohibitive* prerequisites the user hasn't satisfied — they asked to edit a PDF but haven't uploaded one — flag those clearly so they can attach what's missing in their reply.

### Phase 4 — Execute, narrate, hand off

After the user's confirmation, execute the workflow step by step. For each step:

1. State briefly what's about to happen ("Reading the PDF now…"). Keep it to one line.
2. Invoke the skill — this means `view` its SKILL.md first (if not already in context), then follow its instructions.
3. Pass the output of the previous step as the input of the next.
4. If a skill fails or returns unexpected output, stop and tell the user. Don't paper over it by guessing.

After the final step, present the deliverables (use `present_files` if available) and offer the natural next move — but only if a next move genuinely helps ("Want me to also generate the slide deck from this?"). Silence is fine when the work is done.

### Evolution watch (runs throughout Phase 4)

While executing, watch for evolution candidates — moments where a
skill's description didn't match the user's intent, its procedure had a
gap, an anti-pattern just happened that wasn't called out, references
didn't cover a question, or a partnership between two skills was
implicit but unwired. When you notice one, capture it via the
`skill-evolution` skill: a one-line note now becomes a reviewable
proposal under `docs/skill-evolution/` that the user can accept, merge,
or reject later.

Surface captured candidates in the final handoff:

```
(Optional) During this workflow, I noticed 2 evolution candidates:
- docs/skill-evolution/2026-05-13-project-onboarding-register-synonym.md
- docs/skill-evolution/2026-05-13-task-breakdown-granularity.md
Run `skill-merge` when ready to consider applying them.
```

Do not lobby for the changes — list them and let the user decide.

## When NOT to orchestrate

This skill is overhead. Don't pay it for tasks that don't need it.

- **Single-skill task with no prep:** "Read this PDF" → just run `pdf-reading`. Don't wrap it in a plan-and-ask ceremony.
- **No skill needed at all:** "Write me a haiku about autumn" → just respond.
- **User has already specified the chain:** "Run pdf-reading, then docx, with the file I uploaded" → they've planned it. Execute, don't re-plan.
- **Pure conversation, advice, or analysis:** "What do you think about Y?" → answer directly.

If after Phase 1 you find only one relevant skill and no preparation/postprocessing is needed, stand down and let the single skill run normally. Wasted ceremony is worse than no ceremony.

## Input-hint examples

These show the consolidation principle in action.

**User:** "Convert this PDF into a Word document I can edit."
**Already obvious:** PDF is attached, output format is .docx.
**Worth asking (1 question max):** Preserve images and formatting, or clean it up to plain text?
**Plan shown:** `pdf-reading` → `docx`.

**User:** "Build me a habit-tracking app."
**Not obvious:** stack, scope, languages, target platform.
**Worth asking (cap at 3):** stack preference (Python+React / Node+React / Go+React), scope (prototype only / MVP / full v1), UI language (English only / English + Traditional Chinese).
**Plan shown:** `project-prototype` → `project-docs` → `task-breakdown` → `project-frontend` + chosen backend.

**User:** "I want to build a SaaS for X and launch it."
**This matches `lifecycle-pilot`'s `fires_on`** ("said with launch intent (not just prototype)").
**Preferred routing:** invoke the `lifecycle-pilot` agent; its AGENT.md is the workflow.
**Worth asking (cap at 3 across the whole arc):** backend language; launch posture (closed/open/public beta); compliance regime.
**Plan shown:** lifecycle-pilot's 7-phase arc (prototype → docs → task-breakdown → frontend+backend → launch-readiness → GTM → public launch).

**User:** "Plan our re-architecture from monolith to services and the relaunch as v2."
**This needs ≥2 agents** (`architecture-shepherd` + `lifecycle-pilot` + `devops-engineer` as supporter). Multiple agents → engage `scenario-strategist`.
**Preferred routing:** invoke `scenario-strategist`; its four-phase arc (analysis → workflow → group → handoffs) staffs and contracts the multi-agent group.
**Plan shown:** scenario-strategist arc → formed group executes (typically Scenario R from SCENARIOS.md).

**User:** "Summarize the uploaded meeting notes and turn them into a slide deck for tomorrow's board meeting."
**Already obvious:** notes attached, output is .pptx, audience is the board.
**Worth asking (1 question):** rough slide count and whether to include speaker notes.
**Plan shown:** `file-reading` → analyze content → `pptx`.

**User:** "Help me decide which skill to use for X."
**This is meta — the user is explicitly asking for orchestrator guidance.**
**Don't ask any questions yet — just survey the catalog and propose the chain. Then ask for inputs in the same turn.**

## Failure modes to avoid

- **Over-asking.** More than 3 questions in one intake means you haven't done the planning work. Decide for the user where you can; ask only where it genuinely changes the output.
- **Re-asking what's in context.** If the user already said "in Spanish" or already uploaded a file, treat that as decided. State it back so they can correct if needed.
- **Hardcoding skill names.** This skill never assumes a specific skill is present. Read `<available_skills>` fresh each time — it changes across environments. If a needed skill isn't loaded, say so plainly and offer the best alternative.
- **Silent fall-through.** If you decide not to orchestrate, that's fine, but don't pretend orchestration happened. Just run the single skill or answer directly.
- **Asking after starting.** Once execution begins, all questions should already be answered. Mid-workflow prompts mean Phase 3 was rushed.

## Maintenance — when the catalog changes

The skill catalog and the universal instructions evolve alongside the
projects that use them. Two disciplines keep this skill (and the framework
as a whole) consistent under change:

1. **Whenever a skill is added, removed, renamed, or substantially
   re-scoped:** update this SKILL.md and `references/workflow-patterns.md`
   so future orchestration runs see the change. Also re-check the
   companion skills' cross-references (`cognitive-alignment`,
   `memory-ontology`, `compact-ritual`) — they often name partners by
   slug.
2. **Whenever the universal `INSTRUCTIONS/` change in a way that affects
   which skills fire for which intent:** mention the change in the next
   user session before silently applying the new guidance, and update the
   relevant scenario in `SCENARIOS.md` so the playbook still matches.

For the verification half — auditing that a catalog change actually
landed correctly across all the touch points — use the
**`requirement-audit`** skill against the change request. For producing
the participating-skills table for a new scenario, use
**`scenario-checklist`**.

For continuous improvement *driven by live use*, the framework now has
a paired evolution loop: **`skill-evolution`** captures candidates
during execution; **`skill-merge`** applies accepted proposals into
canonical artifacts with conflict detection and downstream consistency
checks. Neither skill modifies anything silently — both surface diffs
and require explicit user confirmation. Treat them as the framework's
own "feature work" mechanic, analogous to how `task-breakdown` works
for user projects.

## Reference files

- `references/workflow-patterns.md` — fleshed-out examples of common multi-skill chains, organized by the four workflow shapes. Load this when a request fits a familiar shape but you want concrete prior-art for the chain.
