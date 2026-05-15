#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Scaffold a pytest parametrize test for a Python function

USAGE
    bash $SCRIPT_NAME [options] <module.path:function>

DESCRIPTION
    Emits a pytest scaffold to stdout (or --output) that imports the
    given function and provides an empty parametrize test skeleton.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    -o, --output FILE Write to FILE instead of stdout
    --async           Emit an async/await scaffold

ARGUMENTS
    module.path:function    Dotted module path + ":" + function name
                            Example: myapp.user.repository:get_user_by_id

EXAMPLES
    bash $SCRIPT_NAME myapp.upper_case:upper_case > tests/test_upper_case.py
    bash $SCRIPT_NAME --async myapp.user.repository:load_user
    bash $SCRIPT_NAME -o tests/test_user.py myapp.user:create_user
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

if [[ $# -lt 1 ]]; then
    echo "error: <module.path:function> is required" >&2
    usage >&2; exit 2
fi

SPEC="$1"
if [[ "$SPEC" != *":"* ]]; then
    echo "error: expected module.path:function, got: $SPEC" >&2
    exit 2
fi

MODULE="${SPEC%%:*}"
FUNC="${SPEC##*:}"

emit() {
    if $ASYNC; then
        cat <<EOF
"""Tests for ${MODULE}:${FUNC}."""

from __future__ import annotations

import pytest

from ${MODULE} import ${FUNC}


@pytest.mark.asyncio
@pytest.mark.parametrize(
    ("name", "input_value", "expected"),
    [
        # ("happy_path", ..., ...),
    ],
    ids=lambda v: v if isinstance(v, str) else None,
)
async def test_${FUNC}_handles(name: str, input_value: object, expected: object) -> None:
    """${FUNC} returns the expected value for each scenario."""
    got = await ${FUNC}(input_value)
    assert got == expected


@pytest.mark.asyncio
async def test_${FUNC}_raises_on_invalid() -> None:
    with pytest.raises(Exception):
        await ${FUNC}(None)
EOF
    else
        cat <<EOF
"""Tests for ${MODULE}:${FUNC}."""

from __future__ import annotations

import pytest

from ${MODULE} import ${FUNC}


@pytest.mark.parametrize(
    ("name", "input_value", "expected"),
    [
        # ("happy_path", ..., ...),
    ],
    ids=lambda v: v if isinstance(v, str) else None,
)
def test_${FUNC}_handles(name: str, input_value: object, expected: object) -> None:
    """${FUNC} returns the expected value for each scenario."""
    assert ${FUNC}(input_value) == expected


def test_${FUNC}_raises_on_invalid() -> None:
    with pytest.raises(Exception):
        ${FUNC}(None)
EOF
    fi
}

if [[ -n "$OUT" ]]; then
    emit > "$OUT"
    echo "Wrote $OUT"
else
    emit
fi
