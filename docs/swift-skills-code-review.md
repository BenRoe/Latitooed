# Swift Skills Code Review — GPSMetadataEditor

Review date: 2026-05-22. Reviewed against four agent skills:
swift-concurrency-pro, swift-testing-pro, swiftdata-pro, swiftui-pro.

Scope: all `GPSMetadataEditor/` sources and `GPSMetadataEditorTests/`.

---

## ProcessRunner.swift

### Lines 24-47: Pipe deadlock — process hangs forever on large output [HIGH]

`readDataToEndOfFile()` runs inside `terminationHandler`. `terminationHandler`
fires only after the process exits. The process cannot exit if it has filled
the stdout/stderr pipe buffer (~64 KB) and nobody drains it — the child blocks
on `write()`, never terminates, the handler never fires, the continuation never
resumes. exiftool batch errors / verbose output easily pass 64 KB. Pipes must
drain *while* the process runs, not after.

```swift
// Before
return try await withTaskCancellationHandler {
    try await withCheckedThrowingContinuation { continuation in
        process.terminationHandler = { terminatedProcess in
            let outputData = standardOutput.fileHandleForReading.readDataToEndOfFile()
            let errorData = standardError.fileHandleForReading.readDataToEndOfFile()
            continuation.resume(returning: ProcessResult(/* ... */))
        }
        do { try process.run() } catch { continuation.resume(throwing: error) }
    }
} onCancel: {
    process.terminate()
}

// After — drain pipes concurrently via readabilityHandler
return try await withTaskCancellationHandler {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<ProcessResult, any Error>) in
        let outputBuffer = Mutex(Data())
        let errorBuffer = Mutex(Data())

        standardOutput.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if chunk.isEmpty { handle.readabilityHandler = nil }
            else { outputBuffer.withLock { $0.append(chunk) } }
        }
        standardError.fileHandleForReading.readabilityHandler = { handle in
            let chunk = handle.availableData
            if chunk.isEmpty { handle.readabilityHandler = nil }
            else { errorBuffer.withLock { $0.append(chunk) } }
        }

        process.terminationHandler = { terminatedProcess in
            continuation.resume(returning: ProcessResult(
                terminationStatus: terminatedProcess.terminationStatus,
                standardOutput: String(decoding: outputBuffer.withLock { $0 }, as: UTF8.self),
                standardError: String(decoding: errorBuffer.withLock { $0 }, as: UTF8.self)
            ))
        }

        do { try process.run() } catch { continuation.resume(throwing: error) }
    }
} onCancel: {
    process.terminate()
}
```

### Lines 24-46: Strict-concurrency note

`Process` and `Pipe` are not `Sendable`, but are captured in `@Sendable`
closures (`terminationHandler`, `onCancel`). If this file compiles today, the
target is not on full strict concurrency checking — verify build settings. The
deadlock above is exactly the class of bug strict checking will not catch.

### Lines 44-46: Cancellation before `process.run()` is lost [LOW]

`onCancel` calls `terminate()` on an un-started process — a no-op — then
`run()` proceeds and the process runs uncancelled. Edge case.

---

## FileIntakeViewModel.swift

### Lines 149-158: No cancellation check in batch loop [LOW]

`applyMetadata` loops awaiting `writer.writeGPS` per file. If the enclosing
`Task` is cancelled (window closed) the loop keeps writing every file. Add
`if Task.isCancelled { break }` before each write.

### Lines 51-53: `message` never pluralizes "warning"

`"\(warningCount) warning"` is always singular. `BatchRunSummary.countsText`
says "warnings" — inconsistent.

---

## SelectedFilesTable.swift

### Lines 154-172: Status cells ignore status — icon/color hardcoded [MEDIUM]

`GPSStatusCell` always uses `"location.slash"`, `LatestResultCell` always
`"clock"`, both `.secondary`. Success / warning / failure are invisible to the
user. Map icon and `foregroundStyle` to the status enum.

