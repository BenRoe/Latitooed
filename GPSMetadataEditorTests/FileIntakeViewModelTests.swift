import Foundation
import Testing
@testable import GPSMetadataEditor

@MainActor
struct FileIntakeViewModelTests {
    @Test func loadedFilesViewModeDefaultsToGrid() {
        let viewModel = FileIntakeViewModel()

        #expect(viewModel.selectedLoadedFilesViewMode == .grid)
    }

    @Test func loadedFilesViewModeIsSessionOnlyInstanceState() {
        let firstViewModel = FileIntakeViewModel()
        let secondViewModel = FileIntakeViewModel()

        firstViewModel.selectedLoadedFilesViewMode = .table

        #expect(firstViewModel.selectedLoadedFilesViewMode == .table)
        #expect(secondViewModel.selectedLoadedFilesViewMode == .grid)
    }

    @Test func successfulIntakeResultAppendsAcceptedSnapshots() {
        let viewModel = FileIntakeViewModel()
        let first = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"), kind: .heic)
        let second = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/clip.MOV"), kind: .mov)

        viewModel.apply(FileIntakeResult(accepted: [first, second], warnings: []), source: .picker)

        #expect(viewModel.selectedFiles == [first, second])
        #expect(viewModel.selectedFiles.count == 2)
        #expect(viewModel.latestWarningDetails.isEmpty)
        #expect(viewModel.latestNotice?.style == .success)
        #expect(viewModel.latestNotice?.message == "2 files loaded.")
    }

    @Test func duplicateAndUnsupportedWarningsUpdateLatestDetailsWithoutAddingRows() {
        let viewModel = FileIntakeViewModel()
        let accepted = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"), kind: .heic)
        let duplicate = IntakeWarning(filename: "IMG 001.HEIC", url: accepted.url, reason: .duplicate)
        let unsupported = IntakeWarning(filename: "notes.txt", url: URL(filePath: "/Volumes/Photos/Trip/notes.txt"), reason: .unsupported)

        viewModel.apply(FileIntakeResult(accepted: [accepted], warnings: []), source: .picker)
        viewModel.apply(FileIntakeResult(accepted: [], warnings: [duplicate, unsupported]), source: .drop)

        #expect(viewModel.selectedFiles == [accepted])
        #expect(viewModel.latestWarningDetails == [duplicate, unsupported])
        #expect(viewModel.latestNotice?.style == .warning)
    }

    @Test func newIntakeEventReplacesPreviousLatestWarningDetails() {
        let viewModel = FileIntakeViewModel()
        let firstWarning = IntakeWarning(filename: "first.txt", url: URL(filePath: "/tmp/first.txt"), reason: .unsupported)
        let secondWarning = IntakeWarning(filename: "second.txt", url: URL(filePath: "/tmp/second.txt"), reason: .missing)

        viewModel.apply(FileIntakeResult(accepted: [], warnings: [firstWarning]), source: .picker)
        viewModel.apply(FileIntakeResult(accepted: [], warnings: [secondWarning]), source: .drop)

        #expect(viewModel.latestWarningDetails == [secondWarning])
        #expect(viewModel.latestWarningDetails.contains(firstWarning) == false)
    }

    @Test func noSelectedFileProducesNoReviewState() {
        let viewModel = FileIntakeViewModel()
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"), kind: .heic)

        viewModel.apply(FileIntakeResult(accepted: [file], warnings: []), source: .picker)

        #expect(viewModel.selectedFileReview == .none)
    }

    @Test func selectingRowExposesFilenameAndFullPathDetails() throws {
        let viewModel = FileIntakeViewModel()
        let file = SelectedMediaFile(
            url: URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"),
            kind: .heic,
            latestResult: .warning,
            latestMessage: "GPS write completed with warnings.",
            latestDiagnosticDetail: "ExifTool warning"
        )

        viewModel.apply(FileIntakeResult(accepted: [file], warnings: []), source: .picker)
        viewModel.selectFile(id: file.id)

        let detail = try #require(viewModel.selectedFileDetail)
        #expect(detail.filename == "IMG 001.HEIC")
        #expect(detail.fileURL == URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"))
        #expect(detail.containingFolderName == "Trip")
        #expect(detail.containingFolderURL == URL(filePath: "/Volumes/Photos/Trip", directoryHint: .isDirectory))
        #expect(detail.gpsStatus == .notChecked)
        #expect(detail.latestResult == .warning)
        #expect(detail.latestMessage == "GPS write completed with warnings.")
        #expect(detail.latestDiagnosticDetail == "ExifTool warning")

        let reviewDetail = try #require(viewModel.singleFileReviewDetail)
        #expect(reviewDetail == detail)
    }

