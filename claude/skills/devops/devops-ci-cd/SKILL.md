---
name: devops-ci-cd
description: Generates or reviews a CI/CD pipeline (GitHub Actions / GitLab CI / Jenkins / CircleCI / Buildkite) with on-PR (lint + type-check + test + build), on-merge-to-main (deploy-staging + smoke), and on-manual-approval (deploy-prod) stages. Pulls test and lint commands from the language-specific dev skills (go-testing, py-testing, node-testing, java-testing) so the pipeline matches the project's actual stack. Enforces branch protection, required status checks, dependency caching, and reproducible builds. Use this skill when the user says "set up CI", "write the pipeline", "add a deploy job", "the CI is failing — fix it", "review my workflow file", "add caching to the build". Pairs with language-specific *-testing and *-linting skills (commands), with devops-iac (deploys target IaC infrastructure), with devops-release-management (production deploy gating + approval chain), with devops-observability (post-deploy smoke + alert silencing during deploys), and with devops-secrets (CI consumes secrets via vault, never from repo env).
status: shipped
owner_agent: devops-engineer
---

# DevOps CI/CD

Generates the CI/CD pipeline. The pipeline is the *quality gate*,
not a deployment script — its job is to refuse to ship broken
code, and to ship known-good code reliably when nothing is broken.

> **The pipeline is owned by engineering, not "DevOps".** This
> skill produces a pipeline the engineering team can read,
> modify, and trust. Hidden magic in YAML is technical debt.

## Why this exists

Pipelines have two predictable failure shapes:

1. **Hand-rolled per project.** Every project re-invents the
   pipeline. There's no compounding investment; common bugs
   recur.
2. **Bespoke "expert" pipelines.** A platform engineer writes a
   1500-line pipeline only they understand. When they leave, the
   pipeline becomes unmaintainable; teams ship broken code to
   avoid touching it.

This skill ships an opinionated baseline that:

- Reads the language-specific dev skills to pick the right test
  and lint commands.
- Uses the same shape across projects so engineers reading a new
  project's CI feel at home.
- Enforces the load-bearing gates (lint, type, test, build,
  required checks, branch protection) without piling on
  decoration.
- Surfaces extensions as additions to the baseline, not rewrites.

## When to fire

Fire when:

- The user asks *"set up CI"*, *"write the pipeline"*, *"add a
  deploy job"*, *"add caching"*, *"my CI is failing — review my
  workflow"*.
- A new project is being onboarded and has no CI yet.
- An existing pipeline needs migration (e.g. Jenkins → GitHub
  Actions).
- A project crosses the prod boundary and CI needs deploy
  stages added.

Do **not** fire when:

- The user is debugging a specific failing job (it's faster to
  diagnose directly than regenerate the pipeline).
