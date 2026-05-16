# Per-Cloud IaC Baselines

Opinionated baseline choices per cloud. Pick one cloud per
project; multi-cloud is a deliberate org-level decision, not a
default.

## AWS

### Networking

- **VPC:** 3 AZs minimum for prod.
- **Subnets:** public (LB), private (compute), isolated (data).
- **NAT:** 1 per AZ for prod (HA); single NAT for dev/staging.
- **Security groups:** deny-all default; named groups per service.
- **VPC flow logs:** enabled → central log bucket.

### Compute

- **ECS Fargate** (default) — managed; no node mgmt.
- **EKS** — for k8s-experienced teams or k8s-mandated workloads.
- **Lambda** — for event-driven / sporadic workloads.

### Data

- **RDS Postgres** — multi-AZ for prod; automated snapshots.
- **DynamoDB** — for K/V or strictly partition-keyed access.
- **S3** — versioned + encrypted; lifecycle to Glacier for archives.

### DNS + TLS

- **Route 53** — hosted zone per domain.
- **ACM** — TLS certs; auto-renewed.
- **CloudFront** — CDN if static + dynamic mix.

### State backend

- **S3** (encrypted, versioned) + **DynamoDB** (lock table).
- One state bucket per environment.

---

## GCP

### Networking

- **VPC:** custom mode; 3 regions for prod multi-region.
- **Subnets:** per region; Cloud NAT for egress.
- **Firewall rules:** deny-all default; service-tagged rules.
- **VPC flow logs:** enabled → Cloud Logging.

### Compute

- **Cloud Run** (default) — managed; serverless containers.
- **GKE** — for k8s-mandated workloads.
- **Compute Engine** — for stateful / legacy workloads.

### Data

- **Cloud SQL Postgres** — HA enabled for prod.
- **Firestore** — for document workloads.
- **Cloud Storage** — versioned + encrypted; lifecycle classes.

### DNS + TLS

- **Cloud DNS** — managed zone per domain.
- **Google-managed certs** — auto-renewed via Load Balancer.

### State backend

- **GCS** (encrypted, versioned) — built-in object locking.
- One state bucket per environment.

---

## Azure

### Networking

- **Virtual Network** — 3 availability zones for prod.
- **Subnets:** application, data, management.
- **NSG (Network Security Groups):** deny-all default.
- **Application Gateway** for L7 LB.

### Compute

- **Container Apps** (default) — managed serverless containers.
- **AKS** — for k8s-mandated workloads.
- **App Service** — for managed app hosting.

### Data

- **Azure Database for Postgres** — Flexible Server, zone-redundant for prod.
- **Cosmos DB** — multi-region NoSQL.
- **Blob Storage** — geo-redundant for prod.

### DNS + TLS

- **Azure DNS** — managed zone.
- **App Service Managed Certs** — auto-renewed.

### State backend

- **Azure Storage** (encrypted) + **Blob lease** for locking.

---

## Multi-cloud / cloud-agnostic

If the project genuinely spans clouds (rare but valid):

- **k8s anywhere** (EKS / GKE / AKS) for compute.
- **Postgres** managed wherever (RDS / Cloud SQL / Azure DB).
- **Cloudflare** for DNS + TLS (cloud-independent).
- **Terraform Cloud** or **Spacelift** for state backend (cloud-
  independent).

Multi-cloud is materially more expensive in ops time. Document
the rationale in `arch-assessment` before committing.

---

## Edge / serverless platforms

For Vercel + Supabase, Cloudflare Workers, Fly.io, etc.:

- IaC is lighter — the platform handles most infrastructure.
- Use the platform's own config (vercel.json, fly.toml,
  wrangler.toml) — often the IaC.
- Terraform providers exist for these platforms; useful when
  state matters.
- Secrets via platform-native vault.

These platforms trade ops simplicity for vendor lock-in. Make
the trade-off explicit in `INSTRUCTIONS/projects/<slug>/`.