    @Test func selectedDetailIncludesLatestResultMessageForDetailPanel() throws {
        let viewModel = FileIntakeViewModel()
        let file = SelectedMediaFile(
            url: URL(filePath: "/Volumes/Photos/Trip/clip.MP4"),
            kind: .mp4,
            latestResult: .warning,
            latestMessage: "Video metadata support will be checked during writing."
        )

        viewModel.apply(FileIntakeResult(accepted: [file], warnings: []), source: .drop)
        viewModel.selectFile(id: file.id)

        let detail = try #require(viewModel.selectedFileDetail)
        #expect(detail.filename == "clip.MP4")
        #expect(detail.latestResult == .warning)
        #expect(detail.latestMessage == "Video metadata support will be checked during writing.")
    }

    @Test func selectedDetailIncludesScannedLatitudeAndLongitude() throws {
        let viewModel = FileIntakeViewModel()
        let file = SelectedMediaFile(
            url: URL(filePath: "/Volumes/Photos/Trip/located.JPG"),
            kind: .jpeg,
            gpsStatus: .present(latitude: 52.520008, longitude: 13.404954)
        )

        viewModel.apply(FileIntakeResult(accepted: [file], warnings: []), source: .picker)
        viewModel.selectFile(id: file.id)

        let detail = try #require(viewModel.selectedFileDetail)
        #expect(detail.gpsStatus == .present(latitude: 52.520008, longitude: 13.404954))
        #expect(detail.gpsStatus.displayName == "52.520008, 13.404954")
    }

    @Test func selectedFileIDsSupportMultipleTableRows() throws {
        let viewModel = FileIntakeViewModel()
        let first = SelectedMediaFile(
            url: URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"),
            kind: .heic,
            latestResult: .warning
        )
        let second = SelectedMediaFile(
            url: URL(filePath: "/Volumes/Photos/Trip/IMG 002.JPG"),
            kind: .jpeg,
            latestResult: .success
        )

        viewModel.apply(FileIntakeResult(accepted: [first, second], warnings: []), source: .picker)
        viewModel.selectFiles(ids: [first.id, second.id])

        #expect(viewModel.selectedFileIDs == [first.id, second.id])
        #expect(viewModel.selectedLoadedFileCount == 2)
        #expect(viewModel.selectedFileDetail == nil)

        let summary = try #require(viewModel.multipleFileReviewSummary)
        #expect(summary.selectedCount == 2)
        #expect(summary.fileTypeCounts[.heic] == 1)
        #expect(summary.fileTypeCounts[.jpeg] == 1)
        #expect(summary.latestResultCounts[.warning] == 1)
        #expect(summary.latestResultCounts[.success] == 1)
    }

    @Test func selectedLoadedFileCountExcludesUnselectedLoadedFiles() {
        let viewModel = FileIntakeViewModel()
        let files = makeGridSelectionFiles()

        viewModel.apply(FileIntakeResult(accepted: files, warnings: []), source: .picker)
        viewModel.selectFile(id: files[0].id)

        #expect(viewModel.selectedFiles.count == 3)
        #expect(viewModel.selectedLoadedFileCount == 1)
    }

    @Test func replacingGridSelectionSelectsOnlyClickedFile() {
        let viewModel = FileIntakeViewModel()
        let files = makeGridSelectionFiles()

        viewModel.apply(FileIntakeResult(accepted: files, warnings: []), source: .picker)
        viewModel.replaceGridSelection(with: files[1].id)

        #expect(viewModel.selectedFileIDs == [files[1].id])
        #expect(viewModel.lastGridSelectionAnchorID == files[1].id)
    }

    @Test func togglingGridSelectionAddsAndRemovesClickedFile() {
        let viewModel = FileIntakeViewModel()
        let files = makeGridSelectionFiles()

        viewModel.apply(FileIntakeResult(accepted: files, warnings: []), source: .picker)
        viewModel.replaceGridSelection(with: files[0].id)
        viewModel.toggleGridSelection(id: files[1].id)

        #expect(viewModel.selectedFileIDs == [files[0].id, files[1].id])
        #expect(viewModel.lastGridSelectionAnchorID == files[1].id)

        viewModel.toggleGridSelection(id: files[1].id)

        #expect(viewModel.selectedFileIDs == [files[0].id])
        #expect(viewModel.lastGridSelectionAnchorID == files[1].id)
    }

    @Test func rangeGridSelectionUsesSelectedFilesOrder() {
        let viewModel = FileIntakeViewModel()
        let files = makeGridSelectionFiles()

        viewModel.apply(FileIntakeResult(accepted: files, warnings: []), source: .picker)
        viewModel.replaceGridSelection(with: files[0].id)
        viewModel.selectGridRange(to: files[2].id)

        #expect(viewModel.selectedFileIDs == [files[0].id, files[1].id, files[2].id])
    }

