# Agents — progress checklist

A single place to track the state of the agent layer. Update this file as
work lands. Status vocabulary matches `skills/share/scenario-checklist/`:

- **shipped** — defined, all dependent skills exist, scenario in SCENARIOS.md.
- **draft** — AGENT.md exists but is partially specified or under review.
- **stub** — AGENT.md exists as a placeholder with frontmatter + intent only.
- **missing** — referenced but not yet created.

For dependent skills, status uses the same vocabulary plus `proposed` (a
named gap with no skill folder yet).

---

## Per-agent status

### 1. lifecycle-pilot — Prototype → Prod → Go-to-Market

- [x] `agents/lifecycle-pilot/AGENT.md` — **shipped (scaffold)**
- [x] Existing skills wired in: `project-prototype`, `project-docs`, `task-breakdown`, `project-frontend`, `project-backend-{node,go,python}`, `project-mockup-app`, `create-project-instruction`, `requirement-audit`
- [x] **New skills (GTM tail) — fleshed out:**
  - [x] `gtm-launch-readiness` — opinionated pre-launch audit; 6 categories, 40+ rows, PASS/PARTIAL/FAIL — **shipped** (+ `references/launch-checklist.md`)
  - [x] `gtm-positioning` — category, ICP, anti-ICP, value prop, differentiation, messaging hierarchy, voice — **shipped** (+ `references/positioning-brief-template.md`)
  - [x] `gtm-pricing-model` — model choice, tiers, feature-tier matrix, free path, anchoring, discount policy, rationale — **shipped** (+ `references/pricing-model-template.md`)
  - [x] `gtm-marketing-site` — Vite + React + Tailwind + i18n site from positioning + pricing + PRD; SEO baseline; analytics pre-wired — **shipped**
  - [x] `gtm-beta-program` — 4-phase ladder (dogfood → closed → open → public), screening from ICP, exit criteria, feedback loop, beta telemetry — **shipped**
  - [x] `gtm-analytics-instrumentation` — north-star + counter-metrics + AARRR funnels + event taxonomy (`events.json`) + per-audience dashboards + alerts + privacy posture — **shipped**
- [x] Scenario M in `SCENARIOS.md` — **shipped** (+ worked Example 1/2 in Appendix B)
- [x] `HOWTO.md` agents-layer entry — **shipped**
- [ ] Reference sub-files (`references/*` beyond the templates already shipped) — *partial; flesh out per skill as projects use them*

### 2. architecture-shepherd — Architecture upgrade support

- [x] `agents/architecture-shepherd/AGENT.md` — **shipped (scaffold)**
- [x] Existing skills wired in: `project-knowledge-base`, `requirement-audit`, `memory-ontology`, language-specific `*-code-review`
- [x] **New skills — all 5 fleshed out:**
  - [x] `arch-assessment` — current-state diagram + hot paths + pain points + risk register + 3+ options matrix with inferred-vs-confirmed discipline — **shipped** (+ `references/assessment-template.md`)
  - [x] `arch-migration-plan` — 3–8 phases with reversible checkpoints (non-negotiable), interface locks, owners, critical path, parallelism, test plans — **shipped** (+ `references/migration-plan-template.md`)
  - [x] `arch-dependency-upgrade` — changelog scan → test matrix → canary → ramp (1/10/50/100%) → cleanup; special-case DB-major with write-cutover discipline — **shipped**
  - [x] `arch-rollout-strategy` — five strategies (big-bang / blue-green / canary / dark-launch / feature-flagged), metric gates tied to SLOs, automatic abort conditions, verbatim per-stage rollback — **shipped**
  - [x] `arch-breaking-change-comms` — audience-specific drafts (internal Slack/email, changelog, customer email, API docs banner, FAQ), sunset escalation pattern (soft → warn → soft-fail → removed), runway by severity — **shipped**
- [x] Scenario P in `SCENARIOS.md` — **shipped**

### 3. scenario-strategist — Scenario analysis, workflow design, agent group formation

