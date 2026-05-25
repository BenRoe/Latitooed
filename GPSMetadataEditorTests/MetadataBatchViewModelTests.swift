import Foundation
import SwiftData
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

    @Test func batchPublishesFilenameFirstProgressBeforeWriterReturns() async throws {
        let first = heicFile("IMG_001.HEIC")
        let second = jpegFile("IMG_002.JPG")
        let writer = SuspendedMetadataWriter()
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [first, second], warnings: []), source: .picker)

        let batchTask = Task {
            await viewModel.applyMetadata(coordinate: .berlin, writer: writer)
        }

        try await waitUntil {
            viewModel.currentMetadataBatchProgress?.displayString == "Writing IMG_001.HEIC (1 of 2)"
        }
        #expect(viewModel.selectedFiles.first?.latestResult == .pending)

        await writer.resumeNext(with: .success(for: first, message: "Updated"))
        try await waitUntil {
            viewModel.currentMetadataBatchProgress?.displayString == "Writing IMG_002.JPG (2 of 2)"
        }
        await writer.resumeNext(with: .success(for: second, message: "Updated"))
        await batchTask.value

        #expect(viewModel.currentMetadataBatchProgress == nil)
    }

    @Test func selectedRowRemainsPendingWhileWriterIsSuspended() async throws {
        let file = heicFile("IMG_001.HEIC")
        let writer = SuspendedMetadataWriter()
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [file], warnings: []), source: .picker)

        let batchTask = Task {
            await viewModel.applyMetadata(coordinate: .berlin, writer: writer)
        }

        try await waitUntil { viewModel.currentMetadataBatchProgress != nil }
        #expect(viewModel.selectedFiles.first?.latestResult == .pending)

        await writer.resumeNext(with: .success(for: file, message: "Updated"))
        await batchTask.value

        #expect(viewModel.selectedFiles.first?.latestResult == .success)
    }

    @Test func applyingMetadataClearsPreviousWriteMarkersBeforeNewResultsArrive() async throws {
        let first = SelectedMediaFile(
            url: URL(filePath: "/Volumes/Photos/first.jpg"),
            kind: .jpeg,
            gpsStatus: .present(latitude: 52.520008, longitude: 13.404954),
            latestResult: .success,
            latestMessage: "Previous success"
        )
        let second = SelectedMediaFile(
            url: URL(filePath: "/Volumes/Photos/second.heic"),
            kind: .heic,
            gpsStatus: .notPresent,
            latestResult: .failure,
            latestMessage: "Previous failure",
            latestDiagnosticDetail: "Old stderr"
        )
        let writer = SuspendedMetadataWriter()
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [first, second], warnings: []), source: .picker)

        let batchTask = Task {
            await viewModel.applyMetadata(coordinate: .berlin, writer: writer)
        }

        try await waitUntil { viewModel.currentMetadataBatchProgress != nil }
        #expect(viewModel.selectedFiles.map(\.latestResult) == [.pending, .pending])
        #expect(viewModel.selectedFiles.map(\.latestMessage) == [nil, nil])
        #expect(viewModel.selectedFiles.map(\.latestDiagnosticDetail) == [nil, nil])
        #expect(viewModel.selectedFiles.map(\.gpsStatus) == [.present(latitude: 52.520008, longitude: 13.404954), .notPresent])

        await writer.resumeNext(with: .success(for: first, message: "Updated"))
        try await waitUntil { viewModel.currentMetadataBatchProgress?.displayString.hasSuffix("(2 of 2)") == true }
        await writer.resumeNext(with: .failure(for: second, message: "Failed"))
        await batchTask.value

        #expect(viewModel.selectedFiles.map(\.latestResult) == [.success, .failure])
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

    @Test func warningAndFailureDetailsExposeDiagnosticDetail() async throws {
        let warningFile = movFile("warning.mov")
        let failureFile = heicFile("failure.heic")
        let writer = RecordingMetadataWriter(results: [
            .warning(for: warningFile, message: "Warning", diagnosticDetail: "warning stderr"),
            .failure(for: failureFile, message: "Failure", diagnosticDetail: "failure stderr"),
        ])
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [warningFile, failureFile], warnings: []), source: .picker)

        await viewModel.applyMetadata(coordinate: .berlin, writer: writer)

        viewModel.selectFile(id: warningFile.id)
        let warningDetail = try #require(viewModel.selectedFileDetail)
        #expect(warningDetail.latestDiagnosticDetail == "warning stderr")

        viewModel.selectFile(id: failureFile.id)
        let failureDetail = try #require(viewModel.selectedFileDetail)
        #expect(failureDetail.latestDiagnosticDetail == "failure stderr")
    }

    @Test func successDetailsDoNotExposeDiagnosticDetail() async throws {
        let file = jpegFile("success.jpg")
        let writer = RecordingMetadataWriter(results: [
            .success(for: file, message: "Updated", diagnosticDetail: "stdout details"),
        ])
        let viewModel = FileIntakeViewModel()
        viewModel.apply(FileIntakeResult(accepted: [file], warnings: []), source: .picker)

        await viewModel.applyMetadata(coordinate: .berlin, writer: writer)
        viewModel.selectFile(id: file.id)

        let detail = try #require(viewModel.selectedFileDetail)
        #expect(detail.latestResult == .success)
        #expect(detail.latestDiagnosticDetail == nil)
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

    @Test func historyCoordinateReuseDoesNotRestorePreviousSelectedFiles() throws {
        let fileIntakeViewModel = FileIntakeViewModel()
        let currentFile = jpegFile("current.jpg")
        fileIntakeViewModel.apply(FileIntakeResult(accepted: [currentFile], warnings: []), source: .picker)
        let coordinateViewModel = CoordinateSelectionViewModel(searchService: FakeCoordinateSearchService())
        let batchSummary = BatchRunSummary(
            timestamp: Date(timeIntervalSinceReferenceDate: 0),
            coordinateLabel: "Berlin",
            latitude: CoordinateSelection.berlin.latitude,
            longitude: CoordinateSelection.berlin.longitude,
            totalFileCount: 12,
            successCount: 9,
            warningCount: 2,
            failureCount: 1
        )
        let snapshot = BatchRunSummarySnapshot(
            id: batchSummary.persistentModelID,
            timestamp: batchSummary.timestamp,
            coordinateLabel: batchSummary.coordinateLabel,
            coordinate: batchSummary.coordinate ?? .berlin,
            totalFileCount: batchSummary.totalFileCount,
            successCount: batchSummary.successCount,
            warningCount: batchSummary.warningCount,
            failureCount: batchSummary.failureCount
        )

        coordinateViewModel.selectBatchRunSummary(snapshot)

        #expect(coordinateViewModel.selectedCoordinate == .berlin)
        #expect(coordinateViewModel.selectedCoordinateLabel == "Berlin")
        #expect(fileIntakeViewModel.selectedFiles == [currentFile])
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

private actor SuspendedMetadataWriter: MetadataWriter {
    private var continuations: [CheckedContinuation<MetadataWriteResult, Never>] = []

    func writeGPS(_ coordinate: CoordinateSelection, to file: SelectedMediaFile) async -> MetadataWriteResult {
        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func resumeNext(with result: MetadataWriteResult) {
        guard continuations.isEmpty == false else {
            return
        }

        continuations.removeFirst().resume(returning: result)
    }
}

private func waitUntil(
    _ condition: @MainActor @escaping () -> Bool,
    fileID: String = #fileID,
    filePath: String = #filePath,
    line: Int = #line,
    column: Int = #column
) async throws {
    for _ in 0..<20 {
        if await condition() {
            return
        }
        try await Task.sleep(for: .milliseconds(10))
    }

    Issue.record(
        "Condition was not met",
        sourceLocation: SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
    )
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
