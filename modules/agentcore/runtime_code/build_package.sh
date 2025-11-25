#!/usr/bin/env bash
set -euo pipefail

# Build AgentCore runtime deployment package with vendored dependencies.
# This script should be run from the `runtime_code` directory.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

PYTHON_BIN=${PYTHON_BIN:-python3}
VENV_DIR=".venv"
BUILD_DIR="build"
ZIP_NAME="code.zip"

echo "[agentcore] Using python: $PYTHON_BIN"

# Optionally create/activate a local venv (keeps things clean)
if [ ! -d "$VENV_DIR" ]; then
  echo "[agentcore] Creating virtualenv in $VENV_DIR ..."
  "$PYTHON_BIN" -m venv "$VENV_DIR"
fi

# shellcheck source=/dev/null
source "$VENV_DIR/bin/activate"

pip install --upgrade pip

echo "[agentcore] Cleaning previous build artifacts ..."
rm -rf "$BUILD_DIR" "$ZIP_NAME"
mkdir -p "$BUILD_DIR"

echo "[agentcore] Installing requirements into build directory ..."
pip install -r requirements.txt -t "$BUILD_DIR"

echo "[agentcore] Copying runtime source files into build directory ..."
# Copy main entrypoint and any local packages
cp main.py "$BUILD_DIR" || true
# Copy any additional .py files or packages if present
find . -maxdepth 1 -type f -name "*.py" ! -name "main.py" -exec cp {} "$BUILD_DIR" \;
for d in */; do
  case "$d" in
    build/|.venv/|__pycache__/)
      ;;
    *)
      # Copy python packages / modules, skip non-code dirs if needed
      if compgen -G "$d*.py" > /dev/null; then
        cp -R "$d" "$BUILD_DIR"/
      fi
      ;;
  esac
done

echo "[agentcore] Creating deployment zip $ZIP_NAME ..."
cd "$BUILD_DIR"
zip -qr "../$ZIP_NAME" .
cd "$ROOT_DIR"

echo "[agentcore] Build complete: $ROOT_DIR/$ZIP_NAME"
