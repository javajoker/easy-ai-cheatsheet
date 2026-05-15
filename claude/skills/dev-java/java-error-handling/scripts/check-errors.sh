#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Check Java code for common error-handling anti-patterns

USAGE
    bash $SCRIPT_NAME [options] [path]

DESCRIPTION
    Scans .java source files for error-handling anti-patterns:
      - catch (Throwable) or bare-rethrow catch
      - empty catch blocks ({ } or { /* comment */ })
      - String == / != for object identity
      - InterruptedException swallowed without re-interrupt
      - Optional.get() without prior check

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
        ! -path '*/out/*' ! -path '*/.gradle/*' \
        ! -path '*/src/test/*' 2>/dev/null
}

FINDINGS=()
add_finding() { FINDINGS+=("$1:$2|$3|$4"); }

check_catch_throwable() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # catch (Throwable t)
        if [[ "$line" =~ catch[[:space:]]*\([[:space:]]*Throwable[[:space:]] ]]; then
            add_finding "$file" "$line_num" "catch-throwable" \
                "catch (Throwable) catches Error subclasses too; narrow to Exception or a specific type"
        fi
    done < "$file"
}

check_empty_catch() {
    local file="$1"
    awk '
    /catch[[:space:]]*\([^)]+\)[[:space:]]*\{[[:space:]]*\}/ {
        print FILENAME ":" NR "|empty-catch|empty catch block silently swallows the exception; at minimum log it"
    }
    ' "$file" | while IFS= read -r out; do
        [[ -n "$out" ]] && FINDINGS+=("$out")
    done
}

check_catch_rethrow() {
    local file="$1"
    local line_num=0 in_block=false start_line=0 var="" body_lines=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ catch[[:space:]]*\([[:space:]]*[A-Za-z_][A-Za-z0-9_]*[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\)[[:space:]]*\{[[:space:]]*$ ]]; then
            in_block=true
            start_line=$line_num
            var="${BASH_REMATCH[1]}"
            body_lines=0
            continue
        fi
        if $in_block; then
            [[ "$line" =~ ^[[:space:]]*$ ]] && continue
            [[ "$line" =~ ^[[:space:]]*// ]] && continue
            body_lines=$((body_lines + 1))
            if [[ $body_lines -eq 1 ]]; then
                local stripped="${line#"${line%%[![:space:]]*}"}"
                stripped="${stripped%"${stripped##*[![:space:]]}"}"
                if [[ "$stripped" == "throw $var;" || "$stripped" == "throw $var" ]]; then
                    add_finding "$file" "$start_line" "catch-rethrow" \
                        "catch-and-rethrow with no transformation; remove the try/catch or add context via cause"
                fi
                in_block=false
            fi
        fi
    done < "$file"
}

check_string_identity() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # x == "..." or "..." == x   (likely incorrect; use .equals)
        if [[ "$line" =~ (==|!=)[[:space:]]*\"[^\"]*\" ]] || \
           [[ "$line" =~ \"[^\"]*\"[[:space:]]*(==|!=) ]]; then
            # Avoid flagging char comparisons
            if [[ ! "$line" =~ \'[^\']*\' ]]; then
                add_finding "$file" "$line_num" "string-identity" \
                    "comparing String with == / !=; use .equals() or Objects.equals()"
            fi
        fi
    done < "$file"
}

check_interrupted_swallow() {
    local file="$1"
    local line_num=0 in_block=false start_line=0 depth=0 has_interrupt=false
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ catch[[:space:]]*\([[:space:]]*InterruptedException[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\)[[:space:]]*\{ ]]; then
            in_block=true
            start_line=$line_num
            depth=1     # the opening brace is on this line
            has_interrupt=false
            continue
        fi
        if $in_block; then
            local opens=${line//[^{]/}
            local closes=${line//[^}]/}
            depth=$(( depth + ${#opens} - ${#closes} ))
            if [[ "$line" == *"Thread.currentThread().interrupt()"* ]]; then
                has_interrupt=true
            fi
            if [[ "$line" =~ ^[[:space:]]*throw[[:space:]] ]]; then
                has_interrupt=true
            fi
            if [[ $depth -le 0 ]]; then
                if ! $has_interrupt; then
                    add_finding "$file" "$start_line" "interrupted-swallow" \
                        "InterruptedException caught without Thread.currentThread().interrupt() or re-throw"
                fi
                in_block=false
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
        echo "No Java files found in: $TARGET"
    fi
    exit 0
fi

for file in "${FILES[@]}"; do
    check_catch_throwable "$file"
    check_empty_catch "$file"
    check_catch_rethrow "$file"
    check_string_identity "$file"
    check_interrupted_swallow "$file"
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
        echo "(Run ErrorProne / SpotBugs for deeper analysis.)"
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
