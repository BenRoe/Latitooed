#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: $0 /path/to/GPSMetadataEditor.app" >&2
  exit 64
fi

APP_PATH="$1"
HELPER_PATH="$APP_PATH/Contents/Resources/ExifTool/exiftool"

if [ ! -d "$APP_PATH" ]; then
  echo "error: app bundle not found: $APP_PATH" >&2
  exit 66
fi

if [ ! -f "$HELPER_PATH" ]; then
  echo "error: bundled ExifTool helper missing: $HELPER_PATH" >&2
  exit 66
fi

if [ ! -x "$HELPER_PATH" ]; then
  echo "error: bundled ExifTool helper is not executable: $HELPER_PATH" >&2
  exit 77
fi

echo "Bundled ExifTool helper:"
echo "  $HELPER_PATH"
echo

echo "Code signature verification:"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"
echo

echo "Code signature details:"
codesign -dv --verbose=4 "$APP_PATH"
echo

echo "Bundled ExifTool version:"
"$HELPER_PATH" -ver
