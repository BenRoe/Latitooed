import SwiftUI

struct SelectedFilesGrid: View {
    let files: [SelectedMediaFile]
    @Binding var selection: Set<SelectedMediaFile.ID>

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 220), spacing: AppDesign.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppDesign.Spacing.md) {
                ForEach(files) { file in
                    Button {
                        selection = [file.id]
                    } label: {
                        SelectedFileGridCard(file: file, isSelected: selection.contains(file.id))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(AppDesign.Spacing.md)
        }
        .frame(minHeight: 220)
    }
}

private struct SelectedFileGridCard: View {
    let file: SelectedMediaFile
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            FilePreviewFallback(kind: file.kind)

            Text(file.displayName)
                .font(.body)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(file.displayName)

            Text(file.kind.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)

            StatusLabel(title: file.gpsStatus.displayName, systemImage: file.gpsStatus.systemImage)
            StatusLabel(title: file.latestResult.displayName, systemImage: file.latestResult.systemImage)

            if isSelected {
                Label("Selected", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.tint)
            }
        }
        .padding(AppDesign.Spacing.md)
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .topLeading)
        .background(isSelected ? .tint.opacity(0.12) : .regularMaterial)
        .overlay {
            RoundedRectangle(cornerSize: AppDesign.Radius.smallSize)
                .stroke(isSelected ? .tint : .quaternary, lineWidth: isSelected ? 2 : 1)
        }
        .clipShape(.rect(cornerSize: AppDesign.Radius.smallSize))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        "\(file.displayName), file type \(file.kind.displayName), GPS status \(file.gpsStatus.displayName), latest result \(file.latestResult.displayName), \(isSelected ? "selected" : "not selected")"
    }
}

private struct FilePreviewFallback: View {
    let kind: MediaFileKind

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.quaternary)

            Image(systemName: kind.fallbackSystemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
        }
        .aspectRatio(4.0 / 3.0, contentMode: .fit)
        .clipShape(.rect(cornerSize: AppDesign.Radius.smallSize))
    }
}

private struct StatusLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

private extension MediaFileKind {
    var fallbackSystemImage: String {
        switch self {
        case .jpeg, .heic:
            "photo"
        case .mov, .mp4:
            "film"
        }
    }
}

private extension GPSStatus {
    var systemImage: String {
        switch self {
        case .notChecked:
            "location.slash"
        case .notPresent:
            "location.slash"
        case .present:
            "location"
        case .updated:
            "location.fill"
        }
    }
}

private extension FileResultStatus {
    var systemImage: String {
        switch self {
        case .pending:
            "clock"
        case .success:
            "checkmark.circle"
        case .warning:
            "exclamationmark.triangle"
        case .failure:
            "xmark.circle"
        }
    }
}
