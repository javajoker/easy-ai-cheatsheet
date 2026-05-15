#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Run automated pre-review checks on a Java project

USAGE
    bash $SCRIPT_NAME [options]

DESCRIPTION
    Runs Spotless check, compile (with ErrorProne if configured), Checkstyle,
    and test against the current project. Auto-detects Maven vs Gradle.

    Exits 0 if all checks pass, 1 if any failed, 2 on error.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --json            Output results as JSON
    --skip-test       Skip running tests (faster pre-review)
    --maven           Force Maven
    --gradle          Force Gradle

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME --json
    bash $SCRIPT_NAME --skip-test
EOF
}

JSON_OUTPUT=false
RUN_TEST=true
BUILD_TOOL="auto"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--version) echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        --json)       JSON_OUTPUT=true; shift ;;
        --skip-test)  RUN_TEST=false; shift ;;
        --maven)      BUILD_TOOL="maven"; shift ;;
        --gradle)     BUILD_TOOL="gradle"; shift ;;
        *)            echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ "$BUILD_TOOL" == "auto" ]]; then
    if [[ -f pom.xml ]]; then BUILD_TOOL="maven"
    elif [[ -f build.gradle || -f build.gradle.kts ]]; then BUILD_TOOL="gradle"
    else
        echo "error: no pom.xml or build.gradle.kts found" >&2
        exit 2
    fi
fi

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/}"; s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

run_stage() {
    local name="$1"; shift
    local cmd=("$@")
    local out status
    if out=$("${cmd[@]}" 2>&1); then
        status="pass"
    else
        status="fail"
    fi
    printf '%s\t%s\t%s\n' "$name" "$status" "$out"
}

STAGES=()

case "$BUILD_TOOL" in
    maven)
        if ! command -v mvn &>/dev/null; then
            echo "error: mvn not on PATH" >&2; exit 2
        fi
        STAGES+=("$(run_stage spotless mvn -B -q spotless:check || true)")
        STAGES+=("$(run_stage compile mvn -B -q compile || true)")
        if [[ -f config/checkstyle/checkstyle.xml ]] || grep -q checkstyle pom.xml 2>/dev/null; then
            STAGES+=("$(run_stage checkstyle mvn -B -q checkstyle:check || true)")
        else
            STAGES+=("$(printf 'checkstyle\tskip\tnot configured')")
        fi
        if $RUN_TEST; then
            STAGES+=("$(run_stage test mvn -B -q test || true)")
        else
            STAGES+=("$(printf 'test\tskip\t--skip-test')")
        fi
        ;;
    gradle)
        GRADLE="./gradlew"
        if [[ ! -x "$GRADLE" ]]; then GRADLE="gradle"; fi
        STAGES+=("$(run_stage spotless $GRADLE spotlessCheck --no-daemon -q || true)")
        STAGES+=("$(run_stage compile $GRADLE compileJava --no-daemon -q || true)")
        if grep -q checkstyle build.gradle build.gradle.kts 2>/dev/null; then
            STAGES+=("$(run_stage checkstyle $GRADLE checkstyleMain --no-daemon -q || true)")
        else
            STAGES+=("$(printf 'checkstyle\tskip\tnot configured')")
        fi
        if $RUN_TEST; then
            STAGES+=("$(run_stage test $GRADLE test --no-daemon -q || true)")
        else
            STAGES+=("$(printf 'test\tskip\t--skip-test')")
        fi
        ;;
esac

FAILED=0
for entry in "${STAGES[@]}"; do
    status=$(printf '%s' "$entry" | awk -F'\t' '{print $2}')
    [[ "$status" == "fail" ]] && FAILED=1
done

if $JSON_OUTPUT; then
    echo "{"
    echo '  "stages": ['
    first=true
    for entry in "${STAGES[@]}"; do
        name=$(printf '%s' "$entry" | awk -F'\t' '{print $1}')
        status=$(printf '%s' "$entry" | awk -F'\t' '{print $2}')
        output=$(printf '%s' "$entry" | awk -F'\t' '{for(i=3;i<=NF;i++) printf "%s%s",(i==3?"":"\t"),$i}')
        $first || echo ","
        first=false
        printf '    {"name":"%s","status":"%s","output":"%s"}' \
            "$name" "$status" "$(json_escape "$output")"
    done
    echo ""
    echo "  ],"
    printf '  "passed": %s\n' "$([[ $FAILED -eq 0 ]] && echo true || echo false)"
    echo "}"
else
    for entry in "${STAGES[@]}"; do
        name=$(printf '%s' "$entry" | awk -F'\t' '{print $1}')
        status=$(printf '%s' "$entry" | awk -F'\t' '{print $2}')
        output=$(printf '%s' "$entry" | awk -F'\t' '{for(i=3;i<=NF;i++) printf "%s%s",(i==3?"":"\t"),$i}')
        echo "=== $name ==="
        if [[ "$status" == "skip" ]]; then
            echo "Skipped: $output"
        elif [[ "$status" == "pass" ]]; then
            echo "OK"
        else
            echo "$output"
        fi
        echo ""
    done
    if [[ $FAILED -eq 1 ]]; then
        echo "Pre-review checks FAILED — fix issues before manual review."
    else
        echo "All pre-review checks passed."
    fi
fi

exit $FAILED
