import Foundation
import Testing
@testable import GPSMetadataEditor

@MainActor
struct MetadataBatchViewModelTests {
    @Test func applyCommandDisabledWithNoSelectedFiles() {
        let viewModel = FileIntakeViewModel()

        #expect(viewModel.canApplyMetadata(selectedCoordinate: .berlin) == false)
    }

    @Test func applyCommandDisabledWithoutSelectedCoordinate() {
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [jpegFile("first.jpg")], warnings: []), source: .picker)

        #expect(viewModel.canApplyMetadata(selectedCoordinate: nil) == false)
    }

    @Test func applyCommandEnabledWithFilesAndCoordinate() {
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [jpegFile("first.jpg")], warnings: []), source: .picker)

        #expect(viewModel.canApplyMetadata(selectedCoordinate: .berlin))
    }

    @Test func batchCallsWriterInSelectedFileOrder() async {
        let files = [
            jpegFile("first.jpg"),
            heicFile("second.heic"),
            movFile("third.mov"),
        ]
        let writer = RecordingMetadataWriter(results: files.map { .success(for: $0, message: "Updated") })
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: files, warnings: []), source: .picker)

        await viewModel.applyMetadata(coordinate: .berlin, writer: writer)

        #expect(await writer.calledFileURLs == files.map(\.url))
    }

    @Test func batchReplacesRowsWithSuccessWarningAndFailureResults() async throws {
        let jpeg = jpegFile("first.jpg")
        let mov = movFile("second.mov")
        let heic = heicFile("third.heic")
        let writer = RecordingMetadataWriter(results: [
            .success(for: jpeg, message: "JPEG updated"),
            .warning(for: mov, message: "Video deferred"),
            .failure(for: heic, message: "HEIC failed"),
        ])
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [jpeg, mov, heic], warnings: []), source: .picker)

        await viewModel.applyMetadata(coordinate: .berlin, writer: writer)

        #expect(viewModel.selectedFiles.map(\.latestResult) == [.success, .warning, .failure])
        #expect(viewModel.selectedFiles.map(\.gpsStatus) == [.updated, .notChecked, .notChecked])
        #expect(viewModel.selectedFiles.map(\.latestMessage) == ["JPEG updated", "Video deferred", "HEIC failed"])
        let summary = try #require(viewModel.latestMetadataBatchSummary)
        #expect(summary.message == "1 updated, 1 warning, 1 failed.")
    }

    @Test func oneFailureDoesNotStopLaterFiles() async {
        let first = jpegFile("first.jpg")
        let second = heicFile("second.heic")
        let writer = RecordingMetadataWriter(results: [
            .failure(for: first, message: "Failed"),
            .success(for: second, message: "Updated"),
        ])
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [first, second], warnings: []), source: .picker)

        await viewModel.applyMetadata(coordinate: .berlin, writer: writer)

        #expect(await writer.calledFileURLs == [first.url, second.url])
        #expect(viewModel.selectedFiles.map(\.latestResult) == [.failure, .success])
    }

    @Test func abortConfirmationPathDoesNotInvokeWriter() async {
        let file = jpegFile("first.jpg")
        let writer = RecordingMetadataWriter(results: [.success(for: file, message: "Updated")])
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [file], warnings: []), source: .picker)

        await viewModel.applyMetadataIfConfirmed(false, coordinate: .berlin, writer: writer)

        #expect(await writer.calledFileURLs.isEmpty)
        #expect(viewModel.selectedFiles.first?.latestResult == .pending)
    }

    @Test func overwriteConfirmationPathInvokesBatchWithSelectedCoordinate() async {
        let file = jpegFile("first.jpg")
        let writer = RecordingMetadataWriter(results: [.success(for: file, message: "Updated")])
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [file], warnings: []), source: .picker)

        await viewModel.applyMetadataIfConfirmed(true, coordinate: .berlin, writer: writer)

        #expect(await writer.calledCoordinates == [.berlin])
    }

    @Test func commandDisabledWhileBatchIsRunning() {
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [jpegFile("first.jpg")], warnings: []), source: .picker)
        viewModel.isMetadataBatchRunning = true

        #expect(viewModel.canApplyMetadata(selectedCoordinate: .berlin) == false)
    }
}

private actor RecordingMetadataWriter: MetadataWriter {
    private(set) var calledFileURLs: [URL] = []
    private(set) var calledCoordinates: [CoordinateSelection] = []
    private var results: [MetadataWriteResult]

    init(results: [MetadataWriteResult]) {
        self.results = results
    }

    func writeGPS(_ coordinate: CoordinateSelection, to file: SelectedMediaFile) async -> MetadataWriteResult {
        calledCoordinates.append(coordinate)
        calledFileURLs.append(file.url)

        guard results.isEmpty == false else {
            return .failure(for: file, message: "Missing fake result")
        }

        return results.removeFirst()
    }
}

private func jpegFile(_ filename: String) -> SelectedMediaFile {
    SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/\(filename)"), kind: .jpeg)
}

private func heicFile(_ filename: String) -> SelectedMediaFile {
    SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/\(filename)"), kind: .heic)
}

private func movFile(_ filename: String) -> SelectedMediaFile {
    SelectedMediaFile(url: URL(filePath: "/Volumes/Photos/\(filename)"), kind: .mov)
}
