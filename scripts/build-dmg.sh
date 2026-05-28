#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Latitooed"
SCHEME="Latitooed"
PROJECT="Latitooed.xcodeproj"
CONFIGURATION="Release"
ARCHIVE_PATH="/tmp/${APP_NAME}.xcarchive"
EXPORT_PATH="/tmp/${APP_NAME}-export"
DMG_DIR="$(pwd)/dist"
VERSION=$(defaults read "$(pwd)/${APP_NAME}.xcodeproj/project.pbxproj" MARKETING_VERSION 2>/dev/null || echo "1.0")
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

echo "==> Building ${APP_NAME} v${VERSION}"

# Archive
xcodebuild archive \
  -project "${PROJECT}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -archivePath "${ARCHIVE_PATH}" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty 2>/dev/null || true

# Export app from archive
APP_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"

if [ ! -d "${APP_PATH}" ]; then
  echo "ERROR: ${APP_PATH} not found. Build may have failed."
  exit 1
fi

echo "==> Ad-hoc signing .app"
codesign --deep --force --sign - "${APP_PATH}"

echo "==> Creating DMG"
mkdir -p "${DMG_DIR}"
STAGING="/tmp/${APP_NAME}-dmg-staging"
rm -rf "${STAGING}"
mkdir -p "${STAGING}"
cp -R "${APP_PATH}" "${STAGING}/"
ln -s /Applications "${STAGING}/Applications"

hdiutil create \
  -volname "${APP_NAME}" \
  -srcfolder "${STAGING}" \
  -ov \
  -format UDZO \
  "${DMG_DIR}/${DMG_NAME}"

rm -rf "${STAGING}"

echo ""
echo "==> Done: dist/${DMG_NAME}"
echo ""
echo "NOTE: Users will see a Gatekeeper warning on first launch."
echo "      They can right-click → Open, or run:"
echo "      xattr -cr /Applications/${APP_NAME}.app"