- [x] `agents/scenario-strategist/AGENT.md` — **shipped (scaffold)**
- [x] Existing skills wired in: `skill-orchestrator`, `scenario-checklist`, `requirement-audit`, `cognitive-alignment`
- [x] **New skills — fleshed out:**
  - [x] `scenario-analysis` — brief + weighted-options analysis + recommendation + decision recording — **shipped** (+ `references/scenario-brief-template.md`, `references/options-analysis-template.md`)
  - [x] `workflow-design` — 3–7 phases with gate kinds (audit / review / metric / decision), critical path, sync points, interface locks, risk-adjusted slack — **shipped** (+ `references/workflow-design-template.md`)
  - [x] `agent-group-formation` — reads `agents/CHECKLIST.md` at runtime; one lead per phase; named conductor; missing-role gaps surfaced — **shipped** (+ `references/agent-group-template.md`)
  - [x] `agent-handoff-protocol` — six-field contract per transition; verification snippets; rejection log; two-rejection rule — **shipped** (+ `references/handoff-protocols-template.md`)
- [x] Scenario N in `SCENARIOS.md` — **shipped** (multi-agent compositions in R, S)

### 4. devops-engineer — DevOps

- [x] `agents/devops-engineer/AGENT.md` — **shipped (scaffold)**
- [x] Existing skills wired in: `requirement-audit`, `memory-ontology`, `doc-markdown-standards`, language-specific dev skills
- [x] **New skills — all 7 fleshed out:**
  - [x] `devops-ci-cd` — opinionated pipeline baseline (on-PR + on-merge + on-approval) with per-platform templates (GitHub Actions / GitLab / Jenkins / CircleCI / Buildkite); cache discipline; required checks; secrets handling — **shipped** (+ `references/pipeline-templates/github-actions-baseline.yml`)
  - [x] `devops-iac` — Terraform-default IaC (Pulumi / CDK alternatives); networking + compute + data + DNS + TLS layers; remote state + locking; per-env separation; tagging discipline; plan-not-apply gate — **shipped**
  - [x] `devops-observability` — OpenTelemetry baseline (structured JSON logs + RED/USE metrics + traces with per-env sampling); golden-signals dashboards; SLOs with multi-window burn-rate alerts — **shipped** (+ `references/slo-worksheet.md`)
  - [x] `devops-incident-runbook` — fixed-shape runbooks (Detect → Diagnose → Mitigate → Recover → Postmortem); quarterly game-day rehearsals; blameless postmortem template — **shipped** (+ `references/runbook-template.md`, `references/postmortem-template.md`)
  - [x] `devops-release-management` — cadence + freeze windows + approval chain + versioning + rollback (3 modes with verbatim procedures) + communication — **shipped** (+ `references/release-policy-template.md`)
  - [x] `devops-security-hardening` — 8-category pre-prod audit (SBOM / dep scan / secrets scan / auth / RBAC / TLS / input validation / OWASP top 10); PASS/PARTIAL/FAIL with evidence; waiver discipline — **shipped**
  - [x] `devops-secrets` — vault choice; per-class rotation (long-lived 90d / short-lived 24h / one-time / external / bootstrap); least-privilege access; audit + anomaly alerts; emergency rotation runbook — **shipped** (+ `references/emergency-rotation-template.md`)
- [x] Scenario O in `SCENARIOS.md` — **shipped**

### 5. knowledge-curator — Enterprise knowledge base upgrade

