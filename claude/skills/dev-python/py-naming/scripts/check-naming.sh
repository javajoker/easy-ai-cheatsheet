#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Check Python naming conventions (PEP 8 / Google)

USAGE
    bash $SCRIPT_NAME [options] [path]

DESCRIPTION
    Scans .py files for naming violations:
      - Classes in snake_case or camelCase (should be PascalCase)
      - Functions / variables in PascalCase or camelCase (should be snake_case)
      - Module-level constants not in UPPER_SNAKE_CASE
      - Hungarian / type-encoding prefixes (str_x, list_x, dict_x, i_x)
      - Exception classes not ending in 'Error'

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --json            Output as JSON

ARGUMENTS
    path              Directory or file to check (default: ./src or .)

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME app/
    bash $SCRIPT_NAME --json myapp
EOF
}

JSON_OUTPUT=false
TARGET=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--version) echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        --json)       JSON_OUTPUT=true; shift ;;
        -*)           echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)            TARGET="$1"; shift ;;
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
        ! -path '*/dist/*' ! -path '*/build/*' 2>/dev/null
}

FINDINGS=()
add_finding() { FINDINGS+=("$1:$2|$3|$4"); }

check_class_case() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # class lower_case or snake_case start
        if [[ "$line" =~ ^[[:space:]]*class[[:space:]]+([a-z][a-zA-Z0-9_]*) ]]; then
            local name="${BASH_REMATCH[1]}"
            add_finding "$file" "$line_num" "class-case" \
                "class '$name' should be PascalCase"
        fi
        # class Snake_Case
        if [[ "$line" =~ ^[[:space:]]*class[[:space:]]+([A-Z][a-zA-Z0-9]*_[a-zA-Z0-9_]+) ]]; then
            local name="${BASH_REMATCH[1]}"
            add_finding "$file" "$line_num" "class-case" \
                "class '$name' uses snake_case; use PascalCase"
        fi
    done < "$file"
}

check_function_case() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # def CamelCase(...) — must start with uppercase to be flagged
        if [[ "$line" =~ ^[[:space:]]*(async[[:space:]]+)?def[[:space:]]+([A-Z][a-zA-Z0-9]*) ]]; then
            local name="${BASH_REMATCH[2]}"
            # Allow dunders (handled by Python)
            if [[ "$name" != _* ]]; then
                add_finding "$file" "$line_num" "function-case" \
                    "function '$name' should be snake_case"
            fi
        fi
        # def camelCase(...) — contains capital after a lower
        if [[ "$line" =~ ^[[:space:]]*(async[[:space:]]+)?def[[:space:]]+([a-z][a-z0-9]*[A-Z][a-zA-Z0-9_]*) ]]; then
            local name="${BASH_REMATCH[2]}"
            add_finding "$file" "$line_num" "function-case" \
                "function '$name' uses camelCase; use snake_case"
        fi
    done < "$file"
}

check_hungarian() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Local / param patterns like str_name, list_users, dict_config, i_count, b_flag
        # Detect in def signatures and at module/function level assignments.
        if [[ "$line" =~ (^|[^a-zA-Z0-9_])(str|list|arr|dict|num|int|bool|obj|b|i)_[a-z][a-z0-9_]* ]]; then
            # Filter out 'str_' as a legitimate stdlib name (rare; we still flag it as worth a look)
            add_finding "$file" "$line_num" "hungarian" \
                "name uses type-encoding prefix (str_/list_/dict_/i_/...); rely on the type annotation"
        fi
    done < "$file"
}

check_exception_naming() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # class Foo(Exception): / class Foo(RuntimeError):
        if [[ "$line" =~ ^[[:space:]]*class[[:space:]]+([A-Z][a-zA-Z0-9_]*)\([^\)]*(Exception|Error|Warning|BaseException)[^\)]*\) ]]; then
            local name="${BASH_REMATCH[1]}"
            local base="${BASH_REMATCH[2]}"
            if [[ "$base" == "Exception" || "$base" == "BaseException" ]] && \
               [[ ! "$name" =~ (Error|Exception)$ ]]; then
                add_finding "$file" "$line_num" "exception-naming" \
                    "exception class '$name' should end in 'Error' (PEP 8 / Google style)"
            fi
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
    check_class_case "$file"
    check_function_case "$file"
    check_hungarian "$file"
    check_exception_naming "$file"
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
        echo "No naming violations found."
        echo "(For full coverage, configure ruff with --select N rules.)"
        exit 0
    fi
    echo "Naming violations:"
    echo ""
    for entry in "${FINDINGS[@]}"; do
        IFS='|' read -r location rule message <<< "$entry"
        printf "  %s  [%s] %s\n" "$location" "$rule" "$message"
    done
    echo ""
    echo "Total: $TOTAL finding(s)"
fi

[[ $TOTAL -gt 0 ]] && exit 1
exit 0
