# Requirements: GPS Metadata Editor

**Defined:** 2026-05-15
**Core Value:** Users can reliably apply a chosen GPS coordinate to many local media files without installing command-line dependencies.

## v1 Requirements

### File Intake

- [x] **FILE-01**: User can select multiple local media files through a file picker.
- [x] **FILE-02**: User can drag and drop supported media files into the app window.
- [x] **FILE-03**: User can see each selected file's display name, detected file type, current GPS status, and latest write result.
- [x] **FILE-04**: User receives a clear warning when a selected file is unsupported, inaccessible, read-only, locked, or missing.
- [x] **FILE-05**: User-selected files with spaces, Unicode characters, and external-drive paths are handled without path parsing failures.

### Location Selection

- [x] **LOC-01**: User can search for a place using Apple MapKit without providing Google or third-party API keys.
- [x] **LOC-02**: User can select a search result to set the target coordinate.
- [x] **LOC-03**: User can click the map to set the target coordinate.
- [x] **LOC-04**: User can switch between standard, satellite/imagery, and hybrid-style map presentations.
- [x] **LOC-05**: User can manually enter latitude and longitude as a fallback to map/search selection.
- [x] **LOC-06**: User can see the currently selected latitude and longitude before applying a batch write.

### Batch Writing

- [x] **BATCH-01**: User can apply one selected coordinate to all eligible selected files in a single batch.
- [ ] **BATCH-02**: User can cancel an active batch write, and cancellation stops before starting the next file and terminates any active metadata helper process.
- [ ] **BATCH-03**: User can see batch progress while writes are running.
- [ ] **BATCH-04**: User can see per-file success, warning, and failure results after a batch.
- [x] **BATCH-05**: User can keep original-file backups by default or must explicitly choose overwrite behavior before destructive writes.
- [x] **BATCH-06**: Batch writes run sequentially in v1 for predictable progress, file access handling, and cancellation behavior.

### Metadata Support

- [x] **META-01**: The app writes GPS latitude and longitude metadata to JPEG files.
- [x] **META-02**: The app writes GPS latitude and longitude metadata to HEIC files.
- [ ] **META-03**: The app attempts best-effort QuickTime-compatible location metadata writes for MOV files and clearly reports warnings or failures.
- [ ] **META-04**: The app attempts best-effort QuickTime-compatible location metadata writes for MP4 files and clearly reports warnings or failures.
- [x] **META-05**: The app uses a bundled ExifTool helper rather than requiring a Homebrew or system ExifTool installation.
- [x] **META-06**: The metadata writer invokes ExifTool through an executable URL and argument array, not through shell command strings.
- [x] **META-07**: The metadata writer returns structured per-file results including status, user-facing message, and diagnostic detail when available.

### Persistence

- [ ] **PERSIST-01**: User can reuse recent coordinates saved by the app.
- [ ] **PERSIST-02**: User can view a simple history of recent batch runs with timestamp, coordinate, and success/warning/failure counts.
- [ ] **PERSIST-03**: SwiftData persistence stores recent coordinates, batch summaries, preferences, and result metadata only; it does not store media file contents.
- [ ] **PERSIST-04**: SwiftData writes that affect correctness are explicitly saved rather than relying on autosave timing.

### Packaging

- [ ] **PKG-01**: The packaged app includes the ExifTool helper in its bundle resources.
- [ ] **PKG-02**: The signed app can locate and execute the bundled helper from the app bundle.
- [ ] **PKG-03**: The app reports a clear user-facing error if the bundled helper is missing, not executable, or fails to launch.
- [ ] **PKG-04**: The app can complete the core JPEG/HEIC metadata write flow on a machine without Homebrew or system ExifTool installed.

## v2 Requirements

### Metadata

- **META-08**: App provides a native Image I/O metadata writer for supported still-image formats.
- **META-09**: App provides richer format-specific warnings for PNG, TIFF, and other image types.
- **META-10**: App can verify written metadata by reading files after write and showing before/after values.

### Reporting

- **REPORT-01**: User can export a batch report.
- **REPORT-02**: User can copy diagnostic details for failed files.

### Workflow

- **FLOW-01**: User can run a dry-run preview before writing metadata.
- **FLOW-02**: User can name and pin favorite coordinates.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Google Maps or Google Places integration | Apple MapKit avoids API-key setup and matches the native macOS direction. |
| Required Homebrew or system ExifTool dependency | The core value requires a self-contained app. |
| Full guaranteed video metadata support | MOV and MP4 metadata behavior varies by container and consuming app, so v1 is best effort. |
| Mac App Store distribution | Bundled helper execution and sandbox review add risk; outside-App-Store distribution is the initial target. |
| Browser/local web implementation | Browser file APIs do not fit reliable arbitrary local metadata writes. |
| Storing copied media files in SwiftData | SwiftData should persist app state and history, not user media contents. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| FILE-01 | Phase 1 | Complete in 01-01 |
| FILE-02 | Phase 1 | Complete in 01-03 |
| FILE-03 | Phase 1 | Complete in 01-02 |
| FILE-04 | Phase 1 | Complete in 01-02 |
| FILE-05 | Phase 1 | Complete in 01-02 |
| LOC-01 | Phase 2 | Complete |
| LOC-02 | Phase 2 | Complete |
| LOC-03 | Phase 2 | Complete |
| LOC-04 | Phase 2 | Complete |
| LOC-05 | Phase 2 | Complete |
| LOC-06 | Phase 2 | Complete |
| BATCH-01 | Phase 3 | Complete |
| BATCH-02 | Phase 4 | Pending |
| BATCH-03 | Phase 4 | Pending |
| BATCH-04 | Phase 4 | Pending |
| BATCH-05 | Phase 3 | Complete |
| BATCH-06 | Phase 3 | Complete |
| META-01 | Phase 3 | Complete |
| META-02 | Phase 3 | Complete |
| META-03 | Phase 4 | Pending |
| META-04 | Phase 4 | Pending |
| META-05 | Phase 3 | Complete |
| META-06 | Phase 3 | Complete |
| META-07 | Phase 3 | Complete |
| PERSIST-01 | Phase 4 | Pending |
| PERSIST-02 | Phase 4 | Pending |
| PERSIST-03 | Phase 4 | Pending |
| PERSIST-04 | Phase 4 | Pending |
| PKG-01 | Phase 5 | Pending |
| PKG-02 | Phase 5 | Pending |
| PKG-03 | Phase 5 | Pending |
| PKG-04 | Phase 5 | Pending |

**Coverage:**
- v1 requirements: 32 total
- Mapped to phases: 32
- Unmapped: 0

---
*Requirements defined: 2026-05-15*
*Last updated: 2026-05-15 after roadmap creation*
