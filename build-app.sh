#!/bin/bash

# Build the app
echo "🔨 Building WhisperMac..."
swift build -c release

# Create app bundle structure
APP_NAME="WhisperMac"
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
swift scripts/generate-icon.swift "$RESOURCES_DIR"

# Copy executable
cp .build/release/WhisperMac "$MACOS_DIR/"

# Ad-hoc code sign the app (helps with some Gatekeeper issues)
echo "🔏 Code signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_DIR"

# Create Info.plist
cat > "$CONTENTS_DIR/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>WhisperMac</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.whisper.mac</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>WhisperMac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>WhisperMac needs access to your microphone to transcribe speech.</string>
    <key>NSSpeechRecognitionUsageDescription</key>
    <string>WhisperMac uses Apple Speech Recognition to convert your speech to text.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>WhisperMac needs to send keystrokes to insert transcribed text at your cursor position.</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright 2024. MIT License.</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSSupportsSuddenTermination</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo ""
echo "✅ App bundle created: $APP_DIR"
echo "   To run: open $APP_DIR"
