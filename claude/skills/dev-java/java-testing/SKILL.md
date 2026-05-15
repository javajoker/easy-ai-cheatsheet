---
name: java-testing
description: Use when writing, reviewing, or improving Java tests — JUnit 5 (Jupiter), AssertJ, Mockito, parameterized tests, integration tests with Spring Boot or Testcontainers, async tests, and test fixtures. Also use when a user asks to write a test for a Java method, even if they don't mention a framework.
license: Apache-2.0
metadata:
  sources: "JUnit 5 docs, AssertJ docs, Mockito docs, Testcontainers docs"
allowed-tools: Bash(bash:*)
---

# Java Testing

## Available Scripts and Assets

- **`assets/ParameterizedTestTemplate.java`** — Canonical JUnit 5 + AssertJ + Mockito scaffold with `@ParameterizedTest` (CsvSource, ValueSource, MethodSource), `@BeforeEach`, `@Nested`, and a Mockito setup. Copy as the starting test class.
- **`scripts/gen-test.sh`** — Generates a JUnit 5 test scaffold for a given fully-qualified class name. Supports `--mockito`, `--output`. Run `bash scripts/gen-test.sh --help`.

## Quick Reference

| Need | Reach for |
|---|---|
| Test runner | JUnit 5 (Jupiter) |
| Assertions | AssertJ |
| Mocks | Mockito |
| Parameterized | `@ParameterizedTest` |
| Async | `@Test` + `Awaitility` |
| Setup / teardown | `@BeforeEach` + `@AfterEach` |
| Real DB | Testcontainers |
| Property-based | jqwik |
| HTTP service | `MockMvc` (Spring), `WebTestClient` |

---

## JUnit 5 Basics

```java
class CalculatorTest {

  @Test
  void addsTwoPositiveNumbers() {
    assertThat(Calculator.add(2, 3)).isEqualTo(5);
  }

  @Test
  void rejectsNegativeInputs() {
    assertThatThrownBy(() -> Calculator.add(-1, 2))
        .isInstanceOf(IllegalArgumentException.class)
        .hasMessageContaining("negative");
  }
}
```

JUnit 5 is the default. Don't start new projects on JUnit 4 — they have
fundamentally different APIs.

---

## Test Names Describe Behavior

```java
// Bad
@Test void testAdd() { ... }
@Test void test1() { ... }

// Good
@Test void returnsTheSumOfTwoPositiveNumbers() { ... }
@Test void throwsWhenTheInputIsNotFinite() { ... }
```

The test name should let the developer who broke it understand the failure
without reading the body.

JUnit also supports `@DisplayName` for fully prose names:

```java
@Test
@DisplayName("returns the sum of two positive numbers")
void addPositives() { ... }
```

---

## AssertJ for Readable Assertions

JUnit's built-in assertions are fine, but AssertJ reads better and chains:

```java
import static org.assertj.core.api.Assertions.*;

assertThat(user.email()).isEqualTo("a@b");
assertThat(users)
    .hasSize(3)
    .extracting(User::email)
    .containsExactly("a@b", "c@d", "e@f");

assertThatThrownBy(() -> load("nope"))
    .isInstanceOf(NotFoundException.class)
    .hasMessageContaining("user");
```

`assertThat(x).usingRecursiveComparison().isEqualTo(y)` compares records and
nested objects field by field — handy for DTOs.

---

## Parameterized Tests

When several cases share the same code path:

```java
@ParameterizedTest
@CsvSource({
    "foo, FOO",
    ",   ''",
    "háy, HÁY",
})
void upper(String input, String expected) {
  assertThat(upper(input)).isEqualTo(expected);
}

@ParameterizedTest
@ValueSource(strings = {"", " ", "\t", "\n"})
void rejectsBlank(String input) {
  assertThatThrownBy(() -> parse(input)).isInstanceOf(ValidationException.class);
}

@ParameterizedTest
@MethodSource("scenarios")
void renders(Scenario s) {
  assertThat(render(s.input())).isEqualTo(s.expected());
}
static Stream<Scenario> scenarios() {
  return Stream.of(
      new Scenario("a", "A"),
      new Scenario("b", "B")
  );
}
```

`@ParameterizedTest` is right when cases differ only in input/output. If
they need different setup, write separate `@Test` methods.

---

## Fixtures: `@BeforeEach`, `@BeforeAll`

```java
class UserServiceTest {
  private UserService service;
  private InMemoryUserRepository repo;

  @BeforeEach
  void setUp() {
    repo = new InMemoryUserRepository();
    service = new UserService(repo);
  }

  @Test
  void createsUser() { ... }
}
```

`@BeforeEach` per test (most isolated). `@BeforeAll` once per class
(`static` method) — use for expensive setup like database containers, but
reset state in `@BeforeEach`.

Default to `@BeforeEach`. `@BeforeAll` is an optimization; it trades
cleanliness for speed.

---

## Mockito for Mocks

When a real implementation isn't practical, Mockito creates a test double:

```java
@ExtendWith(MockitoExtension.class)
class UserServiceTest {

  @Mock UserRepository repo;
  @InjectMocks UserService service;

  @Test
  void returnsUserById() {
    when(repo.findById("1")).thenReturn(Optional.of(new User("1", "a@b", false)));

    var user = service.getById("1");

    assertThat(user.email()).isEqualTo("a@b");
  }

  @Test
  void throwsWhenMissing() {
    when(repo.findById("nope")).thenReturn(Optional.empty());

    assertThatThrownBy(() -> service.getById("nope"))
        .isInstanceOf(NotFoundException.class);
  }
}
```

