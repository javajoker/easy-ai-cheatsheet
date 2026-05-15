#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Scaffold a Vitest table-driven test for a TS function

USAGE
    bash $SCRIPT_NAME [options] <function> <source-file>

DESCRIPTION
    Emits a Vitest scaffold to stdout (or to --output) that imports the
    given function from the relative source file, and provides an empty
    table-driven test skeleton ready to fill in.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    -o, --output FILE Write to FILE instead of stdout
    --async           Emit an async/await scaffold

ARGUMENTS
    function          Name of the function under test
    source-file       Path to the .ts file the function lives in (relative to test)

EXAMPLES
    bash $SCRIPT_NAME upperCase ./upper-case > upper-case.test.ts
    bash $SCRIPT_NAME --async loadUser ./user-repository
    bash $SCRIPT_NAME -o user.test.ts createUser ./user
EOF
}

OUT=""
ASYNC=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)      usage; exit 0 ;;
        -v|--version)   echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        -o|--output)    OUT="${2:?error: --output needs path}"; shift 2 ;;
        --async)        ASYNC=true; shift ;;
        -*)             echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)              break ;;
    esac
done

if [[ $# -lt 2 ]]; then
    echo "error: <function> and <source-file> are required" >&2
    usage >&2
    exit 2
fi

FUNC="$1"
SRC="$2"
# Strip extension; ESM imports use .js suffix in TS source-to-source.
SRC_NOEXT="${SRC%.ts}"
SRC_NOEXT="${SRC_NOEXT%.js}"
IMPORT_PATH="${SRC_NOEXT}.js"

emit() {
    if $ASYNC; then
        cat <<EOF
import { describe, it, expect } from 'vitest';

import { ${FUNC} } from '${IMPORT_PATH}';

describe('${FUNC}', () => {
  it.each<{ name: string; input: unknown; expected: unknown }>([
    // { name: 'happy path', input: ..., expected: ... },
  ])('\$name', async ({ input, expected }) => {
    const got = await ${FUNC}(input as never);
    expect(got).toStrictEqual(expected);
  });

  it('rejects on invalid input', async () => {
    await expect(${FUNC}(/* invalid */ null as never)).rejects.toThrow();
  });
});
EOF
    else
        cat <<EOF
import { describe, it, expect } from 'vitest';

import { ${FUNC} } from '${IMPORT_PATH}';

describe('${FUNC}', () => {
  it.each<{ name: string; input: unknown; expected: unknown }>([
    // { name: 'happy path', input: ..., expected: ... },
  ])('\$name', ({ input, expected }) => {
    const got = ${FUNC}(input as never);
    expect(got).toStrictEqual(expected);
  });

  it('throws on invalid input', () => {
    expect(() => ${FUNC}(/* invalid */ null as never)).toThrow();
  });
});
EOF
    fi
}

if [[ -n "$OUT" ]]; then
    emit > "$OUT"
    echo "Wrote $OUT"
else
    emit
fi
