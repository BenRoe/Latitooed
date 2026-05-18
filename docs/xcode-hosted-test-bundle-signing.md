# Xcode Hosted Test Bundle Signing

## Symptom

The test bundle built but failed to load into the app host:

```text
GPSMetadataEditorTests.xctest ... not valid for use in process:
mapping process and mapped file (non-platform) have different Team IDs
```

Later, disabling the app host caused linker failures for app symbols referenced by tests.

## Cause

The macOS app test target needs a compatible app host for `@testable import GPSMetadataEditor`, but Debug hardened runtime/signing settings can prevent the test bundle from loading into that host.

## Fix

Keep hosted tests configured with `TEST_HOST` and `BUNDLE_LOADER`, use automatic/local debug signing, and disable hardened runtime for Debug app test runs while leaving Release hardened runtime enabled.

## Verification

Run:

```bash
xcodebuild test -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS'
```

The test bundle should load and execute instead of failing during `dlopen`.

