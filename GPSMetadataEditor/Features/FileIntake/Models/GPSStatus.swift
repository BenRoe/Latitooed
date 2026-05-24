import Foundation

nonisolated enum GPSStatus: Hashable, Sendable {
    case notChecked
    case notPresent
    case present(latitude: Double, longitude: Double)
    case updated

    var displayName: String {
        switch self {
        case .notChecked:
            "Not checked"
        case .notPresent:
            "No coordinates"
        case .present(let latitude, let longitude):
            "\(Self.formattedCoordinate(latitude)), \(Self.formattedCoordinate(longitude))"
        case .updated:
            "Updated"
        }
    }

    var systemImage: String {
        switch self {
        case .notChecked, .notPresent:
            "location.slash"
        case .present:
            "location"
        case .updated:
            "location.fill"
        }
    }

    var coordinate: CoordinateSelection? {
        switch self {
        case .present(let latitude, let longitude):
            CoordinateSelection(latitude: latitude, longitude: longitude)
        case .notChecked, .notPresent, .updated:
            nil
        }
    }

    private static func formattedCoordinate(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(6)).locale(Locale(identifier: "en_US_POSIX")))
    }
}
