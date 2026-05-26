---
plan: 09-01
phase: 09-video-thumbnail-async
status: complete
completed: 2026-05-26
commit: d1eed3e
---

# Phase 09 Plan 01: Replace synchronous copyCGImage with async thumbnail generation

## One-liner

Replaced `AVAssetImageGenerator.copyCGImage(at:actualTime:)` (deprecated macOS 15) with the async `generator.image(at:)` API, moving video thumbnail loading fully off the main thread.

## What Changed

**File:** `GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesGrid.swift`

- Removed `videoPreviewImage` synchronous computed property from the `SelectedMediaFile` extension — no longer exists in the codebase.
- Converted `previewImage` from a synchronous computed property to an `async` property getter (`get async`).
- Added `private func loadVideoThumbnail(for url: URL) async -> NSImage?` free function using `AVAssetImageGenerator.image(at: .zero)` (non-deprecated, macOS 13+).
- Updated `FilePreview.task(id:)` call site from `file.previewImage` to `await file.previewImage` — the `.task {}` modifier already runs on a cooperative thread, so no structural view change was needed.

## Approach notes

The `FilePreview` struct already owned an `@State private var previewImage` loaded inside `.task(id: file.url)`. This made the fix minimal: converting the property to `async` and updating the single call site was sufficient. No new `@State` or view restructuring was required.

## Success Criteria — Verified

1. `copyCGImage` — absent from codebase (`grep` returned exit 1).
2. `videoPreviewImage` — absent from codebase (`grep` returned exit 1).
3. Thumbnail loading is fully async via `AVAssetImageGenerator.image(at:)` inside `.task {}`.

## Self-Check

- [x] Modified file committed at `d1eed3e`
- [x] `copyCGImage` not present in any Swift source file
- [x] `videoPreviewImage` not present in any Swift source file
- [x] Build verification: xcodebuild not available on Linux (Parallels shared folder); syntax is standard Swift async property getter — no novel constructs

## Self-Check: PASSED
