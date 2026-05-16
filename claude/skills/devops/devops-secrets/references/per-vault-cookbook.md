# Per-Vault Setup Cookbook

Setup patterns per vault vendor. Pick one per project.

## AWS Secrets Manager

### Provision via Terraform

```hcl
resource "aws_secretsmanager_secret" "db_conn" {
  name                    = "${var.env}/db/conn"
  recovery_window_in_days = 7
  rotation_lambda_arn     = aws_lambda_function.rotation.arn
  rotation_rules {
    automatically_after_days = 90
  }
}

resource "aws_secretsmanager_secret_version" "db_conn" {
  secret_id     = aws_secretsmanager_secret.db_conn.id
  secret_string = jsonencode({
    username = "app_user"
    password = random_password.db.result
    host     = aws_db_instance.main.address
  })
}
```

### Access from app

```python
import boto3
import json

client = boto3.client("secretsmanager", region_name="us-east-1")
secret = json.loads(client.get_secret_value(SecretId="prod/db/conn")["SecretString"])
```

### Rotation Lambda

Uses AWS-provided rotation template; customise per secret type
(RDS / API key / generic).

---

## GCP Secret Manager

### Provision via Terraform

```hcl
resource "google_secret_manager_secret" "db_conn" {
  secret_id = "db-conn"
  labels = { env = var.env, owner = var.team }
  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_version" "db_conn" {
  secret  = google_secret_manager_secret.db_conn.id
  secret_data = jsonencode({...})
}
```

### Access from app

```python
from google.cloud import secretmanager
client = secretmanager.SecretManagerServiceClient()
secret = client.access_secret_version(
    name="projects/<project>/secrets/db-conn/versions/latest"
).payload.data.decode()
```

### Rotation

GCP doesn't ship native rotation Lambdas; use Cloud Scheduler +
Cloud Function for scheduled rotation.

---

## Azure Key Vault

### Provision via Terraform

```hcl
resource "azurerm_key_vault" "main" {
  name                = "${var.env}-${var.project}-kv"
  location            = var.location
  resource_group_name = var.rg
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  enable_rbac_authorization = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = true
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.db.result
  key_vault_id = azurerm_key_vault.main.id
}
```

### Access from app

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

client = SecretClient(
    vault_url="https://<vault>.vault.azure.net/",
    credential=DefaultAzureCredential()
)
secret = client.get_secret("db-password").value
```

---

## HashiCorp Vault (self-host)

### Provision (one-time bootstrap)

```bash
vault operator init
vault operator unseal <key1>
vault operator unseal <key2>
vault operator unseal <key3>

# Enable KV v2 backend
vault secrets enable -path=secret kv-v2

# Enable database secrets engine (dynamic creds)
vault secrets enable database
```

### Access from app

```python
import hvac
client = hvac.Client(url="https://vault.example.com", token=os.environ["VAULT_TOKEN"])
secret = client.secrets.kv.v2.read_secret_version(path="db/conn")["data"]["data"]
```

### Auth methods

- AppRole (typical for services).
- Kubernetes auth (for k8s workloads).
- AWS IAM auth (for AWS workloads).
- OIDC (for humans + CI).

---

## Doppler

### Setup

```bash
doppler login
doppler setup  # links repo to Doppler project + environment
```

### Access from app

Doppler injects secrets as env vars at runtime:

```bash
doppler run -- python app.py
```

For container deploys, use the Doppler operator (k8s) or
secret-fetcher init container.

### Best for

Small-to-medium teams; cross-cloud; ease-of-use prioritised over
deep integration.

---

## 1Password (Secrets Automation)

### Setup

Create a vault per environment in 1Password Business; share
with service principals.

### Access from app

```bash
op item get "db-conn" --vault prod --format json | jq -r '.fields[]|select(.label=="password")|.value'
```

### Best for

Teams already on 1Password; cross-cloud; human + service overlap.

---

## Infisical (open-source SaaS or self-host)

### Setup

```bash
infisical init
infisical login
infisical export --env=prod > .env.prod  # one-time fetch; or use runtime
```

### Access from app

```bash
# Runtime injection (recommended)
infisical run --env=prod -- python app.py
```

### Best for

Open-source preference; cost-sensitive; full-stack apps where
both frontend and backend need secrets.

---

## Choosing — quick decision

| Scenario | Pick |
|---|---|
| Pure AWS stack, no specific compliance constraint | AWS Secrets Manager |
| Pure GCP stack | GCP Secret Manager |
| Pure Azure stack | Azure Key Vault |
| Multi-cloud, opinionated team, need deep features | HashiCorp Vault (self-host) |
| Multi-cloud, small team, prefer SaaS | Doppler or Infisical |
| Existing 1Password Business deployment | 1Password Secrets Automation |
| Need FedRAMP / specific compliance | Check vendor-specific certifications |

---

## Anti-patterns

- **No rotation automation.** Rotation that requires a human will
  not happen on schedule.
- **Secrets in env vars at build time.** Container images become
  secret-laden artifacts; leak risk grows linearly with image
  storage.
- **Vault as glorified env file.** No access policy, no audit, no
  rotation = config file with extra steps.
- **Bootstrap secrets in the same vault as production secrets.**
  If the vault becomes inaccessible, you've locked yourself out of
  the recovery path. Bootstrap secrets in a separate, simpler
  store.
