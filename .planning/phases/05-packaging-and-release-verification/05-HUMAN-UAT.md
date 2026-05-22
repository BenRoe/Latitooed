---
status: partial
phase: 05-packaging-and-release-verification
source: [05-VERIFICATION.md, docs/release-verification.md]
started: 2026-05-22T19:20:00Z
updated: 2026-05-22T19:20:00Z
---

# Phase 05 Human UAT

## Current Test

Host-side signed app verification is pending. Follow `docs/release-verification.md` and paste results here.

## Tests

### 1. PKG-01 Resource Inclusion
expected: `scripts/verify-packaged-app.sh "$APP_PATH"` finds `Contents/Resources/ExifTool/exiftool` inside `GPSMetadataEditor.app` and confirms it is executable.
result: [pending]

### 2. PKG-02 Signed Helper Execution
expected: The signed app bundle can run the bundled helper, and the verifier prints the helper version from `"$APP_PATH/Contents/Resources/ExifTool/exiftool"`.
result: [pending]

### 3. PKG-03 Helper Failure Coverage
expected: Host `xcodebuild test -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS'` passes, including missing-helper, non-executable-helper, and process-runner failure tests.
result: [pending]

### 4. PKG-04 Negative-PATH JPEG/HEIC Write Smoke
expected: Launching the signed app with `PATH=/usr/bin:/bin:/usr/sbin:/sbin` can write Berlin coordinate `52.520008, 13.404954` to copied `sample.jpg` and `sample.heic` files.
result: [pending]

### 5. Pre-Write Metadata Baseline
expected: Before launching the app, bundled-helper inspection of copied `sample.jpg` and `sample.heic` shows no GPS tags or values that do not already match Berlin.
result: [pending]

### 6. Metadata Inspection
expected: `"$APP_PATH/Contents/Resources/ExifTool/exiftool" -gpslatitude -gpslongitude -gpsposition "$SMOKE_DIR/sample.jpg" "$SMOKE_DIR/sample.heic"` reports GPS values matching Berlin for both copied files.
result: [pending]

### 7. Packaging Notes
expected: `docs/release-verification.md` states that Phase 5 verifies a signed `.app` only and defers notarization, stapling, DMG/ZIP packaging, updater, installer, public hosting, and Mac App Store packaging.
result: [pending]

## Summary

total: 7
passed: 0
issues: 0
pending: 7
skipped: 0
blocked: 0

## Gaps
