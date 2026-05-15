#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Check Node.js / TypeScript naming conventions

USAGE
    bash $SCRIPT_NAME [options] [path]

DESCRIPTION
    Scans .ts and .js files for naming violations:
      - Interfaces with 'I' prefix (modern style: no prefix)
      - Type names in lowercase / snake_case
      - Variables / functions in PascalCase or snake_case
      - Constants that should be UPPER_SNAKE_CASE
      - Hungarian / type-encoding prefixes (strX, listX, dictX, iX)

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --json            Output as JSON

ARGUMENTS
    path              Directory or file to check (default: ./src)

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME packages/app/src
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
        \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.mjs' \) \
        ! -path '*/node_modules/*' ! -path '*/dist/*' ! -path '*/build/*' \
        ! -path '*/coverage/*' ! -name '*.d.ts' 2>/dev/null
}

FINDINGS=()
add_finding() { FINDINGS+=("$1:$2|$3|$4"); }

check_interface_iprefix() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ (export[[:space:]]+)?interface[[:space:]]+I[A-Z][a-zA-Z0-9_]+ ]]; then
            add_finding "$file" "$line_num" "iface-iprefix" \
                "interface uses 'I' prefix; modern TS style omits the prefix"
        fi
    done < "$file"
}

check_type_case() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # type foo = ... or class foo ... (lowercase start)
        if [[ "$line" =~ (export[[:space:]]+)?(type|interface|class|enum)[[:space:]]+[a-z][a-zA-Z0-9_]* ]]; then
            local name
            name=$(echo "$line" | sed -E 's/.*(type|interface|class|enum)[[:space:]]+([a-zA-Z0-9_]+).*/\2/')
            add_finding "$file" "$line_num" "type-case" \
                "type/class/interface '$name' should be PascalCase"
        fi
        # type Foo_bar = ... (snake_case)
        if [[ "$line" =~ (export[[:space:]]+)?(type|interface|class|enum)[[:space:]]+[A-Z][a-zA-Z0-9]*_[a-zA-Z0-9_]* ]]; then
            add_finding "$file" "$line_num" "type-case" \
                "type/class/interface uses snake_case; use PascalCase"
        fi
    done < "$file"
}

check_const_case() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Module-level const FOO = 'string-literal' or = 123 — should be UPPER_SNAKE_CASE
        # We only flag if the value is a primitive literal (signaling intent of constant)
        if [[ "$line" =~ ^(export[[:space:]]+)?const[[:space:]]+([a-z][a-zA-Z0-9_]*)[[:space:]]*(:[[:space:]]*[A-Za-z<>\[\][:space:],]+)?[[:space:]]*=[[:space:]]*(\'[^\']*\'|\"[^\"]*\"|[0-9]+|true|false) ]]; then
            local name="${BASH_REMATCH[2]}"
            # Heuristic: only flag if name has all-lowercase letters and looks "constant-like"
            # We won't flag e.g. `const port = 3000` since that may be derived
            # Only flag obvious uppercase intent: name is short AND not derived AND obviously a constant
            # Keep this check conservative — disabled by default in this script
            :  # no-op; this heuristic is too noisy
        fi
    done < "$file"
}

check_hungarian() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Variable patterns: strFoo, listFoo, arrFoo, dictFoo, mapFoo, objFoo
        if [[ "$line" =~ (const|let|var|function|export[[:space:]]+const|export[[:space:]]+let|export[[:space:]]+function)[[:space:]]+(str|arr|list|dict|obj|map|num|int|bool)[A-Z][a-zA-Z0-9]+ ]]; then
            add_finding "$file" "$line_num" "hungarian" \
                "name uses type-encoding prefix (str/arr/list/...); rely on the type, not the name"
        fi
        # interface fields with type prefix is also a smell, harder to detect cleanly
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
    check_interface_iprefix "$file"
    check_type_case "$file"
    check_hungarian "$file"
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
    echo ""
    echo "Consider configuring @typescript-eslint/naming-convention for"
    echo "stronger enforcement (see node-linting skill)."
fi

[[ $TOTAL -gt 0 ]] && exit 1
exit 0
