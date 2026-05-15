# Project State: GPS Metadata Editor

## Project Reference

See: `.planning/PROJECT.md` (updated 2026-05-15)

**Core value:** Users can reliably apply a chosen GPS coordinate to many local media files without installing command-line dependencies.
**Current focus:** Phase 1 - App Shell and File Intake

## Workflow

- **Mode:** yolo
- **Granularity:** coarse
- **Execution:** sequential
- **Worktrees:** disabled
- **Model profile:** inherit
- **Research:** enabled
- **Plan check:** enabled
- **Verifier:** enabled

## Roadmap Status

| Phase | Status | Progress |
|-------|--------|----------|
| 1 - App Shell and File Intake | Pending | 0% |
| 2 - Coordinate Selection | Pending | 0% |
| 3 - Core Metadata Writing | Pending | 0% |
| 4 - Batch Results, Video, and History | Pending | 0% |
| 5 - Packaging and Release Verification | Pending | 0% |

## Decisions To Carry Forward

- v1 uses bundled ExifTool behind a `MetadataWriter` service boundary.
- v1 writes JPEG and HEIC first, with MOV and MP4 treated as best effort.
- Batch writes are sequential and cancellable.
- SwiftData persists recent coordinates, batch history, and preferences only.
- The initial distribution assumption is outside the Mac App Store.

## Next Action

Run `$gsd-discuss-phase 1` to gather context for Phase 1.

---
*State initialized: 2026-05-15*
