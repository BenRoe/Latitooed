import Foundation
import Observation

@Observable
@MainActor
final class FileIntakeViewModel {
    enum IntakeSource: Equatable, Sendable {
        case picker
        case drop
    }

    enum NoticeStyle: Equatable, Sendable {
        case success
        case warning
    }

    enum LoadedFilesViewMode: String, CaseIterable, Identifiable, Sendable {
        case table
        case grid

        var id: Self { self }

        var displayName: String {
            switch self {
            case .table:
                "Table"
            case .grid:
                "Grid"
            }
        }
    }

    enum GridSelectionIntent: Equatable, Sendable {
        case replace
        case toggle
        case range
    }

    struct IntakeNotice: Equatable, Identifiable, Sendable {
        let id = UUID()
        let message: String
        let style: NoticeStyle

        static func == (lhs: IntakeNotice, rhs: IntakeNotice) -> Bool {
            lhs.message == rhs.message && lhs.style == rhs.style
        }
    }

    struct SelectedFileDetail: Equatable, Sendable {
        let filename: String
        let containingFolderName: String
        let containingFolderURL: URL
        let gpsStatus: GPSStatus
        let latestResult: FileResultStatus
        let latestMessage: String?
        let latestDiagnosticDetail: String?
    }

    enum SelectedFileReview: Equatable, Sendable {
        case none
        case single(SelectedFileDetail)
        case multiple(SelectedFilesSummary)
    }

    struct SelectedFilesSummary: Equatable, Sendable {
        let selectedCount: Int
        let fileTypeCounts: [MediaFileKind: Int]
        let latestResultCounts: [FileResultStatus: Int]
    }

    struct MetadataBatchProgress: Equatable, Sendable {
        let filename: String
        let currentIndex: Int
        let totalCount: Int

        var displayString: String {
            "Writing \(filename) (\(currentIndex) of \(totalCount))"
        }
    }

    struct MetadataBatchSummary: Equatable, Sendable {
        let successCount: Int
        let warningCount: Int
        let failureCount: Int

        var message: String {
            "\(successCount) updated, \(warningCount) warning, \(failureCount) failed."
        }
    }

    var selectedFiles: [SelectedMediaFile] = []
    var selectedFileIDs: Set<SelectedMediaFile.ID> = []
    var selectedLoadedFilesViewMode: LoadedFilesViewMode = .grid
    var latestNotice: IntakeNotice?
    var latestWarningDetails: [IntakeWarning] = []
    var latestMetadataBatchSummary: MetadataBatchSummary?
    var currentMetadataBatchProgress: MetadataBatchProgress?
    var isMetadataBatchRunning = false
    var isFileImporterPresented = false
    var isDropTargeted = false
    private(set) var lastGridSelectionAnchorID: SelectedMediaFile.ID?

    var selectedFileReview: SelectedFileReview {
        let selectedFiles = selectedFiles.filter { selectedFileIDs.contains($0.id) }

        switch selectedFiles.count {
        case 0:
            return .none
        case 1:
            guard let selectedFile = selectedFiles.first else {
                return .none
            }

            return .single(Self.detail(for: selectedFile))
        default:
            return .multiple(
                SelectedFilesSummary(
                    selectedCount: selectedFiles.count,
                    fileTypeCounts: Self.counts(selectedFiles.map(\.kind)),
                    latestResultCounts: Self.counts(selectedFiles.map(\.latestResult))
                )
            )
        }
    }

    var selectedFileDetail: SelectedFileDetail? {
        if case .single(let detail) = selectedFileReview {
            detail
        } else {
            nil
        }
    }

    @ObservationIgnored
    private let service: FileIntakeService
    @ObservationIgnored
    private let gpsMetadataReader: any GPSMetadataReading

    init(
        service: FileIntakeService = FileIntakeService(),
        gpsMetadataReader: any GPSMetadataReading = ExifToolGPSMetadataReader()
    ) {
        self.service = service
        self.gpsMetadataReader = gpsMetadataReader
    }

    func presentFileImporter() {
        isFileImporterPresented = true
    }

