---
phase: 09-video-thumbnail-async
reviewed: 2026-05-26T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesGrid.swift
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 9: Code Review Report

**Reviewed:** 2026-05-26
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

The async thumbnail loading refactor is structurally sound. The `.task(id: file.url)` pattern correctly cancels and restarts on URL change. The `AVAssetImageGenerator.image(at:)` async API is the right modern replacement for `copyCGImage(at:actualTime:)`. No critical issues were found. Three warnings relate to synchronous disk I/O on a cooperative thread, a stale preview on URL identity reuse, and a zero-size `NSImage` that may silently break layout. Two info items cover silent error suppression and a missing `maximumSize` cap.

---

## Warnings

### WR-01: Synchronous disk I/O (`NSImage(contentsOf:)`) inside a cooperative thread

**File:** `GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesGrid.swift:193`
**Issue:** The `previewImage` async property calls `NSImage(contentsOf: url)` synchronously for `.jpeg`/`.heic` cases. `NSImage(contentsOf:)` blocks the calling thread while reading from disk. Because `.task {}` runs on the Swift cooperative thread pool, this blocks a cooperative thread for the duration of the I/O, which degrades concurrency throughput whenever many image files are displayed simultaneously (e.g., a large batch load). The video path correctly avoids this via the `await` AVFoundation call.

**Fix:** Move the image load off the cooperative pool with a detached task or use `Task.detached` / `withCheckedContinuation` wrapper, or simply annotate the work explicitly:
```swift
case .jpeg, .heic:
    await Task.detached(priority: .utility) {
        NSImage(contentsOf: url)
    }.value
```
Alternatively, use `ImageIO` / `CGImageSource` with a background queue and bridge via `withCheckedContinuation`.

---

### WR-02: Stale preview remains visible when `file.url` identity is reused with new content

**File:** `GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesGrid.swift:139-142`
**Issue:** `.task(id: file.url)` triggers a re-load only when `file.url` changes. `SelectedMediaFile.id == SelectedMediaFile.url`, so if the same URL is replaced in the `files` array (e.g., after a metadata write updates `gpsStatus` and a new `SelectedMediaFile` value is created for the same URL), the task does NOT re-fire because the `id` is identical. The old `previewImage` @State persists in the view identity that SwiftUI keeps alive. This is not a crash but is a latent bug if thumbnails ever need refreshing.

**Fix:** If the preview should always reflect current file content, include a content-hash or `latestResult` version in the task `id`:
```swift
.task(id: "\(file.url.absoluteString)-\(file.latestResult)") {
    previewImage = await file.previewImage
}
```
Or, if thumbnails are genuinely static once loaded (file content never changes), add a comment documenting this assumption.

---

### WR-03: `NSImage(cgImage:size: .zero)` produces an image with zero intrinsic size

**File:** `GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesGrid.swift:206`
**Issue:** Passing `size: .zero` to `NSImage(cgImage:size:)` creates an image whose `size` property returns `(0, 0)`. When this image is rendered by `Image(nsImage:).resizable().scaledToFill()` inside a `.frame(height: 150)`, AppKit/SwiftUI must infer dimensions from the underlying CGImage pixel size. In practice this typically works, but the zero-size `NSImage` is semantically incorrect and can cause unexpected layout behaviour in edge cases (e.g., when passed to other code paths, accessibility, or if SwiftUI's image renderer changes). The CGImage already carries its dimensions.

**Fix:** Use the CGImage's actual pixel dimensions:
```swift
let size = NSSize(width: cgImage.width, height: cgImage.height)
return NSImage(cgImage: cgImage, size: size)
```

---

## Info

### IN-01: `try?` silently discards all `AVAssetImageGenerator` errors

**File:** `GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesGrid.swift:205`
**Issue:** `try? await generator.image(at: .zero)` swallows all errors — codec failures, missing video track, DRM-protected content, permission errors, and zero-length video all produce the same silent `nil`. The fallback icon is shown with no diagnostic signal. For a thumbnail this is arguably acceptable UI behaviour, but if thumbnail failures ever need debugging (e.g., "why is my video showing only a placeholder?"), there is no logging or error path to follow.

**Fix:** Consider logging in debug builds:
```swift
do {
    let (cgImage, _) = try await generator.image(at: .zero)
    return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
} catch {
    #if DEBUG
    print("[loadVideoThumbnail] failed for \(url.lastPathComponent): \(error)")
    #endif
    return nil
}
```

---

### IN-02: No `maximumSize` set on `AVAssetImageGenerator` — full-resolution frame decoded

**File:** `GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesGrid.swift:203-204`
**Issue:** `AVAssetImageGenerator` defaults to returning a CGImage at the native video resolution. A 4K video (3840×2160) will decode a full-resolution frame just to display it at 220×150 pt in the grid card. This wastes memory and decode time proportional to video resolution.

**Fix:** Cap the output to the display size:
```swift
generator.maximumSize = CGSize(width: GridCardMetrics.width * 2, height: GridCardMetrics.previewHeight * 2)
```
(The ×2 factor accounts for 2x Retina displays.)

---

_Reviewed: 2026-05-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
