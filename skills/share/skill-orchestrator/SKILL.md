---
name: skill-orchestrator
description: Picks the right combination of skills for a user request, chains them into a workflow, and asks for all required inputs upfront in one consolidated prompt before executing. Trigger this whenever the user describes a multi-step task that likely needs more than one skill chained together (examples - "read this PDF and make a presentation", "build me a full SaaS app for X", "extract data from this xlsx and write a report", "turn these meeting notes into a project plan"), or any time the request implicitly spans content extraction plus generation, project scaffolding, document conversion, or a pipeline of operations. Also trigger when the user explicitly asks "what skills should I use", "which skill fits", "how do I combine skills", "help me choose a workflow", or anything similar. Always trigger BEFORE invoking any single downstream skill if the request could plausibly need more than one - it is much cheaper to plan and consolidate input questions upfront than to ask the user piecemeal mid-workflow.
---

# Skill Orchestrator

A meta-skill that reads the available skill catalog, picks the right chain for the user's request, gathers all required inputs in a single consolidated prompt, then executes the workflow end-to-end.

## Why this exists

When a user says "build me a habit-tracking app" or "summarize this PDF as a slide deck", the right answer is almost never one skill — it's two to five skills chained together. Without orchestration, three failure modes recur:

1. **Wrong skill fires.** The closest single match triggers, but the workflow is missing an upstream extraction step or a downstream packaging step. The deliverable is half-finished and the user has to ask again.
2. **Death by a thousand questions.** Each skill asks for its inputs as it needs them, so the user gets pinged every two minutes for the next missing piece. Worse than a single up-front intake.
3. **Skipped reasoning.** Claude jumps to executing without first checking whether the planned chain actually serves the user's goal.

This skill solves all three by planning first and consolidating input collection.

## The four-phase loop

When this skill triggers, run these four phases in order. Do not skip phase 3.

### Phase 1 — Read the catalog

The available skills are listed in the system prompt under `<available_skills>`. Each entry has a name, a description, and a SKILL.md path. Before planning anything, scan that list and identify every skill whose description plausibly relates to the user's request.

Two rules:

- **Read descriptions, not just names.** `pdf` is for *creating/manipulating* PDFs; `pdf-reading` is for *reading* them. A skill's name often understates what it does.
- **If relevance is unclear, view the SKILL.md.** A two-line description hides nuance. Spend the tool call to confirm before including or excluding a borderline skill.

Also check whether the system prompt has any user-loaded skills (often under `/mnt/skills/user/`) — these are usually more specific to the user's domain and should be preferred over public ones when both could apply.

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

## Reference files

- `references/workflow-patterns.md` — fleshed-out examples of common multi-skill chains, organized by the four workflow shapes. Load this when a request fits a familiar shape but you want concrete prior-art for the chain.
