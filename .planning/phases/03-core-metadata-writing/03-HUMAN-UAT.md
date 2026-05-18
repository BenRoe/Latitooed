---
status: partial
phase: 03-core-metadata-writing
source: [03-VERIFICATION.md]
started: 2026-05-18T15:30:00Z
updated: 2026-05-18T15:30:00Z
---

# Phase 03 Human UAT

## Current Test

Awaiting host-side Xcode and macOS app verification.

## Tests

### 1. Xcode test suite
expected: `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test` completes successfully.
result: [pending]

### 2. Apply Location readiness
expected: Apply Location is disabled until at least one selected file and one coordinate exist, then enabled when no batch is running.
result: [pending]

### 3. Destructive confirmation
expected: Apply Location shows overwrite/no-restore copy; Abort does not invoke the writer or alter selected-file results.
result: [pending]

### 4. Real JPEG/HEIC write smoke
expected: On copied sample files, Overwrite writes GPS metadata via bundled ExifTool and updates row statuses plus compact footer counts.
result: [pending]

## Summary

total: 4
passed: 0
issues: 0
pending: 4
skipped: 0
blocked: 0

## Gaps
