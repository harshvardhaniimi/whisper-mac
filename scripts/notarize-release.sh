#!/bin/bash

# Notarize a signed release app bundle for direct macOS distribution.
# Usage: CODESIGN_IDENTITY="Developer ID Application: Name (TEAMID)" \
#        NOTARY_KEYCHAIN_PROFILE="my-notary-profile" \
#        ./scripts/notarize-release.sh [version] [app_path]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../release.config.sh"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

VERSION="${1:-${DEFAULT_VERSION}}"
APP_PATH="${2:-.build/release-${VERSION}/${APP_NAME}.app}"
ZIP_PATH=".build/notary-${APP_NAME}-v${VERSION}.zip"

if [ ! -d "${APP_PATH}" ]; then
    echo "❌ App not found: ${APP_PATH}"
    echo "Run ./scripts/create-release.sh ${VERSION} first."
    exit 1
fi

if [ -z "${CODESIGN_IDENTITY:-}" ]; then
    echo "❌ Missing CODESIGN_IDENTITY environment variable."
    echo "Example: CODESIGN_IDENTITY=\"Developer ID Application: Your Name (TEAMID)\""
    exit 1
fi

if [ -z "${NOTARY_KEYCHAIN_PROFILE:-}" ]; then
    echo "❌ Missing NOTARY_KEYCHAIN_PROFILE environment variable."
    echo "Create one with xcrun notarytool store-credentials, then re-run."
    exit 1
fi

echo "🔏 Signing ${APP_PATH} with Developer ID..."
codesign --force --deep --options runtime --sign "${CODESIGN_IDENTITY}" "${APP_PATH}"

echo "📦 Preparing notarization archive..."
rm -f "${ZIP_PATH}"
ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"

echo "🧾 Submitting to Apple notarization service..."
NOTARY_ARGS=(submit "${ZIP_PATH}" --keychain-profile "${NOTARY_KEYCHAIN_PROFILE}" --wait)
if [ -n "${APPLE_TEAM_ID:-}" ]; then
    NOTARY_ARGS+=(--team-id "${APPLE_TEAM_ID}")
fi
xcrun notarytool "${NOTARY_ARGS[@]}"

echo "📌 Stapling notarization ticket..."
xcrun stapler staple "${APP_PATH}"

echo "✅ Verifying Gatekeeper assessment..."
spctl --assess --type execute --verbose=4 "${APP_PATH}"

echo ""
echo "🎉 Notarization complete:"
echo "   ${APP_PATH}"
echo "   ${ZIP_PATH}"
