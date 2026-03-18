#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="CafeVeloz"
SOURCE_APP_DIR="${ROOT_DIR}/dist/${APP_NAME}.app"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/Applications}"
TARGET_APP_DIR="${INSTALL_DIR}/${APP_NAME}.app"

echo "[install] Building ${APP_NAME} release bundle..."
"${ROOT_DIR}/scripts/build_desktop_app.sh"

if [[ ! -d "${SOURCE_APP_DIR}" ]]; then
    echo "[install] Error: app bundle not found at ${SOURCE_APP_DIR}" >&2
    exit 1
fi

# Kill running instance if any
pkill -f "${TARGET_APP_DIR}/Contents/MacOS/${APP_NAME}" 2>/dev/null || true
sleep 0.5

mkdir -p "${INSTALL_DIR}"
rm -rf "${TARGET_APP_DIR}"

echo "[install] Installing ${APP_NAME}.app into ${INSTALL_DIR}..."
ditto "${SOURCE_APP_DIR}" "${TARGET_APP_DIR}"

echo
echo "[install] Installed ${APP_NAME}.app to ${INSTALL_DIR}"
echo "[install] Launch it from Spotlight, Finder, or Login Items."