Order of preference for test doubles:

1. **Real** — Testcontainers for DB; real HTTP server for service tests.
2. **In-memory fake** — class implementing the same interface (cleanest).
3. **Mockito mock** — when stubbing one or two methods.
4. **Mockito spy** — wraps a real object; use sparingly.

In-memory fakes scale better than mocks. Mocks couple the test to the
implementation's interactions; fakes test against the contract.

---

## Don't Test Implementation

```java
// Bad — couples to the SQL the service emits
verify(repo).query("SELECT * FROM users WHERE id = ?", "1");

// Good — assert the observable behavior
assertThat(service.getById("1").email()).isEqualTo("a@b");
```

`verify(...)` is fine for genuine side effects (event published, metric
recorded). It's brittle when used to verify internal interactions.

---

## Testing Async Code

For `CompletableFuture`:

```java
@Test
void completesWithValue() {
  CompletableFuture<User> future = service.getAsync("1");
  assertThat(future).succeedsWithin(Duration.ofSeconds(1))
      .satisfies(u -> assertThat(u.email()).isEqualTo("a@b"));
}
```

For waiting on eventual consistency, `Awaitility`:

```java
await().atMost(5, SECONDS).until(() -> queue.size() == 1);
```

Avoid `Thread.sleep` — it makes tests slow and flaky.

---

## Testcontainers for Real Dependencies

```java
@Testcontainers
class UserRepositoryIT {

  @Container
  static PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:16");

  static DataSource dataSource;
  UserRepository repo;

  @BeforeAll
  static void setUpClass() {
    dataSource = createDataSource(postgres);
    runMigrations(dataSource);
  }

  @BeforeEach
  void setUp() {
    repo = new JdbcUserRepository(dataSource);
    truncate(dataSource, "users");
  }

  @Test
  void persistsAndFinds() {
    var user = new User("1", "a@b", false);
    repo.save(user);
    assertThat(repo.findById("1")).contains(user);
  }
}
```

Testcontainers gives you a real Postgres / Redis / Kafka in Docker for the
test run. Slower than mocks but tests the actual SQL the driver emits —
invaluable for repository / DAO tests.

---

## Spring Boot Tests

```java
@SpringBootTest
@AutoConfigureMockMvc
class UserControllerTest {

  @Autowired MockMvc mvc;
  @MockitoBean UserService service;

  @Test
  void returnsUserById() throws Exception {
    when(service.getById("1")).thenReturn(new User("1", "a@b", false));

    mvc.perform(get("/users/1"))
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.email").value("a@b"));
  }
}
```

For a slimmer slice, use `@WebMvcTest(UserController.class)` — loads only
the controller layer. For repository-only tests, `@DataJpaTest`.

---

## Property-Based Testing

For functions where a property should hold across all inputs:

```java
@Property
boolean roundTrip(@ForAll String input) {
  return decode(encode(input)).equals(input);
}
```

jqwik finds edge cases (empty strings, unicode, surrogate pairs) that
hand-written tests miss. Reserve for genuine properties — don't use it for
example-based tests.

---

## Coverage: a Floor, Not a Target

```bash
mvn test jacoco:report
```

Set a CI floor (e.g. 70 %) to prevent regressions; don't celebrate the
number. Lines covered with no assertions aren't tested.

JaCoCo's branch coverage catches some "lines covered but uninspected"
gaps:

```xml
<rule>
  <element>BUNDLE</element>
  <limits>
    <limit>
      <counter>BRANCH</counter>
      <value>COVEREDRATIO</value>
      <minimum>0.7</minimum>
    </limit>
  </limits>
</rule>
```

---

## Test Layout

```
src/main/java/com/acme/myapp/user/
  UserRepository.java
src/test/java/com/acme/myapp/user/
  UserRepositoryTest.java          // unit
  UserRepositoryIT.java            // integration (IT suffix)
```

Mirror the source tree. Suffix `*Test` for unit, `*IT` for integration.
Most Maven/Gradle plugins recognize the distinction (`mvn test` vs
`mvn verify`).

---

## Quick Reference

| Question | Default |
|---|---|
| Runner | JUnit 5 |
| Assertions | AssertJ |
| Many cases, same path | `@ParameterizedTest` |
| Mocks | Mockito; prefer in-memory fakes |
| Real DB | Testcontainers |
| Async wait | Awaitility |
| Setup | `@BeforeEach` |
| Spring web | `@WebMvcTest` + `MockMvc` |
| Property-based | jqwik |

## Related Skills

- **Error handling**: [java-error-handling](../java-error-handling/SKILL.md) for `assertThatThrownBy`.
- **Concurrency**: [java-concurrency](../java-concurrency/SKILL.md) for testing concurrent code.
- **HTTP**: [java-http](../java-http/SKILL.md) for Spring `MockMvc`.
- **Classes**: [java-classes](../java-classes/SKILL.md) for testable design.
- **Naming**: [java-naming](../java-naming/SKILL.md) for test naming.
- **Linting**: [java-linting](../java-linting/SKILL.md) for Spotless rules in tests.
