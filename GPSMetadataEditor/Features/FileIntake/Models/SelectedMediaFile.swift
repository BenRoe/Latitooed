import Foundation

nonisolated struct SelectedMediaFile: Identifiable, Hashable, Sendable {
    let id: URL
    let url: URL
    let displayName: String
    let containingFolderURL: URL
    let containingFolderName: String
    let kind: MediaFileKind
    let gpsStatus: GPSStatus
    let latestResult: FileResultStatus
    let latestMessage: String?
    let latestDiagnosticDetail: String?

    init(
        url: URL,
        kind: MediaFileKind,
        gpsStatus: GPSStatus = .notChecked,
        latestResult: FileResultStatus = .pending,
        latestMessage: String? = nil,
        latestDiagnosticDetail: String? = nil
    ) {
        self.id = url
        self.url = url
        self.displayName = url.lastPathComponent
        self.containingFolderURL = url.deletingLastPathComponent()
        self.containingFolderName = url.deletingLastPathComponent().lastPathComponent
        self.kind = kind
        self.gpsStatus = gpsStatus
        self.latestResult = latestResult
        self.latestMessage = latestMessage
        self.latestDiagnosticDetail = latestDiagnosticDetail
    }
}
