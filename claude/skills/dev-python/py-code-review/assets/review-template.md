# Code Review: [PR Title]

## Summary
[1-2 sentences describing what this PR does and why.]

## Verdict
- [ ] Approved — ship it.
- [ ] Approved with suggestions — these can land in a follow-up.
- [ ] Changes requested — list of blockers below.
- [ ] Needs more context — questions below.

## Findings

### Blockers (must change before merge)
- [ ] `src/path/to/file.py:42` — Description of the critical issue.

### Suggestions (consider)
- [ ] `src/path/to/file.py:78` — Description of the optional improvement.

### Questions
- [ ] `src/path/to/file.py:120` — Why this approach instead of X?

## Automated Checks
- [ ] `ruff format --check .` — clean
- [ ] `ruff check .` — clean (no new suppressions)
- [ ] `mypy src/` — passes
- [ ] `pytest` — passes
- [ ] `pip-audit` (or `safety check`) — no high/critical CVEs

## Skills Applied
[List of py-* skills referenced during review, e.g.]
- `py-async` — checked for blocking I/O in async handlers and cancellation
- `py-error-handling` — checked exception chains and bare-except usage
- `py-security` — checked input validation and SQL parameterization
- `py-testing` — checked test naming and parametrize usage

## Notes
[Anything else for the author — context, references, links to related PRs.]
