import SwiftUI

struct FileDetailPanel: View {
    let detail: FileIntakeViewModel.SelectedFileDetail?
    let latestWarnings: [IntakeWarning]

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            SelectedFileDetailContent(detail: detail)
            WarningSummaryView(warnings: latestWarnings)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppDesign.Spacing.md)
        .background(.background)
        .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))
    }
}

private struct SelectedFileDetailContent: View {
    let detail: FileIntakeViewModel.SelectedFileDetail?

    var body: some View {
        if let detail {
            VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                Label(detail.filename, systemImage: "doc")
                    .font(.body)
                    .lineLimit(1)
                    .help(detail.filename)

                Text("Folder: \(detail.containingFolderName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(detail.containingFolderURL.path())

                Text("Access will be checked again before metadata changes in a later phase.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } else {
            Label("Select a row to review file details", systemImage: "sidebar.left")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }
}
