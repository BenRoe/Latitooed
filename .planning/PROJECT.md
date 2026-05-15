# GPS Metadata Editor

## What This Is

GPS Metadata Editor is a native macOS SwiftUI app for bulk-editing GPS metadata on local image files, with best-effort support for common video files. It lets a user select multiple files, choose a target coordinate through Apple MapKit search, map interaction, or manual latitude/longitude entry, and apply that location to all selected files in one batch. The app is for Mac users who want a self-contained visual tool and should not require Homebrew, terminal commands, Google API keys, or a separately installed ExifTool.

## Core Value

Users can reliably apply a chosen GPS coordinate to many local media files without installing command-line dependencies.

## Requirements

### Validated

(None yet - ship to validate)

### Active

- [ ] User can select multiple local image and video files through a file picker.
- [ ] User can drag and drop supported files into the app window.
- [ ] User can view selected files with filename, file type, current GPS status, and write result.
- [ ] User can search for places using Apple MapKit without Google API keys.
- [ ] User can switch between standard, satellite, and hybrid map presentations.
- [ ] User can click the map or choose a search result to set the target coordinate.
- [ ] User can manually enter latitude and longitude as a fallback.
- [ ] User can apply the chosen coordinate to all selected files in one batch.
- [ ] User can see per-file success, warning, and failure messages after a batch write.
- [ ] The app bundles its metadata writer so users do not need Homebrew or a system ExifTool install.
- [ ] The app writes GPS metadata for common still-image formats, especially JPEG and HEIC.
- [ ] The app attempts best-effort location metadata writes for MOV and MP4, with clear warnings when support varies.
- [ ] The app handles filenames with spaces and Unicode characters.
- [ ] The app handles files on external drives through appropriate macOS file access.
- [ ] The app preserves originals by default or provides an explicit overwrite setting.
- [ ] The packaged, signed app can locate and execute its bundled metadata helper.

### Out of Scope

- Google Maps or Google Places integration - Apple MapKit avoids API-key setup and matches the native macOS direction.
- Requiring Homebrew or a separately installed ExifTool - this directly violates the self-contained app goal.
- Pure browser/local web implementation - browsers cannot reliably write arbitrary local EXIF metadata without a native helper.
- Full video metadata guarantees in v1 - MOV and MP4 support depends on container details and consuming app behavior, so v1 treats video as best effort.
- Mac App Store distribution in v1 - bundling and invoking a metadata helper may complicate App Store review and sandboxing; outside-App-Store distribution is the initial assumption.
- Pure native metadata backend in v1 - Apple APIs remain a future fallback path, but broad format support is the higher-priority first release goal.

## Context

The project starts from a plan to build a Mac-only GPS metadata editor using SwiftUI, MapKit, and a bundled metadata helper. The central product frustration is that current command-line workflows are powerful but inconvenient for users who want a visual batch tool. The app should feel like a native utility: direct file selection, clear state, reversible or cautious writes, and explicit per-file feedback.

ExifTool is the preferred v1 backend because it has broad, mature metadata coverage across still images and QuickTime-style video metadata. Apple Image I/O can write GPS keys for images through `CGImageDestination`, and AVFoundation can work with media metadata, but a pure native implementation would likely require more format-specific rewrite/export logic and would weaken the v1 promise around broad batch editing. To keep the architecture flexible, metadata writing should sit behind a dedicated service boundary so a native Image I/O or AVFoundation backend can be added later if packaging, sandboxing, or App Store goals change.

The app should use modern Swift, SwiftUI, Swift concurrency, and Apple-native UI patterns. Since it operates on user-selected local files, implementation needs to account for security-scoped resource access if sandboxing is enabled. Packaging must verify that the bundled helper works from the signed app bundle, not just during development.

## Constraints

- **Platform**: macOS first - the app is a native Mac utility, not iOS or web.
- **UI stack**: SwiftUI and MapKit - native UI and native Apple maps are core product assumptions.
- **Metadata backend**: Bundled ExifTool for v1 - chosen for broad write support and no external install requirement.
- **Distribution**: Outside the Mac App Store initially - reduces risk around bundled helper execution and sandbox review.
- **File access**: User-selected local files only - use file picker, drag and drop, and security-scoped access where required.
- **Video support**: Best effort - MOV and MP4 metadata behavior varies by container and consuming app.
- **Dependency policy**: No third-party Swift frameworks without explicit approval - follows repository guidance and keeps the app lightweight.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Build as a native macOS SwiftUI app | The product needs reliable local file access and a desktop batch-editing workflow. | - Pending |
| Use Apple MapKit for search and map selection | Avoids Google API keys and fits native macOS expectations. | - Pending |
| Bundle ExifTool as the v1 metadata backend | Best match for broad image support, QuickTime-style video location metadata, and self-contained distribution. | - Pending |
| Keep metadata writing behind a service boundary | Allows a future native Image I/O or AVFoundation backend without redesigning the UI workflow. | - Pending |
| Treat MOV and MP4 support as best effort | Video metadata support varies by container, tag location, and consuming application. | - Pending |
| Preserve originals by default or require explicit overwrite | Bulk metadata edits can be destructive, so v1 should bias toward recoverability. | - Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `$gsd-transition`):
1. Requirements invalidated? -> Move to Out of Scope with reason
2. Requirements validated? -> Move to Validated with phase reference
3. New requirements emerged? -> Add to Active
4. Decisions to log? -> Add to Key Decisions
5. "What This Is" still accurate? -> Update if drifted

**After each milestone** (via `$gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check - still the right priority?
3. Audit Out of Scope - reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-15 after initialization*
