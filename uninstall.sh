#!/bin/bash

# WhisperMac Uninstaller
# Completely removes WhisperMac and all associated data

set -e

echo "🗑️  WhisperMac Uninstaller"
echo "========================="
echo ""
echo "This will remove:"
echo "  • WhisperMac.app from /Applications"
echo "  • All downloaded models (~100MB - 3GB)"
echo "  • Transcription history"
echo "  • App preferences"
echo ""

read -p "Are you sure you want to uninstall WhisperMac? (y/N) " -n 1 -r < /dev/tty
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "Uninstalling WhisperMac..."

# Quit the app if running
echo "• Quitting WhisperMac if running..."
pkill -f "WhisperMac" 2>/dev/null || true
sleep 1

# Remove app from Applications
if [ -d "/Applications/WhisperMac.app" ]; then
    echo "• Removing /Applications/WhisperMac.app..."
    rm -rf "/Applications/WhisperMac.app"
fi

# Remove app data (models, history)
APP_SUPPORT="$HOME/Library/Application Support/WhisperMac"
if [ -d "$APP_SUPPORT" ]; then
    echo "• Removing app data from $APP_SUPPORT..."
    rm -rf "$APP_SUPPORT"
fi

# Remove preferences
PREFS="$HOME/Library/Preferences/com.whisper.WhisperMac.plist"
if [ -f "$PREFS" ]; then
    echo "• Removing preferences..."
    rm -f "$PREFS"
fi

# Remove any cached data
CACHES="$HOME/Library/Caches/WhisperMac"
if [ -d "$CACHES" ]; then
    echo "• Removing cached data..."
    rm -rf "$CACHES"
fi

# Remove debug logs if present
rm -f "$HOME/whisper-debug.log" 2>/dev/null || true
rm -f "$HOME/whisper-hotkey.log" 2>/dev/null || true

echo ""
echo "✅ WhisperMac has been completely uninstalled."
echo ""
echo "Thank you for trying WhisperMac!"
echo "Feedback welcome at: https://github.com/harshvardhaniimi/whisper-mac/issues"
