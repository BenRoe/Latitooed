import SwiftData
import SwiftUI

struct BatchHistorySection: View {
    @Query(sort: \BatchRunSummary.timestamp, order: .reverse)
    private var batchRunSummaries: [BatchRunSummary]

    let onUseCoordinate: (BatchRunSummarySnapshot) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Text("Recent Batches")
                .font(.caption)
                .foregroundStyle(.secondary)

            if snapshots.isEmpty {
                Text("Recent batch summaries will appear after a write completes.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshots.prefix(10)) { snapshot in
                    VStack(alignment: .leading, spacing: AppDesign.Spacing.xs) {
                        Text(rowText(for: snapshot))
                            .font(.caption)
                            .foregroundStyle(.primary)
                            .lineLimit(2)

                        Button("Use Coordinate", systemImage: "mappin.and.ellipse") {
                            onUseCoordinate(snapshot)
                        }
                        .font(.caption)
                    }
                    .padding(AppDesign.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial)
                    .clipShape(.rect(cornerSize: AppDesign.Radius.smallSize))
                }
            }
        }
    }

    private var snapshots: [BatchRunSummarySnapshot] {
        batchRunSummaries.compactMap { summary in
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

    private func rowText(for snapshot: BatchRunSummarySnapshot) -> String {
        "\(snapshot.timestamp.formatted(date: .abbreviated, time: .shortened)) - \(snapshot.coordinateLabel) - \(snapshot.totalFileCount) files - \(snapshot.successCount) updated, \(snapshot.warningCount) warnings, \(snapshot.failureCount) failed."
    }
}
