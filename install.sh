#!/bin/bash

# WhisperMac Installer
# Usage: curl -sL https://raw.githubusercontent.com/harshvardhaniimi/whisper-mac/main/install.sh | bash

set -e

APP_NAME="WhisperMac"
DOWNLOAD_URL="https://github.com/harshvardhaniimi/whisper-mac/releases/latest/download/WhisperMac.zip"
INSTALL_DIR="/Applications"
TMP_DIR=$(mktemp -d)

echo "Installing $APP_NAME..."
echo ""

# Download
echo "Downloading..."
curl -sL "$DOWNLOAD_URL" -o "$TMP_DIR/WhisperMac.zip"

# Unzip
echo "Extracting..."
unzip -q "$TMP_DIR/WhisperMac.zip" -d "$TMP_DIR"

# Remove old version if exists
if [ -d "$INSTALL_DIR/$APP_NAME.app" ]; then
    echo "Removing previous version..."
    rm -rf "$INSTALL_DIR/$APP_NAME.app"
fi

# Move to Applications
echo "Installing to $INSTALL_DIR..."
mv "$TMP_DIR/$APP_NAME.app" "$INSTALL_DIR/"

# Remove quarantine attribute
echo "Removing quarantine..."
xattr -cr "$INSTALL_DIR/$APP_NAME.app"

# Cleanup
rm -rf "$TMP_DIR"

echo ""
echo "Installed successfully!"
echo ""
echo "To launch: open /Applications/$APP_NAME.app"
echo ""
echo "First launch setup:"
echo "  1. Right-click the app and select 'Open' (first time only)"
echo "  2. Grant Accessibility permission in System Settings"
echo "  3. Grant Microphone access when prompted"
echo "  4. Press Ctrl twice anywhere to start recording!"
echo ""
