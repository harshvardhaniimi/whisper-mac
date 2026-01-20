#!/bin/bash

# Create a release build of WhisperMac
# Usage: ./scripts/create-release.sh [version]

set -e

VERSION=${1:-"1.0.0"}
APP_NAME="WhisperMac"
BUILD_DIR=".build/release-${VERSION}"
ZIP_NAME_VERSIONED="${APP_NAME}-v${VERSION}.zip"
ZIP_NAME_LATEST="${APP_NAME}.zip"

echo "🔨 Building ${APP_NAME} v${VERSION}..."

# Build release version
swift build -c release

# Create clean app bundle
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS"
mkdir -p "${BUILD_DIR}/${APP_NAME}.app/Contents/Resources"

# Generate app icon
echo "🎨 Generating app icon..."
swift scripts/generate-icon.swift "${BUILD_DIR}/${APP_NAME}.app/Contents/Resources"

# Copy executable
cp .build/release/WhisperMac "${BUILD_DIR}/${APP_NAME}.app/Contents/MacOS/"

# Create Info.plist with version
cat > "${BUILD_DIR}/${APP_NAME}.app/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.whisper.mac</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${VERSION}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>WhisperMac needs microphone access to transcribe your speech.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>WhisperMac uses speech recognition to convert your voice to text.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>WhisperMac needs to send keystrokes to insert transcribed text at your cursor.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2024. MIT License.</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

# Ad-hoc code sign the app
echo "🔏 Code signing (ad-hoc)..."
codesign --force --deep --sign - "${BUILD_DIR}/${APP_NAME}.app"

# Create zips for distribution
echo "📦 Creating release zips..."
cd "${BUILD_DIR}"
zip -r "../../${ZIP_NAME_VERSIONED}" "${APP_NAME}.app"
zip -r "../../${ZIP_NAME_LATEST}" "${APP_NAME}.app"
cd ../..

echo ""
echo "✅ Release created successfully!"
echo ""
echo "   App:  ${BUILD_DIR}/${APP_NAME}.app"
echo "   Zips: ${ZIP_NAME_VERSIONED} (for archives)"
echo "         ${ZIP_NAME_LATEST} (for 'latest' download link)"
echo ""
echo "📝 Next steps:"
echo "   1. Test the app: open '${BUILD_DIR}/${APP_NAME}.app'"
echo "   2. Create GitHub release v${VERSION}"
echo "   3. Upload BOTH zip files to the release"
echo "   4. The docs page 'latest' link will automatically work"
echo ""
echo "⚠️  Users downloading from GitHub will need to:"
echo "   - Run: xattr -cr ~/Downloads/WhisperMac.app"
echo "   - Then right-click → Open (first time, to bypass Gatekeeper)"
echo "   - Grant Accessibility permissions in System Settings"
echo ""
echo "   (This is required because the app is not notarized with Apple)"
