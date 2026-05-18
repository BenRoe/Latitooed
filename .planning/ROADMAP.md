# Roadmap: GPS Metadata Editor

**Created:** 2026-05-15
**Mode:** Vertical MVP
**Granularity:** Coarse
**Core Value:** Users can reliably apply a chosen GPS coordinate to many local media files without installing command-line dependencies.

## Overview

| Phase | Name | Goal | Requirements |
|-------|------|------|--------------|
| 1 | App Shell and File Intake | As a Mac user, I want to select and review supported local media files, so that I can prepare them for GPS metadata editing. | FILE-01, FILE-02, FILE-03, FILE-04, FILE-05 |
| 2 | Coordinate Selection | Let users choose an exact target coordinate through MapKit or manual entry. | LOC-01, LOC-02, LOC-03, LOC-04, LOC-05, LOC-06 |
| 3 | Core Metadata Writing | Complete | BATCH-01, BATCH-05, BATCH-06, META-01, META-02, META-05, META-06, META-07 |
| 4 | Batch Results, Video, and History | Make the batch workflow cancellable, transparent, and persistent enough for daily use. | BATCH-02, BATCH-03, BATCH-04, META-03, META-04, PERSIST-01, PERSIST-02, PERSIST-03, PERSIST-04 |
| 5 | Packaging and Release Verification | Prove the signed packaged app works without external command-line dependencies. | PKG-01, PKG-02, PKG-03, PKG-04 |

## Phases

### Phase 1: App Shell and File Intake

**Goal:** As a Mac user, I want to select and review supported local media files, so that I can prepare them for GPS metadata editing.
**Progress:** 5/5 plans complete. Plan 01-01 created the app shell and first-launch file-intake surface. Plan 01-02 added file-intake value types, URL classification, duplicate prevention, and warning generation. Plan 01-03 wired picker and Finder drop URLs through main-actor intake state into the selected-files and warning UI. Plan 01-04 extracted the final review surfaces for drop zones, selected-file rows, bottom-left details, warning details, and the quiet reserved location panel. Plan 01-05 converted the MVP goal to a valid user story and closed the verification format gap.
**Mode:** mvp
**UI hint:** yes
**Requirements:** FILE-01, FILE-02, FILE-03, FILE-04, FILE-05

**Success Criteria:**
1. User can launch a macOS SwiftUI app with a main utility window for file intake and review.
2. User can add multiple files through both picker and drag/drop.
3. The selected-files table shows display name, detected type, current GPS status placeholder or value, and latest result.
4. Unsupported, inaccessible, read-only, locked, or missing files are surfaced with clear warnings.
5. File URLs with spaces, Unicode, and external-drive paths remain intact through selection and classification.

**Notes:**
- Use value types for selected file snapshots.
- Keep file access handling out of SwiftUI view bodies.
- This phase may use fake write results until the metadata writer exists.

### Phase 2: Coordinate Selection

**Goal:** Let users choose an exact target coordinate through MapKit or manual entry.
**Progress:** 3/3 plans complete. Host-side `xcodebuild` and full MapKit UI verification were waived by the user on 2026-05-18; continue with Phase 3 while carrying that residual risk.
**Mode:** mvp
**UI hint:** yes
**Requirements:** LOC-01, LOC-02, LOC-03, LOC-04, LOC-05, LOC-06

**Success Criteria:**
1. User can search for places using MapKit without third-party API keys.
2. User can select a search result and see the selected coordinate update.
3. User can click the map to set the coordinate.
4. User can switch map presentation between standard, satellite/imagery, and hybrid-style modes.
5. User can enter latitude and longitude manually using numeric fields.
6. The selected coordinate is visible and ready for later batch application.

**Notes:**
- Use SwiftUI MapKit APIs and keep map/search state in an `@MainActor @Observable` model.
- Manual coordinate entry should use formatted numeric bindings, not string parsing in view bodies.

### Phase 3: Core Metadata Writing

**Goal:** Write GPS metadata to eligible still images using bundled ExifTool through a safe service boundary.
**Progress:** 3/3 plans complete and approved. VM static checks passed, host-side verification was accepted by the user, and follow-up bug findings were documented under `docs/`.
**Mode:** mvp
**UI hint:** yes
**Requirements:** BATCH-01, BATCH-05, BATCH-06, META-01, META-02, META-05, META-06, META-07

**Success Criteria:**
1. User can apply the selected coordinate to eligible JPEG and HEIC files in a sequential batch.
2. The app uses a bundled ExifTool helper rather than a Homebrew or system install.
3. Metadata writes invoke ExifTool through executable URL plus argument array, never shell command strings.
4. The write path returns structured per-file success, warning, or failure details.
5. Original preservation is the default or overwrite requires an explicit user choice.
6. Batch write ordering and file access behavior are deterministic.

**Notes:**
- Define a `MetadataWriter` protocol and an `ExifToolMetadataWriter` implementation.
- Argument construction should be unit-testable without running ExifTool.
- Keep security-scoped access active during the actual write.

### Phase 4: Batch Results, Video, and History

**Goal:** Make the batch workflow cancellable, transparent, and persistent enough for daily use.
**Mode:** mvp
**UI hint:** yes
**Requirements:** BATCH-02, BATCH-03, BATCH-04, META-03, META-04, PERSIST-01, PERSIST-02, PERSIST-03, PERSIST-04

**Success Criteria:**
1. User can cancel an active batch, and cancellation terminates any active helper process.
2. User can see batch progress while writes are running.
3. User can review per-file success, warning, and failure results after a batch.
4. MOV and MP4 files receive best-effort QuickTime-compatible location metadata or clear warnings/failures.
5. User can reuse recent coordinates saved by the app.
6. User can view recent batch runs with timestamp, coordinate, and success/warning/failure counts.
7. SwiftData stores only app state/history/preferences, not media contents, and correctness-sensitive saves are explicit.

**Notes:**
- Prefer one structured cancellable batch task over per-file unstructured tasks.
- SwiftData model instances and `ModelContext` must not cross actor boundaries.
- Video copy should be precise: best effort, not guaranteed.

### Phase 5: Packaging and Release Verification

**Goal:** Prove the signed packaged app works without external command-line dependencies.
**Mode:** mvp
**UI hint:** no
**Requirements:** PKG-01, PKG-02, PKG-03, PKG-04

**Success Criteria:**
1. The built app bundle includes the ExifTool helper in bundle resources.
2. The signed app can resolve and execute the bundled helper from `Bundle.main`.
3. The app reports clear errors when the helper is missing, non-executable, or fails to launch.
4. A release verification flow writes GPS metadata to sample JPEG and HEIC files on a machine without Homebrew or system ExifTool.
5. Packaging notes document remaining notarization or distribution constraints.

**Notes:**
- This phase should test the packaged app, not only debug builds.
- Avoid accidentally falling back to `/opt/homebrew/bin/exiftool`.

## Coverage

| Requirement Count | Covered | Unmapped |
|-------------------|---------|----------|
| 32 | 32 | 0 |

---
*Roadmap created: 2026-05-15*
