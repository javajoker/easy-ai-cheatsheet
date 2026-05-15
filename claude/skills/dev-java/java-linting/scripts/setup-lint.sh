#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Drop canonical Java lint configs into a project

USAGE
    bash $SCRIPT_NAME [options]

DESCRIPTION
    Copies the canonical Spotless plugin configuration (Maven or Gradle)
    and a Checkstyle config into the project. The script is conservative:
    it does not run package managers, since Maven/Gradle handle their
    own dependency resolution; just merge the plugin snippet manually.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --maven           Copy spotless-pom-snippet.xml as STDOUT instruction
    --gradle          Copy spotless-build.gradle.kts as STDOUT instruction
    --checkstyle      Copy checkstyle.xml into config/checkstyle/
    --all             Do all of the above
    --force           Overwrite existing files

EXAMPLES
    bash $SCRIPT_NAME --all
    bash $SCRIPT_NAME --maven --checkstyle
    bash $SCRIPT_NAME --gradle --force
EOF
}

DO_MAVEN=false; DO_GRADLE=false; DO_CHECKSTYLE=false
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--version) echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        --maven)      DO_MAVEN=true; shift ;;
        --gradle)     DO_GRADLE=true; shift ;;
        --checkstyle) DO_CHECKSTYLE=true; shift ;;
        --all)        DO_MAVEN=true; DO_GRADLE=true; DO_CHECKSTYLE=true; shift ;;
        --force)      FORCE=true; shift ;;
        *)            echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

# If nothing requested, auto-detect.
if ! $DO_MAVEN && ! $DO_GRADLE && ! $DO_CHECKSTYLE; then
    if [[ -f pom.xml ]]; then
        DO_MAVEN=true; DO_CHECKSTYLE=true
    elif [[ -f build.gradle || -f build.gradle.kts ]]; then
        DO_GRADLE=true; DO_CHECKSTYLE=true
    else
        echo "error: no pom.xml or build.gradle.kts found; use --maven or --gradle explicitly" >&2
        exit 2
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$(cd "$SCRIPT_DIR/../assets" && pwd)"

copy_if_missing() {
    local src="$1" dst="$2"
    if [[ ! -f "$src" ]]; then
        echo "error: asset not found: $src" >&2; exit 2
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ -f "$dst" ]] && ! $FORCE; then
        echo "==> Skipping $dst (exists; use --force to overwrite)"
    else
        cp "$src" "$dst"
        echo "==> Wrote $dst"
    fi
}

if $DO_CHECKSTYLE; then
    copy_if_missing "$ASSETS_DIR/checkstyle.xml" "config/checkstyle/checkstyle.xml"
fi

if $DO_MAVEN; then
    echo ""
    echo "==> Spotless plugin snippet for pom.xml (merge under <build><plugins>):"
    echo ""
    cat "$ASSETS_DIR/spotless-pom-snippet.xml"
    echo ""
    echo "==> Run: mvn spotless:check"
fi

if $DO_GRADLE; then
    echo ""
    echo "==> Spotless config for build.gradle.kts (add to plugins / merge with spotless block):"
    echo ""
    cat "$ASSETS_DIR/spotless-build.gradle.kts"
    echo ""
    echo "==> Run: ./gradlew spotlessCheck"
fi

echo ""
echo "Setup complete."
echo ""
echo "Recommended additional plugins (configure separately):"
echo "  - ErrorProne (compile-time bug detection)"
echo "  - NullAway (null-safety enforcement, ErrorProne plugin)"
echo "  - OWASP Dependency Check (vulnerable dependency scan)"
