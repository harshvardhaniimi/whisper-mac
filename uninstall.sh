#!/bin/bash

# Uninstaller
# Completely removes app binaries and local app data

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "${SCRIPT_DIR}/release.config.sh" ]; then
    source "${SCRIPT_DIR}/release.config.sh"
else
    APP_NAME="${APP_NAME:-Kalam}"
    EXECUTABLE_NAME="${EXECUTABLE_NAME:-Kalam}"
    APP_SUPPORT_SUBDIR="${APP_SUPPORT_SUBDIR:-Kalam}"
    BUNDLE_ID="${BUNDLE_ID:-io.kalam.app}"
    FEEDBACK_URL="${FEEDBACK_URL:-https://github.com/harshvardhaniimi/whisper-mac/issues}"
fi

echo "🗑️  ${APP_NAME} Uninstaller"
echo "========================="
echo ""
echo "This will remove:"
echo "  • ${APP_NAME}.app from /Applications and ~/Applications"
echo "  • All downloaded models (~100MB - 3GB)"
echo "  • Transcription history"
echo "  • App preferences"
echo ""

read -p "Are you sure you want to uninstall ${APP_NAME}? (y/N) " -n 1 -r < /dev/tty
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

echo ""
echo "Uninstalling ${APP_NAME}..."

# Quit the app if running
echo "• Quitting ${APP_NAME} if running..."
pkill -f "${EXECUTABLE_NAME}" 2>/dev/null || true
sleep 1

# Remove app from Applications
if [ -d "/Applications/${APP_NAME}.app" ]; then
    echo "• Removing /Applications/${APP_NAME}.app..."
    rm -rf "/Applications/${APP_NAME}.app"
fi

if [ -d "$HOME/Applications/${APP_NAME}.app" ]; then
    echo "• Removing ~/Applications/${APP_NAME}.app..."
    rm -rf "$HOME/Applications/${APP_NAME}.app"
fi

# Remove app data (models, history)
APP_SUPPORT="$HOME/Library/Application Support/${APP_SUPPORT_SUBDIR}"
if [ -d "$APP_SUPPORT" ]; then
    echo "• Removing app data from $APP_SUPPORT..."
    rm -rf "$APP_SUPPORT"
fi

# Remove preferences
PREFS="$HOME/Library/Preferences/${BUNDLE_ID}.plist"
if [ -f "$PREFS" ]; then
    echo "• Removing preferences..."
    rm -f "$PREFS"
fi

# Remove any cached data
CACHES="$HOME/Library/Caches/${APP_SUPPORT_SUBDIR}"
if [ -d "$CACHES" ]; then
    echo "• Removing cached data..."
    rm -rf "$CACHES"
fi

# Remove debug logs if present
rm -f "$HOME/kalam-debug.log" 2>/dev/null || true
rm -f "$HOME/kalam-hotkey.log" 2>/dev/null || true

echo ""
echo "✅ ${APP_NAME} has been completely uninstalled."
echo ""
echo "Thank you for trying ${APP_NAME}!"
echo "Feedback welcome at: ${FEEDBACK_URL}"
