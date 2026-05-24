import AppKit
import AVFoundation
import SwiftUI

struct SelectedFilesGrid: View {
    let files: [SelectedMediaFile]
    @Binding var selection: Set<SelectedMediaFile.ID>
    let activateFile: (SelectedMediaFile.ID, FileIntakeViewModel.GridSelectionIntent) -> Void

    private let columns = [
        GridItem(.adaptive(minimum: GridCardMetrics.width, maximum: GridCardMetrics.width), spacing: AppDesign.Spacing.md)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppDesign.Spacing.md) {
                ForEach(files) { file in
                    Button {
                        activateFile(file.id, Self.selectionIntent)
                    } label: {
                        SelectedFileGridCard(file: file, isSelected: selection.contains(file.id))
                    }
                    .buttonStyle(.plain)
                    .frame(width: GridCardMetrics.width, height: GridCardMetrics.height)
                }
            }
            .padding(AppDesign.Spacing.md)
        }
        .frame(minHeight: 220)
    }

    private static var selectionIntent: FileIntakeViewModel.GridSelectionIntent {
        let modifierFlags = NSApp.currentEvent?.modifierFlags ?? []

        if modifierFlags.contains(.shift) {
            return FileIntakeViewModel.GridSelectionIntent.range
        } else if modifierFlags.contains(.command) {
            return FileIntakeViewModel.GridSelectionIntent.toggle
        } else {
            return FileIntakeViewModel.GridSelectionIntent.replace
        }
    }
}

private struct SelectedFileGridCard: View {
    let file: SelectedMediaFile
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            FilePreview(file: file)

            Text(file.displayName)
                .font(.body)
                .lineLimit(2)
                .frame(height: 48, alignment: .topLeading)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(file.displayName)

            StatusLabel(title: file.gpsStatus.displayName, systemImage: file.gpsStatus.systemImage)
            StatusLabel(title: file.latestResult.displayName, systemImage: file.latestResult.systemImage)

            Label("Selected", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.tint)
                .opacity(isSelected ? 1 : 0)
        }
        .padding(AppDesign.Spacing.md)
        .frame(width: GridCardMetrics.width, height: GridCardMetrics.height, alignment: .topLeading)
        .background {
            if isSelected {
                Color.accentColor.opacity(0.12)
            } else {
                Rectangle()
                    .fill(.regularMaterial)
            }
        }
        .overlay {
            if isSelected {
                RoundedRectangle(cornerSize: AppDesign.Radius.smallSize)
                    .stroke(.tint, lineWidth: 2)
            } else {
                RoundedRectangle(cornerSize: AppDesign.Radius.smallSize)
                    .stroke(.quaternary, lineWidth: 1)
            }
        }
        .clipShape(.rect(cornerSize: AppDesign.Radius.smallSize))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        "\(file.displayName), file type \(file.kind.displayName), GPS status \(file.gpsStatus.displayName), latest result \(file.latestResult.displayName), \(isSelected ? "selected" : "not selected")"
    }
}

private struct FilePreview: View {
    let file: SelectedMediaFile
    @State private var previewImage: NSImage?

    var body: some View {
        ZStack {
            FilePreviewFallback(kind: file.kind)

            if let previewImage {
                Image(nsImage: previewImage)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(height: GridCardMetrics.previewHeight)
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerSize: AppDesign.Radius.smallSize))
        .task(id: file.url) {
            previewImage = file.previewImage
        }
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
    }
}

private enum GridCardMetrics {
    static let width: CGFloat = 220
    static let height: CGFloat = 300
    static let previewHeight: CGFloat = 150
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

private extension SelectedMediaFile {
    var previewImage: NSImage? {
        switch kind {
        case .jpeg, .heic:
            NSImage(contentsOf: url)
        case .mov, .mp4:
            videoPreviewImage
        }
    }

    var videoPreviewImage: NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true

        do {
            let image = try generator.copyCGImage(at: CMTime(seconds: 0, preferredTimescale: 600), actualTime: nil)
            return NSImage(cgImage: image, size: .zero)
        } catch {
            return nil
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
