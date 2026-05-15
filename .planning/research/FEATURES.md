# Feature Research: GPS Metadata Editor

## Table Stakes

These are expected for the initial product to satisfy the core value.

### File Intake

- Multi-file picker for images and best-effort video files.
- Drag-and-drop support into the app window.
- Supported/unsupported file classification before running a batch.
- File table showing name, type, current GPS status, and write result.
- Clear handling for read-only, locked, missing, or inaccessible files.

### Location Selection

- MapKit map with standard, satellite/imagery, and hybrid-style presentation.
- Place search without Google API keys.
- Click or select a map result to set the coordinate.
- Manual latitude and longitude entry as fallback.
- Visible selected coordinate with precision appropriate for metadata writes.

### Batch Writing

- Apply one target coordinate to all selected files.
- Per-file success, warning, and failure results.
- Progress reporting and cancellation.
- Original preservation by default or a clear overwrite setting.
- No required Homebrew or system ExifTool install.

### Metadata Support

- JPEG and HEIC write support in v1.
- PNG/TIFF support either implemented or clearly warned depending on ExifTool behavior and consuming app expectations.
- MOV/MP4 best-effort QuickTime location metadata writes.
- Filenames with spaces and Unicode handled safely.
- External-drive files handled through appropriate file access.

### Packaging

- Bundled helper included in app resources.
- Signed/notarized app can locate and execute helper.
- User-facing errors for helper missing, helper not executable, or process failure.

## Differentiators

These are valuable but can be phased after the core path works.

- Recent coordinates and reusable named places.
- Batch history with result details.
- Before/after GPS comparison.
- Dry-run mode that previews the exact files and intended writes.
- Map pin refinement with keyboard-accessible coordinate edits.
- Optional native metadata backend for still images.
- Exportable batch report.

## Anti-Features

- Google Maps dependency or API-key setup.
- Terminal-first workflow.
- Silent overwrites with no recovery path.
- Overpromising video support as fully reliable.
- Storing or copying user media into SwiftData.
- Designing around App Store distribution before validating helper packaging.

## Complexity Notes

| Feature | Complexity | Notes |
|---------|------------|-------|
| Map search and selection | Medium | MapKit is native, but search, map state, and selected coordinate state need clean separation. |
| File access | Medium | Sandbox/security-scoped access and external drives need early testing. |
| ExifTool process wrapper | Medium | Must handle paths safely, collect output, and map errors per file. |
| Video metadata | High | QuickTime tags vary by container and consuming app. |
| Signing/notarization with helper | High | Needs explicit packaging verification phase. |
| SwiftData history | Low-Medium | Useful but should stay non-blocking for MVP. |
