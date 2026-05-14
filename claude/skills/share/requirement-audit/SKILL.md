---
name: requirement-audit
description: Verify a numbered list of requirements against the actual artifacts produced — code, docs, skills, instructions, configuration — and emit a checklist with per-item status (PASS / PARTIAL / FAIL) and pointer-style evidence (file paths, line ranges, command output). Use this skill whenever the user has issued a multi-point request and you need to prove that each point was actually delivered before declaring the work done, when a stakeholder asks "is this complete?" against a PRD or RFC, when wrapping up a long workflow to surface anything that quietly got skipped, or when verifying that a refactor preserved every behaviour that was promised. Pairs with cognitive-alignment so the meaning of each requirement is fixed before audit; pairs with memory-ontology so audit findings that should outlive the session are promoted; pairs with compact-ritual when the audit happens at the natural end of a long session.
---

# Requirement Audit

A skill for verifying that a list of requirements has actually been
satisfied, with evidence per item. Output is a structured checklist that a
human or a future Claude instance can re-verify without re-reading the
whole session.

## Why this exists

Multi-point user requests routinely lose items in the noise: nine numbered
asks turn into seven implemented, two forgotten, and a session that
finishes with a confident "all done" when it isn't. The cost shows up
hours later when the user discovers the gap — by which time the context is
gone and re-deriving what was meant is more expensive than the original
work.

This skill is the discipline that prevents that. Every numbered ask gets a
row; every row gets a status and an evidence pointer; nothing slips into
"done" without something to point at.

## When to fire

Proactively when:

- The user issues a numbered or bulleted list of requirements at the start
  of a session.
- A long-running workflow (10+ turns) is approaching its natural end.
- The user asks "are we done?" or "have we covered everything?".
- A formal artifact (PRD, RFC, spec) is being implemented and the user
  expects clause-level verification.
- A refactor promises to preserve a specific list of behaviours.

Reactively when:

- The user surfaces a gap and wants to know whether anything else slipped.
- A stakeholder asks for a compliance check.
- A handoff to a different agent / human / future session needs an
  auditable record.

## The audit structure

Every audit produces one markdown table plus an explicit summary line.
Nothing else is required, but additional sections (caveats, follow-ups,
recommended next steps) are welcome when useful.

### The table

```markdown
| # | Requirement | Status | Evidence |
|---|---|---|---|
| 1 | <verbatim requirement text> | ✅ PASS / ⚠ PARTIAL / ❌ FAIL / ➖ N/A | <pointer to evidence> |
| 2 | … | … | … |
```

Conventions:

- **Requirement** — quoted verbatim from the user's original ask. Do not
  paraphrase. If a requirement was multi-clause, list each clause as its
  own row.
- **Status**:
  - `✅ PASS` — satisfied; evidence points at the delivered artifact.
  - `⚠ PARTIAL` — partly satisfied; evidence shows what was done, plus a
    one-line note on what is missing.
  - `❌ FAIL` — not satisfied. Always state the reason on the same row.
  - `➖ N/A` — superseded by a later requirement or not applicable
    (rare; explain).
- **Evidence** — pointer-style, not prose:
  - File path with line range: `INSTRUCTIONS/README.md:1–115`.
  - Skill path: `skills/share/requirement-audit/SKILL.md`.
  - Command + result: `git log --oneline -- foo.md → 3 commits`.
  - Cross-doc relation: "see Scenario A in SCENARIOS.md".

### The summary line

After the table:

```
Summary: N PASS · M PARTIAL · K FAIL · L N/A (out of T total)
```

A glance tells the user whether the work is done.

## The procedure

### Phase 1 — Anchor the requirements

Read the user's original request verbatim. Split into numbered items if it
was a numbered list; into clauses if it was prose with multiple asks.

If meaning is ambiguous, run a **cognitive-alignment** check on each
ambiguous term before auditing. *"You wrote 'consistent' — confirm you
mean structural-template consistency, not visual styling?"* Lock the
reading, then audit against the locked reading.

### Phase 2 — Gather evidence

For each requirement, identify the most direct evidence:

- **File-system evidence** — does the promised file / directory / structure
  exist?
- **Content evidence** — does the file contain what was promised?
- **Behavioural evidence** — does running the artifact produce the
  promised output?
- **Cross-reference evidence** — are downstream artifacts wired up to use
  the new piece?

Prefer the strongest available form. A file existing is weaker than a file
having the right content; content is weaker than verifying it loads and
works.

### Phase 3 — Status-and-evidence per row

For each requirement, classify status:

- All sub-clauses satisfied with strong evidence → `✅ PASS`.
- Some sub-clauses satisfied, others not → `⚠ PARTIAL`. Name what is
  missing.
- No sub-clauses satisfied → `❌ FAIL`. Name the reason.
- Requirement was withdrawn or replaced → `➖ N/A`. Name what superseded.

Write the evidence pointer to be **independently re-checkable**: someone
opening the audit later should be able to follow the pointer and verify.

### Phase 4 — Report

Output the table, the summary line, and any of these optional sections
when warranted:

- **Caveats** — items marked PASS but with conditions.
- **Follow-ups** — items that need additional work to upgrade PARTIAL →
  PASS.
- **Recommended next step** — one concrete suggestion.

### Phase 5 — Persist (optional)

If the audit is for a piece of work that should outlive the session,
promote it:

- Save the audit document to a project-appropriate location (default:
  `docs/audits/<YYYY-MM-DD>-<topic>-audit.md`).
- Write a `type: project` memory entry (via `memory-ontology`) so the next
  session knows the audit exists.

For one-off in-conversation audits, persistence is unnecessary.

## What this skill does NOT do

- **Implement the missing items.** Audit is a verification tool, not a
  development tool. When a row is FAIL, surface it; do not silently
  upgrade by completing the work mid-audit.
- **Reinterpret the requirements.** The original ask is canonical. If the
  user actually wanted something different, run cognitive-alignment first
  and re-anchor.
- **Score quality.** PASS does not mean "well done" — it means "the
  promise was kept." A separate review skill judges quality.

## Anti-patterns

- **Vague evidence.** *"Done in the docs"* fails the re-checkability test.
  Always give a file path or command.
- **Paraphrased requirements.** Editing the wording is the most common
  way to mark something PASS that the user did not actually ask for.
- **Hidden PARTIALs.** When in doubt between PASS and PARTIAL, pick
  PARTIAL and name the gap. The cost of being too strict is one user
  correction; the cost of being too lenient is a real miss.
- **Combining multiple clauses into one row.** If a requirement has two
  parts, give it two rows. Status of "PASS for part one, FAIL for part
  two" should never appear in one row.

## Companion skills

| When… | Use |
|---|---|
| Before auditing, to lock the meaning of ambiguous terms | `cognitive-alignment` |
| To persist the audit so the next session knows it happened | `memory-ontology` |
| To surface the audit as the final visible artifact before `/compact` | `compact-ritual` |
| To produce the per-scenario skills checklist that audits against | `scenario-checklist` |
| To orchestrate a multi-step workflow where the audit is the final step | `skill-orchestrator` |

## Reference files

- `references/audit-template.md` — copy-paste audit template with the
  status column and example rows.
- `references/evidence-patterns.md` — the strongest forms of evidence for
  each kind of requirement (file presence, content, behaviour, integration).
