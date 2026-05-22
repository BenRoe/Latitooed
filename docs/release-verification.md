# Release Verification

## Scope

Phase 5 verifies a signed `GPSMetadataEditor.app` bundle only. It does not complete notarization, stapling, DMG packaging, ZIP packaging, updater setup, installer packaging, public download hosting, or Mac App Store readiness.

The app must use the bundled helper at `Contents/Resources/ExifTool/exiftool`. Release verification must not depend on Homebrew ExifTool or any separately installed system helper.

## VM Checks

These checks can run from the VM checkout:

```bash
bash -n scripts/verify-packaged-app.sh
file GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.jpg GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.heic
rg -n "Contents/Resources/ExifTool/exiftool|codesign --verify|notarization" scripts docs/release-verification.md
```

Expected fixture output:

- `sample.jpg` reports `JPEG image data`.
- `sample.heic` reports `HEIF`, `HEIC`, or `ISO Media`.

## Host Prerequisites

Host-side Xcode, signing, bundle execution, and SwiftUI smoke verification must run on the macOS host, not in the VM.

```bash
cd /Users/ben/Git/image-exif-gps
xcodebuild test -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS'
```

## Build Artifact

Build or archive the app on the macOS host so the result includes a signed `GPSMetadataEditor.app`. The exact build output path may vary by Xcode configuration; set `APP_PATH` to the resulting app bundle before running package checks.

```bash
APP_PATH="/path/to/GPSMetadataEditor.app"
```

## Static Package Checks

Run the static package verification script against the built app:

```bash
scripts/verify-packaged-app.sh "$APP_PATH"
```

The script verifies:

- `GPSMetadataEditor.app` exists.
- `Contents/Resources/ExifTool/exiftool` exists inside the app bundle.
- The bundled helper is executable.
- The bundled helper runs and prints its version.
- `codesign --verify --deep --strict --verbose=2 "$APP_PATH"` succeeds.
- `codesign -dv --verbose=4 "$APP_PATH"` prints signature details for release evidence.

Static package checks are necessary but not sufficient. The signed packaged app still needs the host manual smoke to prove the app can execute the bundled helper and write GPS metadata to copied JPEG and HEIC files.
