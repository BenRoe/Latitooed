import Foundation
import SwiftData

@Model
final class BatchRunSummary {
    var timestamp: Date
    var coordinateLabel: String
    var latitude: Double
    var longitude: Double
    var totalFileCount: Int
    var successCount: Int
    var warningCount: Int
    var failureCount: Int

    init(
        timestamp: Date,
        coordinateLabel: String,
        latitude: Double,
        longitude: Double,
        totalFileCount: Int,
        successCount: Int,
        warningCount: Int,
        failureCount: Int
    ) {
        self.timestamp = timestamp
        self.coordinateLabel = coordinateLabel
        self.latitude = latitude
        self.longitude = longitude
        self.totalFileCount = totalFileCount
        self.successCount = successCount
        self.warningCount = warningCount
        self.failureCount = failureCount
    }

    var coordinate: CoordinateSelection? {
        CoordinateSelection(latitude: latitude, longitude: longitude)
    }

    var countsText: String {
        "\(successCount) updated, \(warningCount) warnings, \(failureCount) failed."
    }
}