    func intake(urls: [URL], source: IntakeSource) {
        let result = service.intake(urls: urls, currentSelection: selectedFiles)
        apply(result, source: source)

        let acceptedFiles = result.accepted
        Task {
            await refreshGPSStatuses(for: acceptedFiles)
        }
    }

    func apply(_ result: FileIntakeResult, source: IntakeSource) {
        selectedFiles.append(contentsOf: result.accepted)
        latestWarningDetails = result.warnings
        latestNotice = notice(for: result, source: source)

        let currentFileIDs = Set(selectedFiles.map(\.id))
        selectedFileIDs.formIntersection(currentFileIDs)
    }

    func selectFile(id: SelectedMediaFile.ID?) {
        if let id {
            selectedFileIDs = [id]
        } else {
            selectedFileIDs = []
        }
    }

    func selectFiles(ids: Set<SelectedMediaFile.ID>) {
        selectedFileIDs = ids
    }

    func activateGridSelection(id: SelectedMediaFile.ID, intent: GridSelectionIntent) {
        switch intent {
        case .replace:
            replaceGridSelection(with: id)
        case .toggle:
            toggleGridSelection(id: id)
        case .range:
            selectGridRange(to: id)
        }
    }

    func replaceGridSelection(with id: SelectedMediaFile.ID) {
        guard selectedFiles.contains(where: { $0.id == id }) else {
            selectedFileIDs = []
            lastGridSelectionAnchorID = nil
            return
        }

        selectedFileIDs = [id]
        lastGridSelectionAnchorID = id
    }

    func toggleGridSelection(id: SelectedMediaFile.ID) {
        guard selectedFiles.contains(where: { $0.id == id }) else {
            return
        }

        if selectedFileIDs.contains(id) {
            selectedFileIDs.remove(id)
        } else {
            selectedFileIDs.insert(id)
        }

        lastGridSelectionAnchorID = id
    }

    func selectGridRange(to id: SelectedMediaFile.ID) {
        guard let anchorID = lastGridSelectionAnchorID,
              let anchorIndex = selectedFiles.firstIndex(where: { $0.id == anchorID }),
              let targetIndex = selectedFiles.firstIndex(where: { $0.id == id }) else {
            replaceGridSelection(with: id)
            return
        }

        let range = min(anchorIndex, targetIndex)...max(anchorIndex, targetIndex)
        selectedFileIDs = Set(selectedFiles[range].map(\.id))
    }

    func canApplyMetadata(selectedCoordinate: CoordinateSelection?) -> Bool {
        selectedFiles.isEmpty == false && selectedCoordinate != nil && isMetadataBatchRunning == false
    }

    func applyMetadataIfConfirmed(
        _ isConfirmed: Bool,
        coordinate: CoordinateSelection?,
        writer: any MetadataWriter
    ) async {
        guard isConfirmed, let coordinate, canApplyMetadata(selectedCoordinate: coordinate) else {
            return
        }

        await applyMetadata(coordinate: coordinate, writer: writer)
    }

    func applyMetadata(coordinate: CoordinateSelection, writer: any MetadataWriter) async {
        guard isMetadataBatchRunning == false else {
            return
        }

        isMetadataBatchRunning = true
        latestMetadataBatchSummary = nil
        resetMetadataWriteResults()
        defer {
            currentMetadataBatchProgress = nil
            isMetadataBatchRunning = false
        }

        let files = selectedFiles
        var results: [MetadataWriteResult] = []

        for (index, file) in files.enumerated() {
            currentMetadataBatchProgress = MetadataBatchProgress(
                filename: file.displayName,
                currentIndex: index + 1,
                totalCount: files.count
            )
            let result = await writer.writeGPS(coordinate, to: file)
            results.append(result)
            replaceSelectedFile(matching: result)
        }

        let summary = MetadataBatchSummary(results: results)
        latestMetadataBatchSummary = summary
        latestNotice = IntakeNotice(
            message: summary.message,
            style: results.contains(where: { $0.status == .failure || $0.status == .warning }) ? .warning : .success
        )
    }

