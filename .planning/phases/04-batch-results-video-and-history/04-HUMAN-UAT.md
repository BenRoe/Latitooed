---
status: partial
phase: 04-batch-results-video-and-history
source: [04-VERIFICATION.md]
started: 2026-05-19T10:23:50Z
updated: 2026-05-19T10:23:50Z
---

# Phase 04 Human UAT

## Current Test

Awaiting host-side Xcode and app smoke verification.

## Tests

### 1. Host Xcode Tests
expected: `xcodebuild -project GPSMetadataEditor.xcodeproj -scheme GPSMetadataEditor -destination 'platform=macOS' test` passes on the macOS host.
result: [pending]

### 2. Batch Progress And Diagnostics
expected: A small JPEG/HEIC batch shows filename-first footer progress, updates rows after each file completes, and shows collapsed diagnostics only for warning/failure selected rows.
result: [pending]

### 3. MOV/MP4 Best-Effort Writes
expected: One sample MOV and one sample MP4 either receive QuickTime-compatible GPS metadata or show a clear helper-derived warning/failure.
result: [pending]

### 4. Recent Coordinate Reuse
expected: Recent Coordinates and Recent Batches can each update the active coordinate panel.
result: [pending]

### 5. History Privacy Boundary
expected: Recent Batches shows counts-only summaries and no prior filenames, file paths, thumbnails, diagnostics, restore, reopen, or previous per-file results.
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps

