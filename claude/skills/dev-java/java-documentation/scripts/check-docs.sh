#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Check Java public API for missing Javadoc

USAGE
    bash $SCRIPT_NAME [options] [path]

DESCRIPTION
    Scans .java source files for public methods and public classes that
    lack a Javadoc comment (/** ... */) immediately above. Skips test
    files (src/test).

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
        -h|--help)         usage; exit 0 ;;
        -v|--version)      echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        --json)            JSON_OUTPUT=true; shift ;;
        -*)                echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)                 TARGET="$1"; shift ;;
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
        ! -path '*/out/*' ! -path '*/.gradle/*' \
        ! -path '*/src/test/*' 2>/dev/null
}

FINDINGS=()
add_finding() { FINDINGS+=("$1:$2|$3|$4"); }

check_file() {
    local file="$1"
    local line_num=0 javadoc_above=false
    while IFS= read -r line; do
        line_num=$((line_num + 1))

        # Track Javadoc closing.
        if [[ "$line" =~ \*/[[:space:]]*$ ]]; then
            javadoc_above=true
            continue
        fi
        # Annotations and blank/line-comment lines sit between Javadoc and
        # the declaration; they preserve javadoc_above.
        if [[ "$line" =~ ^[[:space:]]*@[A-Z] ]] \
           || [[ "$line" =~ ^[[:space:]]*$ ]] \
           || [[ "$line" =~ ^[[:space:]]*// ]]; then
            continue
        fi

        # Public class/interface/enum/record declaration.
        if [[ "$line" =~ ^[[:space:]]*public[[:space:]]+(static[[:space:]]+|final[[:space:]]+|abstract[[:space:]]+|sealed[[:space:]]+|non-sealed[[:space:]]+)*(class|interface|enum|record)[[:space:]]+([A-Za-z_][A-Za-z0-9_]*) ]]; then
            local kind="${BASH_REMATCH[2]}"
            local name="${BASH_REMATCH[3]}"
            if ! $javadoc_above; then
                add_finding "$file" "$line_num" "missing-javadoc" \
                    "public $kind $name has no Javadoc"
            fi
            javadoc_above=false
            continue
        fi

        # Public method (heuristic): line starts with `public`, contains `(`,
        # and is not a field declaration ending with `;`.
        if [[ "$line" =~ ^[[:space:]]*public[[:space:]]+ ]] \
           && [[ "$line" == *"("* ]] \
           && [[ ! "$line" =~ \;[[:space:]]*$ ]]; then
            local before="${line%%(*}"
            local name="${before##* }"
            if [[ -n "$name" && "$name" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
                if ! $javadoc_above; then
                    add_finding "$file" "$line_num" "missing-javadoc" \
                        "public method $name has no Javadoc"
                fi
            fi
            javadoc_above=false
            continue
        fi

        javadoc_above=false
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
        echo "All public APIs have Javadoc."
        exit 0
    fi
    echo "Missing Javadoc:"
    echo ""
    for entry in "${FINDINGS[@]}"; do
        IFS='|' read -r location rule message <<< "$entry"
        printf "  %s  [%s] %s\n" "$location" "$rule" "$message"
    done
    echo ""
    echo "Total: $TOTAL finding(s)"
    echo ""
    echo "For richer enforcement, configure Checkstyle's MissingJavadocMethod"
    echo "and MissingJavadocType (see java-linting skill)."
fi

[[ $TOTAL -gt 0 ]] && exit 1
exit 0
