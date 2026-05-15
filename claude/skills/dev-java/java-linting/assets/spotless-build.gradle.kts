// Spotless Gradle plugin snippet (Kotlin DSL).
// Add to plugins { } block of build.gradle.kts; then run
//   ./gradlew spotlessApply
//   ./gradlew spotlessCheck

plugins {
    id("com.diffplug.spotless") version "6.25.0"
}

spotless {
    java {
        target("src/**/*.java")
        googleJavaFormat("1.22.0")
        removeUnusedImports()
        importOrder("java", "javax", "org", "com", "")
        trimTrailingWhitespace()
        endWithNewline()
    }
    kotlinGradle {
        target("*.gradle.kts")
        ktlint("1.2.1")
    }
    format("misc") {
        target("*.md", "*.yml", "*.yaml", ".gitignore")
        trimTrailingWhitespace()
        endWithNewline()
    }
}

// Verify formatting in CI.
tasks.named("check") {
    dependsOn("spotlessCheck")
}
