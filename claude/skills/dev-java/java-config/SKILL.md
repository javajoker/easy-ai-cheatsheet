---
name: java-config
description: Use when designing or loading configuration in Java — Spring Boot `@ConfigurationProperties`, environment variables, application.yml profiles, secrets management, validation with Bean Validation (JSR-380), or layered overrides. Also use when reviewing code that reads `System.getenv` ad hoc.
license: Apache-2.0
metadata:
  sources: "12-Factor App, Spring Boot docs, Micronaut config docs, Bean Validation 3.0"
---

# Java Configuration

## Spring Boot: `@ConfigurationProperties`

The canonical way to bind config in Spring Boot is a record (or class) with
`@ConfigurationProperties`:

```java
@ConfigurationProperties(prefix = "myapp")
public record AppProperties(
    @NotBlank String env,
    @Min(1) @Max(65535) int port,
    @NotNull URI databaseUrl,
    String logLevel,
    @NotNull Duration httpTimeout
) {}
```

Enable in the application:

```java
@SpringBootApplication
@EnableConfigurationProperties(AppProperties.class)
public class App { ... }
```

Inject:

```java
@Service
public class UserService {
  public UserService(AppProperties props) {
    this.timeout = props.httpTimeout();
  }
}
```

Validation runs at startup; the application fails fast on invalid config.

---

## Fail Fast on Invalid Config

A bad config should kill the process at startup, before it accepts traffic.
A silent default ("port was missing so I'll use 8080") is a footgun.

```java
@ConfigurationProperties(prefix = "myapp")
@Validated   // triggers Bean Validation
public record AppProperties(
    @NotBlank String env,
    @Min(1) int port,
    @NotNull URI databaseUrl
) {}
```

For values that *do* have a meaningful default (log level, page size),
declare the default in the property file, not as a fallback at the call
site:

```yaml
myapp:
  log-level: INFO
  pagination:
    page-size: 20
```

---

## `application.yml` Layout

```yaml
# application.yml — base
myapp:
  env: development
  port: 8080
  log-level: DEBUG
  http-timeout: 5s

spring:
  datasource:
    url: jdbc:postgresql://localhost:5432/myapp
```

Profile-specific overrides go in `application-<profile>.yml`:

```yaml
# application-production.yml
myapp:
  log-level: INFO
spring:
  datasource:
    hikari:
      maximum-pool-size: 20
```

Activate with `SPRING_PROFILES_ACTIVE=production` or `--spring.profiles.active=production`.

---

## Layered Override Order

Spring Boot's source priority (high to low):

1. Command-line args (`--server.port=8080`).
2. `SPRING_APPLICATION_JSON` env var.
3. OS environment variables (`SERVER_PORT=8080`, with case mapping).
4. Java system properties (`-D`).
5. `application-<profile>.yml`.
6. `application.yml`.

Each layer overrides the one below. Production injects env vars; local dev
uses `application.yml`.

Env var mapping: `MYAPP_DATABASE_URL` → `myapp.database-url`. Dashes
become uppercase underscores.

---

## `.env` and Secrets

`.env` files don't belong in the repository:

| File | Tracked in git? |
|---|---|
| `.env` | No |
| `.env.example` | Yes (placeholder values) |
| `application.yml` | Yes (no secrets) |
| `application-production.yml` | Yes (no secrets — production secrets are env vars) |

For local dev, `spring-dotenv` reads `.env`. In production, the platform
injects env vars from a vault (AWS Secrets Manager, Vault, Kubernetes
Secrets).

Secrets in env vars:

```yaml
# application.yml — reference the env var, don't hardcode
spring:
  datasource:
    password: ${DB_PASSWORD}
```

If the env var is missing, the config fails to bind — that's correct.

---

## Don't Log the Whole Config

```java
// Bad
log.info("starting with {}", appProperties);   // logs database url with password

// Good
log.info("starting env={} port={}", appProperties.env(), appProperties.port());
```

