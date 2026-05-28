import AppKit
import AVFoundation
import SwiftUI

enum ThumbnailSize: String, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var width: CGFloat {
        switch self {
        case .small: 140
        case .medium: 220
        case .large: 300
        }
    }

    var previewHeight: CGFloat {
        switch self {
        case .small: 90
        case .medium: 150
        case .large: 200
        }
    }

    var displayName: String {
        switch self {
        case .small: "Small"
        case .medium: "Medium"
        case .large: "Large"
        }
    }
}

struct SelectedFilesGrid: View {
    let files: [SelectedMediaFile]
    @Binding var selection: Set<SelectedMediaFile.ID>
    let activateFile: (SelectedMediaFile.ID, FileIntakeViewModel.GridSelectionIntent) -> Void
    let thumbnailSize: ThumbnailSize

    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: thumbnailSize.width, maximum: thumbnailSize.width), spacing: AppDesign.Spacing.md)]
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppDesign.Spacing.md) {
                ForEach(files) { file in
                    Button {
                        activateFile(file.id, Self.selectionIntent)
                    } label: {
                        SelectedFileGridCard(file: file, isSelected: selection.contains(file.id), thumbnailSize: thumbnailSize)
                    }
                    .buttonStyle(.plain)
                    .frame(width: thumbnailSize.width)
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
    let thumbnailSize: ThumbnailSize

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            FilePreview(file: file, thumbnailSize: thumbnailSize)

            Text(file.displayName)
                .font(.body)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(file.displayName)

            StatusLabel(title: file.gpsStatus.displayName, systemImage: file.gpsStatus.systemImage)
        }
        .padding(AppDesign.Spacing.md)
        .frame(width: thumbnailSize.width, alignment: .topLeading)
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
                RoundedRectangle(cornerRadius: AppDesign.Radius.small)
                    .stroke(.tint, lineWidth: 2)
            } else {
                RoundedRectangle(cornerRadius: AppDesign.Radius.small)
                    .stroke(.quaternary, lineWidth: 1)
            }
        }
        .overlay(alignment: .topTrailing) {
            WriteResultMarker(status: file.latestResult)
                .padding(AppDesign.Spacing.sm)
        }
        .clipShape(.rect(cornerRadius: AppDesign.Radius.small))
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
    let thumbnailSize: ThumbnailSize
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
        .frame(height: thumbnailSize.previewHeight)
        .frame(maxWidth: .infinity)
        .clipShape(.rect(cornerRadius: AppDesign.Radius.small))
        .task(id: file.url) {
            let maximumSize = NSSize(width: thumbnailSize.width, height: thumbnailSize.previewHeight)
            previewImage = await file.previewImage(maximumSize: maximumSize)
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
    // URLs are stable per session — task(id: file.url) fires once per unique file.
    func previewImage(maximumSize: NSSize) async -> NSImage? {
        switch kind {
        case .jpeg, .heic:
            await Task.detached(priority: .utility) { NSImage(contentsOf: url) }.value
        case .mov, .mp4:
            await loadVideoThumbnail(for: url, maximumSize: maximumSize)
        }
    }
}

private func loadVideoThumbnail(for url: URL, maximumSize: NSSize) async -> NSImage? {
    let asset = AVURLAsset(url: url)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    let scale = await MainActor.run { NSScreen.main?.backingScaleFactor ?? 2.0 }
    generator.maximumSize = NSSize(
        width: maximumSize.width * scale,
        height: maximumSize.height * scale
    )
    guard let (cgImage, _) = try? await generator.image(at: .zero) else { return nil }
    return NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
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
