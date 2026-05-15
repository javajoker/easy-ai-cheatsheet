#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Check Python code for common error-handling anti-patterns

USAGE
    bash $SCRIPT_NAME [options] [path]

DESCRIPTION
    Scans .py source files for error-handling anti-patterns:
      - bare 'except:' (catches BaseException)
      - 'except Exception: pass' (silent swallow)
      - catch-and-rethrow with no transformation
      - log-and-raise (handle errors once)
      - raising non-Exception (string, BaseException)

    Exits 0 if no issues found, 1 if anti-patterns detected, 2 on error.

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
        ! -path '*/dist/*' ! -path '*/build/*' \
        ! -name 'test_*.py' ! -name '*_test.py' 2>/dev/null
}

FINDINGS=()
add_finding() { FINDINGS+=("$1:$2|$3|$4"); }

check_bare_except() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # bare 'except:' (no exception type)
        if [[ "$line" =~ ^[[:space:]]*except[[:space:]]*: ]]; then
            add_finding "$file" "$line_num" "bare-except" \
                "bare 'except:' catches BaseException (including KeyboardInterrupt, SystemExit); narrow it"
        fi
    done < "$file"
}

check_empty_except() {
    local file="$1"
    local line_num=0 in_block=false start_line=0 body_lines=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ ^[[:space:]]*except([[:space:]].*)?:[[:space:]]*$ ]]; then
            in_block=true
            start_line=$line_num
            body_lines=0
            continue
        fi
        if $in_block; then
            [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
            body_lines=$((body_lines + 1))
            if [[ $body_lines -eq 1 ]]; then
                local stripped="${line//[[:space:]]/}"
                if [[ "$stripped" == "pass" || "$stripped" == "..." ]]; then
                    add_finding "$file" "$start_line" "empty-except" \
                        "except block silently swallows the exception (only pass / ...); at minimum log it"
                fi
                in_block=false
            fi
        fi
    done < "$file"
}

check_catch_rethrow() {
    local file="$1"
    local line_num=0 in_block=false start_line=0 var="" body_lines=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        if [[ "$line" =~ ^[[:space:]]*except[[:space:]].*[[:space:]]as[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*:[[:space:]]*$ ]]; then
            in_block=true
            start_line=$line_num
            var="${BASH_REMATCH[1]}"
            body_lines=0
            continue
        fi
        if $in_block; then
            [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
            body_lines=$((body_lines + 1))
            if [[ $body_lines -eq 1 ]]; then
                local stripped="${line#"${line%%[![:space:]]*}"}"
                stripped="${stripped%"${stripped##*[![:space:]]}"}"
                if [[ "$stripped" == "raise $var" || "$stripped" == "raise" ]]; then
                    add_finding "$file" "$start_line" "catch-rethrow" \
                        "catch-and-rethrow with no transformation; remove the try/except or add context with raise ... from"
                fi
                in_block=false
            fi
        fi
    done < "$file"
}

check_log_and_raise() {
    local file="$1" line_num=0
    declare -a window=()
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        window+=("$line")
        if [[ ${#window[@]} -gt 4 ]]; then
            window=("${window[@]:1}")
        fi
        # current line is `raise X` or `raise X from ...`
        if [[ "$line" =~ ^[[:space:]]*raise[[:space:]] ]]; then
            for prev in "${window[@]}"; do
                # logger.error / log.error / logging.error and friends, with our exception variable
                if [[ "$prev" =~ (log|logger|logging)\.(error|exception|warning|warn|info|fatal|critical)\( ]]; then
                    add_finding "$file" "$line_num" "log-and-raise" \
                        "error logged then raised; handle errors once (let the boundary log)"
                    break
                fi
            done
        fi
    done < "$file"
}

check_raise_non_exception() {
    local file="$1" line_num=0
    while IFS= read -r line; do
        line_num=$((line_num + 1))
        # raise "string"
        if [[ "$line" =~ ^[[:space:]]*raise[[:space:]]+[\'\"] ]]; then
            add_finding "$file" "$line_num" "raise-string" \
                "raising a string is illegal in Python 3; raise an Exception subclass"
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
    check_bare_except "$file"
    check_empty_except "$file"
    check_raise_non_exception "$file"
    check_log_and_raise "$file"
    check_catch_rethrow "$file"
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
        echo "(Run ruff check --select E,B,TRY for deeper analysis.)"
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
