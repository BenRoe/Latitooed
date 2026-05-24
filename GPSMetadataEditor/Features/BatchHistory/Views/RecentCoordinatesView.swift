import SwiftData
import SwiftUI

struct RecentCoordinatesView: View {
    @Query(sort: \RecentCoordinate.lastUsedAt, order: .reverse)
    private var recentCoordinates: [RecentCoordinate]

    let onSelect: (RecentCoordinateSnapshot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Text("Recent Coordinates")
                .font(.caption)
                .foregroundStyle(.secondary)

            if snapshots.isEmpty {
                Text("Recent coordinates will appear after you apply a location.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(snapshots) { snapshot in
                            Button {
                                onSelect(snapshot)
                            } label: {
                                RecentCoordinateRow(snapshot: snapshot)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Use Coordinate, \(snapshot.label)")
                        }
                    }
                }
                .frame(height: RecentCoordinateMetrics.listHeight(for: snapshots.count))
            }
        }
    }

    private var snapshots: [RecentCoordinateSnapshot] {
        recentCoordinates.compactMap { recentCoordinate in
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
}

private enum RecentCoordinateMetrics {
    static let rowHeight: CGFloat = 38

    static func listHeight(for rowCount: Int) -> CGFloat {
        let visibleRowCount = min(rowCount, 3)
        let spacingCount = max(visibleRowCount - 1, 0)
        return rowHeight * CGFloat(visibleRowCount) + CGFloat(spacingCount)
    }
}

private struct RecentCoordinateRow: View {
    let snapshot: RecentCoordinateSnapshot

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Image(systemName: "clock.arrow.circlepath")
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
                Text(snapshot.label)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .help(snapshot.label)
            }

            Spacer()

            Label("Use Coordinate", systemImage: "mappin.and.ellipse")
                .font(.caption)
        }
        .padding(.horizontal, AppDesign.Spacing.sm)
        .padding(.vertical, 2)
        .frame(height: RecentCoordinateMetrics.rowHeight)
        .contentShape(.rect)
    }
}
