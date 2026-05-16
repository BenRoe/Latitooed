import Observation
import SwiftUI

struct FileDropZone: View {
    enum Mode {
        case large
        case compact
    }

    let mode: Mode

    @Bindable var viewModel: FileIntakeViewModel

    var body: some View {
        switch mode {
        case .large:
            LargeDropZone(viewModel: viewModel)
        case .compact:
            CompactDropStrip(viewModel: viewModel)
        }
    }
}

private struct LargeDropZone: View {
    @Bindable var viewModel: FileIntakeViewModel

    var body: some View {
        VStack(spacing: AppDesign.Spacing.lg) {
            Image(systemName: "photo.stack")
                .imageScale(.large)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.tint)
                .accessibilityHidden(true)

            VStack(spacing: AppDesign.Spacing.sm) {
                Text("Drop media files here")
                    .font(.title2)
                    .bold()

                Text("Add JPEG, HEIC, MOV, or MP4 files to review them before choosing a location.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .textSelection(.enabled)
            }

            Button("Add Files", systemImage: "plus", action: viewModel.presentFileImporter)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(minHeight: AppDesign.Layout.minimumControlHeight)
        }
        .frame(maxWidth: .infinity, minHeight: AppDesign.Layout.dropZoneMinimumHeight)
        .padding(AppDesign.Spacing.xl)
        .background(.background)
        .fileDropTarget(viewModel: viewModel, cornerSize: AppDesign.Radius.largeSize)
        .accessibilityElement(children: .combine)
    }
}

private struct CompactDropStrip: View {
    @Bindable var viewModel: FileIntakeViewModel

    var body: some View {
        HStack(spacing: AppDesign.Spacing.md) {
            Label("Drop more files here or add files from Finder.", systemImage: "tray.and.arrow.down")
                .font(.body)
                .foregroundStyle(.secondary)

            Spacer()

            Button("Add Files", systemImage: "plus", action: viewModel.presentFileImporter)
                .buttonStyle(.borderedProminent)
                .frame(minHeight: AppDesign.Layout.minimumControlHeight)
        }
        .padding(AppDesign.Spacing.md)
        .background(.background)
        .fileDropTarget(viewModel: viewModel, cornerSize: AppDesign.Radius.mediumSize)
    }
}

private struct FileDropTargetModifier: ViewModifier {
    @Bindable var viewModel: FileIntakeViewModel
    let cornerSize: CGSize

    func body(content: Content) -> some View {
        content
            .overlay {
                RoundedRectangle(cornerSize: cornerSize)
                    .strokeBorder(
                        viewModel.isDropTargeted ? .tint : .quaternary,
                        style: StrokeStyle(
                            lineWidth: viewModel.isDropTargeted ? 2 : 1,
                            dash: viewModel.isDropTargeted ? [] : [8, 6]
                        )
                    )
            }
            .clipShape(.rect(cornerSize: cornerSize))
            .dropDestination(for: URL.self) { urls, _ in
                viewModel.intake(urls: urls, source: .drop)
                return true
            } isTargeted: { isTargeted in
                viewModel.isDropTargeted = isTargeted
            }
    }
}

private extension View {
    func fileDropTarget(viewModel: FileIntakeViewModel, cornerSize: CGSize) -> some View {
        modifier(FileDropTargetModifier(viewModel: viewModel, cornerSize: cornerSize))
    }
}
