#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="CafeVeloz"
APP_BUNDLE="${ROOT_DIR}/dist/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
BIN_DIR="${CONTENTS_DIR}/MacOS"
BIN_PATH="${BIN_DIR}/${APP_NAME}"
INFO_PLIST_PATH="${CONTENTS_DIR}/Info.plist"

echo "[build] Compiling release binary..."
swift build -c release --product "${APP_NAME}"
RELEASE_BIN="$(swift build -c release --show-bin-path)/${APP_NAME}"

if [[ ! -x "${RELEASE_BIN}" ]]; then
  echo "[build] Error: release binary not found at ${RELEASE_BIN}" >&2
  exit 1
fi

echo "[build] Regenerating .app bundle in dist/..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${BIN_DIR}"
cp "${RELEASE_BIN}" "${BIN_PATH}"
chmod +x "${BIN_PATH}"

# Copy the resource bundle if it exists
RESOURCE_BUNDLE="$(swift build -c release --show-bin-path)/CafeVeloz_CafeVeloz.bundle"
if [[ -d "${RESOURCE_BUNDLE}" ]]; then
  echo "[build] Copying resource bundle..."
  cp -R "${RESOURCE_BUNDLE}" "${BIN_DIR}/"
fi

cat > "${INFO_PLIST_PATH}" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>CafeVeloz</string>
    <key>CFBundleIdentifier</key>
    <string>com.cafeveloz.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>CafeVeloz</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

if command -v codesign >/dev/null 2>&1; then
  echo "[build] Signing ad-hoc..."
  codesign --force --sign - --timestamp=none "${APP_BUNDLE}"
fi

echo "[build] OK: ${APP_BUNDLE}"
