#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

cd "${ROOT_DIR}"

echo "[pipeline] 1/3 Validando assets..."
"${ROOT_DIR}/scripts/validate_assets.sh"

echo "[pipeline] 2/3 Ejecutando tests..."
swift test

echo "[pipeline] 3/3 Generando app de escritorio..."
"${ROOT_DIR}/scripts/build_desktop_app.sh"

echo "[pipeline] Listo."
