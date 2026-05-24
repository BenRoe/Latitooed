import SwiftUI

struct WarningSummaryView: View {
    let warnings: [IntakeWarning]

    var body: some View {
        if warnings.isEmpty == false {
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
