#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Scaffold a JUnit 5 / AssertJ test class

USAGE
    bash $SCRIPT_NAME [options] <fqcn>

DESCRIPTION
    Emits a JUnit 5 + AssertJ test class scaffold to stdout (or --output).
    The fqcn is the fully-qualified class name under test, e.g.
    'com.acme.myapp.user.UserService' — the script derives the test
    class name and package.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    -o, --output FILE Write to FILE instead of stdout
    --mockito         Include MockitoExtension and @Mock skeleton

ARGUMENTS
    fqcn              Fully-qualified class name under test

EXAMPLES
    bash $SCRIPT_NAME com.acme.myapp.user.UserService > UserServiceTest.java
    bash $SCRIPT_NAME --mockito com.acme.myapp.charge.ChargeService
    bash $SCRIPT_NAME -o src/test/java/com/acme/UserServiceTest.java com.acme.UserService
EOF
}

OUT=""
MOCKITO=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)      usage; exit 0 ;;
        -v|--version)   echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        -o|--output)    OUT="${2:?error: --output needs path}"; shift 2 ;;
        --mockito)      MOCKITO=true; shift ;;
        -*)             echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
        *)              break ;;
    esac
done

if [[ $# -lt 1 ]]; then
    echo "error: <fqcn> is required" >&2
    usage >&2; exit 2
fi

FQCN="$1"
PACKAGE="${FQCN%.*}"
CLASS="${FQCN##*.}"
TEST_CLASS="${CLASS}Test"

emit() {
    cat <<EOF
package ${PACKAGE};

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
EOF

    if $MOCKITO; then
        cat <<'EOF'
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
EOF
    fi

    echo ""

    if $MOCKITO; then
        echo "@ExtendWith(MockitoExtension.class)"
    fi
    cat <<EOF
class ${TEST_CLASS} {

EOF

    if $MOCKITO; then
        cat <<'EOF'
    // @Mock SomeDependency dependency;

EOF
    fi

    cat <<EOF
    ${CLASS} subject;

    @BeforeEach
    void setUp() {
        // subject = new ${CLASS}(/* deps */);
    }

    @Test
    void describesTheHappyPath() {
        // assertThat(subject.method()).isEqualTo(expected);
    }

    @Test
    void describesAnEdgeCase() {
        // assertThatThrownBy(() -> subject.method())
        //     .isInstanceOf(IllegalArgumentException.class)
        //     .hasMessageContaining("...");
    }
}
EOF
}

if [[ -n "$OUT" ]]; then
    mkdir -p "$(dirname "$OUT")"
    emit > "$OUT"
    echo "Wrote $OUT"
else
    emit
fi
