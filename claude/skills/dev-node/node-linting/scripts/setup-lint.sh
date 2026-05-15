#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Install and wire up the canonical Node.js / TS lint stack

USAGE
    bash $SCRIPT_NAME [options]

DESCRIPTION
    Installs ESLint 9 (flat config), typescript-eslint, eslint-plugin-import,
    Prettier, and eslint-config-prettier. Copies the canonical eslint.config.mjs
    and .prettierrc into the project root (will not overwrite without --force).

    Uses npm by default; supports --pnpm and --yarn flavors.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --pnpm            Use pnpm instead of npm
    --yarn            Use yarn instead of npm
    --force           Overwrite existing eslint.config.mjs / .prettierrc

ENVIRONMENT
    SKIP_INSTALL      Set non-empty to skip npm install (only copy configs)

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME --pnpm
    bash $SCRIPT_NAME --force
EOF
}

PKG_MANAGER="npm"
FORCE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--version) echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        --pnpm)       PKG_MANAGER="pnpm"; shift ;;
        --yarn)       PKG_MANAGER="yarn"; shift ;;
        --force)      FORCE=true; shift ;;
        *)            echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$(cd "$SCRIPT_DIR/../assets" && pwd)"

if [[ ! -f package.json ]]; then
    echo "error: no package.json in $(pwd); run from project root" >&2
    exit 2
fi

DEV_DEPS=(
    "eslint@^9"
    "@eslint/js@^9"
    "typescript-eslint@^8"
    "eslint-plugin-import@^2"
    "eslint-import-resolver-typescript@^3"
    "prettier@^3"
    "eslint-config-prettier@^9"
)

if [[ -z "${SKIP_INSTALL:-}" ]]; then
    echo "==> Installing dev dependencies with $PKG_MANAGER..."
    case "$PKG_MANAGER" in
        npm)  npm install --save-dev "${DEV_DEPS[@]}" ;;
        pnpm) pnpm add -D "${DEV_DEPS[@]}" ;;
        yarn) yarn add --dev "${DEV_DEPS[@]}" ;;
    esac
fi

copy_if_missing() {
    local src="$1" dst="$2"
    if [[ ! -f "$src" ]]; then
        echo "error: asset not found: $src" >&2
        exit 2
    fi
    if [[ -f "$dst" ]] && ! $FORCE; then
        echo "==> Skipping $dst (already exists; use --force to overwrite)"
    else
        cp "$src" "$dst"
        echo "==> Wrote $dst"
    fi
}

copy_if_missing "$ASSETS_DIR/eslint.config.mjs" "./eslint.config.mjs"
copy_if_missing "$ASSETS_DIR/prettierrc.json" "./.prettierrc"

if [[ ! -f ".prettierignore" ]] || $FORCE; then
    cat > .prettierignore <<EOF
dist
build
coverage
.next
node_modules
*.lock
EOF
    echo "==> Wrote .prettierignore"
fi

echo ""
echo "Setup complete. Suggested package.json scripts:"
echo ""
cat <<'EOF'
  "scripts": {
    "lint": "eslint .",
    "lint:fix": "eslint . --fix",
    "format": "prettier --write .",
    "format:check": "prettier --check .",
    "typecheck": "tsc --noEmit"
  }
EOF
