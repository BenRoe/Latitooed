nonisolated protocol MetadataWriter: Sendable {
    func writeGPS(_ coordinate: CoordinateSelection, to file: SelectedMediaFile) async -> MetadataWriteResult
}
