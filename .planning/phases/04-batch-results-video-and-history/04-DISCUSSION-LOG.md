# Phase 4: Batch Results, Video, and History - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md - this log preserves the alternatives considered.

**Date:** 2026-05-18T22:26:45+02:00
**Phase:** 4-Batch Results, Video, and History
**Areas discussed:** Batch Cancellation And Progress, Result Review Depth, Video Best-Effort Behavior, Recent Coordinates And Batch History

---

## Gray Area Selection

| Option | Description | Selected |
|--------|-------------|----------|
| Batch Cancellation And Progress | How visible should progress be, where should Cancel live, and what should happen to current vs remaining files? | yes |
| Result Review Depth | Should results stay row/footer/detail-panel level, or should Phase 4 add a clearer history/results surface with diagnostic detail? | yes |
| Video Best-Effort Behavior | How should MOV/MP4 attempts be presented, and what counts as success, warning, or failure when video metadata support varies? | yes |
| Recent Coordinates And Batch History | Where should saved coordinates and recent batch runs appear, and how much detail should SwiftData persist? | yes |

**User's choice:** all
**Notes:** All four proposed gray areas were discussed.

---

## Batch Cancellation And Progress

| Option | Description | Selected |
|--------|-------------|----------|
| Footer-only progress | Show compact progress in the existing footer with a Cancel button beside Apply. | |
| Footer plus row states | Use the footer for overall progress and update each row as pending, writing, success, warning, failure, or cancelled. | yes |
| Dedicated progress panel | Add a more prominent batch panel with progress, current file, counts, and Cancel. | |

**User's choice:** Footer plus row states.
**Notes:** This was later narrowed after cancellation was dropped.

| Option | Description | Selected |
|--------|-------------|----------|
| Mark remaining files as cancelled | Already-written files keep their real result, active file reports cancellation/failure, and not-yet-started files show Cancelled. | yes |
| Leave remaining files pending | Only attempted files update; unstarted files stay pending. | |
| Mark remaining files as skipped | Use a neutral skipped/warning-style result for not-yet-started files. | |

**User's choice:** Mark remaining files as cancelled.
**Notes:** Superseded by the later decision to drop active cancellation entirely.

| Option | Description | Selected |
|--------|-------------|----------|
| Defer cancellation out of Phase 4 | Remove active cancellation from this phase and treat it as future work. | yes |
| Keep cancellation, but not as a footer button | Use another UI route, such as toolbar/menu or window-close behavior. | |
| Keep the Cancel button after all | Proceed with the requirement as written. | |

**User's choice:** Defer cancellation out of Phase 4, with clarification: do not add it to future.
**Notes:** The final locked decision is stronger than the option label: active cancellation is intentionally dropped and should not be deferred as a future feature.

| Option | Description | Selected |
|--------|-------------|----------|
| Simple row states | Pending, Writing, Updated, Warning, Failed. No cancelled state. | |
| Simple row states plus current-file emphasis | Same states plus visible current row emphasis. | |
| Footer-only current file | Rows only update after each file completes; footer shows the current file. | yes |

**User's choice:** Footer-only current file.
**Notes:** Rows update only after each file completes; no cancelled state.

| Option | Description | Selected |
|--------|-------------|----------|
| Count-first | `Writing 3 of 12: IMG_2042.HEIC` | |
| Filename-first | `Writing IMG_2042.HEIC (3 of 12)` | yes |
| Summary-only | `Writing files... 3 of 12` | |

**User's choice:** Filename-first.
**Notes:** Footer progress copy should prioritize the current filename.

---

## Result Review Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Existing table plus detail panel | Keep the table as the main result surface; selecting a row shows message and diagnostics in the existing bottom-left detail panel. | yes |
| Add a batch results drawer | Add a collapsible results drawer with counts, per-file rows, and diagnostics. | |
| Add a separate history/results view | Create a persistent view for completed runs now. | |

**User's choice:** Existing table plus detail panel.
**Notes:** Avoid adding a second results table.

| Option | Description | Selected |
|--------|-------------|----------|
| User-facing message only | No stdout/stderr or exit status in the UI. | |
| Collapsed technical detail | Show message by default, with disclosure for exit status/stdout/stderr when available. | yes |
| Always show technical detail | Display diagnostic detail directly for every warning/failure. | |

**User's choice:** Collapsed technical detail.
**Notes:** Applies to warning and failure rows when diagnostic details exist.

| Option | Description | Selected |
|--------|-------------|----------|
| Counts only | `9 updated, 2 warnings, 1 failed.` | yes |
| Counts plus action cue | `9 updated, 2 warnings, 1 failed. Select a file for details.` | |
| Counts plus strongest issue | Include the first failure in the summary. | |

**User's choice:** Counts only.
**Notes:** Completed batch summary should stay compact.

| Option | Description | Selected |
|--------|-------------|----------|
| Warnings and failures only | Success rows show a normal success message with no diagnostics. | yes |
| All rows if diagnostics exist | Successful writes can expose stdout/stderr if ExifTool returned notes. | |
| Failures only | Warnings get message-only; failures get collapsed diagnostics. | |

