#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.0"
SCRIPT_NAME="$(basename "$0")"

usage() {
    cat <<EOF
$SCRIPT_NAME v$VERSION — Install and wire up the canonical Python lint stack

USAGE
    bash $SCRIPT_NAME [options]

DESCRIPTION
    Installs ruff, mypy, and pre-commit. Copies the canonical ruff.toml
    and .pre-commit-config.yaml into the project root (will not overwrite
    without --force).

    Uses 'uv add' by default if uv is on PATH; falls back to 'pip install'.

OPTIONS
    -h, --help        Show this help
    -v, --version     Show version
    --pip             Use pip even if uv is available
    --poetry          Use poetry add --group dev
    --force           Overwrite existing config files
    --no-install      Only copy configs; skip installing tools

EXAMPLES
    bash $SCRIPT_NAME
    bash $SCRIPT_NAME --poetry
    bash $SCRIPT_NAME --force
EOF
}

PKG="auto"
FORCE=false
NO_INSTALL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)    usage; exit 0 ;;
        -v|--version) echo "$SCRIPT_NAME v$VERSION"; exit 0 ;;
        --pip)        PKG="pip"; shift ;;
        --poetry)     PKG="poetry"; shift ;;
        --force)      FORCE=true; shift ;;
        --no-install) NO_INSTALL=true; shift ;;
        *)            echo "error: unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
done

if [[ "$PKG" == "auto" ]]; then
    if command -v uv &>/dev/null; then PKG="uv"
    elif command -v poetry &>/dev/null && [[ -f pyproject.toml ]]; then PKG="poetry"
    else PKG="pip"
    fi
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$(cd "$SCRIPT_DIR/../assets" && pwd)"

if [[ ! -f pyproject.toml && ! -f setup.cfg && ! -f setup.py ]]; then
    echo "warn: no pyproject.toml/setup.cfg in $(pwd); creating ruff.toml at repo root" >&2
fi

DEPS=("ruff>=0.6" "mypy>=1.10" "pre-commit>=3")

if ! $NO_INSTALL; then
    echo "==> Installing dev dependencies via $PKG..."
    case "$PKG" in
        uv)     uv add --dev "${DEPS[@]}" ;;
        poetry) poetry add --group dev "${DEPS[@]}" ;;
        pip)    python -m pip install --upgrade "${DEPS[@]}" ;;
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

copy_if_missing "$ASSETS_DIR/ruff.toml" "./ruff.toml"
copy_if_missing "$ASSETS_DIR/pre-commit-config.yaml" "./.pre-commit-config.yaml"

if command -v pre-commit &>/dev/null; then
    pre-commit install
    echo "==> pre-commit hook installed"
fi

echo ""
echo "Setup complete. Suggested commands:"
echo ""
cat <<'EOF'
  ruff check .
  ruff format --check .
  mypy src/
  pre-commit run --all-files
EOF
