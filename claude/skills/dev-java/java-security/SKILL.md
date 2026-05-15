---
name: java-security
description: Use when reviewing or writing security-sensitive Java code — input validation, SQL injection, command injection, deserialization, XSS, SSRF, Spring Security configuration, JWT handling, secrets, dependency audit (OWASP Dependency Check), or rate limiting. Also use during a security review of a PR.
license: Apache-2.0
metadata:
  sources: "OWASP Top 10, OWASP Java Cheat Sheets, Spring Security docs, OWASP Dependency Check"
---

# Java Security

## Input Validation Is Layer One

Every external input is untrusted. Validate at the boundary with Bean
Validation annotations:

```java
public record CreateUser(
    @Email String email,
    @NotBlank @Size(min = 1, max = 100) String name,
    @Min(0) @Max(150) int age
) {}

@PostMapping
public UserDto create(@Valid @RequestBody CreateUser req) { ... }
```

Casting without checking is not validation:

```java
// Bad
Object raw = ...;
Map<String, Object> body = (Map<String, Object>) raw;   // unchecked

// Good
CreateUser req = mapper.readValue(rawJson, CreateUser.class);  // type-checked + validated
```

---

## SQL Injection

Use parameterized queries. Always. JDBC, JPA, jOOQ, and Spring Data all
support them.

```java
// Bad
String sql = "SELECT * FROM users WHERE email = '" + email + "'";
stmt.execute(sql);

// Good — JDBC PreparedStatement
PreparedStatement ps = conn.prepareStatement("SELECT * FROM users WHERE email = ?");
ps.setString(1, email);
ps.executeQuery();

// Good — JPA / Spring Data
@Query("SELECT u FROM User u WHERE u.email = :email")
Optional<User> findByEmail(@Param("email") String email);

// Good — Spring NamedParameterJdbcTemplate
jdbc.query("SELECT * FROM users WHERE email = :email",
    new MapSqlParameterSource("email", email),
    rowMapper);
```

For dynamic column / table names (rare): use an **allow-list**:

```java
private static final Set<String> ALLOWED_COLUMNS = Set.of("id", "email", "created_at");
public List<User> findOrdered(String orderBy) {
  if (!ALLOWED_COLUMNS.contains(orderBy)) {
    throw new IllegalArgumentException("invalid column: " + orderBy);
  }
  return jdbc.query("SELECT * FROM users ORDER BY " + orderBy, rowMapper);
}
```

Never interpolate user-controlled identifiers.

---

## Command Injection

Never pass user input to `Runtime.exec` or `ProcessBuilder` with shell
syntax:

```java
// Bad
Runtime.getRuntime().exec("convert " + userFile + " out.png");

// Good — args array, no shell
new ProcessBuilder("convert", userFile, "out.png")
    .redirectErrorStream(true)
    .start()
    .waitFor();
```

`ProcessBuilder` with an args array skips the shell entirely. Validate any
file paths against an allowed directory.

---

## Deserialization

Java serialization (`ObjectInputStream`) on untrusted data is the
classic-but-still-current attack vector — it executes arbitrary code on
deserialization.

```java
// Critical — never on untrusted bytes
ObjectInputStream in = new ObjectInputStream(socket.getInputStream());
Object obj = in.readObject();
```

If you must use Java serialization (legacy), set up a class allow-list:

```java
ObjectInputStream in = new ObjectInputStream(stream);
in.setObjectInputFilter(filterInfo ->
    ALLOWED_CLASSES.contains(filterInfo.serialClass())
        ? ObjectInputFilter.Status.ALLOWED
        : ObjectInputFilter.Status.REJECTED);
```

For modern code: use Jackson / Gson with schema-validated DTOs, or
protobuf. Don't accept arbitrary object graphs.

XML / YAML: use safe loaders. SnakeYAML 2.0+ defaults to `SafeConstructor`;
SnakeYAML 1.x defaults are unsafe.

