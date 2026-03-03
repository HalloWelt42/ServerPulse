#!/bin/bash
set -euo pipefail

# ServerPulse .app Builder
# Usage: ./build-app.sh [--release|--debug]

MODE="${1:---release}"
APP_NAME="ServerPulse"
BUNDLE_ID="com.serverpulse.app"
VERSION="1.0.3"
BUILD_NUMBER="1"
OUTPUT_DIR="$(pwd)/dist"
APP_PATH="${OUTPUT_DIR}/${APP_NAME}.app"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=== ${APP_NAME} App Builder ===${NC}"

# 1. Build
if [ "$MODE" = "--release" ]; then
    echo -e "${YELLOW}Building release...${NC}"
    swift build -c release 2>&1
    BINARY=".build/release/${APP_NAME}"
    RESOURCE_BUNDLE=".build/release/ServerPulse_ServerPulse.bundle"
else
    echo -e "${YELLOW}Building debug...${NC}"
    swift build 2>&1
    BINARY=".build/debug/${APP_NAME}"
    RESOURCE_BUNDLE=".build/debug/ServerPulse_ServerPulse.bundle"
fi

if [ ! -f "$BINARY" ]; then
    echo -e "${RED}Build failed: binary not found at ${BINARY}${NC}"
    exit 1
fi

echo -e "${GREEN}Build successful${NC}"

# 2. Create .app bundle structure
echo -e "${YELLOW}Creating app bundle...${NC}"
rm -rf "$APP_PATH"
mkdir -p "${APP_PATH}/Contents/MacOS"
mkdir -p "${APP_PATH}/Contents/Resources"

# 3. Copy binary
cp "$BINARY" "${APP_PATH}/Contents/MacOS/${APP_NAME}"

# 4. Copy SPM resource bundle (contains Localization + QRCodes)
# Bundle.module looks for ServerPulse_ServerPulse.bundle at Bundle.main.bundleURL
# For .app bundles, put in Contents/Resources and symlink to root for Bundle.module
RESOURCE_DEST="${APP_PATH}/Contents/Resources/ServerPulse_ServerPulse.bundle"
if [ -d "$RESOURCE_BUNDLE" ]; then
    cp -R "$RESOURCE_BUNDLE" "$RESOURCE_DEST"
    echo "  Resource bundle copied to Contents/Resources"
else
    echo -e "${YELLOW}  SPM resource bundle not found, copying from source...${NC}"
    mkdir -p "${RESOURCE_DEST}/Localization"
    mkdir -p "${RESOURCE_DEST}/QRCodes"
    cp -R "ServerPulse/Resources/Localization/"*.json "${RESOURCE_DEST}/Localization/" 2>/dev/null || true
    cp -R "ServerPulse/Resources/QRCodes/"*.svg "${RESOURCE_DEST}/QRCodes/" 2>/dev/null || true
    echo "  Resources copied from source"
fi
# Symlink at .app root so Bundle.module (which looks at Bundle.main.bundleURL) can find it
ln -sf "Contents/Resources/ServerPulse_ServerPulse.bundle" "${APP_PATH}/ServerPulse_ServerPulse.bundle"
echo "  Symlink created for Bundle.module compatibility"

# 5. Create Info.plist
cat > "${APP_PATH}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSMainStoryboardFile</key>
    <string></string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

echo "  Info.plist created"

# 5b. Copy app icon
ICON_SRC="ServerPulse/Resources/AppIcon.icns"
if [ -f "$ICON_SRC" ]; then
    cp "$ICON_SRC" "${APP_PATH}/Contents/Resources/AppIcon.icns"
    echo "  App icon copied"
fi

# 6. Ad-hoc code signing
echo -e "${YELLOW}Code signing...${NC}"
codesign --force --sign - "${APP_PATH}" 2>&1 || {
    echo -e "${YELLOW}Code signing warning (app will still run locally)${NC}"
}
echo -e "${GREEN}Code signed (ad-hoc)${NC}"

# 7. Summary
BINARY_SIZE=$(du -sh "${APP_PATH}/Contents/MacOS/${APP_NAME}" | cut -f1)
APP_SIZE=$(du -sh "${APP_PATH}" | cut -f1)

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo -e "  App:      ${APP_PATH}"
echo -e "  Binary:   ${BINARY_SIZE}"
echo -e "  Total:    ${APP_SIZE}"
echo -e "  Version:  ${VERSION} (${BUILD_NUMBER})"
echo ""
echo -e "  ${YELLOW}Doppelklick zum Starten oder:${NC}"
echo -e "  open \"${APP_PATH}\""
echo ""
echo -e "  ${YELLOW}Nach ~/Applications kopieren:${NC}"
echo -e "  cp -R \"${APP_PATH}\" ~/Applications/"
