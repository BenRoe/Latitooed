# Walking Skeleton - GPS Metadata Editor

**Phase:** 1
**Generated:** 2026-05-15

## Capability Proven End-to-End

A Mac user can launch the native SwiftUI utility, add supported local media files, and review accepted files plus clear warnings for rejected files.

## Architectural Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Framework | Native macOS SwiftUI app target | The product requires reliable local file access, Finder drag/drop, and a desktop utility workflow. |
| Data layer | In-memory Phase 1 state only | Persistence belongs to Phase 4; Phase 1 should not introduce SwiftData before history/recent-coordinate requirements exist. |
| Auth | None | The app edits user-selected local files and has no account or network identity flow. |
| Deployment target | Local macOS app build through Xcode/xcodebuild | Initial release is outside the Mac App Store; Phase 1 proves the app launches and builds locally. |
| Directory layout | Feature folders under `GPSMetadataEditor/Features/FileIntake` plus tests under `GPSMetadataEditorTests` | Keeps file intake isolated from later coordinate, metadata writer, batch, persistence, and packaging features. |

## Stack Touched in Phase 1

- [x] Project scaffold: macOS SwiftUI app target and Swift Testing test target.
- [x] Routing: single main window scene with split utility layout.
- [x] Data layer: in-memory selected-file snapshots and warning state; no persistent database in Phase 1 by roadmap scope.
- [x] UI: add-files action and drag/drop surfaces wired to file intake state.
- [x] Deployment: local build/test commands documented in plans.

## Out of Scope

- Coordinate search, map selection, map style switching, and manual latitude/longitude entry.
- Metadata reading or writing.
- Batch execution, cancellation, progress, and result history.
- SwiftData persistence.
- Recursive folder scanning.
- Packaging, signing, notarization, bundled ExifTool, and release verification.

## Subsequent Slice Plan

Each later phase adds one vertical capability on top of this skeleton without changing the Phase 1 file intake contracts:

- Phase 2: Coordinate selection through MapKit and manual latitude/longitude entry.
- Phase 3: Core metadata writing for eligible still images using bundled ExifTool.
- Phase 4: Batch progress/results, video best-effort behavior, and SwiftData history.
- Phase 5: Packaged app verification with bundled helper execution.
