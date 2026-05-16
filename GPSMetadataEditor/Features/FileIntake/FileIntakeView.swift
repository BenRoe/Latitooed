import Observation
import SwiftUI
import UniformTypeIdentifiers

struct FileIntakeView: View {
    @State private var viewModel = FileIntakeViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                    if viewModel.selectedFiles.isEmpty {
                        FileIntakeEmptyDropZone(viewModel: viewModel)
                    } else {
                        FileIntakeCompactDropStrip(viewModel: viewModel)
                    }

                    VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                        HStack {
                            Text("Selected Files")
                                .font(.headline)
                                .bold()

                            Spacer()

                            Text("\(viewModel.selectedFiles.count) \(viewModel.selectedFiles.count == 1 ? "file" : "files")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        FileIntakeTable(viewModel: viewModel)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppDesign.Spacing.md)
                        .background(.background)
                        .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))

                        FileIntakeDetailPanel(viewModel: viewModel)
                    }
                }
                .frame(minWidth: AppDesign.Layout.leftColumnMinimumWidth, idealWidth: AppDesign.Layout.leftColumnIdealWidth)
                .padding(AppDesign.Spacing.lg)

                VStack(spacing: AppDesign.Spacing.md) {
                    Spacer()

                    Image(systemName: "location.slash")
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)

                    VStack(spacing: AppDesign.Spacing.sm) {
                        Text("Location selection comes next")
                            .font(.headline)
                            .bold()

                        Text("Phase 1 is focused on building a reliable file set.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .textSelection(.enabled)
                    }

                    Spacer()
                }
                .frame(minWidth: AppDesign.Layout.rightColumnMinimumWidth, maxWidth: .infinity, maxHeight: .infinity)
                .padding(AppDesign.Spacing.xl)
                .background(.background)
            }

            Divider()

            HStack(spacing: AppDesign.Spacing.sm) {
                Label(viewModel.latestNotice?.message ?? "Ready", systemImage: viewModel.latestNotice?.style == .warning ? "exclamationmark.triangle" : "tray")
                    .font(.caption)
                    .foregroundStyle(viewModel.latestNotice?.style == .warning ? .orange : .secondary)

                Spacer()

                Text(viewModel.selectedFiles.isEmpty ? "Add files to start the intake review." : "Review selected files before choosing a location.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(height: AppDesign.Layout.footerHeight)
            .padding(.horizontal, AppDesign.Spacing.lg)
        }
        .frame(minWidth: AppDesign.Layout.minimumWindowWidth, minHeight: AppDesign.Layout.minimumWindowHeight)
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: Self.allowedContentTypes,
            allowsMultipleSelection: true,
            onCompletion: handleFileImport
        )
    }

    private func handleFileImport(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            viewModel.intake(urls: urls, source: .picker)
        case .failure(let error):
            viewModel.reportPickerFailure(error)
        }
    }

    private static let allowedContentTypes: [UTType] = [
        .jpeg,
        .heic,
        .quickTimeMovie,
        .mpeg4Movie,
    ]
}

private struct FileIntakeEmptyDropZone: View {
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

            Text("Drop more files here or add files from Finder.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: AppDesign.Layout.dropZoneMinimumHeight)
        .padding(AppDesign.Spacing.xl)
        .background(.background)
        .fileDropTarget(viewModel: viewModel, cornerSize: AppDesign.Radius.largeSize)
        .accessibilityElement(children: .combine)
    }
}

private struct FileIntakeCompactDropStrip: View {
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

private struct FileIntakeTable: View {
    @Bindable var viewModel: FileIntakeViewModel

    var body: some View {
        if viewModel.selectedFiles.isEmpty {
            Text("No files selected")
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
        } else {
            Table(viewModel.selectedFiles, selection: $viewModel.selectedFileID) {
                TableColumn("Display Name") { file in
                    Text(file.displayName)
                        .lineLimit(1)
                        .help(file.displayName)
                }

                TableColumn("Type") { file in
                    Text(file.kind.displayName)
                        .font(.caption)
                        .padding(.horizontal, AppDesign.Spacing.sm)
                        .padding(.vertical, AppDesign.Spacing.xs)
                        .background(.quaternary)
                        .clipShape(.rect(cornerSize: AppDesign.Radius.smallSize))
                }
                .width(min: 72, ideal: 80, max: 96)

                TableColumn("GPS") { file in
                    Label(file.gpsStatus.displayName, systemImage: "location.slash")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.secondary)
                }
                .width(min: 116, ideal: 128, max: 144)

                TableColumn("Latest Result") { file in
                    Label(file.latestResult.displayName, systemImage: "clock")
                        .labelStyle(.titleAndIcon)
                        .foregroundStyle(.secondary)
                }
                .width(min: 120, ideal: 136, max: 160)
            }
            .frame(minHeight: 220)
        }
    }
}

private struct FileIntakeDetailPanel: View {
    @Bindable var viewModel: FileIntakeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
            if let detail = viewModel.selectedFileDetail {
                VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
                    Label(detail.filename, systemImage: "doc")
                        .font(.body)

                    Text("Folder: \(detail.containingFolderName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .help(detail.containingFolderURL.path())
                }
            } else {
                Label("Ready for supported media files", systemImage: "checkmark.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            if viewModel.latestWarningDetails.isEmpty == false {
                FileIntakeWarningList(warnings: viewModel.latestWarningDetails)
            } else {
                HStack(spacing: AppDesign.Spacing.md) {
                    Text("Not checked")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("Pending")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppDesign.Spacing.md)
        .background(.background)
        .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))
    }
}

private struct FileIntakeWarningList: View {
    let warnings: [IntakeWarning]

    var body: some View {
        VStack(alignment: .leading, spacing: AppDesign.Spacing.sm) {
            Label("\(warnings.count) \(warnings.count == 1 ? "item" : "items") could not be added", systemImage: "exclamationmark.triangle")
                .font(.body)
                .foregroundStyle(.orange)

            ForEach(warnings) { warning in
                Text(warning.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
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

#Preview {
    FileIntakeView()
}
