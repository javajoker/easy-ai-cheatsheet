# Formatting Reference

## Tooling Decision

Run a formatter. The canonical choice is **google-java-format** via
**Spotless**. It is opinionated, mature, and ships as a Maven and Gradle
plugin.

```xml
<!-- pom.xml -->
<plugin>
  <groupId>com.diffplug.spotless</groupId>
  <artifactId>spotless-maven-plugin</artifactId>
  <version>2.43.0</version>
  <configuration>
    <java>
      <googleJavaFormat>
        <version>1.22.0</version>
      </googleJavaFormat>
      <removeUnusedImports/>
      <importOrder>
        <order>java,javax,org,com,</order>
      </importOrder>
    </java>
  </configuration>
  <executions>
    <execution>
      <goals><goal>check</goal></goals>
    </execution>
  </executions>
</plugin>
```

```kotlin
// build.gradle.kts
plugins {
    id("com.diffplug.spotless") version "6.25.0"
}

spotless {
    java {
        googleJavaFormat("1.22.0")
        removeUnusedImports()
        importOrder("java", "javax", "org", "com", "")
    }
}
```

Run on save in editors. Pre-commit hook on touched files. Fail CI on
violations.

```bash
mvn spotless:apply       # format
mvn spotless:check       # verify in CI
./gradlew spotlessApply
./gradlew spotlessCheck
```

## Indent and Braces

| Element | Google Java Style |
|---|---|
| Indent | 2 spaces |
| Continuation indent | +4 spaces |
| Brace style | K&R (opening brace on same line) |
| Tab | Never |
| `else` / `catch` | Same line as `}` |

Many older Java codebases use 4-space indent (AOSP). Either is fine —
google-java-format defaults to 2 spaces; the `AOSP` flavour uses 4. Pick
once; commit the choice; stop debating.

## Line Length

Google Java Style: 100 columns. Common alternatives are 80 (legacy) and
120 (wider). google-java-format hard-wraps at 100 — adjust source to fit,
don't change the formatter.

```java
// Bad — long chain
List<String> result = users.stream().filter(u -> u.isActive() && u.age() > 18).map(User::email).toList();

// Good — let the formatter wrap
List<String> result = users.stream()
    .filter(u -> u.isActive() && u.age() > 18)
    .map(User::email)
    .toList();
```

## Imports

Order: `java`, `javax`, `org`, `com`, then everything else. Inside a group,
sort alphabetically. No wildcard imports.

```java
// Good
import java.util.List;
import java.util.Map;

import javax.sql.DataSource;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.acme.myapp.user.User;
```

Spotless's `importOrder` directive enforces this. The formatter also
removes unused imports if `removeUnusedImports()` is on.

## Modifier Order

Modifiers go in the canonical JLS order:

```java
public protected private abstract default static final transient volatile synchronized native strictfp
```

Most often: `public static final`, not `final public static`. Spotless
enforces.

## Annotation Placement

| Where | Style |
|---|---|
| Type / method / field | One per line, above |
| Parameter / local | Inline with the declaration |

```java
@Override
@SuppressWarnings("unchecked")
public List<User> activeUsers() { ... }

void handle(@NonNull String id) { ... }
```

## Trailing Whitespace and Final Newline

- No trailing whitespace.
- End of file: exactly one newline.

`.editorconfig` covers what the formatter doesn't:

```
root = true

[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true

[*.java]
indent_style = space
indent_size = 2
```

## CI Check

```yaml
- name: Spotless check
  run: mvn -B spotless:check

# Or for Gradle
- name: Spotless check
  run: ./gradlew spotlessCheck --no-daemon
```

If Spotless finds unformatted files, fail the build. Local pre-commit hook
prevents the bad commit in the first place.

## Migrating to google-java-format

The output is opinionated; the first PR that runs `spotless:apply` across
an established codebase will be a big diff. Land it as a single commit
with no logic changes. Future PRs touch only the lines they care about.

For projects on Checkstyle's `google_checks.xml` already, google-java-format
output passes the formatter-relevant rules.
