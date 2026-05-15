#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Check Python public API for missing docstrings

USAGE
    bash $SCRIPT_NAME [options] [path]

DESCRIPTION
    Scans .py source files for public functions (no leading _) and public
    classes that lack a docstring as the first statement of the body.

    Skips test files and private members.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --json            Output as JSON
    --include-private Also check leading-underscore functions/classes

ARGUMENTS
    path              Directory or file to check (default: ./src or .)

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME app/
    bash $SCRIPT_NAME --json myapp
    bash $SCRIPT_NAME --include-private myapp
EOF
}

JSON_OUTPUT=false
INCLUDE_PRIVATE=false
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)         usage; exit 0 ;;
        -v|--version)      echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        --json)            JSON_OUTPUT=true; shift ;;
        --include-private) INCLUDE_PRIVATE=true; shift ;;
        -*)                echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)                 TARGET="$1"; shift ;;
    esac
done

if [[ -z "$TARGET" ]]; then
    if [[ -d ./src ]]; then TARGET="./src"
    else TARGET="."
    fi
fi
[[ -e "$TARGET" ]] || { echo "error: path not found: $TARGET" >&2; exit 2; }

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/}"; s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

find_files() {
    local t="$1"
    if [[ -f "$t" ]]; then echo "$t"; return; fi
    find "$t" -name '*.py' \
        ! -path '*/.venv/*' ! -path '*/venv/*' ! -path '*/.tox/*' \
        ! -path '*/__pycache__/*' ! -path '*/node_modules/*' \
        ! -path '*/dist/*' ! -path '*/build/*' \
        ! -name 'test_*.py' ! -name '*_test.py' 2>/dev/null
}

FINDINGS=()
add_finding() { FINDINDS_TEMP=("$1:$2|$3|$4"); FINDINGS+=("$1:$2|$3|$4"); }

is_public_name() {
    local name="$1"
    $INCLUDE_PRIVATE && return 0
    [[ "$name" =~ ^__.*__$ ]] && return 0      # dunders
    [[ "$name" != _* ]]
}

check_file() {
    local file="$1"
    local line_num=0 looking=false pending_kind="" pending_name="" pending_line=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Match `def name` / `async def name` / `class name`
        if [[ "$line" =~ ^[[:space:]]*(async[[:space:]]+)?(def|class)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
            pending_kind="${BASH_REMATCH[2]}"
            pending_name="${BASH_REMATCH[3]}"
            if is_public_name "$pending_name"; then
                pending_line=$line_num
                looking=true
            else
                looking=false
            fi
            continue
        fi

        if $looking; then
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue
            [[ "$line" =~ ^[[:space:]]*# ]] && continue

            # Strip leading whitespace
            local stripped="${line#"${line%%[![:space:]]*}"}"

            # Check for docstring opening token
            if [[ "$stripped" == \"\"\"* ]] \
               || [[ "$stripped" == "'''"* ]] \
               || [[ "$stripped" == \"* ]] \
               || [[ "$stripped" == "'"* ]]; then
                looking=false
                continue
            fi

            add_finding "$file" "$pending_line" "missing-docstring" \
                "public $pending_kind $pending_name has no docstring"
            looking=false
        fi
    done < "$file"
}

FILES=()
while IFS= read -r f; do
    [[ -n "$f" ]] && FILES+=("$f")
done < <(find_files "$TARGET")

if [[ ${#FILES[@]} -eq 0 ]]; then
    if $JSON_OUTPUT; then
        echo '{"findings":[],"count":0,"status":"no_files"}'
    else
        echo "No Python files found in: $TARGET"
    fi
    exit 0
fi

for file in "${FILES[@]}"; do
    check_file "$file"
done

TOTAL=${#FINDINGS[@]}

if $JSON_OUTPUT; then
    echo "{"
    echo '  "findings": ['
    first=true
    for entry in "${FINDINGS[@]+"${FINDINGS[@]}"}"; do
        IFS='|' read -r location rule message <<< "$entry"
        file="${location%:*}"; line="${location##*:}"
        $first || echo ","
        first=false
        printf '    {"file":"%s","line":%s,"rule":"%s","message":"%s"}' \
            "$(json_escape "$file")" "$line" "$(json_escape "$rule")" "$(json_escape "$message")"
    done
    echo ""
    echo "  ],"
    printf '  "total": %d\n' "$TOTAL"
    echo "}"
else
    if [[ $TOTAL -eq 0 ]]; then
        echo "All public APIs have docstrings."
        exit 0
    fi
    echo "Missing docstrings:"
    echo ""
    for entry in "${FINDINGS[@]}"; do
        IFS='|' read -r location rule message <<< "$entry"
        printf "  %s  [%s] %s\n" "$location" "$rule" "$message"
    done
    echo ""
    echo "Total: $TOTAL finding(s)"
    echo ""
    echo "For richer enforcement, add ruff rules: --select D (pydocstyle)."
fi

[[ $TOTAL -gt 0 ]] && exit 1
exit 0
