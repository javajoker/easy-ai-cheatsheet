#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Check Node.js / TypeScript exported APIs for missing TSDoc

USAGE
    bash $SCRIPT_NAME [options] [path]

DESCRIPTION
    Scans .ts and .tsx source files for exported declarations
    (function, class, interface, type, const) that lack a TSDoc comment
    immediately above. Skips test files and .d.ts.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --json            Output as JSON

ARGUMENTS
    path              Directory or file to check (default: ./src)

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME src/lib
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
    find "$t" \
        \( -name '*.ts' -o -name '*.tsx' \) \
        ! -path '*/node_modules/*' ! -path '*/dist/*' ! -path '*/build/*' \
        ! -path '*/coverage/*' ! -name '*.d.ts' \
        ! -name '*.test.ts' ! -name '*.spec.ts' \
        ! -name '*.test.tsx' ! -name '*.spec.tsx' 2>/dev/null
}

FINDINGS=()
add_finding() { FINDINGS+=("$1:$2|$3|$4"); }

check_file() {
    local file="$1"
    local line_num=0 prev_was_doc=false prev_was_comment_end=false
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Track if the previous non-blank line ended a /** ... */ block
        if [[ "$line" =~ ^[[:space:]]*$ ]]; then
            : # blank, preserve prev_was_doc
        elif [[ "$line" =~ \*/[[:space:]]*$ ]]; then
            prev_was_doc=true
            continue
        elif [[ "$line" =~ ^[[:space:]]*// ]] || [[ "$line" =~ ^[[:space:]]*\* ]]; then
            # Plain comments don't count as TSDoc
            continue
        elif [[ "$line" =~ ^[[:space:]]*export[[:space:]]+(default[[:space:]]+)?(async[[:space:]]+)?(function|class|interface|type|enum|const|let) ]]; then
            if ! $prev_was_doc; then
                # Extract symbol kind and name
                local kind name
                if [[ "$line" =~ export[[:space:]]+(default[[:space:]]+)?(async[[:space:]]+)?(function)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                    kind="function"; name="${BASH_REMATCH[4]}"
                elif [[ "$line" =~ export[[:space:]]+(default[[:space:]]+)?(abstract[[:space:]]+)?(class)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                    kind="class"; name="${BASH_REMATCH[4]}"
                elif [[ "$line" =~ export[[:space:]]+(interface|type|enum)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                    kind="${BASH_REMATCH[1]}"; name="${BASH_REMATCH[2]}"
                elif [[ "$line" =~ export[[:space:]]+(const|let)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]]; then
                    kind="${BASH_REMATCH[1]}"; name="${BASH_REMATCH[2]}"
                else
                    kind="export"; name="?"
                fi
                add_finding "$file" "$line_num" "missing-tsdoc" \
                    "exported $kind '$name' is missing a TSDoc comment"
            fi
            prev_was_doc=false
        else
            prev_was_doc=false
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
        echo "No TS files found in: $TARGET"
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
        echo "All exported APIs have TSDoc comments."
        exit 0
    fi
    echo "Missing TSDoc:"
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
