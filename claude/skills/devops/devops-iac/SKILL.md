---
name: devops-iac
description: Scaffolds infrastructure-as-code (Terraform by default; Pulumi or CDK on request) for a project — networking (VPC / subnets / SG / NAT), compute (ECS / EKS / Cloud Run / VMs / serverless), data layer (RDS / Cloud SQL / DynamoDB), DNS + TLS (Route 53 / Cloud DNS / Cloudflare + ACM / Let's Encrypt), and dev / staging / prod environments with remote state + locking. Emits a `terraform plan` for human review; never runs `apply` directly. Enforces tagging discipline (owner / project / env / cost-center on every resource) and one-environment-per-state separation. Use this skill when the user says "set up the infra", "write the Terraform", "we need IaC", "scaffold the cloud resources", "add staging environment". Pairs with arch-rollout-strategy (rollout targets IaC-managed infra), with devops-ci-cd (deploys land in this infra; CI can run `terraform plan` on PRs), with devops-release-management (production infra changes follow the same approval chain as code releases), with devops-observability (telemetry backend infra is provisioned here), and with devops-secrets (vault is provisioned here too).
status: shipped
owner_agent: devops-engineer
---

# DevOps IaC

Scaffolds the infrastructure. Defaults to **Terraform** because
it's the broadest-supported across teams and clouds; supports
Pulumi or AWS/GCP/Azure CDK on request.

> **The skill never runs `apply`.** It scaffolds the code and
> emits a `terraform plan`; a human reviews and runs. Silent
> infrastructure changes are the single most-expensive failure
> mode in DevOps — the gate is non-negotiable.

## Why this exists

Hand-rolled infrastructure failures are predictable:

1. **Click-ops drift.** Resources created in the cloud console;
   nobody knows how to recreate them; the next environment is
   "close enough but different".
2. **Bus-factor-1 expertise.** One engineer understands the
   Terraform; when they leave, nobody touches it for fear of
   breaking prod.
3. **Local state.** State on a laptop → corrupted state →
   irreversible infrastructure (`terraform import` archaeology).
4. **No tags.** Cost-center attribution impossible; resource
   lifecycle ambiguous; orphans accumulate.
5. **Shared state across environments.** A bad plan in dev wipes
   prod because state is one file.

This skill ships an opinionated baseline that:

- Separates state per environment.
- Uses remote state with locking.
- Tags every resource.
- Scaffolds the standard layers (networking / compute / data /
  DNS / TLS) consistently across projects.
- Refuses to apply itself — humans review every plan.

## When to fire

Fire when:

- The user asks *"set up the infra"*, *"write the Terraform"*,
  *"scaffold the cloud resources"*, *"add staging environment"*,
  *"migrate to IaC"*.
- A new project is preparing for prod and has no IaC yet.
- An existing project's infra is click-ops and needs to be
  brought under IaC (an *import* exercise — different from
  scaffolding; document this clearly).

Do **not** fire when:

- The user wants a single one-off resource added (just do it; no
  scaffolding ceremony).
- The user is debugging an existing Terraform issue (diagnose
  directly).
- The project explicitly opts out of IaC (rare but legitimate —
  e.g. fully serverless on Vercel where the platform handles
  infra). Document the decision and respect it.

## Inputs

Required:

- `INSTRUCTIONS/projects/<slug>/project-context.md` — cloud
  target, region(s), stack.

Asked once (cap at 4):

1. **IaC tool.** Terraform (default) / OpenTofu / Pulumi / AWS
   CDK / Azure Bicep / GCP Deployment Manager.
2. **Cloud.** AWS / GCP / Azure / multi-cloud / Vercel + Supabase
   / Cloudflare Workers / DigitalOcean / Fly.io.
3. **Compute model.** Container orchestration (ECS / EKS / Cloud
   Run / Kubernetes) / VMs / serverless / hybrid.
4. **Remote state backend.** S3 + DynamoDB (AWS default) / GCS
   (GCP default) / Azure Storage / Terraform Cloud /
   Spacelift / Scalr.

## The opinionated baseline

### Directory layout

```
infrastructure/
├── README.md                    # what this is, how to run
├── modules/                     # reusable modules (org-level)
│   ├── network/
│   ├── compute/
│   ├── data/
│   └── dns-tls/
├── environments/
│   ├── dev/
│   │   ├── main.tf
│   │   ├── backend.tf           # remote state config
│   │   ├── variables.tf
│   │   ├── terraform.tfvars     # env-specific values (no secrets)
│   │   └── outputs.tf
│   ├── staging/                 # same shape
│   └── prod/                    # same shape
├── shared/                      # cross-env resources (ECR, DNS zone)
│   └── main.tf
└── .terraform-version           # tfenv pin
```

**Each environment has its own state.** A bad plan in dev cannot
touch prod state. This is non-negotiable.

### State backend

| Cloud | Backend | Locking |
|---|---|---|
| AWS | S3 (encrypted, versioned) | DynamoDB lock table |
| GCP | GCS (encrypted, versioned) | Built-in object locking |
| Azure | Azure Storage | Blob lease |
| Multi-cloud | Terraform Cloud / Spacelift | Built-in |

**Never local state in a multi-engineer project.** Even for
solo projects, remote state survives the laptop dying.

### Tags / labels (every resource)

| Tag | Value | Why |
|---|---|---|
| `owner` | team or individual email | Who to ping about this resource |
| `project` | slug from INSTRUCTIONS/projects/ | Which project owns it |
| `env` | dev / staging / prod | Lifecycle context |
| `cost_center` | accounting code | Showback / chargeback |
| `managed_by` | terraform | Distinguishes IaC from click-ops |
| `created` | YYYY-MM-DD | Audit / orphan detection |

Enforced via `default_tags` in the provider (Terraform AWS
provider) or equivalent.

### Module discipline

- **Modules ≥ 3 use cases** before promoting from per-project
  to shared.
- **Modules expose narrow interfaces.** A 50-variable module is
  a config file, not a module.
- **Module versioning.** Tag releases; environments reference
  pinned versions, not main.

## The procedure

### Phase 1 — Pick the stack

Per the inputs question. Stack picks:

| Cloud | Default compute | Default data | Default DNS |
|---|---|---|---|
| AWS | ECS Fargate (or EKS for k8s teams) | RDS Postgres | Route 53 + ACM |
| GCP | Cloud Run (or GKE) | Cloud SQL Postgres | Cloud DNS + Google-managed certs |
| Azure | Container Apps (or AKS) | Azure Database for Postgres | Azure DNS + App Service Managed Certs |
| Multi-cloud | k8s anywhere | Postgres anywhere | Cloudflare DNS + universal SSL |

These are starting points; the user can override.

### Phase 2 — Scaffold the layers

For each layer, generate the module:

**Networking:**

- 1 VPC (3 AZ minimum for prod).
- Public subnets (load balancers) + private subnets (compute) +
  isolated subnets (data).
- NAT gateway per AZ (prod) or single NAT (dev/staging).
- Security groups: deny-all default; named groups per service.
- VPC flow logs enabled to a central log bucket.

**Compute:**

- Container registry (ECR / GCR / GHCR).
- Cluster / service definitions per app.
- Autoscaling policies (CPU + memory + custom metrics).
- Health checks pointing at app health endpoints.
- IAM roles per service (least privilege).

**Data:**

- Primary database (Postgres default).
- Read replicas for prod.
- Automated snapshots (35 day retention default).
- Encryption at rest enabled.
- Network: in isolated subnet; security group allows only from
  app SG.
- Connection string surfaced as IaC output (referenced by app
  via secrets manager, not directly).

**DNS + TLS:**

- Hosted zone for the project's domain (shared module — DNS
  zones rarely change per env).
