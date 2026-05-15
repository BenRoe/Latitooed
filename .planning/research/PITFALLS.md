# Pitfalls Research: GPS Metadata Editor

## Critical Pitfalls

### Treating Video Metadata as Fully Reliable

**Risk:** MOV and MP4 location tags differ by container and consumer. A file may be written successfully but ignored by another app.

**Prevention:** Mark video support best effort in requirements, write QuickTime-compatible tags, and include manual verification samples.

**Phase to address:** Metadata writer and verification phases.

### Requiring External ExifTool by Accident

**Risk:** Development succeeds because the machine has Homebrew ExifTool, but packaged app fails for users.

**Prevention:** Resolve helper only from app resources in production paths. Add a test/check on a machine or environment without system ExifTool.

**Phase to address:** Packaging phase.

### Losing File Access Before Write

**Risk:** Sandbox/security-scoped resource access starts during selection but is not active during batch write.

**Prevention:** Centralize access in `FileAccessService` and keep access open around the actual write operation.

**Phase to address:** File intake and batch writing phases.

### Silent Destructive Writes

**Risk:** Bulk metadata edits are hard to undo if originals are overwritten without clear user intent.

**Prevention:** Keep backups enabled by default or require explicit overwrite confirmation. Show a confirmation dialog for destructive policy changes.

**Phase to address:** Batch writing phase.

### Shell Command Construction

**Risk:** Paths with spaces, Unicode, or special characters fail or become unsafe if commands are built as strings.

**Prevention:** Use `Process.executableURL` plus argument arrays. Never invoke through a shell string.

**Phase to address:** Metadata writer phase.

### Broken Batch Cancellation

**Risk:** The Swift task is cancelled but the currently running ExifTool process continues writing metadata.

**Prevention:** Wrap process execution so cancellation terminates the child process, and call `Task.checkCancellation()` before starting each file.

**Phase to address:** Metadata writer and batch orchestration phases.

### Unstructured Per-File Tasks

**Risk:** Starting `Task {}` for every file loses cancellation propagation and makes progress/result ordering hard to reason about.

**Prevention:** Use one structured batch operation for v1 sequential writes. If later parallel writes are needed, use a bounded task group and collect per-file `Result` values.

**Phase to address:** Batch orchestration phase.

### Overusing SwiftData

**Risk:** Persisting external media state as if it were app-owned data creates stale bookmarks, actor-boundary issues, and unnecessary migration complexity.

**Prevention:** Use SwiftData for recent coordinates, batch history, and preferences only. Keep selected files as value objects during active sessions.

**Phase to address:** Persistence/history phase.

### SwiftUI View Logic Bloat

**Risk:** Map, file intake, and batch writing logic drift into large view bodies.

**Prevention:** Extract subviews into separate files and place command logic in `@MainActor @Observable` models and services.

**Phase to address:** App shell and every UI phase.

### Packaging Helper Incorrectly

**Risk:** The helper exists during development but lacks executable permissions, is not copied into the signed bundle, or is blocked after notarization.

**Prevention:** Add packaging checks that run the bundled helper from `Bundle.main` and verify write capability after signing/notarization.

**Phase to address:** Packaging phase.

## Warning Signs

- Any call that builds `exiftool ...` as one string.
- UI views directly calling `Process`.
- `Task {}` launched once per selected file.
- Cancellation paths that update UI state but do not terminate the running helper process.
- `@Query` used inside a service or model instead of a SwiftUI view.
- Batch write code that does not return per-file structured results.
- Requirements or copy that imply video support is guaranteed.
- Tests that pass only when `/opt/homebrew/bin/exiftool` is available.
