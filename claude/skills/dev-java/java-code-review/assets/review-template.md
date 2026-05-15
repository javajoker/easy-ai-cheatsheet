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
- [ ] `src/main/java/.../File.java:42` — Description of the critical issue.

### Suggestions (consider)
- [ ] `src/main/java/.../File.java:78` — Description of the optional improvement.

### Questions
- [ ] `src/main/java/.../File.java:120` — Why this approach instead of X?

## Automated Checks
- [ ] `mvn spotless:check` (or `./gradlew spotlessCheck`) — clean
- [ ] `mvn compile` — clean (no new ErrorProne warnings)
- [ ] `mvn checkstyle:check` — clean
- [ ] `mvn test` — passes
- [ ] `mvn org.owasp:dependency-check-maven:check` — no high CVEs

## Skills Applied
[List of java-* skills referenced during review, e.g.]
- `java-concurrency` — checked virtual-thread vs platform-thread usage and InterruptedException handling
- `java-error-handling` — checked exception chains and `try-with-resources`
- `java-security` — checked input validation and SQL parameterization
- `java-testing` — checked test naming and parameterized usage

## Notes
[Anything else for the author — context, references, links to related PRs.]