- [x] `agents/knowledge-curator/AGENT.md` — **shipped (scaffold)**
- [x] Existing skills wired in: `project-knowledge-base`, `book-to-knowledge-graph`, `ontology-extraction`, `ontology-merging`, `ontology-storage`, `ontology-qa`, `memory-ontology`, `cognitive-alignment`
- [x] **New skills — all 5 fleshed out:**
  - [x] `enterprise-kb-architecture` — 7-domain default taxonomy (products / teams / decisions / terminology / runbooks / customers / partners); entity contract (base required fields + per-domain extras); promotion + sunset criteria; re-architecture triggers — **shipped** (+ `references/architecture-template.md`)
  - [x] `enterprise-kb-merge` — per-entity decision tree (canonical / per-project / conflict); explicit conflict surfacing; cross-reference rewriting; alias capture; versioned merge reports — **shipped**
  - [x] `enterprise-kb-refresh-policy` — per-entity-type staleness rules; named ownership (mandatory); automatic + manual triggers; soft/hard sunset; unowned-entity governance with auto-sunset safety valve — **shipped**
  - [x] `enterprise-kb-search-index` — shared retrieval client; context-preserving chunking (1–3 per entity, with metadata prefix); hybrid (dense + BM25) + reranking; per-vector-DB defaults; ACL-aware at retrieval layer — **shipped**
  - [x] `enterprise-kb-access-control` — 5-level classification (public / internal / restricted / confidential / regulated); internal as restrictive default; per-classification redaction policy; full audit log with anomaly alerts; quarterly access audits — **shipped**
- [x] Scenario Q in `SCENARIOS.md` — **shipped** (multi-agent composition in S)

### 6. feature-development — Add a feature to an onboarded project

- [x] `agents/feature-development/AGENT.md` — **shipped**
- [x] Existing skills wired in: `cognitive-alignment`, `project-knowledge-base`, `memory-ontology`, `requirement-audit`, `compact-ritual`, `skill-orchestrator`, language `*-code-review`/`*-testing`/`*-linting`, `doc-markdown-standards`
- [x] **New skill — fleshed out:**
  - [x] `feature-spec` — single-feature delta spec; 11-section structure (why, out-of-scope, load-bearing terms, user-facing change, API contract delta, data model delta, background work delta, verification plan, rollout plan, risks + open questions, related artifacts); writes `docs/features/FEATURE_<slug>.md` into the project (not `/mnt/user-data/outputs/`); pairs with `requirement-audit` for the verification rubric — **shipped** (+ `references/feature-spec-template.md`, `references/api-delta-template.yaml`, `references/verification-rubric.md`)
- [x] Reference files for the agent — **shipped** (`feature-development-checklist.md`, `handoff-decision-tree.md`, `feature-pr-template.md`)
- [x] Scenario T in `SCENARIOS.md` — **shipped**
- [x] Worked walkthrough — **shipped** (`SCENARIOS.md` Appendix B, Example 2)

---

## Cross-cutting work

- [x] `agents/README.md` — abstraction defined; relationship to skills + INSTRUCTIONS documented.
- [x] `agents/CHECKLIST.md` — this file.
- [x] Top-level `claude/README.md` — references `agents/` (pass 1).
- [x] `SCENARIOS.md` — agent-aware scenarios M–T shipped (6 single-agent + 2 multi-agent) plus Scenario U (version tuning) and two worked examples in Appendix B.
- [x] `skills/share/skill-orchestrator/SKILL.md` — teaches preference for named agents when `fires_on` matches; multi-match routes via `scenario-strategist` (pass 8).
- [x] `claude/HOWTO.md` — covers the agents layer + orchestrator preference + agent vs skill decision rules (pass 8).
- [ ] `skills/share/scenario-checklist/SKILL.md` — extend output table to include an "agent" column when an agent owns a row — *missing* (low priority — agent ownership is documented in AGENT.md already; this is a polish item)

---

## Summary counts

| Group | Total | Shipped | Stub | Missing |
|---|---|---|---|---|
| Agents | 6 | 6 | 0 | 0 |
| Agent-dependent skills (GTM / arch / scenario / devops / KB / feature) | 28 | 28 | 0 | 0 |
| Agent scenarios in `SCENARIOS.md` (M–T single, R/S multi) | 8 | 8 | 0 | 0 |
| Worked examples (`SCENARIOS.md` Appendix B) | 2 | 2 | 0 | 0 |

The agent layer is fully shipped: every agent has an AGENT.md, all
dependent skills exist, and every agent has at least one scenario.
Remaining work is per-project polish — flesh out each skill's
`references/*` as real projects exercise them.
