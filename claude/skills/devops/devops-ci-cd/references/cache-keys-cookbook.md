# Cache Keys Cookbook — per-language patterns

Pipeline cache strategies. The right cache key = `OS + lockfile-hash`,
never `branch-name`. Branch-keyed caches go stale within hours;
lockfile-keyed caches are accurate as long as deps haven't changed.

## Node.js (npm)

```yaml
- name: Cache npm
  uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-npm-${{ hashFiles('package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-npm-
```

## Node.js (pnpm)

```yaml
- name: Cache pnpm store
  uses: actions/cache@v4
  with:
    path: ~/.pnpm-store
    key: ${{ runner.os }}-pnpm-${{ hashFiles('pnpm-lock.yaml') }}
    restore-keys: |
      ${{ runner.os }}-pnpm-
```

## Node.js (yarn)

```yaml
- name: Cache yarn
  uses: actions/cache@v4
  with:
    path: ~/.yarn/cache
    key: ${{ runner.os }}-yarn-${{ hashFiles('yarn.lock') }}
```

## Python (pip)

```yaml
- name: Cache pip
  uses: actions/cache@v4
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('requirements.txt', 'pyproject.toml') }}
```

## Python (uv)

```yaml
- name: Cache uv
  uses: actions/cache@v4
  with:
    path: ~/.cache/uv
    key: ${{ runner.os }}-uv-${{ hashFiles('uv.lock', 'pyproject.toml') }}
```

## Python (poetry)

```yaml
- name: Cache poetry
  uses: actions/cache@v4
  with:
    path: ~/.cache/pypoetry
    key: ${{ runner.os }}-poetry-${{ hashFiles('poetry.lock') }}
```

## Go

```yaml
- name: Cache Go modules + build
  uses: actions/cache@v4
  with:
    path: |
      ~/go/pkg/mod
      ~/.cache/go-build
    key: ${{ runner.os }}-go-${{ hashFiles('go.sum') }}
```

## Java (Maven)

```yaml
- name: Cache Maven
  uses: actions/cache@v4
  with:
    path: ~/.m2/repository
    key: ${{ runner.os }}-maven-${{ hashFiles('**/pom.xml') }}
```

## Java (Gradle)

```yaml
- name: Cache Gradle
  uses: actions/cache@v4
  with:
    path: |
      ~/.gradle/caches
      ~/.gradle/wrapper
    key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
```

## Rust (Cargo)

```yaml
- name: Cache Cargo
  uses: actions/cache@v4
  with:
    path: |
      ~/.cargo/registry
      ~/.cargo/git
      target
    key: ${{ runner.os }}-cargo-${{ hashFiles('Cargo.lock') }}
```

## Docker layer cache (BuildKit)

```yaml
- name: Cache Docker layers
  uses: actions/cache@v4
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-
```

## Common rules

1. **Keyed by lockfile hash**, not branch.
2. **`restore-keys`** allows partial matches when lockfile changes.
3. **Per-OS** (`${{ runner.os }}`) — cross-OS cache is broken.
4. **Eviction:** ≥7 days old OR >2GB → eviction; document policy.
5. **Don't cache build outputs** indiscriminately — stale build
   cache hides flaky tests.

## Anti-patterns

| Pattern | Why bad | Better |
|---|---|---|
| `key: ${{ github.ref }}-deps` | Stale within hours | lockfile hash |
| `path: node_modules` | Cache invalidates per-install; large | `~/.npm` or `~/.pnpm-store` |
| No `restore-keys` | First-run + dep-update both have cache miss | Add `restore-keys: ` for partial matches |
| Caching `target/` or `dist/` for libraries | Stale outputs ship; hides test failures | Don't cache build outputs |
| Cache without versioning the action | Action updates invalidate; large recompute | Pin action version |
