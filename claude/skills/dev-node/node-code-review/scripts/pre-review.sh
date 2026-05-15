#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Run automated pre-review checks on a Node.js / TS project

USAGE
    bash $SCRIPT_NAME [options]

DESCRIPTION
    Runs Prettier --check, ESLint, TypeScript --noEmit, and (if installed)
    npm audit against the current project. Reports per-stage status with
    a final pass/fail summary.

    Exits 0 if all checks pass, 1 if any failed, 2 on error.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --json            Output results as JSON
    --no-audit        Skip npm audit (offline / restricted environments)
    --pnpm            Use pnpm instead of npm
    --yarn            Use yarn instead of npm

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME --json
    bash $SCRIPT_NAME --no-audit --pnpm
EOF
}

JSON_OUTPUT=false
RUN_AUDIT=true
PKG="npm"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--version) echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        --json)       JSON_OUTPUT=true; shift ;;
        --no-audit)   RUN_AUDIT=false; shift ;;
        --pnpm)       PKG="pnpm"; shift ;;
        --yarn)       PKG="yarn"; shift ;;
        *)            echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

[[ -f package.json ]] || { echo "error: no package.json in $(pwd)" >&2; exit 2; }

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

# Prettier
if command -v npx &>/dev/null; then
    STAGES+=("$(run_stage prettier npx --no-install prettier --check . || true)")
fi

# ESLint
if [[ -f eslint.config.mjs || -f eslint.config.js || -f .eslintrc.cjs || -f .eslintrc.json ]]; then
    STAGES+=("$(run_stage eslint npx --no-install eslint . || true)")
else
    STAGES+=("$(printf 'eslint\tskip\tno ESLint config in repo')")
fi

# TypeScript
if [[ -f tsconfig.json ]]; then
    STAGES+=("$(run_stage typecheck npx --no-install tsc --noEmit || true)")
else
    STAGES+=("$(printf 'typecheck\tskip\tno tsconfig.json')")
fi

# Audit
if $RUN_AUDIT; then
    case "$PKG" in
        npm)  STAGES+=("$(run_stage audit npm audit --omit=dev --audit-level=high || true)") ;;
        pnpm) STAGES+=("$(run_stage audit pnpm audit --prod --audit-level high || true)") ;;
        yarn) STAGES+=("$(run_stage audit yarn npm audit --severity high --groups dependencies || true)") ;;
    esac
else
    STAGES+=("$(printf 'audit\tskip\t--no-audit')")
fi

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
