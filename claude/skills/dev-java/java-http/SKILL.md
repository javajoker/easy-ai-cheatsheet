---
name: java-http
description: Use when building HTTP services in Java — Spring Boot controllers, request validation, exception handlers, status codes, response shapes, streaming, content negotiation, or virtual-thread HTTP servers. Examples target Spring Boot 3 (preferred). Notes for Jakarta REST (formerly JAX-RS) and Helidon/Quarkus.
license: Apache-2.0
compatibility: Spring Boot 3.x / Java 21+.
metadata:
  sources: "Spring Boot docs, Jakarta EE REST guide, OWASP API Security Top 10"
---

# Java HTTP Services

## Pick One Framework

| Framework | When |
|---|---|
| Spring Boot | Default for most Java services. Mature, big ecosystem. |
| Quarkus | Cold-start sensitive (serverless, edge). Native-image friendly. |
| Helidon | Lightweight, microservice-focused. |
| Jakarta REST (JAX-RS) directly | Library-style, no opinions. |

This skill uses Spring Boot in examples.

---

## Validate at the Edge

Every request body, query, and path param is untrusted. Use Bean Validation
annotations on the controller record / DTO; Spring runs the validation before
your handler:

```java
public record CreateUserRequest(
    @Email String email,
    @NotBlank @Size(min = 1, max = 100) String name,
    @Min(0) @Max(150) int age
) {}

@RestController
@RequestMapping("/users")
public class UserController {
  private final UserService service;

  public UserController(UserService service) {
    this.service = service;
  }

  @PostMapping
  @ResponseStatus(HttpStatus.CREATED)
  public UserDto create(@Valid @RequestBody CreateUserRequest req) {
    return UserDto.from(service.create(req));
  }
}
```

`@Valid` triggers Bean Validation. Spring converts the `ConstraintViolationException`
into a 400.

---

## Status Codes

Use the standard set; don't invent.

| Code | When |
|---|---|
| 200 OK | Successful GET / PUT / PATCH with body |
| 201 Created | Successful POST returning the new resource |
| 202 Accepted | Queued for async processing |
| 204 No Content | Successful DELETE or update with no body |
| 400 Bad Request | Validation failure |
| 401 Unauthorized | No / invalid credentials |
| 403 Forbidden | Authenticated but not allowed |
| 404 Not Found | Resource doesn't exist |
| 409 Conflict | Duplicate-key, optimistic-lock |
| 422 Unprocessable Entity | Semantically invalid input |
| 429 Too Many Requests | Rate-limited |
| 500 Internal Server Error | Unexpected failure |
| 502 / 503 / 504 | Upstream / overload / timeout |

Don't return 200 with `{"ok": false, "error": "..."}`. Use the HTTP layer.

---

## One Error Translator

Don't sprinkle `ResponseEntity.status(500)` calls across controllers. Use
`@RestControllerAdvice`:

```java
@RestControllerAdvice
public class GlobalExceptionHandler {

  @ExceptionHandler(NotFoundException.class)
  public ResponseEntity<ErrorBody> notFound(NotFoundException ex) {
    return ResponseEntity.status(404)
        .body(new ErrorBody("not_found", ex.resource(), ex.id()));
  }

  @ExceptionHandler(MethodArgumentNotValidException.class)
  public ResponseEntity<ErrorBody> validation(MethodArgumentNotValidException ex) {
    List<Issue> issues = ex.getBindingResult().getFieldErrors().stream()
        .map(fe -> new Issue(fe.getField(), fe.getDefaultMessage()))
        .toList();
    return ResponseEntity.badRequest().body(new ErrorBody("validation", issues));
  }

  @ExceptionHandler(Exception.class)
  public ResponseEntity<ErrorBody> unhandled(Exception ex) {
    log.error("unhandled", ex);
    return ResponseEntity.status(500).body(new ErrorBody("internal"));
  }
}
```

In production, never leak stack traces or internal messages in responses.

---

## Response Bodies Have Stable Shape

Define canonical error and resource shapes:

```json
// Error
{"error": "validation", "issues": [{"field": "email", "message": "must be a valid email"}]}

// Resource
{"id": "u_1", "email": "a@b", "createdAt": "2024-01-01T00:00:00Z"}
```

Avoid:

- Bare string body (clients have to parse).
- Wrapping every successful response in `{"data": ..., "success": true}` —
  HTTP status carries success.
- Inconsistent date formats — ISO-8601 strings everywhere. Configure Jackson
  globally if you must override the default.

---

## Don't Expose Entities Directly

```java
// Bad — leaks JPA fields and locks the contract to the DB schema
@GetMapping("/{id}")
public User getById(@PathVariable String id) {
  return service.getById(id);   // exposes lazy-loaded fields, internal state
}

// Good — DTO at the boundary
public record UserDto(String id, String email, boolean isAdmin) {
  public static UserDto from(User u) {
    return new UserDto(u.id(), u.email(), u.isAdmin());
  }
}

@GetMapping("/{id}")
public UserDto getById(@PathVariable String id) {
  return UserDto.from(service.getById(id));
}
```

DTOs decouple your wire format from your domain. Records make them
ergonomic.

---

## Request Logging

Spring's default access log is fine for development. For production,
configure structured logging and a request filter that populates MDC:

