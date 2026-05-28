import Observation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct FileIntakeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FileIntakeViewModel()
    @State private var coordinateViewModel = CoordinateSelectionViewModel()
    @State private var isOverwriteConfirmationPresented = false
    @State private var leftPanelWidth: CGFloat = AppDesign.Layout.leftColumnIdealWidth
    @State private var totalWidth: CGFloat = AppDesign.Layout.minimumWindowWidth
    @AppStorage("thumbnailSize") private var thumbnailSize: ThumbnailSize = .medium

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                        if viewModel.selectedFiles.isEmpty {
                            FileDropZone(mode: .large, viewModel: viewModel)
                        } else {
                            FileDropZone(mode: .compact, viewModel: viewModel)
                        }

                        if viewModel.selectedFiles.isEmpty == false {
                            VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                                HStack {
                                    Text("Loaded Files")
                                        .font(.headline)
                                        .bold()

                                    Spacer()

                                    Picker("Loaded files view", selection: $viewModel.selectedLoadedFilesViewMode) {
                                        ForEach(FileIntakeViewModel.LoadedFilesViewMode.allCases) { mode in
                                            Text(mode.displayName)
                                                .tag(mode)
                                        }
                                    }
                                    .labelsHidden()
                                    .pickerStyle(.segmented)
                                    .frame(maxWidth: 180)

                                    if viewModel.selectedLoadedFilesViewMode == .grid {
                                        Picker("Thumbnail size", selection: $thumbnailSize) {
                                            ForEach(ThumbnailSize.allCases) { size in
                                                Text(size.displayName).tag(size)
                                            }
                                        }
                                        .labelsHidden()
                                        .pickerStyle(.segmented)
                                        .frame(maxWidth: 180)
                                    }
                                }

                                switch viewModel.selectedLoadedFilesViewMode {
                                case .table:
                                    SelectedFilesTable(
                                        files: viewModel.selectedFiles,
                                        selection: $viewModel.selectedFileIDs
                                    )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(AppDesign.Spacing.md)
                                    .background(.background)
                                    .clipShape(.rect(cornerRadius: AppDesign.Radius.medium))
                                case .grid:
                                SelectedFilesGrid(
                                    files: viewModel.selectedFiles,
                                    selection: $viewModel.selectedFileIDs,
                                    activateFile: activateLoadedFile,
                                    thumbnailSize: thumbnailSize
                                )
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.background)
                                    .clipShape(.rect(cornerRadius: AppDesign.Radius.medium))
                                }

                                FileDetailPanel(
                                    review: viewModel.selectedFileReview,
                                    latestWarnings: viewModel.latestWarningDetails
                                )
                            }
                        }
                    }
                    .frame(width: leftPanelWidth)
                    .padding(AppDesign.Spacing.lg)

                    PanelDivider(leftWidth: $leftPanelWidth, totalWidth: totalWidth)

                    CoordinateSelectionView(viewModel: coordinateViewModel)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { totalWidth = $0 }

            Divider()

            FileIntakeFooter(
                loadedFileCount: viewModel.selectedFiles.count,
                selectedFileCount: viewModel.selectedLoadedFileCount,
                latestNotice: viewModel.latestNotice,
                metadataBatchProgress: viewModel.currentMetadataBatchProgress,
                isApplyEnabled: viewModel.canApplyMetadata(selectedCoordinate: coordinateViewModel.selectedCoordinate),
                isMetadataBatchRunning: viewModel.isMetadataBatchRunning,
                applyAction: presentOverwriteConfirmation
            )
        }
        .frame(minWidth: AppDesign.Layout.minimumWindowWidth, minHeight: AppDesign.Layout.minimumWindowHeight)
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: Self.allowedContentTypes,
            allowsMultipleSelection: true,
            onCompletion: handleFileImport
        )
        .confirmationDialog(
            "Overwrite GPS Metadata?",
            isPresented: $isOverwriteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Overwrite", role: .destructive, action: confirmOverwrite)
            Button("Abort", role: .cancel) {}
        } message: {
            Text("GPS metadata will be overwritten in the selected files. The original metadata cannot be restored through this app.")
        }
        .environment(viewModel)
    }

    private func handleFileImport(_ result: Result<[URL], any Error>) {
        switch result {
        case .success(let urls):
            viewModel.intake(urls: urls, source: .picker)
        case .failure(let error):
            viewModel.reportPickerFailure(error)
        }
    }

    private func presentOverwriteConfirmation() {
        isOverwriteConfirmationPresented = true
    }

    private func activateLoadedFile(
        id: SelectedMediaFile.ID,
        intent: FileIntakeViewModel.GridSelectionIntent
    ) {
        viewModel.activateGridSelection(id: id, intent: intent)

        guard intent == .replace,
              let file = viewModel.selectedFiles.first(where: { $0.id == id }),
              let coordinate = file.gpsStatus.coordinate else {
            return
        }

        coordinateViewModel.selectLoadedFileCoordinate(coordinate)
    }

    private func confirmOverwrite() {
        let selectedCoordinate = coordinateViewModel.selectedCoordinate
        let coordinateLabel = coordinateViewModel.selectedCoordinateLabel ?? selectedCoordinate?.displayText
        let totalFileCount = viewModel.selectedFiles.count
        Task {
            await viewModel.applyMetadataIfConfirmed(
                true,
                coordinate: selectedCoordinate,
                writer: ExifToolMetadataWriter()
            )

            guard let selectedCoordinate,
                  let coordinateLabel,
                  let summary = viewModel.latestMetadataBatchSummary else {
                return
            }

            do {
                try BatchHistoryStore(modelContext: modelContext).recordBatchRun(
                    coordinateLabel: coordinateLabel,
                    coordinate: selectedCoordinate,
                    summary: summary,
                    totalFileCount: totalFileCount
                )
            } catch {
                viewModel.reportBatchHistoryFailure(error)
            }
        }
    }

    private static let allowedContentTypes: [UTType] = [
        .jpeg,
        .heic,
        .quickTimeMovie,
        .mpeg4Movie,
    ]
}

private struct FileIntakeFooter: View {
    let loadedFileCount: Int
    let selectedFileCount: Int
    let latestNotice: FileIntakeViewModel.IntakeNotice?
    let metadataBatchProgress: FileIntakeViewModel.MetadataBatchProgress?
    let isApplyEnabled: Bool
    let isMetadataBatchRunning: Bool
    let applyAction: () -> Void

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            HStack(spacing: AppDesign.Spacing.sm) {
                Label("Loaded: \(loadedFileCount)", systemImage: "tray.full")
                Label("Selected: \(selectedFileCount)", systemImage: "checkmark.circle")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let latestNotice {
                Divider()
                    .padding(.horizontal, AppDesign.Spacing.md)
                Label(latestNotice.message, systemImage: latestNotice.style == .warning ? "exclamationmark.triangle" : "tray")
                    .font(.caption)
                    .foregroundStyle(latestNotice.style == .warning ? .orange : .secondary)
            }

            Spacer()

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Apply Location", systemImage: "location.fill", action: applyAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(isApplyEnabled == false)
        }
        .frame(height: AppDesign.Layout.footerHeight)
        .padding(.horizontal, AppDesign.Spacing.lg)
    }

    private var statusText: String {
        if let metadataBatchProgress {
            metadataBatchProgress.displayString
        } else if isMetadataBatchRunning {
            "Applying selected location..."
        } else if loadedFileCount == 0 {
            ""
        } else {
            ""
        }
    }
}

#Preview {
    FileIntakeView()
        .modelContainer(for: [RecentCoordinate.self, BatchRunSummary.self], inMemory: true)
}
