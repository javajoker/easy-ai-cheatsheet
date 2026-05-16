# Scan Tools Cookbook

Per-tool configuration + invocation patterns. Open-source defaults
listed first; SaaS alternatives noted.

## SBOM generation — `syft`

```bash
# Generate SBOM in CycloneDX format
syft <image-or-directory> -o cyclonedx-json=sbom.json

# In CI pipeline
- name: Generate SBOM
  run: |
    syft ${{ env.IMAGE_TAG }} -o cyclonedx-json=sbom.json
    aws s3 cp sbom.json s3://<sbom-bucket>/${{ github.sha }}/sbom.json
```

Alternatives: SPDX format via `syft -o spdx-json=sbom.json`;
Trivy can also produce SBOMs.

## SBOM vulnerability scan — `grype`

```bash
grype sbom:./sbom.json --fail-on high
```

Returns non-zero if any high-severity vuln found; fail the
pipeline.

## Dependency vulnerability scan — per language

### Node

```bash
npm audit --audit-level=high
# OR
pnpm audit --audit-level=high
```

### Python

```bash
pip-audit --strict
# OR
uv pip list --outdated  # for tracking
safety check
```

### Go

```bash
govulncheck ./...
```

### Java

```bash
./mvnw dependency-check:check
# OR (Gradle)
./gradlew dependencyCheckAnalyze
```

### Cross-language alternative — Trivy

```bash
trivy fs --severity HIGH,CRITICAL --exit-code 1 .
```

## Secrets scan — git history + working tree

### `gitleaks`

```bash
# Full history scan
gitleaks detect --source=. --report-format=json --report-path=gitleaks-report.json

# Pre-commit hook
gitleaks protect --staged
```

### `trufflehog`

```bash
trufflehog git file://. --json --no-update
trufflehog git https://github.com/<org>/<repo> --json --no-update
```

### Pre-commit configuration

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

## Container scan — `Trivy`

```bash
trivy image --severity HIGH,CRITICAL --exit-code 1 <image-tag>

# With config scan
trivy image --severity HIGH,CRITICAL --scanners vuln,config,secret <image-tag>
```

Alternatives: Snyk, Aqua, Anchore.

## SAST — `Semgrep`

```bash
# Default rule packs
semgrep ci --config=p/security-audit --config=p/owasp-top-ten

# Language-specific
semgrep --config=p/python --config=p/javascript --config=p/golang .
```

Alternatives: GitHub CodeQL (free for public repos), SonarQube,
Checkmarx.

## TLS scan — `testssl.sh` or `ssllabs-scan`

```bash
# testssl.sh (self-host)
testssl.sh --severity HIGH <hostname>

# SSL Labs API (rate-limited)
ssllabs-scan -quiet -usecache <hostname>
```

## DAST baseline — `OWASP ZAP`

```bash
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://<staging-host> \
  -r zap-report.html
```

Run against **staging**, never prod. ZAP baseline is non-intrusive
but still load-generating.

## CSP / security headers — `securityheaders.com` API

```bash
curl -s "https://securityheaders.com/?q=<url>&followRedirects=on&hideResults=on"
```

Or self-check via `curl -I` and inspecting response headers.

## Web vulnerabilities — `Nuclei`

```bash
nuclei -u https://<host> -t cves/ -t exposures/ -severity high,critical
```

Templated detection of known issues; large template community.

## Pipeline integration

Recommended CI stage layout:

```yaml
security:
  parallel:
    - name: Generate SBOM
      run: syft ${{ env.IMAGE_TAG }} -o cyclonedx-json=sbom.json
    - name: SBOM vuln scan
      run: grype sbom:./sbom.json --fail-on high
    - name: Dependency scan (language-specific)
      run: <per-language command>
    - name: Secrets scan
      run: gitleaks detect --source=. --no-banner
    - name: Container scan
      run: trivy image --severity HIGH,CRITICAL --exit-code 1 ${{ env.IMAGE_TAG }}
    - name: SAST
      run: semgrep ci
```

All scans run in parallel; any non-zero fails the security stage.

## SaaS alternatives — when to switch

| Open-source | SaaS alternative | Switch when |
|---|---|---|
| `grype` | Snyk / Dependabot | Want fixed-vuln auto-PRs |
| `gitleaks` | GitGuardian | Want full git-history monitoring + alerts |
| `trivy` (container) | Aqua / Sysdig | Want runtime + admission control |
| `semgrep` (CLI) | Semgrep Cloud | Want PR-comment integration + dashboard |
| `testssl.sh` | Qualys SSL Labs | Want third-party attestation |
| `OWASP ZAP` (baseline) | Burp Suite / Detectify | Want fuller DAST + manual testing |

The CI baseline can start fully open-source; SaaS swaps come when
specific gaps emerge.

## Tuning false positives

Every scanner has noise. Tune by:

- **Allowlist** known-false-positive paths (test fixtures with
  fake credentials, vendored test data).
- **Severity filter** at the scanner level — `--severity HIGH,CRITICAL`
  is the default for blocking.
- **Triaging cadence** — false-positives addressed within a week
  to keep the signal usable.

Untuned scanners become alert fatigue.
