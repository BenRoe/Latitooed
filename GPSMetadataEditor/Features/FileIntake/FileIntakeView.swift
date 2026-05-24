import Observation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct FileIntakeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = FileIntakeViewModel()
    @State private var coordinateViewModel = CoordinateSelectionViewModel()
    @State private var isOverwriteConfirmationPresented = false

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                    if viewModel.selectedFiles.isEmpty {
                        FileDropZone(mode: .large, viewModel: viewModel)
                    } else {
                        FileDropZone(mode: .compact, viewModel: viewModel)
                    }

                    if viewModel.selectedFiles.isEmpty == false {
                        VStack(alignment: .leading, spacing: AppDesign.Spacing.md) {
                            HStack {
                                Text("Selected Files")
                                    .font(.headline)
                                    .bold()

                                Spacer()

                                Text("\(viewModel.selectedFiles.count) \(viewModel.selectedFiles.count == 1 ? "file" : "files")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Picker("Loaded files view", selection: $viewModel.selectedLoadedFilesViewMode) {
                                    ForEach(FileIntakeViewModel.LoadedFilesViewMode.allCases) { mode in
                                        Text(mode.displayName)
                                            .tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(maxWidth: 180)
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
                                .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))
                            case .grid:
                                SelectedFilesGrid(
                                    files: viewModel.selectedFiles,
                                    selection: $viewModel.selectedFileIDs
                                )
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.background)
                                .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))
                            }

                            FileDetailPanel(
                                review: viewModel.selectedFileReview,
                                latestWarnings: viewModel.latestWarningDetails
                            )

                            BatchHistorySection(onUseCoordinate: coordinateViewModel.selectBatchRunSummary)
                        }
                    }
                }
                .frame(minWidth: AppDesign.Layout.leftColumnMinimumWidth, idealWidth: AppDesign.Layout.leftColumnIdealWidth)
                .padding(AppDesign.Spacing.lg)

                CoordinateSelectionView(viewModel: coordinateViewModel)
                    .frame(minWidth: AppDesign.Layout.rightColumnMinimumWidth, maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            FileIntakeFooter(
                selectedFileCount: viewModel.selectedFiles.count,
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
    let selectedFileCount: Int
    let latestNotice: FileIntakeViewModel.IntakeNotice?
    let metadataBatchProgress: FileIntakeViewModel.MetadataBatchProgress?
    let isApplyEnabled: Bool
    let isMetadataBatchRunning: Bool
    let applyAction: () -> Void

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Label(
                latestNotice?.message ?? "Ready",
                systemImage: latestNotice?.style == .warning ? "exclamationmark.triangle" : "tray"
            )
            .font(.caption)
            .foregroundStyle(latestNotice?.style == .warning ? .orange : .secondary)

            Spacer()

            Text(statusText)
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Apply Location", systemImage: "location.fill", action: applyAction)
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
        } else if selectedFileCount == 0 {
            "Add files to start the intake review."
        } else {
            "Review selected files before applying a location."
        }
    }
}

#Preview {
    FileIntakeView()
        .modelContainer(for: [RecentCoordinate.self, BatchRunSummary.self], inMemory: true)
}