    func reportPickerFailure(_ error: any Error) {
        latestWarningDetails = []
        latestNotice = IntakeNotice(
            message: "Files could not be added. \(error.localizedDescription)",
            style: .warning
        )
    }

    func reportBatchHistoryFailure(_ error: any Error) {
        latestNotice = IntakeNotice(
            message: "Batch finished, but recent history could not be saved. \(error.localizedDescription)",
            style: .warning
        )
    }

    private func notice(for result: FileIntakeResult, source: IntakeSource) -> IntakeNotice? {
        if result.warnings.isEmpty == false {
            let itemLabel = result.warnings.count == 1 ? "item" : "items"
            return IntakeNotice(
                message: "\(result.warnings.count) \(itemLabel) could not be added.",
                style: .warning
            )
        }

        guard result.accepted.isEmpty == false else {
            return nil
        }

        let itemLabel = result.accepted.count == 1 ? "file" : "files"
        let sourceLabel = switch source {
        case .picker:
            "selected"
        case .drop:
            "dropped"
        }

        return IntakeNotice(
            message: "\(result.accepted.count) \(itemLabel) \(sourceLabel).",
            style: .success
        )
    }

    private func replaceSelectedFile(matching result: MetadataWriteResult) {
        guard let index = selectedFiles.firstIndex(where: { $0.id == result.fileID || $0.url == result.url }) else {
            return
        }

        let existing = selectedFiles[index]
        selectedFiles[index] = SelectedMediaFile(
            url: existing.url,
            kind: existing.kind,
            gpsStatus: result.gpsStatus ?? existing.gpsStatus,
            latestResult: result.status,
            latestMessage: result.message,
            latestDiagnosticDetail: result.detailForReview
        )
    }

    private func resetMetadataWriteResults() {
        selectedFiles = selectedFiles.map { file in
            SelectedMediaFile(
                url: file.url,
                kind: file.kind,
                gpsStatus: file.gpsStatus,
                latestResult: .pending
            )
        }
    }

    private func refreshGPSStatuses(for files: [SelectedMediaFile]) async {
        for file in files {
            guard let gpsStatus = await gpsMetadataReader.gpsStatus(for: file) else {
                continue
            }

            replaceGPSStatus(gpsStatus, for: file)
        }
    }

    private func replaceGPSStatus(_ gpsStatus: GPSStatus, for file: SelectedMediaFile) {
        guard let index = selectedFiles.firstIndex(where: { $0.id == file.id }) else {
            return
        }

        let existing = selectedFiles[index]
        guard existing.gpsStatus != .updated else {
            return
        }

        selectedFiles[index] = SelectedMediaFile(
            url: existing.url,
            kind: existing.kind,
            gpsStatus: gpsStatus,
            latestResult: existing.latestResult,
            latestMessage: existing.latestMessage,
            latestDiagnosticDetail: existing.latestDiagnosticDetail
        )
    }

    private static func detail(for selectedFile: SelectedMediaFile) -> SelectedFileDetail {
        SelectedFileDetail(
            filename: selectedFile.displayName,
            containingFolderName: selectedFile.containingFolderName,
            containingFolderURL: selectedFile.containingFolderURL,
            gpsStatus: selectedFile.gpsStatus,
            latestResult: selectedFile.latestResult,
            latestMessage: selectedFile.latestMessage,
            latestDiagnosticDetail: selectedFile.latestDiagnosticDetail
        )
    }

    private static func counts<Value: Hashable>(_ values: [Value]) -> [Value: Int] {
        values.reduce(into: [:]) { counts, value in
            counts[value, default: 0] += 1
        }
    }
}

private extension FileIntakeViewModel.MetadataBatchSummary {
    init(results: [MetadataWriteResult]) {
        successCount = results.filter { $0.status == .success }.count
        warningCount = results.filter { $0.status == .warning }.count
        failureCount = results.filter { $0.status == .failure }.count
    }
}

private extension MetadataWriteResult {
    var detailForReview: String? {
        switch status {
        case .warning, .failure:
            diagnosticDetail
        case .pending, .success:
            nil
        }
    }
}
