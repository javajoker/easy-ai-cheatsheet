# State Backend Cookbook — per backend with locking

State backend setup patterns. The non-negotiables: **remote state**
(never local in multi-engineer projects) + **locking** (prevent
concurrent applies corrupting state).

## AWS — S3 + DynamoDB

### Provision (one-time bootstrap)

```bash
# Encrypted versioned bucket
aws s3api create-bucket \
  --bucket <org>-terraform-state-<env> \
  --region us-east-1
aws s3api put-bucket-versioning \
  --bucket <org>-terraform-state-<env> \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption \
  --bucket <org>-terraform-state-<env> \
  --server-side-encryption-configuration '{
    "Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]
  }'
aws s3api put-public-access-block \
  --bucket <org>-terraform-state-<env> \
  --public-access-block-configuration '
    BlockPublicAcls=true,IgnorePublicAcls=true,
    BlockPublicPolicy=true,RestrictPublicBuckets=true'

# Locking table
aws dynamodb create-table \
  --table-name <org>-terraform-locks-<env> \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### Per-environment backend.tf

```hcl
terraform {
  backend "s3" {
    bucket         = "<org>-terraform-state-prod"
    key            = "infrastructure/prod.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "<org>-terraform-locks-prod"
  }
}
```

One state file per env; one lock table per env.

---

## GCP — GCS

### Provision

```bash
gcloud storage buckets create gs://<org>-terraform-state-<env> \
  --location=US \
  --uniform-bucket-level-access \
  --public-access-prevention

gcloud storage buckets update gs://<org>-terraform-state-<env> \
  --versioning

# GCS has built-in object locking — no separate lock table needed.
```

### backend.tf

```hcl
terraform {
  backend "gcs" {
    bucket = "<org>-terraform-state-prod"
    prefix = "infrastructure/prod"
  }
}
```

---

## Azure — Storage Account + Blob lease

### Provision

```bash
RESOURCE_GROUP=tfstate-rg
STORAGE_ACCOUNT=<org>tfstate<env>
CONTAINER=tfstate

az group create --name "$RESOURCE_GROUP" --location eastus
az storage account create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$STORAGE_ACCOUNT" \
  --sku Standard_LRS \
  --encryption-services blob \
  --allow-blob-public-access false

az storage container create \
  --name "$CONTAINER" \
  --account-name "$STORAGE_ACCOUNT"
```

### backend.tf

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "<org>tfstateprod"
    container_name       = "tfstate"
    key                  = "infrastructure/prod.tfstate"
  }
}
```

Blob lease provides locking automatically.

---

## Terraform Cloud / Enterprise

For multi-cloud or org-wide standardisation:

### backend.tf

```hcl
terraform {
  cloud {
    organization = "<org>"
    workspaces {
      name = "infrastructure-prod"
    }
  }
}
```

Provides state + locking + remote execution + audit log in one
service.

---

## Spacelift / Env0 / etc.

Similar to TFC but third-party. Often chosen for richer policy
controls.

---

## Bootstrap discipline

The **state backend itself** is a chicken-and-egg problem:

- If the state for the state-backend is in the state backend,
  you can't apply changes without breaking it.

Solutions:

| Pattern | Use when |
|---|---|
| **Bootstrap by hand** | Run the bucket-creation commands once via CLI; check resulting config into IaC for documentation; don't `terraform import` it back |
| **Bootstrap module** | Separate Terraform module for the state backend that uses local state (one-time apply); document the apply in a runbook |
| **Cloud-native primitives** | Use cloud-native tools (CloudFormation, Cloud Deployment Manager) for the bootstrap; Terraform for everything downstream |

The bootstrap is **a one-time event**; document it clearly so the
team doesn't try to manage it via the regular IaC pipeline.

## Anti-patterns

- **Local state in multi-engineer projects.** Last-writer-wins
  on a shared resource = data loss.
- **Shared state across environments.** A bad plan in dev wipes
  prod state. One state file per env.
- **No encryption.** State contains secrets (DB passwords if
  inline, IAM credentials, etc.). Encrypt at rest.
- **No versioning.** Once state corrupts, no recovery point.
  Versioning is cheap; loss is expensive.
- **No locking.** Two engineers apply simultaneously → state
  corruption. Locking is non-negotiable.
- **Storing locks in code.** Lock files in the repo (terraform
  has none by default; some plugins do) get pushed/pulled and
  cause stale-lock issues. Use the backend's native locking.