---

## SSRF

Server-Side Request Forgery: server fetches a URL the user controls,
attacker points it at internal services or cloud metadata
(`http://169.254.169.254/...`).

Defenses (apply all that fit):

1. **Allow-list domains** — whitelist destinations.
2. **Resolve hostname, block private IPs** — `127.0.0.0/8`, `10.0.0.0/8`,
   `172.16.0.0/12`, `192.168.0.0/16`, `169.254.0.0/16`, IPv6 equivalents.
3. **Disable redirects** or follow through the same checks.
4. **Restrict to `https://`** — no `file://`, `gopher://`, `jar:`, `ftp://`.

```java
URI uri = URI.create(url);
if (!"https".equals(uri.getScheme())) throw new IllegalArgumentException();
InetAddress addr = InetAddress.getByName(uri.getHost());
if (addr.isLoopbackAddress() || addr.isSiteLocalAddress()
    || addr.isLinkLocalAddress() || addr.isAnyLocalAddress()) {
  throw new IllegalArgumentException("private address");
}
```

---

## XSS

For server-rendered HTML (Thymeleaf, JSP), the engine auto-escapes by
default. Don't disable with `th:utext` on user content. For email and PDF
rendering, same rules apply.

For JSON APIs, XSS isn't a server concern — but ensure the client doesn't
`innerHTML` the response. Jackson escapes JSON-special chars by default.

---

## JWT

Use a vetted library (Auth0 `java-jwt`, `jjwt`, Spring Security OAuth2
Resource Server).

- **Verify the signature**, don't just decode.
- **Pin algorithms** — don't trust the token's `alg` header (the "none"
  attack is famous).
- Set short `exp` for access tokens (15 min); refresh separately.
- Don't put secrets in the payload — JWT bodies are base64, not encrypted.

```java
// Auth0 java-jwt
Algorithm alg = Algorithm.RSA256((RSAPublicKey) publicKey, null);   // public-only verifier
JWTVerifier verifier = JWT.require(alg)
    .withIssuer("https://issuer.example")
    .withAudience("my-api")
    .build();
DecodedJWT jwt = verifier.verify(token);  // throws on invalid
```

For Spring, use Spring Security's `JwtDecoder` configured with a JWKs
endpoint — the framework rotates keys automatically.

---

## Spring Security: Minimum Config

```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {

  @Bean
  public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
    return http
        .authorizeHttpRequests(auth -> auth
            .requestMatchers("/actuator/health/**").permitAll()
            .requestMatchers("/api/public/**").permitAll()
            .anyRequest().authenticated())
        .oauth2ResourceServer(o -> o.jwt(Customizer.withDefaults()))
        .csrf(c -> c.disable())       // CSRF off for stateless API
        .sessionManagement(s -> s.sessionCreationPolicy(STATELESS))
        .build();
  }
}
```

Don't disable security globally during development "to save time" — it
ships to production.

---

## CSRF

CSRF matters for cookie-based browser sessions. For Bearer-token APIs (JWT
in `Authorization`), it's not the threat — disable CSRF for the API and
keep it for any form-based admin UI.

For cookie sessions, Spring Security's CSRF protection is on by default.
Use `SameSite=Lax` (or `Strict`) on session cookies.

---

## Password Hashing

```java
// Bad — fast hash, brute-force-friendly
String hash = DigestUtils.sha256Hex(password);

// Good — adaptive
PasswordEncoder encoder = new BCryptPasswordEncoder();
String hash = encoder.encode(password);
boolean ok = encoder.matches(submitted, hash);

// Better — argon2id when available
PasswordEncoder encoder = new Argon2PasswordEncoder(16, 32, 1, 65536, 3);
```

Spring's `PasswordEncoderFactories.createDelegatingPasswordEncoder` picks a
modern default and supports upgrade-on-login.

Never plain `MessageDigest` for passwords. Never `MD5`/`SHA-1`.

---