```swift
// Before
private struct LatestResultCell: View {
    let status: FileResultStatus
    var body: some View {
        Label(status.displayName, systemImage: "clock")
            .labelStyle(.titleAndIcon)
            .foregroundStyle(.secondary)
    }
}

// After — icon + color reflect state
private struct LatestResultCell: View {
    let status: FileResultStatus
    var body: some View {
        Label(status.displayName, systemImage: status.symbolName)
            .labelStyle(.titleAndIcon)
            .foregroundStyle(status.tint)
    }
}
```

### Lines 43-128: `TableSelectionNormalizer` — global event monitor + `Task.yield()` timing hack [MEDIUM]

`NSEvent.addLocalMonitorForEvents` is app-wide and intercepts every left-click.
`Task { @MainActor in await Task.yield(); selection.wrappedValue = ... }` uses
`yield()` as a scheduling guess to land after SwiftUI's own selection write —
fragile. AppKit interop is a real need for `Table` single-click behaviour, but:
scope the monitor tighter, replace the `yield()` race with explicit ordering if
possible, and document why the workaround exists.

---

## ReservedLocationPanel.swift

### Whole file: dead code [LOW]

Defined, never referenced — `CoordinateSelectionView` replaced it. Body still
says "Phase 1". Delete.

---

## ExifToolArgumentBuilder.swift

### Line 4: `throws` declared, never thrown [LOW]

Remove `throws`, or it is unused future-proofing.

### Lines 7-17: filename passed last with no `--` separator [LOW]

A file named `-overwrite_original.jpg` is parsed by exiftool as an option.
Pass `--` before the path, or place the path first.

---

## CoordinateSelectionViewModelTests.swift

### Line 247: timing-based test — flaky [MEDIUM]

`staleSearchResponseDoesNotOverwriteNewerState` does
`Task.sleep(.milliseconds(50))` against a 20 ms fake delay. CI load → race →
flake. Use a continuation-controlled fake (like `SuspendedMetadataWriter` in
MetadataBatchViewModelTests) so ordering is deterministic, not clock-based.

### Lines 126, 209, 219, 229: `await Task.yield()` after `search()` [LOW]

Works only because the fake never truly suspends — one yield drains the
unstructured task. Brittle coupling to the scheduler. Same continuation-fake
pattern fixes it.

---

## ProcessRunnerTests.swift

### Whole file: deadlock untested, only 1 test [LOW-MEDIUM]

`#expect(throws: (any Error).self)` is very broad. No test covers the
large-output path — the HIGH bug above ships untested. Add a test running a
script that emits >64 KB to stdout; current code hangs, fixed code passes.

---

## BatchHistoryStore.swift

### Lines 123-127, 129-138: double full-table fetch per insert [LOW]

`existingRecentCoordinate` fetches all rows, `pruneRecentCoordinates` fetches
all again. With ≤10 rows this is negligible. If limits grow, use
`FetchDescriptor` + `#Predicate` + `fetchLimit`.

---

## Summary — fix order

1. **HIGH — ProcessRunner pipe deadlock.** Real hang in production on large
   exiftool output. Drain pipes concurrently. Add a >64 KB regression test.
2. **MEDIUM — SelectedFilesTable status cells.** Success/warning/failure
   invisible. Map icon + color to status.
3. **MEDIUM — flaky timing test** (`staleSearchResponse...`, line 247). Swap to
   a continuation-controlled fake.
4. **MEDIUM — TableSelectionNormalizer hack.** Global monitor + `Task.yield()`
   race. Scope tighter, document.
5. **LOW — cleanup:** delete `ReservedLocationPanel`, drop unused `throws`, fix
   "warning" plural, add batch-loop cancellation check, `--` before the exiftool
   path.

### Strong points

Consistent `nonisolated`-struct style (MainActor-default build mode); Sendable
value snapshots to cross the actor boundary out of SwiftData; `@MainActor` test
suites; parameterized tests; actor + continuation fakes. The concurrency model
is sound everywhere except ProcessRunner.
