---
name: java-linting
description: Use when setting up, tuning, or troubleshooting Java linters and formatters — Spotless, Checkstyle, ErrorProne, SonarLint, NullAway, ArchUnit, pre-commit hooks, CI integration, or migrating between linter stacks. Also use when reviewing lint suppressions.
license: Apache-2.0
metadata:
  sources: "Spotless docs, Checkstyle docs, ErrorProne docs, SonarLint docs, ArchUnit docs"
allowed-tools: Bash(bash:*)
---

# Java Linting

## Available Scripts and Assets

- **`assets/spotless-pom-snippet.xml`** — Spotless Maven plugin snippet with `googleJavaFormat`, import ordering, `removeUnusedImports`, and `trimTrailingWhitespace`. Merge under `<build><plugins>`.
- **`assets/spotless-build.gradle.kts`** — Equivalent Spotless configuration for the Gradle Kotlin DSL.
- **`assets/checkstyle.xml`** — Minimal, opinionated Checkstyle config that complements google-java-format (naming, imports, Javadoc, modifier order, magic numbers, fallthrough).
- **`scripts/setup-lint.sh`** — Drops the matching Spotless snippet to stdout (Maven or Gradle, auto-detected) and copies `checkstyle.xml` into `config/checkstyle/`. Supports `--all`, `--force`. Run `bash scripts/setup-lint.sh --help`.

## The Stack

For new projects, the canonical stack is:

- **Spotless** — formatter (wraps google-java-format).
- **Checkstyle** or **PMD** — style + structural rules.
- **ErrorProne** — bug-catching at compile time.
- **NullAway** — null-safety enforcement (ErrorProne plugin).
- **ArchUnit** — architectural rules in tests.
- **SonarLint** (IDE) / **SonarQube** (CI) — broad code-smell catalog.

Don't run all five with overlapping rule sets. Pick the canonical formatter
(Spotless) and one or two analyzers.

---

## Spotless (Formatter)

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

```bash
mvn spotless:apply       # format
mvn spotless:check       # verify in CI
```

`google-java-format` is the de facto modern standard. Run on save and in
pre-commit; check in CI.

---

## Checkstyle

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-checkstyle-plugin</artifactId>
  <configuration>
    <configLocation>google_checks.xml</configLocation>
    <consoleOutput>true</consoleOutput>
    <failsOnError>true</failsOnError>
  </configuration>
  <executions>
    <execution>
      <id>checkstyle</id>
      <phase>verify</phase>
      <goals><goal>check</goal></goals>
    </execution>
  </executions>
</plugin>
```

Start with Google's `google_checks.xml`; tune from there. Useful checks
the formatter doesn't cover:

- `MissingJavadocMethod` — public methods must have Javadoc.
- `WhitespaceAround` — operator spacing edge cases.
- `MagicNumber` — name your constants.
- `CyclomaticComplexity` — method complexity ceiling.
- `EmptyCatchBlock` — no empty `catch`.

---

## ErrorProne

ErrorProne is a compile-time bug pattern detector. It catches things like:

- Comparing `String` with `==`.
- Mutable enum members.
- Missing `super.toString()` calls.
- Unused exception thrown from a constructor.
- Missing braces in `if` bodies.

```xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-compiler-plugin</artifactId>
  <configuration>
    <compilerArgs>
      <arg>-XDcompilePolicy=simple</arg>
      <arg>-Xplugin:ErrorProne -XepDisableWarningsInGeneratedCode</arg>
    </compilerArgs>
    <annotationProcessorPaths>
      <path>
        <groupId>com.google.errorprone</groupId>
        <artifactId>error_prone_core</artifactId>
        <version>2.27.1</version>
      </path>
    </annotationProcessorPaths>
  </configuration>
</plugin>
```

The default check set catches real bugs. Promote individual checks to
errors with `-Xep:CheckName:ERROR`.

---

## NullAway

NullAway is an ErrorProne plugin that enforces nullness annotations
(`@Nullable`, JSpecify `@NullMarked`):

```xml
<arg>-Xplugin:ErrorProne -Xep:NullAway:ERROR -XepOpt:NullAway:AnnotatedPackages=com.acme</arg>
```

Annotate one package; NullAway treats everything in it as non-null by
default, flagging unchecked dereferences. Combine with `@Nullable` for
fields and parameters where null is legitimate.

---

## ArchUnit (Architectural Rules)

Encode architecture rules as tests:

```java
class ArchitectureTest {

  private static final JavaClasses classes = new ClassFileImporter()
      .importPackages("com.acme.myapp");

  @Test
  void controllersOnlyCallServices() {
    classes()
        .that().resideInAPackage("..controller..")
        .should().onlyDependOnClassesThat()
        .resideInAnyPackage("..service..", "..dto..", "java..", "..springframework..")
        .check(classes);
  }

