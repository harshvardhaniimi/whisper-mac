# Launch Blueprint

This document turns the current project into a launch-ready product for:
- Gumroad
- Direct macOS download (Developer ID + notarization)
- Mac App Store
- Play Store (requires a separate Android app)

## 1. Product Brand Setup

Edit `release.config.sh` first:

- `APP_NAME`
- `EXECUTABLE_NAME`
- `BUNDLE_ID`
- `APP_SUPPORT_SUBDIR`
- `REPO_OWNER`
- `REPO_NAME`
- `DOWNLOAD_URL`
- permission strings (`MICROPHONE_USAGE_DESCRIPTION`, etc.)

After this, these scripts will use the new brand automatically:
- `build-app.sh`
- `scripts/create-release.sh`
- `install.sh`
- `uninstall.sh`
- `setup.sh` (model storage path messaging)

## 2. Legal + Compliance Checklist

- Create your own Privacy Policy URL.
- Create Terms of Use URL (required if you ship subscriptions or accounts later).
- Ensure your app name and logo do not infringe any trademark.
- Keep attribution for `whisper.cpp` and MIT-licensed dependencies.
- Ensure local processing claims are true in shipped behavior.

## 3. Packaging and Signing Paths

### A) Fast local package (development/testing)

```bash
./build-app.sh 1.0.0
```

This creates `${APP_NAME}.app` with ad-hoc signing.

### B) Release package for downloads (GitHub, Gumroad)

```bash
./scripts/create-release.sh 1.0.0
```

Output:
- `.build/release-1.0.0/${APP_NAME}.app`
- `${APP_NAME}-v1.0.0.zip`
- `${APP_NAME}.zip` (latest link asset)

Optional identity signing:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/create-release.sh 1.0.0
```

Notarize for direct macOS distribution:

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" \
NOTARY_KEYCHAIN_PROFILE="your-notary-profile" \
APPLE_TEAM_ID="TEAMID" \
./scripts/notarize-release.sh 1.0.0
```

## 4. Gumroad Launch Package

Ship:
- `${APP_NAME}.zip`
- short install instructions
- changelog for the version
- license key strategy (optional, if you later add license validation)

Gumroad product page assets:
- icon (1024x1024)
- 3 to 5 screenshots (16:10 or 16:9)
- 30 to 90 second demo video
- support email and refund policy

## 5. Mac App Store Path

Important: this is a separate distribution target from direct download.

You will need:
- Apple Developer Program account
- App Store Connect app record
- App Sandbox enabled + tested entitlements
- Archive/upload through Xcode
- Privacy answers + metadata + screenshots

Current code uses global hotkeys and text insertion behaviors that may need adjustment under sandbox constraints. Validate these features specifically for the Mac App Store build.

## 6. Play Store Path (Android)

This repository is native macOS Swift code. It cannot be submitted to Google Play as-is.

To launch on Play Store, build an Android client (Kotlin/Compose or cross-platform framework), then reuse:
- brand assets
- positioning/messaging
- privacy and legal docs
- backend/data policy decisions

## 7. Store Assets Checklist

Prepare once and reuse across channels:
- App icon (1024x1024 source + exported variants)
- Feature graphic / banner
- Screenshot set per channel
- Short description (80 chars)
- Long description (up to 4000 chars)
- Keywords (App Store)
- Category and subcategory
- Release notes template
- Support URL
- Privacy policy URL

## 8. Release Ops Checklist (Every Version)

1. Update app version.
2. Run build and sanity QA.
3. Run `./scripts/create-release.sh <version>`.
4. Smoke test on a clean macOS user account.
5. Publish release notes.
6. Upload zip to GitHub release and Gumroad.
7. Submit App Store build if applicable.
