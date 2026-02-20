#!/bin/bash

# Build the App Store (sandboxed) variant of Kalam.
# This build disables global hotkeys and CGEvent text insertion
# which are incompatible with macOS App Sandbox.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/release.config.sh"
cd "${SCRIPT_DIR}"

VERSION="${1:-${DEFAULT_VERSION}}"

# Build with APP_STORE_BUILD flag
echo "🔨 Building ${APP_NAME} v${VERSION} (App Store)..."
swift build -c release -Xswiftc -DAPP_STORE_BUILD

# Create app bundle structure
APP_DIR="$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Clean up old bundle
rm -rf "$APP_DIR"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Generate app icon
echo "🎨 Generating app icon..."
swift "${SCRIPT_DIR}/scripts/generate-icon.swift" "$RESOURCES_DIR"

# Copy executable
cp ".build/release/${EXECUTABLE_NAME}" "$MACOS_DIR/${EXECUTABLE_NAME}"

# Create Info.plist (App Store variant — no Apple Events or Accessibility descriptions)
cat > "$CONTENTS_DIR/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${EXECUTABLE_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS_VERSION}</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>${MICROPHONE_USAGE_DESCRIPTION}</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>${SPEECH_USAGE_DESCRIPTION}</string>
    <key>NSUserNotificationUsageDescription</key>
    <string>${NOTIFICATIONS_USAGE_DESCRIPTION}</string>
    <key>NSHumanReadableCopyright</key>
    <string>${COPYRIGHT_TEXT}</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Copy entitlements
cp "${SCRIPT_DIR}/Kalam.entitlements" "$CONTENTS_DIR/Resources/"

# Code sign with entitlements
if [ -n "${CODESIGN_IDENTITY:-}" ]; then
    echo "🔏 Code signing with identity: ${CODESIGN_IDENTITY}"
    codesign --force --deep --options runtime \
        --entitlements "${SCRIPT_DIR}/Kalam.entitlements" \
        --sign "${CODESIGN_IDENTITY}" "$APP_DIR"
else
    echo "🔏 Code signing (ad-hoc) with entitlements..."
    codesign --force --deep \
        --entitlements "${SCRIPT_DIR}/Kalam.entitlements" \
        --sign - "$APP_DIR"
fi

echo ""
echo "✅ App Store build created: $APP_DIR"
echo "   Features disabled: Global hotkey, auto text insertion"
echo "   Features enabled: Recording, transcription, clipboard copy"
echo ""
echo "   To test: open $APP_DIR"
echo ""
echo "   For App Store submission:"
echo "   1. Sign with your App Store certificate"
echo "   2. Create a .pkg installer: productbuild --component $APP_DIR /Applications ${APP_NAME}.pkg"
echo "   3. Upload via Transporter or xcrun altool"
