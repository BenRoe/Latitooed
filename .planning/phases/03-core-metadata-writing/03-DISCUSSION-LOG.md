# Phase 3: Core Metadata Writing - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-18T13:35:14+02:00
**Phase:** 3-Core Metadata Writing
**Areas discussed:** Original preservation, bundled ExifTool behavior, file scope, apply/result UI boundary

---

## Original Preservation

| Option | Description | Selected |
|--------|-------------|----------|
| Preserve originals by default | Let ExifTool create adjacent `_original` backups. Safest and simplest recovery path. | |
| Ask before each batch | Ask whether to preserve originals or overwrite in place before every write. More control, more UI. | |
| Overwrite without backups | Edit metadata in place without creating backups. Fastest, cleanest folder output, highest risk. | ✓ |
| Custom backup folder | Copy originals to a separate backup folder before writing. Cleaner than adjacent backups, more complexity. | |

**User's choice:** Overwrite by default, but show a popup warning with a note like "you overwrite the exif data and there is no way back to original"; actions should be OK/abort.
**Notes:** The context narrows this to a blocking confirmation before writes. No backup behavior is in scope for Phase 3.

---

## Bundled ExifTool Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Bundle ExifTool now | Add the helper into app resources in Phase 3, resolve it from `Bundle.main`, and fail clearly if missing or not executable. | ✓ |
| Service first, bundle later | Build writer boundary and argument tests now, but defer the real bundled resource to packaging. | |
| Dev fallback only | Prefer bundled ExifTool but fall back to a developer path or system tool if missing. Easier local testing but weakens self-contained behavior. | |

**User's choice:** Bundle ExifTool now.
**Notes:** Phase 3 should prove the no-Homebrew path instead of relying on a developer fallback.

---

## File Scope

| Option | Description | Selected |
|--------|-------------|----------|
| JPEG + HEIC only | Write selected JPEG/HEIC files and warn for MOV/MP4 rows that video writing comes later. | ✓ |
| Reject video at batch start | Abort the whole batch if any selected MOV/MP4 files are present. | |
| Try MOV/MP4 now | Include best-effort video writes immediately. More useful, but overlaps with Phase 4. | |

**User's choice:** JPEG + HEIC only.
**Notes:** Mixed selections remain valid; video rows should not block still-image writes.

---

## Apply Button and Result Boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal batch UI | Add one Apply Location command, confirmation dialog, per-row latest result/message updates, and compact footer summary. | ✓ |
| Result drawer now | Add a results panel or drawer with per-file messages. More transparent, overlaps with Phase 4. | |
| Service-only phase | Implement writer and tests without exposing the UI command. Does not satisfy user-level batch application. | |

**User's choice:** Minimal batch UI.
**Notes:** Phase 4 keeps progress, cancellation, detailed result review, video writes, and history.

---

## the agent's Discretion

- Exact protocol/type names for the metadata writer and result structures.
- Whether the batch coordinator is part of `FileIntakeViewModel` or a small adjacent view model.
- Exact helper resource subpath inside the app bundle.
- Exact wording of the destructive confirmation, as long as it clearly communicates overwrite/no-restore risk.

## Deferred Ideas

- Backup preservation and overwrite preferences.
- MOV/MP4 best-effort writes.
- Batch progress, cancellation, detailed result review, and persistent history.
- Future native metadata backends behind the writer service boundary.
