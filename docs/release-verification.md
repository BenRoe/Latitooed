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

Phase 5 verifies a signed `.app` only. Notarization, stapling, DMG/ZIP packaging, updater setup, installer packaging, public hosting, and Mac App Store packaging remain deferred release constraints.

## Build Artifact

Build the Release app on the macOS host so the result includes a signed `GPSMetadataEditor.app`:

```bash
cd /Users/ben/Git/image-exif-gps
DERIVED_DATA_PATH="$PWD/.build/DerivedData"

xcodebuild build \
  -project GPSMetadataEditor.xcodeproj \
  -scheme GPSMetadataEditor \
  -configuration Release \
  -destination 'platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_PATH"

APP_PATH="$DERIVED_DATA_PATH/Build/Products/Release/GPSMetadataEditor.app"
test -d "$APP_PATH"
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
- `codesign --verify --deep --strict --verbose=2 "$APP_PATH"` succeeds.
- `codesign -dv --verbose=4 "$APP_PATH"` prints signature details for release evidence.
- The bundled helper runs and prints its version after signature verification succeeds.

Static package checks are necessary but not sufficient. The signed packaged app still needs the host manual smoke to prove the app can execute the bundled helper and write GPS metadata to copied JPEG and HEIC files.

Interpretation notes:

- `codesign --verify --deep --strict --verbose=2 "$APP_PATH"` should exit 0.
- `codesign -dv --verbose=4 "$APP_PATH"` prints signing details to stderr; this is expected.
- Developer ID signing, notarization, and hardened runtime are still the outside-App-Store distribution path to finish later. Passing this Phase 5 checklist does not mean the app is notarized.

## Manual Smoke: No External ExifTool

Copy the committed fixtures to a temporary working directory before writing metadata:

```bash
cd /Users/ben/Git/image-exif-gps
SMOKE_DIR="$HOME/Desktop/gps-metadata-editor-smoke"
rm -rf "$SMOKE_DIR"
mkdir -p "$SMOKE_DIR"

cp GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.jpg "$SMOKE_DIR/sample.jpg"
cp GPSMetadataEditorTests/Fixtures/ReleaseSmoke/sample.heic "$SMOKE_DIR/sample.heic"

file "$SMOKE_DIR/sample.jpg" "$SMOKE_DIR/sample.heic"
open "$SMOKE_DIR"
```

Record the pre-write GPS baseline for the copied files:

```bash
"$APP_PATH/Contents/Resources/ExifTool/exiftool" \
  -gpslatitude -gpslongitude -gpsposition \
  "$SMOKE_DIR/sample.jpg" "$SMOKE_DIR/sample.heic"
```

Expected baseline: the copied fixtures should have no GPS tags, or at least should not already report Berlin `52.520008, 13.404954`.

Launch the signed app with external helper lookup stripped from `PATH`:

```bash
PATH=/usr/bin:/bin:/usr/sbin:/sbin "$APP_PATH/Contents/MacOS/GPSMetadataEditor"
```

In the app:

1. Select `$SMOKE_DIR/sample.jpg` and `$SMOKE_DIR/sample.heic`.
2. Set the target coordinate to Berlin: latitude `52.520008`, longitude `13.404954`.
3. Apply the location.
4. Confirm both file rows report success.

Inspect the copied files with the bundled helper path from the signed app:

```bash
"$APP_PATH/Contents/Resources/ExifTool/exiftool" \
  -gpslatitude -gpslongitude -gpsposition \
  "$SMOKE_DIR/sample.jpg" "$SMOKE_DIR/sample.heic"
```

Expected evidence:

- The pre-write baseline does not already match Berlin GPS values.
- The app launches and writes metadata while `PATH=/usr/bin:/bin:/usr/sbin:/sbin`.
- The copied JPEG and HEIC files show GPS values for `52.520008, 13.404954` or equivalent north/east formatted output.
- The tracked fixtures under `GPSMetadataEditorTests/Fixtures/ReleaseSmoke/` remain unchanged; only the temporary copies are mutated.
