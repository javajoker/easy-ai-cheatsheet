#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Check Node.js / TypeScript code for common error-handling anti-patterns

USAGE
    bash $SCRIPT_NAME [options] [path]

DESCRIPTION
    Scans .ts and .js source files for error-handling anti-patterns:
      - throw of a non-Error (string, plain object, number)
      - catch-and-rethrow with no transformation
      - log-and-throw / log-and-return (handle errors once)
      - empty catch blocks

    Exits 0 if no issues found, 1 if anti-patterns detected, 2 on error.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --json            Output as JSON

ARGUMENTS
    path              Directory or file to check (default: ./src)

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME ./packages/server/src
    bash $SCRIPT_NAME --json src
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

TARGET="${TARGET:-./src}"

if [[ ! -e "$TARGET" ]]; then
    echo "error: path not found: $TARGET" >&2
    exit 2
fi

json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"; s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"; s="${s//$'\r'/}"; s="${s//$'\t'/\\t}"
    printf '%s' "$s"
}

find_files() {
    local t="$1"
    if [[ -f "$t" ]]; then
        echo "$t"
    else
        find "$t" \
            \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.mjs' -o -name '*.cjs' \) \
            ! -path '*/node_modules/*' ! -path '*/dist/*' ! -path '*/build/*' \
            ! -path '*/coverage/*' ! -path '*/.next/*' ! -name '*.d.ts' \
            ! -name '*.test.ts' ! -name '*.spec.ts' ! -name '*.test.js' ! -name '*.spec.js' \
            2>/dev/null
    fi
}

FINDINGS=()

add_finding() {
    FINDINGS+=("$1:$2|$3|$4")
}

check_throw_non_error() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # throw "string literal"
        if [[ "$line" =~ throw[[:space:]]+[\'\"\`] ]]; then
            add_finding "$file" "$line_num" "throw-non-error" \
                "throwing a string; wrap in new Error(...) so callers get a stack trace"
        fi
        # throw { ... } plain object
        if [[ "$line" =~ throw[[:space:]]+\{ ]]; then
            add_finding "$file" "$line_num" "throw-non-error" \
                "throwing a plain object; subclass Error so instanceof matching works"
        fi
        # throw number / boolean
        if [[ "$line" =~ throw[[:space:]]+(true|false|[0-9]) ]]; then
            add_finding "$file" "$line_num" "throw-non-error" \
                "throwing a non-Error primitive; throw an Error subclass"
        fi
    done < "$file"
}

check_empty_catch() {
    local file="$1" line_num=0 prev_line=""
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # catch (...) { } or catch (...) { /* comment-only */ }
        if [[ "$line" =~ catch[[:space:]]*\([^\)]*\)[[:space:]]*\{[[:space:]]*\}[[:space:]]*$ ]]; then
            add_finding "$file" "$line_num" "empty-catch" \
                "empty catch block silently swallows errors; at minimum log them"
        fi
        prev_line="$line"
    done < "$file"
}

check_catch_rethrow() {
    local file="$1"
    awk '
    /catch[[:space:]]*\([[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)?[[:space:]]*\)[[:space:]]*\{[[:space:]]*$/ {
        in_catch = 1; depth = 1; start_line = NR; var = $0;
        sub(/.*catch[[:space:]]*\(/, "", var); sub(/\).*/, "", var);
        gsub(/[[:space:]]/, "", var); body = "";
        next
    }
    in_catch {
        body = body "\n" $0
        n = gsub(/\{/, "{")
        m = gsub(/\}/, "}")
        depth += n - m
        if (depth <= 0) {
            # Examine body for "throw err" only
            stripped = body
            gsub(/[[:space:]]/, "", stripped)
            expected = "throw" var ";}"
            expected2 = "throw" var "}"
            if (stripped == expected || stripped == expected2) {
                print FILENAME ":" start_line "|catch-rethrow|catch-and-rethrow with no transformation; remove the try/catch"
            }
            in_catch = 0; body = ""
        }
    }
    ' "$file" | while IFS= read -r out; do
        if [[ -n "$out" ]]; then
            FINDINGS+=("$out")
        fi
    done
}

check_log_and_throw() {
    local file="$1" line_num=0
    declare -a window=()
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        window+=("$line")
        if [[ ${#window[@]} -gt 4 ]]; then
            window=("${window[@]:1}")
        fi
        # current line throws or returns the caught error
        if [[ "$line" =~ ^[[:space:]]*throw[[:space:]] ]] || \
           [[ "$line" =~ ^[[:space:]]*return.*err ]]; then
            for prev in "${window[@]}"; do
                if [[ "$prev" =~ (log|logger|console)\.(error|warn|info|fatal) ]]; then
                    add_finding "$file" "$line_num" "log-and-throw" \
                        "error logged then thrown/returned; handle errors once (log at the boundary)"
                    break
                fi
            done
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
        echo "No TS/JS files found in: $TARGET"
    fi
    exit 0
fi

for file in "${FILES[@]}"; do
    check_throw_non_error "$file"
    check_empty_catch "$file"
    check_log_and_throw "$file"
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
        echo "No error-handling anti-patterns found."
        exit 0
    fi
    echo "Error-handling anti-patterns found:"
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
