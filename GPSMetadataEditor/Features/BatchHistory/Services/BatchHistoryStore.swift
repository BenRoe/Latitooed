import Foundation
import SwiftData

nonisolated struct RecentCoordinateSnapshot: Equatable, Identifiable, Sendable {
    let id: PersistentIdentifier
    let label: String
    let coordinate: CoordinateSelection
    let lastUsedAt: Date
}

nonisolated struct BatchRunSummarySnapshot: Equatable, Identifiable, Sendable {
    let id: PersistentIdentifier
    let timestamp: Date
    let coordinateLabel: String
    let coordinate: CoordinateSelection
    let totalFileCount: Int
    let successCount: Int
    let warningCount: Int
    let failureCount: Int
}

@MainActor
final class BatchHistoryStore {
    private let modelContext: ModelContext
    private let recentCoordinateLimit: Int
    private let batchSummaryLimit: Int

    init(modelContext: ModelContext, recentCoordinateLimit: Int = 30, batchSummaryLimit: Int = 10) {
        self.modelContext = modelContext
        self.recentCoordinateLimit = recentCoordinateLimit
        self.batchSummaryLimit = batchSummaryLimit
    }

    func recordRecentCoordinate(
        label: String,
        coordinate: CoordinateSelection,
        lastUsedAt: Date = Date()
    ) throws {
        let coord = RecentCoordinate(
            label: label,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            lastUsedAt: lastUsedAt
        )
        modelContext.insert(coord)
        // Set mutable fields after insert so SwiftData carries them on #Unique merge.
        coord.label = label
        coord.lastUsedAt = lastUsedAt
        try pruneRecentCoordinates()
        try modelContext.save()
    }

    func recentCoordinates() throws -> [RecentCoordinateSnapshot] {
        try fetchRecentCoordinates().compactMap { recentCoordinate in
            guard let coordinate = recentCoordinate.coordinate else {
                return nil
            }

            return RecentCoordinateSnapshot(
                id: recentCoordinate.persistentModelID,
                label: recentCoordinate.label,
                coordinate: coordinate,
                lastUsedAt: recentCoordinate.lastUsedAt
            )
        }
    }

    func recordBatchRun(
        coordinateLabel: String,
        coordinate: CoordinateSelection,
        summary: FileIntakeViewModel.MetadataBatchSummary,
        totalFileCount: Int,
        timestamp: Date = Date()
    ) throws {
        try recordRecentCoordinate(label: coordinateLabel, coordinate: coordinate, lastUsedAt: timestamp)

        modelContext.insert(BatchRunSummary(
            timestamp: timestamp,
            coordinateLabel: coordinateLabel,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            totalFileCount: totalFileCount,
            successCount: summary.successCount,
            warningCount: summary.warningCount,
            failureCount: summary.failureCount
        ))

        try pruneBatchRunSummaries()

        try modelContext.save()
    }

    func batchRunSummaries() throws -> [BatchRunSummarySnapshot] {
        try fetchBatchRunSummaries().compactMap { summary in
            guard let coordinate = summary.coordinate else {
                return nil
            }

            return BatchRunSummarySnapshot(
                id: summary.persistentModelID,
                timestamp: summary.timestamp,
                coordinateLabel: summary.coordinateLabel,
                coordinate: coordinate,
                totalFileCount: summary.totalFileCount,
                successCount: summary.successCount,
                warningCount: summary.warningCount,
                failureCount: summary.failureCount
            )
        }
    }

    private func pruneRecentCoordinates() throws {
        let recentCoordinates = try fetchRecentCoordinates()
        guard recentCoordinates.count > recentCoordinateLimit else {
            return
        }

        for recentCoordinate in recentCoordinates.dropFirst(recentCoordinateLimit) {
            modelContext.delete(recentCoordinate)
        }
    }

    private func pruneBatchRunSummaries() throws {
        let summaries = try fetchBatchRunSummaries()
        guard summaries.count > batchSummaryLimit else {
            return
        }

        for summary in summaries.dropFirst(batchSummaryLimit) {
            modelContext.delete(summary)
        }
    }

    private func fetchRecentCoordinates() throws -> [RecentCoordinate] {
        let descriptor = FetchDescriptor<RecentCoordinate>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }

    private func fetchBatchRunSummaries() throws -> [BatchRunSummary] {
        let descriptor = FetchDescriptor<BatchRunSummary>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
