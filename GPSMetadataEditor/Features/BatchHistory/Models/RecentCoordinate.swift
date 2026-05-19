import Foundation
import SwiftData

@Model
final class RecentCoordinate {
    var label: String
    var latitude: Double
    var longitude: Double
    var lastUsedAt: Date

    init(label: String, latitude: Double, longitude: Double, lastUsedAt: Date) {
        self.label = label
        self.latitude = latitude
        self.longitude = longitude
        self.lastUsedAt = lastUsedAt
    }

    var coordinate: CoordinateSelection? {
        CoordinateSelection(latitude: latitude, longitude: longitude)
    }
}
