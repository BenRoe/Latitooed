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

    @Test func batchRunSummaryStoresOnlyCompactCountsAndCoordinate() throws {
        let summary = BatchRunSummary(
            timestamp: Date(timeIntervalSinceReferenceDate: 30),
            coordinateLabel: "Berlin",
            latitude: CoordinateSelection.berlin.latitude,
            longitude: CoordinateSelection.berlin.longitude,
            totalFileCount: 12,
            successCount: 9,
            warningCount: 2,
            failureCount: 1
        )

        #expect(summary.coordinateLabel == "Berlin")
        #expect(summary.coordinate == .berlin)
        #expect(summary.totalFileCount == 12)
        #expect(summary.countsText == "9 updated, 2 warnings, 1 failed.")
    }

    @Test func recordingRecentCoordinateSavesValueSnapshot() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let store = BatchHistoryStore(modelContext: context)
        let usedAt = Date(timeIntervalSinceReferenceDate: 10)

        try store.recordRecentCoordinate(label: "Berlin", coordinate: .berlin, lastUsedAt: usedAt)

        let snapshots = try store.recentCoordinates()
        #expect(snapshots.count == 1)
        #expect(snapshots.first?.label == "Berlin")
        #expect(snapshots.first?.coordinate == .berlin)
        #expect(snapshots.first?.lastUsedAt == usedAt)
        #expect(context.hasChanges == false)
    }

    @Test func recordingSameCoordinateUpdatesExistingRow() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let store = BatchHistoryStore(modelContext: context)

        try store.recordRecentCoordinate(
            label: "Berlin",
            coordinate: .berlin,
            lastUsedAt: Date(timeIntervalSinceReferenceDate: 10)
        )
        try store.recordRecentCoordinate(
            label: "Berlin Mitte",
            coordinate: .berlin,
            lastUsedAt: Date(timeIntervalSinceReferenceDate: 20)
        )

        let snapshots = try store.recentCoordinates()
        #expect(snapshots.count == 1)
        #expect(snapshots.first?.label == "Berlin Mitte")
        #expect(snapshots.first?.lastUsedAt == Date(timeIntervalSinceReferenceDate: 20))
    }

    @Test func recordingMoreThanTenCoordinatesPrunesOldestRows() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let store = BatchHistoryStore(modelContext: context)

        for index in 0..<12 {
            let coordinate = try #require(CoordinateSelection(latitude: Double(index), longitude: Double(index)))
            try store.recordRecentCoordinate(
                label: "Coordinate \(index)",
                coordinate: coordinate,
                lastUsedAt: Date(timeIntervalSinceReferenceDate: TimeInterval(index))
            )
        }

        let snapshots = try store.recentCoordinates()
        #expect(snapshots.count == 10)
        #expect(snapshots.map(\.label) == (2..<12).reversed().map { "Coordinate \($0)" })
    }

    @Test func recordingBatchRunInsertsSummaryAndRecentCoordinate() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let store = BatchHistoryStore(modelContext: context)
        let summary = FileIntakeViewModel.MetadataBatchSummary(successCount: 9, warningCount: 2, failureCount: 1)
        let timestamp = Date(timeIntervalSinceReferenceDate: 30)

        try store.recordBatchRun(
            coordinateLabel: "Berlin",
            coordinate: .berlin,
            summary: summary,
            totalFileCount: 12,
            timestamp: timestamp
        )

        let summaries = try store.batchRunSummaries()
        #expect(summaries.count == 1)
        #expect(summaries.first?.coordinateLabel == "Berlin")
        #expect(summaries.first?.coordinate == .berlin)
        #expect(summaries.first?.totalFileCount == 12)
        #expect(summaries.first?.successCount == 9)
        #expect(summaries.first?.warningCount == 2)
        #expect(summaries.first?.failureCount == 1)
        #expect(try store.recentCoordinates().map(\.label) == ["Berlin"])
        #expect(context.hasChanges == false)
    }

    @Test func recordingMoreThanTenBatchRunsPrunesOldestRows() throws {
        let container = try makeInMemoryContainer()
        let context = ModelContext(container)
        let store = BatchHistoryStore(modelContext: context)
        let summary = FileIntakeViewModel.MetadataBatchSummary(successCount: 1, warningCount: 0, failureCount: 0)

        for index in 0..<12 {
            let coordinate = try #require(CoordinateSelection(latitude: Double(index), longitude: Double(index)))
            try store.recordBatchRun(
                coordinateLabel: "Run \(index)",
                coordinate: coordinate,
                summary: summary,
                totalFileCount: 1,
                timestamp: Date(timeIntervalSinceReferenceDate: TimeInterval(index))
            )
        }

        let summaries = try store.batchRunSummaries()
        #expect(summaries.count == 10)
        #expect(summaries.map(\.coordinateLabel) == (2..<12).reversed().map { "Run \($0)" })
    }
}

@MainActor
private func makeInMemoryContainer() throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: RecentCoordinate.self, BatchRunSummary.self, configurations: configuration)
}
