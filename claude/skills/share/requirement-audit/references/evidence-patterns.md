# Evidence Patterns

The strongest available form of evidence depends on what kind of
requirement is being audited. This file maps requirement kinds to the
evidence that most reliably proves satisfaction.

## File-existence requirements

> *"Add a README.md."* / *"Generate the project-context.md file."*

**Weakest evidence:** a claim that the file exists.
**Stronger:** the file path and confirmation the path resolves
(`ls -l <path>`).
**Strongest:** the file path with line ranges that prove it has the
required content.

Format: `path/to/file.md:1–120` or `path/to/file.md` if line ranges are
not meaningful (e.g. one-line stubs).

## Content requirements

> *"The README must explain the framework's language policy."*

**Weakest:** "the README explains it."
**Stronger:** "see README.md lines 10–30."
**Strongest:** the exact lines quoted in the evidence column, plus the
location.

Example evidence pointer:

```
README.md:10–14 — "instructions are English ... project output follows
the project's primary language"
```

When the content is too long to quote, use a tight one-liner plus the
range:

```
README.md:50–112 — "Counts" table covers all skill groups with totals
```

## Behavioural requirements

> *"The script should produce output X when run with input Y."*

**Weakest:** "the script looks right."
**Stronger:** "I ran the script."
**Strongest:** the exact command and a hash / line / sample of the
output that confirms the expected behaviour.

Example:

```
$ python scripts/chunk_book.py --input fixture.txt --out work/chunks/
   --target-tokens 1000
  → work/chunks/index.json (12 chunks)
  → checked: chunks 0–11 have token_count between 800 and 1100
```

## Integration requirements

> *"The new skill should be wired into the orchestrator."*

**Weakest:** "the skill is now in the catalog."
**Stronger:** "the orchestrator's SKILL.md references it."
**Strongest:** the line in the orchestrator that names the new skill,
plus a sample workflow that demonstrates the wiring.

Example:

```
skills/share/skill-orchestrator/SKILL.md:14–22 — names the four meta-skills
including the new one; references/workflow-patterns.md updated with one
worked example
```

## Documentation requirements

> *"Document the new feature."*

**Weakest:** a docstring exists.
**Stronger:** a doc file exists and is linked from the index.
**Strongest:** the doc exists, is linked from the index, AND covers the
feature's required aspects (API, examples, gotchas).

Audit each promised aspect separately. *"Document the new feature"* often
expands into: API reference (one row), worked example (another row), and
gotchas / limitations (a third row).

## Negative requirements

> *"Don't change the public API."* / *"No new external dependencies."*

These are harder because evidence is about *absence*, not presence.

**Weakest:** "I didn't change it."
**Stronger:** a diff command that shows the relevant area unchanged.
**Strongest:** a diff command **plus** a test that would have caught a
change (e.g. a contract test, a generated SDK that did not need
regeneration).

Example:

```
$ git diff main..HEAD -- internal/api/v1/
  → no changes; contract test ./contract/v1_test.go passes
```

## Process requirements

> *"Run the linter and fix any issues."*

The evidence is the result of running the process:

```
$ golangci-lint run ./... 
  → 0 issues
```

Capture both the command and the result. "It passes" without the command
is not evidence.

## Cognitive requirements

> *"Make sure cognitive-alignment is always mentioned in skill descriptions."*

This is the hardest category — it requires cross-cutting checks across many
artifacts. Use a search command as evidence:

```
$ grep -rl 'cognitive-alignment' skills/ | wc -l
  → 11 files reference cognitive-alignment
$ grep -L 'cognitive-alignment\|alignment' skills/share/*/SKILL.md
  → (empty — every share skill mentions alignment)
```

## When evidence is genuinely thin

Some requirements have no strong evidence — e.g. *"the explanation should
feel natural in Spanish."* Mark these PARTIAL with the honest gap:

```
| 3 | Spanish explanation feels natural | ⚠ PARTIAL | Native-speaker review not done; structural translation in `INSTRUCTIONS/README.md:80–110` |
```

Resist the temptation to mark PASS on subjective requirements just to keep
the table clean. PARTIAL with an honest reason is more useful than PASS
with a brittle one.
