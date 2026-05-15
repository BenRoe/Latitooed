# Phase 1: App Shell and File Intake - Research

**Researched:** 2026-05-15
**Status:** Ready for planning after UI design contract
**Scope:** Phase 1 only - native macOS SwiftUI app shell and file intake

## Research Question

What needs to be known to plan Phase 1 well?

Phase 1 establishes the macOS SwiftUI app shell and a trustworthy file intake workflow. The implementation needs to let users add JPEG, HEIC, MOV, and MP4 files through a picker and drag/drop, reject invalid inputs with clear warnings, preserve exact file URLs, and show enough per-file state for later GPS reading/writing phases without pretending that metadata writes exist yet.

## Source Inputs

- `.planning/phases/01-app-shell-and-file-intake/01-CONTEXT.md`
- `.planning/REQUIREMENTS.md`
- `.planning/ROADMAP.md`
- `.planning/STATE.md`
- Project AGENTS.md instructions
- SwiftUI Pro skill references: `api.md`, `views.md`, `data.md`
- SwiftData Pro skill reference: `core-rules.md`
- Context7 Apple SwiftUI docs for `fileImporter`, `dropDestination`, drag/drop, and table row drops

## Current Codebase State

No app source files exist yet. Phase 1 should create the initial Xcode/macOS SwiftUI structure rather than retrofit an existing app. Because there are no established local source patterns, plans should define a conservative feature-oriented structure and keep each Swift type in its own file.

Recommended initial source areas:

- App entry and main window scene.
- File intake feature views.
- File intake view model.
- File snapshot, classification, warning, and result value types.
- File access/classification service.
- Unit tests for classification, duplicate handling, and warning generation.

## SwiftUI App Shell Direction

Use a native macOS SwiftUI app with a single utility-style main window. The roadmap and context require a split layout: the left side owns file intake and review; the right side is reserved for Phase 2 coordinate selection.

Planning implications:

- Use `NavigationSplitView` or a simple split layout that keeps the Phase 2 placeholder visually quiet.
- Avoid putting business logic in SwiftUI view bodies.
- Extract meaningful view pieces into separate `View` structs and separate files, rather than computed `some View` helpers.
- Own shared UI state with an `@Observable @MainActor` view model stored in `@State`.
- Use `Button("Label", systemImage: ..., action: ...)` for actions.
- Use `foregroundStyle()` and `clipShape(.rect(cornerRadius:))`; avoid legacy SwiftUI modifiers called out by project instructions.
- Use `#Preview` for previews if previews are added.

The Phase 1 UI should not include map controls or coordinate entry. The right side placeholder should only signal that location selection comes later.

## File Picker Research

Apple SwiftUI docs expose `fileImporter(isPresented:allowedContentTypes:allowsMultipleSelection:onCompletion:)` and the newer overload with `onCancellation`. The importer returns `Result<[URL], any Error>` and supports multiple selection through `allowsMultipleSelection: true`.

Planning implications:

- The picker should be launched from a clearly labeled button in the file intake UI.
- Allowed content types should include JPEG, HEIC, QuickTime movie, and MPEG-4 movie where platform UTTypes are available.
- The completion handler should pass URLs into the view model or intake service; it should not perform classification inline in the view body.
- Security-scoped access must be considered even in Phase 1. If the selected URL requires `startAccessingSecurityScopedResource()`, the implementation should use balanced start/stop calls while reading file attributes or create a plan for bookmark persistence later.
- Phase 1 should store URL values directly in snapshots, not parse paths as strings. This protects spaces, Unicode, and external-drive paths.

Relevant current-doc finding from Context7: SwiftUI file importer success returns selected URLs, and docs explicitly note using `startAccessingSecurityScopedResource()` and `stopAccessingSecurityScopedResource()` when accessing received URLs.

## Drag and Drop Research

Apple SwiftUI docs identify `dropDestination(for:action:isTargeted:)` as the preferred path when possible, using `Transferable` types. Older `onDrop(of:delegate:)` remains available for UTType-driven `NSItemProvider` handling.

Planning implications:

- For local file URLs from Finder, the plan should evaluate whether `URL` or a small Transferable wrapper is viable for the deployment target. If not, use `onDrop(of:delegate:)` with file URL/content UTTypes and isolate `NSItemProvider` loading in a service or drop handler.
- Use the large initial drop zone when no files are selected, and a compact persistent drop strip after files exist.
- Set an `isTargeted` state or equivalent visual state for drag-over feedback.
- Dropped directories should be rejected in Phase 1, not recursively scanned.
- Bulk drop warnings must list every rejected item in the latest warning details.

Relevant current-doc finding from Context7: SwiftUI drag/drop guidance prefers `Transferable` where possible and `dropDestination` for receiving expected dropped items; table row drop destinations are also available on macOS 14+ but Phase 1 only needs whole-surface file intake.

## File Type Classification

The context locks the accepted file set to JPEG, HEIC, MOV, and MP4. It also requires platform file type information where available, with case-insensitive extension fallback.

Recommended classification design:

