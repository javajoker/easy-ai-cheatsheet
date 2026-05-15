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
- [ ] `src/path/to/file.ts:42` — Description of the critical issue.

### Suggestions (consider)
- [ ] `src/path/to/file.ts:78` — Description of the optional improvement.

### Questions
- [ ] `src/path/to/file.ts:120` — Why this approach instead of X?

## Automated Checks
- [ ] `npx prettier --check .` — clean
- [ ] `npx eslint .` — clean (no new suppressions)
- [ ] `npx tsc --noEmit` — passes
- [ ] `npm test` — passes
- [ ] `npm audit --omit=dev` — no high/critical CVEs

## Skills Applied
[List of node-* skills referenced during review, e.g.]
- `node-async` — checked for floating promises and parallel/sequential trade-offs
- `node-error-handling` — checked custom error subclasses and `cause` chain
- `node-security` — checked input validation and SQL parameterization
- `node-testing` — checked test naming and parametrization

## Notes
[Anything else for the author — context, references, links to related PRs.]
