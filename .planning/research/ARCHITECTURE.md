# Architecture Research: GPS Metadata Editor

## Proposed Components

### App Shell

- `GPSMetadataEditorApp`
- Configures SwiftData `ModelContainer` if history/recent coordinates are included.
- Provides app-wide services through environment or root view construction.

### Main Window UI

- `MainEditorView`: top-level layout.
- `FileSelectionView`: file picker, drag-and-drop target, selected file list.
- `MapSelectionView`: MapKit map, map style control, search field, selected coordinate.
- `CoordinateEntryView`: manual latitude/longitude editing.
- `BatchControlsView`: apply/cancel/overwrite or backup controls.
- `BatchResultsView`: per-file results and summary counts.

### State and View Models

- `@MainActor @Observable BatchEditorModel`
  - Owns selected files, target coordinate, map style, batch progress, and current results.
  - Exposes command methods called from buttons.
- `@MainActor @Observable LocationSearchModel`
  - Owns search query, search results, selected map item, and selected coordinate.
- `@MainActor @Observable PreferencesModel`
  - Owns overwrite/backup preference if not persisted directly through SwiftData queries.

### Domain Types

- `MediaFileSelection`: value snapshot of user-selected URL, display name, file type, access state.
- `TargetCoordinate`: latitude, longitude, optional altitude/name/source.
- `MetadataWriteRequest`: file URL, coordinate, write policy, file classification.
- `MetadataWriteResult`: success/warning/failure, message, raw helper details when useful.
- `MediaFileType`: jpeg, heic, png, tiff, mov, mp4, unsupported.

### Services

- `FileAccessService`
  - Opens file picker or receives dropped URLs.
  - Manages security-scoped resource access where required.
  - Classifies files by URL/content type.
- `LocationSearchService`
  - Wraps MapKit search APIs and returns value snapshots usable by the UI.
- `MetadataWriter`
  - Protocol boundary for metadata writes.
- `ExifToolMetadataWriter`
  - Builds ExifTool arguments, invokes bundled helper with `Process`, parses output.
  - Bridges process lifecycle into async Swift with checked continuations or equivalent structured wrappers.
  - Terminates the child process when the parent task is cancelled.
- `NativeMetadataWriter` (future)
  - Optional Image I/O/AVFoundation backend if a later phase needs it.
- `BatchWriteService`
  - Runs writes sequentially for v1 reliability and progress clarity.
  - Supports cancellation and per-file result reporting.

### SwiftData Models

Optional but recommended for UX polish:

- `RecentCoordinate`
- `BatchRun`
- `BatchFileResult`
- `StoredPreference`

Keep SwiftData persistence behind repositories or small stores. Do not let SwiftData model instances cross actors or leak into process-writing services.

## Data Flow

1. User selects or drops files.
2. `FileAccessService` returns file selection value objects.
3. User searches, clicks map, or enters coordinates manually.
4. `BatchEditorModel` creates `MetadataWriteRequest` values.
5. `BatchWriteService` iterates requests sequentially and calls `MetadataWriter`.
6. `ExifToolMetadataWriter` invokes bundled ExifTool and returns structured results.
7. UI updates progress and per-file results on the main actor.
8. Optional SwiftData persistence records recent coordinate and batch summary after explicit save.

## Concurrency Model

- Keep UI-facing models `@MainActor @Observable`.
- Keep selected files, coordinates, write requests, and write results as `Sendable` value types where possible.
- Do not pass SwiftData model instances or `ModelContext` into background services; persist value snapshots after the batch result returns to the main actor.
- Prefer one structured batch task owned by the view model over unstructured `Task {}` calls per file.
- Because project config requests sequential execution and worktrees are disabled, run v1 metadata writes sequentially unless a later phase explicitly introduces bounded parallelism.
- Check cancellation before each file write and bridge cancellation into the underlying `Process` so cancelling the Swift task also terminates the helper process.
- Treat actor state as potentially changed after every `await`; compute local write requests before leaving the main actor where practical.

## Build Order Implications

1. Create app shell and state model with fake in-memory services.
2. Implement file intake and file table.
3. Implement MapKit coordinate selection and manual entry.
4. Implement ExifTool writer behind protocol with testable argument construction.
5. Implement batch write orchestration, cancellation, and result display.
6. Add SwiftData history/recent coordinates only after the core write path is stable.
7. Add packaging/signing verification for bundled helper.

## Architectural Risks

- Process execution should not be embedded in SwiftUI views.
- Map search should not directly mutate batch-writing state.
- SwiftData should not be used as a live representation of external files being edited.
- ExifTool command generation must avoid shell interpolation; invoke `Process` with executable URL and argument array.
- Security-scoped file access must be held for the actual write operation, not only file selection.
- `Process` wrappers must not ignore cancellation; otherwise cancelling a batch can leave ExifTool running.
