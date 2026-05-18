import Foundation

nonisolated struct ExifToolArgumentBuilder: Sendable {
    nonisolated enum BuildError: Error, Equatable, Sendable {
        case unsupportedMediaKind(MediaFileKind)
    }

    func gpsWriteArguments(for file: SelectedMediaFile, coordinate: CoordinateSelection) throws -> [String] {
        switch file.kind {
        case .jpeg, .heic:
            [
                "-overwrite_original",
                "-gpsposition=\(coordinate.latitude), \(coordinate.longitude)",
                file.url.path(percentEncoded: false),
            ]
        case .mov, .mp4:
            throw BuildError.unsupportedMediaKind(file.kind)
        }
    }
}
