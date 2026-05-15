# Stack Research: GPS Metadata Editor

## Recommendation

Use a native macOS SwiftUI application with MapKit for coordinate selection, SwiftData for lightweight persistence, and a bundled ExifTool executable behind a dedicated metadata-writing service.

## Core Stack

| Layer | Choice | Rationale | Confidence |
|-------|--------|-----------|------------|
| App platform | macOS SwiftUI | Matches the desktop file-batch workflow and repository guidance. | High |
| Language/runtime | Swift 6.2+, modern Swift concurrency | Keeps file access, process execution, and UI state under strict concurrency rules. | High |
| UI architecture | SwiftUI with `@Observable` `@MainActor` view models | Aligns with project instructions and SwiftUI Pro data-flow guidance. | High |
| Map | MapKit for SwiftUI | Apple docs expose `Map`, `MapStyle`, map controls, and selectable map features for native map UX. | High |
| Place search | MapKit local search APIs | Avoids Google API keys and keeps the app native. | High |
| Persistence | SwiftData | Store recent batches, saved coordinates, app preferences, and optional history. Do not store media file contents. | Medium |
| Metadata backend | Bundled ExifTool invoked through `Process` | Best broad-format metadata writer; supports EXIF GPS and QuickTime-style GPS targets. | High |
| Native metadata fallback | Image I/O and AVFoundation service implementation later | Good future option for App Store or sandbox hardening, but weaker for v1 broad support. | Medium |

## SwiftUI Direction

- Use `NavigationSplitView` or a dense single-window utility layout with distinct file list, map/coordinate picker, and batch result surfaces.
- Keep body code small by extracting real subviews into separate `View` structs and files.
- Put shared UI state in `@Observable @MainActor` models owned by `@State`.
- Use `@Bindable` for editable state passed into child views.
- Use `Button("Label", systemImage: ..., action: ...)` for commands rather than tap gestures.
- Use numeric `TextField` bindings with `format: .number` for manual latitude and longitude.
- Prefer `confirmationDialog` for destructive overwrite/batch actions and attach it to the triggering control.

## SwiftData Direction

SwiftData is useful, but it should not become the core media model. User-selected files are security-sensitive external resources, and batch state can be transient.

Recommended persisted models:

- `RecentCoordinate`: name, latitude, longitude, optional map item metadata.
- `BatchRun`: timestamp, target coordinate, counts for success/warning/failure.
- `BatchFileResult`: display name, original URL bookmark data if needed, file type, result status, message.
- `AppSetting`: explicit overwrite/backups preference if it should persist beyond a session.

SwiftData rules to enforce:

- Save explicitly when correctness matters; do not rely on autosave timing.
- Keep `ModelContext` and model instances on the correct actor. Pass persistent identifiers or value snapshots across actor boundaries.
- Use explicit delete rules for relationships such as `BatchRun -> BatchFileResult`.
- Use `@Query` only in SwiftUI views; use `ModelContext.fetch(...)` in services.
- Avoid CloudKit assumptions for v1.

## ExifTool Direction

Use a bundled helper located in app resources and invoke it internally. Treat ExifTool as an implementation detail owned by `MetadataWriter`.

Image write path:

- Use ExifTool GPS composite tags where possible, e.g. GPS position writes that populate latitude, longitude, and refs together.
- Preserve originals by default or expose an explicit overwrite setting.
- Capture stdout, stderr, and exit status per file.
- Implement process execution as an async API with explicit cancellation propagation to the child process.
- Avoid unstructured per-file `Task {}` calls; v1 should run one cancellable sequential batch.

Video write path:

- For MP4/MOV, target QuickTime-compatible location metadata such as `Keys:GPSCoordinates` where appropriate.
- Surface video support as best effort because container structure and consuming app behavior vary.

## What Not To Use

- Do not require Homebrew ExifTool for end users.
- Do not make a local web app; browser file APIs do not fit reliable arbitrary metadata writes.
- Do not start with a pure Image I/O/AVFoundation backend if broad format support is v1's main promise.
- Do not introduce third-party Swift UI or persistence frameworks without explicit approval.