  @Test
  void noCyclesBetweenFeatures() {
    slices().matching("com.acme.myapp.(*)..")
        .should().beFreeOfCycles()
        .check(classes);
  }

  @Test
  void noFieldInjection() {
    noFields()
        .should().beAnnotatedWith(Autowired.class)
        .check(classes);
  }
}
```

These tests fail when an architectural rule is violated — turning what's
usually a code-review gotcha into a compile-time check.

---

## SonarLint / SonarQube

SonarLint runs in the IDE; SonarQube on the build server. Rich rule
catalog covering bugs, vulnerabilities, code smells. Most useful as the
"final-pass" linter that surfaces issues the others missed.

In CI:

```yaml
- run: mvn sonar:sonar -Dsonar.host.url=$SONAR_URL -Dsonar.login=$SONAR_TOKEN
```

Don't let SonarQube become a meta-bureaucracy — pick the high-value rules
(bug / vulnerability), accept that the "code smell" set is opinionated and
fight only the false positives that matter.

---

## OWASP Dependency Check

```xml
<plugin>
  <groupId>org.owasp</groupId>
  <artifactId>dependency-check-maven</artifactId>
  <configuration>
    <failBuildOnCVSS>7</failBuildOnCVSS>
  </configuration>
  <executions>
    <execution>
      <goals><goal>check</goal></goals>
    </execution>
  </executions>
</plugin>
```

Treat high-severity vulnerabilities as a build break. See
[java-security](../java-security/SKILL.md).

---

## Pre-Commit Hooks

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer

  - repo: local
    hooks:
      - id: spotless
        name: spotless
        entry: mvn spotless:apply
        language: system
        types: [java]
        pass_filenames: false
```

Don't block commits on a full project lint — slow hooks get skipped with
`--no-verify`. Aim for under 5 seconds on a typical change.

---

## CI Integration

```yaml
- run: mvn spotless:check
- run: mvn compile             # ErrorProne runs as a compile plugin
- run: mvn checkstyle:check
- run: mvn test                # includes ArchUnit
- run: mvn dependency-check:check
```

Each check is a separate step so failures are clearly attributed. If you
use Gradle, the equivalents are `./gradlew spotlessCheck checkstyleMain
errorprone test dependencyCheckAnalyze`.

---

## Suppressing a Rule

Suppression should have a reason — a comment for stylistic ignores, an
annotation for stronger ones:

```java
@SuppressWarnings("unchecked")  // generic cast safe by construction
List<User> users = (List<User>) raw;

@SuppressWarnings("PMD.UseTryWithResources")  // legacy API doesn't implement AutoCloseable
InputStream in = legacy.open();
try { ... } finally { in.close(); }
```

For Checkstyle:

```java
// CHECKSTYLE.OFF: MagicNumber  -- math formula constants are fine inline
double area = 0.5 * base * height;
// CHECKSTYLE.ON: MagicNumber
```

Open suppressions accumulate technical debt. Periodically grep:

```bash
grep -rn '@SuppressWarnings\|CHECKSTYLE.OFF\|noqa' src/ | wc -l
```

Trend it down.

---

## Editor Integration

- **IntelliJ IDEA** — built-in inspections cover most of what Checkstyle
  does. Install Spotless plugin for one-click formatting. SonarLint plugin
  surfaces Sonar's rules in-editor.
- **VS Code** — Java Extension Pack + Checkstyle for Java + SonarLint.

Real-time editor feedback closes the loop — bugs caught while typing don't
reach the PR.

---

## Migrating from Older Stacks

`mvn site` -> Maven reporting plugins -> static-analysis dashboards used to
be the default. Modern Java projects prefer CI-integrated checks that fail
the build rather than reports nobody reads.

If you inherit a project with `findbugs`, switch to `spotbugs` (the
maintained fork) and add `findsecbugs-plugin` for security.

---

## Quick Reference

| Tool | Role |
|---|---|
| Spotless | Formatting |
| Checkstyle (or PMD) | Style + structural rules |
| ErrorProne | Compile-time bug detection |
| NullAway | Null safety |
| ArchUnit | Architectural invariants in tests |
| SonarLint / SonarQube | Broad analysis |
| SpotBugs + FindSecBugs | Security smells |
| OWASP Dependency Check | Vulnerable deps |
| pre-commit | Local enforcement |

## Related Skills

- **Style core**: [java-style-core](../java-style-core/SKILL.md) for what Spotless enforces.
- **Naming**: [java-naming](../java-naming/SKILL.md) for what Checkstyle's naming rules check.
- **Packages**: [java-packages](../java-packages/SKILL.md) for what ArchUnit constrains.
- **Types**: [java-types](../java-types/SKILL.md) for null annotations NullAway reads.
- **Security**: [java-security](../java-security/SKILL.md) for SpotBugs and dependency check.
- **Code review**: [java-code-review](../java-code-review/SKILL.md) for when to push back on suppressions.
