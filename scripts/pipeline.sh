#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

echo "[pipeline] 1/3 Validating assets..."
"${ROOT_DIR}/scripts/validate_assets.sh"

echo "[pipeline] 2/3 Running tests..."
CLANG_MODULE_CACHE_PATH="${ROOT_DIR}/.build/ModuleCache" \
  swift test --disable-sandbox

echo "[pipeline] 3/3 Building desktop app..."
"${ROOT_DIR}/scripts/build_desktop_app.sh"

echo "[pipeline] Done."
