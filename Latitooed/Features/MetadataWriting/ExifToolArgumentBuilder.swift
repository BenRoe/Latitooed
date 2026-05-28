import Foundation

nonisolated struct ExifToolArgumentBuilder: Sendable {
    func gpsWriteArguments(for file: SelectedMediaFile, coordinate: CoordinateSelection) throws -> [String] {
        switch file.kind {
        case .jpeg, .heic:
            [
                "-overwrite_original",
                "-gpsposition=\(coordinate.latitude), \(coordinate.longitude)",
                file.url.path(percentEncoded: false),
            ]
        case .mov, .mp4:
            [
                "-overwrite_original",
                "-Keys:GPSCoordinates=\(coordinate.latitude), \(coordinate.longitude)",
                file.url.path(percentEncoded: false),
            ]
        }
    }
}