    @Test func staleGridRangeFallsBackToPlainSelection() {
        let viewModel = FileIntakeViewModel()
        let files = makeGridSelectionFiles()

        viewModel.apply(FileIntakeResult(accepted: files, warnings: []), source: .picker)
        viewModel.replaceGridSelection(with: files[0].id)
        viewModel.selectedFiles.removeFirst()
        viewModel.selectGridRange(to: files[2].id)

        #expect(viewModel.selectedFileIDs == [files[2].id])
        #expect(viewModel.lastGridSelectionAnchorID == files[2].id)
    }

    @Test func latestWarningsExposeEveryRejectedItemForWarningSummary() {
        let viewModel = FileIntakeViewModel()
        let unsupported = IntakeWarning(filename: "notes.txt", url: URL(filePath: "/tmp/notes.txt"), reason: .unsupported)
        let directory = IntakeWarning(filename: "Album", url: URL(filePath: "/tmp/Album", directoryHint: .isDirectory), reason: .directory)
        let locked = IntakeWarning(filename: "locked.heic", url: URL(filePath: "/tmp/locked.heic"), reason: .locked)

        viewModel.apply(FileIntakeResult(accepted: [], warnings: [unsupported, directory, locked]), source: .drop)

        #expect(viewModel.latestWarningDetails.map(\.filename) == ["notes.txt", "Album", "locked.heic"])
        #expect(viewModel.latestWarningDetails.map(\.reason) == [.unsupported, .directory, .locked])
        #expect(viewModel.latestNotice?.message == "3 items could not be added.")
    }

    @Test func intakeCommandDelegatesURLClassificationThroughService() throws {
        let directory = try temporaryDirectory()
        let supportedURL = directory.appending(path: "family photo.JPG")
        let unsupportedURL = directory.appending(path: "notes.txt")
        try Data().write(to: supportedURL)
        try Data().write(to: unsupportedURL)
        let viewModel = FileIntakeViewModel()

        viewModel.intake(urls: [supportedURL, unsupportedURL], source: .drop)

        #expect(viewModel.selectedFiles.map(\.url) == [supportedURL])
        #expect(viewModel.selectedFiles.map(\.kind) == [.jpeg])
        #expect(viewModel.latestWarningDetails.map(\.reason) == [.unsupported])
    }

    @Test func intakeCommandScansAcceptedFilesForExistingGPSCoordinates() async throws {
        let directory = try temporaryDirectory()
        let locatedURL = directory.appending(path: "located.JPG")
        let unlocatedURL = directory.appending(path: "unlocated.HEIC")
        try Data().write(to: locatedURL)
        try Data().write(to: unlocatedURL)
        let viewModel = FileIntakeViewModel(
            gpsMetadataReader: FakeGPSMetadataReader(statuses: [
                locatedURL: .present(latitude: 52.520008, longitude: 13.404954),
                unlocatedURL: .notPresent,
            ])
        )

        viewModel.intake(urls: [locatedURL, unlocatedURL], source: .picker)

        try await waitUntil {
            viewModel.selectedFiles.map(\.gpsStatus) == [.present(latitude: 52.520008, longitude: 13.404954), .notPresent]
        }

        #expect(viewModel.selectedFiles.first?.gpsStatus.displayName == "52.520008, 13.404954")
        #expect(viewModel.selectedFiles.last?.gpsStatus.displayName == "No coordinates")
    }

    @Test func gpsStatusDisplaysLatitudeAndLongitudeInsteadOfPresenceLabels() {
        let status = GPSStatus.present(latitude: 48.137154, longitude: 11.576124)

        #expect(status.displayName == "48.137154, 11.576124")
        #expect(GPSStatus.notPresent.displayName == "No coordinates")
        #expect(GPSStatus.notPresent.displayName != "No GPS")
        #expect(status.displayName != "Has GPS")
    }