- The project has a working pipeline they like and just wants
  one specific change (do the change; don't impose the baseline).
- The user explicitly wants a "different shape" — capture the
  shape they want; don't fight it.

## Inputs

Required:

- `INSTRUCTIONS/projects/<slug>/project-context.md` — stack,
  test/build commands, deploy target.

Asked once (cap at 3):

1. **CI platform.** GitHub Actions (default if repo is on
   GitHub) / GitLab CI / Jenkins / CircleCI / Buildkite.
2. **Deploy targets.** Which environments exist (dev / staging /
   prod minimum). Where they live (URLs, cloud regions).
3. **Approval chain for prod.** Who can approve a prod deploy.

## The opinionated baseline

### On every PR (must complete green before merge)

| Stage | What | Owner skill |
|---|---|---|
| Setup | Install deps with cache; restore from lockfile | – |
| Lint | Per-language lint | `<lang>-linting` |
| Type-check | Per-language type-check | `<lang>-types` / `<lang>-typing` |
| Unit tests | Per-language unit tests | `<lang>-testing` |
| Integration tests | Per-language integration tests | `<lang>-testing` |
| Build | Per-language build (artifact, container, binary) | – |
| Security | Dep scan + secrets scan | `devops-security-hardening` |

### On merge to main

| Stage | What |
|---|---|
| Rebuild from main | Clean build of the merged commit |
| Push artifact | To registry (Docker Hub, GHCR, ECR, GCR) or storage (S3) |
| Deploy staging | Automatic, no approval |
| Staging smoke | Post-deploy smoke tests |
| Notify | Slack / email confirmation of staging deploy |

### On manual approval (for prod)

| Stage | What |
|---|---|
| Approval gate | Named approver from `devops-release-management` chain |
| Deploy prod | According to chosen strategy (rolling / blue-green / canary) |
| Prod smoke | Post-deploy smoke tests; gate the strategy's ramp |
| Notify | Slack / email confirmation + changelog entry |
| Tag release | Git tag matching the deployed version |

## The procedure

### Phase 1 — Read project context

Open `INSTRUCTIONS/projects/<slug>/project-context.md`. Pull:

- Stack (language, framework).
- Test command (e.g. `pnpm test`, `go test ./...`, `pytest`,
  `./mvnw test`).
- Lint command.
- Build command + artifact location.
- Deploy target (cloud / region / hosting platform).
- Any project-specific quirks (custom scripts, special env vars).

If `project-context.md` is missing or stale, run
`project-onboarding` first (or at least surface the gap).

### Phase 2 — Pick the platform variant

| Platform | File(s) generated | Notes |
|---|---|---|
| GitHub Actions | `.github/workflows/ci.yml`, `.github/workflows/deploy.yml` | Default for GitHub repos |
| GitLab CI | `.gitlab-ci.yml` | Single file; uses stages |
| Jenkins | `Jenkinsfile` | Declarative pipeline |
| CircleCI | `.circleci/config.yml` | Workflows + jobs |
| Buildkite | `.buildkite/pipeline.yml` | Steps + agent queues |

The skill ships one template per platform under
[references/pipeline-templates/](references/pipeline-templates/).
Pick the right one; substitute project-specific values.

### Phase 3 — Cache discipline

Caching cuts pipeline time 50%+ but mis-configured caches cause
the most-painful CI failures (stale dependency cache, corrupted
build cache).

**Rules:**

- **Lockfile-keyed cache.** Cache key = OS + lockfile hash, never
  branch name.
- **Per-language defaults.**
  - Node: `~/.pnpm-store` or `~/.npm` keyed by `pnpm-lock.yaml`.
  - Python: `~/.cache/pip` or `~/.cache/uv` keyed by
    `pyproject.toml` + lockfile.
  - Go: `~/go/pkg/mod` keyed by `go.sum`.
  - Java: `~/.m2/repository` or `~/.gradle/caches` keyed by
    `pom.xml` / `build.gradle`.
- **Cache build outputs sparingly.** Test caches (e.g. Vitest,
  pytest) — yes; built artifacts — usually no (just rebuild).
- **Eviction.** Caches >7 days old or >2GB get evicted; document
  the policy.

### Phase 4 — Required status checks + branch protection

The pipeline is meaningless without enforcement. Enable, via the
platform's API or settings:

- **Required status checks** before merge: lint, type-check,
  test, build, security scan.
- **Branch protection on main**: require PRs; require ≥1 approval;
  no force-push; no direct push.
- **Stale review dismissal** on new pushes.
- **Conversation resolution required** before merge.
- **CODEOWNERS** for areas that need specific reviewer (auth,
  payments, infra).

These configurations live as code where possible:

- GitHub: `.github/CODEOWNERS`, branch protection via Terraform
  or `gh api` script in repo.
- GitLab: project settings as code via Terraform provider.

### Phase 5 — Deploy stages

For each environment (dev / staging / prod):

| Field | Decision |
|---|---|
| Trigger | merge-to-main (staging) / manual (prod) / nightly (dev) |
| Strategy | rolling / blue-green / canary (see `arch-rollout-strategy` if non-trivial) |
| Smoke tests | curl health endpoint + run smoke-test suite |
| Rollback | verbatim command in the pipeline; no manual SSH-and-pray |
| Notification | Slack channel + email per environment |
| Tag | git tag on prod deploys |

Hand off the rollout strategy detail to `arch-rollout-strategy`
if the deploy is non-trivial (canary ramp percentages, gates).

### Phase 6 — Secrets handling in CI

Secrets in pipelines is the most-leaked surface in DevOps. Rules:

- **Never** `echo $SECRET` for debug.
- **Never** commit `.env` to repo.
- **Always** pull from the chosen vault at runtime (see
  `devops-secrets`).
- **Mask** secrets in logs (most CI platforms do this when the
  secret is declared as a secret; declare them properly).
- **Audit** secret access — CI access goes into the audit log
  with the workflow run ID.

### Phase 7 — Emit the pipeline files

Write the chosen platform's files. Include:

- One workflow per concern (CI, deploy, scheduled jobs) — not
  one monolithic file.
- Comments explaining *why* a step exists where it's not
  obvious. Steps explain *what* via their names.
- A short `README.md` in the workflows directory pointing at
  this skill and listing the on-call procedure for "CI is
  down".

### Phase 8 — Validate

Run a sanity check before declaring done:

- Pipeline YAML parses (use the platform's linter — `actionlint`,
  `gitlab-ci-lint`, etc.).
- Required secrets are declared in the platform's secret store
  (don't hardcode their *values*; verify the *names* are
  configured).
- Branch protection is enabled.
- A PR has run green at least once against the new pipeline.

## Common extensions (added as PRs to the baseline)

| Extension | When to add |
|---|---|
| Matrix testing (multiple versions / OSes) | Library or tool used across versions |
| Code coverage upload | Want coverage trend visibility (Codecov / Coveralls) |
| Lighthouse / web-vitals | Web frontend with SEO / perf requirements |
| E2E tests (Playwright / Cypress) | Web product with critical user journeys |
| Container scan (Trivy / Snyk) | Container deploys |
| SAST (Semgrep, CodeQL) | High-security project |
| License scan | Org compliance requirement |
| ChromaticUI / Percy | Visual regression matters |
| Release-please / changesets | Library publishing automation |

These extend the baseline; they don't replace it.

## Anti-patterns

- **One mega-workflow.** A 1000-line single workflow is
  unmaintainable. Split by concern.
- **No caching.** Every CI run installs deps from scratch →
  10-minute feedback loop where it should be 2.
- **Cache too aggressive.** Caching build artifacts indiscriminately
  hides flaky tests and stale-dependency bugs.
- **Skipping required status checks.** A pipeline that runs but
  isn't required to pass is decoration.
- **Secrets in repo / logs.** Single most-common breach vector.
  Vault them; mask them; audit them.
- **Hidden expertise.** A pipeline only one engineer understands
  is a bus-factor-1 dependency. Write it readable.
- **Bypassing CI for "small" changes.** Either CI is required or
  it isn't. "I'll just merge this typo fix" is how broken builds
  land.

## Companion skills

- Language `*-testing`, `*-linting`, `*-types` skills — supply
  commands the pipeline runs.
- `devops-iac` — deploys land in IaC-managed infrastructure.
- `devops-release-management` — production approval chain +
  freeze windows.
- `devops-observability` — post-deploy smoke + alert silencing
  during deploys.
- `devops-secrets` — vault integration.
- `devops-security-hardening` — security scan stage.
- `arch-rollout-strategy` — non-trivial deploy strategies.

## Reference files

- [references/pipeline-templates/](references/pipeline-templates/) —
  per-platform baseline templates (GitHub Actions / GitLab / Jenkins).
- `references/required-checks-matrix.md` — which checks to make
  required per project type.
- `references/cache-keys-cookbook.md` — caching patterns per
  language.
