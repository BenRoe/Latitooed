import SwiftUI

struct WarningSummaryView: View {
    let warnings: [IntakeWarning]

    var body: some View {
        if warnings.isEmpty {
            HStack(spacing: AppDesign.Spacing.md) {
                Label("GPS: Not checked", systemImage: "location.slash")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Label("Latest result: Pending", systemImage: "clock")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                Label("\(warnings.count) \(warnings.count == 1 ? "item" : "items") could not be added", systemImage: "exclamationmark.triangle")
                    .font(.body)
                    .foregroundStyle(.orange)

                ForEach(warnings) { warning in
                    WarningRow(warning: warning)
                }
            }
        }
    }
}

private struct WarningRow: View {
    let warning: IntakeWarning

    var body: some View {
        Label(warning.message, systemImage: "exclamationmark.circle")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .help(warning.message)
            .textSelection(.enabled)
    }
}
