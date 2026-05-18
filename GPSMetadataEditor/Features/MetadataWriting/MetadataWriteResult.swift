import Foundation

nonisolated struct MetadataWriteResult: Equatable, Sendable {
    let fileID: SelectedMediaFile.ID
    let url: URL
    let status: FileResultStatus
    let message: String
    let diagnosticDetail: String?
    let gpsStatus: GPSStatus?

    init(
        fileID: SelectedMediaFile.ID,
        url: URL,
        status: FileResultStatus,
        message: String,
        diagnosticDetail: String? = nil,
        gpsStatus: GPSStatus? = nil
    ) {
        self.fileID = fileID
        self.url = url
        self.status = status
        self.message = message
        self.diagnosticDetail = diagnosticDetail
        self.gpsStatus = gpsStatus
    }

    static func success(
        for file: SelectedMediaFile,
        message: String,
        diagnosticDetail: String? = nil
    ) -> MetadataWriteResult {
        MetadataWriteResult(
            fileID: file.id,
            url: file.url,
            status: .success,
            message: message,
            diagnosticDetail: diagnosticDetail,
            gpsStatus: .updated
        )
    }

    static func warning(
        for file: SelectedMediaFile,
        message: String,
        diagnosticDetail: String? = nil
    ) -> MetadataWriteResult {
        MetadataWriteResult(
            fileID: file.id,
            url: file.url,
            status: .warning,
            message: message,
            diagnosticDetail: diagnosticDetail,
            gpsStatus: nil
        )
    }

    static func failure(
        for file: SelectedMediaFile,
        message: String,
        diagnosticDetail: String? = nil
    ) -> MetadataWriteResult {
        MetadataWriteResult(
            fileID: file.id,
            url: file.url,
            status: .failure,
            message: message,
            diagnosticDetail: diagnosticDetail,
            gpsStatus: nil
        )
    }
}