    @Test func exifToolGPSMetadataReaderMapsJSONCoordinatesToDisplayableStatus() async throws {
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/located.jpg"), kind: .jpeg)
        let runner = RecordingGPSReadRunner(
            result: ProcessResult(
                terminationStatus: 0,
                standardOutput: #"""
                [
                    {"SourceFile":"/Volumes/Photos/located.jpg","GPSLatitude":52.520008,"GPSLongitude":13.404954}
                ]
                """#,
                standardError: ""
            )
        )
        let reader = ExifToolGPSMetadataReader(
            resolver: BundledExifToolResolver(bundle: try Self.fakeExifToolBundle()),
            processRunner: runner
        )

        let status = await reader.gpsStatus(for: file)

        #expect(status == .present(latitude: 52.520008, longitude: 13.404954))
        #expect(status?.displayName == "52.520008, 13.404954")
        #expect(runner.capturedArguments.contains("-json"))
        #expect(runner.capturedArguments.contains("-n"))
        #expect(runner.capturedArguments.contains("-GPSLatitude"))
        #expect(runner.capturedArguments.contains("-GPSLongitude"))
    }

    @Test func exifToolGPSMetadataReaderMapsMissingCoordinatesToNoCoordinates() async throws {
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/unlocated.jpg"), kind: .jpeg)
        let runner = RecordingGPSReadRunner(
            result: ProcessResult(
                terminationStatus: 0,
                standardOutput: #"""
                [
                    {"SourceFile":"/Volumes/Photos/unlocated.jpg"}
                ]
                """#,
                standardError: ""
            )
        )
        let reader = ExifToolGPSMetadataReader(
            resolver: BundledExifToolResolver(bundle: try Self.fakeExifToolBundle()),
            processRunner: runner
        )

        let status = await reader.gpsStatus(for: file)

        #expect(status == .notPresent)
        #expect(runner.capturedArguments.contains("-json"))
        #expect(runner.capturedArguments.contains("-n"))
        #expect(runner.capturedArguments.contains("-GPSLatitude"))
        #expect(runner.capturedArguments.contains("-GPSLongitude"))
    }

    @Test func exifToolGPSMetadataReaderMapsVideoGPSCoordinatesString() async throws {
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/clip.mov"), kind: .mov)
        let runner = RecordingGPSReadRunner(
            result: ProcessResult(
                terminationStatus: 0,
                standardOutput: #"""
                [
                    {"SourceFile":"/Volumes/Photos/clip.mov","GPSCoordinates":"+52.520008+013.404954/"}
                ]
                """#,
                standardError: ""
            )
        )
        let reader = ExifToolGPSMetadataReader(
            resolver: BundledExifToolResolver(bundle: try Self.fakeExifToolBundle()),
            processRunner: runner
        )

        let status = await reader.gpsStatus(for: file)

        #expect(status == .present(latitude: 52.520008, longitude: 13.404954))
        #expect(runner.capturedArguments.contains("-json"))
        #expect(runner.capturedArguments.contains("-n"))
        #expect(runner.capturedArguments.contains("-GPSLatitude"))
        #expect(runner.capturedArguments.contains("-GPSLongitude"))
    }

    private static func fakeExifToolBundle() throws -> Bundle {
        let bundleURL = URL.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let helperDirectoryURL = bundleURL.appending(path: "ExifTool", directoryHint: .isDirectory)
        let helperURL = helperDirectoryURL.appending(path: "exiftool")
        try FileManager.default.createDirectory(at: helperDirectoryURL, withIntermediateDirectories: true)
        try Data().write(to: helperURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: helperURL.path(percentEncoded: false))

        return try #require(Bundle(url: bundleURL))
    }

    private final class RecordingGPSReadRunner: ProcessRunning, @unchecked Sendable {
        let result: ProcessResult
        private(set) var capturedArguments: [String] = []

        init(result: ProcessResult) { self.result = result }

        func run(executableURL: URL, arguments: [String]) async throws -> ProcessResult {
            capturedArguments = arguments
            return result
        }
    }

    private func temporaryDirectory() throws -> URL {
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func makeGridSelectionFiles() -> [SelectedMediaFile] {
        [
            SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"), kind: .heic),
            SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/IMG 002.JPG"), kind: .jpeg),
            SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/clip.MOV"), kind: .mov),
        ]
    }
}

private struct FakeGPSMetadataReader: GPSMetadataReading {
    let statuses: [URL: GPSStatus]

    func gpsStatus(for file: SelectedMediaFile) async -> GPSStatus? {
        statuses[file.url]
    }
}

private func waitUntil(
    _ condition: @MainActor @escaping () -> Bool,
    sourceLocation: SourceLocation = #_sourceLocation
) async throws {
    for _ in 0..<20 {
        if await condition() { return }
        await Task.yield()
    }
    Issue.record("Condition was not met", sourceLocation: sourceLocation)
}

private extension FileIntakeViewModel {
    var singleFileReviewDetail: FileIntakeViewModel.SelectedFileDetail? {
        if case .single(let detail) = selectedFileReview {
            detail
        } else {
            nil
        }
    }

    var multipleFileReviewSummary: FileIntakeViewModel.SelectedFilesSummary? {
        if case .multiple(let summary) = selectedFileReview {
            summary
        } else {
            nil
        }
    }
}
