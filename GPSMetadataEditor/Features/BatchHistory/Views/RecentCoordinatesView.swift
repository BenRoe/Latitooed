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

                Text(snapshot.coordinate.displayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Label("Use Coordinate", systemImage: "mappin.and.ellipse")
                .font(.caption)
        }
        .padding(AppDesign.Spacing.sm)
        .contentShape(.rect)
    }
}
