import Foundation
import SwiftData

@Model
final class RecentCoordinate {
    #Unique<RecentCoordinate>([\.latitude, \.longitude])
    #Index<RecentCoordinate>([\.lastUsedAt])
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

    // Warning: Do not use this computed property inside #Predicate expressions —
    // SwiftData's predicate compiler does not support arbitrary computed properties
    // and will crash at runtime.
    var coordinate: CoordinateSelection? {
        CoordinateSelection(latitude: latitude, longitude: longitude)
    }
}
