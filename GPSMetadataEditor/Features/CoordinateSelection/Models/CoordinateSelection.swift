import Foundation

struct CoordinateSelection: Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    init?(latitude: Double, longitude: Double) {
        guard Self.isValidLatitude(latitude), Self.isValidLongitude(longitude) else {
            return nil
        }

        self.latitude = latitude
        self.longitude = longitude
    }

    private init(validatedLatitude latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }

    var latitudeDisplay: String {
        latitude.formatted(Self.displayFormat)
    }

    var longitudeDisplay: String {
        longitude.formatted(Self.displayFormat)
    }

    var displayText: String {
        "\(latitudeDisplay), \(longitudeDisplay)"
    }

    static func isValidLatitude(_ value: Double) -> Bool {
        (-90...90).contains(value)
    }

    static func isValidLongitude(_ value: Double) -> Bool {
        (-180...180).contains(value)
    }

    private static let displayFormat = FloatingPointFormatStyle<Double>.number.precision(.fractionLength(6))

    static let berlin = CoordinateSelection(validatedLatitude: 52.520008, longitude: 13.404954)
}