- Create a value type such as `SelectedMediaFile` or `SelectedFileSnapshot` with stable `id`, `url`, `displayName`, `kind`, `gpsStatus`, `latestResult`, and warning/access metadata.
- Create a `MediaFileKind` enum with cases for `jpeg`, `heic`, `mov`, and `mp4`.
- Create a `FileIntakeService` or similar type that accepts `[URL]` and returns accepted snapshots plus rejected entries.
- Use URL resource values and/or `UTType` conformance checks before falling back to lowercased extension matching.
- Reject directories, missing files, inaccessible files, read-only files, and locked files before table insertion.
- Treat GPS status as `unknown` in Phase 1. Include future enum cases for `notPresent`, `present`, and `updated` if useful, but do not claim real metadata inspection.

Testing should cover:

- Uppercase and mixed-case extensions.
- Filenames containing spaces.
- Unicode filenames.
- Duplicate URL intake.
- Directory rejection.
- Unsupported extension rejection.
- Missing file rejection.
- Read-only or locked resource warning behavior where testable without fragile filesystem assumptions.

## Warning and Result State

Phase 1 requires both a transient notice and a persistent latest-action warning summary/details area. The latest warning details should be replaced by each new picker/drop event.

Recommended model:

- `IntakeNotice` for transient notice text/status.
- `IntakeWarning` for rejected file display name, URL if available, reason, and detail.
- `FileResultStatus` for latest result placeholder states such as `notRun`, `success`, `warning`, and `failure`.
- `GPSStatus` for `unknown` initially, with future states staged but not populated by metadata reading.

The table should show display name, detected type, GPS status icon/state, and latest result. The bottom-left detail area can show selected file folder plus filename, access status, and latest warnings.

## SwiftData Considerations

Phase 1 does not need SwiftData models because persistence is assigned to Phase 4. Planning should avoid introducing SwiftData prematurely.

Carry-forward rules for later phases:

- Use SwiftData for app state/history/preferences only, not media contents.
- Use explicit `save()` when correctness matters.
- Do not move `ModelContext` or model instances across actor boundaries.
- Use `@Query` only in SwiftUI views.
- Add explicit relationship delete rules when models are introduced.

If Phase 1 creates any persistence hooks, they should be protocol seams or TODO-free extension points, not active SwiftData storage.

## Concurrency and File Access

Phase 1 file intake can be mostly main-actor because it updates UI state and performs lightweight file attribute reads. Still, keep file access outside views and avoid unstructured task creation.

Recommended approach:

- Mark the file intake view model `@MainActor @Observable`.
- Keep URL classification synchronous only if it remains cheap and deterministic.
- If async item-provider loading is needed for drag/drop, centralize it in a method that returns accepted/rejected intake results, then apply state updates on the main actor.
- Use balanced security-scoped access around attribute reads.
- Do not use `DispatchQueue.main.async()`.

## Accessibility and UI Quality Notes

Planning should require:

- Text labels for icon buttons.
- Dynamic Type-friendly text styles rather than fixed font sizes.
- A table/list that remains scannable with long filenames.
- Clear warning copy for unsupported, inaccessible, read-only, locked, missing, and directory cases.
- No visible instructional prose beyond normal app controls and empty/drop states.
- No map-like or batch-write affordances in Phase 1.

## Risks and Open Questions

- Xcode project scaffolding may be absent. The plan should explicitly include creating the macOS app target and test target if no `.xcodeproj` exists.
- Finder drag/drop of local files may require `NSItemProvider` handling if `Transferable` support for URLs is insufficient in practice. The plan should permit the executor to choose the smallest native approach after reading current APIs.
- Security-scoped access can be easy to over-retain. Phase 1 should only hold access while classifying files unless later phases require bookmarks.
- Read-only and locked detection may vary by filesystem. Tests should focus on deterministic cases and keep platform-dependent checks isolated.
- Current GPS metadata is not read in Phase 1, so the UI must use an honest unknown/not-checked state.

## Recommended Plan Shape

Because Phase 1 is marked MVP and starts a new project, plan this as a walking skeleton:

1. Create the macOS SwiftUI app and test target.
2. Add the main split window shell with empty/drop-zone state and Phase 2 placeholder.
3. Implement file intake domain types and classification service.
4. Wire picker and drag/drop into an `@MainActor @Observable` view model.
5. Render selected files, details, warnings, GPS placeholder, and result placeholder.
6. Add unit tests for classification, duplicate handling, and warning generation.

## Validation Architecture

Minimum verification for Phase 1:

- Build the macOS app target.
- Run unit tests for file classification and intake state transitions.
- Source-check that Phase 1 requirements FILE-01 through FILE-05 are referenced by plan frontmatter.
- Source-check that no SwiftData models are introduced unless explicitly justified.
- Source-check that no metadata writer, coordinate picker, MapKit UI, or batch execution is implemented in Phase 1.
- Manual smoke check: launch app, add multiple supported files through picker, drop supported and unsupported files, verify warnings and table rows.

## Research Complete

Phase 1 can be planned with a small number of vertical MVP tasks. The main planning dependency remaining is the GSD UI design contract because `workflow.ui_phase` and `workflow.ui_safety_gate` are enabled and this phase has explicit UI scope.
