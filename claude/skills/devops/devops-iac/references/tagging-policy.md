# Tagging Policy

Every cloud resource gets a standard tag set. Enforced via
`default_tags` in the provider config + per-resource overrides.

## Required tags (every resource)

| Tag | Value | Why |
|---|---|---|
| `owner` | team or individual email | Who to ping about this resource |
| `project` | project slug (from `INSTRUCTIONS/projects/<slug>/`) | Which project owns it |
| `env` | dev / staging / prod | Lifecycle context |
| `cost_center` | accounting code | Showback / chargeback |
| `managed_by` | `terraform` (or `pulumi` / `cdk`) | Distinguishes IaC from click-ops |
| `created` | YYYY-MM-DD | Audit / orphan detection |

## Recommended additional tags

| Tag | Value | Why |
|---|---|---|
| `compliance` | `none` / `hipaa` / `pci` / `soc2` / `gdpr` | Routes resources to compliant policies |
| `data_classification` | per `enterprise-kb-access-control` levels | What kind of data it touches |
| `criticality` | `low` / `medium` / `high` / `critical` | Drives SLA + on-call routing |
| `sunset_date` | YYYY-MM-DD (if known) | Lifecycle awareness |

## Terraform provider config (AWS example)

```hcl
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      owner       = var.owner
      project     = var.project_slug
      env         = var.env
      cost_center = var.cost_center
      managed_by  = "terraform"
      created     = formatdate("YYYY-MM-DD", timestamp())
    }
  }
}
```

Per-resource overrides only when needed (e.g. one resource has a
different owner).

## Enforcement

**Pre-apply check:** policy-as-code (OPA / Sentinel / Checkov)
rejects resources missing required tags.

**Periodic audit:** monthly scan of resources missing required
tags; surface to owner; auto-tag orphans (or alert on un-tagged
resources persisting >30 days).

## Cost attribution

Tag-based cost reports per:

- `project` — bills per project.
- `env` — bills per environment (typical: prod 80%, staging
  15%, dev 5%).
- `team` (via `owner`) — bills per team.

## Lifecycle / orphan detection

Resources with no recent activity (no API calls, no metrics) +
no `sunset_date` set are candidates for orphan cleanup. Run
monthly; require named approver before delete.

## Anti-patterns

- **Tags as documentation.** Tags are for automation (cost,
  policy, lifecycle), not human reading. For human reading, use
  documentation.
- **Free-form tag values.** `owner: "John"` is useless without a
  vocabulary. Use emails / handles.
- **Per-resource manual tagging.** Use `default_tags` at the
  provider level; override only by exception.
- **No enforcement.** Tags that aren't checked become aspirational.
  Use policy-as-code.
- **Conflicting tag conventions across teams.** One org-level
  policy; one set of required tags.
