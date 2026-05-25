import SwiftUI

struct FileDetailPanel: View {
    let review: FileIntakeViewModel.SelectedFileReview
    let latestWarnings: [IntakeWarning]
    @State private var isExpanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            Button(action: toggleExpanded) {
                HStack(spacing: AppDesign.Spacing.sm) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label("Details", systemImage: "info.circle")
                        .font(.body)
                        .bold()

                    Spacer()
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isExpanded ? "Collapse details" : "Expand details")

            if isExpanded {
                SelectedFileReviewContent(review: review)
                WarningSummaryView(warnings: latestWarnings)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, AppDesign.Spacing.md)
        .padding(.vertical, 5)
        .background(.background)
        .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))
    }

    private func toggleExpanded() {
        isExpanded.toggle()
    }
}

private struct SelectedFileReviewContent: View {
    let review: FileIntakeViewModel.SelectedFileReview

    var body: some View {
        switch review {
        case .none:
            Label("Select a file to review details", systemImage: "sidebar.left")
                .font(.body)
                .foregroundStyle(.secondary)
        case .single(let detail):
            VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                Label(detail.filename, systemImage: "doc")
                    .font(.body)
                    .lineLimit(1)
                    .help(detail.filename)

                Text("Path: \(detail.fileURL.path())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(detail.fileURL.path())

                Label("GPS: \(detail.gpsStatus.displayName)", systemImage: detail.gpsStatus.systemImage)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if detail.latestResult.isVisibleInDetail {
                    Label("Latest result: \(detail.latestResult.displayName)", systemImage: detail.latestResult.systemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let latestMessage = detail.latestMessage {
                    Text(latestMessage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

                if detail.latestResult.supportsDiagnosticReview,
                   let latestDiagnosticDetail = detail.latestDiagnosticDetail,
                   latestDiagnosticDetail.isEmpty == false {
                    DisclosureGroup("Diagnostics") {
                        Text(latestDiagnosticDetail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .font(.caption)
                }
            }
        case .multiple(let summary):
            SelectedFilesSummaryContent(summary: summary)
        }
    }
}

private struct SelectedFilesSummaryContent: View {
    let summary: FileIntakeViewModel.SelectedFilesSummary

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Label("\(summary.selectedCount) files selected", systemImage: "checkmark.circle")
                .font(.body)

            CountSummary(title: "Types", counts: summary.fileTypeCounts, label: \.displayName)
            CountSummary(title: "Latest results", counts: visibleLatestResultCounts, label: \.displayName)
        }
    }

    private var visibleLatestResultCounts: [FileResultStatus: Int] {
        summary.latestResultCounts.filter { status, _ in status.isVisibleInDetail }
    }
}

private struct CountSummary<Value: Hashable>: View {
    let title: String
    let counts: [Value: Int]
    let label: (Value) -> String

    var body: some View {
        if counts.isEmpty == false {
            Text("\(title): \(summaryText)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var summaryText: String {
        counts
            .map { value, count in "\(label(value)) \(count)" }
            .sorted()
            .joined(separator: ", ")
    }
}

private extension FileResultStatus {
    var isVisibleInDetail: Bool {
        switch self {
        case .success, .warning, .failure:
            true
        case .pending:
            false
        }
    }

    var supportsDiagnosticReview: Bool {
        switch self {
        case .warning, .failure:
            true
        case .pending, .success:
            false
        }
    }
}
