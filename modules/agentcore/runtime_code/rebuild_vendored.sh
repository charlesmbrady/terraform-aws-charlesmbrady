#!/usr/bin/env bash
set -euo pipefail

echo "[rebuild_vendored] Rebuilding vendored dependency tree"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f requirements.txt ]; then
  echo "requirements.txt not found in runtime_code directory" >&2
  exit 1
fi

echo "[rebuild_vendored] Removing old vendored directory"
rm -rf vendored
mkdir -p vendored

echo "[rebuild_vendored] Installing dependencies into vendored/"
pip install --no-cache-dir --target vendored -r requirements.txt

echo "[rebuild_vendored] Stripping __pycache__ and .pyc files"
find vendored -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
find vendored -type f -name "*.pyc" -delete || true

echo "[rebuild_vendored] Done. Contents:" 
find vendored -maxdepth 2 -type d -print | head -50

echo "[rebuild_vendored] To package: zip -r runtime_code.zip main.py vendored"