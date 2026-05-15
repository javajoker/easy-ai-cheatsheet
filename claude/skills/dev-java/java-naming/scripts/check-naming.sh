#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Check Java naming conventions

USAGE
    bash $SCRIPT_NAME [options] [path]

DESCRIPTION
    Scans .java files for naming violations:
      - Interfaces with 'I' prefix (modern style: no prefix)
      - Classes / interfaces in camelCase or snake_case
      - Methods / fields in PascalCase or snake_case
      - Module-level constants not in UPPER_SNAKE_CASE
      - Exception classes not ending in 'Exception'
      - Hungarian / type-encoding prefixes (strX, listX, etc.)

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --json            Output as JSON

ARGUMENTS
    path              Directory or file to check (default: src/main/java)

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME src/main/java/com/acme
    bash $SCRIPT_NAME --json .
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
    if [[ -d src/main/java ]]; then TARGET="src/main/java"
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
    find "$t" -name '*.java' \
        ! -path '*/target/*' ! -path '*/build/*' \
        ! -path '*/out/*' ! -path '*/.gradle/*' 2>/dev/null
}

FINDINGS=()
add_finding() { FINDINGS+=("$1:$2|$3|$4"); }

check_iface_iprefix() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ (public[[:space:]]+|private[[:space:]]+|protected[[:space:]]+)?interface[[:space:]]+I[A-Z][a-zA-Z0-9_]+ ]]; then
            add_finding "$file" "$line_num" "iface-iprefix" \
                "interface uses 'I' prefix; modern Java style omits the prefix"
        fi
    done < "$file"
}

check_class_case() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # class/interface/record/enum lowercase or snake_case
        if [[ "$line" =~ (class|interface|record|enum)[[:space:]]+([a-z][a-zA-Z0-9_]*) ]]; then
            local kind="${BASH_REMATCH[1]}"
            local name="${BASH_REMATCH[2]}"
            add_finding "$file" "$line_num" "type-case" \
                "$kind '$name' should be PascalCase"
        fi
        if [[ "$line" =~ (class|interface|record|enum)[[:space:]]+([A-Z][a-zA-Z0-9]*_[a-zA-Z0-9_]+) ]]; then
            local kind="${BASH_REMATCH[1]}"
            local name="${BASH_REMATCH[2]}"
            add_finding "$file" "$line_num" "type-case" \
                "$kind '$name' uses snake_case; use PascalCase"
        fi
    done < "$file"
}

check_exception_suffix() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # class Foo extends ... Exception
        if [[ "$line" =~ class[[:space:]]+([A-Z][a-zA-Z0-9_]*)[[:space:]]+extends[[:space:]]+([A-Z][a-zA-Z0-9_]*) ]]; then
            local name="${BASH_REMATCH[1]}"
            local parent="${BASH_REMATCH[2]}"
            if [[ "$parent" =~ Exception$ ]] && [[ ! "$name" =~ Exception$ ]]; then
                add_finding "$file" "$line_num" "exception-suffix" \
                    "exception class '$name' should end in 'Exception'"
            fi
            if [[ "$name" =~ Error$ ]] && [[ "$parent" =~ Exception$ ]]; then
                add_finding "$file" "$line_num" "exception-suffix" \
                    "class '$name' ends in 'Error' but extends an Exception; in Java, 'Error' is reserved for JVM errors"
            fi
        fi
    done < "$file"
}

check_hungarian() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # Variable declarations like String strName, List listUsers, etc.
        if [[ "$line" =~ (private|public|protected|final|static|^[[:space:]]+)[[:space:]]+[A-Z][a-zA-Z0-9_]*(\<[^\>]+\>)?[[:space:]]+(str|arr|list|dict|map|num|int|bool|obj)[A-Z][a-zA-Z0-9_]* ]]; then
            add_finding "$file" "$line_num" "hungarian" \
                "field/variable uses type-encoding prefix (str/arr/list/...); rely on the declared type"
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
        echo "No Java files found in: $TARGET"
    fi
    exit 0
fi

for file in "${FILES[@]}"; do
    check_iface_iprefix "$file"
    check_class_case "$file"
    check_exception_suffix "$file"
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
        echo "(Use Checkstyle's google_checks.xml for stronger enforcement.)"
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