```java
@Component
public class RequestIdFilter extends OncePerRequestFilter {

  @Override
  protected void doFilterInternal(HttpServletRequest req,
                                  HttpServletResponse res,
                                  FilterChain chain) throws IOException, ServletException {
    String id = Optional.ofNullable(req.getHeader("X-Request-Id"))
        .orElseGet(() -> UUID.randomUUID().toString());
    MDC.put("requestId", id);
    try {
      chain.doFilter(req, res);
    } finally {
      MDC.clear();
    }
  }
}
```

Every log line during the request now includes `requestId`. See
[java-logging](../java-logging/SKILL.md).

---

## Timeouts at Every Hop

| Place | Default |
|---|---|
| Server-side request | 30 s (Tomcat `server.tomcat.connection-timeout`) |
| Outbound `RestClient` / `WebClient` | 5 s |
| DB query | 5 s (HikariCP `connection-timeout`, plus per-statement) |
| External SDK | Set explicitly |

Without timeouts, a stuck upstream hangs threads and threads exhaust.

```java
// RestClient (Spring 6.1+)
RestClient client = RestClient.builder()
    .requestFactory(new SimpleClientHttpRequestFactory() {
      {
        setConnectTimeout(2000);
        setReadTimeout(5000);
      }
    })
    .build();
```

---

## Virtual Threads (Java 21 + Spring Boot 3.2+)

Spring Boot 3.2 added one-line virtual-thread support:

```yaml
spring:
  threads:
    virtual:
      enabled: true
```

Every HTTP request now runs on a virtual thread. Blocking calls (JDBC, RPC)
no longer pin an OS thread — throughput improves substantially under load.

This is a step change from the old async-everything advice. With virtual
threads, traditional synchronous controllers + JDBC scales further than
reactive `WebClient` chains for most workloads.

---

## Streaming Responses

For big payloads, stream rather than buffer:

```java
@GetMapping(value = "/export.ndjson", produces = "application/x-ndjson")
public StreamingResponseBody export() {
  return out -> {
    try (var rows = repo.streamAll()) {
      for (var row : rows) {
        out.write((toJson(row) + "\n").getBytes(StandardCharsets.UTF_8));
        out.flush();
      }
    }
  };
}
```

For server-sent events:

```java
@GetMapping(value = "/events", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
public SseEmitter events() {
  SseEmitter emitter = new SseEmitter(Duration.ofMinutes(30).toMillis());
  // ... add events from a background thread ...
  return emitter;
}
```

---

## CORS, Compression, Security Headers

Spring's defaults are good. Customize via config:

```yaml
server:
  compression:
    enabled: true
    mime-types: application/json,text/html,text/css
```

CORS:

```java
@Configuration
public class WebConfig implements WebMvcConfigurer {
  @Override
  public void addCorsMappings(CorsRegistry registry) {
    registry.addMapping("/api/**")
        .allowedOrigins("https://app.example.com")
        .allowedMethods("GET", "POST", "PUT", "DELETE");
  }
}
```

Security headers: Spring Security adds HSTS, X-Content-Type-Options,
X-Frame-Options, CSP. Don't disable them globally.

---

## Rate Limiting

For per-IP or per-user limits, use `bucket4j` or a gateway/proxy layer
(Nginx, Envoy, API gateway). Key on the right axis: per-IP for anonymous
endpoints, per-user for authenticated.

```java
@Component
public class RateLimitFilter extends OncePerRequestFilter {
  private final Map<String, Bucket> buckets = new ConcurrentHashMap<>();

  private Bucket bucketFor(String ip) {
    return buckets.computeIfAbsent(ip, k -> Bucket.builder()
        .addLimit(Bandwidth.simple(60, Duration.ofMinutes(1)))
        .build());
  }
  // ... apply in doFilterInternal ...
}
```

---

## Health and Readiness

Spring Boot Actuator provides `/actuator/health` and `/actuator/health/liveness`,
`/actuator/health/readiness` (Kubernetes-friendly):

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health, info, metrics, prometheus
  endpoint:
    health:
      probes:
        enabled: true
```

A passing liveness with a failing readiness lets the load balancer take
the pod out of rotation without restarting it.

---

## OpenAPI

Spring Boot doesn't include OpenAPI out of the box. Add **springdoc-openapi**:

```xml
<dependency>
  <groupId>org.springdoc</groupId>
  <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
</dependency>
```

Serves `/v3/api-docs` (JSON) and `/swagger-ui.html` (UI). Schemas come from
Bean Validation annotations and JavaDoc; refine with `@Schema` where
needed.

---

## Quick Reference

| Question | Default |
|---|---|
| Framework | Spring Boot 3 |
| Validate where | At the controller, with `@Valid` + Bean Validation |
| Status codes | Standard set |
| Error handling | `@RestControllerAdvice` |
| DTO at boundary | Yes — records |
| Virtual threads | `spring.threads.virtual.enabled=true` (Java 21+) |
| Streaming | `StreamingResponseBody` / `SseEmitter` |
| Health | Actuator probes |
| OpenAPI | springdoc-openapi |

## Related Skills

- **Error handling**: [java-error-handling](../java-error-handling/SKILL.md) for status-code mapping.
- **Logging**: [java-logging](../java-logging/SKILL.md) for request-scoped MDC.
- **Concurrency**: [java-concurrency](../java-concurrency/SKILL.md) for virtual threads.
- **Types**: [java-types](../java-types/SKILL.md) for records as DTOs.
- **Security**: [java-security](../java-security/SKILL.md) for input validation, headers, rate limit.
- **Config**: [java-config](../java-config/SKILL.md) for port, timeouts, CORS.