**User's choice:** Warnings and failures only.
**Notes:** Success rows stay quiet.

---

## Video Best-Effort Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| QuickTime GPSCoordinates only | Write the common QuickTime-compatible GPS coordinate tag and report best-effort results. | |
| QuickTime plus matching still-image GPS tags | Try QuickTime GPSCoordinates and image-style GPS tags for broader tool compatibility. | |
| Research-led exact tags | Require Phase 4 research to pick the minimal ExifTool tag set for MOV/MP4. | yes |

**User's choice:** Research-led exact tags.
**Notes:** Context should not hard-code MOV/MP4 tags.

| Option | Description | Selected |
|--------|-------------|----------|
| Same as images | Use `GPS metadata updated.` | yes |
| Best-effort success | Use `Location metadata written; video app compatibility may vary.` | |
| Verified-by-ExifTool only | Use `Location metadata written by ExifTool.` | |

**User's choice:** Same as images.
**Notes:** This is a stronger user-facing promise than the existing v1 caveat.

| Option | Description | Selected |
|--------|-------------|----------|
| Only warn on actual helper warnings/failures | Clean ExifTool exit means success; no extra caveat on video rows. | yes |
| Success plus batch-level note when videos were included | Rows show success, but footer/detail/history records a quiet compatibility note. | |
| Always warning for video | Mark MOV/MP4 as warning even if ExifTool exits cleanly. | |

**User's choice:** Only warn on actual helper warnings/failures.
**Notes:** No compatibility caveat is added to successful video rows.

| Option | Description | Selected |
|--------|-------------|----------|
| Same behavior and copy | Treat both MOV and MP4 as video best-effort files with the same messages. | |
| Separate behavior if research finds differences | Default to same UI copy, but allow split arguments/result handling if ExifTool support differs. | yes |
| Distinguish visibly in UI | Show MOV-specific and MP4-specific wording. | |

**User's choice:** Separate behavior if research finds differences.
**Notes:** User-facing behavior remains unified unless implementation differences are justified.

---

## Recent Coordinates And Batch History

| Option | Description | Selected |
|--------|-------------|----------|
| In the coordinate panel | Add a compact recent-coordinates list/dropdown near search/manual controls. | yes |
| In a menu only | Keep the main UI unchanged and expose recent coordinates through a menu command. | |
| In batch history only | Reuse coordinates only by selecting a prior batch run. | |

**User's choice:** In the coordinate panel.
**Notes:** Reuse belongs where the user chooses a location.

| Option | Description | Selected |
|--------|-------------|----------|
| Place name when available, coordinates otherwise | Use selected MapKit result title for search results; manual/map-click entries fall back to formatted coordinates. | yes |
| Always coordinates | Use latitude/longitude for all saved items. | |
| User naming not in Phase 4 | Store generated labels only; custom names/pinned favorites remain out of scope. | |

**User's choice:** Place name when available, coordinates otherwise.
**Notes:** Custom naming remains out of scope.

| Option | Description | Selected |
|--------|-------------|----------|
| Bottom-left detail/history area | Reuse the lower-left area for compact recent runs when no file detail is selected. | |
| Separate history panel in the left column | Add a dedicated compact history section below selected files/result detail. | yes |
| Menu/window only | Access history from a menu or secondary window. | |

**User's choice:** Separate history panel in the left column.
**Notes:** History should be visible in the main workflow.

| Option | Description | Selected |
|--------|-------------|----------|
| Timestamp, coordinate label, counts | Show timestamp, coordinate label, and success/warning/failure counts. | |
| Timestamp, coordinate label, counts, file count | Adds total file count for batch size scanning. | yes |
| Timestamp, coordinate label, counts, expandable per-file results | Stores and displays each file's result metadata for prior runs. | |

**User's choice:** Timestamp, coordinate label, counts, file count.
**Notes:** Avoid full per-file history.

| Option | Description | Selected |
|--------|-------------|----------|
| Read-only summary only | Selection highlights the entry and shows stored summary/counts. | |
| Reuse coordinate | Selecting an entry supports reuse of that run's coordinate. | yes |
| Restore full result context | Repopulate prior per-file results into the table/detail surface. | |

**User's choice:** Reuse coordinate.
**Notes:** Do not restore prior files or results.

| Option | Description | Selected |
|--------|-------------|----------|
| Coordinate and batch summaries only | Store recent coordinate records plus batch timestamp, coordinate label/value, total file count, and result counts. | yes |
| Summaries plus per-file result metadata | Also store display name, media kind, result status, and message. | |
| Summaries plus file bookmarks | Store enough bookmark data to reconnect prior files later. | |

**User's choice:** Coordinate and batch summaries only.
**Notes:** No per-file history or bookmark data.

---

## the agent's Discretion

- Exact SwiftData model names and retention counts.
- Exact detail-panel diagnostic disclosure UI.
- Exact MOV/MP4 ExifTool tag set after research.

## Deferred Ideas

- None. Active cancellation was explicitly dropped and should not be deferred as future work.
