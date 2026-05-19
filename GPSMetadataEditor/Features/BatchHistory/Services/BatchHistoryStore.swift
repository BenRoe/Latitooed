import Foundation
import SwiftData

nonisolated struct RecentCoordinateSnapshot: Equatable, Identifiable, Sendable {
    let id: PersistentIdentifier
    let label: String
    let coordinate: CoordinateSelection
    let lastUsedAt: Date
}

@MainActor
final class BatchHistoryStore {
    private let modelContext: ModelContext
    private let recentCoordinateLimit: Int

    init(modelContext: ModelContext, recentCoordinateLimit: Int = 10) {
        self.modelContext = modelContext
        self.recentCoordinateLimit = recentCoordinateLimit
    }

    func recordRecentCoordinate(
        label: String,
        coordinate: CoordinateSelection,
        lastUsedAt: Date = Date()
    ) throws {
        let recentCoordinate = try existingRecentCoordinate(for: coordinate) ?? RecentCoordinate(
            label: label,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            lastUsedAt: lastUsedAt
        )

        recentCoordinate.label = label
        recentCoordinate.latitude = coordinate.latitude
        recentCoordinate.longitude = coordinate.longitude
        recentCoordinate.lastUsedAt = lastUsedAt

        if recentCoordinate.modelContext == nil {
            modelContext.insert(recentCoordinate)
        }

        try pruneRecentCoordinates()

        if modelContext.hasChanges {
            try modelContext.save()
        }
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

    private func existingRecentCoordinate(for coordinate: CoordinateSelection) throws -> RecentCoordinate? {
        try fetchRecentCoordinates().first {
            $0.latitude == coordinate.latitude && $0.longitude == coordinate.longitude
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

    private func fetchRecentCoordinates() throws -> [RecentCoordinate] {
        let descriptor = FetchDescriptor<RecentCoordinate>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
}
