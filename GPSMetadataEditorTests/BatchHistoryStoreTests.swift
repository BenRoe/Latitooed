import SwiftData
import Testing
@testable import GPSMetadataEditor

@MainActor
struct BatchHistoryStoreTests {
    @Test func recentCoordinateStoresOnlyCompactCoordinateFields() throws {
        let coordinate = CoordinateSelection.berlin
        let recent = RecentCoordinate(
            label: "Berlin",
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            lastUsedAt: Date(timeIntervalSinceReferenceDate: 0)
        )

        #expect(recent.label == "Berlin")
        #expect(recent.latitude == coordinate.latitude)
        #expect(recent.longitude == coordinate.longitude)
        #expect(recent.coordinate == coordinate)
    }

    @Test func inMemoryContainerAcceptsRecentCoordinateModel() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let recent = RecentCoordinate(
            label: "Berlin",
            latitude: CoordinateSelection.berlin.latitude,
            longitude: CoordinateSelection.berlin.longitude,
            lastUsedAt: Date(timeIntervalSinceReferenceDate: 0)
        )

        context.insert(recent)
        try context.save()

        let results = try context.fetch(FetchDescriptor<RecentCoordinate>())
        #expect(results.map(\.label) == ["Berlin"])
    }
}

@MainActor
private func makeInMemoryContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: RecentCoordinate.self, configurations: configuration)
}
