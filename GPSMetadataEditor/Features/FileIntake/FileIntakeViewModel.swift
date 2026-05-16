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
    }

    var selectedFiles: [SelectedMediaFile] = []
    var selectedFileID: SelectedMediaFile.ID?
    var latestNotice: IntakeNotice?
    var latestWarningDetails: [IntakeWarning] = []
    var isFileImporterPresented = false
    var isDropTargeted = false

    var selectedFileDetail: SelectedFileDetail? {
        guard let selectedFileID,
              let selectedFile = selectedFiles.first(where: { $0.id == selectedFileID }) else {
            return nil
        }

        return SelectedFileDetail(
            filename: selectedFile.displayName,
            containingFolderName: selectedFile.containingFolderName,
            containingFolderURL: selectedFile.containingFolderURL
        )
    }

    @ObservationIgnored
    private let service: FileIntakeService

    init(service: FileIntakeService = FileIntakeService()) {
        self.service = service
    }

    func presentFileImporter() {
        isFileImporterPresented = true
    }

    func intake(urls: [URL], source: IntakeSource) {
        let result = service.intake(urls: urls, currentSelection: selectedFiles)
        apply(result, source: source)
    }

    func apply(_ result: FileIntakeResult, source: IntakeSource) {
        selectedFiles.append(contentsOf: result.accepted)
        latestWarningDetails = result.warnings
        latestNotice = notice(for: result, source: source)

        if let selectedFileID, selectedFiles.contains(where: { $0.id == selectedFileID }) == false {
            self.selectedFileID = nil
        }
    }

    func selectFile(id: SelectedMediaFile.ID?) {
        selectedFileID = id
    }

    func reportPickerFailure(_ error: any Error) {
        latestWarningDetails = []
        latestNotice = IntakeNotice(
            message: "Files could not be added. \(error.localizedDescription)",
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
}
