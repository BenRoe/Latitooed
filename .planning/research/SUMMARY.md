# Research Summary: GPS Metadata Editor

## Stack

Build a native macOS SwiftUI app using MapKit for coordinate selection, SwiftData for lightweight history/preferences, and bundled ExifTool for v1 metadata writes. Apple docs support SwiftUI MapKit primitives such as `Map`, `MapStyle`, map controls, and selectable map features. ExifTool docs support writing EXIF GPS composite positions and QuickTime-style GPS metadata such as MP4 `Keys:GPSCoordinates`.

## Product Shape

The MVP should be a focused desktop utility:

1. Select or drop multiple files.
2. Choose one coordinate through search, map interaction, or manual entry.
3. Apply that coordinate to all selected files.
4. Show progress and per-file results.
5. Preserve originals by default or require explicit overwrite.

## Research-Driven Decisions

| Decision | Recommendation |
|----------|----------------|
| Metadata backend | Bundled ExifTool for v1. |
| Native metadata APIs | Keep as future backend option behind `MetadataWriter`. |
| Video support | Best effort only, with clear warnings and verification samples. |
| Persistence | SwiftData for recent coordinates, batch history, and preferences; not media storage. |
| Execution | Sequential, structured async batch writes for v1, matching project config and simplifying progress/cancellation. |
| UI state | `@MainActor @Observable` models, separate SwiftUI views per concern. |

## Requirements Implications

Table stakes for v1:

- Multi-file picker and drag-and-drop.
- File classification and selected file table.
- MapKit search, map style switching, map/manual coordinate selection.
- Batch metadata writes with per-file results.
- Bundled helper packaging verification.
- JPEG/HEIC support, plus explicit best-effort MOV/MP4 support.

Defer unless explicitly needed:

- Full native Image I/O/AVFoundation backend.
- App Store distribution.
- Rich batch history beyond simple recent coordinates/results.
- Exportable reports.

## Watch Out For

- Do not accidentally depend on Homebrew ExifTool.
- Do not build shell command strings.
- Do not allow SwiftUI views to own process execution.
- Do not overpromise video metadata behavior.
- Do not use SwiftData model instances across actor boundaries.
- Do not store media contents in SwiftData.
- Do not launch unstructured per-file tasks.
- Do not treat Swift task cancellation as sufficient unless the ExifTool process is also terminated.

## Suggested Phase Shape

1. App shell, file intake, and selected-files table.
2. MapKit coordinate selection and manual coordinate entry.
3. ExifTool metadata writer and batch write orchestration.
4. Results, safety controls, and SwiftData recent/history persistence.
5. Packaging, signing/notarization checks, and sample-file verification.
