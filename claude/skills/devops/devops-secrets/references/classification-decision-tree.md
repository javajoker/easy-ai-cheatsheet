# Secret Classification Decision Tree

How to classify a new secret. Walk the tree top-to-bottom.

```
Is the secret used by humans directly (e.g. for ad-hoc CLI access)?
├── YES → human-facing classification
│        ├── Used routinely (daily-weekly)?
│        │   ├── YES → Long-lived (90d rotation)
│        │   └── NO  → Short-lived (24h, on-demand provisioning)
│        └── Used for emergency / break-glass only?
│            └── One-time (per use; full audit)
│
└── NO  → Service-to-service or app-internal
         ├── Is it an external vendor API key?
         │   ├── YES → External (90d, or vendor recommendation)
         │   └── NO  → continue
         ├── Is it used by CI/CD or IaC?
         │   ├── YES → Bootstrap (30d, scheduled rotation)
         │   └── NO  → continue
         ├── Is it a per-request / per-session token?
         │   ├── YES → Short-lived (24h or shorter)
         │   └── NO  → continue
         ├── Is it the master credential for a long-lived
         │   resource (DB master password, root API key)?
         │   ├── YES → Long-lived (90d, automated rotation)
         │   └── NO  → continue
         └── Default → Long-lived (90d) [safest]
```

## Examples

| Secret | Class | Rotation |
|---|---|---|
| Postgres `app_user` password | Long-lived | 90d |
| Postgres `replication_user` password | Long-lived | 90d |
| Postgres root password | Long-lived | 90d (rotate carefully) |
| Stripe live API key | External | 90d or vendor rec |
| SendGrid API key | External | 90d |
| GitHub PAT for CI | Bootstrap | 30d |
| AWS IAM service principal key | Bootstrap | 30d |
| JWT signing key (HS256) | Long-lived | 90d (with old-key tolerance during rotation) |
| JWT signing key (RS256 private) | Long-lived | 180d (asymmetric; longer OK) |
| User session token | Short-lived | per session, ≤1h |
| Password reset token | One-time | ≤1h, single use |
| Magic-link token | One-time | ≤15 min, single use |
| Webhook secret (we receive) | External | 90d, coordinated with sender |
| Webhook secret (we send) | External | 90d |
| Customer-issued API key | per customer | per customer policy |
| Encryption key for at-rest data | Long-lived (special: KMS-managed; never raw) | per KMS rotation policy |

## Special cases

### Database encryption keys

Often **never directly rotated** — managed by cloud KMS with key
versioning. Rotation = adding new key version + re-encrypting; old
versions remain for old data.

### TLS certificates

Not strictly secrets, but use vault for the private key. Rotation
= renewal (auto via ACM / Let's Encrypt). Treat as External class
with 90d cadence (max cert lifetime is shrinking industry-wide).

### Asymmetric keys

Private keys are secrets; public keys are not. Rotation involves
both — issue new pair; allow old + new validation period; remove
old.

### Customer-managed keys

If customers BYOK (bring your own key), follow the customer's
policy. Treat as External; track per customer.

---

## When in doubt

Default to **long-lived (90d, automated rotation)** — that's the
class with the strongest safety properties.

It's better to over-rotate a low-risk secret than under-rotate a
high-risk one.