- Per-env records (`dev.app.com`, `staging.app.com`,
  `app.com`).
- TLS certs auto-renewed (ACM / Let's Encrypt / cloud-managed).
- HSTS + redirect HTTP → HTTPS at the load balancer.

### Phase 3 — Environment separation

Per environment, generate `environments/<env>/`:

- `backend.tf` — points at the env's own state file.
- `main.tf` — instantiates the modules.
- `variables.tf` — env-specific variables (instance sizes,
  scaling limits, retention).
- `terraform.tfvars` — values for those variables.
- `outputs.tf` — what other systems consume.

**Naming convention:** `<env>-<project>-<resource>` (e.g.
`prod-frostfire-api-cluster`). Prefix-by-env makes everything
greppable.

### Phase 4 — Cost guardrails

The skill emits a cost-estimate (via `infracost` or equivalent)
in the plan output:

- Per-env monthly estimate.
- Highest-cost resources called out.
- Comparison vs. previous plan (delta).

For prod, declare a monthly cost ceiling in
`environments/prod/cost-budget.tf`; alert if monthly cost
exceeds 110% of ceiling.

### Phase 5 — Plan, not apply

The skill never runs `terraform apply`. It:

1. Runs `terraform init` (or instructs the user to).
2. Runs `terraform plan` and surfaces the plan.
3. Calls out additions / changes / destroys.
4. **Stops.** The user reviews and runs `apply` themselves.

For high-stakes envs (prod), strongly recommend the plan be
reviewed by a second engineer.

### Phase 6 — Import existing resources (if applicable)

If the project has click-ops infrastructure being brought under
IaC for the first time:

- Use `terraform import` per resource (or `terraformer` for bulk).
- **Do not destroy** during import — risk of recreating with
  different state.
- Plan after import should show *no changes*; if it shows
  changes, the imported state and reality diverge; reconcile
  before continuing.

### Phase 7 — Wire into CI/CD

Hand off to `devops-ci-cd` to add:

- PR-time `terraform plan` for infrastructure changes (catches
  drift early).
- Merge-time `terraform plan` artifact for human review.
- Apply only on explicit approval, not on merge.

### Phase 8 — Document

Generate `infrastructure/README.md`:

- What this directory is.
- How to run locally (`tfenv use`, `terraform init`, `plan`,
  `apply`).
- Per-env quirks.
- Who owns it.
- Pointer to `devops-ci-cd` for CI-level automation.

## Anti-patterns

- **Local state.** Even for prototypes, push to remote. Laptop
  loss = infrastructure orphans.
- **Shared state across environments.** Dev mistakes wipe prod.
  Separate.
- **Auto-apply on merge.** A bad merge wipes prod. Plan-then-
  apply with human in the loop.
- **Untagged resources.** Orphans accumulate; cost attribution
  fails. Tag everything via `default_tags`.
- **Hardcoded secrets in tfvars.** Secrets live in the vault
  (see `devops-secrets`), not in source control.
- **Click-ops on top of IaC.** Resources created in the console
  on top of IaC-managed resources cause drift. Forbid via
  policy + tag-check.
- **Mega-modules.** A single module with 80 variables is a
  config-as-code anti-pattern. Split.
- **Pinning to `main`.** Modules referenced as
  `?ref=main` change without warning. Pin to tags / commits.

## Companion skills

- `devops-ci-cd` — CI runs `terraform plan` on PRs.
- `devops-release-management` — infrastructure changes follow
  the release approval chain.
- `devops-observability` — telemetry backend infra lives here.
- `devops-secrets` — vault lives here.
- `arch-rollout-strategy` — rollout targets IaC-managed infra.
- `arch-migration-plan` — infrastructure migrations use
  reversible-checkpoint discipline.
- `requirement-audit` — verify tag compliance + state-backend
  config quarterly.

## Reference files

- [references/terraform-module-template/](references/terraform-module-template/) —
  starter module skeleton.
- `references/per-cloud-baselines.md` — opinionated defaults
  per cloud target.
- `references/tagging-policy.md` — the canonical tag list +
  enforcement patterns.
- `references/state-backend-cookbook.md` — per-backend setup
  with locking patterns.
