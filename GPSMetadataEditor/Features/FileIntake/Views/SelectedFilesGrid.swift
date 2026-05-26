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
                    .frame(width: GridCardMetrics.width)
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
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(file.displayName)

            StatusLabel(title: file.gpsStatus.displayName, systemImage: file.gpsStatus.systemImage)
        }
        .padding(AppDesign.Spacing.md)
        .frame(width: GridCardMetrics.width, alignment: .topLeading)
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
        .overlay(alignment: .topTrailing) {
            WriteResultMarker(status: file.latestResult)
                .padding(AppDesign.Spacing.sm)
        }
        .clipShape(.rect(cornerSize: AppDesign.Radius.smallSize))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        var parts = [
            file.displayName,
            "file type \(file.kind.displayName)",
            "GPS status \(file.gpsStatus.displayName)",
            isSelected ? "selected" : "not selected",
        ]

        if let accessibilityDescription = file.latestResult.accessibilityDescription {
            parts.insert(accessibilityDescription, at: 3)
        }

        return parts.joined(separator: ", ")
    }
}

private struct WriteResultMarker: View {
    let status: FileResultStatus

    var body: some View {
        if let marker = status.cardMarker {
            Image(systemName: marker.systemImage)
                .font(.caption)
                .bold()
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(marker.background)
                .clipShape(.circle)
                .accessibilityLabel(marker.accessibilityLabel)
        }
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
            previewImage = await file.previewImage
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
        get async {
            switch kind {
            case .jpeg, .heic:
                NSImage(contentsOf: url)
            case .mov, .mp4:
                await loadVideoThumbnail(for: url)
            }
        }
    }
}

private func loadVideoThumbnail(for url: URL) async -> NSImage? {
    let asset = AVURLAsset(url: url)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    guard let (cgImage, _) = try? await generator.image(at: .zero) else { return nil }
    return NSImage(cgImage: cgImage, size: .zero)
}

private extension FileResultStatus {
    var cardMarker: (systemImage: String, background: Color, accessibilityLabel: String)? {
        switch self {
        case .success:
            ("checkmark", .green, "Location write succeeded")
        case .failure:
            ("xmark", .red, "Location write failed")
        case .pending, .warning:
            nil
        }
    }

    var accessibilityDescription: String? {
        switch self {
        case .success:
            "location write succeeded"
        case .failure:
            "location write failed"
        case .warning:
            "location write warning"
        case .pending:
            nil
        }
    }
}
