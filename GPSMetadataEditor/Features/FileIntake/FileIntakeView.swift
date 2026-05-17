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
                        FileDropZone(mode: .large, viewModel: viewModel)
                    } else {
                        FileDropZone(mode: .compact, viewModel: viewModel)
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

                        SelectedFilesTable(
                            files: viewModel.selectedFiles,
                            selection: $viewModel.selectedFileID
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppDesign.Spacing.md)
                        .background(.background)
                        .clipShape(.rect(cornerSize: AppDesign.Radius.mediumSize))

                        FileDetailPanel(
                            detail: viewModel.selectedFileDetail,
                            latestWarnings: viewModel.latestWarningDetails
                        )
                    }
                }
                .frame(minWidth: AppDesign.Layout.leftColumnMinimumWidth, idealWidth: AppDesign.Layout.leftColumnIdealWidth)
                .padding(AppDesign.Spacing.lg)

                CoordinateSelectionView()
                    .frame(minWidth: AppDesign.Layout.rightColumnMinimumWidth, maxWidth: .infinity, maxHeight: .infinity)
            }

            Divider()

            FileIntakeFooter(
                selectedFileCount: viewModel.selectedFiles.count,
                latestNotice: viewModel.latestNotice
            )
        }
        .frame(minWidth: AppDesign.Layout.minimumWindowWidth, minHeight: AppDesign.Layout.minimumWindowHeight)
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: Self.allowedContentTypes,
            allowsMultipleSelection: true,
            onCompletion: handleFileImport
        )
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

    var body: some View {
        HStack(spacing: AppDesign.Spacing.sm) {
            Label(
                latestNotice?.message ?? "Ready",
                systemImage: latestNotice?.style == .warning ? "exclamationmark.triangle" : "tray"
            )
            .font(.caption)
            .foregroundStyle(latestNotice?.style == .warning ? .orange : .secondary)

            Spacer()

            Text(selectedFileCount == 0 ? "Add files to start the intake review." : "Review selected files before choosing a location.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: AppDesign.Layout.footerHeight)
        .padding(.horizontal, AppDesign.Spacing.lg)
    }
}

#Preview {
    FileIntakeView()
}
