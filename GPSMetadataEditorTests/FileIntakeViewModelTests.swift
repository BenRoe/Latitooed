import Foundation
import Testing
@testable import GPSMetadataEditor

@MainActor
struct FileIntakeViewModelTests {
    @Test func successfulIntakeResultAppendsAcceptedSnapshots() {
        let viewModel = FileIntakeViewModel()
        let first = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"), kind: .heic)
        let second = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/clip.MOV"), kind: .mov)

        viewModel.apply(FileIntakeResult(accepted: [first, second], warnings: []), source: .picker)

        #expect(viewModel.selectedFiles == [first, second])
        #expect(viewModel.selectedFiles.count == 2)
        #expect(viewModel.latestWarningDetails.isEmpty)
        #expect(viewModel.latestNotice?.style == .success)
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

    @Test func selectingRowExposesFilenameAndContainingFolderDetails() throws {
        let viewModel = FileIntakeViewModel()
        let file = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"), kind: .heic)

        viewModel.apply(FileIntakeResult(accepted: [file], warnings: []), source: .picker)
        viewModel.selectFile(id: file.id)

        let detail = try #require(viewModel.selectedFileDetail)
        #expect(detail.filename == "IMG 001.HEIC")
        #expect(detail.containingFolderName == "Trip")
        #expect(detail.containingFolderURL == URL(filePath: "/Volumes/Photos/Trip", directoryHint: .isDirectory))
        #expect(detail.latestResult == .pending)
        #expect(detail.latestMessage == nil)
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

    @Test func selectedFileIDsSupportMultipleTableRows() throws {
        let viewModel = FileIntakeViewModel()
        let first = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/IMG 001.HEIC"), kind: .heic)
        let second = SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/Trip/IMG 002.JPG"), kind: .jpeg)

        viewModel.apply(FileIntakeResult(accepted: [first, second], warnings: []), source: .picker)
        viewModel.selectFiles(ids: [first.id, second.id])

        #expect(viewModel.selectedFileIDs == [first.id, second.id])
        let detail = try #require(viewModel.selectedFileDetail)
        #expect(detail.filename == "IMG 001.HEIC")
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

    private func temporaryDirectory() throws -> URL {
        let url = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
