---
phase: 01-app-shell-and-file-intake
reviewed: 2026-05-16T08:33:45Z
depth: standard
files_reviewed: 29
files_reviewed_list:
  - GPSMetadataEditor/GPSMetadataEditorApp.swift
  - GPSMetadataEditor/Support/AppDesign.swift
  - GPSMetadataEditor/Features/FileIntake/FileIntakeView.swift
  - GPSMetadataEditor/Features/FileIntake/FileIntakeViewModel.swift
  - GPSMetadataEditor/Features/FileIntake/Models/SelectedMediaFile.swift
  - GPSMetadataEditor/Features/FileIntake/Models/MediaFileKind.swift
  - GPSMetadataEditor/Features/FileIntake/Models/GPSStatus.swift
  - GPSMetadataEditor/Features/FileIntake/Models/FileResultStatus.swift
  - GPSMetadataEditor/Features/FileIntake/Models/IntakeWarning.swift
  - GPSMetadataEditor/Features/FileIntake/Models/FileIntakeResult.swift
  - GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift
  - GPSMetadataEditor/Features/FileIntake/Views/FileDropZone.swift
  - GPSMetadataEditor/Features/FileIntake/Views/SelectedFilesTable.swift
  - GPSMetadataEditor/Features/FileIntake/Views/FileDetailPanel.swift
  - GPSMetadataEditor/Features/FileIntake/Views/WarningSummaryView.swift
  - GPSMetadataEditor/Features/FileIntake/Views/ReservedLocationPanel.swift
  - GPSMetadataEditorTests/FileIntakeSmokeTests.swift
  - GPSMetadataEditorTests/FileIntakeServiceTests.swift
  - GPSMetadataEditorTests/FileIntakeViewModelTests.swift
  - AGENTS.md
  - .planning/PROJECT.md
  - .planning/REQUIREMENTS.md
  - .planning/phases/01-app-shell-and-file-intake/01-01-SUMMARY.md
  - .planning/phases/01-app-shell-and-file-intake/01-02-SUMMARY.md
  - .planning/phases/01-app-shell-and-file-intake/01-03-SUMMARY.md
  - .planning/phases/01-app-shell-and-file-intake/01-04-SUMMARY.md
  - .agents/skills/swiftui-pro/SKILL.md
  - .agents/skills/swift-concurrency-pro/SKILL.md
  - .agents/skills/swift-testing-pro/SKILL.md
findings:
  critical: 0
  warning: 1
  info: 0
  total: 1
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-05-16T08:33:45Z
**Depth:** standard
**Files Reviewed:** 29
**Status:** issues_found

## Summary

Reviewed the Phase 01 SwiftUI app shell, file-intake models, URL classification service, extracted intake views, and Swift Testing coverage. The SwiftUI state flow follows the requested `@Observable @MainActor` pattern, the source avoids the banned legacy SwiftUI/concurrency APIs scanned for this phase, and target membership for the new source/test files is present in the Xcode project.

One correctness issue remains in duplicate detection: the service treats raw `URL` equality as file identity, so the same local file can be accepted twice when it arrives through different URL spellings or symlinked paths. That also leaves a missing test gap around duplicate rejection across canonical file identity.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Duplicate Detection Uses Raw URL Equality Instead of File Identity

**File:** `GPSMetadataEditor/Features/FileIntake/Services/FileIntakeService.swift:8`

**Issue:** `seenURLs` is built from `SelectedMediaFile.url` and checked with `seenURLs.contains(url)` before accepting each file. That only rejects byte-for-byte equal `URL` values. On macOS, the same selected file can be represented through a symlink or non-standardized path and still point to the same filesystem item, so the current logic can create two accepted rows for one file. That violates the phase's duplicate-rejection contract and can later cause a batch writer to process the same file more than once.

The existing duplicate test at `GPSMetadataEditorTests/FileIntakeServiceTests.swift:81` only covers the exact same URL appearing twice in one intake call. It does not cover duplicates against `currentSelection` using a different spelling for the same file.

**Fix:**

Normalize the identity used for duplicate checks while preserving the original URL in `SelectedMediaFile`.

```swift
func intake(urls: [URL], currentSelection: [SelectedMediaFile]) -> FileIntakeResult {
    var accepted: [SelectedMediaFile] = []
    var warnings: [IntakeWarning] = []
    var seenFileIdentities = Set(currentSelection.map { fileIdentity(for: $0.url) })

    for url in urls {
        let filename = displayName(for: url)
        let identity = fileIdentity(for: url)

        guard seenFileIdentities.contains(identity) == false else {
            warnings.append(IntakeWarning(filename: filename, url: url, reason: .duplicate))
            continue
        }

        switch classify(url: url) {
        case .accepted(let kind):
            accepted.append(SelectedMediaFile(url: url, kind: kind))
            seenFileIdentities.insert(identity)
        case .rejected(let reason):
            warnings.append(IntakeWarning(filename: filename, url: url, reason: reason))
        }
    }

    return FileIntakeResult(accepted: accepted, warnings: warnings)
}

private func fileIdentity(for url: URL) -> URL {
    url.resolvingSymlinksInPath().standardizedFileURL
}
```

Add a regression test that creates a file, creates a symlink or otherwise non-standardized URL to the same file, places one URL in `currentSelection`, then asserts the alternate URL is rejected with `.duplicate`.

---

_Reviewed: 2026-05-16T08:33:45Z_
_Reviewer: the agent (gsd-code-reviewer)_
_Depth: standard_
