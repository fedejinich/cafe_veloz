#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="CafeVeloz"
VERSION_FILE="${ROOT_DIR}/VERSION"
DIST_DIR="${ROOT_DIR}/dist"
APP_BUNDLE="${DIST_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
BIN_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"
BIN_PATH="${BIN_DIR}/${APP_NAME}"
INFO_PLIST_PATH="${CONTENTS_DIR}/Info.plist"
MODULE_CACHE_DIR="${ROOT_DIR}/.build/ModuleCache"
ICNS_SOURCE="${ROOT_DIR}/Sources/CafeVeloz/Resources/AppIcon.icns"
ICON_PATH="${RESOURCES_DIR}/AppIcon.icns"
RESOURCE_SOURCE_DIR="${ROOT_DIR}/Sources/CafeVeloz/Resources"

read_version() {
  if [[ -f "${VERSION_FILE}" ]]; then
    tr -d '[:space:]' < "${VERSION_FILE}"
  else
    echo "1.0.0"
  fi
}

APP_VERSION="${APP_VERSION:-$(read_version)}"
APP_BUILD="${APP_BUILD:-1}"
BUNDLE_IDENTIFIER="${BUNDLE_IDENTIFIER:-com.cafeveloz.app}"
APP_CATEGORY="${APP_CATEGORY:-public.app-category.utilities}"
ZIP_PATH="${DIST_DIR}/${APP_NAME}-${APP_VERSION}.zip"
CHECKSUM_PATH="${ZIP_PATH}.sha256"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[build] Error: required command not found: $1" >&2
    exit 1
  fi
}

swift_release_build() {
  mkdir -p "${MODULE_CACHE_DIR}"
  CLANG_MODULE_CACHE_PATH="${MODULE_CACHE_DIR}" \
    swift build --disable-sandbox -c release --product "${APP_NAME}"
}

swift_release_bin_dir() {
  CLANG_MODULE_CACHE_PATH="${MODULE_CACHE_DIR}" \
    swift build --disable-sandbox -c release --show-bin-path
}

copy_app_icon() {
  if [[ ! -f "${ICNS_SOURCE}" ]]; then
    echo "[build] Error: app icon not found at ${ICNS_SOURCE}" >&2
    echo "[build] Regenerate it with scripts/generate_app_icon_icns.py" >&2
    exit 1
  fi

  cp "${ICNS_SOURCE}" "${ICON_PATH}"
}

write_info_plist() {
  cat > "${INFO_PLIST_PATH}" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Cafe Veloz</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_IDENTIFIER}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Cafe Veloz</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${APP_VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${APP_BUILD}</string>
    <key>LSApplicationCategoryType</key>
    <string>${APP_CATEGORY}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
PLIST
}

sign_app_bundle() {
  if ! command -v codesign >/dev/null 2>&1; then
    echo "[build] Warning: codesign not available, skipping signing"
    return
  fi

  local identity="${CODESIGN_IDENTITY:--}"
  local codesign_args=(--force --deep --sign "${identity}")

  if [[ "${identity}" == "-" ]]; then
    codesign_args+=(--timestamp=none)
  else
    codesign_args+=(--timestamp --options runtime)
  fi

  echo "[build] Signing app bundle with identity '${identity}'..."
  codesign "${codesign_args[@]}" "${APP_BUNDLE}"
  codesign --verify --deep --strict "${APP_BUNDLE}"
}

package_release_zip() {
  require_command ditto

  rm -f "${ZIP_PATH}" "${CHECKSUM_PATH}"

  echo "[build] Creating zip artifact..."
  ditto -c -k --sequesterRsrc --keepParent "${APP_BUNDLE}" "${ZIP_PATH}"
  shasum -a 256 "${ZIP_PATH}" > "${CHECKSUM_PATH}"
}

echo "[build] Compiling release binary..."
swift_release_build
RELEASE_BIN_DIR="$(swift_release_bin_dir)"
RELEASE_BIN="${RELEASE_BIN_DIR}/${APP_NAME}"

if [[ ! -x "${RELEASE_BIN}" ]]; then
  echo "[build] Error: release binary not found at ${RELEASE_BIN}" >&2
  exit 1
fi

echo "[build] Regenerating .app bundle in dist/..."
rm -rf "${APP_BUNDLE}"
mkdir -p "${BIN_DIR}"
mkdir -p "${RESOURCES_DIR}"
cp "${RELEASE_BIN}" "${BIN_PATH}"
chmod +x "${BIN_PATH}"

echo "[build] Copying runtime resources..."
cp "${RESOURCE_SOURCE_DIR}/coffee_cup.png" "${RESOURCES_DIR}/"
cp "${RESOURCE_SOURCE_DIR}/coffee_cup@2x.png" "${RESOURCES_DIR}/"
cp "${RESOURCE_SOURCE_DIR}/assets_index.json" "${RESOURCES_DIR}/"

echo "[build] Generating app icon..."
copy_app_icon

echo "[build] Writing Info.plist..."
write_info_plist

sign_app_bundle
package_release_zip

echo "[build] OK: ${APP_BUNDLE}"
echo "[build] ZIP: ${ZIP_PATH}"
echo "[build] SHA256: ${CHECKSUM_PATH}"
