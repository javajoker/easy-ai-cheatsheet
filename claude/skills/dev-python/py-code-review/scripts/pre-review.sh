#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Run automated pre-review checks on a Python project

USAGE
    bash $SCRIPT_NAME [options]

DESCRIPTION
    Runs ruff format --check, ruff check, mypy, and (if available)
    pip-audit / safety check. Reports per-stage status with a final
    pass/fail summary.

    Exits 0 if all checks pass, 1 if any failed, 2 on error.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --json            Output results as JSON
    --no-audit        Skip vulnerability scan (offline / restricted)
    --skip-mypy       Skip type-check (large repos may run it separately)
    --src DIR         Source directory for mypy (default: ./src or .)

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME --json
    bash $SCRIPT_NAME --no-audit --skip-mypy
    bash $SCRIPT_NAME --src myapp
EOF
}

JSON_OUTPUT=false
RUN_AUDIT=true
RUN_MYPY=true
SRC_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--version) echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        --json)       JSON_OUTPUT=true; shift ;;
        --no-audit)   RUN_AUDIT=false; shift ;;
        --skip-mypy)  RUN_MYPY=false; shift ;;
        --src)        SRC_DIR="${2:?--src needs path}"; shift 2 ;;
        *)            echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ -z "$SRC_DIR" ]]; then
    if [[ -d ./src ]]; then SRC_DIR="./src"
    else SRC_DIR="."
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
    if ! command -v "${cmd[0]}" &>/dev/null; then
        printf '%s\tskip\t%s not installed\n' "$name" "${cmd[0]}"
        return
    fi
    if out=$("${cmd[@]}" 2>&1); then
        status="pass"
    else
        status="fail"
    fi
    printf '%s\t%s\t%s\n' "$name" "$status" "$out"
}

STAGES=()

STAGES+=("$(run_stage ruff-format ruff format --check . || true)")
STAGES+=("$(run_stage ruff ruff check . || true)")

if $RUN_MYPY; then
    STAGES+=("$(run_stage mypy mypy "$SRC_DIR" || true)")
else
    STAGES+=("$(printf 'mypy\tskip\t--skip-mypy')")
fi

if $RUN_AUDIT; then
    if command -v pip-audit &>/dev/null; then
        STAGES+=("$(run_stage pip-audit pip-audit || true)")
    elif command -v safety &>/dev/null; then
        STAGES+=("$(run_stage safety safety check --json || true)")
    else
        STAGES+=("$(printf 'audit\tskip\tneither pip-audit nor safety installed')")
    fi
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