## Constant-Time Comparison

For comparing secrets (signatures, tokens), use `MessageDigest.isEqual` —
not `String.equals`:

```java
boolean valid = MessageDigest.isEqual(
    expectedSignature.getBytes(StandardCharsets.UTF_8),
    providedSignature.getBytes(StandardCharsets.UTF_8));
```

`String.equals` can short-circuit, leaking timing information.

---

## Secure Random

```java
// Bad — predictable
new Random().nextInt();

// Good
new SecureRandom().nextInt();

// Or — generate a token directly
byte[] bytes = new byte[32];
new SecureRandom().nextBytes(bytes);
String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
```

`Random` is a PRNG — fine for non-security uses; never for tokens,
passwords, session IDs.

---

## Dependency Audit

```bash
# Maven
mvn org.owasp:dependency-check-maven:check

# Gradle
./gradlew dependencyCheckAnalyze
```

Run in CI. Treat known-high vulnerabilities as a build break. For
supply-chain hardening:

- Pin dependency versions (no `LATEST`).
- Use a dependency lock file (`maven-lockfile` plugin, Gradle locking).
- Audit transitive dependencies separately from direct.

For continuous scanning, **Snyk**, **Dependabot**, **Renovate**.

---

## Secrets in Code

Never commit secrets. Use a pre-commit hook (`gitleaks`, `trufflehog`) and
the platform's secret scanner.

If a secret leaked: rotate first, then remove from git history. Removing
without rotation is theater.

For dev secrets, use a vault-backed secret store; for CI, the platform's
encrypted secrets feature.

---

## Process Hardening

- Run as a non-root user (`USER nobody` in Dockerfile).
- Drop capabilities (`--cap-drop=ALL` in container runtime).
- Use a security manager... actually no — `SecurityManager` is deprecated
  in modern Java. Rely on process-level isolation (containers, namespaces).
- Limit JVM features (`-Dcom.sun.management.jmxremote=false` in
  production unless needed).

---

## Static Analysis

Run **SpotBugs** with **FindSecBugs** plugin in CI:

```xml
<plugin>
  <groupId>com.github.spotbugs</groupId>
  <artifactId>spotbugs-maven-plugin</artifactId>
  <configuration>
    <plugins>
      <plugin>
        <groupId>com.h3xstream.findsecbugs</groupId>
        <artifactId>findsecbugs-plugin</artifactId>
      </plugin>
    </plugins>
  </configuration>
</plugin>
```

Catches command injection, weak crypto, hardcoded passwords, unsafe XML
parsing, and the usual suspects.

---

## Quick Reference

| Threat | Defense |
|---|---|
| Bad input | Bean Validation at controller |
| SQL injection | PreparedStatement / JPA params |
| Command injection | `ProcessBuilder` with args array |
| Deserialization | DTO + Jackson; safe YAML loader |
| SSRF | Allow-list domains, block private IPs |
| XSS (server templates) | Auto-escape; never `th:utext` user input |
| JWT confusion | Pin algorithm; verify, don't decode |
| CSRF | `SameSite` + token for cookie sessions; disable for Bearer APIs |
| Password hashing | bcrypt or argon2id |
| Constant-time | `MessageDigest.isEqual` |
| Random | `SecureRandom` |
| Vulnerable deps | OWASP Dependency Check in CI |

## Related Skills

- **HTTP**: [java-http](../java-http/SKILL.md) for Spring Security setup.
- **Error handling**: [java-error-handling](../java-error-handling/SKILL.md) for not leaking traces.
- **Logging**: [java-logging](../java-logging/SKILL.md) for secret redaction.
- **Config**: [java-config](../java-config/SKILL.md) for secret env vars and vault integration.
- **Linting**: [java-linting](../java-linting/SKILL.md) for SpotBugs + FindSecBugs in CI.
- **Code review**: [java-code-review](../java-code-review/SKILL.md) for the security section of a PR review.
