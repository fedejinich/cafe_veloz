#!/bin/bash
set -euo pipefail

APP_NAME="CafeVeloz"
APP_DIR="${HOME}/Applications/${APP_NAME}.app"
CONTENTS_DIR="${APP_DIR}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "Building ${APP_NAME} in release mode..."
swift build -c release 2>&1

EXEC_PATH=$(swift build -c release --show-bin-path)/${APP_NAME}

if [ ! -f "$EXEC_PATH" ]; then
    echo "Error: Executable not found at $EXEC_PATH"
    exit 1
fi

# Kill running instance if any
pkill -f "${APP_DIR}/Contents/MacOS/${APP_NAME}" 2>/dev/null || true
sleep 0.5

# Remove old app bundle
rm -rf "$APP_DIR"

echo "Creating app bundle at ${APP_DIR}..."
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Copy executable
cp "$EXEC_PATH" "$MACOS_DIR/${APP_NAME}"

# Copy the resource bundle if it exists
BUNDLE_PATH="$(swift build -c release --show-bin-path)/CafeVeloz_CafeVeloz.bundle"
if [ -d "$BUNDLE_PATH" ]; then
    cp -R "$BUNDLE_PATH" "$MACOS_DIR/"
fi

# Generate icns from the PNGs in the asset catalog
ICONSET_DIR="/tmp/${APP_NAME}.iconset"
rm -rf "$ICONSET_DIR"
mkdir -p "$ICONSET_DIR"

ICON_SRC="Sources/CafeVeloz/Resources/Assets.xcassets/AppIcon.appiconset"

cp "${ICON_SRC}/icon_16.png"    "$ICONSET_DIR/icon_16x16.png"
cp "${ICON_SRC}/icon_16@2x.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "${ICON_SRC}/icon_32.png"    "$ICONSET_DIR/icon_32x32.png"
cp "${ICON_SRC}/icon_32@2x.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "${ICON_SRC}/icon_128.png"   "$ICONSET_DIR/icon_128x128.png"
cp "${ICON_SRC}/icon_128@2x.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "${ICON_SRC}/icon_256.png"   "$ICONSET_DIR/icon_256x256.png"
cp "${ICON_SRC}/icon_256@2x.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "${ICON_SRC}/icon_512.png"   "$ICONSET_DIR/icon_512x512.png"
cp "${ICON_SRC}/icon_512@2x.png" "$ICONSET_DIR/icon_512x512@2x.png"

iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
rm -rf "$ICONSET_DIR"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>CafeVeloz</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.cafeVeloz.app</string>
    <key>CFBundleName</key>
    <string>Cafe Veloz</string>
    <key>CFBundleDisplayName</key>
    <string>Cafe Veloz</string>
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

echo ""
echo "Installed ${APP_NAME}.app to ~/Applications/"
echo "You can now launch it from Spotlight or Finder."