`@ConfigurationProperties` records have generated `toString` that includes
every field. Override or be explicit about what you log.

For DB connections, the password is part of the URL — be especially careful
with full `URI` toString.

---

## Multi-Environment

Don't write `if (env.equals("production"))` across modules. Translate the
environment into typed config once, then branch on the config:

```java
// Bad
if (System.getenv("ENV").equals("production")) { ... }

// Good
if ("production".equals(appProperties.env())) { ... }

// Better — feature-specific property
if (appProperties.enableNewCheckout()) { ... }
```

For features that vary, prefer **feature flags** over env checks. Flags
are explicit, runtime-toggleable, and don't require a deploy.

---

## Don't Read `System.getenv` Outside Config

```java
// Bad — scattered reads
int port = Integer.parseInt(System.getenv("PORT"));

// Good
@Autowired AppProperties props;
int port = props.port();
```

Central reads mean:

- The model documents every input.
- Adding a new env var is a single-file change.
- Validation catches typos before the call site does.

ArchUnit rule:

```java
@Test
void noDirectEnvAccess() {
  noClasses()
      .that().resideInAPackage("..myapp..")
      .and().areNotAssignableTo(AppProperties.class)
      .should().callMethod(System.class, "getenv", String.class)
      .check(importedClasses);
}
```

---

## Test Configuration

In tests, override properties at the test class level:

```java
@SpringBootTest(properties = {
    "myapp.port=4000",
    "myapp.log-level=ERROR",
})
class IntegrationTest { ... }
```

Or with a separate profile:

```java
@ActiveProfiles("test")
@SpringBootTest
class IntegrationTest { ... }
```

```yaml
# application-test.yml
myapp:
  env: test
  log-level: ERROR
spring:
  datasource:
    url: jdbc:h2:mem:test
```

The same validation runs in tests — bad test config fails like production
would.

---

## Bean Validation Across the Property Tree

```java
@ConfigurationProperties("myapp")
@Validated
public record AppProperties(
    @NotBlank String env,
    @Valid Database database,        // validate nested
    @Valid Cache cache
) {
  public record Database(@NotNull URI url, @Min(1) int poolSize) {}
  public record Cache(@NotNull Duration ttl, @Min(1) int maxSize) {}
}
```

`@Valid` cascades validation into nested records. Without it, only the
top-level fields are checked.

---

## Feature Flags

For simple per-environment toggles, a boolean in config works:

```java
@ConfigurationProperties("myapp.features")
public record FeatureFlags(boolean newCheckout, boolean betaUi) {}

if (features.newCheckout()) { ... }
```

For per-user or per-tenant flags, use a service (LaunchDarkly, Unleash,
Togglz). Don't roll your own from env vars when granularity grows.

---

## Non-Spring Projects

For non-Spring Java (libraries, CLIs), use:

- **Typesafe Config (lightbend-config)** — HOCON files, layered.
- **Picocli** — for CLI options and env vars.
- **Manual** — `System.getenv(...)` wrapped in one config class.

The same principle holds: read once, validate, then expose typed access.

---

## Quick Reference

| Question | Default |
|---|---|
| Source of truth | `@ConfigurationProperties` record |
| Validation | `@Validated` + Bean Validation |
| Where read | One config class / module |
| `.env` in git | No |
| `.env.example` in git | Yes |
| Defaults | In `application.yml` |
| Secrets | Env var referencing vault |
| Profile activation | `spring.profiles.active` |
| Multi-env logic | Branch on typed properties |

## Related Skills

- **Security**: [java-security](../java-security/SKILL.md) for secret handling.
- **Logging**: [java-logging](../java-logging/SKILL.md) for log-level config.
- **HTTP**: [java-http](../java-http/SKILL.md) for binding port and timeouts.
- **Types**: [java-types](../java-types/SKILL.md) for record-based property classes.
- **Testing**: [java-testing](../java-testing/SKILL.md) for test profiles.
