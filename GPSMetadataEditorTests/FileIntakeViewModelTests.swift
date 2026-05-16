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
    }
}
